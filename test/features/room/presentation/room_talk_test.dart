// AC2: CUANDO otra persona habla y el usuario está en PTT sin transmitir ENTONCES el núcleo muestra a quien habla; CUANDO el anfitrión está solo ENTONCES la pista invita a mostrar el QR.
// AC6: CUANDO el usuario está en la frecu activa ENTONCES la isla dice, por prioridad, reconectando, conectando, al aire con su tiempo, quién habla, micrófono abierto o silenciado con n/6, esperando a tu grupo o en línea con n/6.
// AC7: CUANDO la frecu está conectando o reconectando ENTONCES el núcleo queda en espera y no se puede hablar ni cambiar de modo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/status_island.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

MeshNode _node(
  String name,
  int slot, {
  bool me = false,
  bool host = false,
  bool speaking = false,
  MeshLink link = MeshLink.ok,
}) => MeshNode(
  id: name,
  name: name,
  slot: slot,
  isMe: me,
  isHost: host,
  speaking: speaking,
  link: link,
);

RoomTalk _talk({
  RoomStatus? status = const RoomStatus.connected(),
  TalkMode mode = TalkMode.pushToTalk,
  bool talking = false,
  List<MeshNode> nodes = const [],
}) {
  final slots = List<MeshNode?>.filled(meshSlotCount, null);
  for (final node in nodes) {
    slots[node.slot] = node;
  }
  return RoomTalk.from(
    status: status,
    mode: mode,
    talking: talking,
    nodes: slots,
  );
}

