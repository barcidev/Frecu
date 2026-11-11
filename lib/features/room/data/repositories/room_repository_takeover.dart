part of 'room_repository_impl.dart';

/// Traspaso de la frecu: ceder ante un rival, seguir un `host_handover` y
/// tomar la frecu.
extension _Takeover on RoomRepositoryImpl {
  /// Como anfitrión, empieza a preguntar si otro lleva la frecu; si acaba
  /// de ceder la suya, avisa quién la lleva.
  void _afterWelcome(String me, List<Participant> participants) {
    if (_isHost) {
      _probe.start(
        state: () => _succession.current,
        me: me,
        serverPort: _server.port,
        onRival: _onRival,
      );
    }
    final rival = _outranked;
    if (rival == null || _isHost) return;
    _outranked = null;
    final host = participants.where((p) => p.isHost).firstOrNull;
    _takeover
      ..forget()
      ..announce(
        hostId: host?.id ?? rival.host,
        hostName: host?.displayName ?? '',
        you: false,
        reason: HostChangeReason.outranked,
        hostAddress: rival.address,
        port: rival.port,
      );
  }

  void _onRival(HostRival rival) => unawaited(_yieldTo(rival));

  /// Por internet, la nube rechazó el relé de este teléfono: otro lleva la
  /// frecu con un turno mayor, y se le cede por el mismo socket de invitado.
  void _onRelayOutranked() => unawaited(
    _yieldTo(const HostRival(host: '', term: 0, address: '', port: 0)),
  );

  /// Otro teléfono lleva esta frecu con traspaso con un turno que gana
  /// ([rival]): le cede la frecu y vuelve a ella como invitado, como quien
  /// sigue un `host_handover`. En local, sus invitados van al rival; por
  /// internet ya volvieron solos a la nube, y él vuelve por el socket de
  /// invitado.
  Future<void> _yieldTo(HostRival rival) async {
    final state = _succession.current;
    final me = _participants
        .where((p) => p.id == _localParticipantId)
        .firstOrNull;
    final back = _yieldUri(state, rival);
    if (!_isHost || _outranked != null || me == null || back == null) return;
    final session = _session;
    _outranked = rival;
    _probe.stop();
    unawaited(_clientSubscription?.cancel());
    _clientSubscription = null;
    await _release(rival, internet: state!.reach == RoomReach.internet);
    if (session != _session) return;
    _isHost = false;
    _following = true;
    _target = _JoinTarget(
      uri: back,
      host: rival.address,
      port: rival.port,
      accessCode: state.accessCode,
      displayName: me.displayName,
      peerId: me.id,
    );
    await _client.disconnect();
    _handleClientConnectionChange(false);
  }

  /// A dónde vuelve como invitado quien cede la frecu de [state] a [rival]:
  /// en local, al servidor del rival; por internet, al socket de invitado.
  /// Nulo si la frecu no admite traspaso.
  Uri? _yieldUri(RoomSuccession? state, HostRival rival) {
    if (state == null || !state.handover) return null;
    if (state.reach == RoomReach.local) {
      return Uri.parse('ws://${rival.address}:${rival.port}');
    }
    final internetId = _internetId;
    return internetId == null ? null : cloudConfig.guestSocket(internetId);
  }

  /// Suelta la frecu que cede a [rival]: en local, sus invitados van al
  /// rival; por internet ya volvieron solos a la nube.
  Future<void> _release(HostRival rival, {required bool internet}) async {
    if (!internet) return _server.yieldTo(rival);
    await _relay.stop();
    await _server.stop();
  }

  /// El anfitrión pasa la frecu a `to`: si es este teléfono, la toma; si
  /// no, la reconexión apunta a la IP de `to` (o a la `address` y el `port`
  /// del mensaje, si vienen) con el mismo id.
  void _onHostHandover(int session, SignalingHostHandoverMessage message) {
    // El anfitrión que pasa la frecu ya sale: no sigue a nadie.
    if (_isHost) return;
    final SignalingHostHandoverMessage(:to, :term) = message;
    final state = _succession.current;
    final target = _target;
    final heir = state?.members.where((m) => m.id == to).firstOrNull;
    // Por internet se sigue a quien la recibe por el mismo socket.
    final address = state?.reach == RoomReach.internet
        ? ''
        : message.address ?? heir?.address;
    if (state == null || target == null || address == null) return;
    final host = _participants.where((p) => p.isHost).firstOrNull;
    _takeover.previousHost = host?.displayName;
    if (to != _localParticipantId) {
      _following = true;
      _target = target.toward(
        address,
        port: message.port,
        peerId: _localParticipantId,
      );
      return;
    }
    unawaited(
      _takeOver(
        session,
        state: state,
        term: term,
        address: address,
        previousHostId: host?.id ?? state.order.first,
        target: target,
      ),
    );
  }

