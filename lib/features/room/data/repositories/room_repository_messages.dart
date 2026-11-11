part of 'room_repository_impl.dart';

/// Conexión del cliente a la frecu: sesiones, `join` y los mensajes que
/// llegan (`welcome`, rechazos, participantes y cierre).
extension _Messages on RoomRepositoryImpl {
  /// Abre una sesión nueva y cierra la anterior si seguía viva (p. ej. una
  /// frecu que se dejó con Atrás), sin reconectarla.
  Future<int> _beginSession({required bool host}) async {
    final session = ++_session;
    _joined = false;
    _target = null;
    _isDeliberateLeave = true;
    if (_live) await _teardownConnection();
    _live = true;
    _isDeliberateLeave = false;
    _isClosed = false;
    _isHost = host;
    _internetId = null;
    _following = false;
    _outranked = null;
    _localParticipantId = null;
    _takeover.forget();
    _succession.update(null);
    _probe.remember(null);
    _setParticipants(const []);
    _setStatus(const RoomStatus.connecting());
    return session;
  }

  /// Deshace un intento fallido de crear o unirse.
  Future<void> _abortSession(int session) async {
    if (session != _session) return;
    _joined = false;
    _target = null;
    _localParticipantId = null;
    _isDeliberateLeave = true;
    await _teardownConnection();
    _isDeliberateLeave = false;
    _succession.update(null);
    _setParticipants(const []);
    _setStatus(const RoomStatus.idle());
  }

  /// Suelta la conexión de la sesión actual: mensajes, notificación,
  /// servidor (si es anfitrión) y socket.
  Future<void> _teardownConnection() async {
    _live = false;
    _probe.stop();
    // Dejar de escuchar es inmediato; no hace falta esperar.
    unawaited(_clientSubscription?.cancel());
    _clientSubscription = null;
    await _foregroundService.stopService();
    await _relay.stop();
    if (_isHost || _server.isRunning) await _server.stop();
    _isHost = false;
    await _client.disconnect();
  }

  /// Envía el `join` y espera el `welcome` como mucho [welcomeTimeout].
  Future<Result<Room>> _join(
    int session, {
    required String displayName,
    required String accessCode,
    required String hostAddress,
    required int port,
    String? peerId,
  }) async {
    final welcome = Completer<Result<Room>>();
    _listen(
      session,
      welcome: welcome,
      rejoin: false,
      accessCode: accessCode,
      hostAddress: hostAddress,
      port: port,
    );
    _client.send(
      SignalingMessage.join(
        displayName: displayName,
        accessCode: accessCode,
        peerId: peerId,
        term: _succession.current?.term,
      ),
    );
    return welcome.future.timeout(
      welcomeTimeout,
      onTimeout: () => const Result.failure(Failure.hostUnreachable()),
    );
  }

  void _listen(
    int session, {
    required Completer<Result<Room>> welcome,
    required bool rejoin,
    required String accessCode,
    required String hostAddress,
    required int port,
  }) {
    final join = _Joining(
      welcome: welcome,
      rejoin: rejoin,
      accessCode: accessCode,
      hostAddress: hostAddress,
      port: port,
    );
    unawaited(_clientSubscription?.cancel());
    _clientSubscription = _client.messages.listen(
      (message) {
        if (session == _session) _onMessage(session, message, join);
      },
      onError: (Object error) {
        AppLogger.w('Client message error: $error');
        if (!welcome.isCompleted) {
          welcome.complete(const Result.failure(Failure.hostUnreachable()));
        }
      },
    );
  }

  void _onMessage(int session, SignalingMessage message, _Joining join) =>
      switch (message) {
        SignalingWelcomeMessage() => _onWelcomeMessage(message, join),
        SignalingRejectedMessage(:final reason) => _onRejected(
          join.welcome,
          reason,
          rejoin: join.rejoin,
        ),
        SignalingPeerJoinedMessage(:final participant) => _onPeerJoined(
          participant,
        ),
        SignalingPeerLeftMessage(:final peerId) => _onPeerLeft(peerId),
        SignalingRoomStateMessage(:final state) => _onRoomState(state),
        SignalingRoomClosedMessage(:final reason) => _onRoomClosed(reason),
        SignalingHostHandoverMessage() => _onHostHandover(session, message),
        SignalingHostChangedMessage(:final host, :final reason) =>
          _onHostChanged(host, reason),
        // El resto de la señalización no cambia la frecu. Cada mensaje va
        // nombrado para que el compilador avise si llega uno nuevo.
        SignalingJoinMessage() => null,
        SignalingOfferMessage() => null,
        SignalingAnswerMessage() => null,
        SignalingIceMessage() => null,
        SignalingTalkStateMessage() => null,
        SignalingQuickMessage() => null,
        SignalingPositionMessage() => null,
        SignalingPingMessage() => null,
        SignalingPongMessage() => null,
        SignalingHostProbeMessage() => null,
      };

