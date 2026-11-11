// AC5: CUANDO la frecu es local en una Wi-Fi compartida, o por internet ENTONCES los participantes saben que admite traspaso, y cada uno conoce el orden de sucesión, el turno vigente y el estado de la frecu (nombre, código, nota, modo y participantes), que el anfitrión les envía al entrar y en cada cambio.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/features/room/data/datasources/cloud_relay_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';

/// Interfaz de red falsa con sus IPv4.
class _Interface implements NetworkInterface {
  _Interface(this.name, List<String> addresses)
    : addresses = [for (final a in addresses) _Address(a)];

  @override
  final String name;

  @override
  int get index => 0;

  @override
  final List<InterfaceAddress> addresses;
}

class _Address implements InterfaceAddress {
  _Address(String text) : _ip = InternetAddress(text);

  final InternetAddress _ip;

  @override
  String get address => _ip.address;

  @override
  bool get isLoopback => _ip.isLoopback;

  @override
  InternetAddressType get type => _ip.type;

  @override
  int get prefixLength => 24;

  @override
  InternetAddress? get broadcast => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Relé de la nube que no sale a internet: anota con qué socket se abrió.
class _QuietRelay extends CloudRelayDataSource {
  Uri? uri;

  @override
  Future<void> start(
    Uri uri, {
    required void Function(SignalingConnection connection) onGuest,
  }) async => this.uri = uri;

  @override
  Future<void> stop() async {}
}

/// Un teléfono con las [interfaces] dadas y, si la creó, la red de Frecu al
/// aire en [frecuNetwork].
RoomRepositoryImpl _phone({
  List<NetworkInterface> interfaces = const [],
  String? frecuNetwork,
  CloudRelayDataSource? relay,
}) {
  final repository = RoomRepositoryImpl(
    serverDataSource: SignalingServerDataSource(),
    clientDataSource: SignalingClientDataSource(),
    cloudRelayDataSource: relay,
    cloudConfig: const CloudConfig('http://127.0.0.1:9'),
    networkInterfacesProvider: () async => interfaces,
    preferredLanInterface: () => frecuNetwork,
    signalingPort: 0,
  );
  addTearDown(repository.dispose);
  return repository;
}

/// La primera sucesión que conoce [phone] con [people] personas.
Future<RoomSuccession> _successionOf(RoomRepositoryImpl phone, int people) =>
    phone
        .watchSuccession()
        .firstWhere((s) => s != null && s.members.length == people)
        .then((s) => s!)
        .timeout(const Duration(seconds: 3));

/// El anfitrión [host] abre una frecu y un invitado se une por la red local.
Future<(RoomRepositoryImpl, String?)> _openAndJoin(
  RoomRepositoryImpl host, {
  RoomReach reach = RoomReach.local,
}) async {
  final hosted = await host.createRoom(
    name: 'Ruta 40',
    accessCode: '4821',
    displayName: 'Andrés',
    note: const RoomNote(semitone: 4),
    reach: reach,
  );
  expect(hosted.isSuccess, isTrue);
  final guest = _phone();
  final joined = await guest.joinRoom(
    hostAddress: '127.0.0.1',
    port: hosted.dataOrNull!.port,
    accessCode: '4821',
    displayName: 'Ana',
  );
  expect(joined.isSuccess, isTrue);
  return (guest, hosted.dataOrNull!.internetId);
}

/// Un participante de mentira conectado al servidor, con lo que recibe.
class _Peer {
  final SignalingClientDataSource client = SignalingClientDataSource();
  final List<SignalingMessage> received = [];
  StreamSubscription<SignalingMessage>? _sub;
  bool _closed = false;
  String? id;

  Future<void> join(SignalingServerDataSource server, String name) async {
    await client.connect(Uri.parse('ws://127.0.0.1:${server.port}'));
    _sub = client.messages.listen(received.add);
    client.send(SignalingMessage.join(displayName: name, accessCode: '4821'));
    await _until(() => received.any((m) => m is SignalingWelcomeMessage));
    id = received.whereType<SignalingWelcomeMessage>().first.peerId;
  }

  /// El último `room_state` que recibió.
  RoomSuccession? get state =>
      received.whereType<SignalingRoomStateMessage>().lastOrNull?.state;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _sub?.cancel();
    await client.dispose();
  }
}

