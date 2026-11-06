import 'package:audio_session/audio_session.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Datasource para la configuración y control de la sesión de audio nativa.
class AudioSessionDataSource {
  /// Constructor.
  AudioSessionDataSource([this._session]);

  AudioSession? _session;

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
