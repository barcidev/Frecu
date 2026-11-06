// AC1: CUANDO el usuario conmuta la salida de audio entre altavoz, auricular y Bluetooth ENTONCES la sesión de audio redirige la salida al dispositivo seleccionado y actualiza el icono de ruta de audio en tiempo real.
// AC2: CUANDO se conecta o desconecta un accesorio de audio (auriculares cableados o Bluetooth) ENTONCES el sistema detecta el cambio de periférico y actualiza la ruta de audio activa.
// AC3: CUANDO un participante silencia su micrófono ENTONCES se desactiva la pista local de audio (`track.enabled = false`) sin renegociar la sesión WebRTC y se notifica a la sala el cese de habla.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
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
    registerFallbackValue(AudioRoute.speaker);
    LocaleSettings.setLocale(AppLocale.es);
  });

  group('Voice UI and mic controls', () {
    late MockRoomRepository roomRepository;
    late MockVoiceRepository voiceRepository;
    late StreamController<bool> isTalkingController;
    late StreamController<Set<String>> speakingPeersController;
    late StreamController<TalkMode> talkModeController;
    late StreamController<AudioRoute> audioRouteController;
    late StreamController<Set<AudioRoute>> availableRoutesController;

    setUp(() {
      roomRepository = MockRoomRepository();
      voiceRepository = MockVoiceRepository();
      isTalkingController = StreamController<bool>.broadcast();
      speakingPeersController = StreamController<Set<String>>.broadcast();
      talkModeController = StreamController<TalkMode>.broadcast();
      audioRouteController = StreamController<AudioRoute>.broadcast();
      availableRoutesController = StreamController<Set<AudioRoute>>.broadcast();

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
      when(() => voiceRepository.watchAudioRoute())
          .thenAnswer((_) => audioRouteController.stream);
      when(() => voiceRepository.watchAvailableAudioRoutes())
          .thenAnswer((_) => availableRoutesController.stream);
      when(() => voiceRepository.startTalking())
          .thenAnswer((_) async => const Result<void>.success(null));
      when(() => voiceRepository.stopTalking())
          .thenAnswer((_) async => const Result<void>.success(null));
      when(() => voiceRepository.setTalkMode(any()))
          .thenAnswer((_) async => const Result<void>.success(null));
      when(() => voiceRepository.setAudioRoute(any()))
          .thenAnswer((_) async => const Result<void>.success(null));
      when(() => voiceRepository.dispose()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await isTalkingController.close();
      await speakingPeersController.close();
      await talkModeController.close();
      await audioRouteController.close();
      await availableRoutesController.close();
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
      expect(find.byIcon(Icons.volume_up), findsWidgets);
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
        expect(find.byIcon(Icons.volume_up), findsWidgets);
        expect(find.text(t.room.speaking), findsWidgets);

        // Remote peer stops speaking
        speakingPeersController.add({});
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('speaking_indicator_peer-2')),
          findsNothing,
        );
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

    // AC1
    testWidgets(
      'AC1: tapping audio route button switches audio route and updates icon dynamically',
      (tester) async {
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        audioRouteController.add(AudioRoute.speaker);
        availableRoutesController.add({
          AudioRoute.speaker,
          AudioRoute.earpiece,
          AudioRoute.bluetooth,
        });
        await tester.pumpAndSettle();

        final routeButton = find.byKey(const Key('audio_route_button'));
        expect(routeButton, findsOneWidget);

        // Initial route: speaker (volume_up)
        expect(
          find.descendant(
            of: routeButton,
            matching: find.byIcon(Icons.volume_up),
          ),
          findsOneWidget,
        );

        // Tap to cycle route
        await tester.tap(routeButton);
        await tester.pumpAndSettle();
        verify(() => voiceRepository.setAudioRoute(any())).called(1);

        // Simulated state change to bluetooth
        audioRouteController.add(AudioRoute.bluetooth);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: routeButton,
            matching: find.byIcon(Icons.bluetooth_audio),
          ),
          findsOneWidget,
        );

        // Simulated state change to earpiece
        audioRouteController.add(AudioRoute.earpiece);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: routeButton,
            matching: find.byIcon(Icons.phone_in_talk),
          ),
          findsOneWidget,
        );
      },
    );

    // AC2
    testWidgets(
      'AC2: audio route changes dynamically when accessory is disconnected or route stream emits',
      (tester) async {
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        final routeButton = find.byKey(const Key('audio_route_button'));

        // Accessory connected: route is bluetooth
        audioRouteController.add(AudioRoute.bluetooth);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: routeButton,
            matching: find.byIcon(Icons.bluetooth_audio),
          ),
          findsOneWidget,
        );

        // Accessory disconnected: fallback to speaker
        audioRouteController.add(AudioRoute.speaker);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: routeButton,
            matching: find.byIcon(Icons.volume_up),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
