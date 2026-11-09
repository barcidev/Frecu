// Red de Frecu (anfitrión): el repositorio crea la red por el canal `frecu/hotspot` y devuelve su nombre, clave, interfaz e IPv4; si Android dice que falta el permiso, lo pide una sola vez y reintenta; cada código nativo se traduce a su motivo, y sin la parte nativa (iOS o pruebas) la red no está disponible. Apagar la red y los avisos de Android pasan tal cual.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/network/data/datasources/local_hotspot_datasource.dart';
import 'package:frecu/features/network/data/repositories/local_hotspot_repository_impl.dart';
import 'package:frecu/features/network/domain/entities/local_hotspot.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  late List<String> calls;
  late List<Permission> requested;
  late List<Object?> answers;
  late PermissionStatus permission;
  late StreamController<void> stopped;

  setUp(() {
    calls = [];
    requested = [];
    answers = [];
    permission = PermissionStatus.granted;
    stopped = StreamController<void>.broadcast();
  });

  tearDown(() => stopped.close());

  LocalHotspotRepositoryImpl repository() => LocalHotspotRepositoryImpl(
    dataSource: LocalHotspotDataSource(
      invoke: (method) async {
        calls.add(method);
        if (method != 'start') return null;
        final answer = answers.removeAt(0);
        if (answer is Exception) throw answer;
        return answer;
      },
      stopped: stopped.stream,
      requestPermission: (asked) async {
        requested.add(asked);
        return permission;
      },
    ),
  );

  const info = {
    'ssid': 'AndroidShare_4821',
    'passphrase': 'a3f91c7e5b2d',
    'interface': 'swlan0',
    'address': '192.168.62.1',
  };
  const hotspot = LocalHotspot(
    credentials: WifiCredentials(
      ssid: 'AndroidShare_4821',
      passphrase: 'a3f91c7e5b2d',
    ),
    interfaceName: 'swlan0',
    address: '192.168.62.1',
  );

  PlatformException code(String code) => PlatformException(code: code);

  test('crea la red con su nombre, clave, interfaz e IPv4', () async {
    answers.add(info);

    final result = await repository().start();

    expect(result.dataOrNull, hotspot);
    expect(calls, ['start']);
    expect(requested, isEmpty);
  });

  test('sin interfaz ni IPv4 la red igual sirve', () async {
    answers.add({'ssid': 'AndroidShare_4821', 'passphrase': 'clave'});

    final result = await repository().start();

    expect(
      result.dataOrNull,
      const LocalHotspot(
        credentials: WifiCredentials(
          ssid: 'AndroidShare_4821',
          passphrase: 'clave',
        ),
      ),
    );
  });

  test('sin el permiso de dispositivos cercanos lo pide y reintenta', () async {
    answers.addAll([code('permission_nearby'), info]);

    final result = await repository().start();

    expect(result.dataOrNull, hotspot);
    expect(requested, [Permission.nearbyWifiDevices]);
    expect(calls, ['start', 'start']);
  });

  test('en Android 12 o anterior pide el de ubicación', () async {
    answers.addAll([code('permission_location'), info]);

    await repository().start();

    expect(requested, [Permission.locationWhenInUse]);
  });

  test('si niegan el permiso no reintenta y dice cuál falta', () async {
    permission = PermissionStatus.permanentlyDenied;
    answers.add(code('permission_nearby'));

    final result = await repository().start();

    expect(
      result.failureOrNull,
      const Failure.hotspot(HotspotFailureReason.nearbyDenied),
    );
    expect(calls, ['start']);
  });

  test('si con el permiso vuelve a faltar, no lo pide otra vez', () async {
    answers.addAll([code('permission_location'), code('permission_location')]);

    final result = await repository().start();

    expect(
      result.failureOrNull,
      const Failure.hotspot(HotspotFailureReason.locationDenied),
    );
    expect(requested, hasLength(1));
  });

  test('cada código nativo se traduce a su motivo', () async {
    const reasons = {
      'unsupported': HotspotFailureReason.unsupported,
      'location_off': HotspotFailureReason.locationOff,
      'incompatible_mode': HotspotFailureReason.hotspotOn,
      'no_channel': HotspotFailureReason.failed,
      'disallowed': HotspotFailureReason.failed,
      'failed': HotspotFailureReason.failed,
    };
    for (final MapEntry(key: native, value: reason) in reasons.entries) {
      answers.add(code(native));

      final result = await repository().start();

      expect(result.failureOrNull, Failure.hotspot(reason), reason: native);
    }
  });

  test('sin la parte nativa la red no está disponible', () async {
    answers.add(MissingPluginException());

    final result = await repository().start();

    expect(
      result.failureOrNull,
      const Failure.hotspot(HotspotFailureReason.unsupported),
    );
  });

  test('una respuesta sin nombre de red es un fallo', () async {
    answers.add({'passphrase': 'clave'});

    final result = await repository().start();

    expect(
      result.failureOrNull,
      const Failure.hotspot(HotspotFailureReason.failed),
    );
  });

  test('apagar llama al canal y los avisos de Android pasan', () async {
    final repo = repository();
    final events = <void>[];
    final sub = repo.watchStopped().listen(events.add);

    await repo.stop();
    stopped.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(calls, ['stop']);
    expect(events, hasLength(1));
    await sub.cancel();
  });
}
