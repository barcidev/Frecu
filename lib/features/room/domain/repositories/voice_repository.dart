import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';

/// Contrato del repositorio para la captura, transmisión y gestión de voz.
abstract interface class VoiceRepository {
  /// Inicializa la sesión de audio y solicita permisos de micrófono.
  Future<Result<void>> initializeAudio();

  /// Inicia la transmisión de voz en el canal WebRTC.
  Future<Result<void>> startTalking();

  /// Detiene la transmisión de voz (silencia el micrófono).
  Future<Result<void>> stopTalking();

  /// Cambia el modo de habla (PTT o micrófono abierto).
  Future<Result<void>> setTalkMode(TalkMode mode);

  /// Conmuta la salida de audio a la ruta seleccionada.
  Future<Result<void>> setAudioRoute(AudioRoute route);

  /// Activa o desactiva la salida por el altavoz externo.
  Future<Result<void>> setSpeakerOn(bool enabled);

  /// Stream reactivo que emite si el usuario local está hablando/transmitiendo.
  Stream<bool> watchIsTalking();

  /// Stream reactivo del conjunto de IDs de participantes remotos que están hablando.
  Stream<Set<String>> watchSpeakingPeers();

  /// Nivel de la voz propia, de 0 a 1, medido por WebRTC. Se lee solo
  /// mientras alguien escucha este flujo o [watchPeerLevels].
  Stream<double> watchLocalLevel();

  /// Nivel de la voz recibida de cada participante remoto por su id, de 0 a
  /// 1, medido por WebRTC. Se lee solo mientras alguien escucha.
  Stream<Map<String, double>> watchPeerLevels();

  /// Stream reactivo del modo de habla actual.
  Stream<TalkMode> watchTalkMode();

  /// Stream reactivo de la ruta de salida de audio activa.
  Stream<AudioRoute> watchAudioRoute();

  /// Stream reactivo del conjunto de rutas de audio disponibles en el dispositivo.
  Stream<Set<AudioRoute>> watchAvailableAudioRoutes();

  /// Libera recursos y cierra pistas de audio y conexiones de voz.
  Future<void> dispose();
}
