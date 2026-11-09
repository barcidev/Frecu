// PTT con volumen (corte 5 de la épica de hardware V1): el canal nativo
// `frecu/volume_ptt` se activa y desactiva, y sus pulsaciones llegan como
// down, up o toggle; lo desconocido se ignora y sin la parte nativa no falla.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/volume_buttons_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('activa y desactiva por el canal', () async {
    final calls = <(String, Object?)>[];
    final buttons = VolumeButtonsDataSource(
      invoke: (method, arguments) async => calls.add((method, arguments)),
    );

    await buttons.setEnabled(enabled: true);
    await buttons.setEnabled(enabled: false);

    expect(calls, [('setEnabled', true), ('setEnabled', false)]);
  });

  test('sin la parte nativa no falla', () async {
    await expectLater(
      VolumeButtonsDataSource().setEnabled(enabled: true),
      completes,
    );
  });

  test(
    'las pulsaciones llegan con su tipo y lo desconocido se ignora',
    () async {
      final raw = StreamController<Object?>();
      final buttons = VolumeButtonsDataSource(events: raw.stream);
      final seen = <VolumeKeyEvent>[];
      final sub = buttons.watch().listen(seen.add);

      raw
        ..add('down')
        ..add('up')
        ..add('rara')
        ..add('toggle');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      await raw.close();

      expect(seen, [
        VolumeKeyEvent.down,
        VolumeKeyEvent.up,
        VolumeKeyEvent.toggle,
      ]);
    },
  );
}
