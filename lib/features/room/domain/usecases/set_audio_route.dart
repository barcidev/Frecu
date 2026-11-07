import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';

/// Caso de uso para cambiar la ruta de salida de audio activa.
final class SetAudioRoute implements UseCase<void, AudioRoute> {
  /// Constructor con inyección del repositorio de voz.
  const SetAudioRoute(this._repository);

  final VoiceRepository _repository;

  @override
  String get name => 'SetAudioRoute';

  @override
  Future<Result<void>> call(AudioRoute route) {
    return _repository.setAudioRoute(route);
  }
}