final List<MeshNode> _group = [
  _node('Jorge', 0, me: true),
  _node('Andrés', 1, host: true),
  _node('Ana', 2),
];

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('RoomTalk', () {
    test('AC6: cuenta las personas de la malla y sabe quién habla', () {
      final talk = _talk(
        nodes: [
          _node('Jorge', 0, me: true),
          _node('Ana', 2, speaking: true),
          _node('Leo', 5),
        ],
      );

      expect(talk.count, 3);
      expect(talk.speaker?.name, 'Ana');
      expect(talk.alone, isFalse);
    });

    test('AC6: la persona propia al aire no cuenta como quien habla', () {
      final talk = _talk(
        talking: true,
        nodes: [_node('Jorge', 0, me: true, speaking: true), _node('Ana', 2)],
      );

      expect(talk.speaker, isNull);
    });

    test('AC6: nadie habla si su enlace no está bien', () {
      final talk = _talk(
        status: const RoomStatus.reconnecting(),
        nodes: [
          _node('Jorge', 0, me: true),
          _node('Ana', 2, speaking: true, link: MeshLink.rec),
        ],
      );

      expect(talk.speaker, isNull);
    });

    test('AC2: el anfitrión está solo si es el único nodo y es el propio', () {
      expect(
        _talk(nodes: [_node('Jorge', 0, me: true, host: true)]).alone,
        isTrue,
      );
      expect(_talk(nodes: [_node('Jorge', 0, me: true)]).alone, isFalse);
      expect(_talk(nodes: [_node('Andrés', 1, host: true)]).alone, isFalse);
      expect(
        _talk(nodes: [_node('Jorge', 0, me: true, host: true), _node('Ana', 2)])
            .alone,
        isFalse,
      );
    });

    test('AC7: conectando y reconectando dejan el núcleo en espera', () {
      final reconnecting = _talk(status: const RoomStatus.reconnecting());
      final connecting = _talk(status: const RoomStatus.connecting());

      expect(reconnecting.link, TalkLink.reconnecting);
      expect(reconnecting.enabled, isFalse);
      expect(reconnecting.pttPhase(pressed: true), PttPhase.reconnecting);
      expect(connecting.link, TalkLink.connecting);
      expect(connecting.enabled, isFalse);
      expect(
        _talk(status: const RoomStatus.connecting(), talking: true).pttPhase(),
        PttPhase.connecting,
      );
      expect(_talk().enabled, isTrue);
      expect(_talk(status: null).link, TalkLink.ready);
      expect(_talk(status: const RoomStatus.idle()).enabled, isTrue);
    });

    test('AC2: fases del núcleo en PTT', () {
      final speaking = [..._group.take(2), _node('Ana', 2, speaking: true)];

      expect(_talk(nodes: _group).pttPhase(), PttPhase.idle);
      expect(_talk(nodes: _group).pttPhase(pressed: true), PttPhase.onAir);
      expect(_talk(talking: true, nodes: _group).pttPhase(), PttPhase.onAir);
      expect(_talk(nodes: speaking).pttPhase(), PttPhase.receiving);
      expect(_talk(talking: true, nodes: speaking).pttPhase(), PttPhase.onAir);
      expect(
        _talk(nodes: [_node('Jorge', 0, me: true, host: true)]).pttPhase(),
        PttPhase.alone,
      );
    });

    test('AC2: fases del núcleo con micrófono abierto', () {
      expect(
        _talk(mode: TalkMode.openMic, talking: true).pttPhase(),
        PttPhase.open,
      );
      expect(_talk(mode: TalkMode.openMic).pttPhase(), PttPhase.muted);
      expect(
        _talk(mode: TalkMode.openMic).pttPhase(pressed: true),
        PttPhase.muted,
      );
    });

    test('AC7: qué fases responden a la presión, al toque o a nada', () {
      for (final phase in PttPhase.values) {
        final kinds = [phase.isPush, phase.isToggle, phase.isWaiting];
        expect(kinds.where((kind) => kind), hasLength(1), reason: '$phase');
      }
      expect(PttPhase.receiving.isPush, isTrue);
      expect(PttPhase.muted.isToggle, isTrue);
      expect(PttPhase.reconnecting.isWaiting, isTrue);
    });

    test('AC6: prioridad de la isla', () {
      final speaking = [..._group.take(2), _node('Ana', 2, speaking: true)];
      final cases = <RoomTalk, IslandPhase>{
        _talk(status: const RoomStatus.reconnecting(), talking: true):
            IslandPhase.reconnecting,
        _talk(status: const RoomStatus.connecting(), talking: true):
            IslandPhase.connecting,
        _talk(talking: true, nodes: speaking): IslandPhase.onAir,
        _talk(nodes: speaking): IslandPhase.receiving,
        _talk(mode: TalkMode.openMic, talking: true, nodes: speaking):
            IslandPhase.receiving,
        _talk(mode: TalkMode.openMic, talking: true): IslandPhase.openMic,
        _talk(mode: TalkMode.openMic): IslandPhase.muted,
        _talk(nodes: [_node('Jorge', 0, me: true, host: true)]):
            IslandPhase.waiting,
        _talk(nodes: _group): IslandPhase.online,
      };
      for (final MapEntry(key: talk, value: phase) in cases.entries) {
        expect(talk.islandPhase, phase);
      }
    });

    test('AC6: el tiempo al aire va en minutos y segundos', () {
      expect(formatOnAir(Duration.zero), '00:00');
      expect(formatOnAir(const Duration(seconds: 4)), '00:04');
      expect(formatOnAir(const Duration(minutes: 1, seconds: 15)), '01:15');
    });
  });

  group('RoomStatusIsland', () {
    Future<StatusIsland> pumpIsland(
      WidgetTester tester,
      RoomTalk talk, {
      Duration? onAirFor,
    }) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RoomStatusIsland(talk: talk, onAirFor: onAirFor),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      return tester.widget<StatusIsland>(find.byType(StatusIsland));
    }

    testWidgets('AC6: en línea dice cuántas personas hay de 6', (tester) async {
      final island = await pumpIsland(tester, _talk(nodes: _group));

      expect(island.label, 'En línea · 3/6');
      expect(island.tone, StatusIslandTone.neutral);
      expect(find.text('EN LÍNEA · 3/6'), findsOneWidget);
      expect(tester.getSize(find.byType(RoomStatusIsland)).height, 44);
    });

    testWidgets('AC6: al aire lleva el relleno de señal y el tiempo', (
      tester,
    ) async {
      final island = await pumpIsland(
        tester,
        _talk(talking: true, nodes: _group),
        onAirFor: const Duration(seconds: 4),
      );

      expect(island.label, 'Al aire · 00:04');
      expect(island.tone, StatusIslandTone.onAir);
    });

    testWidgets(
      'AC6: quien habla sale con su nombre y el color de su lugar de noche',
      (tester) async {
        final island = await pumpIsland(
          tester,
          _talk(nodes: [..._group.take(2), _node('Ana', 2, speaking: true)]),
        );

        expect(island.label, 'Ana · hablando');
        expect(island.labelColor, FrColors.dark.p2);
        expect(island.labelColor, isNot(FrColors.light.p2));
      },
    );

    testWidgets('AC6: con micrófono abierto dice si transmite o está en '
        'silencio con n/6', (tester) async {
      var island = await pumpIsland(
        tester,
        _talk(mode: TalkMode.openMic, talking: true, nodes: _group),
      );
      expect(island.label, 'Micrófono abierto · 3/6');

      island = await pumpIsland(
        tester,
        _talk(mode: TalkMode.openMic, nodes: _group),
      );
      expect(island.label, 'Silenciado · 3/6');
    });

    testWidgets('AC6: el anfitrión solo está al aire esperando a su grupo', (
      tester,
    ) async {
      final island = await pumpIsland(
        tester,
        _talk(nodes: [_node('Jorge', 0, me: true, host: true)]),
      );

      expect(island.label, 'Al aire · esperando a tu grupo');
    });

    testWidgets('AC6: reconectando va en ámbar y conectando con la onda', (
      tester,
    ) async {
      var island = await pumpIsland(
        tester,
        _talk(status: const RoomStatus.reconnecting(), nodes: _group),
      );
      expect(island.label, 'Reconectando…');
      expect(island.tone, StatusIslandTone.warn);

      island = await pumpIsland(
        tester,
        _talk(status: const RoomStatus.connecting(), nodes: _group),
      );
      expect(island.label, 'Conectando…');
    });
  });
}
