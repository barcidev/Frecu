// AC5: CUANDO el anfitrión confirma «Cerrar frecu» ENTONCES se llama `leaveRoom` y ve la pantalla de cierre con la nota fuera del aire, «Fin de la transmisión», su mensaje, la duración, las personas y la nota, y «Volver al inicio» lo lleva al inicio.
// AC6: CUANDO la frecu se cierra sin que el usuario salga ENTONCES se cierran las hojas, se llama `leaveRoom` y ve la pantalla de cierre con el mensaje del anfitrión que cerró o de la señal perdida; la salida propia (`user_left`) no la muestra.
// AC7: CUANDO la app está en inglés ENTONCES la pantalla de cierre sale en inglés; CUANDO se reduce el movimiento ENTONCES la línea del cierre queda plana.
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
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/pages/room_page.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/room_closed_view.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

class _ActiveRoom extends RoomNotifier {
  _ActiveRoom(this._room);

  final Room _room;

  @override
  Room? build() => _room;
}

const _ok = Result<void>.success(null);
const _alice = Participant(id: 'peer-1', displayName: 'Alice', isHost: true);
const _bob = Participant(id: 'peer-2', displayName: 'Bob');
const _leo = Participant(id: 'peer-3', displayName: 'Leo');

/// Texto exacto sin distinguir mayúsculas (el estilo pasa algunos a
/// mayúsculas).
Finder _caseless(String text) => find.textContaining(
  RegExp('^${RegExp.escape(text)}\$', caseSensitive: false),
);

/// Frecu abierta hace [ago], con nota Mi4 salvo que se pida sin nota.
Room _openedAgo(Duration ago, {bool withNote = true}) => Room(
  id: 'room-123',
  name: 'Ruta 40',
  hostAddress: '192.168.43.1',
  port: 47800,
  accessCode: '4821',
  createdAt: DateTime.now().subtract(ago),
  note: withNote ? const RoomNote(semitone: 4) : null,
);

