// AC1: CUANDO el usuario está en una frecu activa ENTONCES ve arriba la isla, en medio la malla y abajo el selector PTT | Abierto con el núcleo PTT debajo.
// AC3: CUANDO elige «Abierto» o «PTT» en el selector ENTONCES se llama `setTalkMode` con ese modo.
// AC4: CUANDO el modo es micrófono abierto y la salida es el altavoz ENTONCES aparece el aviso de eco, que se puede cerrar y que se va al volver a PTT o cambiar la ruta.
// AC5: CUANDO el usuario entra a una frecu ENTONCES el modo pasa al modo por defecto de Ajustes si es distinto del actual, sin abrir el micrófono.
// AC6: CUANDO el usuario está en la frecu activa ENTONCES la isla dice en línea con n/6, al aire con el tiempo que avanza, quién habla, micrófono abierto o silenciado, esperando a tu grupo, conectando o reconectando.
// AC7: CUANDO la frecu reconecta ENTONCES el núcleo queda en espera, el selector no responde y, si se transmitía con el dedo, se deja de transmitir.
// AC8: CUANDO la app está en inglés ENTONCES el núcleo, el selector, la isla y el aviso salen en inglés.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/design/widgets/status_island.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

const _alice = Participant(id: 'peer-1', displayName: 'Alice', isHost: true);
const _bob = Participant(id: 'peer-2', displayName: 'Bob');

