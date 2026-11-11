import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';

/// Niveles de voz leídos de las conexiones, de 0 a 1: el propio (`local`) y
/// el recibido de cada par por su id (`peers`).
typedef VoiceLevels = ({double local, Map<String, double> peers});

/// Lo que dice el `getStats()` de un enlace sobre su calidad: el tiempo de ida
/// y vuelta del par de candidatos elegido, en milisegundos, y los contadores
/// acumulados de paquetes de audio recibidos y perdidos. Cada dato es nulo si
/// el informe no lo trae.
typedef LinkSample = ({double? rttMs, int? packetsReceived, int? packetsLost});

/// Datasource responsable de gestionar la malla de conexiones WebRTC
/// peer-to-peer de la frecu activa.
///
/// Escucha la señalización desde que se crea: lo que llega antes de saber el
/// id local se guarda y se atiende al fijarlo con [attach]. Los mensajes de
/// cada par se procesan en orden y sus errores se registran; los candidatos
/// ICE que llegan antes de la descripción remota se aplican después de ella.
/// Las offers y answers esperan a que se decida el micrófono
/// ([prepareMedia]) para llevar la pista local.
///
/// Un enlace que no conecta en [linkWaitLimit] (sin ruta de voz, p. ej.)
/// queda como caído en lugar de seguir «conectando» para siempre.
class PeerConnectionDataSource {
  /// Constructor con inyección de cliente de señalización y fábricas
  /// opcionales.
  PeerConnectionDataSource({
    required this.signalingClient,
    this.peerConnectionFactory,
    this.userMediaFactory,
    this.mediaWaitLimit = const Duration(seconds: 20),
    this.linkWaitLimit = const Duration(seconds: 15),
  }) {
    _signalingSub = signalingClient.messages.listen(
      _handleSignalingMessage,
      onError: (Object error) => AppLogger.w('Signaling error: $error'),
    );
  }

  /// Cliente WebSocket de señalización.
  final SignalingClientDataSource signalingClient;

  /// Fábrica de RTCPeerConnection para pruebas o personalización.
  final Future<RTCPeerConnection> Function(Map<String, dynamic> config)?
  peerConnectionFactory;

  /// Fábrica de MediaStream para captura de medios locales.
  final Future<MediaStream> Function(Map<String, dynamic> constraints)?
  userMediaFactory;

  /// Espera máxima a que se decida el micrófono antes de negociar sin él.
  final Duration mediaWaitLimit;

  /// Espera máxima a que un enlace conecte; después queda como caído (si
  /// conecta más tarde, vuelve a contar como conectado).
  final Duration linkWaitLimit;

  /// Servidores STUN y TURN de los enlaces nuevos: vacío en la red local
  /// (solo direcciones locales), con STUN y TURN en una frecu por internet.
  List<Map<String, dynamic>> iceServers = const [];

  Map<String, dynamic> get _config => {
    'iceServers': iceServers,
    'sdpSemantics': 'unified-plan',
  };