void main() {
  setUpAll(() {
    registerFallbackValue(TalkMode.pushToTalk);
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  late _MockRoomRepository room;
  late _MockVoiceRepository voice;
  late StreamController<RoomStatus> status;
  late StreamController<List<Participant>> participants;
  late String localId;

  setUp(() {
    // El núcleo PTT, la malla, el inicio y la línea del cierre animan sin
    // fin: con movimiento reducido quedan quietos y pumpAndSettle termina.
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
      ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    room = _MockRoomRepository();
    voice = _MockVoiceRepository();
    status = StreamController<RoomStatus>.broadcast();
    participants = StreamController<List<Participant>>.broadcast();
    localId = 'peer-2';

    when(() => room.watchStatus()).thenAnswer((_) => status.stream);
    when(() => room.watchParticipants()).thenAnswer((_) => participants.stream);
    when(() => room.localParticipantId).thenAnswer((_) => localId);
    when(() => room.leaveRoom()).thenAnswer((_) async => _ok);
    when(() => voice.initializeAudio()).thenAnswer((_) async => _ok);
    when(() => voice.watchIsTalking()).thenAnswer((_) => const Stream.empty());
    when(() => voice.watchSpeakingPeers())
        .thenAnswer((_) => const Stream.empty());
    when(() => voice.watchTalkMode()).thenAnswer((_) => const Stream.empty());
    when(() => voice.watchAudioRoute())
        .thenAnswer((_) => const Stream<AudioRoute>.empty());
    when(() => voice.watchAvailableAudioRoutes())
        .thenAnswer((_) => const Stream.empty());
    when(() => voice.setTalkMode(any())).thenAnswer((_) async => _ok);
    when(() => voice.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await status.close();
    await participants.close();
  });

  /// Entra a [active] con [people] conectados.
  Future<void> enterRoom(
    WidgetTester tester, {
    required Room active,
    List<Participant> people = const [_alice, _bob],
  }) async {
    final router = AppRouter();
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            roomRepositoryProvider.overrideWithValue(room),
            voiceRepositoryProvider.overrideWithValue(voice),
            roomNotifierProvider.overrideWith(() => _ActiveRoom(active)),
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

  /// Cierra la frecu como anfitrión con la hoja de salir.
  Future<void> closeAsHost(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('leave_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leave_confirm')));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('AC5: al cerrar la frecu el anfitrión ve el fin de la '
      'transmisión con la duración, las personas y la nota', (tester) async {
    localId = 'peer-1';
    await enterRoom(
      tester,
      active: _openedAgo(const Duration(minutes: 42, seconds: 17)),
      people: const [_alice, _bob, _leo],
    );
    participants.add(const [_alice, _bob]);
    await tester.pumpAndSettle();

    await closeAsHost(tester);

    verify(() => room.leaveRoom()).called(1);
    expect(find.byType(RoomClosedView), findsOneWidget);
    expect(find.byType(RoomHeader), findsNothing);
    expect(_caseless('Mi4 · fuera del aire'), findsOneWidget);
    expect(find.text('Fin de la transmisión'), findsOneWidget);
    expect(
      find.text(
        'Cerraste la frecu. Todos los participantes fueron desconectados.',
      ),
      findsOneWidget,
    );
    expect(textOf(tester, 'closure_duration'), matches(r'^42:(1[7-9]|2\d)$'));
    expect(textOf(tester, 'closure_people'), '03');
    expect(_caseless('Duración'), findsOneWidget);
    expect(_caseless('Personas'), findsOneWidget);
    expect(_caseless('Nota'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RoomClosedView),
        matching: find.byType(RoomNoteName),
      ),
      findsOneWidget,
    );
  });

  testWidgets('AC5: «Volver al inicio» lleva al inicio', (tester) async {
    localId = 'peer-1';
    await enterRoom(tester, active: _openedAgo(const Duration(minutes: 5)));
    await closeAsHost(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('closure_home')),
        matching: _caseless('Volver al inicio'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('closure_home')));
    await tester.pumpAndSettle();

    expect(find.byType(RoomPage), findsNothing);
  });

  testWidgets('AC5: la duración va en mm:ss y desde una hora en h:mm:ss', (
    tester,
  ) async {
    expect(formatClosureDuration(Duration.zero), '00:00');
    expect(
      formatClosureDuration(const Duration(minutes: 42, seconds: 17)),
      '42:17',
    );
    expect(
      formatClosureDuration(const Duration(hours: 1, minutes: 2, seconds: 5)),
      '1:02:05',
    );
  });

  testWidgets('AC6: si el anfitrión cierra la frecu se cierran las hojas, se '
      'suelta la frecu y se ve el fin de la transmisión', (tester) async {
    await enterRoom(tester, active: _openedAgo(const Duration(minutes: 3)));
    await tester.tap(find.byKey(const Key('audio_route_button')));
    await tester.pumpAndSettle();
    expect(find.byType(AudioRouteSheet), findsOneWidget);

    status.add(const RoomStatus.closed(reason: 'host_closed'));
    await tester.pumpAndSettle();

    expect(find.byType(AudioRouteSheet), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('La frecu fue cerrada por el anfitrión'), findsNothing);
    expect(find.text('Fin de la transmisión'), findsOneWidget);
    expect(
      find.text(
        'El anfitrión cerró la frecu. Puedes unirte a otra cuando quieras.',
      ),
      findsOneWidget,
    );
    expect(textOf(tester, 'closure_people'), '02');
    verify(() => room.leaveRoom()).called(1);
  });

  testWidgets('AC6: si se pierde la señal del anfitrión el cierre lo dice, '
      'y sin nota dice «Fuera del aire» y «—»', (tester) async {
    await enterRoom(
      tester,
      active: _openedAgo(
        const Duration(hours: 1, minutes: 2, seconds: 5),
        withNote: false,
      ),
    );

    status.add(const RoomStatus.closed(reason: 'host_unreachable'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Se perdió la señal del anfitrión. Puedes unirte a otra cuando '
        'quieras.',
      ),
      findsOneWidget,
    );
    expect(_caseless('Fuera del aire'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RoomClosedView),
        matching: find.text('—'),
      ),
      findsOneWidget,
    );
    expect(textOf(tester, 'closure_duration'), matches(r'^1:02:(0[5-9]|1\d)$'));
  });

  testWidgets('AC6: la salida propia (user_left) no muestra el cierre', (
    tester,
  ) async {
    await enterRoom(tester, active: _openedAgo(const Duration(minutes: 1)));

    status.add(const RoomStatus.closed(reason: 'user_left'));
    await tester.pumpAndSettle();

    expect(find.byType(RoomClosedView), findsNothing);
    verifyNever(() => room.leaveRoom());
  });

  testWidgets('AC7: en inglés el fin de la transmisión sale en inglés y, con '
      'movimiento reducido, la línea queda plana', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
    await enterRoom(tester, active: _openedAgo(const Duration(minutes: 9)));

    status.add(const RoomStatus.closed(reason: 'host_closed'));
    await tester.pumpAndSettle();

    expect(_caseless('E4 · off the air'), findsOneWidget);
    expect(find.text('End of transmission'), findsOneWidget);
    expect(
      find.text(
        'The host closed the frecu. You can join another one whenever you '
        'like.',
      ),
      findsOneWidget,
    );
    expect(_caseless('Duration'), findsOneWidget);
    expect(_caseless('People'), findsOneWidget);
    expect(_caseless('Back to home'), findsOneWidget);
    final line = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(ClosureLine),
        matching: find.byType(CustomPaint),
      ),
    );
    expect((line.painter! as ClosureLinePainter).still, isTrue);
  });
}
