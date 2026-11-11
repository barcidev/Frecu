// AC2: CUANDO la nube cierra el socket vigente del relé del anfitrión con el código 4000 (otro anfitrión con el mismo secreto tomó la sala) ENTONCES el relé no vuelve a conectar y avisa, igual que con el 409.
// AC3: CUANDO el relé falla por otra causa (sin red, 403, 404, 503 o un cierre con otro código) ENTONCES sigue reconectando como hoy, sin avisar.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/network/network_return.dart';
import 'package:frecu/features/room/data/datasources/cloud_relay_datasource.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Punto de encuentro falso: acepta el relé del anfitrión o lo rechaza con
/// [refuse] (un código HTTP), y cuenta los intentos.
class _Cloud {
  HttpServer? _server;

  /// Socket vigente del anfitrión.
  WebSocketChannel? host;

  /// Código HTTP con que se rechaza el próximo intento; nulo: se acepta.
  int? refuse;

  /// Intentos de abrir el relé, aceptados o no.
  int attempts = 0;

  /// Relés aceptados.
  int accepted = 0;

  Uri get uri => Uri.parse('ws://127.0.0.1:${_server!.port}/rooms/r/host');

  Future<void> start() async {
    _server = await shelf_io.serve(_handle, '127.0.0.1', 0);
  }

  FutureOr<Response> _handle(Request request) {
    attempts++;
    final status = refuse;
    if (status != null) return Response(status);
    return webSocketHandler((WebSocketChannel channel, String? _) {
      accepted++;
      host = channel;
      channel.stream.listen((_) {});
    })(request);
  }

  /// Cierra el socket vigente del anfitrión con [code].
  Future<void> closeHost([int? code]) async => host?.sink.close(code);

  Future<void> stop() async => _server?.close(force: true);
}

Future<void> _until(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late _Cloud cloud;
  late CloudRelayDataSource relay;
  late int outranked;

  setUp(() async {
    cloud = _Cloud();
    await cloud.start();
    outranked = 0;
    relay = CloudRelayDataSource(
      reconnectBaseDelay: const Duration(milliseconds: 20),
      maxReconnectDelay: const Duration(milliseconds: 40),
      networkWatcher: NetworkReturnWatcher(interfaces: () async => []),
    )..onOutranked = () => outranked++;
    await relay.start(cloud.uri, onGuest: (_) {});
    expect(relay.isConnected, isTrue);
  });

  tearDown(() async {
    await relay.dispose();
    await cloud.stop();
  });

  /// Tras unos reintentos, los intentos ya no cambian.
  Future<void> expectNoMoreAttempts() async {
    final seen = cloud.attempts;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(cloud.attempts, seen);
  }

  test(
    'AC2: a reconnect refused with 409 stops reconnecting and tells once',
    () async {
      cloud.refuse = 409;
      await cloud.closeHost();

      await _until(() => outranked > 0);
      await expectNoMoreAttempts();
      expect(outranked, 1);
      expect(relay.isConnected, isFalse);
      expect(cloud.accepted, 1);
    },
  );

  test('AC2: the current socket closed with 4000 does not reconnect and '
      'tells once', () async {
    await cloud.closeHost(4000);

    await _until(() => outranked > 0);
    await expectNoMoreAttempts();
    expect(outranked, 1);
    expect(relay.isConnected, isFalse);
    expect(cloud.attempts, 1);
  });

  for (final status in [403, 404, 503]) {
    test('AC3: a reconnect refused with $status keeps reconnecting without '
        'telling', () async {
      cloud.refuse = status;
      await cloud.closeHost();
      await _until(() => cloud.attempts >= 3);

      cloud.refuse = null;
      await _until(() => relay.isConnected);
      expect(cloud.accepted, 2);
      expect(outranked, 0);
    });
  }

  for (final code in [null, 1000, 3000, 4001]) {
    test('AC3: the socket closed with ${code ?? 'no code'} reconnects without '
        'telling', () async {
      await cloud.closeHost(code);

      await _until(() => cloud.accepted == 2 && relay.isConnected);
      expect(outranked, 0);
    });
  }

  test(
    'AC3: without a network the relay keeps trying and does not tell',
    () async {
      await cloud.stop();
      await cloud.closeHost();
      await _until(() => !relay.isConnected);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(outranked, 0);
    },
  );

  test('AC2: isOutranked only recognises the 409 of the host upgrade', () {
    expect(
      CloudRelayDataSource.isOutranked(
        WebSocketChannelException.from(const WebSocketException('', 409)),
      ),
      isTrue,
    );
    expect(
      CloudRelayDataSource.isOutranked(const WebSocketException('', 409)),
      isTrue,
    );
    for (final error in <Object>[
      WebSocketChannelException.from(const WebSocketException('', 403)),
      WebSocketChannelException.from(const WebSocketException('closed')),
      const SocketException('down'),
      TimeoutException('slow'),
    ]) {
      expect(CloudRelayDataSource.isOutranked(error), isFalse);
    }
  });
}
