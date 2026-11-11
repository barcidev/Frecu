// AC1: CUANDO el anfitrión anterior de una frecu por internet recupera la red y la nube rechaza su relé con 409 porque otro la tomó con un turno mayor ENTONCES deja de reintentar el relé, cierra su servidor, vuelve por el socket de invitado de la frecu (`guestSocket(internetId)`) con su mismo id y sin volver a escribir el código, y emite `HostChange(you: false, reason: outranked)` con el id y el nombre de quien la lleva. Quien la lleva lo ve como invitado, y la nube no vuelve a recibir su turno viejo.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/core/network/network_return.dart';
import 'package:frecu/features/room/data/datasources/cloud_relay_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Punto de encuentro falso con el contrato del Durable Object: turno
/// vigente, gracia con `host_lost` y 409 a un turno menor. Con
/// [unreachableTerm], el anfitrión de ese turno no llega (no tiene red).
class _FakeCloud {
  HttpServer? _server;
  WebSocketChannel? host;
  final Map<String, WebSocketChannel> guests = {};
  int _next = 0;

  /// Turno vigente de la sala.
  int term = 0;

  /// Secreto con que se reclamó la sala.
  String? secret;

  /// Turno con que se conectó cada anfitrión, en orden.
  final List<int> hostTerms = [];

  /// Rechazos 409 a un turno menor.
  int outranked = 0;

  /// Turno de un anfitrión sin red: sus intentos no llegan (503).
  int? unreachableTerm;

  CloudConfig get config => CloudConfig('http://127.0.0.1:${_server!.port}');

  Future<void> start() async {
    _server = await shelf_io.serve(_handle, '127.0.0.1', 0);
  }

  FutureOr<Response> _handle(Request request) {
    final path = request.url.path;
    if (path.endsWith('/host')) {
      final query = request.url.queryParameters;
      final asked = int.tryParse(query['term'] ?? '') ?? 0;
      if (asked == unreachableTerm) return Response(503);
      if (secret != null && query['secret'] != secret) {
        return Response.forbidden('');
      }
      if (asked < term) {
        outranked++;
        return Response(409);
      }
      secret = query['secret'];
      term = asked;
      hostTerms.add(asked);
      return webSocketHandler(
        (WebSocketChannel channel, String? _) => _acceptHost(channel),
      )(request);
    }
    if (host == null) return Response.notFound('');
    return webSocketHandler(
      (WebSocketChannel channel, String? _) => _acceptGuest(channel),
    )(request);
  }

  void _acceptHost(WebSocketChannel channel) {
    final old = host;
    host = channel;
    if (old != null) unawaited(old.sink.close(4000));
    final waiting = List.of(guests.values);
    guests.clear();
    for (final guest in waiting) {
      unawaited(guest.sink.close(3012));
    }
    channel.stream.listen(
      (data) {
        final envelope = jsonDecode(data as String) as Map<String, dynamic>;
        final guest = guests[envelope['c']];
        if (guest == null) return;
        if (envelope['t'] == 'msg') guest.sink.add(envelope['d']);
        if (envelope['t'] == 'close') unawaited(guest.sink.close());
      },
      onDone: () {
        if (!identical(host, channel)) return;
        host = null;
        // Gracia: los invitados siguen abiertos y se enteran.
        for (final guest in guests.values) {
          guest.sink.add(jsonEncode({'t': 'host_lost'}));
        }
      },
    );
  }

  void _acceptGuest(WebSocketChannel channel) {
    final id = 'g${++_next}';
    guests[id] = channel;
    host?.sink.add(jsonEncode({'t': 'open', 'c': id, 'k': 'k$id'}));
    channel.stream.listen(
      (data) => host?.sink.add(jsonEncode({'t': 'msg', 'c': id, 'd': data})),
      onDone: () {
        if (guests.remove(id) == null) return;
        host?.sink.add(jsonEncode({'t': 'close', 'c': id}));
      },
    );
  }

  /// El anfitrión se cae: la nube corta su socket.
  Future<void> dropHost() async => host?.sink.close();

  Future<void> stop() async => _server?.close(force: true);
}

/// Interfaz de red de mentira con sus direcciones.
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

Future<T> _first<T>(Stream<T> stream, bool Function(T) test) =>
    stream.firstWhere(test).timeout(const Duration(seconds: 10));

