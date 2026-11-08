// AC1: CUANDO el usuario está en una frecu activa ENTONCES ve la malla de 6 lugares sobre un lienzo de 390 × 304 (centro en (195, 138), radio 104, a 90°, 150°, 210°, 270°, 330° y 30°) con un nodo por participante: su firma de señal (`SignalSignature` de su nombre), su nombre debajo y su papel («Tú», «Tú · anfitrión» o «Anfitrión»); la persona propia está en el lugar 0 con el color de la señal, cada participante conserva su lugar y su color mientras siga y quien llega toma el primer lugar libre; hay una arista entre cada par de nodos y cada lugar vacío muestra un círculo punteado con «+» y «Libre», que al tocarlo abre la invitación QR.
// AC2: CUANDO alguien habla (un participante remoto en `speakingPeers` o con `isSpeaking`, o la persona propia al transmitir) ENTONCES su nodo crece con halo y anillo de su color, su firma ondula con su nivel de voz, su etiqueta dice «Hablando» (o «Al aire» si es la propia) en su color, sus aristas se degradan desde su nodo y salen paquetes de voz hacia cada nodo conectado; CUANDO deja de hablar ENTONCES el nodo vuelve al reposo y los paquetes se acaban.
// AC3: CUANDO la frecu está reconectando ENTONCES todas las aristas son punteadas en ámbar, los anillos son punteados en ámbar, las firmas pasan a «enlazando», las etiquetas dicen «Reconectando» en ámbar y no hay halos ni paquetes aunque alguien hable; CUANDO la frecu está conectando o un participante está conectando ENTONCES su etiqueta dice «Conectando», su firma está enlazando y sus aristas son punteadas; un participante silenciado dice «Silenciado» con la firma aplanada.
// AC4: CUANDO alguien se une ENTONCES su nodo aparece con el resorte del prototipo (escala `1 − e^(−6a)·cos(11a)` entre 0 y 1,25 durante 1,6 s) y sus aristas se funden en 0,7 s; CUANDO el sistema pide reducir el movimiento ENTONCES los nodos aparecen a escala 1 sin resorte, la malla no anima ni lanza paquetes y quien habla se sigue viendo por su halo, su anillo y su etiqueta.
// AC6: CUANDO el usuario está en la frecu activa ENTONCES ... con tema claro, la etiqueta y la firma propias y el texto «Hablando» del micrófono abierto van en `signalFg`, nunca en verde sobre blanco.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/i18n/strings.g.dart';

const jorge = Participant(id: 'p-1', displayName: 'Jorge', isHost: true);
const ana = Participant(id: 'p-2', displayName: 'Ana');
const leo = Participant(id: 'p-3', displayName: 'Leo');
const sofi = Participant(id: 'p-4', displayName: 'Sofi');

const allSlots = {'p-1': 0, 'p-2': 1, 'p-3': 2, 'p-4': 3, 'p-5': 4};

void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> pumpMesh(
  WidgetTester tester, {
  required List<Participant> participants,
  String? localId = 'p-1',
  Set<String> speakingPeers = const {},
  bool localTalking = false,
  RoomStatus status = const RoomStatus.connected(),
  VoidCallback? onInvite,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: RoomMesh(
            participants: participants,
            localParticipantId: localId,
            speakingPeers: speakingPeers,
            localTalking: localTalking,
            status: status,
            onInvite: onInvite,
          ),
        ),
      ),
    ),
  );
}

Finder signatureOf(String name) => find.byWidgetPredicate(
  (widget) => widget is SignalSignature && widget.name == name,
);

SignalSignature signature(WidgetTester tester, String name) =>
    tester.widget<SignalSignature>(signatureOf(name));

Offset meshOrigin(WidgetTester tester) =>
    tester.getTopLeft(find.byType(RoomMesh));

Offset slotCenter(WidgetTester tester, int slot) =>
    meshOrigin(tester) + meshSlots(meshCanvas)[slot];

