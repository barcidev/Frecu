// AC1: CUANDO el usuario conmuta la salida de audio entre altavoz, auricular y Bluetooth ENTONCES la sesión de audio redirige la salida al dispositivo seleccionado y actualiza el icono de ruta de audio en tiempo real.
// AC2: CUANDO se conecta o desconecta un accesorio de audio (auriculares cableados o Bluetooth) ENTONCES el sistema detecta el cambio de periférico y actualiza la ruta de audio activa.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/domain/usecases/set_audio_route.dart';
import 'package:frecu/features/room/domain/usecases/set_speaker_on.dart';
import 'package:mocktail/mocktail.dart';

class MockVoiceRepository extends Mock implements VoiceRepository {}

void main() {
  group('Audio route use cases', () {
    late MockVoiceRepository mockRepository;

    setUp(() {
      mockRepository = MockVoiceRepository();
    });

    // AC1
    test('AC1: SetAudioRoute delegates to repository.setAudioRoute', () async {
      when(() => mockRepository.setAudioRoute(AudioRoute.speaker))
          .thenAnswer((_) async => const Result.success(null));

      final useCase = SetAudioRoute(mockRepository);
      final result = await useCase(AudioRoute.speaker);

      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.setAudioRoute(AudioRoute.speaker)).called(1);
    });

    // AC1
    test('AC1: SetSpeakerOn delegates to repository.setSpeakerOn', () async {
      when(() => mockRepository.setSpeakerOn(true))
          .thenAnswer((_) async => const Result.success(null));

      final useCase = SetSpeakerOn(mockRepository);
      final result = await useCase(true);

      expect(result.isSuccess, isTrue);
      verify(() => mockRepository.setSpeakerOn(true)).called(1);
    });
  });
}
