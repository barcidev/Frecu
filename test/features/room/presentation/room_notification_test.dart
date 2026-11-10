import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/pages/room_notification.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/features/room/presentation/widgets/room_notification_art.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

const _me = MeshNode(id: 'me', name: 'Ana', slot: 0, isMe: true);
const _andres = MeshNode(id: 'a', name: 'Andrés', slot: 3, isHost: true);
const _beto = MeshNode(id: 'b', name: 'Beto', slot: 1);

List<MeshNode?> _nodes(List<MeshNode> present) {
  final nodes = List<MeshNode?>.filled(meshSlotCount, null);
  for (final node in present) {
    nodes[node.slot] = node;
  }
  return nodes;
}

RoomNotificationScene _scene({
  RoomTalk? talk,
  List<MeshNode> present = const [_me, _andres, _beto],
  AudioRoute route = AudioRoute.speaker,
  bool host = false,
  Duration? onAirFor,
  int? retryIn,
  RoomIslandEvent? event,
  RoomNotificationSos? sos,
  String? bluetoothName,
}) {
  final nodes = _nodes(present);
  return roomNotificationScene(
    roomName: 'Ruta 40',
    note: const RoomNote(semitone: 7),
    talk:
        talk ??
        RoomTalk.from(
          status: null,
          mode: TalkMode.pushToTalk,
          talking: false,
          nodes: nodes,
        ),
    nodes: nodes,
    route: route,
    host: host,
    onAirFor: onAirFor,
    retryIn: retryIn,
    event: event,
    sos: sos,
    bluetoothName: bluetoothName,
  );
}

