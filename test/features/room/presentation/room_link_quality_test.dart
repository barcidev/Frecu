// Señal débil (corte 1 de la épica de hardware V1): CUANDO el enlace de voz
// con alguien llega débil ENTONCES su nodo dice «Señal débil» (por debajo de
// conectando, reconectando y silenciado, y por encima de hablando), sus
// aristas se dibujan punteadas y la isla avisa «X · señal débil» en ámbar.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/link_quality.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

const _me = Participant(id: 'me', displayName: 'Jorge');
const _ana = Participant(id: 'ana', displayName: 'Ana');
const _leo = Participant(
  id: 'leo',
  displayName: 'Leo',
  linkQuality: LinkQuality.weak,
);
const _slots = {'me': 0, 'ana': 1, 'leo': 2};

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('buildMeshNodes', () {
    test('marca débil a quien tiene el enlace débil, nunca a la persona '
        'propia', () {
      final nodes = buildMeshNodes(
        participants: const [_me, _ana, _leo],
        slots: _slots,
        localId: 'me',
        status: const RoomStatus.connected(),
      );

      expect(nodes[0]!.weak, isFalse);
      expect(nodes[1]!.weak, isFalse);
      expect(nodes[2]!.weak, isTrue);
      // Débil no es caído: se le sigue oyendo.
      expect(nodes[2]!.link, MeshLink.ok);
    });

    test('la calidad no viaja en la señalización', () {
      expect(_leo.toJson().containsKey('linkQuality'), isFalse);
      expect(
        Participant.fromJson({
          'id': 'x',
          'displayName': 'X',
          'linkQuality': 'weak',
        }).linkQuality,
        LinkQuality.good,
      );
    });
  });

  group('meshCaption', () {
    const weak = MeshNode(id: 'leo', name: 'Leo', slot: 2, weak: true);

    test('dice «Señal débil»', () {
      expect(meshCaption(weak), MeshCaption.weak);
    });

    test('manda sobre hablando y el papel', () {
      expect(
        meshCaption(
          const MeshNode(
            id: 'leo',
            name: 'Leo',
            slot: 2,
            weak: true,
            speaking: true,
            isHost: true,
          ),
        ),
        MeshCaption.weak,
      );
    });

    test('silenciado, conectando y reconectando mandan sobre ella', () {
      expect(
        meshCaption(
          const MeshNode(id: 'l', name: 'L', slot: 2, weak: true, muted: true),
        ),
        MeshCaption.muted,
      );
      expect(
        meshCaption(
          const MeshNode(
            id: 'l',
            name: 'L',
            slot: 2,
            weak: true,
            link: MeshLink.link,
          ),
        ),
        MeshCaption.connecting,
      );
      expect(
        meshCaption(
          const MeshNode(
            id: 'l',
            name: 'L',
            slot: 2,
            weak: true,
            link: MeshLink.rec,
          ),
        ),
        MeshCaption.reconnecting,
      );
    });
  });

  test('meshEdges: las aristas de quien llega débil van punteadas', () {
    final nodes = buildMeshNodes(
      participants: const [_me, _ana, _leo],
      slots: _slots,
      localId: 'me',
    );

    final weak = {
      for (final edge in meshEdges(nodes)) (edge.from, edge.to): edge.weak,
    };

    expect(weak, {(0, 1): false, (0, 2): true, (1, 2): true});
  });

  group('RoomIslandEvent.weak', () {
    test('dice «X · señal débil»', () {
      expect(
        const RoomIslandEvent.weak(name: 'Leo').label,
        'Leo · señal débil',
      );
    });

    test('en inglés, «X · weak signal»', () async {
      await LocaleSettings.setLocale(AppLocale.en);
      expect(
        const RoomIslandEvent.weak(name: 'Leo').label,
        'Leo · weak signal',
      );
    });
  });
}
