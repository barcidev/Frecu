part of 'signaling_server_datasource.dart';

/// Enrutado de lo que llega al servidor: antes del `join` solo se atiende
/// el `join` o un `host_probe`; después, se reenvía con el id de quien lo
/// mandó.
extension _Routing on SignalingServerDataSource {
  /// Enruta un mensaje de [from], que ya se unió, forzando su id como
  /// remitente.
  void _routeFrom(String from, SignalingMessage message) => switch (message) {
    SignalingOfferMessage(:final to) => _forward(
      message,
      from,
      to,
      message.copyWith(from: from),
    ),
    SignalingAnswerMessage(:final to) => _forward(
      message,
      from,
      to,
      message.copyWith(from: from),
    ),
    SignalingIceMessage(:final to) => _forward(
      message,
      from,
      to,
      message.copyWith(from: from),
    ),
    SignalingTalkStateMessage() => _echo(
      message,
      from,
      message.copyWith(peerId: from),
    ),
    SignalingQuickMessage() => _echo(
      message,
      from,
      message.copyWith(peerId: from),
    ),
    SignalingPositionMessage() => _echo(
      message,
      from,
      message.copyWith(peerId: from),
    ),
    SignalingPingMessage(:final timestamp) => _sendToPeer(
      from,
      SignalingMessage.pong(timestamp: timestamp),
    ),
    // Solo el anfitrión emite el resto; uno de un participante se ignora.
    // Cada mensaje va nombrado para que el compilador avise si llega uno
    // nuevo.
    SignalingJoinMessage() => null,
    SignalingWelcomeMessage() => null,
    SignalingRejectedMessage() => null,
    SignalingPeerJoinedMessage() => null,
    SignalingPeerLeftMessage() => null,
    SignalingPongMessage() => null,
    SignalingRoomStateMessage() => null,
    SignalingHostHandoverMessage() => null,
    SignalingHostProbeMessage() => null,
    SignalingHostChangedMessage() => null,
    SignalingRoomClosedMessage() => null,
  };

  /// Avisa a este teléfono de [original] y lo reenvía de [from] a [to] como
  /// [stamped], con el id de quien lo mandó.
  void _forward(
    SignalingMessage original,
    String from,
    String to,
    SignalingMessage stamped,
  ) {
    _messagesController.add(original);
    _routeToPeer(from, to, stamped);
  }

  /// Avisa a este teléfono de [original] y lo reparte como [stamped] a todos
  /// menos a quien lo mandó ([from]).
  void _echo(SignalingMessage original, String from, SignalingMessage stamped) {
    _messagesController.add(original);
    _broadcast(stamped, excludePeerId: from);
  }

  /// Antes del `join` no se enruta nada: solo se atiende el `join`, que
  /// devuelve el id asignado, o una pregunta de `host_probe`. Cada mensaje
  /// va nombrado para que el compilador avise si llega uno nuevo.
  String? _beforeJoin(SignalingConnection channel, SignalingMessage message) =>
      switch (message) {
        SignalingJoinMessage() => _acceptJoin(channel, message),
        SignalingHostProbeMessage() => _probeBeforeJoin(channel, message),
        SignalingWelcomeMessage() => null,
        SignalingRejectedMessage() => null,
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

  /// Avisa del [join] y lo procesa; devuelve el id asignado, si lo hay.
  String? _acceptJoin(SignalingConnection channel, SignalingJoinMessage join) {
    _messagesController.add(join);
    return _processJoin(channel, join);
  }

  /// Responde un `host_probe` antes del `join`: quien pregunta no recibe id.
  String? _probeBeforeJoin(
    SignalingConnection channel,
    SignalingHostProbeMessage probe,
  ) {
    _answerProbe(channel, probe);
    return null;
  }
}