List<(RoomNotificationAction, RoomNotificationIcon, String)> _buttons(
  RoomNotificationScene scene,
) => [
  for (final button in scene.buttons)
    (button.action, button.icon, button.label),
];

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));
  const c = FrColors.dark;

  group('roomNotificationScene', () {
    test(
      'en línea: la frecu, su nota, «En línea · n/6» y los tres botones',
      () {
        final scene = _scene();
        expect(scene.title, 'Ruta 40');
        expect(scene.note, 'Sol4');
        expect(scene.subtitle, 'En línea · 3/6');
        expect(scene.accent, c.signal);
        expect(scene.tapInvites, isFalse);
        expect(_buttons(scene), [
          (RoomNotificationAction.mic, RoomNotificationIcon.mic, 'Hablar'),
          (
            RoomNotificationAction.route,
            RoomNotificationIcon.speaker,
            'Salida de audio: Altavoz',
          ),
          (
            RoomNotificationAction.leave,
            RoomNotificationIcon.exit,
            'Salir de la frecu',
          ),
        ]);
        expect(scene.art.note, 'Sol4');
        expect(scene.art.nodes.nonNulls, hasLength(3));
      },
    );

    test('alguien habla: su nombre y el color de su canal, encendido en la '
        'malla', () {
      const speaking = MeshNode(id: 'b', name: 'Beto', slot: 1, speaking: true);
      final scene = _scene(present: const [_me, _andres, speaking]);
      expect(scene.subtitle, 'Beto · hablando');
      expect(scene.accent, c.p2);
      expect(scene.art.nodes[1], RoomArtNode(c.p2, RoomArtNodeState.hot));
    });

    test('al aire en PTT: tiempo al aire y «Cortar»', () {
      final scene = _scene(
        talk: RoomTalk.from(
          status: null,
          mode: TalkMode.pushToTalk,
          talking: true,
          nodes: _nodes(const [_me, _andres]),
        ),
        present: const [_me, _andres],
        onAirFor: const Duration(seconds: 4),
      );
      expect(scene.subtitle, 'Al aire · 00:04');
      expect(_buttons(scene).first, (
        RoomNotificationAction.mic,
        RoomNotificationIcon.stop,
        'Cortar',
      ));
    });

    test('micrófono abierto: silenciarse y volver a activarlo', () {
      final nodes = _nodes(const [_me, _andres]);
      final open = _scene(
        talk: RoomTalk.from(
          status: null,
          mode: TalkMode.openMic,
          talking: true,
          nodes: nodes,
        ),
        present: const [_me, _andres],
      );
      expect(open.subtitle, 'Micrófono abierto · 2/6');
      expect(_buttons(open).first, (
        RoomNotificationAction.mic,
        RoomNotificationIcon.mic,
        'Silenciarme',
      ));

      final muted = _scene(
        talk: RoomTalk.from(
          status: null,
          mode: TalkMode.openMic,
          talking: false,
          nodes: nodes,
        ),
        present: const [_me, _andres],
      );
      expect(muted.subtitle, 'Silenciado · 2/6');
      expect(muted.accent, c.tx3);
      expect(_buttons(muted).first, (
        RoomNotificationAction.mic,
        RoomNotificationIcon.micOff,
        'Activar micrófono',
      ));
    });

    test('reconectando: ámbar, cuenta atrás y solo salir', () {
      final scene = _scene(
        talk: const RoomTalk(
          link: TalkLink.reconnecting,
          mode: TalkMode.pushToTalk,
          talking: false,
          count: 3,
        ),
        retryIn: 4,
      );
      expect(scene.subtitle, 'Reconectando · 4 s');
      expect(scene.accent, c.warn);
      expect(_buttons(scene).map((b) => b.$1), [RoomNotificationAction.leave]);
    });

    test('un SOS manda: quién pide ayuda, hacia dónde y cómo atenderlo', () {
      final scene = _scene(
        sos: const RoomNotificationSos(
          id: 'a',
          name: 'Andrés',
          where: '120 m hacia el noreste',
        ),
      );
      expect(scene.title, 'Andrés necesita ayuda');
      expect(scene.subtitle, 'SOS · 120 m hacia el noreste');
      expect(scene.accent, c.alert);
      expect(_buttons(scene).map((b) => b.$1), [
        RoomNotificationAction.sosGo,
        RoomNotificationAction.sosAck,
        RoomNotificationAction.leave,
      ]);
      expect(scene.art.nodes[3]?.state, RoomArtNodeState.alert);

      // Sin ubicaciones compartidas dice la frecu.
      expect(
        _scene(
          sos: const RoomNotificationSos(id: 'a', name: 'Andrés'),
        ).subtitle,
        'SOS · Ruta 40',
      );
    });

    test('el anfitrión solo: tocar la tarjeta invita y salir la cierra', () {
      const me = MeshNode(
        id: 'me',
        name: 'Ana',
        slot: 0,
        isMe: true,
        isHost: true,
      );
      final scene = _scene(present: const [me], host: true);
      expect(scene.subtitle, 'Al aire · esperando a tu grupo');
      expect(scene.tapInvites, isTrue);
      expect(_buttons(scene).last.$3, 'Cerrar la frecu');
    });

    test('un evento pasajero se dice como en la isla, con su color', () {
      final scene = _scene(
        event: RoomIslandEvent.message(
          name: 'Beto',
          color: c.p2,
          text: 'Parada en la próxima',
        ),
      );
      expect(scene.subtitle, 'Beto · Parada en la próxima');
      expect(scene.accent, c.p2);
    });

    test('la salida de audio dice cuál suena, con el nombre del Bluetooth', () {
      final scene = _scene(
        route: AudioRoute.bluetooth,
        bluetoothName: 'Sena 50S',
      );
      expect(_buttons(scene)[1], (
        RoomNotificationAction.route,
        RoomNotificationIcon.headset,
        'Salida de audio: Sena 50S',
      ));
    });
  });

  testWidgets('la carátula es un PNG del tamaño pedido', (tester) async {
    final png = await tester.runAsync(
      () => paintRoomNotificationArt(
        RoomNotificationArt(
          nodes: [
            RoomArtNode(c.signal, RoomArtNodeState.hot),
            RoomArtNode(c.p2, RoomArtNodeState.muted),
            null,
            RoomArtNode(c.p1, RoomArtNodeState.weak),
            null,
            null,
          ],
          glow: c.signal,
          background: c.bg1,
          note: 'Sol4',
        ),
        size: 64,
      ),
    );
    expect(png, isNotNull);
    // Firma PNG y ancho de 64 px en la cabecera IHDR.
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(png.sublist(16, 20), [0, 0, 0, 64]);
  });
}
