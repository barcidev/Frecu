// Filtro de viento (corte 7 de la épica de hardware V1): el canal
// `frecu/wind_filter` engancha o quita el paso alto y dice si pudo (falla
// mientras WebRTC no ha arrancado o sin la parte nativa).
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/wind_filter_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('engancha y quita por el canal y dice si pudo', () async {
    final calls = <(String, Object?)>[];
    final filter = WindFilterDataSource(
      invoke: (method, enabled) async {
        calls.add((method, enabled));
        return true;
      },
    );

    expect(await filter.setEnabled(enabled: true), isTrue);
    expect(await filter.setEnabled(enabled: false), isTrue);
    expect(calls, [('setEnabled', true), ('setEnabled', false)]);
  });

  test('si WebRTC aún no arrancó, no queda enganchado', () async {
    final filter = WindFilterDataSource(invoke: (_, _) async => false);

    expect(await filter.setEnabled(enabled: true), isFalse);
  });

  test('sin la parte nativa no queda enganchado ni lanza', () async {
    expect(await WindFilterDataSource().setEnabled(enabled: true), isFalse);
  });
}
