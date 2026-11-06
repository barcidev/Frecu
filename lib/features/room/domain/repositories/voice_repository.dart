import 'package:frecu/core/result/result.dart';
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

  /// Stream reactivo que emite si el usuario local está hablando/transmitiendo.
  Stream<bool> watchIsTalking();

  /// Stream reactivo del conjunto de IDs de participantes remotos que están hablando.
  Stream<Set<String>> watchSpeakingPeers();

  /// Stream reactivo del modo de habla actual.
  Stream<TalkMode> watchTalkMode();

  /// Libera recursos y cierra pistas de audio y conexiones de voz.
  Future<void> dispose();
}
