// AC9: CUANDO, en una frecu local en una Wi-Fi compartida, el anfitrión anterior vuelve con su frecu abierta o dos teléfonos llevan la misma frecu a la vez ENTONCES cada anfitrión pregunta con `host_probe` (código, turno, su id y su puerto) en las IPs de quienes salieron de su sucesión, y quien responde con el código correcto devuelve su propio `host_probe`. Gana el turno mayor y, a igual turno, el `peer_N` menor; el otro avisa a sus invitados `host_handover` con el id, la IP y el puerto del ganador, cierra su servidor sin `room_closed` y entra como invitado al ganador, sin volver a escribir el código. Emite un `HostChange` con razón `outranked` y quien la lleva, y ve el aviso «Volviste como invitado · «nombre» lleva la frecu», la cabecera «Anfitrión · «nombre»» y deja de llevar la frecu (su invitación es la del ganador). Sus invitados vuelven al ganador. Un `host_probe` con el código incorrecto se rechaza como un `join` incorrecto.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/host_probe.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

/// Un teléfono en una Wi-Fi compartida, en el [port] de la frecu; su IP de
/// la invitación es de documentación (no responde). [probe] es su pregunta
/// a otros anfitriones.
RoomRepositoryImpl _phone(int port, {HostProbe? probe}) {
  final repository = RoomRepositoryImpl(
    serverDataSource: SignalingServerDataSource(),
    clientDataSource: SignalingClientDataSource(),
    networkInterfacesProvider: () async => [
      _Interface('wlan0', ['192.0.2.20']),
    ],
    signalingPort: port,
    reconnectBaseDelay: const Duration(milliseconds: 100),
    hostProbe: probe ?? HostProbe(interval: const Duration(milliseconds: 100)),
  );
  addTearDown(repository.dispose);
  return repository;
}

bool _isClosed(RoomStatus status) =>
    status.maybeWhen(closed: (_) => true, orElse: () => false);

Future<T> _first<T>(Stream<T> stream, bool Function(T value) test) =>
    stream.firstWhere(test).timeout(const Duration(seconds: 10));

/// Andrés abre la frecu; Ana entra por [anaProxy] y Leo por [leoProxy]
/// (cada teléfono abre su servidor, si la toma, en el puerto de su proxy).
Future<(RoomRepositoryImpl, RoomRepositoryImpl, RoomRepositoryImpl)> _room({
  required int hostPort,
  required _Proxy anaProxy,
  required _Proxy leoProxy,
  HostProbe? andresProbe,
  HostProbe? anaProbe,
}) async {
  final andres = _phone(hostPort, probe: andresProbe);
  final ana = _phone(anaProxy.port, probe: anaProbe);
  final leo = _phone(leoProxy.port);
  final hosted = await andres.createRoom(
    name: 'Ruta 40',
    accessCode: '4821',
    displayName: 'Andrés',
  );
  expect(hosted.isSuccess, isTrue);
  expect(hosted.dataOrNull!.handover, isTrue);
  for (final (phone, name, proxy) in [
    (ana, 'Ana', anaProxy),
    (leo, 'Leo', leoProxy),
  ]) {
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
  return (andres, ana, leo);
}

void main() {
  group('AC9: gana el turno mayor y el otro entra como invitado', () {
    test('AC9: el anfitrión anterior vuelve, pregunta, pierde y entra como '
        'invitado a quien la tomó', () async {
      final hostPort = await _freePort();
      final proxy = await _Proxy.open(await _freePort(), target: hostPort);
      addTearDown(proxy.cut);
      final (andres, ana, leo) = await _room(
        hostPort: hostPort,
        anaProxy: proxy,
        leoProxy: proxy,
        // En pruebas, cada servidor tiene su puerto: Andrés pregunta en el
        // de quien tomará la frecu.
        andresProbe: HostProbe(
          port: proxy.port,
          interval: const Duration(milliseconds: 100),
        ),
      );
      final anaId = ana.localParticipantId!;
      final closed = <RoomStatus>[];
      final sub = andres.watchStatus().where(_isClosed).listen(closed.add);
      addTearDown(sub.cancel);
      final change = _first(andres.watchHostChanges(), (_) => true);

      await proxy.cut();

      final received = await change;
      expect(received.you, isFalse);
      expect(received.reason, HostChangeReason.outranked);
      expect(received.hostId, anaId);
      expect(received.hostName, 'Ana');
      expect(received.hostAddress, '127.0.0.1');
      expect(received.port, proxy.port);
      final people = await _first(
        andres.watchParticipants(),
        (list) => list.any((p) => p.id == anaId && p.isHost),
      );
      expect(people.where((p) => p.isHost), hasLength(1));
      final me = people.singleWhere((p) => p.id == andres.localParticipantId);
      expect(me.displayName, 'Andrés');
      expect(me.isHost, isFalse);
      expect(andres.succession?.term, 2);
      await _first(
        ana.watchParticipants(),
        (list) => list.any((p) => p.displayName == 'Andrés' && !p.isHost),
      );
      await _first(
        leo.watchParticipants(),
        (list) => list.any((p) => p.displayName == 'Andrés'),
      );
      expect(closed, isEmpty);
    });

    test('AC9: dos anfitriones a la vez: el de turno menor cede, y su '
        'invitado vuelve al ganador sin escribir el código', () async {
      final hostPort = await _freePort();
      final anaProxy = await _Proxy.open(await _freePort(), target: hostPort);
      final leoProxy = await _Proxy.open(await _freePort(), target: hostPort);
      addTearDown(anaProxy.cut);
      addTearDown(leoProxy.cut);
      final (andres, ana, leo) = await _room(
        hostPort: hostPort,
        anaProxy: anaProxy,
        leoProxy: leoProxy,
        // Ana pregunta a la IP de Andrés: en pruebas, su servidor.
        anaProbe: HostProbe(
          interval: const Duration(milliseconds: 100),
          connect: (uri) => WebSocketChannel.connect(
            uri.replace(host: '127.0.0.1', port: hostPort),
          ),
        ),
      );
      final anaId = ana.localParticipantId!;
      final leoId = leo.localParticipantId!;
      final leoClosed = <RoomStatus>[];
      final sub = leo.watchStatus().where(_isClosed).listen(leoClosed.add);
      addTearDown(sub.cancel);
      final andresChange = _first(andres.watchHostChanges(), (_) => true);
      final anaTook = _first(ana.watchHostChanges(), (c) => c.you);

      // Solo Ana pierde a Andrés: Leo sigue con él (una partición).
      await anaProxy.cut();
      await anaTook;

      final received = await andresChange;
      expect(received.reason, HostChangeReason.outranked);
      expect(received.hostId, anaId);
      expect(received.hostName, 'Ana');
      final people = await _first(
        leo.watchParticipants(),
        (list) =>
            list.any((p) => p.id == anaId && p.isHost) &&
            list.any((p) => p.displayName == 'Andrés'),
      );
      expect(people.where((p) => p.isHost).single.id, anaId);
      expect(leo.localParticipantId, leoId);
      final state = await _first(
        ana.watchSuccession(),
        (s) => s?.term == 2 && s!.members.length == 3,
      );
      expect(state!.order.first, anaId);
      expect(leoClosed, isEmpty);
    });
  });
}
