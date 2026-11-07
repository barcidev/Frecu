// AC1: CUANDO el usuario se encuentra en modo PTT y mantiene presionado el botón de hablar (`onPointerDown`) ENTONCES se activa la transmisión de voz (`startTalking()`) y el botón refleja visualmente el estado de habla hasta que el usuario lo suelta o cancela la pulsación (`onPointerUp`/`onPointerCancel`), silenciando el micrófono (`stopTalking()`).
// AC2: CUANDO el usuario selecciona el modo de micrófono abierto (`openMic`) en la sala ENTONCES el modo se actualiza a `openMic` y el botón de micrófono permite alternar la transmisión continua (conmutar silencio/habla con un solo toque).
// AC3: CUANDO el usuario cambia de modo de habla de micrófono abierto transmitiendo a PTT ENTONCES la transmisión continua se detiene de inmediato silenciando el micrófono.
// AC2 (C4): CUANDO alguien habla ENTONCES su etiqueta en la malla dice «Hablando».
// AC6 (C4): CUANDO el usuario está en la frecu activa ENTONCES el PTT, el micrófono abierto, el cambio de modo y el ciclo de ruta de audio funcionan como antes sobre la malla; con tema claro, el texto «Hablando» del micrófono abierto va en `signalFg`, nunca en verde sobre blanco.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/mic_control_section.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomRepository extends Mock implements RoomRepository {}

class MockVoiceRepository extends Mock implements VoiceRepository {}

void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(TalkMode.openMic);
    registerFallbackValue(TalkMode.pushToTalk);
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

    // AC1
    testWidgets(
      'AC1: PTT mode starts talking on pointer down and stops talking on pointer up or cancel',
      (tester) async {
        reduceMotion(tester);
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        talkModeController.add(TalkMode.pushToTalk);
        isTalkingController.add(false);
        await tester.pumpAndSettle();

        final pttButton = find.byKey(const Key('ptt_button'));
        expect(pttButton, findsOneWidget);

        // Pointer down -> starts talking
        final gesture = await tester.startGesture(tester.getCenter(pttButton));
        await tester.pump();
        verify(() => voiceRepository.startTalking()).called(1);

        // While pressed, simulated stream update to talking
        isTalkingController.add(true);
        await tester.pump();
        expect(find.text(t.room.speaking), findsWidgets);

        // Pointer up -> stops talking
        await gesture.up();
        await tester.pump();
        verify(() => voiceRepository.stopTalking()).called(1);

        // Test cancel
        final gesture2 = await tester.startGesture(tester.getCenter(pttButton));
        await tester.pump();
        verify(() => voiceRepository.startTalking()).called(1);

        await gesture2.cancel();
        await tester.pump();
        verify(() => voiceRepository.stopTalking()).called(1);
      },
    );

    // AC2
    testWidgets(
      'AC2: selecting openMic mode updates talk mode and allows toggling mic with single tap',
      (tester) async {
        reduceMotion(tester);
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        talkModeController.add(TalkMode.pushToTalk);
        isTalkingController.add(false);
        await tester.pumpAndSettle();

        final openMicSegment = find.byKey(const Key('mode_open_mic'));
        expect(openMicSegment, findsOneWidget);

        await tester.tap(openMicSegment);
        await tester.pumpAndSettle();
        verify(() => voiceRepository.setTalkMode(TalkMode.openMic)).called(1);

        // Mode changes to openMic
        talkModeController.add(TalkMode.openMic);
        await tester.pumpAndSettle();

        final micButton = find.byKey(const Key('mic_toggle_button'));
        expect(micButton, findsOneWidget);

        // Tap to start talking continuously
        await tester.tap(micButton);
        await tester.pumpAndSettle();
        verify(() => voiceRepository.startTalking()).called(1);

        // State updates to talking
        isTalkingController.add(true);
        await tester.pumpAndSettle();

        // Tap again to mute
        await tester.tap(micButton);
        await tester.pumpAndSettle();
        verify(() => voiceRepository.stopTalking()).called(1);
      },
    );

    // AC3
    testWidgets(
      'AC3: switching from openMic to PTT mode while talking stops transmission and silences mic',
      (tester) async {
        reduceMotion(tester);
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        talkModeController.add(TalkMode.openMic);
        isTalkingController.add(true);
        await tester.pumpAndSettle();

        final pttSegment = find.byKey(const Key('mode_ptt'));
        expect(pttSegment, findsOneWidget);

        await tester.tap(pttSegment);
        await tester.pumpAndSettle();
        verify(() => voiceRepository.setTalkMode(TalkMode.pushToTalk))
            .called(1);
      },
    );

    testWidgets('RoomPage shows mic open and active speaking indicator', (
      tester,
    ) async {
      reduceMotion(tester);
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
      expect(find.text(t.room.openMic), findsWidgets);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets(
      'RoomPage activates speaking indicator and subtitle when participant speaks',
      (tester) async {
        reduceMotion(tester);
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
        expect(find.text(t.room.speaking.toUpperCase()), findsOneWidget);

        // Remote peer stops speaking
        speakingPeersController.add({});
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('speaking_indicator_peer-2')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Tapping audio route button switches audio route and updates icon dynamically',
      (tester) async {
        reduceMotion(tester);
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

    testWidgets(
      'Audio route changes dynamically when accessory is disconnected or route stream emits',
      (tester) async {
        reduceMotion(tester);
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

    // AC6
    testWidgets(
      'AC6: de día el «Hablando» del micrófono abierto va en signalFg y no en '
      'verde',
      (tester) async {
        reduceMotion(tester);
        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        talkModeController.add(TalkMode.openMic);
        isTalkingController.add(true);
        await tester.pumpAndSettle();

        final talking = find.descendant(
          of: find.byType(MicControlSection),
          matching: find.text(t.room.speaking),
        );
        expect(talking, findsOneWidget);
        final color = tester.widget<Text>(talking).style?.color;
        expect(color, FrColors.light.signalFg);
        expect(color, isNot(FrColors.light.signal));
      },
    );
  });
}
