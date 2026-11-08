import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';

/// Datasource responsable de gestionar la malla de conexiones WebRTC peer-to-peer.
class PeerConnectionDataSource {
  /// Constructor con inyección de cliente de señalización y fábricas opcionales.
  PeerConnectionDataSource({
    required this.signalingClient,
    this.peerConnectionFactory,
    this.userMediaFactory,
  });

  /// Cliente WebSocket de señalización.
  final SignalingClientDataSource signalingClient;

  /// Fábrica de RTCPeerConnection para pruebas o personalización.
  final Future<RTCPeerConnection> Function(Map<String, dynamic> config)?
  peerConnectionFactory;

  /// Fábrica de MediaStream para captura de medios locales.
  final Future<MediaStream> Function(Map<String, dynamic> constraints)?
  userMediaFactory;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};
  final Map<String, bool> _hasRemoteDescription = {};

  MediaStream? _localStream;
  MediaStreamTrack? _localAudioTrack;
  String _localPeerId = '';
  StreamSubscription<SignalingMessage>? _signalingSub;

  /// Retorna las conexiones activas por par remoto.
  Map<String, RTCPeerConnection> get peerConnections =>
      Map.unmodifiable(_peerConnections);

  /// Indica si el micrófono local está actualmente habilitado.
  bool get isMicrophoneEnabled => _localAudioTrack?.enabled ?? false;

  /// Inicializa la captura local de audio y escucha mensajes de señalización.
  Future<void> initialize({required String localPeerId}) async {
    _localPeerId = localPeerId;
    await _setupLocalMedia();

    await _signalingSub?.cancel();
    _signalingSub = signalingClient.messages.listen(_handleSignalingMessage);
  }

  Future<void> _setupLocalMedia() async {
    const constraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };

    try {
      if (userMediaFactory != null) {
        _localStream = await userMediaFactory!(constraints);
      } else {
        _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      }

      final audioTracks = _localStream?.getAudioTracks();
      if (audioTracks != null && audioTracks.isNotEmpty) {
        _localAudioTrack = audioTracks.first;
        _localAudioTrack!.enabled = false;
      }
    } on Object catch (e, st) {
      AppLogger.w('Failed to acquire user media: $e\n$st');
    }
  }

  /// Establece o silencia el micrófono local y emite `talk_state`.
  void setMicrophoneEnabled({required bool enabled}) {
    if (_localAudioTrack != null) {
      _localAudioTrack!.enabled = enabled;
    }
    if (_localPeerId.isNotEmpty) {
      signalingClient.send(
        SignalingMessage.talkState(peerId: _localPeerId, isSpeaking: enabled),
      );
    }
  }

  /// Inicia conexión hacia un par remoto generando una oferta SDP.
  Future<void> connectToPeer(String remotePeerId) async {
    final pc = await _getOrCreatePeerConnection(remotePeerId);
    try {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      signalingClient.send(
        SignalingMessage.offer(
          from: _localPeerId,
          to: remotePeerId,
          sdp: offer.sdp ?? '',
        ),
      );
    } on Object catch (e, st) {
      AppLogger.e('Error creating offer for $remotePeerId', e, st);
    }
  }

  Future<RTCPeerConnection> _getOrCreatePeerConnection(
    String remotePeerId,
  ) async {
    final existing = _peerConnections[remotePeerId];
    if (existing != null) return existing;

    const config = <String, dynamic>{
      'iceServers': <Map<String, dynamic>>[],
      'sdpSemantics': 'unified-plan',
    };

    final pc = peerConnectionFactory != null
        ? await peerConnectionFactory!(config)
        : await createPeerConnection(config);

    _peerConnections[remotePeerId] = pc;
    _hasRemoteDescription[remotePeerId] = false;
    _pendingIceCandidates[remotePeerId] = [];

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        signalingClient.send(
          SignalingMessage.ice(
            from: _localPeerId,
            to: remotePeerId,
            candidate: candidate.candidate!,
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: candidate.sdpMLineIndex,
          ),
        );
      }
    };

    return pc;
  }

  void _handleSignalingMessage(SignalingMessage msg) {
    msg.when(
      offer: (from, to, sdp, _) => _handleOffer(from, sdp),
      answer: (from, to, sdp, _) => _handleAnswer(from, sdp),
      ice: (from, to, candidate, sdpMid, sdpMLineIndex, _) =>
          _handleIce(from, candidate, sdpMid, sdpMLineIndex),
      peerLeft: (peerId, _) => _closePeer(peerId),
      welcome: (_, __, ___, ____) {},
      rejected: (_, __) {},
      peerJoined: (_, __) {},
      talkState: (_, __, ___) {},
      ping: (_, __) {},
      pong: (_, __) {},
      roomClosed: (_, __) {},
      join: (_, __, ___, ____) {},
    );
  }

  Future<void> _handleOffer(String from, String sdp) async {
    final pc = await _getOrCreatePeerConnection(from);
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    _hasRemoteDescription[from] = true;
    await _flushPendingIce(from, pc);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    signalingClient.send(
      SignalingMessage.answer(
        from: _localPeerId,
        to: from,
        sdp: answer.sdp ?? '',
      ),
    );
  }

  Future<void> _handleAnswer(String from, String sdp) async {
    final pc = _peerConnections[from];
    if (pc != null) {
      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
      _hasRemoteDescription[from] = true;
      await _flushPendingIce(from, pc);
    }
  }

  Future<void> _handleIce(
    String from,
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    final rtcCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
    final pc = _peerConnections[from];
    final isReady = _hasRemoteDescription[from] ?? false;

    if (pc != null && isReady) {
      await pc.addCandidate(rtcCandidate);
    } else {
      _pendingIceCandidates[from] ??= [];
      _pendingIceCandidates[from]!.add(rtcCandidate);
    }
  }

  Future<void> _flushPendingIce(String peerId, RTCPeerConnection pc) async {
    final pending = _pendingIceCandidates[peerId];
    if (pending != null && pending.isNotEmpty) {
      for (final candidate in pending) {
        await pc.addCandidate(candidate);
      }
      pending.clear();
    }
  }

  void _closePeer(String peerId) {
    _peerConnections[peerId]?.close();
    _peerConnections.remove(peerId);
    _pendingIceCandidates.remove(peerId);
    _hasRemoteDescription.remove(peerId);
  }

  /// Cierra todas las conexiones activas y libera medios locales.
  Future<void> dispose() async {
    await _signalingSub?.cancel();
    _signalingSub = null;

    for (final pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    _pendingIceCandidates.clear();
    _hasRemoteDescription.clear();

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream?.dispose();
      _localStream = null;
    }
    _localAudioTrack = null;
  }
}
