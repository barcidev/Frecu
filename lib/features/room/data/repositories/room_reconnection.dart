import 'dart:async';
import 'dart:io';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/network/network_return.dart';
import 'package:frecu/features/room/data/datasources/room_succession.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';

/// Bucle de reintentos para volver a la frecu tras perder el socket: espera
/// con backoff exponencial (adelantándose si vuelve la red) y prueba hasta
/// [maxAttempts] veces.
class RejoinLoop {
  /// Crea el bucle con su vigía de la red, la primera espera y el máximo de
  /// intentos.
  RejoinLoop({
    required this._networkReturn,
    required this.baseDelay,
    required this.maxAttempts,
  });

  final NetworkReturnWatcher _networkReturn;

  /// Espera antes del primer intento; se dobla en cada uno.
  final Duration baseDelay;

  /// Intentos antes de rendirse.
  final int maxAttempts;

  /// Reintenta mientras [active]: avisa cada espera con [onWaiting] (con
  /// `Duration.zero` si la red volvió antes de tiempo), prueba con
  /// [attempt] (que es `true` si volvió o si ya no hay que seguir) y, si se
  /// agotan los intentos, llama a [onGiveUp].
  Future<void> run({
    required bool Function() active,
    required void Function(Duration retryIn, int attempt) onWaiting,
    required Future<bool> Function(int attempt) attempt,
    required void Function() onGiveUp,
  }) async {
    var delay = baseDelay;
    try {
      var baseline = await _networkReturn.addresses();
      for (var n = 1; n <= maxAttempts; n++) {
        if (!active()) return;
        onWaiting(delay, n);
        final networkBack = await _networkReturn.wait(
          delay,
          baseline: baseline,
          cancelled: () => !active(),
        );
        if (!active()) return;
        // Volvió la red antes de tiempo: la cuenta pasa a «intentando».
        if (networkBack) onWaiting(Duration.zero, n);
        // La referencia se renueva antes de cada intento: una misma red que
        // aparece solo adelanta un intento.
        baseline = await _networkReturn.addresses();
        if (!active()) return;
        if (await attempt(n)) return;
        delay = _next(delay);
      }
      if (active()) onGiveUp();
    } on Object catch (e, st) {
      AppLogger.e('Reconnect loop failed', e, st);
      if (active()) onGiveUp();
    }
  }

  static Duration _next(Duration current) => Duration(
    milliseconds: (current.inMilliseconds * 2).clamp(
      0,
      NetworkConstants.maxReconnectBackoff.inMilliseconds,
    ),
  );
}

/// Traspaso de la frecu visto desde este teléfono: recuerda quién la
/// llevaba, abre el servidor de quien la recibe y avisa cada cambio de
/// anfitrión.
class HostTakeover {
  final StreamController<HostChange> _changes =
      StreamController<HostChange>.broadcast();

  /// Cada cambio de anfitrión.
  Stream<HostChange> watch() => _changes.stream;

  /// Nombre de quien llevaba la frecu, guardado antes de que salga de la
  /// lista.
  String? previousHost;

  /// Olvida el traspaso en curso (frecu nueva o salida).
  void forget() => previousHost = null;

  /// Avisa que [hostName] ([hostId]) lleva ahora la frecu, en [hostAddress]
  /// y [port]; [you] si es este teléfono.
  void announce({
    required String hostId,
    required String hostName,
    required bool you,
    required HostChangeReason reason,
    required String hostAddress,
    required int port,
  }) {
    if (_changes.isClosed) return;
    _changes.add(
      HostChange(
        hostId: hostId,
        hostName: hostName,
        you: you,
        reason: reason,
        hostAddress: hostAddress,
        port: port,
        previousHost: previousHost,
      ),
    );
    previousHost = null;
  }

  /// Abre en [server] la frecu de [state] para [me], con el turno [term] y
  /// la IPv4 [address], en [port]: guarda un lugar a cada persona menos a
  /// [previousHostId]. Si el puerto aún está ocupado (el anterior lo está
  /// soltando), reintenta [attempts] veces cada [retry].
  static Future<void> openServer(
    SignalingServerDataSource server, {
    required RoomSuccession state,
    required String me,
    required String previousHostId,
    required String address,
    required int term,
    required int port,
    int attempts = 10,
    Duration retry = const Duration(milliseconds: 300),
  }) async {
    server
      ..hostOwnsNetwork = false
      ..succession.configure(
        reach: state.reach,
        hostOwnsNetwork: false,
        hostAddress: address,
        internetId: state.internetId,
        hostSecret: state.hostSecret,
        term: term,
      );
    for (var n = 1; ; n++) {
      server.inherited = InheritedRoom(
        state,
        host: me,
        previous: previousHostId,
      );
      try {
        await server.start(
          accessCode: state.accessCode,
          roomName: state.name,
          note: state.note,
          port: port,
        );
        return;
      } on SocketException catch (e) {
        if (n >= attempts) rethrow;
        AppLogger.w('Port $port still busy for the takeover: $e');
        await Future<void>.delayed(retry);
      }
    }
  }

  /// Libera el stream.
  Future<void> dispose() => _changes.close();
}
