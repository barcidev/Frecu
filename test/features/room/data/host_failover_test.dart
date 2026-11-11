// AC8: CUANDO el anfitrión de una frecu local en una Wi-Fi compartida deja de responder ENTONCES cada invitado lo reintenta dos veces (unos 4 s, en `reconnecting`) y, si no vuelve, sigue la sucesión en orden sin el anfitrión: a cada persona le da 2 intentos en su IP con su mismo id, y si la persona es este teléfono y su red sigue arriba, toma la frecu con el turno siguiente y la razón `lost` (si su red no está arriba, pasa a la siguiente). Quien la recibe emite un `HostChange` propio con razón `lost` y el nombre del anfitrión anterior, y los demás vuelven a ella con su mismo id y emiten un `HostChange` con razón `lost`, el anterior y quien la lleva, sin que la frecu se cierre. Todo `join` lleva el turno que conoce, y un servidor con un turno menor lo rechaza con `stale_term`.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_reconnection.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
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

/// Un puerto libre de 127.0.0.1.
Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

/// Proxy TCP delante del servidor del anfitrión: al cortarlo, los demás
/// pierden el socket sin `room_closed`, como si el anfitrión se hubiera
/// quedado fuera de alcance.
class _Proxy {
  _Proxy._(this._server, this._target);

  final ServerSocket _server;
  final int _target;
  final List<Socket> _sockets = [];

  int get port => _server.port;

  static Future<_Proxy> open(int port, {required int target}) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    final proxy = _Proxy._(server, target);
    server.listen(proxy._pipe);
    return proxy;
  }

  Future<void> _pipe(Socket client) async {
    _sockets.add(client);
    try {
      final upstream = await Socket.connect(
        InternetAddress.loopbackIPv4,
        _target,
      );
      _sockets.add(upstream);
      client.listen(
        upstream.add,
        onDone: upstream.destroy,
        onError: (Object _) => upstream.destroy(),
      );
      upstream.listen(
        client.add,
        onDone: client.destroy,
        onError: (Object _) => client.destroy(),
      );
    } on Object {
      client.destroy();
    }
  }

  /// Corta todo y deja el puerto libre.
  Future<void> cut() async {
    await _server.close();
    for (final socket in _sockets) {
      socket.destroy();
    }
  }
}

/// Un teléfono en una Wi-Fi compartida; con [online] en falso no tiene red.
RoomRepositoryImpl _phone(int port, {bool Function()? online}) {
  final repository = RoomRepositoryImpl(
    serverDataSource: SignalingServerDataSource(),
    clientDataSource: SignalingClientDataSource(),
    networkInterfacesProvider: () async => [
      if (online?.call() ?? true) _Interface('wlan0', ['192.168.1.20']),
    ],
    signalingPort: port,
    reconnectBaseDelay: const Duration(milliseconds: 100),
  );
  addTearDown(repository.dispose);
  return repository;
}

bool _isClosed(RoomStatus status) =>
    status.maybeWhen(closed: (_) => true, orElse: () => false);

bool _isReconnecting(RoomStatus status) =>
    status.maybeWhen(reconnecting: (_, _) => true, orElse: () => false);

Future<T> _first<T>(Stream<T> stream, bool Function(T value) test) =>
    stream.firstWhere(test).timeout(const Duration(seconds: 10));

/// Andrés abre la frecu en la Wi-Fi de todos; Ana y Leo se unen por el
/// proxy, en ese orden.
Future<(RoomRepositoryImpl, RoomRepositoryImpl, RoomRepositoryImpl, _Proxy)>
_room({bool Function()? anaOnline}) async {
  final hostPort = await _freePort();
  final proxy = await _Proxy.open(await _freePort(), target: hostPort);
  addTearDown(proxy.cut);
  final andres = _phone(hostPort);
  final ana = _phone(proxy.port, online: anaOnline);
  final leo = _phone(proxy.port);
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
      port: proxy.port,
      accessCode: '4821',
      displayName: name,
    );
    expect(joined.isSuccess, isTrue);
  }
  for (final phone in [andres, ana, leo]) {
    await _first(phone.watchSuccession(), (s) => s?.members.length == 3);
  }
  return (andres, ana, leo, proxy);
}

RoomMember _member(String id, String name) => RoomMember(
  id: id,
  displayName: name,
  joinedAt: DateTime(2026, 11, 11, 16),
  address: '192.168.1.${20 + int.parse(id.substring(5))}',
);

/// Cada paso del plan en una palabra.
String _describe(FailoverStep step) => switch (step) {
  FailoverRetryHost() => 'host',
  FailoverFollow(:final member) => 'follow ${member.id}',
  FailoverTake() => 'take',
};