void main() {
  late _FakeCloud cloud;

  setUp(() async {
    cloud = _FakeCloud();
    await cloud.start();
  });

  tearDown(() async => cloud.stop());

  /// Un teléfono con datos móviles; [relayRetry] es la espera de su relé
  /// antes de reconectar.
  RoomRepositoryImpl phone({
    Duration relayRetry = const Duration(seconds: 30),
  }) {
    Future<List<NetworkInterface>> interfaces() async => [
      _Interface('pdp_ip0', ['10.20.30.40']),
    ];
    final repository = RoomRepositoryImpl(
      serverDataSource: SignalingServerDataSource(),
      clientDataSource: SignalingClientDataSource(),
      cloudRelayDataSource: CloudRelayDataSource(
        reconnectBaseDelay: relayRetry,
        maxReconnectDelay: relayRetry,
        networkWatcher: NetworkReturnWatcher(interfaces: () async => []),
      ),
      cloudConfig: cloud.config,
      networkInterfacesProvider: interfaces,
      signalingPort: 0,
      reconnectBaseDelay: const Duration(milliseconds: 200),
    );
    addTearDown(repository.dispose);
    return repository;
  }

  bool ledBy(List<Participant> list, String host, String guest) =>
      list.any((p) => p.isHost && p.displayName == host) &&
      list.any((p) => !p.isHost && p.displayName == guest);

  test('AC1: the previous internet host comes back with a lower term, is '
      'refused with 409 and joins as a guest through the guest socket with '
      'its id', () async {
    // Ana abre la frecu por internet; Beto y Caro se unen, en ese orden.
    final ana = phone(relayRetry: const Duration(milliseconds: 50));
    final beto = phone();
    final caro = phone();
    final created = await ana.createRoom(
      name: 'Ruta',
      accessCode: '1234',
      displayName: 'Ana',
      reach: RoomReach.internet,
    );
    final internetId = created.dataOrNull!.internetId!;
    for (final (guest, name) in [(beto, 'Beto'), (caro, 'Caro')]) {
      final joined = await guest.joinInternetRoom(
        internetId: internetId,
        accessCode: '1234',
        displayName: name,
      );
      expect(joined.isSuccess, isTrue);
    }
    for (final guest in [beto, caro]) {
      await _first<RoomSuccession?>(
        guest.watchSuccession(),
        (s) => s?.members.length == 3 && s?.hostSecret != null,
      );
    }
    final betoId = beto.localParticipantId!;

    // Ana pierde la red: Beto toma la frecu con el turno siguiente.
    cloud.unreachableTerm = 1;
    final heir = _first(beto.watchHostChanges(), (c) => c.you);
    final outranked = _first(
      ana.watchHostChanges(),
      (c) => c.reason == HostChangeReason.outranked,
    );
    await cloud.dropHost();
    expect((await heir).reason, HostChangeReason.lost);
    expect(cloud.hostTerms, [1, 2]);

    // Ana recupera la red: la nube rechaza su relé y ella entra como
    // invitada, sin volver a escribir el código.
    cloud.unreachableTerm = null;
    final change = await outranked;
    expect(change.you, isFalse);
    expect(change.hostId, betoId);
    expect(change.hostName, 'Beto');

    await _first(ana.watchParticipants(), (l) => ledBy(l, 'Beto', 'Ana'));
    await _first(beto.watchParticipants(), (l) => ledBy(l, 'Beto', 'Ana'));
    // Vuelve con su id en `join.peerId`; quien la tomó por caída no le
    // guarda el lugar del anfitrión perdido, así que entra con uno nuevo
    // (supuesto A4).
    final seen = await _first(
      beto.watchParticipants(),
      (l) => l.any((p) => p.id == ana.localParticipantId),
    );
    final back = seen.firstWhere((p) => p.id == ana.localParticipantId);
    expect(back.displayName, 'Ana');
    expect(back.isHost, isFalse);
    expect(ana.succession?.internetId, internetId);
    expect(ana.succession?.term, 2);

    // Ya no reintenta su relé con el turno viejo.
    final refused = cloud.outranked;
    expect(refused, greaterThan(0));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(cloud.outranked, refused);
    expect(cloud.hostTerms, [1, 2]);
  });
}
