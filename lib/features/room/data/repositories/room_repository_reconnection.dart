part of 'room_repository_impl.dart';

/// Reconexión de un invitado que perdió el socket y plan de caída de la
/// frecu con traspaso.
extension _Reconnection on RoomRepositoryImpl {
  void _handleClientConnectionChange(bool isConnected) {
    if (isConnected || !_canReconnect) return;
    final session = _session;
    // Un solo bucle de reconexión por sesión.
    if (_reconnectSession == session) return;
    _reconnectSession = session;
    unawaited(
      _reconnect(session).whenComplete(() {
        if (_reconnectSession == session) _reconnectSession = null;
      }),
    );
  }

  bool _stillReconnecting(int session) => session == _session && _canReconnect;

  Future<void> _reconnect(int session) {
    final plan = _failoverPlan();
    return _rejoin.run(
      active: () => _stillReconnecting(session),
      onWaiting: _onReconnectWait,
      waits: plan?.waits,
      attempt: (attempt) => plan == null
          ? _attemptRejoin(session, attempt)
          : _failoverAttempt(session, plan, attempt),
      onGiveUp: _giveUp,
    );
  }

  /// Cuenta la espera de la reconexión en el estado y en la notificación.
  void _onReconnectWait(Duration retryIn, int attempt) {
    _setStatus(RoomStatus.reconnecting(retryIn: retryIn, attempt: attempt));
    if (retryIn == Duration.zero) return;
    unawaited(
      _foregroundService.updateNotification(
        roomName: _roomName,
        status: ForegroundStatus.reconnecting,
      ),
    );
  }

  /// Plan de caída si el anfitrión de una frecu con traspaso (local o por
  /// internet) dejó de responder; nulo para reconectar como siempre (otra
  /// frecu, sin sucesión o siguiendo un `host_handover`).
  FailoverPlan? _failoverPlan() {
    final state = _succession.current;
    final me = _localParticipantId;
    if (_following || state == null || me == null) return null;
    if (!state.handover) return null;
    final host = _participants.where((p) => p.isHost).firstOrNull?.id;
    final lost = host ?? state.order.firstOrNull;
    if (lost == null || lost == me) return null;
    return FailoverPlan(
      state: state,
      lostHost: lost,
      me: me,
      base: _rejoin.baseDelay,
    );
  }

  /// Un paso del plan de caída; `true` si volvió, si tomó la frecu o si ya
  /// no hay que seguir.
  Future<bool> _failoverAttempt(
    int session,
    FailoverPlan plan,
    int attempt,
  ) async {
    final target = _target;
    if (target == null) return true;
    switch (plan.steps[attempt - 1]) {
      case FailoverRetryHost():
        return _attemptRejoin(session, attempt);
      case FailoverFollow(:final member):
        _takeover.previousHost = plan.lostHostName;
        _target = target.toward(
          member.address ?? '',
          peerId: _localParticipantId,
        );
        return _attemptRejoin(session, attempt);
      case FailoverTake():
        final address = plan.internet ? '' : plan.myAddress;
        if (address == null || !await _rejoin.networkUp()) return false;
        if (!_stillReconnecting(session)) return true;
        _takeover.previousHost = plan.lostHostName;
        unawaited(
          _takeOver(
            session,
            state: plan.state,
            term: plan.state.term + 1,
            address: address,
            previousHostId: plan.lostHost,
            target: target,
            reason: HostChangeReason.lost,
          ),
        );
        return true;
    }
  }

  /// Un intento de volver a la frecu; `true` si volvió o si ya no hay que
  /// seguir intentando.
  Future<bool> _attemptRejoin(int session, int attempt) async {
    final target = _target;
    if (target == null) return true;
    try {
      await _client.connect(target.uri);
      if (!_stillReconnecting(session)) return true;

      final welcome = Completer<Result<Room>>();
      _listen(
        session,
        welcome: welcome,
        rejoin: true,
        accessCode: target.accessCode,
        hostAddress: target.host,
        port: target.port,
      );
      _client.send(
        SignalingMessage.join(
          displayName: target.displayName,
          accessCode: target.accessCode,
          peerId: target.peerId,
          term: _succession.current?.term,
        ),
      );
      final result = await welcome.future.timeout(
        rejoinWelcomeTimeout,
        onTimeout: () => const Result.failure(Failure.hostUnreachable()),
      );
      if (result.isSuccess || !_stillReconnecting(session)) return true;
      // Sin welcome a tiempo: se suelta ese socket antes del próximo intento.
      await _client.disconnect();
      return false;
    } on Object catch (e) {
      AppLogger.w('Reconnect attempt $attempt failed: $e');
      return !_stillReconnecting(session);
    }
  }

  /// Se agotaron los intentos: la frecu queda cerrada sin anfitrión.
  void _giveUp() {
    _isClosed = true;
    _joined = false;
    _localParticipantId = null;
    unawaited(_foregroundService.stopService());
    unawaited(_clientSubscription?.cancel());
    _clientSubscription = null;
    unawaited(_client.disconnect());
    _setStatus(const RoomStatus.closed(reason: 'host_unreachable'));
    _succession.update(null);
    _setParticipants(const []);
  }
}

/// Frecu a la que volver al reconectar.
class _JoinTarget {
  const _JoinTarget({
    required this.uri,
    required this.host,
    required this.port,
    required this.accessCode,
    required this.displayName,
    this.peerId,
  });

  final Uri uri;
  final String host;
  final int port;
  final String accessCode;
  final String displayName;

  /// Lugar al que volver (su mismo id) en la frecu que tomó otro
  /// anfitrión; nulo para volver con un id nuevo.
  final String? peerId;

  /// La misma frecu en el servidor de quien la tomó, en [host] (y en
  /// [port], si cambia). Sin [host] (por internet), el mismo socket de
  /// invitado.
  _JoinTarget toward(String host, {int? port, String? peerId}) => host.isEmpty
      ? _JoinTarget(
          uri: uri,
          host: this.host,
          port: this.port,
          accessCode: accessCode,
          displayName: displayName,
          peerId: peerId,
        )
      : _JoinTarget(
          uri: Uri.parse('ws://$host:${port ?? this.port}'),
          host: host,
          port: port ?? this.port,
          accessCode: accessCode,
          displayName: displayName,
          peerId: peerId,
        );
}
