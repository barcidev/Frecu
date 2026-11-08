// AC2: CUANDO el usuario transmite (PTT o micrófono abierto) ENTONCES el bisel y el anillo del núcleo PTT siguen, con su resorte, el nivel real de su micrófono en la escala del VU; CUANDO recibe a alguien ENTONCES el anillo de recepción sigue el nivel real del audio de esa persona; CUANDO no suenan ENTONCES vuelven a reposo (al aire, al mínimo de al aire). El núcleo ya no usa `frVoice`.
// AC3: CUANDO alguien habla en la malla ENTONCES su firma, su halo, su anillo, sus aristas y sus paquetes siguen el nivel real de su voz (la propia con el micrófono y las demás con su audio recibido) y en silencio vuelven a reposo. La malla ya no usa `frVoice`.
// AC4: CUANDO el sistema pide reducir el movimiento ENTONCES el núcleo y la malla muestran el nivel real a saltos, sin resorte, ondas ni paquetes.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
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
import 'package:frecu/features/room/presentation/widgets/room_mesh.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

const _jorge = Participant(id: 'p-1', displayName: 'Jorge', isHost: true);
const _ana = Participant(id: 'p-2', displayName: 'Ana');
const _leo = Participant(id: 'p-3', displayName: 'Leo');

/// Jorge (propio) en el 0, Ana hablando con nivel [ana] en el 1 y Leo, que
/// no habla pero trae nivel, en el 2.
List<MeshNode?> _scene(double ana, {bool anaSpeaks = true}) => [
  const MeshNode(id: 'p-1', name: 'Jorge', slot: 0, isMe: true),
  MeshNode(id: 'p-2', name: 'Ana', slot: 1, speaking: anaSpeaks, level: ana),
  const MeshNode(id: 'p-3', name: 'Leo', slot: 2, level: 0.9),
  null,
  null,
  null,
];

