// F6: CUANDO la conexión con el anfitrión cae (una o varias veces) ENTONCES hay un solo bucle de reconexión; al rendirse cierra la frecu una sola vez con `host_unreachable`, y una unión fallida nunca deja bucles.
// F8: CUANDO no se puede conectar con el anfitrión (sin respuesta, socket rechazado o handshake roto) ENTONCES unirse falla con `hostUnreachable`, no con un error inesperado.
// F9: CUANDO alguien se une ENTONCES la frecu lleva el nombre que trae el `welcome`; sin él (anfitrión anterior) queda sin nombre para que la pantalla use el genérico.
// P105: CUANDO la frecu reconecta ENTONCES el estado dice cuánto falta para el próximo intento y cuál es.
// AC3: CUANDO un invitado reconecta y aparece una red nueva durante la espera ENTONCES reintenta antes de que termine la espera, el estado pasa a `reconnecting(retryIn: 0, attempt)` antes del intento y vuelve a quedar en línea.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';

/// Cliente de señalización de mentira: responde el `join` con un `welcome`
/// y deja tirar la red.
class _FakeClient extends SignalingClientDataSource {
  final _messages = StreamController<SignalingMessage>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  bool _connected = false;

  /// Intentos de conexión.
  int connects = 0;

  /// Lo que lanza conectar; nulo si conecta.
  Exception? connectError;

  /// Responde el `join` con un `welcome`.
  bool answerJoin = true;

  /// Nombre de la frecu en el `welcome`.
  String? roomName = 'Ruta 40';

  /// Quienes además figuran en el `welcome` (p. ej. un lugar viejo).
  List<Participant> extra = const [];

  int _peers = 1;

  @override
  bool get isConnected => _connected;

  @override
  Stream<SignalingMessage> get messages => _messages.stream;

  @override
  Stream<bool> get connectionState => _connection.stream;

  @override
  Future<void> connect(Uri uri) async {
    connects++;
    await disconnect();
    final error = connectError;
    if (error != null) throw error;
    _connected = true;
    _connection.add(true);
  }

  @override
  void send(SignalingMessage message) {
    if (!_connected || message is! SignalingJoinMessage || !answerJoin) return;
    final id = 'peer_${++_peers}';
    scheduleMicrotask(
      () => _messages.add(
        SignalingMessage.welcome(
          peerId: id,
          participants: [
            const Participant(
              id: 'peer_1',
              displayName: 'Andrés',
              isHost: true,
            ),
            ...extra,
            Participant(id: id, displayName: message.displayName),
          ],
          roomName: roomName,
        ),
      ),
    );
  }

  @override
  Future<void> disconnect() async => drop();

  /// Se cae la red.
  void drop() {
    if (!_connected) return;
    _connected = false;
    _connection.add(false);
  }

  /// Llega un aviso de desconexión más (p. ej. de un socket viejo).
  void echoDisconnected() => _connection.add(false);

