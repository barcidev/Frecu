// Red de Frecu (invitado): el repositorio ata la app a la red del anfitrión antes de probar si responde; conecta a la red de la frecu por el canal `frecu/wifi` y espera a que el anfitrión responda; cada código nativo se traduce a su motivo, sin la parte nativa no se conecta solo, y si conectó pero el anfitrión nunca responde es que no encontró la red. Soltar la red llama al canal.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/network/data/datasources/wifi_join_datasource.dart';
import 'package:frecu/features/network/data/repositories/wifi_join_repository_impl.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';

void main() {
  late List<String> calls;
  late List<Object?> arguments;
  late Exception? joinError;
  late bool routes;
  late List<bool> probes;

  setUp(() {
    calls = [];
    arguments = [];
    joinError = null;
    routes = true;
    probes = [];
  });

  WifiJoinRepositoryImpl repository() => WifiJoinRepositoryImpl(
    dataSource: WifiJoinDataSource(
      invoke: (method, args) async {
        calls.add(method);
        arguments.add(args);
        if (method == 'route') return routes;
        if (method == 'join' && joinError != null) throw joinError!;
        return null;
      },
      probe: (host, port, timeout) async {
        calls.add('probe $host:$port');
        return probes.isNotEmpty && probes.removeAt(0);
      },
      routes: true,
      native: true,
    ),
    joinTimeout: const Duration(milliseconds: 30),
    retryDelay: const Duration(milliseconds: 1),
  );

  const wifi = WifiCredentials(
    ssid: 'AndroidShare_4821',
    passphrase: 'a3f91c7e5b2d',
  );

  test('route ata la app a la red del anfitrión', () async {
    expect(await repository().route('192.168.62.1'), isTrue);
    expect(calls, ['route']);
    expect(arguments, [
      {'host': '192.168.62.1'},
    ]);
  });

  test('reaches ata la app y luego prueba si el anfitrión responde', () async {
    probes.add(true);

    expect(await repository().reaches('192.168.62.1', 47800), isTrue);
    expect(calls, ['route', 'probe 192.168.62.1:47800']);
  });

  test('join conecta a la red y espera a que el anfitrión responda', () async {
    probes.addAll([false, false, true]);

    final result = await repository().join(
      wifi,
      host: '192.168.62.1',
      port: 47800,
    );

    expect(result.isSuccess, isTrue);
    expect(calls.first, 'join');
    expect(arguments.first, {
      'ssid': 'AndroidShare_4821',
      'passphrase': 'a3f91c7e5b2d',
    });
    expect(calls.where((call) => call.startsWith('probe')), hasLength(3));
  });

  test('una red abierta va sin clave', () async {
    probes.add(true);

    await repository().join(
      const WifiCredentials(ssid: 'Frecu'),
      host: '192.168.62.1',
      port: 47800,
    );

    expect(arguments.first, {'ssid': 'Frecu', 'passphrase': null});
  });

  test('si el anfitrión nunca responde, no encontró la red', () async {
    final result = await repository().join(
      wifi,
      host: '192.168.62.1',
      port: 47800,
    );

    expect(
      result.failureOrNull,
      const Failure.wifiJoin(WifiJoinFailureReason.notFound),
    );
  });

  test('cada código nativo se traduce a su motivo', () async {
    const reasons = {
      'unsupported': WifiJoinFailureReason.unsupported,
      'declined': WifiJoinFailureReason.declined,
      'not_found': WifiJoinFailureReason.notFound,
      'failed': WifiJoinFailureReason.failed,
      'otro': WifiJoinFailureReason.failed,
    };
    for (final MapEntry(key: native, value: reason) in reasons.entries) {
      joinError = PlatformException(code: native);

      final result = await repository().join(
        wifi,
        host: '192.168.62.1',
        port: 47800,
      );

      expect(result.failureOrNull, Failure.wifiJoin(reason), reason: native);
    }
  });

  test('sin la parte nativa no se conecta solo', () async {
    joinError = MissingPluginException();

    final result = await repository().join(
      wifi,
      host: '192.168.62.1',
      port: 47800,
    );

    expect(
      result.failureOrNull,
      const Failure.wifiJoin(WifiJoinFailureReason.unsupported),
    );
  });

  test('sin la parte nativa route responde que no y soltar no falla', () async {
    final repo = WifiJoinRepositoryImpl(
      dataSource: WifiJoinDataSource(
        invoke: (_, _) async => throw MissingPluginException(),
        routes: true,
        native: true,
      ),
    );

    expect(await repo.route('192.168.62.1'), isFalse);
    await expectLater(repo.release(), completes);
  });

  test('fuera de Android e iOS no llama al canal: no hay red que atar ni '
      'conexión sola', () async {
    final repo = WifiJoinRepositoryImpl(
      dataSource: WifiJoinDataSource(
        invoke: (method, _) async {
          calls.add(method);
          return null;
        },
        routes: false,
        native: false,
      ),
    );

    expect(await repo.route('192.168.62.1'), isFalse);
    expect(
      (await repo.join(wifi, host: '192.168.62.1', port: 47800)).failureOrNull,
      const Failure.wifiJoin(WifiJoinFailureReason.unsupported),
    );
    await repo.release();
    expect(calls, isEmpty);
  });

  test('release suelta la red', () async {
    await repository().release();

    expect(calls, ['release']);
  });
}
