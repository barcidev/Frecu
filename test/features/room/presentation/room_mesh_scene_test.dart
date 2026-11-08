// AC1: CUANDO el usuario está en una frecu activa ENTONCES ve la malla de 6 lugares sobre un lienzo de 390 × 304 (centro en (195, 138), radio 104, a 90°, 150°, 210°, 270°, 330° y 30°) con un nodo por participante: su firma de señal (`SignalSignature` de su nombre), su nombre debajo y su papel («Tú», «Tú · anfitrión» o «Anfitrión»); la persona propia está en el lugar 0 con el color de la señal, cada participante conserva su lugar y su color mientras siga y quien llega toma el primer lugar libre; hay una arista entre cada par de nodos y cada lugar vacío muestra un círculo punteado con «+» y «Libre», que al tocarlo abre la invitación QR.
// AC2: CUANDO alguien habla (un participante remoto en `speakingPeers` o con `isSpeaking`, o la persona propia al transmitir) ENTONCES su nodo crece con halo y anillo de su color, su firma ondula con su nivel de voz, su etiqueta dice «Hablando» (o «Al aire» si es la propia) en su color, sus aristas se degradan desde su nodo y salen paquetes de voz hacia cada nodo conectado; CUANDO deja de hablar ENTONCES el nodo vuelve al reposo y los paquetes se acaban.
// AC3: CUANDO la frecu está reconectando ENTONCES todas las aristas son punteadas en ámbar, los anillos son punteados en ámbar, las firmas pasan a «enlazando», las etiquetas dicen «Reconectando» en ámbar y no hay halos ni paquetes aunque alguien hable; CUANDO la frecu está conectando o un participante está conectando ENTONCES su etiqueta dice «Conectando», su firma está enlazando y sus aristas son punteadas; un participante silenciado dice «Silenciado» con la firma aplanada.
// AC4: CUANDO alguien se une ENTONCES su nodo aparece con el resorte del prototipo (escala `1 − e^(−6a)·cos(11a)` entre 0 y 1,25 durante 1,6 s) y sus aristas se funden en 0,7 s; CUANDO el sistema pide reducir el movimiento ENTONCES los nodos aparecen a escala 1 sin resorte, la malla no anima ni lanza paquetes y quien habla se sigue viendo por su halo, su anillo y su etiqueta.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/i18n/strings.g.dart';

import 'room_mesh_support.dart';

const allSlots = {'p-1': 0, 'p-2': 1, 'p-3': 2, 'p-4': 3, 'p-5': 4};

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
      'AC1: la persona propia va al lugar 0 y los demás al primer lugar libre',
      () {
        final slots = assignMeshSlots(
          previous: const {},
          participants: const [ana, jorge, leo],
          localId: 'p-1',
        );

        expect(slots, {'p-1': 0, 'p-2': 1, 'p-3': 2});
      },
    );

    test(
      'AC1: cada participante conserva su lugar y quien llega toma el primer '
      'lugar libre',
      () {
        final slots = assignMeshSlots(
          previous: const {'p-1': 0, 'p-2': 1, 'p-3': 2},
          participants: const [jorge, leo, sofi],
          localId: 'p-1',
        );

        expect(slots, {'p-1': 0, 'p-3': 2, 'p-4': 1});
      },
    );

    test('AC1: sin id propio los nodos llenan los lugares 1 a 5 y luego el 0, '
        'hasta 6', () {
      final many = List.generate(
        7,
        (i) => Participant(id: 'x$i', displayName: 'X$i'),
      );

      final slots = assignMeshSlots(
        previous: const {},
        participants: many,
        localId: null,
      );

      expect(slots, {'x0': 1, 'x1': 2, 'x2': 3, 'x3': 4, 'x4': 5, 'x5': 0});
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

        expect(slots, {'p-1': 0, 'p-2': 1});
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

    test('AC4: con movimiento reducido quien habla muestra su nivel a saltos, '
        'sin resorte, y no hay paquetes', () {
      final motion = MeshMotion();
      for (var frame = 0; frame <= 120; frame++) {
        final level = frame.isEven ? 0.6 : 0.3;
        motion.advance(frame / 60, talkingScene(level: level), reduced: true);
        expect(motion.levels[1], level);
        expect(motion.levels[0], 0);
        expect(motion.packets, isEmpty);
      }
    });
  });
}