void main() {
  group('AC8: plan de caída', () {
    final state = RoomSuccession(
      term: 1,
      handover: true,
      name: 'Ruta 40',
      accessCode: '4821',
      members: [
        _member('peer_1', 'Andrés'),
        _member('peer_2', 'Ana'),
        _member('peer_3', 'Leo'),
        _member('peer_4', 'Sofi'),
      ],
    );

    test('AC8: dos reintentos al anfitrión y dos pasos por cada persona de '
        'la sucesión, en orden y sin el anfitrión', () {
      final plan = FailoverPlan(
        state: state,
        lostHost: 'peer_1',
        me: 'peer_3',
        base: const Duration(seconds: 1),
      );

      expect(plan.lostHostName, 'Andrés');
      expect(
        [for (final step in plan.steps) _describe(step)],
        [
          'host',
          'host',
          'follow peer_2',
          'follow peer_2',
          'take',
          'take',
          'follow peer_4',
          'follow peer_4',
        ],
      );
      expect(plan.waits.take(4), const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 1),
        Duration(seconds: 2),
      ]);
    });

    test('AC8: los dos reintentos al anfitrión suman unos 3–4 s', () {
      final plan = FailoverPlan(
        state: state,
        lostHost: 'peer_1',
        me: 'peer_2',
        base: const Duration(seconds: 1),
      );
      final host = plan.waits.take(2).fold(Duration.zero, (a, b) => a + b);

      expect(host, const Duration(seconds: 3));
      expect(_describe(plan.steps[2]), 'take');
    });
  });

  group('AC8: caída del anfitrión en una Wi-Fi compartida', () {
    test('AC8: la toma la primera persona de la sucesión, con el turno '
        'siguiente y la razón lost', () async {
      final (_, ana, _, proxy) = await _room();
      final anaId = ana.localParticipantId!;
      final statuses = <RoomStatus>[];
      final sub = ana.watchStatus().listen(statuses.add);
      addTearDown(sub.cancel);
      final change = _first(ana.watchHostChanges(), (_) => true);

      await proxy.cut();

      final received = await change;
      expect(received.you, isTrue);
      expect(received.hostId, anaId);
      expect(received.hostName, 'Ana');
      expect(received.previousHost, 'Andrés');
      expect(received.reason, HostChangeReason.lost);
      final state = await _first(ana.watchSuccession(), (s) => s?.term == 2);
      expect(state!.order.first, anaId);
      expect(statuses.where(_isReconnecting), isNotEmpty);
      expect(statuses.where(_isClosed), isEmpty);
      await _first(ana.watchStatus(), (s) => s == const RoomStatus.connected());
    });

    test('AC8: los demás vuelven a quien la tomó con su mismo id y saben que '
        'el anfitrión se desconectó', () async {
      final (_, ana, leo, proxy) = await _room();
      final anaId = ana.localParticipantId!;
      final leoId = leo.localParticipantId!;
      final statuses = <RoomStatus>[];
      final sub = leo.watchStatus().listen(statuses.add);
      addTearDown(sub.cancel);
      final change = _first(leo.watchHostChanges(), (_) => true);

      await proxy.cut();

      final received = await change;
      expect(received.you, isFalse);
      expect(received.hostId, anaId);
      expect(received.hostName, 'Ana');
      expect(received.previousHost, 'Andrés');
      expect(received.reason, HostChangeReason.lost);
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
      expect(statuses.where(_isReconnecting), isNotEmpty);
      expect(statuses.where(_isClosed), isEmpty);
    });

    test('AC8: si la primera de la sucesión no tiene red, la toma la '
        'siguiente y la primera vuelve a ella', () async {
      var anaOnline = true;
      final (_, ana, leo, proxy) = await _room(anaOnline: () => anaOnline);
      final anaId = ana.localParticipantId!;
      final leoId = leo.localParticipantId!;
      final anaClosed = <RoomStatus>[];
      final sub = ana.watchStatus().where(_isClosed).listen(anaClosed.add);
      addTearDown(sub.cancel);
      final leoChange = _first(leo.watchHostChanges(), (_) => true);
      final anaChange = _first(ana.watchHostChanges(), (_) => true);

      anaOnline = false;
      await proxy.cut();

      final taken = await leoChange;
      expect(taken.you, isTrue);
      expect(taken.hostId, leoId);
      expect(taken.previousHost, 'Andrés');
      expect(taken.reason, HostChangeReason.lost);
      final followed = await anaChange;
      expect(followed.you, isFalse);
      expect(followed.hostId, leoId);
      expect(followed.hostName, 'Leo');
      expect(followed.reason, HostChangeReason.lost);
      expect(ana.localParticipantId, anaId);
      final state = await _first(
        leo.watchSuccession(),
        (s) => s?.term == 2 && s!.members.length == 2,
      );
      expect(state!.order, [leoId, anaId]);
      expect(anaClosed, isEmpty);
    });
  });
}
