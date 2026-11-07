import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';

export 'set_audio_route.dart';
export 'set_speaker_on.dart';

/// Caso de uso para iniciar la transmisión de voz.
final class StartTalking implements UseCase<void, NoParams> {
  /// Constructor con inyección de repositorio.
  const StartTalking(this._repository);

  final VoiceRepository _repository;

  @override
  String get name => 'StartTalking';

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.startTalking();
  }
}

/// Caso de uso para detener la transmisión de voz (silenciar micrófono).
final class StopTalking implements UseCase<void, NoParams> {
  /// Constructor con inyección de repositorio.
  const StopTalking(this._repository);

  final VoiceRepository _repository;

  @override
  String get name => 'StopTalking';

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.stopTalking();
  }
}

/// Caso de uso para cambiar el modo de habla (PTT o micrófono abierto).
final class ChangeTalkMode implements UseCase<void, TalkMode> {
  /// Constructor con inyección de repositorio.
  const ChangeTalkMode(this._repository);

  final VoiceRepository _repository;

  @override
  String get name => 'ChangeTalkMode';

  @override
  Future<Result<void>> call(TalkMode mode) {
    return _repository.setTalkMode(mode);
  }
}
