// Red de Frecu (anfitrión): la red empieza apagada; al crearla pasa por «creando» y queda al aire o falla con su motivo; si Android la apaga por su cuenta queda perdida; apagarla mientras se crea la deja apagada y, si Android llega a crearla, la apaga; crearla de nuevo con la red al aire o mientras se crea no hace nada. La interfaz de la red al aire es la que prefiere la invitación.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/domain/entities/local_hotspot.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/domain/repositories/local_hotspot_repository.dart';
import 'package:frecu/features/network/presentation/providers/local_hotspot_provider.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';

/// Red que responde cuando la prueba completa [pending].
class _FakeHotspots implements LocalHotspotRepository {
  final StreamController<void> stopped = StreamController<void>.broadcast();
  Completer<Result<LocalHotspot>> pending = Completer<Result<LocalHotspot>>();
  int starts = 0;
  int stops = 0;

  @override
  Future<Result<LocalHotspot>> start() {
    starts++;
    return pending.future;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Stream<void> watchStopped() => stopped.stream;
}

void main() {
  late _FakeHotspots hotspots;
  late ProviderContainer container;

  const hotspot = LocalHotspot(
    credentials: WifiCredentials(
      ssid: 'AndroidShare_4821',
      passphrase: 'a3f91c7e5b2d',
    ),
    interfaceName: 'swlan0',
    address: '192.168.62.1',
  );

  setUp(() {
    hotspots = _FakeHotspots();
    container = ProviderContainer(
      overrides: [localHotspotRepositoryProvider.overrideWithValue(hotspots)],
    );
  });

  tearDown(() async {
    container.dispose();
    await hotspots.stopped.close();
  });

  LocalHotspotState state() => container.read(localHotspotProvider);
  LocalHotspotNotifier notifier() =>
      container.read(localHotspotProvider.notifier);

  test('empieza apagada y sin interfaz', () {
    expect(state(), const LocalHotspotState.off());
    expect(notifier().interfaceName, isNull);
  });

  test('al crearla pasa por creando y queda al aire', () async {
    final started = notifier().start();
    expect(state(), const LocalHotspotState.starting());

    hotspots.pending.complete(const Result.success(hotspot));

    expect(await started, const LocalHotspotState.ready(hotspot));
    expect(state(), const LocalHotspotState.ready(hotspot));
    expect(notifier().interfaceName, 'swlan0');
  });

  test('si falla queda con su motivo', () async {
    final started = notifier().start();
    hotspots.pending.complete(
      const Result.failure(Failure.hotspot(HotspotFailureReason.hotspotOn)),
    );

    expect(
      await started,
      const LocalHotspotState.failed(HotspotFailureReason.hotspotOn),
    );
  });

  test('un fallo que no es de la red cuenta como fallo genérico', () async {
    final started = notifier().start();
    hotspots.pending.complete(const Result.failure(Failure.network()));

    expect(
      await started,
      const LocalHotspotState.failed(HotspotFailureReason.failed),
    );
  });

  test('si Android la apaga por su cuenta queda perdida', () async {
    final started = notifier().start();
    hotspots.pending.complete(const Result.success(hotspot));
    await started;

    hotspots.stopped.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(state(), const LocalHotspotState.lost());
    expect(notifier().interfaceName, isNull);
  });

  test('un aviso de Android con la red apagada no cambia nada', () async {
    expect(state(), const LocalHotspotState.off());

    hotspots.stopped.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(state(), const LocalHotspotState.off());
  });

  test('apagarla al aire la apaga en Android', () async {
    final started = notifier().start();
    hotspots.pending.complete(const Result.success(hotspot));
    await started;

    await notifier().stop();

    expect(state(), const LocalHotspotState.off());
    expect(hotspots.stops, 1);
  });

  test(
    'apagarla mientras se crea la deja apagada y apaga la que llegue',
    () async {
      final started = notifier().start();

      await notifier().stop();
      hotspots.pending.complete(const Result.success(hotspot));
      await started;

      expect(state(), const LocalHotspotState.off());
      expect(hotspots.stops, 2);
    },
  );

  test('crearla al aire o mientras se crea no hace nada', () async {
    final first = notifier().start();
    final second = notifier().start();
    expect(await second, const LocalHotspotState.starting());

    hotspots.pending.complete(const Result.success(hotspot));
    await first;
    await notifier().start();

    expect(hotspots.starts, 1);
  });

  test('apagada, apagarla no llama a Android', () async {
    await notifier().stop();

    expect(hotspots.stops, 0);
  });
}
