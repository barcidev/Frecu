// AC4: CUANDO la red de una frecu local la crea el anfitrión ENTONCES la hoja de salir solo ofrece «Cerrar frecu», con el texto «Tu teléfono es la red de la frecu. Si sales, la frecu se cierra para …». Si el anfitrión se cae, los invitados reintentan como hoy y, si no vuelve, la frecu se cierra con «Se perdió la red del anfitrión y no volvió.».
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';

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

/// Un teléfono con las [interfaces] dadas y, si la creó, la red de Frecu al
/// aire en [frecuNetwork].
RoomRepositoryImpl _phone({
  List<NetworkInterface> interfaces = const [],
  String? frecuNetwork,
}) {
  final repository = RoomRepositoryImpl(
    serverDataSource: SignalingServerDataSource(),
    clientDataSource: SignalingClientDataSource(),
    networkInterfacesProvider: () async => interfaces,
    preferredLanInterface: () => frecuNetwork,
    signalingPort: 0,
  );
  addTearDown(repository.dispose);
  return repository;
}

/// El anfitrión abre una frecu local y un invitado se une a ella; devuelve
/// las dos frecus y los participantes que ve el invitado.
Future<(Room, Room, List<Participant>)> _openAndJoin(
  RoomRepositoryImpl host,
) async {
  final hosted = await host.createRoom(
    name: 'Ruta 40',
    accessCode: '4821',
    displayName: 'Andrés',
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
  final people = await guest.watchParticipants().first;
  return (hosted.dataOrNull!, joined.dataOrNull!, people);
}

void main() {
  group('AC4: red del anfitrión', () {
    test('AC4: con la red de Frecu al aire, la frecu no admite traspaso y '
        'quien se une lo sabe', () async {
      final host = _phone(
        interfaces: [
          _Interface('wlan0', ['192.168.1.20']),
          _Interface('wlan1', ['192.168.49.1']),
        ],
        frecuNetwork: 'wlan1',
      );

      final (hosted, joined, people) = await _openAndJoin(host);

      expect(hosted.hostAddress, '192.168.49.1');
      expect(hosted.hostOwnsNetwork, isTrue);
      expect(hosted.handover, isFalse);
      expect(joined.hostOwnsNetwork, isTrue);
      expect(joined.handover, isFalse);
      expect(people.singleWhere((p) => p.isHost).ownsNetwork, isTrue);
      expect(
        people.where((p) => !p.isHost).every((p) => !p.ownsNetwork),
        isTrue,
      );
    });

    test(
      'AC4: en la zona Wi-Fi del anfitrión, la frecu no admite traspaso',
      () async {
        final host = _phone(
          interfaces: [
            _Interface('ap0', ['192.168.43.1']),
          ],
        );

        final (hosted, joined, _) = await _openAndJoin(host);

        expect(hosted.hostOwnsNetwork, isTrue);
        expect(joined.hostOwnsNetwork, isTrue);
        expect(joined.handover, isFalse);
      },
    );

    test('AC4: sin red local a la vista (zona Wi-Fi de iPhone sin nadie aún), '
        'la red es del anfitrión', () async {
      final (hosted, joined, _) = await _openAndJoin(_phone());

      expect(hosted.hostOwnsNetwork, isTrue);
      expect(joined.hostOwnsNetwork, isTrue);
    });

    test('AC4: en una Wi-Fi compartida la frecu admite traspaso y nadie es '
        'la red', () async {
      final host = _phone(
        interfaces: [
          _Interface('wlan0', ['192.168.1.20']),
        ],
      );

      final (hosted, joined, people) = await _openAndJoin(host);

      expect(hosted.hostAddress, '192.168.1.20');
      expect(hosted.hostOwnsNetwork, isFalse);
      expect(hosted.handover, isTrue);
      expect(joined.hostOwnsNetwork, isFalse);
      expect(joined.handover, isTrue);
      expect(people.any((p) => p.ownsNetwork), isFalse);
    });
  });

  group('AC4: traspaso según el tipo de frecu', () {
    Room room({String? internetId, bool hostOwnsNetwork = false}) => Room(
      id: 'room-1',
      name: 'Ruta 40',
      hostAddress: internetId == null ? '192.168.43.1' : '',
      port: 47800,
      accessCode: '4821',
      createdAt: DateTime(2026, 11, 11),
      internetId: internetId,
      hostOwnsNetwork: hostOwnsNetwork,
    );

    test('AC4: una frecu local en la red del anfitrión no admite traspaso; '
        'en Wi-Fi compartida y por internet, sí', () {
      expect(room(hostOwnsNetwork: true).handover, isFalse);
      expect(room().handover, isTrue);
      expect(room(internetId: 'abc123').handover, isTrue);
    });

    test('AC4: un anfitrión de una versión anterior no manda la red: vale '
        'Wi-Fi compartida', () {
      final participant = Participant.fromJson({
        'id': 'peer_1',
        'displayName': 'Andrés',
        'isHost': true,
      });

      expect(participant.ownsNetwork, isFalse);
    });
  });
}