  /// Este teléfono toma la frecu de [state]: deja de reconectar, abre el
  /// servidor con el turno [term] y vuelve a su mismo lugar como anfitrión;
  /// [reason] dice si se la pasaron al salir o si se cayó el anterior.
  Future<void> _takeOver(
    int session, {
    required RoomSuccession state,
    required int term,
    required String address,
    required String previousHostId,
    required _JoinTarget target,
    HostChangeReason reason = HostChangeReason.left,
  }) async {
    final me = _localParticipantId;
    if (me == null) return;
    _isHost = true;
    _target = null;
    unawaited(_clientSubscription?.cancel());
    _clientSubscription = null;
    try {
      await _client.disconnect();
      await HostTakeover.openServer(
        _server,
        state: state,
        me: me,
        previousHostId: previousHostId,
        address: address,
        term: term,
        port: target.port,
        reason: reason,
      );
      if (state.reach == RoomReach.internet) {
        await InternetHandover.openRelay(
          _relay,
          cloudConfig,
          state: state,
          term: term,
          onGuest: _server.accept,
        );
      }
      if (session != _session) return;
      await _client.connect(Uri.parse('ws://127.0.0.1:${_server.port}'));
      await _rejoinAsHost(session, me, state, address, target, reason);
    } on Object catch (e, st) {
      if (session != _session) return;
      if (await _joinAsGuestIfRefused(e, state, me, target)) return;
      AppLogger.e('Could not take over the room', e, st);
      _giveUp();
      unawaited(_server.stop());
    }
  }

  /// Si [error] es el rechazo (409) de la nube al relé con que este
  /// teléfono tomaba la frecu por internet de [state], otro ya la lleva con
  /// un turno mayor: cierra el servidor que acababa de abrir, vuelve como
  /// invitado ([me]) por el socket de invitado y, al llegar el `welcome`,
  /// avisa quién la lleva. `false` si es otro fallo.
  Future<bool> _joinAsGuestIfRefused(
    Object error,
    RoomSuccession state,
    String me,
    _JoinTarget target,
  ) async {
    final internetId = _internetId;
    if (state.reach != RoomReach.internet ||
        internetId == null ||
        !CloudRelayDataSource.isOutranked(error)) {
      return false;
    }
    AppLogger.i('Another host leads the room: joining as a guest');
    await _relay.stop();
    await _server.stop();
    _isHost = false;
    _following = true;
    _outranked = const HostRival(host: '', term: 0, address: '', port: 0);
    _target = _JoinTarget(
      uri: cloudConfig.guestSocket(internetId),
      host: '',
      port: target.port,
      accessCode: state.accessCode,
      displayName: target.displayName,
      peerId: me,
    );
    _handleClientConnectionChange(false);
    return true;
  }

  /// Vuelve como anfitrión a su mismo lugar ([me]) en el servidor que acaba
  /// de abrir, y avisa que lleva la frecu.
  Future<void> _rejoinAsHost(
    int session,
    String me,
    RoomSuccession state,
    String address,
    _JoinTarget target,
    HostChangeReason reason,
  ) async {
    final result = await _join(
      session,
      displayName: target.displayName,
      accessCode: state.accessCode,
      hostAddress: address,
      port: _server.port,
      peerId: me,
    );
    if (session != _session) return;
    if (result.isFailure) throw StateError('No welcome after the takeover');
    _takeover.announce(
      hostId: me,
      hostName: target.displayName,
      you: true,
      reason: reason,
      hostAddress: address,
      port: _server.port,
    );
  }

  /// Quien tomó la frecu ([host]) avisa al volver a ella.
  void _onHostChanged(String host, String reason) {
    final target = _target;
    // El anfitrión que pasó la frecu ya sale: no sigue a nadie.
    if (_isHost || target == null) return;
    final person = _participants.where((p) => p.id == host).firstOrNull;
    _takeover.announce(
      hostId: host,
      hostName: person?.displayName ?? '',
      you: false,
      reason: reason == 'lost' ? HostChangeReason.lost : HostChangeReason.left,
      hostAddress: target.host,
      port: target.port,
    );
  }
}
