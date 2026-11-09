// Auricular al acercar (corte 6 de la épica de hardware V1): el canal
// `frecu/proximity` se activa y dice si el teléfono tiene sensor; las
// lecturas llegan como cerca (true) o lejos (false) y lo demás se ignora.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/proximity_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('activa por el canal y dice si hay sensor', () async {
    final sensor = ProximityDataSource(invoke: (_, enabled) async => enabled);

    expect(await sensor.setEnabled(enabled: true), isTrue);
    expect(await sensor.setEnabled(enabled: false), isFalse);
  });

  test('sin la parte nativa cuenta como sin sensor', () async {
    expect(await ProximityDataSource().setEnabled(enabled: true), isFalse);
  });

  test('las lecturas llegan como cerca o lejos', () async {
    final raw = StreamController<Object?>();
    final seen = <bool>[];
    final sub = ProximityDataSource(events: raw.stream)
        .watch()
        .listen(seen.add);

    raw
      ..add(true)
      ..add('x')
      ..add(false);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    await raw.close();

    expect(seen, [true, false]);
  });
}