/// Avanza [motion] por los cuadros de [from] a [to] (a 60 por segundo).
void _frames(MeshMotion motion, int from, int to, List<MeshNode?> nodes) {
  for (var frame = from; frame <= to; frame++) {
    motion.advance(frame / 60, nodes);
  }
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Firma de [name] en la malla.
SignalSignature _signature(WidgetTester tester, String name) =>
    tester.widget<SignalSignature>(
      find.descendant(
        of: find.byType(RoomMesh),
        matching: find.byWidgetPredicate(
          (w) => w is SignalSignature && w.name == name,
        ),
      ),
    );

double _level(WidgetTester tester, String name) =>
    _signature(tester, name).levelOf?.call(0) ?? 0;

Future<void> _pumpMesh(WidgetTester tester, Map<String, double> levels) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: RoomMesh(
              participants: const [_jorge, _ana, _leo],
              localParticipantId: 'p-1',
              speakingPeers: const {'p-2'},
              localTalking: true,
              levels: levels,
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(TalkMode.pushToTalk);
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  group('Escena de la malla con nivel real', () {
    test('AC3: buildMeshNodes da a cada nodo su nivel por id', () {
      final nodes = buildMeshNodes(
        participants: const [_jorge, _ana, _leo],
        slots: const {'p-1': 0, 'p-2': 1, 'p-3': 2},
        localId: 'p-1',
        levels: const {'p-1': 0.4, 'p-2': 0.9},
      );

      expect(nodes[0]!.level, 0.4);
      expect(nodes[1]!.level, 0.9);
      expect(nodes[2]!.level, 0);
    });

    test('AC3: quien habla sigue su nivel con el resorte, lanza paquetes si '
        'suena y en silencio vuelve a reposo', () {
      final motion = MeshMotion()
        ..advance(0, _scene(0.8))
        ..advance(1 / 60, _scene(0.8));
      expect(motion.levels[1], greaterThan(0));
      expect(motion.levels[1], lessThan(0.8));

      _frames(motion, 2, 120, _scene(0.8));
      expect(motion.levels[1], closeTo(0.8, 0.01));
      expect(motion.levels[2], 0);
      expect(motion.packets.map((packet) => packet.from), everyElement(1));
      expect(motion.packets, isNotEmpty);

      _frames(motion, 121, 240, _scene(0.1));
      expect(motion.levels[1], closeTo(0.1, 0.01));
      expect(motion.packets, isEmpty);

      _frames(motion, 241, 360, _scene(0));
      expect(motion.levels[1], lessThan(0.04));
    });

    test('AC3: sin voz no hay nivel ni paquetes aunque hable, porque ya no '
        'sigue una onda simulada', () {
      final motion = MeshMotion();
      for (var frame = 0; frame <= 180; frame++) {
        motion.advance(frame / 60, _scene(0));
        expect(motion.levels, everyElement(0));
        expect(motion.packets, isEmpty);
      }
    });

    test('AC4: con movimiento reducido el nivel cambia a saltos y no hay '
        'paquetes', () {
      final motion = MeshMotion()..advance(0, _scene(0.7), reduced: true);
      expect(motion.levels[1], 0.7);

      motion.advance(0.1, _scene(0.2), reduced: true);
      expect(motion.levels[1], 0.2);
      expect(motion.levels[2], 0);
      expect(motion.packets, isEmpty);
    });
  });

  group('RoomMesh con nivel real', () {
    testWidgets('AC3: la firma de cada persona sigue su nivel, la propia con '
        'el micrófono, y solo si habla', (tester) async {
      _reduceMotion(tester);
      await _pumpMesh(tester, const {'p-1': 0.35, 'p-2': 0.8, 'p-3': 0.9});
      await tester.pump();

      expect(_level(tester, 'Jorge'), 0.35);
      expect(_level(tester, 'Ana'), 0.8);
      expect(_level(tester, 'Leo'), 0);

      await _pumpMesh(tester, const {'p-2': 0.2});
      await tester.pump();
      expect(_level(tester, 'Ana'), 0.2);
      expect(_level(tester, 'Jorge'), 0);
    });

    testWidgets('AC3: sin movimiento reducido la firma sube con el resorte y '
        'vuelve a reposo en silencio', (tester) async {
      await _pumpMesh(tester, const {'p-2': 0.8});
      await tester.pump(const Duration(milliseconds: 16));
      expect(_level(tester, 'Ana'), greaterThan(0));
      expect(_level(tester, 'Ana'), lessThan(0.8));

      await tester.pump(const Duration(seconds: 1));
      expect(_level(tester, 'Ana'), closeTo(0.8, 0.01));

      await _pumpMesh(tester, const {});
      await tester.pump(const Duration(seconds: 2));
      expect(_level(tester, 'Ana'), lessThan(0.04));
    });
  });

  group('Frecu activa', () {
    late _MockRoomRepository room;
    late _MockVoiceRepository voice;
    late StreamController<List<Participant>> participants;
    late StreamController<Set<String>> speaking;
    late StreamController<double> local;
    late StreamController<Map<String, double>> peers;

    setUp(() {
      _setUpRoom(
        room = _MockRoomRepository(),
        voice = _MockVoiceRepository(),
        participants = StreamController<List<Participant>>.broadcast(),
        speaking = StreamController<Set<String>>.broadcast(),
      );
      local = StreamController<double>.broadcast();
      peers = StreamController<Map<String, double>>.broadcast();
      when(voice.watchLocalLevel).thenAnswer((_) => local.stream);
      when(voice.watchPeerLevels).thenAnswer((_) => peers.stream);
    });

    tearDown(() async {
      for (final controller in [participants, speaking, local, peers]) {
        await controller.close();
      }
    });

    Future<void> enterRoom(WidgetTester tester) async {
      _reduceMotion(tester);
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
      participants.add(const [_jorge, _ana, _leo]);
      await tester.pumpAndSettle();
    }

    testWidgets('AC2: el núcleo recibe el nivel propio y el de quien habla '
        'en la escala del VU', (tester) async {
      await enterRoom(tester);
      final core = find.byType(PttCore);
      expect(tester.widget<PttCore>(core).level, 0);
      expect(tester.widget<PttCore>(core).speakerLevel, 0);

      local.add(1);
      peers.add(const {'p-2': 0.1, 'p-3': 0.5});
      await tester.pumpAndSettle();
      expect(tester.widget<PttCore>(core).level, 1);
      expect(tester.widget<PttCore>(core).speakerLevel, 0);

      speaking.add(const {'p-2'});
      await tester.pumpAndSettle();
      expect(
        tester.widget<PttCore>(core).speakerLevel,
        closeTo(1 - 20 / 48, 1e-9),
      );
    });

    testWidgets('AC3: la malla recibe el nivel de cada persona, la propia '
        'incluida', (tester) async {
      await enterRoom(tester);
      expect(tester.widget<RoomMesh>(find.byType(RoomMesh)).levels, {'p-1': 0});

      local.add(1);
      peers.add(const {'p-2': 0.1});
      await tester.pumpAndSettle();

      final levels = tester.widget<RoomMesh>(find.byType(RoomMesh)).levels;
      expect(levels.keys, unorderedEquals(['p-1', 'p-2']));
      expect(levels['p-1'], 1);
      expect(levels['p-2'], closeTo(1 - 20 / 48, 1e-9));

      speaking.add(const {'p-2'});
      await tester.pumpAndSettle();
      expect(_level(tester, 'Ana'), closeTo(1 - 20 / 48, 1e-9));
    });
  });
}

/// Dobles de la frecu activa: conectada, con [participants] y [speaking], y
/// la persona propia `p-1`.
void _setUpRoom(
  _MockRoomRepository room,
  _MockVoiceRepository voice,
  StreamController<List<Participant>> participants,
  StreamController<Set<String>> speaking,
) {
  const ok = Result<void>.success(null);
  when(room.watchStatus)
      .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
  when(room.watchParticipants).thenAnswer((_) => participants.stream);
  when(() => room.localParticipantId).thenReturn('p-1');
  when(voice.initializeAudio).thenAnswer((_) async => ok);
  when(voice.watchIsTalking).thenAnswer((_) => const Stream.empty());
  when(voice.watchSpeakingPeers).thenAnswer((_) => speaking.stream);
  when(voice.watchTalkMode).thenAnswer((_) => const Stream.empty());
  when(voice.watchAudioRoute)
      .thenAnswer((_) => Stream.value(AudioRoute.speaker));
  when(voice.watchAvailableAudioRoutes).thenAnswer((_) => const Stream.empty());
  when(() => voice.setTalkMode(any())).thenAnswer((_) async => ok);
  when(voice.dispose).thenAnswer((_) async {});
}
