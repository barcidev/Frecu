// AC1: CUANDO un participante se une a la sala del anfitrión ENTONCES se negocia automáticamente una conexión WebRTC mesh directa (SDP offer/answer e ICE local) entre ambos extremos sin servidores STUN/TURN.
// AC2: CUANDO ambos extremos tienen el micrófono activado en modo abierto ENTONCES la captura local de audio transmite en tiempo real hacia el otro teléfono y se emite señalización de estado de habla (`talk_state`).
// AC3: CUANDO un participante silencia su micrófono ENTONCES se desactiva la pista local de audio (`track.enabled = false`) sin renegociar la sesión WebRTC y se notifica a la sala el cese de habla.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomRepository extends Mock implements RoomRepository {}

class MockVoiceRepository extends Mock implements VoiceRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(TalkMode.openMic);
    LocaleSettings.setLocale(AppLocale.es);
  });

  group('Voice UI and mic controls', () {
    late MockRoomRepository roomRepository;
    late MockVoiceRepository voiceRepository;
    late StreamController<bool> isTalkingController;
    late StreamController<Set<String>> speakingPeersController;
    late StreamController<TalkMode> talkModeController;

    setUp(() {
      roomRepository = MockRoomRepository();
      voiceRepository = MockVoiceRepository();
      isTalkingController = StreamController<bool>.broadcast();
      speakingPeersController = StreamController<Set<String>>.broadcast();
      talkModeController = StreamController<TalkMode>.broadcast();

      when(() => roomRepository.watchStatus())
          .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
      when(() => roomRepository.watchParticipants()).thenAnswer(
        (_) =>
            Stream.value([const Participant(id: 'peer-2', displayName: 'Bob')]),
      );

      when(() => voiceRepository.initializeAudio())
          .thenAnswer((_) async => const Result<void>.success(null));
      when(() => voiceRepository.watchIsTalking())
          .thenAnswer((_) => isTalkingController.stream);
      when(() => voiceRepository.watchSpeakingPeers())
          .thenAnswer((_) => speakingPeersController.stream);
      when(() => voiceRepository.watchTalkMode())
          .thenAnswer((_) => talkModeController.stream);
      when(() => voiceRepository.startTalking())
          .thenAnswer((_) async => const Result<void>.success(null));
      when(() => voiceRepository.stopTalking())
          .thenAnswer((_) async => const Result<void>.success(null));
      when(() => voiceRepository.setTalkMode(any()))
          .thenAnswer((_) async => const Result<void>.success(null));
      when(() => voiceRepository.dispose()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await isTalkingController.close();
      await speakingPeersController.close();
      await talkModeController.close();
    });

    Widget createTestApp(AppRouter router) {
      return TranslationProvider(
        child: ProviderScope(
          overrides: [
            roomRepositoryProvider.overrideWithValue(roomRepository),
            voiceRepositoryProvider.overrideWithValue(voiceRepository),
          ],
          child: FrecuApp(appRouter: router),
        ),
      );
    }

    // AC2
    testWidgets('AC2: RoomPage shows mic open and active speaking indicator', (
      tester,
    ) async {
      final router = AppRouter();
      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      unawaited(router.push(RoomRoute(roomId: 'room-123')));
      await tester.pumpAndSettle();

      isTalkingController.add(true);
      speakingPeersController.add({'peer-2'});
      talkModeController.add(TalkMode.openMic);
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.text(t.room.openMic), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    // AC2
    testWidgets(
      'AC2: RoomPage activates speaking indicator and subtitle when participant speaks',
      (tester) async {
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        expect(find.text('Bob'), findsOneWidget);
        expect(
          find.byKey(const Key('speaking_indicator_peer-2')),
          findsNothing,
        );

        // Remote peer starts speaking
        speakingPeersController.add({'peer-2'});
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('speaking_indicator_peer-2')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.volume_up), findsOneWidget);
        expect(find.text(t.room.speaking), findsWidgets);

        // Remote peer stops speaking
        speakingPeersController.add({});
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('speaking_indicator_peer-2')),
          findsNothing,
        );
        expect(find.byIcon(Icons.volume_up), findsNothing);
      },
    );

    // AC3
    testWidgets('AC3: RoomPage allows muting mic and updates talk status', (
      tester,
    ) async {
      final router = AppRouter();
      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      unawaited(router.push(RoomRoute(roomId: 'room-123')));
      await tester.pumpAndSettle();

      isTalkingController.add(true);
      talkModeController.add(TalkMode.openMic);
      await tester.pumpAndSettle();

      final micButton = find.byKey(const Key('mic_toggle_button'));
      expect(micButton, findsOneWidget);

      await tester.tap(micButton);
      await tester.pumpAndSettle();

      verify(() => voiceRepository.stopTalking()).called(1);

      isTalkingController.add(false);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.mic_off), findsOneWidget);
      expect(find.text(t.room.muted), findsOneWidget);
    });
  });
}