Future<void> _until(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('AC5: room_state en el protocolo', () {
    test('AC5: room_state viaja como JSON y vuelve igual; sin internet no '
        'lleva secreto ni id', () {
      final state = RoomSuccession(
        term: 2,
        handover: true,
        name: 'Ruta 40',
        accessCode: '4821',
        note: const RoomNote(semitone: 4),
        members: [
          RoomMember(
            id: 'peer_1',
            displayName: 'Andrés',
            joinedAt: DateTime.utc(2026, 11, 11, 8),
            address: '192.168.1.20',
          ),
          RoomMember(
            id: 'peer_2',
            displayName: 'Ana',
            joinedAt: DateTime.utc(2026, 11, 11, 8, 1),
          ),
        ],
      );
      final json =
          jsonDecode(jsonEncode(SignalingMessage.roomState(state: state)))
              as Map<String, dynamic>;

      expect(json['type'], 'room_state');
      final body = json['state'] as Map<String, dynamic>;
      expect(body.containsKey('hostSecret'), isFalse);
      expect(body.containsKey('internetId'), isFalse);
      expect(
        ((body['members'] as List)[1] as Map).containsKey('address'),
        isFalse,
      );
      final back = SignalingMessage.fromJson(json);
      expect(back, isA<SignalingRoomStateMessage>());
      expect((back as SignalingRoomStateMessage).state, state);
      expect(back.state.order, ['peer_1', 'peer_2']);
      expect(back.state.reach, RoomReach.local);
    });
  });

  group('AC5: el anfitrión reparte la sucesión', () {
    late SignalingServerDataSource server;
    late List<_Peer> peers;

    setUp(() async {
      server = SignalingServerDataSource();
      server.succession.configure(
        reach: RoomReach.local,
        hostOwnsNetwork: false,
        hostAddress: '192.168.1.20',
      );
      await server.start(
        accessCode: '4821',
        roomName: 'Ruta 40',
        note: const RoomNote(semitone: 4),
        host: '127.0.0.1',
        port: 0,
      );
      peers = [_Peer(), _Peer(), _Peer()];
    });

    tearDown(() async {
      for (final peer in peers) {
        await peer.close();
      }
      await server.dispose();
    });

    test('AC5: al entrar cada uno, todos reciben el turno, el orden de '
        'llegada y el estado de la frecu', () async {
      final [andres, ana, leo] = peers;
      await andres.join(server, 'Andrés');
      await ana.join(server, 'Ana');
      await leo.join(server, 'Leo');
      final order = [andres.id, ana.id, leo.id];

      for (final peer in peers) {
        await _until(() => peer.state?.members.length == 3);
        final state = peer.state!;
        expect(state.term, 1);
        expect(state.handover, isTrue);
        expect(state.order, order);
        expect(state.name, 'Ruta 40');
        expect(state.accessCode, '4821');
        expect(state.note, const RoomNote(semitone: 4));
        expect(state.reach, RoomReach.local);
        expect(state.hostSecret, isNull);
        expect(state.members.map((m) => m.displayName), [
          'Andrés',
          'Ana',
          'Leo',
        ]);
        expect(state.members.first.address, '192.168.1.20');
        expect(state.members[1].address, '127.0.0.1');
        expect(
          state.members[1].joinedAt.isBefore(state.members.first.joinedAt),
          isFalse,
        );
        expect(
          state.members[2].joinedAt.isBefore(state.members[1].joinedAt),
          isFalse,
        );
      }
    });

    test('AC5: al salir alguien, los demás reciben la sucesión sin él', () async {
      final [andres, ana, leo] = peers;
      await andres.join(server, 'Andrés');
      await ana.join(server, 'Ana');
      await leo.join(server, 'Leo');
      await _until(() => andres.state?.members.length == 3);

      await ana.close();

      for (final peer in [andres, leo]) {
        await _until(() => peer.state?.members.length == 2);
        expect(peer.state!.order, [andres.id, leo.id]);
      }
    });
  });

  group('AC5: cada participante conoce la sucesión', () {
    test('AC5: en una Wi-Fi compartida, quien se une sabe que admite '
        'traspaso, el turno, el orden y el estado de la frecu', () async {
      final host = _phone(
        interfaces: [
          _Interface('wlan0', ['192.168.1.20']),
        ],
      );
      final (guest, _) = await _openAndJoin(host);

      final known = await _successionOf(guest, 2);
      final hostKnows = await _successionOf(host, 2);

      expect(known.handover, isTrue);
      expect(known.term, 1);
      expect(known.order, [host.localParticipantId, guest.localParticipantId]);
      expect(known.name, 'Ruta 40');
      expect(known.accessCode, '4821');
      expect(known.note, const RoomNote(semitone: 4));
      expect(known.reach, RoomReach.local);
      expect(known.members.first.address, '192.168.1.20');
      expect(known.members.last.displayName, 'Ana');
      expect(hostKnows, known);
      expect(guest.succession, known);
    });

    test('AC5: con la red de Frecu del anfitrión, saben que no admite '
        'traspaso', () async {
      final host = _phone(
        interfaces: [
          _Interface('wlan0', ['192.168.1.20']),
          _Interface('wlan1', ['192.168.49.1']),
        ],
        frecuNetwork: 'wlan1',
      );
      final (guest, _) = await _openAndJoin(host);

      final known = await _successionOf(guest, 2);

      expect(known.handover, isFalse);
      expect(known.members.first.address, '192.168.49.1');
    });

    test('AC5: por internet, saben que admite traspaso y conocen el id y el '
        'secreto de anfitrión', () async {
      final relay = _QuietRelay();
      final host = _phone(relay: relay);
      // El socket local hace de punto de encuentro para el invitado.
      final (guest, internetId) = await _openAndJoin(
        host,
        reach: RoomReach.internet,
      );

      final known = await _successionOf(guest, 2);

      expect(known.handover, isTrue);
      expect(known.reach, RoomReach.internet);
      expect(known.internetId, internetId);
      expect(known.hostSecret, isNotNull);
      expect(known.hostSecret, relay.uri!.queryParameters['secret']);
      expect(known.members.first.address, isNull);
    });

    test('AC5: al salir de la frecu, ya no conoce la sucesión', () async {
      final host = _phone(
        interfaces: [
          _Interface('wlan0', ['192.168.1.20']),
        ],
      );
      final (guest, _) = await _openAndJoin(host);
      await _successionOf(guest, 2);

      await guest.leaveRoom();

      expect(guest.succession, isNull);
    });
  });
}
