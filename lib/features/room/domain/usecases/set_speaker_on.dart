import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';

/// Caso de uso para conmutar el altavoz externo del dispositivo.
final class SetSpeakerOn implements UseCase<void, bool> {
  /// Constructor con inyección del repositorio de voz.
  const SetSpeakerOn(this._repository);

  final VoiceRepository _repository;

  @override
  String get name => 'SetSpeakerOn';

  @override
  Future<Result<void>> call(bool enabled) {
    return _repository.setSpeakerOn(enabled);
  }
}
