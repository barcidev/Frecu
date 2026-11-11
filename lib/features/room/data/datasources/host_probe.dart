import 'dart:async';
import 'dart:convert';

import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Si el anfitrión con el turno [term] y el id [host] gana al que lleva el
/// turno [otherTerm] con el id [otherHost]: gana el turno mayor y, a igual
/// turno, el `peer_N` menor (quien llegó antes a la frecu).
bool outranks({
  required int term,
  required String host,
  required int otherTerm,
  required String otherHost,
}) {
  if (term != otherTerm) return term > otherTerm;
  final rank = _rank(host).compareTo(_rank(otherHost));
  return rank == 0 ? host.compareTo(otherHost) < 0 : rank < 0;
}

/// Número de un id `peer_N`; los que no lo tienen van al final.
int _rank(String id) =>
    int.tryParse(id.replaceFirst('peer_', '')) ?? 0x7fffffff;

/// Otro teléfono que lleva la misma frecu con un turno que gana: [host] con
/// el turno [term], en [address] y [port].
class HostRival {
  /// Crea el rival.
  const HostRival({
    required this.host,
    required this.term,
    required this.address,
    required this.port,
  });

  /// Id de quien la lleva.
  final String host;

  /// Su turno.
  final int term;

  /// IPv4 de su servidor.
  final String address;

  /// Puerto de su servidor.
  final int port;

  /// Quien pregunta con [probe] desde [address], si su turno gana al de
  /// este servidor ([term] de [host]); si no gana, nulo.
  static HostRival? challenging(
    SignalingHostProbeMessage probe, {
    required String address,
    required int term,
    required String host,
  }) {
    final wins = outranks(
      term: probe.term,
      host: probe.host,
      otherTerm: term,
      otherHost: host,
    );
    if (!wins) return null;
    return HostRival(
      host: probe.host,
      term: probe.term,
      address: address,
      port: probe.port,
    );
  }
}

/// Pregunta con `host_probe`, mientras este teléfono lleva una frecu local
/// con traspaso, en las IPs de quienes salieron de su sucesión: si alguno
/// lleva la misma frecu con un turno que gana, lo avisa una vez.
class HostProbe {
  /// Crea la pregunta; [port] fija el puerto al que preguntar (en pruebas),
  /// y sin él se pregunta en el de la frecu.
  HostProbe({
    this.port,
    this.interval = const Duration(seconds: 3),
    this.timeout = const Duration(seconds: 1),
    WebSocketChannel Function(Uri uri)? connect,
  }) : _connect = connect ?? WebSocketChannel.connect;

  /// Puerto al que preguntar; nulo: el del servidor de la frecu.
  final int? port;

  /// Cada cuánto se pregunta.
  final Duration interval;

  /// Espera máxima de cada pregunta.
  final Duration timeout;

  final WebSocketChannel Function(Uri uri) _connect;

  /// IPv4 de cada persona que se vio en la sucesión en esta sesión.
  final Map<String, String> _seen = {};

  /// IPs que rechazaron el código: llevan otra frecu.
  final Set<String> _refused = {};

  Timer? _timer;
  int _generation = 0;
  bool _busy = false;

  /// Está preguntando.
  bool get running => _timer != null;

  /// Recuerda las IPs de [state]; con `null` (sin frecu), las olvida.
  void remember(RoomSuccession? state) {
    if (state == null) {
      _seen.clear();
      _refused.clear();
      return;
    }
    for (final member in state.members) {
      final address = member.address;
      if (address != null) _seen[member.id] = address;
    }
  }

  /// IPs de quienes salieron de [state]: sin las de quienes siguen (este
  /// teléfono incluido) ni las que rechazaron el código.
  List<String> absent(RoomSuccession state) {
    final present = {for (final member in state.members) ?member.address};
    return {
      for (final MapEntry(key: id, value: address) in _seen.entries)
        if (!state.order.contains(id) &&
            !present.contains(address) &&
            !_refused.contains(address))
          address,
    }.toList();
  }

