// AC1: CUANDO quien toma una frecu por internet por caída recibe un 409 al abrir su relé ENTONCES no la da por perdida: cierra su servidor, deja de ser anfitrión, vuelve por el socket de invitado de la frecu (`guestSocket(internetId)`) con su id y sin volver a escribir el código, y emite `HostChange(you: false, reason: outranked)` con el id y el nombre de quien la lleva; quien la lleva lo ve como invitado y la nube no recibe otro intento de su relé.
// AC2: CUANDO al tomar la frecu por internet el relé falla por otra causa (por ejemplo 503) ENTONCES la da por perdida como hoy (`RoomStatus.closed`).
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
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Punto de encuentro falso con el contrato del Durable Object: turno
/// vigente, gracia con `host_lost` y 409 a un turno menor. Con
/// [unreachableTerms], el anfitrión de esos turnos no llega (no tiene red).
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

  /// Turnos de anfitriones sin red: sus intentos no llegan (503).
  final Set<int> unreachableTerms = {};

  /// Rechaza (404) a los invitados que llegan hasta el primer 409.
  bool refuseGuestsUntilOutranked = false;

  CloudConfig get config => CloudConfig('http://127.0.0.1:${_server!.port}');

  Future<void> start() async {
    _server = await shelf_io.serve(_handle, '127.0.0.1', 0);
  }

  FutureOr<Response> _handle(Request request) {
    final path = request.url.path;
    if (path.endsWith('/host')) {
      final query = request.url.queryParameters;
      final asked = int.tryParse(query['term'] ?? '') ?? 0;
      if (unreachableTerms.contains(asked)) return Response(503);
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
    if (refuseGuestsUntilOutranked && outranked == 0) {
      return Response.notFound('');
    }
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

  /// La nube corta solo el socket del invitado [id].
  Future<void> dropGuest(String id) async => guests[id]?.sink.close();

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

  /// Un teléfono con datos móviles.
  RoomRepositoryImpl phone() {
    Future<List<NetworkInterface>> interfaces() async => [
      _Interface('pdp_ip0', ['10.20.30.40']),
    ];
    final repository = RoomRepositoryImpl(
      serverDataSource: SignalingServerDataSource(),
      clientDataSource: SignalingClientDataSource(),
      cloudRelayDataSource: CloudRelayDataSource(
        reconnectBaseDelay: const Duration(seconds: 30),
        maxReconnectDelay: const Duration(seconds: 30),
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

  /// Ana abre la frecu por internet y se unen [names], en ese orden.
  Future<(RoomRepositoryImpl, List<RoomRepositoryImpl>)> openRoom(
    List<String> names,
  ) async {
    final ana = phone();
    final created = await ana.createRoom(
      name: 'Ruta',
      accessCode: '1234',
      displayName: 'Ana',
      reach: RoomReach.internet,
    );
    final internetId = created.dataOrNull!.internetId!;
    final guests = <RoomRepositoryImpl>[];
    for (final name in names) {
      final guest = phone();
      final joined = await guest.joinInternetRoom(
        internetId: internetId,
        accessCode: '1234',
        displayName: name,
      );
      expect(joined.isSuccess, isTrue);
      guests.add(guest);
    }
    for (final guest in guests) {
      await _first<RoomSuccession?>(
        guest.watchSuccession(),
        (s) => s?.members.length == names.length + 1 && s?.hostSecret != null,
      );
    }
    return (ana, guests);
  }

  test(
    'AC1: the successor refused with 409 when opening its relay joins '
    'as a guest through the guest socket instead of losing the room',
    () async {
      final (ana, [beto, _]) = await openRoom(['Beto', 'Caro']);
      final anaId = ana.localParticipantId!;

      // Ana sigue llevando la frecu con un turno mayor que el que pedirá
      // Beto, y la nube corta solo el socket de Beto y le rechaza el de
      // invitado: Beto cree que Ana se cayó y le toca tomarla.
      cloud
        ..term = 3
        ..refuseGuestsUntilOutranked = true;
      final change = _first(beto.watchHostChanges(), (c) => !c.you);
      await cloud.dropGuest('g1');

      final seen = await change;
      expect(seen.reason, HostChangeReason.outranked);
      expect(seen.hostId, anaId);
      expect(seen.hostName, 'Ana');
      expect(cloud.outranked, 1);

      bool betoIsGuest(List<Participant> list) =>
          list.any((p) => p.isHost && p.displayName == 'Ana') &&
          list.any((p) => !p.isHost && p.displayName == 'Beto');
      await _first(beto.watchParticipants(), betoIsGuest);
      await _first(ana.watchParticipants(), betoIsGuest);
      await _first(
        beto.watchStatus(),
        (s) => s == const RoomStatus.connected(),
      );

      // No vuelve a intentar su relé.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(cloud.outranked, 1);
      expect(cloud.hostTerms, [1]);
    },
  );

  test('AC2: the successor whose relay fails for another reason (503) '
      'loses the room as before', () async {
    final (_, [beto]) = await openRoom(['Beto']);

    // Ana se cae sin red, y la nube no deja llegar el relé de Beto.
    cloud.unreachableTerms.addAll([1, 2]);
    const lost = RoomStatus.closed(reason: 'host_unreachable');
    final closed = _first(beto.watchStatus(), (s) => s == lost);
    await cloud.dropHost();

    expect(await closed, lost);
    expect(cloud.outranked, 0);
  });
}