Color? textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

double silentLevel(WidgetTester tester, String name) =>
    signature(tester, name).levelOf?.call(0) ?? 0;

/// Escena con Ana hablando en el lugar 1, Leo en el 2 y Sofi enlazando en el
/// 3.
List<MeshNode?> talkingScene({
  bool anaSpeaks = true,
  bool withLeo = true,
  MeshLink link = MeshLink.ok,
}) => [
  MeshNode(id: 'p-1', name: 'Jorge', slot: 0, isMe: true, link: link),
  MeshNode(id: 'p-2', name: 'Ana', slot: 1, speaking: anaSpeaks, link: link),
  if (withLeo) MeshNode(id: 'p-3', name: 'Leo', slot: 2, link: link) else null,
  const MeshNode(id: 'p-4', name: 'Sofi', slot: 3, link: MeshLink.link),
  null,
  null,
];

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  group('Escena de la malla', () {
    test('AC1: los 6 lugares forman un hexágono de radio 104 alrededor de '
        '(w/2, h/2 − 14)', () {
      expect(meshCanvas, const Size(390, 304));
      expect(meshRadius, 104);

      final slots = meshSlots(meshCanvas);
      const expected = [
        Offset(195, 242),
        Offset(104.93336, 190),
        Offset(104.93336, 86),
        Offset(195, 34),
        Offset(285.06664, 86),
        Offset(285.06664, 190),
      ];
      expect(slots, hasLength(6));
      for (var i = 0; i < 6; i++) {
        expect(slots[i].dx, closeTo(expected[i].dx, 1e-3), reason: '$i');
        expect(slots[i].dy, closeTo(expected[i].dy, 1e-3), reason: '$i');
      }

      final other = meshSlots(const Size(400, 300));
      expect(other[0].dx, closeTo(200, 1e-9));
      expect(other[0].dy, closeTo(240, 1e-9));
    });

    test(
      'AC1: la persona propia va al lugar 0 y los demás al primer lugar libre '
      'en el orden del prototipo: arriba (3), abajo a la izquierda (1)…',
      () {
        final slots = assignMeshSlots(
          previous: const {},
          participants: const [ana, jorge, leo],
          localId: 'p-1',
        );

        expect(slots, {'p-1': 0, 'p-2': 3, 'p-3': 1});
      },
    );

    test(
      'AC1: cada participante conserva su lugar y quien llega toma el primer '
      'lugar libre',
      () {
        final slots = assignMeshSlots(
          previous: const {'p-1': 0, 'p-2': 3, 'p-3': 1},
          participants: const [jorge, leo, sofi],
          localId: 'p-1',
        );

        expect(slots, {'p-1': 0, 'p-3': 1, 'p-4': 3});
      },
    );

    test('AC1: sin id propio los nodos llenan los lugares 3, 1, 5, 2 y 4 y '
        'luego el 0, hasta 6', () {
      final many = List.generate(
        7,
        (i) => Participant(id: 'x$i', displayName: 'X$i'),
      );

      final slots = assignMeshSlots(
        previous: const {},
        participants: many,
        localId: null,
      );

      expect(slots, {'x0': 3, 'x1': 1, 'x2': 5, 'x3': 2, 'x4': 4, 'x5': 0});
    });

    test(
      'AC1: si el id propio llega después, la persona propia toma el lugar 0 y '
      'quien lo tenía pasa al primer lugar libre',
      () {
        final slots = assignMeshSlots(
          previous: const {'p-2': 0},
          participants: const [ana, jorge],
          localId: 'p-1',
        );

        expect(slots, {'p-1': 0, 'p-2': 3});
      },
    );

    test('AC1: hay una arista entre cada par de nodos', () {
      final nodes = <MeshNode?>[
        const MeshNode(id: 'p-1', name: 'Jorge', slot: 0, isMe: true),
        const MeshNode(id: 'p-2', name: 'Ana', slot: 1),
        null,
        const MeshNode(id: 'p-4', name: 'Sofi', slot: 3),
        null,
        null,
      ];

      final edges = meshEdges(nodes);

      expect(edges.map((e) => (e.from, e.to)).toSet(), {
        (0, 1),
        (0, 3),
        (1, 3),
      });
      expect(edges, hasLength(3));
      expect(edges.every((e) => !e.weak), isTrue);
    });

    test(
      'AC2: buildMeshNodes marca a la persona propia, al anfitrión y a quien '
      'habla',
      () {
        const leoTalking = Participant(
          id: 'p-3',
          displayName: 'Leo',
          isSpeaking: true,
        );

        final nodes = buildMeshNodes(
          participants: const [jorge, ana, leoTalking, sofi],
          slots: allSlots,
          localId: 'p-1',
          speakingPeers: const {'p-2'},
          localTalking: true,
          status: const RoomStatus.connected(),
        );

        expect(nodes, hasLength(6));
        expect(nodes[4], isNull);
        expect(nodes[5], isNull);
        final me = nodes[0]!;
        expect(me.id, 'p-1');
        expect(me.name, 'Jorge');
        expect(me.slot, 0);
        expect(me.isMe, isTrue);
        expect(me.isHost, isTrue);
        expect(me.speaking, isTrue);
        expect(me.link, MeshLink.ok);
        expect(nodes[1]!.name, 'Ana');
        expect(nodes[1]!.isMe, isFalse);
        expect(nodes[1]!.speaking, isTrue);
        expect(nodes[2]!.speaking, isTrue);
        expect(nodes[3]!.speaking, isFalse);

        final quiet = buildMeshNodes(
          participants: const [jorge, ana],
          slots: allSlots,
          localId: 'p-1',
        );
        expect(quiet[0]!.speaking, isFalse);
        expect(quiet[1]!.speaking, isFalse);
        expect(quiet[0]!.link, MeshLink.ok);
      },
    );

    test('AC3: reconectando pone a todos en rec, conectando en link y cada '
        'participante sigue su estado de conexión', () {
      List<MeshLink> links(
        RoomStatus status, [
        List<Participant> participants = const [jorge, ana],
      ]) => buildMeshNodes(
        participants: participants,
        slots: allSlots,
        localId: 'p-1',
        status: status,
      ).nonNulls.map((node) => node.link).toList();

      expect(
        links(const RoomStatus.reconnecting()),
        everyElement(MeshLink.rec),
      );
      expect(links(const RoomStatus.connecting()), everyElement(MeshLink.link));

      const pepe = Participant(
        id: 'p-3',
        displayName: 'Pepe',
        connectionState: PeerConnectionState.connecting,
      );
      const rita = Participant(
        id: 'p-4',
        displayName: 'Rita',
        connectionState: PeerConnectionState.reconnecting,
      );
      const tito = Participant(
        id: 'p-5',
        displayName: 'Tito',
        connectionState: PeerConnectionState.disconnected,
      );
      expect(
        links(const RoomStatus.connected(), const [
          jorge,
          ana,
          pepe,
          rita,
          tito,
        ]),
        [MeshLink.ok, MeshLink.ok, MeshLink.link, MeshLink.rec, MeshLink.off],
      );
    });

    test(
      'AC1: la leyenda dice tú, tú · anfitrión o anfitrión según el papel',
      () {
        expect(
          meshCaption(
            const MeshNode(
              id: 'a',
              name: 'A',
              slot: 0,
              isMe: true,
              isHost: true,
            ),
          ),
          MeshCaption.youHost,
        );
        expect(
          meshCaption(const MeshNode(id: 'a', name: 'A', slot: 0, isMe: true)),
          MeshCaption.you,
        );
        expect(
          meshCaption(
            const MeshNode(id: 'b', name: 'B', slot: 1, isHost: true),
          ),
          MeshCaption.host,
        );
        expect(
          meshCaption(const MeshNode(id: 'c', name: 'C', slot: 2)),
          MeshCaption.none,
        );
      },
    );

    test('AC2: quien habla dice hablando, o al aire si es la propia', () {
      expect(
        meshCaption(
          const MeshNode(id: 'b', name: 'B', slot: 1, speaking: true),
        ),
        MeshCaption.speaking,
      );
      expect(
        meshCaption(
          const MeshNode(
            id: 'a',
            name: 'A',
            slot: 0,
            isMe: true,
            isHost: true,
            speaking: true,
          ),
        ),
        MeshCaption.onAir,
      );
    });

    test(
      'AC3: conectando, reconectando y silenciado mandan sobre el papel y el '
      'habla',
      () {
        expect(
          meshCaption(
            const MeshNode(
              id: 'a',
              name: 'A',
              slot: 0,
              isMe: true,
              speaking: true,
              link: MeshLink.link,
            ),
          ),
          MeshCaption.connecting,
        );
        expect(
          meshCaption(
            const MeshNode(
              id: 'b',
              name: 'B',
              slot: 1,
              isHost: true,
              speaking: true,
              link: MeshLink.rec,
            ),
          ),
          MeshCaption.reconnecting,
        );
        expect(
          meshCaption(
            const MeshNode(
              id: 'c',
              name: 'C',
              slot: 2,
              speaking: true,
              muted: true,
            ),
          ),
          MeshCaption.muted,
        );
      },
    );

    test('AC3: las aristas de un nodo que no está ok son punteadas', () {
      final nodes = <MeshNode?>[
        const MeshNode(id: 'p-1', name: 'Jorge', slot: 0, isMe: true),
        const MeshNode(id: 'p-2', name: 'Ana', slot: 1),
        const MeshNode(id: 'p-3', name: 'Leo', slot: 2, link: MeshLink.rec),
        null,
        null,
        null,
      ];

      final weak = {
        for (final edge in meshEdges(nodes)) (edge.from, edge.to): edge.weak,
      };

      expect(weak, {(0, 1): false, (0, 2): true, (1, 2): true});
    });

    test(
      'AC4: quien llega aparece con el resorte del prototipo y sus aristas se '
      'funden en 0,7 s',
      () {
        double spring(double a) => 1 - math.exp(-6 * a) * math.cos(11 * a);

        expect(meshAppearScale(0), closeTo(0, 1e-9));
        expect(meshAppearScale(0.3), closeTo(spring(0.3), 1e-9));
        expect(meshAppearScale(0.3), greaterThan(1));
        expect(meshAppearScale(1), closeTo(spring(1), 1e-9));
        expect(meshAppearScale(1.6), 1);
        expect(meshAppearScale(5), 1);
        for (var a = 0.0; a < 2; a += 0.01) {
          expect(meshAppearScale(a), inInclusiveRange(0, 1.25));
        }

        expect(meshEdgeAlpha(0), closeTo(0, 1e-9));
        expect(meshEdgeAlpha(0.5), closeTo(0.7, 1e-9));
        expect(meshEdgeAlpha(0.72), 1);
        expect(meshEdgeAlpha(3), 1);
      },
    );

    test(
      'AC2: quien habla lanza paquetes de voz hacia cada nodo conectado',
      () {
        final motion = MeshMotion();
        final nodes = talkingScene();
        final targets = <int>{};
        var loudest = 0.0;

        for (var frame = 0; frame <= 180; frame++) {
          motion.advance(frame / 60, nodes);
          loudest = math.max(loudest, motion.levels[1]);
          for (final packet in motion.packets) {
            expect(packet.from, 1);
            targets.add(packet.to);
          }
        }

        expect(motion.levels, hasLength(6));
        expect(loudest, greaterThan(0.18));
        expect(targets, {0, 2});
        expect(motion.levels[0], 0);
        expect(motion.levels[2], 0);
      },
    );

    test(
      'AC2: cuando deja de hablar su nivel vuelve al reposo y los paquetes se '
      'acaban',
      () {
        final motion = MeshMotion();
        for (var frame = 0; frame <= 180; frame++) {
          motion.advance(frame / 60, talkingScene());
        }
        for (var frame = 181; frame <= 270; frame++) {
          motion.advance(frame / 60, talkingScene(anaSpeaks: false));
        }

        expect(motion.packets, isEmpty);
        expect(motion.levels[1], lessThan(0.04));
      },
    );

    test('AC2: los paquetes hacia un nodo que se fue desaparecen', () {
      final motion = MeshMotion();
      var frame = 0;
      while (!motion.packets.any((packet) => packet.to == 2)) {
        expect(frame, lessThan(180), reason: 'sin paquetes hacia Leo');
        motion.advance(frame / 60, talkingScene());
        frame++;
      }

      motion.advance(frame / 60, talkingScene(withLeo: false));

      expect(motion.packets.where((packet) => packet.to == 2), isEmpty);
    });

    test('AC3: reconectando no hay halos ni paquetes aunque alguien hable', () {
      final motion = MeshMotion();
      for (var frame = 0; frame <= 120; frame++) {
        motion.advance(frame / 60, talkingScene());
      }

      motion.advance(121 / 60, talkingScene(link: MeshLink.rec));
      expect(motion.packets, isEmpty);
      expect(motion.levels, everyElement(0));

      for (var frame = 122; frame <= 240; frame++) {
        motion.advance(frame / 60, talkingScene(link: MeshLink.rec));
        expect(motion.packets, isEmpty);
        expect(motion.levels, everyElement(0));
      }
    });

    test(
      'AC4: con movimiento reducido quien habla queda en un nivel fijo de 0,6 '
      'y no hay paquetes',
      () {
        final motion = MeshMotion();
        for (var frame = 0; frame <= 120; frame++) {
          motion.advance(frame / 60, talkingScene(), reduced: true);
          expect(motion.levels[1], 0.6);
          expect(motion.levels[0], 0);
          expect(motion.packets, isEmpty);
        }
      },
    );
  });

  group('RoomMesh', () {
    testWidgets(
      'AC1: cada participante tiene su firma en su lugar del hexágono, con su '
      'nombre, su papel y su color',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(tester, participants: const [ana, jorge, leo]);
        await tester.pumpAndSettle();

        expect(find.byType(SignalSignature), findsNWidgets(3));
        expect(
          tester.getCenter(signatureOf('Jorge')),
          offsetMoreOrLessEquals(slotCenter(tester, 0), epsilon: 0.5),
        );
        expect(
          tester.getCenter(signatureOf('Ana')),
          offsetMoreOrLessEquals(slotCenter(tester, 3), epsilon: 0.5),
        );
        expect(
          tester.getCenter(signatureOf('Leo')),
          offsetMoreOrLessEquals(slotCenter(tester, 1), epsilon: 0.5),
        );

        expect(find.text('Jorge'), findsOneWidget);
        expect(find.text('Ana'), findsOneWidget);
        expect(find.text('Leo'), findsOneWidget);
        expect(find.text('TÚ · ANFITRIÓN'), findsOneWidget);
        expect(find.text('LIBRE'), findsNWidgets(3));

        const colors = FrColors.dark;
        expect(signature(tester, 'Jorge').color, colors.signalFg);
        expect(signature(tester, 'Ana').color, colors.p1);
        expect(signature(tester, 'Leo').color, colors.p2);
      },
    );

    testWidgets(
      'AC1: cada uno conserva su lugar y su color y quien llega toma el primer '
      'lugar libre',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(tester, participants: const [jorge, ana, leo]);
        await tester.pumpAndSettle();

        await pumpMesh(tester, participants: const [jorge, leo]);
        await tester.pumpAndSettle();

        expect(find.text('Ana'), findsNothing);
        expect(find.text('LIBRE'), findsNWidgets(4));
        expect(
          tester.getCenter(signatureOf('Leo')),
          offsetMoreOrLessEquals(slotCenter(tester, 1), epsilon: 0.5),
        );
        expect(signature(tester, 'Leo').color, FrColors.dark.p2);

        await pumpMesh(tester, participants: const [jorge, leo, sofi]);
        await tester.pumpAndSettle();

        expect(
          tester.getCenter(signatureOf('Sofi')),
          offsetMoreOrLessEquals(slotCenter(tester, 3), epsilon: 0.5),
        );
        expect(signature(tester, 'Sofi').color, FrColors.dark.p1);
        expect(
          tester.getCenter(signatureOf('Leo')),
          offsetMoreOrLessEquals(slotCenter(tester, 1), epsilon: 0.5),
        );
      },
    );

    testWidgets(
      'AC1: un lugar libre muestra «LIBRE» y al tocarlo pide la invitación',
      (tester) async {
        reduceMotion(tester);
        var invites = 0;
        await pumpMesh(
          tester,
          participants: const [jorge],
          onInvite: () => invites++,
        );
        await tester.pumpAndSettle();

        expect(find.text('LIBRE'), findsNWidgets(5));
        expect(find.byKey(const Key('mesh_free_slot_0')), findsNothing);
        final freeSlot = find.byKey(const Key('mesh_free_slot_3'));
        expect(freeSlot, findsOneWidget);
        expect(
          tester.getCenter(freeSlot),
          offsetMoreOrLessEquals(slotCenter(tester, 3), epsilon: 0.5),
        );

        await tester.tap(freeSlot);
        await tester.pump();

        expect(invites, 1);
      },
    );

    testWidgets(
      'AC2: quien habla dice «Hablando» en su color y la persona propia «Al '
      'aire», y al callar vuelven al reposo',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(
          tester,
          participants: const [jorge, ana, leo],
          speakingPeers: const {'p-2'},
          localTalking: true,
        );
        await tester.pumpAndSettle();

        const colors = FrColors.dark;
        expect(find.text('HABLANDO'), findsOneWidget);
        expect(find.text('AL AIRE'), findsOneWidget);
        expect(textColor(tester, 'HABLANDO'), colors.p1);
        expect(textColor(tester, 'Ana'), colors.p1);
        expect(textColor(tester, 'AL AIRE'), colors.signalFg);
        expect(find.byKey(const Key('speaking_indicator_p-2')), findsOneWidget);
        expect(find.byKey(const Key('speaking_indicator_p-1')), findsOneWidget);
        expect(find.byKey(const Key('speaking_indicator_p-3')), findsNothing);
        expect(signature(tester, 'Ana').levelOf?.call(0), closeTo(0.6, 1e-9));
        expect(silentLevel(tester, 'Leo'), 0);

        await pumpMesh(tester, participants: const [jorge, ana, leo]);
        await tester.pumpAndSettle();

        expect(find.text('HABLANDO'), findsNothing);
        expect(find.text('AL AIRE'), findsNothing);
        expect(find.byKey(const Key('speaking_indicator_p-2')), findsNothing);
        expect(silentLevel(tester, 'Ana'), 0);
      },
    );

    testWidgets('AC2: un participante con isSpeaking también se ve hablando', (
      tester,
    ) async {
      reduceMotion(tester);
      await pumpMesh(
        tester,
        participants: const [
          jorge,
          Participant(id: 'p-2', displayName: 'Ana', isSpeaking: true),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('HABLANDO'), findsOneWidget);
      expect(find.byKey(const Key('speaking_indicator_p-2')), findsOneWidget);
    });

    testWidgets(
      'AC3: al reconectar todos dicen «Reconectando» en ámbar, las firmas '
      'enlazan y nadie se ve hablando',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(
          tester,
          participants: const [jorge, ana],
          speakingPeers: const {'p-2'},
          status: const RoomStatus.reconnecting(),
        );
        await tester.pumpAndSettle();

        final reconnecting = find.text('RECONECTANDO');
        expect(reconnecting, findsNWidgets(2));
        for (final text in tester.widgetList<Text>(reconnecting)) {
          expect(text.style?.color, FrColors.dark.warn);
        }
        expect(find.text('HABLANDO'), findsNothing);
        expect(find.byKey(const Key('speaking_indicator_p-2')), findsNothing);
        expect(signature(tester, 'Jorge').mode, SignatureMode.link);
        expect(signature(tester, 'Ana').mode, SignatureMode.link);
        expect(silentLevel(tester, 'Ana'), 0);
      },
    );

    testWidgets('AC3: conectando dice «Conectando» con la firma enlazando y un '
        'silenciado dice «Silenciado» con la firma aplanada', (tester) async {
      reduceMotion(tester);
      const pepe = Participant(
        id: 'p-3',
        displayName: 'Pepe',
        connectionState: PeerConnectionState.connecting,
      );
      const rita = Participant(id: 'p-4', displayName: 'Rita', isMuted: true);
      await pumpMesh(tester, participants: const [jorge, pepe, rita]);
      await tester.pumpAndSettle();

      expect(find.text('CONECTANDO'), findsOneWidget);
      expect(signature(tester, 'Pepe').mode, SignatureMode.link);
      expect(find.text('SILENCIADO'), findsOneWidget);
      expect(signature(tester, 'Rita').mode, SignatureMode.muted);

      await pumpMesh(
        tester,
        participants: const [jorge, rita],
        status: const RoomStatus.connecting(),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONECTANDO'), findsNWidgets(2));
      expect(signature(tester, 'Jorge').mode, SignatureMode.link);
    });

    testWidgets('AC4: quien se une aparece con el resorte del prototipo', (
      tester,
    ) async {
      await pumpMesh(tester, participants: const [jorge]);
      await tester.pump(const Duration(seconds: 2));

      await pumpMesh(tester, participants: const [jorge, ana]);
      double width() => tester.getRect(signatureOf('Ana')).width;

      expect(width(), lessThan(20));

      await tester.pump(const Duration(milliseconds: 300));
      expect(width(), greaterThan(41));
      expect(width(), lessThanOrEqualTo(50));

      await tester.pump(const Duration(seconds: 2));
      expect(width(), closeTo(40, 0.01));
      expect(tester.getRect(signatureOf('Jorge')).width, closeTo(40, 0.01));
    });

    testWidgets(
      'AC4: con movimiento reducido quien se une aparece a escala 1 sin '
      'resorte y quien habla se sigue viendo',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(tester, participants: const [jorge]);
        await tester.pumpAndSettle();

        await pumpMesh(
          tester,
          participants: const [jorge, ana],
          speakingPeers: const {'p-2'},
        );
        expect(tester.getRect(signatureOf('Ana')).width, closeTo(40, 0.01));

        await tester.pumpAndSettle();
        expect(tester.getRect(signatureOf('Ana')).width, closeTo(40, 0.01));
        expect(find.text('HABLANDO'), findsOneWidget);
        expect(signature(tester, 'Ana').levelOf?.call(0), closeTo(0.6, 1e-9));
      },
    );

    testWidgets(
      'AC6: de día la etiqueta y la firma propias van en signalFg, nunca en '
      'verde',
      (tester) async {
        reduceMotion(tester);
        await pumpMesh(
          tester,
          participants: const [jorge, ana],
          localTalking: true,
          theme: AppTheme.light,
        );
        await tester.pumpAndSettle();

        const colors = FrColors.light;
        expect(signature(tester, 'Jorge').color, colors.signalFg);
        expect(signature(tester, 'Jorge').color, isNot(colors.signal));
        expect(textColor(tester, 'AL AIRE'), colors.signalFg);
        expect(textColor(tester, 'Jorge'), colors.signalFg);
      },
    );
  });
}
