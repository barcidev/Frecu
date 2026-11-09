import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/current_then.dart';
import 'package:frecu/features/room/data/repositories/voice_level_sampler.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:permission_handler/permission_handler.dart';

/// Implementación concreta de [VoiceRepository].
///
/// La voz se une a la malla con [joinMesh] (lo llama quien crea o se une a
/// la frecu, y también el `welcome` que llegue mientras este repositorio
/// existe, p. ej. al reconectar) y sale con [leaveMesh]. Sin anfitrión
/// (señalización caída) deja de transmitir y, al volver, retoma el
/// micrófono abierto si estaba abierto.
class VoiceRepositoryImpl implements VoiceRepository {
  /// Constructor con inyección de datasources y requester de permisos;
  /// [isAndroid] se inyecta en pruebas.
  VoiceRepositoryImpl({
    required AudioSessionDataSource audioSessionDataSource,
    required PeerConnectionDataSource peerConnectionDataSource,
    required SignalingClientDataSource signalingClientDataSource,
    Future<bool> Function()? permissionRequester,
    Future<bool> Function()? settingsOpener,
    bool? isAndroid,
  }) : _audioSession = audioSessionDataSource,
       _peerConnection = peerConnectionDataSource,
       _signalingClient = signalingClientDataSource,
       _permissionRequester =
           permissionRequester ?? _defaultPermissionRequester,
       _settingsOpener = settingsOpener ?? openAppSettings,
       _isAndroid = isAndroid ?? Platform.isAndroid {
    _signalingSubscription = _signalingClient.messages.listen(
      _handleSignalingMessage,
      onError: _logStreamError,
    );
    _connectionSubscription = _signalingClient.connectionState.listen(
      _handleConnectionChange,
      onError: _logStreamError,
    );
    _devicesSubscription = _audioSession.devicesStream.listen(
      _handleAudioDevicesChanged,
      onError: _logStreamError,
    );
    // En Android, audioswitch elige salida por su cuenta (un Bluetooth antes
    // que el altavoz) y descarta la que se pide antes de ver los
    // dispositivos: cada vez que cambia, vuelve la ruta elegida.
    if (_isAndroid) {
      _webRtcDevicesSubscription = _audioSession.webRtcDeviceChanges.listen(
        (_) => _reapplyRouteSoon(),
        onError: _logStreamError,
      );
    }
  }

  final AudioSessionDataSource _audioSession;
  final PeerConnectionDataSource _peerConnection;
  final SignalingClientDataSource _signalingClient;
  final Future<bool> Function() _permissionRequester;
  final Future<bool> Function() _settingsOpener;
  final bool _isAndroid;
  late final VoiceLevelSampler _levels = VoiceLevelSampler(
    _peerConnection.readVoiceLevels,
  );

  StreamSubscription<SignalingMessage>? _signalingSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Set<AudioDevice>>? _devicesSubscription;
  StreamSubscription<void>? _webRtcDevicesSubscription;
  Timer? _reapplyRoute;

  final StreamController<bool> _isTalkingController =
      StreamController<bool>.broadcast();
  final StreamController<Set<String>> _speakingPeersController =
      StreamController<Set<String>>.broadcast();
  final StreamController<Set<String>> _mutedPeersController =
      StreamController<Set<String>>.broadcast();
  final StreamController<TalkMode> _talkModeController =
      StreamController<TalkMode>.broadcast();
  final StreamController<AudioRoute> _audioRouteController =
      StreamController<AudioRoute>.broadcast();
  final StreamController<Set<AudioRoute>> _availableRoutesController =
      StreamController<Set<AudioRoute>>.broadcast();
  final StreamController<String?> _bluetoothNameController =
      StreamController<String?>.broadcast();

  Set<String> _speakingPeers = const {};
  Set<String> _mutedPeers = const {};
  TalkMode _talkMode = TalkMode.pushToTalk;
  AudioRoute _activeAudioRoute = AudioRoute.speaker;
  Set<AudioRoute> _availableAudioRoutes = const {
    AudioRoute.speaker,
    AudioRoute.earpiece,
  };
  String? _bluetoothName;
  bool _isTalking = false;

  /// Id con el que la voz está en la malla; nulo fuera de una frecu.
  String? _meshPeerId;

  /// Permiso, sesión de audio y micrófono de la frecu, una sola vez.
  Future<Result<void>>? _audio;

  /// Sube al salir de la frecu: lo que estaba en curso se descarta.
  int _epoch = 0;

  /// El micrófono abierto se cortó al perder al anfitrión.
  bool _resumeOpenMic = false;

  bool _devicesKnown = false;
  bool _hadBluetooth = false;
  bool _hadWired = false;

  static Future<bool> _defaultPermissionRequester() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static void _logStreamError(Object error) =>
      AppLogger.w('Voice stream error: $error');

