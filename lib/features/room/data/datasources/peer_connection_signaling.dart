part of 'peer_connection_datasource.dart';

/// Señalización de la malla: ofertas, respuestas y candidatos ICE dirigidos
/// a este teléfono, y quien se va.
extension _Signaling on PeerConnectionDataSource {
  void _handleSignalingMessage(SignalingMessage msg) => switch (msg) {
    SignalingOfferMessage(:final from, :final to, :final sdp) => _ifForMe(
      msg,
      to,
      from,
      (token) => _handleOffer(from, sdp, token),
    ),
    SignalingAnswerMessage(:final from, :final to, :final sdp) => _ifForMe(
      msg,
      to,
      from,
      (token) => _handleAnswer(from, sdp, token),
    ),
    SignalingIceMessage(
      :final from,
      :final to,
      :final candidate,
      :final sdpMid,
      :final sdpMLineIndex,
    ) =>
      _ifForMe(
        msg,
        to,
        from,
        (token) =>
            _handleIce(from, RTCIceCandidate(candidate, sdpMid, sdpMLineIndex)),
      ),
    SignalingPeerLeftMessage(:final peerId) => _closePeer(peerId),
    // El resto de la señalización no toca la malla. Cada mensaje va
    // nombrado para que el compilador avise si llega uno nuevo.
    SignalingJoinMessage() => null,
    SignalingWelcomeMessage() => null,
    SignalingRejectedMessage() => null,
    SignalingPeerJoinedMessage() => null,
    SignalingTalkStateMessage() => null,
    SignalingQuickMessage() => null,
    SignalingPositionMessage() => null,
    SignalingPingMessage() => null,
    SignalingPongMessage() => null,
    SignalingRoomStateMessage() => null,
    SignalingHostHandoverMessage() => null,
    SignalingHostProbeMessage() => null,
    SignalingHostChangedMessage() => null,
    SignalingRoomClosedMessage() => null,
  };

  /// Encola [task] tras lo pendiente de [from] si [msg] va dirigido a este
  /// teléfono ([to]).
  void _ifForMe(
    SignalingMessage msg,
    String to,
    String from,
    Future<void> Function(_PeerToken token) task,
  ) {
    if (_isForMe(msg, to)) unawaited(_enqueue(from, task));
  }

  /// Si el mensaje va dirigido al id local; sin id aún (antes de la
  /// primera frecu), lo guarda para atenderlo al fijarlo.
  bool _isForMe(SignalingMessage msg, String to) {
    if (_localPeerId.isEmpty) {
      const max = PeerConnectionDataSource._maxEarlyMessages;
      if (!_attachedOnce && _early.length < max) _early.add(msg);
      return false;
    }
    return to == _localPeerId;
  }
}
