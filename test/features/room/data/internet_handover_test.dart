// AC7: CUANDO el anfitrión de una frecu por internet la pasa a otra persona ENTONCES quien la recibe abre el relé de anfitrión con el mismo id, el mismo secreto y el turno siguiente, y emite `HostChange(you: true, reason: left)` con el nombre del anterior. Los demás vuelven por su socket de invitado con su mismo id, ven a quien la recibe como anfitrión y sin el anterior, y emiten `HostChange(reason: left)` con su nombre. La frecu conserva su id por internet (el enlace y el QR siguen sirviendo).
// AC8: CUANDO el anfitrión de una frecu por internet se cae ENTONCES cada invitado, al recibir `host_lost` (o al perder el socket), sigue el plan de caída con la sucesión: reintenta dos veces y luego la toma la primera persona de la sucesión que tiene red, abriendo el relé con el turno siguiente y razón `lost`. Los demás vuelven por su socket de invitado con su mismo id y emiten `HostChange(reason: lost)` con el nombre de quien la lleva.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/constants/cloud_config.dart';
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
/// vigente, gracia con `host_lost` y 409 a un turno menor.
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

  CloudConfig get config => CloudConfig('http://127.0.0.1:${_server!.port}');

  Future<void> start() async {
    _server = await shelf_io.serve(_handle, '127.0.0.1', 0);
  }

  FutureOr<Response> _handle(Request request) {
    final path = request.url.path;
    if (path.endsWith('/host')) {
      final query = request.url.queryParameters;
      final asked = int.tryParse(query['term'] ?? '') ?? 0;
      if (secret != null && query['secret'] != secret) {
        return Response.forbidden('');
      }
      if (asked < term) return Response(409);
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
      unawaited(guest.sink.close(1012));
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

  /// Un teléfono con datos móviles; con [online] en falso no tiene red.
  RoomRepositoryImpl phone({bool online = true}) {
    final repository = RoomRepositoryImpl(
      serverDataSource: SignalingServerDataSource(),
      clientDataSource: SignalingClientDataSource(),
      cloudRelayDataSource: CloudRelayDataSource(
        reconnectBaseDelay: const Duration(seconds: 30),
      ),
      cloudConfig: cloud.config,
      networkInterfacesProvider: () async => [
        if (online) _Interface('pdp_ip0', ['10.20.30.40']),
      ],
      signalingPort: 0,
      reconnectBaseDelay: const Duration(milliseconds: 200),
    );
    addTearDown(repository.dispose);
    return repository;
  }

  /// Ana abre la frecu por internet; Beto y Caro se unen, en ese orden.
  Future<(RoomRepositoryImpl, RoomRepositoryImpl, RoomRepositoryImpl, String)>
  room({bool betoOnline = true}) async {
    final ana = phone();
    final beto = phone(online: betoOnline);
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
    // Todos conocen la sucesión completa, con el secreto de anfitrión.
    for (final guest in [beto, caro]) {
      await _first<RoomSuccession?>(
        guest.watchSuccession(),
        (s) => s?.members.length == 3 && s?.hostSecret != null,
      );
    }
    return (ana, beto, caro, internetId);
  }

  bool led(List<Participant> list, String name) =>
      list.any((p) => p.isHost && p.displayName == name) &&
      !list.any((p) => p.displayName == 'Ana');

  test(
    'AC7: the host hands an internet room over: the heir opens the host '
    'relay with the next term and the others come back with their ids',
    () async {
      final (ana, beto, caro, internetId) = await room();
      expect(cloud.hostTerms, [1]);
      final betoId = beto.localParticipantId!;
      final caroId = caro.localParticipantId!;
      final heirChange = _first(beto.watchHostChanges(), (c) => c.you);
      final caroChange = _first(caro.watchHostChanges(), (c) => !c.you);

      expect((await ana.handOver(betoId)).isSuccess, isTrue);

      final mine = await heirChange;
      expect(mine.reason, HostChangeReason.left);
      expect(mine.previousHost, 'Ana');
      final seen = await caroChange;
      expect(seen.reason, HostChangeReason.left);
      expect(seen.hostId, betoId);
      expect(seen.hostName, 'Beto');
      expect(cloud.hostTerms, [1, 2]);

      await _first(caro.watchParticipants(), (list) => led(list, 'Beto'));
      expect(caro.localParticipantId, caroId);
      final state = await _first<RoomSuccession?>(
        caro.watchSuccession(),
        (s) => s?.term == 2,
      );
      expect(state!.internetId, internetId);
      expect(beto.succession?.internetId, internetId);
    },
  );

  test('AC8: the internet host drops: the first successor with a network '
      'takes the room with the next term and the others follow with their '
      'ids', () async {
    final (_, beto, caro, internetId) = await room();
    final betoId = beto.localParticipantId!;
    final caroId = caro.localParticipantId!;
    final heirChange = _first(beto.watchHostChanges(), (c) => c.you);
    final caroChange = _first(caro.watchHostChanges(), (c) => !c.you);

    await cloud.dropHost();

    final mine = await heirChange;
    expect(mine.reason, HostChangeReason.lost);
    expect(mine.previousHost, 'Ana');
    final seen = await caroChange;
    expect(seen.reason, HostChangeReason.lost);
    expect(seen.hostId, betoId);
    expect(seen.hostName, 'Beto');
    expect(cloud.hostTerms, [1, 2]);

    await _first(caro.watchParticipants(), (list) => led(list, 'Beto'));
    expect(caro.localParticipantId, caroId);
    expect(caro.succession?.internetId, internetId);
  });

  test('AC8: a successor without a network does not take the room; the next '
      'one does', () async {
    final (_, beto, caro, _) = await room(betoOnline: false);
    final caroId = caro.localParticipantId!;
    final heir = _first(caro.watchHostChanges(), (c) => c.you);
    final betoChange = _first(beto.watchHostChanges(), (c) => !c.you);

    await cloud.dropHost();

    final mine = await heir;
    expect(mine.reason, HostChangeReason.lost);
    expect(mine.previousHost, 'Ana');
    final seen = await betoChange;
    expect(seen.hostId, caroId);
    expect(seen.reason, HostChangeReason.lost);
    expect(cloud.hostTerms, [1, 2]);
    await _first(beto.watchParticipants(), (list) => led(list, 'Caro'));
  });
}