  @override
  Future<Result<void>> initializeAudio() => _audio ??= _prepareAudio();

  Future<Result<void>> _prepareAudio() async {
    final epoch = _epoch;
    var capturing = false;
    try {
      final granted = await _permissionRequester();
      if (epoch != _epoch) return const Result.failure(Failure.audio());

      await _audioSession.activate();
      // La ruta elegida (o la de los audífonos ya conectados) manda sobre la
      // que deja la sesión recién configurada.
      await setAudioRoute(_activeAudioRoute);
      if (epoch != _epoch) return const Result.failure(Failure.audio());

      // Se intenta capturar aunque el permiso diga que no: si el plugin de
      // permisos no puede preguntar, `getUserMedia` pregunta por su cuenta.
      capturing = true;
      await _peerConnection.prepareMedia(capture: true);
      if (_peerConnection.hasMicrophone) return const Result.success(null);
      return granted
          ? const Result.failure(Failure.audio())
          : const Result.failure(
              Failure.permissionDenied(permission: 'microphone'),
            );
    } on Object catch (e, st) {
      AppLogger.e('Failed to initialize audio', e, st);
      return const Result.failure(Failure.audio());
    } finally {
      // Sin micrófono la malla igual se arma para escuchar.
      if (!capturing && epoch == _epoch) {
        unawaited(_peerConnection.prepareMedia(capture: false));
      }
    }
  }

  @override
  Future<void> joinMesh({
    required String localPeerId,
    required List<String> peerIds,
  }) async {
    if (localPeerId.isEmpty || localPeerId == _meshPeerId) return;
    _meshPeerId = localPeerId;
    _setSpeakingPeers(const {});
    _setMutedPeers(const {});
    // Desde aquí se atienden las offers dirigidas a este id.
    _peerConnection.attach(localPeerId);

    await initializeAudio();
    if (_meshPeerId != localPeerId) return;

    await Future.wait([
      for (final peerId in peerIds)
        if (peerId != localPeerId) _peerConnection.connectToPeer(peerId),
    ]);
    if (_meshPeerId != localPeerId) return;

    final resume = _resumeOpenMic;
    _resumeOpenMic = false;
    if (_talkMode != TalkMode.openMic) return;
    if (resume) {
      await startTalking();
    } else {
      _announce();
    }
  }

  @override
  Future<void> leaveMesh() async {
    _epoch++;
    _meshPeerId = null;
    _audio = null;
    _resumeOpenMic = false;
    if (_isTalking) {
      _isTalking = false;
      _emit(_isTalkingController, false);
    }
    _setSpeakingPeers(const {});
    _setMutedPeers(const {});
    await _peerConnection.reset();
    // Si ya empezó otra frecu, su sesión de audio no se toca.
    if (_meshPeerId == null && _audio == null) {
      await _audioSession.deactivate();
    }
  }

  /// Avisa a la frecu del estado propio (al entrar alguien, o al volver).
  void _announce() {
    _peerConnection.announceTalkState(
      speaking: _isTalking,
      muted: _talkMode == TalkMode.openMic && !_isTalking,
    );
  }

