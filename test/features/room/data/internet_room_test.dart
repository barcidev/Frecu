// I1: CUANDO el anfitrión abre una frecu por internet ENTONCES su relé se conecta al punto de encuentro y la frecu lleva su id por internet.
// I2: CUANDO un invitado se une por el id de la frecu ENTONCES entra por la nube y ambos ven la lista de participantes.
// I3: CUANDO un invitado por internet manda un código incorrecto ENTONCES lo rechaza el anfitrión, igual que en la red local.
// I4: CUANDO el relé del anfitrión se cae ENTONCES sus invitados por internet salen de la frecu.
// I5: CUANDO no hay punto de encuentro configurado ENTONCES abrir o unirse por internet falla sin dejar nada abierto.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/room/data/datasources/cloud_relay_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Punto de encuentro falso: el mismo contrato que el Durable Object.
class _FakeCloud {
  HttpServer? _server;
  WebSocketChannel? host;
  final Map<String, WebSocketChannel> guests = {};
  int _next = 0;

  int get port => _server!.port;

  CloudConfig get config => CloudConfig('http://127.0.0.1:$port');

  Future<void> start() async {
    _server = await shelf_io.serve(
      (request) {
        final path = request.url.path;
        return webSocketHandler((WebSocketChannel channel, String? _) {
          if (path.endsWith('/host')) {
            host = channel;
            channel.stream.listen(
              (data) {
                final envelope =
                    jsonDecode(data as String) as Map<String, dynamic>;
                final guest = guests[envelope['c']];
                if (guest == null) return;
                if (envelope['t'] == 'msg') guest.sink.add(envelope['d']);
                if (envelope['t'] == 'close') unawaited(guest.sink.close());
              },
              onDone: () {
                host = null;
                final dropped = List.of(guests.values);
                guests.clear();
                for (final guest in dropped) {
                  unawaited(guest.sink.close());
                }
              },
            );
          } else {
            final id = 'g${++_next}';
            guests[id] = channel;
            host?.sink.add(jsonEncode({'t': 'open', 'c': id, 'k': 'k$id'}));
            channel.stream.listen(
              (data) =>
                  host?.sink.add(jsonEncode({'t': 'msg', 'c': id, 'd': data})),
              onDone: () {
                guests.remove(id);
                host?.sink.add(jsonEncode({'t': 'close', 'c': id}));
              },
            );
          }
        })(request);
      },
      '127.0.0.1',
      0,
    );
  }

  Future<void> dropHost() async => host?.sink.close();

  Future<void> stop() async => _server?.close(force: true);
}

Future<T> _firstWhere<T>(Stream<T> stream, bool Function(T) test) =>
    stream.firstWhere(test).timeout(const Duration(seconds: 5));

void main() {
  late _FakeCloud cloud;
  late RoomRepositoryImpl host;
  late RoomRepositoryImpl guest;

  setUp(() async {
    cloud = _FakeCloud();
    await cloud.start();
    host = RoomRepositoryImpl(
      serverDataSource: SignalingServerDataSource(),
      clientDataSource: SignalingClientDataSource(),
      cloudRelayDataSource: CloudRelayDataSource(
        reconnectBaseDelay: const Duration(seconds: 30),
      ),
      cloudConfig: cloud.config,
      networkInterfacesProvider: () async => [],
      signalingPort: 0,
    );
    guest = RoomRepositoryImpl(
      serverDataSource: SignalingServerDataSource(),
      clientDataSource: SignalingClientDataSource(),
      cloudConfig: cloud.config,
      networkInterfacesProvider: () async => [],
      signalingPort: 0,
      maxReconnectAttempts: 1,
    );
  });

  tearDown(() async {
    await guest.dispose();
    await host.dispose();
    await cloud.stop();
  });

  test('I1: a room opened over the internet carries its internet id and '
      'no made-up local address', () async {
    final result = await host.createRoom(
      name: 'Ruta',
      accessCode: '1234',
      displayName: 'Ana',
      internet: true,
    );

    final room = result.dataOrNull!;
    expect(CloudConfig.isRoomId(room.internetId!), isTrue);
    expect(room.hostAddress, isEmpty);
    expect(cloud.host, isNotNull);
  });

  test('I2: a guest joins through the cloud and both see each other', () async {
    final room = (await host.createRoom(
      name: 'Ruta',
      accessCode: '1234',
      displayName: 'Ana',
      internet: true,
    )).dataOrNull!;

    final joined = await guest.joinInternetRoom(
      internetId: room.internetId!,
      accessCode: '1234',
      displayName: 'Beto',
    );

    expect(joined.isSuccess, isTrue);
    expect(joined.dataOrNull!.internetId, room.internetId);
    expect(joined.dataOrNull!.name, 'Ruta');
    Set<String> names(List<Participant> list) =>
        list.map((p) => p.displayName).toSet();
    await _firstWhere(
      host.watchParticipants(),
      (list) => names(list).containsAll({'Ana', 'Beto'}),
    );
    await _firstWhere(
      guest.watchParticipants(),
      (list) => names(list).containsAll({'Ana', 'Beto'}),
    );
    // El anfitrión marca a quien entró por internet; a sí mismo, no.
    final seen = await host.watchParticipants().first;
    expect(seen.firstWhere((p) => p.displayName == 'Beto').remote, isTrue);
    expect(seen.firstWhere((p) => p.displayName == 'Ana').remote, isFalse);
  });

  test('I3: a wrong code over the internet is rejected by the host', () async {
    final room = (await host.createRoom(
      name: 'Ruta',
      accessCode: '1234',
      internet: true,
    )).dataOrNull!;

    final joined = await guest.joinInternetRoom(
      internetId: room.internetId!,
      accessCode: '9999',
      displayName: 'Beto',
    );

    expect(joined.failureOrNull, const Failure.invalidAccessCode());
  });

  test(
    'I4: when the host relay drops, internet guests leave the room',
    () async {
      final room = (await host.createRoom(
        name: 'Ruta',
        accessCode: '1234',
        displayName: 'Ana',
        internet: true,
      )).dataOrNull!;
      await guest.joinInternetRoom(
        internetId: room.internetId!,
        accessCode: '1234',
        displayName: 'Beto',
      );
      await _firstWhere(host.watchParticipants(), (list) => list.length == 2);

      await cloud.dropHost();

      await _firstWhere(host.watchParticipants(), (list) => list.length == 1);
    },
  );

  test(
    'I5: without a meeting point, internet create and join fail cleanly',
    () async {
      final offline = RoomRepositoryImpl(
        serverDataSource: SignalingServerDataSource(),
        clientDataSource: SignalingClientDataSource(),
        // Explícito: sin `FRECU_CLOUD_URL` coincide con el valor por defecto.
        // ignore: avoid_redundant_argument_values
        cloudConfig: CloudConfig.disabled,
        networkInterfacesProvider: () async => [],
        signalingPort: 0,
      );
      addTearDown(offline.dispose);

      final created = await offline.createRoom(
        name: 'Ruta',
        accessCode: '1234',
        internet: true,
      );
      final joined = await offline.joinInternetRoom(
        internetId: CloudConfig.newRoomId(),
        accessCode: '1234',
        displayName: 'Beto',
      );

      expect(created.isFailure, isTrue);
      expect(joined.failureOrNull, const Failure.hostUnreachable());
    },
  );
}
