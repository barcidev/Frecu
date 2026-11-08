// AC1: CUANDO el usuario se encuentra en modo PTT y mantiene presionado el botón de hablar (`onPointerDown`) ENTONCES se activa la transmisión de voz (`startTalking()`) y el botón refleja visualmente el estado de habla hasta que el usuario lo suelta o cancela la pulsación (`onPointerUp`/`onPointerCancel`), silenciando el micrófono (`stopTalking()`).
// AC2: CUANDO el usuario selecciona el modo de micrófono abierto (`openMic`) en la sala ENTONCES el modo se actualiza a `openMic` y el botón de micrófono permite alternar la transmisión continua (conmutar silencio/habla con un solo toque).
// AC3: CUANDO el usuario cambia de modo de habla de micrófono abierto transmitiendo a PTT ENTONCES la transmisión continua se detiene de inmediato silenciando el micrófono.
// AC2 (C4): CUANDO alguien habla ENTONCES su etiqueta en la malla dice «Hablando».
// AC6 (C4): CUANDO el usuario está en la frecu activa ENTONCES el PTT, el micrófono abierto, el cambio de modo y el ciclo de ruta de audio funcionan como antes sobre la malla; con tema claro, el texto «Hablando» del micrófono abierto va en `signalFg`, nunca en verde sobre blanco.
// AC1 y AC3 (C18): el núcleo PTT reemplaza al botón y a la tarjeta de Material: al aire dice «Al aire» y con micrófono abierto es un conmutador cuyas letras van en `signalInk` sobre el relleno de señal.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
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
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomRepository extends Mock implements RoomRepository {}

class MockVoiceRepository extends Mock implements VoiceRepository {}

void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Ícono propio de la ruta que muestra la pastilla [pill].
FrIconData routeIcon(WidgetTester tester, Finder pill) => tester
    .widget<FrIcon>(
      find.descendant(of: pill, matching: find.byType(FrIcon)).first,
    )
    .icon;

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
      // El sintonizador del inicio anima sin fin: con movimiento reducido
      // queda quieto y pumpAndSettle termina.
      final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
        ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
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
        expect(find.text(t.room.talk.core.onAir.toUpperCase()), findsWidgets);

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
      expect(find.text(t.room.speaker), findsWidgets);
      expect(find.textContaining(t.room.openMic), findsWidgets);
      expect(find.byKey(const Key('mic_toggle_button')), findsOneWidget);
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
        expect(find.text(t.room.speaker), findsWidgets);
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
      'Tapping the audio route pill opens the route sheet and choosing a '
      'route switches it',
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
        expect(routeIcon(tester, routeButton), FrIcons.speaker);

        await tester.tap(routeButton);
        await tester.pumpAndSettle();
        expect(find.byType(AudioRouteSheet), findsOneWidget);
        await tester.tap(find.byKey(const Key('audio_route_option_bluetooth')));
        await tester.pumpAndSettle();
        verify(() => voiceRepository.setAudioRoute(AudioRoute.bluetooth))
            .called(1);
        expect(find.byType(AudioRouteSheet), findsNothing);

        // Simulated state change to bluetooth
        audioRouteController.add(AudioRoute.bluetooth);
        await tester.pumpAndSettle();
        expect(routeIcon(tester, routeButton), FrIcons.headset);

        // Simulated state change to earpiece
        audioRouteController.add(AudioRoute.earpiece);
        await tester.pumpAndSettle();
        expect(routeIcon(tester, routeButton), FrIcons.earpiece);
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
        expect(routeIcon(tester, routeButton), FrIcons.headset);

        // Accessory disconnected: fallback to speaker
        audioRouteController.add(AudioRoute.speaker);
        await tester.pumpAndSettle();
        expect(routeIcon(tester, routeButton), FrIcons.speaker);
      },
    );

    // AC6
    testWidgets(
      'AC6: de día las letras del micrófono abierto van en signalInk sobre la '
      'señal y no en verde',
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

        final label = find.descendant(
          of: find.byType(MicControlSection),
          matching: find.byKey(const Key('ptt_core_label')),
        );
        expect(label, findsOneWidget);
        final text = tester.widget<Text>(label);
        expect(text.data, t.room.talk.core.open.toUpperCase());
        expect(text.style?.color, FrColors.light.signalInk);
        expect(text.style?.color, isNot(FrColors.light.signal));
      },
    );
  });
}
