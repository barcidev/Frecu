// AC7: CUANDO el anfitrión de una frecu local en una Wi-Fi compartida pasa la frecu ENTONCES quien la recibe abre el servidor, sube el turno y ve «Ahora llevas la frecu. «anterior» te la pasó al salir.» con «Mostrar el QR». Los demás se reconectan a él con su mismo id y lugar, sin volver a escribir el código, y ven ««anterior» salió · «nombre» lleva ahora la frecu». La cabecera dice «Anfitrión · «nombre»», y quien la recibe ve «Llevas la frecu». Su QR es el nuevo (su IP).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';

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

/// Un puerto libre de 127.0.0.1, el mismo para todos los teléfonos de la
/// prueba: quien recibe la frecu abre su servidor donde estaba el anterior.
Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// Un teléfono en una Wi-Fi compartida (la red no la crea el anfitrión).
RoomRepositoryImpl _phone(int port) {
  final repository = RoomRepositoryImpl(
    serverDataSource: SignalingServerDataSource(),
    clientDataSource: SignalingClientDataSource(),
    networkInterfacesProvider: () async => [
      _Interface('wlan0', ['192.168.1.20']),
    ],
    signalingPort: port,
  );
  addTearDown(repository.dispose);
  return repository;
}

bool _isClosed(RoomStatus status) =>
    status.maybeWhen(closed: (_) => true, orElse: () => false);

Future<T> _first<T>(Stream<T> stream, bool Function(T value) test) =>
    stream.firstWhere(test).timeout(const Duration(seconds: 8));

/// Andrés abre la frecu en la Wi-Fi de todos, y Ana y Leo se unen.
Future<(RoomRepositoryImpl, RoomRepositoryImpl, RoomRepositoryImpl)>
_room() async {
  final port = await _freePort();
  final andres = _phone(port);
  final ana = _phone(port);
  final leo = _phone(port);
  final hosted = await andres.createRoom(
    name: 'Ruta 40',
    accessCode: '4821',
    displayName: 'Andrés',
    note: const RoomNote(semitone: 4),
  );
  expect(hosted.isSuccess, isTrue);
  expect(hosted.dataOrNull!.handover, isTrue);
  for (final (phone, name) in [(ana, 'Ana'), (leo, 'Leo')]) {
    final joined = await phone.joinRoom(
      hostAddress: '127.0.0.1',
      port: port,
      accessCode: '4821',
      displayName: name,
    );
    expect(joined.isSuccess, isTrue);
  }
  for (final phone in [andres, ana, leo]) {
    await _first(phone.watchSuccession(), (s) => s?.members.length == 3);
  }
  return (andres, ana, leo);
}

void main() {
  group('Traspaso voluntario en Wi-Fi compartida', () {
    test('AC7: quien recibe la frecu abre el servidor, sube el turno y '
        'sabe que se la pasó el anfitrión anterior', () async {
      final (andres, ana, _) = await _room();
      final anaId = ana.localParticipantId!;
      final change = _first(ana.watchHostChanges(), (_) => true);

      final passed = await andres.handOver(anaId);

      expect(passed.isSuccess, isTrue);
      final received = await change;
      expect(received.you, isTrue);
      expect(received.hostId, anaId);
      expect(received.hostName, 'Ana');
      expect(received.previousHost, 'Andrés');
      expect(received.reason, HostChangeReason.left);
      expect(received.hostAddress, '127.0.0.1');
      final state = await _first(ana.watchSuccession(), (s) => s?.term == 2);
      expect(state!.order.first, anaId);
      expect(state.accessCode, '4821');
      expect(state.name, 'Ruta 40');
      final people = await _first(
        ana.watchParticipants(),
        (list) => list.any((p) => p.id == anaId && p.isHost),
      );
      expect(people.map((p) => p.displayName), isNot(contains('Andrés')));
      expect(ana.localParticipantId, anaId);
      expect(await ana.watchStatus().first, const RoomStatus.connected());
    });

    test('AC7: los demás se reconectan a quien la recibe con su mismo id y '
        'lugar, y saben quién la lleva ahora', () async {
      final (andres, ana, leo) = await _room();
      final anaId = ana.localParticipantId!;
      final leoId = leo.localParticipantId!;
      final statuses = <RoomStatus>[];
      final sub = leo.watchStatus().listen(statuses.add);
      addTearDown(sub.cancel);
      final change = _first(leo.watchHostChanges(), (_) => true);

      await andres.handOver(anaId);

      final received = await change;
      expect(received.you, isFalse);
      expect(received.hostId, anaId);
      expect(received.hostName, 'Ana');
      expect(received.previousHost, 'Andrés');
      expect(received.reason, HostChangeReason.left);
      expect(received.hostAddress, '127.0.0.1');
      expect(leo.localParticipantId, leoId);
      final people = await _first(
        leo.watchParticipants(),
        (list) => list.any((p) => p.id == anaId && p.isHost),
      );
      expect([for (final p in people) p.id], [anaId, leoId]);
      final state = await _first(
        leo.watchSuccession(),
        (s) => s?.term == 2 && s!.members.length == 2,
      );
      expect(state!.order, [anaId, leoId]);
      expect(statuses.where(_isClosed), isEmpty);
    });

    test('AC7: el anfitrión que pasa la frecu sale de ella sin cerrarla para '
        'los demás', () async {
      final (andres, ana, leo) = await _room();
      final closed = <RoomStatus>[];
      final sub = leo.watchStatus().where(_isClosed).listen(closed.add);
      addTearDown(sub.cancel);

      await andres.handOver(ana.localParticipantId!);

      expect(
        await andres.watchStatus().first,
        const RoomStatus.closed(reason: 'user_left'),
      );
      await _first(leo.watchHostChanges(), (_) => true);
      expect(closed, isEmpty);
    });

    test('AC7: no se pasa la frecu a alguien que no está en ella', () async {
      final (andres, _, leo) = await _room();

      final passed = await andres.handOver('peer_99');

      expect(passed.isFailure, isTrue);
      expect(await andres.watchStatus().first, const RoomStatus.connected());
      expect(await leo.watchStatus().first, const RoomStatus.connected());
    });
  });
}