void main() {
  setUpAll(() {
    registerFallbackValue(TalkMode.pushToTalk);
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  late _MockRoomRepository room;
  late _MockVoiceRepository voice;
  late StreamController<RoomStatus> status;
  late StreamController<List<Participant>> participants;
  late StreamController<bool> talking;
  late StreamController<Set<String>> speaking;
  late StreamController<TalkMode> mode;
  late StreamController<AudioRoute> route;

  setUp(() {
    // El núcleo PTT y el inicio animan sin fin: con movimiento reducido
    // quedan quietos y pumpAndSettle termina.
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
      ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    room = _MockRoomRepository();
    voice = _MockVoiceRepository();
    status = StreamController<RoomStatus>.broadcast();
    participants = StreamController<List<Participant>>.broadcast();
    talking = StreamController<bool>.broadcast();
    speaking = StreamController<Set<String>>.broadcast();
    mode = StreamController<TalkMode>.broadcast();
    route = StreamController<AudioRoute>.broadcast();

    when(() => room.watchStatus()).thenAnswer((_) => status.stream);
    when(() => room.watchParticipants()).thenAnswer((_) => participants.stream);
    when(() => voice.initializeAudio()).thenAnswer((_) async => _ok);
    when(() => voice.watchIsTalking()).thenAnswer((_) => talking.stream);
    when(() => voice.watchSpeakingPeers()).thenAnswer((_) => speaking.stream);
    when(() => voice.watchTalkMode()).thenAnswer((_) => mode.stream);
    when(() => voice.watchAudioRoute()).thenAnswer((_) => route.stream);
    when(() => voice.watchAvailableAudioRoutes())
        .thenAnswer((_) => const Stream.empty());
    when(() => voice.startTalking()).thenAnswer((_) async => _ok);
    when(() => voice.stopTalking()).thenAnswer((_) async => _ok);
    when(() => voice.setTalkMode(any())).thenAnswer((_) async => _ok);
    when(() => voice.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    for (final controller in [
      status,
      participants,
      talking,
      speaking,
      mode,
      route,
    ]) {
      await controller.close();
    }
  });

  /// Entra a la frecu con [people] conectados.
  Future<void> enterRoom(
    WidgetTester tester, {
    List<Participant> people = const [_alice, _bob],
  }) async {
    final router = AppRouter();
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            roomRepositoryProvider.overrideWithValue(room),
            voiceRepositoryProvider.overrideWithValue(voice),
          ],
          child: FrecuApp(appRouter: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(RoomRoute(roomId: 'room-123')));
    await tester.pumpAndSettle();
    status.add(const RoomStatus.connected());
    participants.add(people);
    await tester.pumpAndSettle();
  }

  StatusIsland island(WidgetTester tester) =>
      tester.widget<StatusIsland>(find.byType(StatusIsland));

  String coreText(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('AC1: la isla va arriba y el selector y el núcleo debajo de '
      'la malla', (tester) async {
    await enterRoom(tester);

    final islandBox = tester.getRect(find.byType(StatusIsland));
    final header = tester.getRect(find.byType(RoomHeader));
    final selector = tester.getRect(find.byType(FrSegmented<TalkMode>));
    final core = tester.getRect(find.byType(PttCore));
    expect(islandBox.bottom, lessThanOrEqualTo(header.top));
    expect(selector.bottom, lessThanOrEqualTo(core.top));
    expect(find.text('PTT'), findsOneWidget);
    expect(find.text('ABIERTO'), findsOneWidget);
    expect(coreText(tester, 'ptt_core_label'), 'MANTÉN');
  });

  testWidgets('AC6: la isla dice «En línea» con las personas de la malla', (
    tester,
  ) async {
    await enterRoom(tester);
    expect(island(tester).label, 'En línea · 2/6');

    participants.add(const [
      _alice,
      _bob,
      Participant(id: 'peer-3', displayName: 'Leo'),
    ]);
    await tester.pumpAndSettle();
    expect(island(tester).label, 'Leo se unió');

    await tester.pump(RoomIslandEvent.duration);
    await tester.pumpAndSettle();
    expect(island(tester).label, 'En línea · 3/6');
  });

  testWidgets('AC6: al transmitir en PTT la isla y el núcleo dicen «Al aire» '
      'con el tiempo que avanza', (tester) async {
    await enterRoom(tester);

    talking.add(true);
    await tester.pump();
    await tester.pump();
    expect(island(tester).label, 'Al aire · 00:00');
    expect(island(tester).tone, StatusIslandTone.onAir);

    await tester.pump(const Duration(seconds: 1));
    expect(island(tester).label, 'Al aire · 00:01');
    await tester.pump(const Duration(seconds: 2));
    expect(island(tester).label, 'Al aire · 00:03');
    expect(coreText(tester, 'ptt_core_timer'), '00:03');

    talking.add(false);
    await tester.pumpAndSettle();
    expect(island(tester).label, 'En línea · 2/6');
  });

  testWidgets('AC6: cuando otra persona habla la isla la nombra con el color '
      'de su lugar y el núcleo la anuncia', (tester) async {
    await enterRoom(tester);

    speaking.add({'peer-2'});
    await tester.pumpAndSettle();

    expect(island(tester).label, 'Bob · hablando');
    expect(island(tester).labelColor, FrColors.dark.p2);
    expect(
      coreText(tester, 'ptt_core_hint'),
      'BOB ESTÁ HABLANDO · PUEDES RESPONDER',
    );
  });

  testWidgets('AC6: con micrófono abierto la isla dice si está abierto o '
      'silenciado', (tester) async {
    await enterRoom(tester);

    mode.add(TalkMode.openMic);
    await tester.pumpAndSettle();
    expect(island(tester).label, 'Silenciado · 2/6');
    expect(coreText(tester, 'ptt_core_label'), 'SILENCIO');

    talking.add(true);
    await tester.pumpAndSettle();
    expect(island(tester).label, 'Micrófono abierto · 2/6');
    expect(coreText(tester, 'ptt_core_label'), 'ABIERTO');
  });

  testWidgets('AC6: el anfitrión solo está al aire esperando a su grupo', (
    tester,
  ) async {
    when(() => room.localParticipantId).thenReturn('me');
    await enterRoom(
      tester,
      people: const [Participant(id: 'me', displayName: 'Jorge', isHost: true)],
    );

    expect(island(tester).label, 'Al aire · esperando a tu grupo');
    expect(
      coreText(tester, 'ptt_core_hint'),
      'MUESTRA EL QR PARA QUE TU GRUPO SE UNA',
    );
  });

  testWidgets('AC7: al reconectar la isla avisa en ámbar, el núcleo queda en '
      'espera y el selector no responde', (tester) async {
    await enterRoom(tester);

    status.add(const RoomStatus.reconnecting());
    await tester.pumpAndSettle();

    expect(island(tester).label, 'Reconectando…');
    expect(island(tester).tone, StatusIslandTone.warn);
    expect(coreText(tester, 'ptt_core_label'), 'EN ESPERA');
    expect(coreText(tester, 'ptt_core_hint'), 'RECUPERANDO LA CONEXIÓN…');

    await tester.tap(find.byKey(const Key('mode_open_mic')));
    await tester.pumpAndSettle();
    verifyNever(() => voice.setTalkMode(any()));
  });

  testWidgets('AC7: si se cae la conexión con el dedo en el núcleo se deja '
      'de transmitir', (tester) async {
    await enterRoom(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('ptt_button'))),
    );
    await tester.pump();
    verify(() => voice.startTalking()).called(1);

    status.add(const RoomStatus.reconnecting());
    await tester.pump();
    await tester.pump();
    verify(() => voice.stopTalking()).called(1);

    await gesture.up();
    await tester.pump();
    verifyNever(() => voice.stopTalking());
  });

  testWidgets('AC7: conectando la isla y el núcleo esperan al anfitrión', (
    tester,
  ) async {
    await enterRoom(tester);

    status.add(const RoomStatus.connecting());
    await tester.pump();
    await tester.pump();

    expect(island(tester).label, 'Conectando…');
    expect(coreText(tester, 'ptt_core_hint'), 'CONECTANDO CON EL ANFITRIÓN…');
  });

  testWidgets('AC3: el selector PTT | Abierto cambia el modo de habla', (
    tester,
  ) async {
    await enterRoom(tester);

    await tester.tap(find.byKey(const Key('mode_open_mic')));
    await tester.pumpAndSettle();
    verify(() => voice.setTalkMode(TalkMode.openMic)).called(1);

    mode.add(TalkMode.openMic);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mode_ptt')));
    await tester.pumpAndSettle();
    verify(() => voice.setTalkMode(TalkMode.pushToTalk)).called(1);
  });

  testWidgets('AC4: con micrófono abierto y altavoz aparece el aviso de eco, '
      'que se puede cerrar y vuelve la próxima vez', (tester) async {
    await enterRoom(tester);
    expect(find.byKey(const Key('echo_notice')), findsNothing);

    mode.add(TalkMode.openMic);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('echo_notice')), findsOneWidget);
    expect(
      find.textContaining('Micrófono abierto con altavoz.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Usa audífonos para evitar eco.'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Cerrar aviso'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('echo_notice')), findsNothing);

    mode.add(TalkMode.pushToTalk);
    await tester.pumpAndSettle();
    mode.add(TalkMode.openMic);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('echo_notice')), findsOneWidget);
  });

  testWidgets('AC4: el aviso de eco se va al cambiar la ruta de audio', (
    tester,
  ) async {
    await enterRoom(tester);
    mode.add(TalkMode.openMic);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('echo_notice')), findsOneWidget);

    route.add(AudioRoute.earpiece);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('echo_notice')), findsNothing);

    route.add(AudioRoute.speaker);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('echo_notice')), findsOneWidget);
  });

  testWidgets('AC5: al entrar aplica el modo por defecto de Ajustes sin abrir '
      'el micrófono', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'settings.defaultTalkMode': 'openMic',
        });
    addTearDown(
      () => SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty(),
    );

    await enterRoom(tester);

    verify(() => voice.setTalkMode(TalkMode.openMic)).called(1);
    verifyNever(() => voice.startTalking());
  });

  testWidgets('AC5: si el modo ya es el de Ajustes no lo cambia', (
    tester,
  ) async {
    await enterRoom(tester);

    verifyNever(() => voice.setTalkMode(any()));
  });

  testWidgets('AC8: en inglés el núcleo, el selector, la isla y el aviso '
      'salen en inglés', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

    await enterRoom(tester);
    expect(island(tester).label, 'Online · 2/6');
    expect(coreText(tester, 'ptt_core_label'), 'HOLD');
    expect(coreText(tester, 'ptt_core_hint'), 'HOLD TO TALK');
    expect(find.text('OPEN'), findsOneWidget);

    mode.add(TalkMode.openMic);
    await tester.pumpAndSettle();
    expect(island(tester).label, 'Muted · 2/6');
    expect(find.textContaining('Open mic on speaker.'), findsOneWidget);
  });
}

const Result<void> _ok = Result.success(null);