  /// Pregunta cada [interval] con la sucesión de [state] como [me], que
  /// lleva la frecu en [serverPort]; al primer rival que gana, se detiene y
  /// llama a [onRival].
  void start({
    required RoomSuccession? Function() state,
    required String me,
    required int serverPort,
    required void Function(HostRival rival) onRival,
  }) {
    stop();
    final generation = _generation;
    _timer = Timer.periodic(
      interval,
      (_) => unawaited(_tick(generation, state(), me, serverPort, onRival)),
    );
  }

  /// Deja de preguntar.
  void stop() {
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick(
    int generation,
    RoomSuccession? state,
    String me,
    int serverPort,
    void Function(HostRival rival) onRival,
  ) async {
    if (_busy || state == null) return;
    if (!state.handover || state.reach != RoomReach.local) return;
    _busy = true;
    try {
      for (final address in absent(state)) {
        final rival = await ask(
          address,
          port ?? serverPort,
          accessCode: state.accessCode,
          term: state.term,
          host: me,
          serverPort: serverPort,
        );
        if (generation != _generation) return;
        if (rival == null) continue;
        stop();
        onRival(rival);
        return;
      }
    } finally {
      _busy = false;
    }
  }

  /// Pregunta en [address] y [port] con el turno [term] de [host], que
  /// lleva la frecu de [accessCode] en [serverPort]. Devuelve el rival si
  /// su respuesta gana; nulo si no gana, si no responde o si rechaza el
  /// código (y entonces esa IP no se vuelve a preguntar).
  Future<HostRival?> ask(
    String address,
    int port, {
    required String accessCode,
    required int term,
    required String host,
    required int serverPort,
  }) async {
    final reply = await _exchange(
      Uri.parse('ws://$address:$port'),
      SignalingMessage.hostProbe(
        accessCode: accessCode,
        term: term,
        host: host,
        port: serverPort,
      ),
    );
    return switch (reply) {
      SignalingRejectedMessage() => _refuse(address),
      SignalingHostProbeMessage() => HostRival.challenging(
        reply,
        address: address,
        term: term,
        host: host,
      ),
      // Sin respuesta, o una que no es de `host_probe`: nadie disputa la
      // frecu. Cada mensaje va nombrado para que el compilador avise si
      // llega uno nuevo.
      null => null,
      SignalingJoinMessage() => null,
      SignalingWelcomeMessage() => null,
      SignalingPeerJoinedMessage() => null,
      SignalingPeerLeftMessage() => null,
      SignalingOfferMessage() => null,
      SignalingAnswerMessage() => null,
      SignalingIceMessage() => null,
      SignalingTalkStateMessage() => null,
      SignalingQuickMessage() => null,
      SignalingPositionMessage() => null,
      SignalingPingMessage() => null,
      SignalingPongMessage() => null,
      SignalingRoomStateMessage() => null,
      SignalingHostHandoverMessage() => null,
      SignalingHostChangedMessage() => null,
      SignalingRoomClosedMessage() => null,
    };
  }

  /// [address] rechazó el código: no se le vuelve a preguntar.
  HostRival? _refuse(String address) {
    _refused.add(address);
    return null;
  }

  /// Envía [probe] a [uri] y devuelve su respuesta (`host_probe` o
  /// `rejected`); nula si no responde a tiempo.
  Future<SignalingMessage?> _exchange(Uri uri, SignalingMessage probe) async {
    WebSocketChannel? channel;
    try {
      channel = _connect(uri);
      await channel.ready.timeout(timeout);
      channel.sink.add(jsonEncode(probe.toJson()));
      return await channel.stream
          .map(SignalingMessage.tryDecode)
          .firstWhere(
            (m) =>
                m is SignalingHostProbeMessage || m is SignalingRejectedMessage,
          )
          .timeout(timeout);
    } on Object catch (e) {
      AppLogger.d('No host answered at $uri: $e');
      return null;
    } finally {
      unawaited(_close(channel));
    }
  }

  static Future<void> _close(WebSocketChannel? channel) async {
    try {
      await channel?.sink.close();
    } on Object {
      // Ya estaba cerrado.
    }
  }
}
