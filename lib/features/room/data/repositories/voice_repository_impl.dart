import 'dart:async';

import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:permission_handler/permission_handler.dart';

/// Implementación concreta de [VoiceRepository].
class VoiceRepositoryImpl implements VoiceRepository {
  /// Constructor con inyección de datasources y requester de permisos.
  VoiceRepositoryImpl({
    required AudioSessionDataSource audioSessionDataSource,
    required PeerConnectionDataSource peerConnectionDataSource,
    required SignalingClientDataSource signalingClientDataSource,
    Future<bool> Function()? permissionRequester,
  }) : _audioSession = audioSessionDataSource,
       _peerConnection = peerConnectionDataSource,
       _signalingClient = signalingClientDataSource,
       _permissionRequester =
           permissionRequester ?? _defaultPermissionRequester {
    _signalingSubscription = _signalingClient.messages.listen(
      _handleSignalingMessage,
    );
  }

  final AudioSessionDataSource _audioSession;
  final PeerConnectionDataSource _peerConnection;
  final SignalingClientDataSource _signalingClient;
  final Future<bool> Function() _permissionRequester;

  StreamSubscription<SignalingMessage>? _signalingSubscription;
  final StreamController<bool> _isTalkingController =
      StreamController<bool>.broadcast();
  final StreamController<Set<String>> _speakingPeersController =
      StreamController<Set<String>>.broadcast();
  final StreamController<TalkMode> _talkModeController =
      StreamController<TalkMode>.broadcast();

  final Set<String> _speakingPeers = {};
  TalkMode _talkMode = TalkMode.pushToTalk;
  bool _isTalking = false;
  String _localPeerId = '';

  static Future<bool> _defaultPermissionRequester() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<Result<void>> initializeAudio({String? localPeerId}) async {
    try {
      final granted = await _permissionRequester();
      if (!granted) {
        return const Result.failure(
          Failure.permissionDenied(permission: 'microphone'),
        );
      }

      await _audioSession.activate();

      if (localPeerId != null && localPeerId.isNotEmpty) {
        _localPeerId = localPeerId;
        await _peerConnection.initialize(localPeerId: _localPeerId);
      }

      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Failed to initialize audio', e, st);
      return Result.failure(Failure.audio(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> startTalking() async {
    try {
      _isTalking = true;
      _peerConnection.setMicrophoneEnabled(enabled: true);
      _isTalkingController.add(true);
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error starting voice transmission', e, st);
      return Result.failure(Failure.audio(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> stopTalking() async {
    try {
      _isTalking = false;
      _peerConnection.setMicrophoneEnabled(enabled: false);
      _isTalkingController.add(false);
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error stopping voice transmission', e, st);
      return Result.failure(Failure.audio(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> setTalkMode(TalkMode mode) async {
    try {
      _talkMode = mode;
      _talkModeController.add(mode);
      if (mode == TalkMode.pushToTalk && _isTalking) {
        await stopTalking();
      }
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error changing talk mode', e, st);
      return Result.failure(Failure.audio(message: e.toString()));
    }
  }

  @override
  Stream<bool> watchIsTalking() async* {
    yield _isTalking;
    yield* _isTalkingController.stream;
  }

  @override
  Stream<Set<String>> watchSpeakingPeers() async* {
    yield Set<String>.from(_speakingPeers);
    yield* _speakingPeersController.stream;
  }

  @override
  Stream<TalkMode> watchTalkMode() async* {
    yield _talkMode;
    yield* _talkModeController.stream;
  }

  void _handleSignalingMessage(SignalingMessage msg) {
    msg.when(
      welcome: (peerId, participants, _) =>
          _handleWelcome(peerId, participants),
      talkState: (peerId, isSpeaking, _) =>
          _handleTalkState(peerId, isSpeaking),
      peerLeft: (peerId, _) => _handlePeerLeft(peerId),
      roomClosed: (reason, _) => _handleRoomClosed(),
      offer: (_, __, ___, ____) {},
      answer: (_, __, ___, ____) {},
      ice: (_, __, ___, ____, _____, ______) {},
      peerJoined: (_, __) {},
      ping: (_, __) {},
      pong: (_, __) {},
      join: (_, __, ___, ____) {},
      rejected: (_, __) {},
    );
  }

  Future<void> _handleWelcome(
    String peerId,
    List<Participant> participants,
  ) async {
    _localPeerId = peerId;
    await _peerConnection.initialize(localPeerId: peerId);

    for (final participant in participants) {
      if (participant.id != peerId) {
        await _peerConnection.connectToPeer(participant.id);
      }
    }
  }

  void _handleTalkState(String peerId, bool isSpeaking) {
    if (isSpeaking) {
      _speakingPeers.add(peerId);
    } else {
      _speakingPeers.remove(peerId);
    }
    _speakingPeersController.add(Set<String>.from(_speakingPeers));
  }

  void _handlePeerLeft(String peerId) {
    if (_speakingPeers.remove(peerId)) {
      _speakingPeersController.add(Set<String>.from(_speakingPeers));
    }
  }

  void _handleRoomClosed() {
    _speakingPeers.clear();
    _speakingPeersController.add({});
    if (_isTalking) {
      _isTalking = false;
      _peerConnection.setMicrophoneEnabled(enabled: false);
      _isTalkingController.add(false);
    }
  }

  @override
  Future<void> dispose() async {
    await _signalingSubscription?.cancel();
    _signalingSubscription = null;
    await _peerConnection.dispose();
    await _audioSession.deactivate();
    await _isTalkingController.close();
    await _speakingPeersController.close();
    await _talkModeController.close();
  }
}
