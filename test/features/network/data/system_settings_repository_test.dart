// P83/P86/P92/P93/P97: la app abre los ajustes de Wi-Fi, del punto de acceso y los suyos (para la cámara); si el sistema no los abre, el repositorio devuelve un fallo en vez de lanzar.
import 'package:app_settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/network/data/datasources/system_settings_datasource.dart';
import 'package:frecu/features/network/data/repositories/system_settings_repository_impl.dart';

void main() {
  late List<Object> opened;
  late bool appOpens;

  SystemSettingsRepositoryImpl repository({bool fails = false}) =>
      SystemSettingsRepositoryImpl(
        dataSource: SystemSettingsDataSource(
          openSettings: (type) async {
            if (fails) throw Exception('no settings');
            opened.add(type);
          },
          openAppSettings: () async {
            opened.add('app');
            return appOpens;
          },
        ),
      );

  setUp(() {
    opened = [];
    appOpens = true;
  });

  test('abre los ajustes de Wi-Fi y los del punto de acceso', () async {
    final settings = repository();

    expect((await settings.openWifiSettings()).isSuccess, isTrue);
    expect((await settings.openHotspotSettings()).isSuccess, isTrue);

    expect(opened, [AppSettingsType.wifi, AppSettingsType.hotspot]);
  });

  test('abre los ajustes de la app', () async {
    final result = await repository().openAppSettings();

    expect(result.isSuccess, isTrue);
    expect(opened, ['app']);
  });

  test(
    'si el sistema no abre los ajustes devuelve un fallo sin lanzar',
    () async {
      appOpens = false;
      expect((await repository().openAppSettings()).isFailure, isTrue);

      final failing = repository(fails: true);
      expect((await failing.openWifiSettings()).isFailure, isTrue);
      expect((await failing.openHotspotSettings()).isFailure, isTrue);
    },
  );
}
