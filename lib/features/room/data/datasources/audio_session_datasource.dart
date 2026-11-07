import 'package:audio_session/audio_session.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Datasource para la configuración y control de la sesión de audio nativa.
class AudioSessionDataSource {
  /// Constructor con inyección opcional de sesión y setters de speaker.
  AudioSessionDataSource([
    this._session,
    Future<void> Function(bool enabled)? speakerphoneSetter,
    Future<void> Function()? speakerphoneWithBluetoothSetter,
  ]) : _speakerphoneSetter = speakerphoneSetter ?? Helper.setSpeakerphoneOn,
       _speakerphoneWithBluetoothSetter =
           speakerphoneWithBluetoothSetter ??
           Helper.setSpeakerphoneOnButPreferBluetooth;

  AudioSession? _session;
  final Future<void> Function(bool enabled) _speakerphoneSetter;
  final Future<void> Function() _speakerphoneWithBluetoothSetter;

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