  static const Map<String, dynamic> _constraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': false,
  };

  /// Mensajes guardados mientras no hay id local.
  static const int _maxEarlyMessages = 256;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};
  final Set<String> _hasRemoteDescription = {};
  final Map<String, Future<void>> _queues = {};
  final Map<String, int> _peerEpochs = {};
  final List<SignalingMessage> _early = [];
  final Map<String, PeerConnectionState> _links = {};
  final Map<String, Timer> _linkTimers = {};
  final StreamController<Map<String, PeerConnectionState>> _linksController =
      StreamController<Map<String, PeerConnectionState>>.broadcast();

  MediaStream? _localStream;
  MediaStreamTrack? _localAudioTrack;
  Future<void>? _media;
  Completer<void> _mediaSettled = Completer<void>();
  int _mediaEpoch = 0;
  bool _microphoneEnabled = false;
  String _localPeerId = '';
  int _generation = 0;

  /// Ya hubo una frecu: después de salir, lo que llegue sin id local es de
  /// la anterior y no se guarda.
  bool _attachedOnce = false;
  StreamSubscription<SignalingMessage>? _signalingSub;

  /// Retorna las conexiones activas por par remoto.
  Map<String, RTCPeerConnection> get peerConnections =>
      Map.unmodifiable(_peerConnections);

  /// Indica si el micrófono local está actualmente habilitado.
  bool get isMicrophoneEnabled => _localAudioTrack?.enabled ?? false;

  /// Hay pista de micrófono capturada en esta frecu.
  bool get hasMicrophone => _localAudioTrack != null;

  /// Id local en la frecu activa; vacío sin frecu.
  String get localPeerId => _localPeerId;

  /// Estado del enlace con cada par remoto.
  Map<String, PeerConnectionState> get links => Map.unmodifiable(_links);

  /// Cada cambio de [links].
  Stream<Map<String, PeerConnectionState>> get linkChanges =>
      _linksController.stream;

  /// Fija el id local de la frecu: desde aquí atiende offers, answers e ICE
  /// dirigidos a [localPeerId], incluidos los que llegaron antes. Con otro
  /// id (al reconectar) cierra antes los enlaces del id anterior.
  void attach(String localPeerId) {
    if (localPeerId.isEmpty || localPeerId == _localPeerId) return;
    if (_localPeerId.isNotEmpty) _closeAllPeers();
    _localPeerId = localPeerId;
    _attachedOnce = true;
    final early = List<SignalingMessage>.of(_early);
    _early.clear();
    early.forEach(_handleSignalingMessage);
  }

  /// Decide el micrófono de esta frecu, una sola vez: con [capture] lo
  /// captura (silenciado); sin él la malla solo escucha.
  Future<void> prepareMedia({required bool capture}) {
    final media = _media ??= capture ? _setupLocalMedia() : Future.value();
    return media.whenComplete(() {
      if (!_mediaSettled.isCompleted) _mediaSettled.complete();
    });
  }

  Future<void> _setupLocalMedia() async {
    final epoch = _mediaEpoch;
    try {
      final stream = userMediaFactory != null
          ? await userMediaFactory!(_constraints)
          : await navigator.mediaDevices.getUserMedia(_constraints);
      if (epoch != _mediaEpoch) {
        await _release(stream);
        return;
      }
      _localStream = stream;
      final audioTracks = stream.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        _localAudioTrack = audioTracks.first..enabled = _microphoneEnabled;
      }
    } on Object catch (e, st) {
      AppLogger.w('Failed to acquire user media: $e\n$st');
    }
  }

  Future<void> _waitForMedia() async {
    if (_mediaSettled.isCompleted) return;
    await _mediaSettled.future.timeout(
      mediaWaitLimit,
      onTimeout: () => AppLogger.w('Negotiating without a microphone decision'),
    );
  }

  /// Habilita o silencia la pista local y, con [announce], emite
  /// `talk_state` ([muted] si se silenció en micrófono abierto).
  void setMicrophoneEnabled({
    required bool enabled,
    bool muted = false,
    bool announce = true,
  }) {
    _microphoneEnabled = enabled;
    _localAudioTrack?.enabled = enabled;
    if (announce) announceTalkState(speaking: enabled, muted: muted);
  }

  /// Emite el estado de habla propio sin tocar la pista.
  void announceTalkState({required bool speaking, bool muted = false}) {
    if (_localPeerId.isEmpty) return;
    signalingClient.send(
      SignalingMessage.talkState(
        peerId: _localPeerId,
        isSpeaking: speaking,
        muted: muted ? true : null,
      ),
    );
  }

  /// Lee a la vez el `getStats()` de cada conexión: el `audioLevel` del
  /// informe `media-source` de audio es el nivel propio (el mayor de todas) y
  /// el del `inbound-rtp` de audio, el del par. Una conexión que falla se
  /// salta; sin conexiones el nivel propio es 0.
  Future<VoiceLevels> readVoiceLevels() async {
    final reads = await Future.wait([
      for (final MapEntry(key: id, value: pc) in _peerConnections.entries)
        _statsOf(id, pc),
    ]);
    var local = 0.0;
    final peers = <String, double>{};
    for (final (id, reports) in reads) {
      for (final report in reports) {
        final level = _audioLevel(report);
        if (level == null) continue;
        switch (report.type) {
          case 'media-source':
            local = math.max(local, level);
          case 'inbound-rtp':
            peers[id] = math.max(peers[id] ?? 0, level);
        }
      }
    }
    return (local: local, peers: peers);
  }

  /// Lee a la vez el `getStats()` de cada conexión y devuelve, por par, su
  /// [LinkSample]: el `currentRoundTripTime` del `candidate-pair` elegido
  /// (`succeeded` y nominado) y los `packetsReceived`/`packetsLost` de su
  /// `inbound-rtp` de audio. Una conexión que falla se salta.
  Future<Map<String, LinkSample>> readLinkStats() async {
    final reads = await Future.wait([
      for (final MapEntry(key: id, value: pc) in _peerConnections.entries)
        _statsOf(id, pc),
    ]);
    return {
      for (final (id, reports) in reads)
        if (reports.isNotEmpty) id: linkSampleOf(reports),
    };
  }

  /// [LinkSample] de los informes de un enlace.
  static LinkSample linkSampleOf(List<StatsReport> reports) {
    double? rttMs;
    int? received;
    int? lost;
    for (final report in reports) {
      final values = report.values;
      switch (report.type) {
        case 'candidate-pair'
            when values['state'] == 'succeeded' && values['nominated'] != false:
          final rtt = values['currentRoundTripTime'];
          if (rtt is num) rttMs = math.max(rttMs ?? 0, rtt * 1000);
        case 'inbound-rtp'
            when (values['kind'] ?? values['mediaType']) == 'audio':
          final r = values['packetsReceived'];
          final l = values['packetsLost'];
          if (r is num) received = (received ?? 0) + r.toInt();
          if (l is num) lost = (lost ?? 0) + l.toInt();
      }
    }
    return (rttMs: rttMs, packetsReceived: received, packetsLost: lost);
  }

  Future<(String, List<StatsReport>)> _statsOf(
    String peerId,
    RTCPeerConnection pc,
  ) async {
    try {
      return (peerId, await pc.getStats());
    } on Object catch (e) {
      AppLogger.d('getStats failed for $peerId: $e');
      return (peerId, const <StatsReport>[]);
    }
  }

  /// `audioLevel` de un informe de audio, entre 0 y 1, o nulo si no lo es.
  static double? _audioLevel(StatsReport report) {
    final values = report.values;
    if ((values['kind'] ?? values['mediaType']) != 'audio') return null;
    final level = values['audioLevel'];
    return level is num ? level.toDouble().clamp(0, 1).toDouble() : null;
  }

  /// Inicia conexión hacia un par remoto generando una oferta SDP.
  Future<void> connectToPeer(String remotePeerId) {
    return _enqueue(remotePeerId, (token) async {
      final pc = await _peerConnectionFor(remotePeerId, token);
      if (pc == null) return;
      final offer = await pc.createOffer();
      if (!token.isCurrent) return;
      await pc.setLocalDescription(offer);
      if (!token.isCurrent) return;
      signalingClient.send(
        SignalingMessage.offer(
          from: _localPeerId,
          to: remotePeerId,
          sdp: offer.sdp ?? '',
        ),
      );
    });
  }

  /// Encola [task] tras lo pendiente de [peerId]; lo que falle se registra.
  Future<void> _enqueue(
    String peerId,
    Future<void> Function(_PeerToken token) task,
  ) {
    final token = _PeerToken(this, peerId);
    final previous = _queues[peerId] ?? Future<void>.value();
    final next = previous.then((_) async {
      if (!token.isCurrent) return;
      try {
        await task(token);
      } on Object catch (e, st) {
        AppLogger.w('WebRTC negotiation with $peerId failed: $e', e, st);
      }
    });
    _queues[peerId] = next;
    return next;
  }

  Future<RTCPeerConnection?> _peerConnectionFor(
    String remotePeerId,
    _PeerToken token,
  ) async {
    final existing = _peerConnections[remotePeerId];
    if (existing != null) return existing;

    await _waitForMedia();
    if (!token.isCurrent) return null;

    final pc = peerConnectionFactory != null
        ? await peerConnectionFactory!(_config)
        : await createPeerConnection(_config);
    if (!token.isCurrent) {
      unawaited(_closeQuietly(pc));
      return null;
    }

    _peerConnections[remotePeerId] = pc;
    _setLink(remotePeerId, PeerConnectionState.connecting);

    pc
      ..onIceCandidate = (candidate) {
        final value = candidate.candidate;
        if (value == null || !identical(_peerConnections[remotePeerId], pc)) {
          return;
        }
        signalingClient.send(
          SignalingMessage.ice(
            from: _localPeerId,
            to: remotePeerId,
            candidate: value,
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: candidate.sdpMLineIndex,
          ),
        );
      }
      ..onIceConnectionState = (state) {
        if (!identical(_peerConnections[remotePeerId], pc)) return;
        final link = _linkOf(state);
        if (link != null) _setLink(remotePeerId, link);
      };

    final stream = _localStream;
    final tracks = stream?.getTracks() ?? const <MediaStreamTrack>[];
    if (stream != null && tracks.isNotEmpty) {
      for (final track in tracks) {
        await pc.addTrack(track, stream);
      }
    } else {
      // Sin micrófono la malla igual escucha: sin ninguna sección de medios
      // la oferta no arrancaría ICE.
      try {
        await pc.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
          init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
        );
      } on Object catch (e) {
        AppLogger.w('Could not add a receive-only audio transceiver: $e');
      }
    }
    return pc;
  }

  static PeerConnectionState? _linkOf(RTCIceConnectionState state) =>
      switch (state) {
        RTCIceConnectionState.RTCIceConnectionStateNew ||
        RTCIceConnectionState.RTCIceConnectionStateChecking =>
          PeerConnectionState.connecting,
        RTCIceConnectionState.RTCIceConnectionStateConnected ||
        RTCIceConnectionState.RTCIceConnectionStateCompleted =>
          PeerConnectionState.connected,
        RTCIceConnectionState.RTCIceConnectionStateDisconnected =>
          PeerConnectionState.reconnecting,
        RTCIceConnectionState.RTCIceConnectionStateFailed ||
        RTCIceConnectionState.RTCIceConnectionStateClosed =>
          PeerConnectionState.disconnected,
        RTCIceConnectionState.RTCIceConnectionStateCount => null,
      };

  void _handleSignalingMessage(SignalingMessage msg) {
    switch (msg) {
      case SignalingOfferMessage(:final from, :final to, :final sdp):
        if (!_isForMe(msg, to)) return;
        unawaited(_enqueue(from, (token) => _handleOffer(from, sdp, token)));
      case SignalingAnswerMessage(:final from, :final to, :final sdp):
        if (!_isForMe(msg, to)) return;
        unawaited(_enqueue(from, (token) => _handleAnswer(from, sdp, token)));
      case SignalingIceMessage(
        :final from,
        :final to,
        :final candidate,
        :final sdpMid,
        :final sdpMLineIndex,
      ):
        if (!_isForMe(msg, to)) return;
        final ice = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
        unawaited(_enqueue(from, (token) => _handleIce(from, ice)));
      case SignalingPeerLeftMessage(:final peerId):
        _closePeer(peerId);
      default:
        // El resto de la señalización no toca la malla.
        break;
    }
  }

  /// Si el mensaje va dirigido al id local; sin id aún (antes de la
  /// primera frecu), lo guarda para atenderlo al fijarlo.
  bool _isForMe(SignalingMessage msg, String to) {
    if (_localPeerId.isEmpty) {
      if (!_attachedOnce && _early.length < _maxEarlyMessages) _early.add(msg);
      return false;
    }
    return to == _localPeerId;
  }

  Future<void> _handleOffer(String from, String sdp, _PeerToken token) async {
    final pc = await _peerConnectionFor(from, token);
    if (pc == null) return;
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    if (!token.isCurrent) return;
    _hasRemoteDescription.add(from);
    await _flushPendingIce(from, pc);

    final answer = await pc.createAnswer();
    if (!token.isCurrent) return;
    await pc.setLocalDescription(answer);
    if (!token.isCurrent) return;

    signalingClient.send(
      SignalingMessage.answer(
        from: _localPeerId,
        to: from,
        sdp: answer.sdp ?? '',
      ),
    );
  }

  Future<void> _handleAnswer(String from, String sdp, _PeerToken token) async {
    final pc = _peerConnections[from];
    if (pc == null) return;
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    if (!token.isCurrent) return;
    _hasRemoteDescription.add(from);
    await _flushPendingIce(from, pc);
  }

  Future<void> _handleIce(String from, RTCIceCandidate candidate) async {
    final pc = _peerConnections[from];
    if (pc != null && _hasRemoteDescription.contains(from)) {
      await pc.addCandidate(candidate);
    } else {
      (_pendingIceCandidates[from] ??= []).add(candidate);
    }
  }

  Future<void> _flushPendingIce(String peerId, RTCPeerConnection pc) async {
    final pending = _pendingIceCandidates.remove(peerId);
    if (pending == null) return;
    for (final candidate in pending) {
      try {
        await pc.addCandidate(candidate);
      } on Object catch (e) {
        AppLogger.w('Could not apply an early ICE candidate from $peerId: $e');
      }
    }
  }

  /// Cierra solo el enlace con [peerId] (p. ej. el anfitrión que se fue en
  /// un traspaso); los demás siguen como están.
  void closePeer(String peerId) {
    if (peerId.isEmpty || peerId == _localPeerId) return;
    _closePeer(peerId);
  }

  void _closePeer(String peerId) {
    _peerEpochs[peerId] = (_peerEpochs[peerId] ?? 0) + 1;
    _linkTimers.remove(peerId)?.cancel();
    _queues.remove(peerId);
    _pendingIceCandidates.remove(peerId);
    _hasRemoteDescription.remove(peerId);
    final pc = _peerConnections.remove(peerId);
    if (pc != null) unawaited(_closeQuietly(pc));
    if (_links.remove(peerId) != null) _emitLinks();
  }

  /// Cierra todos los enlaces; lo que estaba en curso se descarta.
  List<Future<void>> _closeAllPeers() {
    _generation++;
    for (final timer in _linkTimers.values) {
      timer.cancel();
    }
    _linkTimers.clear();
    final closing = [
      for (final pc in _peerConnections.values) _closeQuietly(pc),
    ];
    _peerConnections.clear();
    _queues.clear();
    _peerEpochs.clear();
    _pendingIceCandidates.clear();
    _hasRemoteDescription.clear();
    if (_links.isNotEmpty) {
      _links.clear();
      _emitLinks();
    }
    return closing;
  }

  static Future<void> _closeQuietly(RTCPeerConnection pc) async {
    try {
      await pc.close();
    } on Object catch (e) {
      AppLogger.w('Could not close a peer connection: $e');
    }
  }

  static Future<void> _release(MediaStream stream) async {
    for (final track in stream.getTracks()) {
      try {
        await track.stop();
      } on Object catch (e) {
        AppLogger.w('Could not stop a local track: $e');
      }
    }
    try {
      await stream.dispose();
    } on Object catch (e) {
      AppLogger.w('Could not dispose the local stream: $e');
    }
  }

  /// Mientras el enlace con [peerId] está conectando corre su espera
  /// ([linkWaitLimit]); cualquier otro estado la cancela.
  void _setLink(String peerId, PeerConnectionState state) {
    if (state == PeerConnectionState.connecting) {
      _linkTimers[peerId] ??= Timer(linkWaitLimit, () => _linkTimedOut(peerId));
    } else {
      _linkTimers.remove(peerId)?.cancel();
    }
    if (_links[peerId] == state) return;
    _links[peerId] = state;
    _emitLinks();
  }

  /// El enlace con [peerId] no conectó a tiempo: sin ruta de voz (p. ej. ICE
  /// sin pares) se quedaría «conectando» para siempre y bloquearía la frecu.
  void _linkTimedOut(String peerId) {
    _linkTimers.remove(peerId);
    if (_links[peerId] != PeerConnectionState.connecting) return;
    AppLogger.w('Voice link with $peerId did not connect in $linkWaitLimit');
    _links[peerId] = PeerConnectionState.disconnected;
    _emitLinks();
  }

  void _emitLinks() {
    if (!_linksController.isClosed) {
      _linksController.add(Map.unmodifiable(_links));
    }
  }

  /// Sale de la frecu: cierra todos los enlaces, para y suelta el micrófono
  /// y olvida el id local, para que la próxima frecu empiece de cero.
  Future<void> reset() async {
    final closing = _closeAllPeers();
    _early.clear();
    _localPeerId = '';
    _microphoneEnabled = false;
    _mediaEpoch++;
    _media = null;
    if (!_mediaSettled.isCompleted) _mediaSettled.complete();
    _mediaSettled = Completer<void>();
    final stream = _localStream;
    _localStream = null;
    _localAudioTrack = null;
    // Primero el micrófono: que deje de capturar cuanto antes.
    if (stream != null) await _release(stream);
    await Future.wait(closing);
  }

  /// Cierra todas las conexiones activas y libera medios locales.
  Future<void> dispose() async {
    await _signalingSub?.cancel();
    _signalingSub = null;
    await reset();
    await _linksController.close();
  }
}

/// Vigencia de una tarea de negociación con un par: deja de valer si la
/// malla se reinicia o si ese par sale.
class _PeerToken {
  _PeerToken(this._owner, this._peerId)
    : _generation = _owner._generation,
      _epoch = _owner._peerEpochs[_peerId] ?? 0;

  final PeerConnectionDataSource _owner;
  final String _peerId;
  final int _generation;
  final int _epoch;

  bool get isCurrent =>
      _generation == _owner._generation &&
      _epoch == (_owner._peerEpochs[_peerId] ?? 0);
}
