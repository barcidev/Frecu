// AC1: CUANDO un participante se une a la sala del anfitrión ENTONCES se negocia automáticamente una conexión WebRTC mesh directa (SDP offer/answer e ICE local) entre ambos extremos sin servidores STUN/TURN.
// AC2: CUANDO ambos extremos tienen el micrófono activado en modo abierto ENTONCES la captura local de audio transmite en tiempo real hacia el otro teléfono y se emite señalización de estado de habla (`talk_state`).
// AC3: CUANDO un participante silencia su micrófono ENTONCES se desactiva la pista local de audio (`track.enabled = false`) sin renegociar la sesión WebRTC y se notifica a la sala el cese de habla.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/domain/usecases/voice_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockVoiceRepository extends Mock implements VoiceRepository {}

void main() {
  group('Voice use cases', () {
    late MockVoiceRepository repository;
    late StartTalking startTalking;
    late StopTalking stopTalking;
    late ChangeTalkMode changeTalkMode;

    setUp(() {
      repository = MockVoiceRepository();
      startTalking = StartTalking(repository);
      stopTalking = StopTalking(repository);
      changeTalkMode = ChangeTalkMode(repository);
    });

    // AC2
    test('AC2: StartTalking use case triggers voice transmission', () async {
      when(() => repository.startTalking())
          .thenAnswer((_) async => const Result<void>.success(null));

      final result = await startTalking(const NoParams());

      expect(result.isSuccess, isTrue);
      verify(() => repository.startTalking()).called(1);
    });

    // AC3
    test('AC3: StopTalking use case mutes voice transmission', () async {
      when(() => repository.stopTalking())
          .thenAnswer((_) async => const Result<void>.success(null));

      final result = await stopTalking(const NoParams());

      expect(result.isSuccess, isTrue);
      verify(() => repository.stopTalking()).called(1);
    });

    test('ChangeTalkMode use case sets new talk mode', () async {
      when(() => repository.setTalkMode(TalkMode.openMic))
          .thenAnswer((_) async => const Result<void>.success(null));

      final result = await changeTalkMode(TalkMode.openMic);

      expect(result.isSuccess, isTrue);
      verify(() => repository.setTalkMode(TalkMode.openMic)).called(1);
    });
  });
}