  /// Estado compartido de la frecu: sucesión y turno.
  void _onRoomState(RoomSuccession state) {
    _succession.update(state);
    _probe.remember(state);
  }

  void _onWelcomeMessage(SignalingWelcomeMessage message, _Joining join) {
    // Un intento de reconexión que ya se dio por fallido no revive.
    if (join.rejoin && join.welcome.isCompleted) return;
    // Al reconectar, el lugar viejo propio puede seguir en la lista hasta
    // que el anfitrión note que se fue: no es otra persona. Si vuelve a su
    // mismo lugar (traspaso), no hay lugar viejo.
    final stale = join.rejoin && message.peerId != _localParticipantId
        ? _localParticipantId
        : null;
    _onWelcome(
      join.welcome,
      peerId: message.peerId,
      participants: [
        for (final participant in message.participants)
          if (participant.id != stale) participant,
      ],
      note: message.note,
      roomName: message.roomName,
      accessCode: join.accessCode,
      hostAddress: join.hostAddress,
      port: join.port,
    );
  }

  void _onWelcome(
    Completer<Result<Room>> completer, {
    required String peerId,
    required List<Participant> participants,
    required RoomNote? note,
    required String? roomName,
    required String accessCode,
    required String hostAddress,
    required int port,
  }) {
    _joined = true;
    _isClosed = false;
    _following = false;
    _localParticipantId = peerId;
    if (roomName != null && roomName.isNotEmpty) _roomName = roomName;
    _setParticipants(participants);
    _setStatus(const RoomStatus.connected());
    unawaited(
      _foregroundService.startService(
        roomName: _roomName,
        status: ForegroundStatus.connected,
      ),
    );

    final room = Room(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: _roomName,
      hostAddress: hostAddress,
      port: port,
      accessCode: accessCode,
      createdAt: DateTime.now(),
      note: note,
      internetId: _internetId,
      hostOwnsNetwork: participants.any((p) => p.isHost && p.ownsNetwork),
    );

    if (!completer.isCompleted) completer.complete(Result.success(room));
    _afterWelcome(peerId, participants);
  }

  void _onRejected(
    Completer<Result<Room>> completer,
    String reason, {
    required bool rejoin,
  }) {
    // Al reconectar, un rechazo (p. ej. su lugar viejo aún ocupa la frecu
    // llena) es un intento fallido más, no el final de la frecu.
    if (!rejoin) _localParticipantId = null;
    final failure = switch (reason) {
      RejectReason.invalidAccessCode => const Failure.invalidAccessCode(),
      RejectReason.roomFull => const Failure.roomFull(),
      RejectReason.versionMismatch => const Failure.versionMismatch(),
      _ => Failure.unexpected(error: 'rejected: $reason'),
    };
    if (!completer.isCompleted) completer.complete(Result.failure(failure));
  }

  void _onPeerJoined(Participant participant) {
    _setParticipants([
      ..._participants.where((p) => p.id != participant.id),
      participant,
    ]);
  }

  void _onPeerLeft(String peerId) {
    _setParticipants(_participants.where((p) => p.id != peerId).toList());
  }

  void _onRoomClosed(String reason) {
    _isClosed = true;
    _joined = false;
    _localParticipantId = null;
    unawaited(_foregroundService.stopService());
    _setStatus(RoomStatus.closed(reason: reason));
    _succession.update(null);
    _setParticipants(const []);
  }
}

/// Lo que espera cada `join` enviado: su `welcome` y a qué frecu va.
class _Joining {
  const _Joining({
    required this.welcome,
    required this.rejoin,
    required this.accessCode,
    required this.hostAddress,
    required this.port,
  });

  final Completer<Result<Room>> welcome;
  final bool rejoin;
  final String accessCode;
  final String hostAddress;
  final int port;
}