  @override
  Future<void> dispose() async {
    await _messages.close();
    await _connection.close();
  }
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

void main() {
  late _FakeClient client;
  late RoomRepositoryImpl repository;
  late List<RoomStatus> statuses;
  late StreamSubscription<RoomStatus> statusSub;

  setUp(() {
    client = _FakeClient();
    repository = RoomRepositoryImpl(
      serverDataSource: SignalingServerDataSource(),
      clientDataSource: client,
      networkInterfacesProvider: () async => [],
      reconnectBaseDelay: const Duration(milliseconds: 10),
      maxReconnectAttempts: 3,
      welcomeTimeout: const Duration(milliseconds: 200),
      rejoinWelcomeTimeout: const Duration(milliseconds: 50),
    );
    statuses = [];
    statusSub = repository.watchStatus().listen(statuses.add);
  });

  tearDown(() async {
    await statusSub.cancel();
    await repository.dispose();
    await client.dispose();
  });

  Future<void> join() async {
    final result = await repository.joinRoom(
      hostAddress: '192.168.43.1',
      port: 47800,
      accessCode: '4821',
      displayName: 'Ana',
    );
    expect(result.isSuccess, isTrue);
  }

  Iterable<RoomStatus> reconnects() => statuses.where(
    (s) => s.maybeWhen(reconnecting: (_, _) => true, orElse: () => false),
  );

  Iterable<RoomStatus> closures() => statuses.where(
    (s) => s.maybeWhen(closed: (_) => true, orElse: () => false),
  );

  group('F6 · un solo bucle de reconexión', () {
    test('F6: aunque la conexión avise varias veces, reintenta una sola vez '
        'por turno y al rendirse cierra la frecu una vez', () async {
      await join();
      expect(client.connects, 1);
      client
        ..connectError = const SocketException('host down')
        ..drop()
        ..echoDisconnected()
        ..echoDisconnected();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      client.echoDisconnected();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Un bucle: 3 intentos, no 3 por cada aviso.
      expect(client.connects, 1 + 3);
      expect(closures(), [const RoomStatus.closed(reason: 'host_unreachable')]);
      expect(repository.localParticipantId, isNull);

      // Ya cerrada, otro aviso no reabre nada.
      client.echoDisconnected();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(client.connects, 1 + 3);
    });

    test('P105: cada intento dice cuánto falta y cuál es', () async {
      await join();
      client
        ..connectError = const SocketException('host down')
        ..drop();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(reconnects().toList(), const [
        RoomStatus.reconnecting(
          retryIn: Duration(milliseconds: 10),
          attempt: 1,
        ),
        RoomStatus.reconnecting(
          retryIn: Duration(milliseconds: 20),
          attempt: 2,
        ),
        RoomStatus.reconnecting(
          retryIn: Duration(milliseconds: 40),
          attempt: 3,
        ),
      ]);
    });

    test(
      'F6: si vuelve, queda en línea con el id nuevo y sin cerrar',
      () async {
        await join();
        final firstId = repository.localParticipantId;
        client.drop();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(statuses.last, const RoomStatus.connected());
        expect(repository.localParticipantId, isNot(firstId));
        expect(closures(), isEmpty);
        expect(client.connects, 2);
      },
    );

    test(
      'F6: al volver, el lugar viejo propio no aparece como otra persona',
      () async {
        await join();
        final firstId = repository.localParticipantId!;
        client
          ..extra = [Participant(id: firstId, displayName: 'Ana')]
          ..drop();
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final people = await repository.watchParticipants().first;
        expect(people.map((p) => p.id), [
          'peer_1',
          repository.localParticipantId,
        ]);
      },
    );

    test('F6: una unión fallida no deja bucles de reconexión', () async {
      client.connectError = const SocketException('nobody here');
      final result = await repository.joinRoom(
        hostAddress: '10.0.0.9',
        port: 47800,
        accessCode: '4821',
        displayName: 'Ana',
      );
      expect(result.failureOrNull, const Failure.hostUnreachable());

      client.echoDisconnected();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(client.connects, 1);
      expect(reconnects(), isEmpty);
      expect(statuses.last, const RoomStatus.idle());
    });

    test('F6: salir durante la reconexión la detiene', () async {
      await join();
      client
        ..connectError = const SocketException('host down')
        ..drop();
      await repository.leaveRoom();
      final connects = client.connects;
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(client.connects, connects);
      expect(closures(), [const RoomStatus.closed(reason: 'user_left')]);
    });
  });

  group('AC3 · reintentar en cuanto vuelve la red', () {
    test('AC3: si aparece una red durante la espera reintenta antes y vuelve '
        'a quedar en línea', () async {
      final otherClient = _FakeClient();
      var interfaces = <NetworkInterface>[];
      final slow = RoomRepositoryImpl(
        serverDataSource: SignalingServerDataSource(),
        clientDataSource: otherClient,
        networkInterfacesProvider: () async => interfaces,
        networkReturnPollInterval: const Duration(milliseconds: 10),
        reconnectBaseDelay: const Duration(seconds: 5),
        maxReconnectAttempts: 3,
        welcomeTimeout: const Duration(milliseconds: 200),
        rejoinWelcomeTimeout: const Duration(milliseconds: 50),
      );
      final seen = <RoomStatus>[];
      final sub = slow.watchStatus().listen(seen.add);
      addTearDown(() async {
        await sub.cancel();
        await slow.dispose();
        await otherClient.dispose();
      });
      final joined = await slow.joinRoom(
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '4821',
        displayName: 'Ana',
      );
      expect(joined.isSuccess, isTrue);

      final clock = Stopwatch()..start();
      otherClient.drop();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(otherClient.connects, 1);
      interfaces = [
        _Interface('wlan0', ['192.168.43.27']),
      ];
      while (seen.last != const RoomStatus.connected() &&
          clock.elapsed < const Duration(seconds: 2)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(clock.elapsed, lessThan(const Duration(seconds: 2)));
      expect(otherClient.connects, 2);
      expect(
        seen,
        containsAllInOrder(const [
          RoomStatus.reconnecting(retryIn: Duration(seconds: 5), attempt: 1),
          RoomStatus.reconnecting(retryIn: Duration.zero, attempt: 1),
          RoomStatus.connected(),
        ]),
      );
    });
  });

  group('F8 · unirse con límite y el fallo correcto', () {
    for (final (label, error) in [
      ('sin respuesta', TimeoutException('ready')),
      ('socket rechazado', const SocketException('refused')),
      ('handshake roto', const WebSocketException('not a websocket')),
    ]) {
      test('F8: $label es que el anfitrión no responde', () async {
        client.connectError = error;
        final result = await repository.joinRoom(
          hostAddress: '192.168.43.7',
          port: 47800,
          accessCode: '4821',
          displayName: 'Ana',
        );
        expect(result.failureOrNull, const Failure.hostUnreachable());
      });
    }

    test('F8: sin welcome a tiempo es que el anfitrión no responde', () async {
      client.answerJoin = false;
      final result = await repository.joinRoom(
        hostAddress: '192.168.43.7',
        port: 47800,
        accessCode: '4821',
        displayName: 'Ana',
      );
      expect(result.failureOrNull, const Failure.hostUnreachable());
      expect(client.isConnected, isFalse);
    });

    test('F11: unirse pasa por «conectando» antes de «en línea»', () async {
      await join();
      await pumpEventQueue();
      expect(
        statuses,
        containsAllInOrder(const [
          RoomStatus.connecting(),
          RoomStatus.connected(),
        ]),
      );
    });
  });

  group('F9 · nombre de la frecu', () {
    test('F9: quien se une recibe el nombre de la frecu del welcome', () async {
      final result = await repository.joinRoom(
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '4821',
        displayName: 'Ana',
      );
      expect(result.dataOrNull?.name, 'Ruta 40');
    });

    test('F9: sin nombre en el welcome la frecu queda sin nombre', () async {
      client.roomName = null;
      final result = await repository.joinRoom(
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '4821',
        displayName: 'Ana',
      );
      expect(result.dataOrNull?.name, isEmpty);
    });
  });
}
