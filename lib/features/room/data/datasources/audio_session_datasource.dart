import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Datasource para la configuración y control de la sesión de audio nativa.
class AudioSessionDataSource {
  /// Constructor con inyección opcional de sesión, setters de speaker y
  /// cambios del gestor de audio de WebRTC.
  AudioSessionDataSource([
    this._session,
    Future<void> Function(bool enabled)? speakerphoneSetter,
    Future<void> Function()? speakerphoneWithBluetoothSetter,
    Stream<void>? webRtcDeviceChanges,
  ]) : _speakerphoneSetter = speakerphoneSetter ?? _setSpeakerphone,
       _speakerphoneWithBluetoothSetter =
           speakerphoneWithBluetoothSetter ??
           Helper.setSpeakerphoneOnButPreferBluetooth,
       _webRtcDeviceChanges = webRtcDeviceChanges;

  AudioSession? _session;
  final Future<void> Function(bool enabled) _speakerphoneSetter;
  final Future<void> Function() _speakerphoneWithBluetoothSetter;
  final Stream<void>? _webRtcDeviceChanges;

  static StreamController<void>? _deviceChanges;

  /// Cada vez que el gestor de audio de WebRTC ve otros dispositivos o elige
  /// otra salida (en Android, audioswitch, que puede elegir por su cuenta
  /// cualquier Bluetooth).
  Stream<void> get webRtcDeviceChanges =>
      _webRtcDeviceChanges ?? _nativeDeviceChanges();

  static Stream<void> _nativeDeviceChanges() {
    final changes = _deviceChanges ??= StreamController<void>.broadcast(
      onListen: () =>
          navigator.mediaDevices.ondevicechange = (_) =>
              _deviceChanges?.add(null),
      onCancel: () => navigator.mediaDevices.ondevicechange = null,
    );
    return changes.stream;
  }

  /// Altavoz o, sin él, auricular (o audífonos de cable). En Android elige el
  /// dispositivo exacto: «sin altavoz» de flutter_webrtc prefiere cualquier
  /// Bluetooth, y un reloj se llevaría la voz.
  static Future<void> _setSpeakerphone(bool enabled) async {
    if (!Platform.isAndroid) return Helper.setSpeakerphoneOn(enabled);
    if (enabled) return Helper.selectAudioOutput(_speaker);
    final devices = await navigator.mediaDevices.enumerateDevices();
    final wired = devices.any(
      (device) => device.kind == 'audiooutput' && device.deviceId == _wired,
    );
    return Helper.selectAudioOutput(wired ? _wired : _earpiece);
  }

  /// Salidas de audioswitch (`AudioDeviceKind` de flutter_webrtc).
  static const String _speaker = 'speaker';
  static const String _earpiece = 'earpiece';
  static const String _wired = 'wired-headset';

  /// Stream reactivo del conjunto de dispositivos de audio detectados.
  Stream<Set<AudioDevice>> get devicesStream async* {
    _session ??= await AudioSession.instance;
    yield* _session!.devicesStream;
  }

  /// Obtiene los dispositivos de audio disponibles actualmente.
  Future<Set<AudioDevice>> getDevices() async {
    try {
      _session ??= await AudioSession.instance;
      return await _session!.getDevices();
    } on Object catch (e) {
      AppLogger.w('Failed to get audio devices: $e');
      return <AudioDevice>{};
    }
  }

  /// Activa o desactiva la salida por altavoz del dispositivo.
  Future<void> setSpeakerphoneOn(bool enable) async {
    try {
      await _speakerphoneSetter(enable);
      AppLogger.i('Speakerphone set to $enable');
    } on Object catch (e) {
      AppLogger.w('Failed to set speakerphone on: $e');
    }
  }

  /// Activa el altavoz prefiriendo dispositivos Bluetooth conectados si existen.
  Future<void> setSpeakerphoneOnButPreferBluetooth() async {
    try {
      await _speakerphoneWithBluetoothSetter();
      AppLogger.i('Speakerphone set with Bluetooth preference');
    } on Object catch (e) {
      AppLogger.w('Failed to set speakerphone with Bluetooth preference: $e');
    }
  }

  /// Inicializa y configura la sesión de audio para comunicación de voz VoIP.
  Future<void> activate() async {
    try {
      _session ??= await AudioSession.instance;
      await _session!.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetooth,
          avAudioSessionMode: AVAudioSessionMode.voiceChat,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
        ),
      );
      await _session!.setActive(true);
      AppLogger.i('Audio session activated successfully');
    } on Object catch (e, st) {
      AppLogger.w('Failed to activate audio session: $e\n$st');
    }
  }

  /// Desactiva la sesión de audio liberando el foco de audio del sistema.
  Future<void> deactivate() async {
    try {
      if (_session != null) {
        await _session!.setActive(false);
      }
    } on Object catch (e) {
      AppLogger.w('Failed to deactivate audio session: $e');
    }
  }
}
