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

  /// El teléfono tiene alguna dirección de red que no es loopback.
  Future<bool> networkUp() async =>
      (await _networkReturn.addresses())?.isNotEmpty ?? false;

  /// Reintenta mientras [active]: avisa cada espera con [onWaiting] (con
  /// `Duration.zero` si la red volvió antes de tiempo), prueba con
  /// [attempt] (que es `true` si volvió o si ya no hay que seguir) y, si se
  /// agotan los intentos, llama a [onGiveUp]. Con [waits], hace un intento
  /// por cada espera de la lista en lugar del backoff de [maxAttempts].
  Future<void> run({
    required bool Function() active,
    required void Function(Duration retryIn, int attempt) onWaiting,
    required Future<bool> Function(int attempt) attempt,
    required void Function() onGiveUp,
    List<Duration>? waits,
  }) async {
    final schedule = waits ?? _backoff();
    try {
      var baseline = await _networkReturn.addresses();
      for (var n = 1; n <= schedule.length; n++) {
        if (!active()) return;
        baseline = await _pause(
          schedule[n - 1],
          n,
          baseline: baseline,
          active: active,
          onWaiting: onWaiting,
        );
        if (!active()) return;
        if (await attempt(n)) return;
      }
      if (active()) onGiveUp();
    } on Object catch (e, st) {
      AppLogger.e('Reconnect loop failed', e, st);
      if (active()) onGiveUp();
    }
  }

  /// Espera [delay] antes del intento [attempt] (adelantándose si vuelve
  /// la red) y devuelve la referencia de red renovada para el próximo.
  Future<Set<String>?> _pause(
    Duration delay,
    int attempt, {
    required Set<String>? baseline,
    required bool Function() active,
    required void Function(Duration retryIn, int attempt) onWaiting,
  }) async {
    onWaiting(delay, attempt);
    final networkBack = await _networkReturn.wait(
      delay,
      baseline: baseline,
      cancelled: () => !active(),
    );
    if (!active()) return baseline;
    // Volvió la red antes de tiempo: la cuenta pasa a «intentando».
    if (networkBack) onWaiting(Duration.zero, attempt);
    // La referencia se renueva antes de cada intento: una misma red que
    // aparece solo adelanta un intento.
    return _networkReturn.addresses();
  }

  /// Las esperas de siempre: [baseDelay] y el doble en cada intento.
  List<Duration> _backoff() {
    var delay = baseDelay;
    return [
      for (var n = 0; n < maxAttempts; n++)
        if (n == 0) delay else delay = _next(delay),
    ];
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
  /// [previousHostId], a quienes responde `host_changed` con [reason]. Si el puerto aún está ocupado (el anterior lo está
  /// soltando), reintenta [attempts] veces cada [retry].
  static Future<void> openServer(
    SignalingServerDataSource server, {
    required RoomSuccession state,
    required String me,
    required String previousHostId,
    required String address,
    required int term,
    required int port,
    HostChangeReason reason = HostChangeReason.left,
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
        reason: reason.name,
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

/// Un paso del plan de caída ([FailoverPlan]).
sealed class FailoverStep {
  const FailoverStep();
}

/// Reintentar al anfitrión que dejó de responder.
final class FailoverRetryHost extends FailoverStep {
  /// Crea el paso.
  const FailoverRetryHost();
}

/// Volver a la frecu en la IP de [member], con el mismo id, por si la tomó.
final class FailoverFollow extends FailoverStep {
  /// Crea el paso hacia [member].
  const FailoverFollow(this.member);

  /// Persona de la sucesión que la habrá tomado.
  final RoomMember member;
}

/// Tomar la frecu este teléfono, si su red sigue arriba.
final class FailoverTake extends FailoverStep {
  /// Crea el paso.
  const FailoverTake();
}

/// Plan de un invitado cuando el anfitrión de una frecu local con traspaso
/// deja de responder: [hostRetries] reintentos al anfitrión y, por cada
/// persona de la sucesión sin él y en orden, [triesEach] pasos: volver a su
/// IP o, si es este teléfono, tomarla. Todos siguen el mismo plan con la
/// misma sucesión, así que cada uno llega a la misma persona, y a la vez.
class FailoverPlan {
  /// Arma el plan con la sucesión [state], el anfitrión que se cayó
  /// ([lostHost]), este teléfono ([me]) y la espera [base].
  FailoverPlan({
    required this.state,
    required this.lostHost,
    required this.me,
    required Duration base,
  }) {
    for (var n = 0; n < hostRetries; n++) {
      _add(const FailoverRetryHost(), base * (1 << n));
    }
    for (final member in state.members) {
      if (member.id == lostHost) continue;
      final address = member.address;
      if (member.id != me && address == null) continue;
      for (var n = 0; n < triesEach; n++) {
        _add(
          member.id == me ? const FailoverTake() : FailoverFollow(member),
          base * (1 << n),
        );
      }
    }
  }

  /// Reintentos al anfitrión antes de seguir la sucesión.
  static const int hostRetries = 2;

  /// Pasos por cada persona de la sucesión.
  static const int triesEach = 2;

  /// Sucesión que mandó el anfitrión antes de caerse.
  final RoomSuccession state;

  /// Id del anfitrión que dejó de responder.
  final String lostHost;

  /// Id de este teléfono.
  final String me;

  final List<FailoverStep> _steps = [];
  final List<Duration> _waits = [];

  /// Los pasos, en orden.
  List<FailoverStep> get steps => List.unmodifiable(_steps);

  /// La espera antes de cada paso.
  List<Duration> get waits => List.unmodifiable(_waits);

  /// Nombre del anfitrión que dejó de responder.
  String? get lostHostName => state.members
      .where((member) => member.id == lostHost)
      .firstOrNull
      ?.displayName;

  /// IPv4 de este teléfono en la sucesión: la que conocen los demás.
  String? get myAddress =>
      state.members.where((member) => member.id == me).firstOrNull?.address;

  void _add(FailoverStep step, Duration wait) {
    _steps.add(step);
    _waits.add(wait);
  }
}