  @override
  Future<Result<void>> startTalking() async {
    try {
      _isTalking = true;
      _peerConnection.setMicrophoneEnabled(enabled: true);
      _emit(_isTalkingController, true);
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
      _peerConnection.setMicrophoneEnabled(
        enabled: false,
        muted: _talkMode == TalkMode.openMic,
      );
      _emit(_isTalkingController, false);
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error stopping voice transmission', e, st);
      return Result.failure(Failure.audio(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> setTalkMode(TalkMode mode) async {
    try {
      if (mode == _talkMode) return const Result.success(null);
      _talkMode = mode;
      _emit(_talkModeController, mode);
      switch (mode) {
        case TalkMode.pushToTalk:
          if (_isTalking) {
            await stopTalking();
          } else {
            // Ya no está silenciado: está en PTT.
            _announce();
          }
        case TalkMode.openMic:
          // Abierto empieza en silencio hasta que se abre el micrófono.
          if (!_isTalking) _announce();
      }
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error changing talk mode', e, st);
      return Result.failure(Failure.audio(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> setAudioRoute(AudioRoute route) async {
    try {
      switch (route) {
        case AudioRoute.speaker:
          await _audioSession.setSpeakerphoneOn(true);
        case AudioRoute.earpiece:
          await _audioSession.setSpeakerphoneOn(false);
        case AudioRoute.bluetooth:
          await _audioSession.setSpeakerphoneOnButPreferBluetooth();
      }
      _activeAudioRoute = route;
      _emit(_audioRouteController, route);
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error changing audio route', e, st);
      return Result.failure(Failure.audio(message: e.toString()));
    }
  }

  /// Vuelve a aplicar la ruta elegida cuando audioswitch se calma; elegir la
  /// misma salida no genera otro cambio, así que no se repite.
  void _reapplyRouteSoon() {
    _reapplyRoute?.cancel();
    _reapplyRoute = Timer(const Duration(milliseconds: 250), () {
      unawaited(setAudioRoute(_activeAudioRoute));
    });
  }

  @override
  Future<Result<void>> setSpeakerOn(bool enabled) {
    return setAudioRoute(enabled ? AudioRoute.speaker : AudioRoute.earpiece);
  }

  @override
  Stream<bool> watchIsTalking() =>
      currentThen(() => _isTalking, _isTalkingController.stream);

  @override
  Stream<Set<String>> watchSpeakingPeers() =>
      currentThen(() => _speakingPeers, _speakingPeersController.stream);

  @override
  Stream<Set<String>> watchMutedPeers() =>
      currentThen(() => _mutedPeers, _mutedPeersController.stream);

  @override
  Stream<double> watchLocalLevel() => _levels.watchLocal();

  @override
  Stream<Map<String, double>> watchPeerLevels() => _levels.watchPeers();

  @override
  Stream<Map<String, PeerConnectionState>> watchPeerLinks() =>
      currentThen(() => _peerConnection.links, _peerConnection.linkChanges);

  @override
  Stream<TalkMode> watchTalkMode() =>
      currentThen(() => _talkMode, _talkModeController.stream);

  @override
  Stream<AudioRoute> watchAudioRoute() =>
      currentThen(() => _activeAudioRoute, _audioRouteController.stream);

  @override
  Stream<Set<AudioRoute>> watchAvailableAudioRoutes() => currentThen(
    () => _availableAudioRoutes,
    _availableRoutesController.stream,
  );

  @override
  Stream<String?> watchBluetoothName() =>
      currentThen(() => _bluetoothName, _bluetoothNameController.stream);

  static bool _isBluetooth(AudioDeviceType type) =>
      type == AudioDeviceType.bluetoothSco ||
      type == AudioDeviceType.bluetoothA2dp ||
      type == AudioDeviceType.bluetoothLe;

  /// Bluetooth que reproduce medios (A2DP o LE Audio): audífonos,
  /// intercomunicadores, el carro.
  static bool _playsMedia(AudioDeviceType type) =>
      type == AudioDeviceType.bluetoothA2dp ||
      type == AudioDeviceType.bluetoothLe;

  /// Bluetooth al que la salida puede ir sola. En Android, un dispositivo
  /// solo de llamadas (sin A2DP ni LE Audio, como un reloj) se puede elegir
  /// pero no se lleva la voz; en iOS los audífonos se ven como HFP, así que
  /// cuenta cualquiera.
  bool _takesOutput(AudioDevice device, Iterable<AudioDevice> bluetooth) =>
      !_isAndroid ||
      bluetooth.any((d) => d.name == device.name && _playsMedia(d.type));

  static bool _isWired(AudioDeviceType type) =>
      type == AudioDeviceType.wiredHeadset ||
      type == AudioDeviceType.wiredHeadphones ||
      type == AudioDeviceType.usbAudio;

  /// Al conectar audífonos (Bluetooth o de cable) la salida cambia a ellos;
  /// al desconectar los que se usaban, vuelve al altavoz. Un Bluetooth solo
  /// de llamadas en Android (un reloj) queda para elegirlo a mano.
  void _handleAudioDevicesChanged(Set<AudioDevice> devices) {
    final bluetooth = devices.where((d) => _isBluetooth(d.type)).toList()
      ..sort((a, b) => (b.isOutput ? 1 : 0) - (a.isOutput ? 1 : 0));
    final listening = bluetooth
        .where((d) => _takesOutput(d, bluetooth))
        .toList();
    final hasBluetooth = bluetooth.isNotEmpty;
    final takesOutput = listening.isNotEmpty;
    final hasWired = devices.any((d) => _isWired(d.type));

    final named = takesOutput ? listening : bluetooth;
    final name = hasBluetooth ? named.first.name.trim() : '';
    final bluetoothName = name.isEmpty ? null : name;
    if (bluetoothName != _bluetoothName) {
      _bluetoothName = bluetoothName;
      _emit(_bluetoothNameController, bluetoothName);
    }

    _availableAudioRoutes = {
      AudioRoute.speaker,
      AudioRoute.earpiece,
      if (hasBluetooth) AudioRoute.bluetooth,
    };
    _emit(_availableRoutesController, _availableAudioRoutes);

    final first = !_devicesKnown;
    final bluetoothArrived = takesOutput && (first || !_hadBluetooth);
    final wiredArrived = hasWired && (first || !_hadWired);
    final wiredLeft = !hasWired && _hadWired;
    _devicesKnown = true;
    _hadBluetooth = takesOutput;
    _hadWired = hasWired;

    final AudioRoute? next;
    if (bluetoothArrived) {
      next = AudioRoute.bluetooth;
    } else if (wiredArrived && !takesOutput) {
      next = AudioRoute.earpiece;
    } else if (!hasBluetooth && _activeAudioRoute == AudioRoute.bluetooth) {
      // Se fue el Bluetooth (o ya no estaba): nunca queda una ruta muda.
      next = hasWired ? AudioRoute.earpiece : AudioRoute.speaker;
    } else if (wiredLeft && _activeAudioRoute == AudioRoute.earpiece) {
      next = AudioRoute.speaker;
    } else {
      next = null;
    }
    if (next != null && next != _activeAudioRoute) {
      unawaited(setAudioRoute(next));
    }
  }

  void _handleConnectionChange(bool connected) {
    if (connected || _meshPeerId == null) return;
    // Sin anfitrión no se transmite; al volver se retoma según el modo.
    _resumeOpenMic =
        _resumeOpenMic || (_talkMode == TalkMode.openMic && _isTalking);
    if (_isTalking) {
      _isTalking = false;
      _peerConnection.setMicrophoneEnabled(enabled: false, announce: false);
      _emit(_isTalkingController, false);
    }
    _setSpeakingPeers(const {});
  }

  void _handleSignalingMessage(SignalingMessage msg) {
    switch (msg) {
      case SignalingWelcomeMessage(:final peerId, :final participants):
        // Al reconectar, el id viejo propio puede seguir en la lista un
        // rato: no se le ofrece.
        final previous = _meshPeerId;
        unawaited(
          joinMesh(
            localPeerId: peerId,
            peerIds: [
              for (final participant in participants)
                if (participant.id != peerId && participant.id != previous)
                  participant.id,
            ],
          ),
        );
      case SignalingTalkStateMessage(
        :final peerId,
        :final isSpeaking,
        :final muted,
      ):
        _handleTalkState(peerId, isSpeaking, muted: muted ?? false);
      case SignalingPeerJoinedMessage():
        // Quien llega no sabe si alguien ya habla o está silenciado.
        if (_meshPeerId != null &&
            (_isTalking || _talkMode == TalkMode.openMic)) {
          _announce();
        }
      case SignalingPeerLeftMessage(:final peerId):
        _setSpeakingPeers({..._speakingPeers}..remove(peerId));
        _setMutedPeers({..._mutedPeers}..remove(peerId));
      case SignalingRoomClosedMessage():
        unawaited(leaveMesh());
      case SignalingJoinMessage() ||
          SignalingRejectedMessage() ||
          SignalingOfferMessage() ||
          SignalingAnswerMessage() ||
          SignalingIceMessage() ||
          SignalingPingMessage() ||
          SignalingPongMessage():
        break;
    }
  }

  void _handleTalkState(String peerId, bool isSpeaking, {required bool muted}) {
    if (peerId == _meshPeerId) return;
    final speaking = {..._speakingPeers};
    if (isSpeaking) {
      speaking.add(peerId);
    } else {
      speaking.remove(peerId);
    }
    _setSpeakingPeers(speaking);
    final mutedPeers = {..._mutedPeers};
    if (muted) {
      mutedPeers.add(peerId);
    } else {
      mutedPeers.remove(peerId);
    }
    _setMutedPeers(mutedPeers);
  }

  void _setSpeakingPeers(Set<String> peers) {
    if (_sameSet(peers, _speakingPeers)) return;
    _speakingPeers = Set.unmodifiable(peers);
    _emit(_speakingPeersController, _speakingPeers);
  }

  void _setMutedPeers(Set<String> peers) {
    if (_sameSet(peers, _mutedPeers)) return;
    _mutedPeers = Set.unmodifiable(peers);
    _emit(_mutedPeersController, _mutedPeers);
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  static void _emit<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) controller.add(value);
  }

  @override
  Future<bool> openMicrophoneSettings() async {
    try {
      return await _settingsOpener();
    } on Object catch (e, st) {
      AppLogger.w('Could not open the app settings', e, st);
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await _signalingSubscription?.cancel();
    _signalingSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _devicesSubscription?.cancel();
    _devicesSubscription = null;
    _reapplyRoute?.cancel();
    await _webRtcDevicesSubscription?.cancel();
    _webRtcDevicesSubscription = null;
    await _levels.dispose();
    await _peerConnection.dispose();
    await _audioSession.deactivate();
    await _isTalkingController.close();
    await _speakingPeersController.close();
    await _mutedPeersController.close();
    await _talkModeController.close();
    await _audioRouteController.close();
    await _availableRoutesController.close();
    await _bluetoothNameController.close();
  }
}
