import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/permissions/data/datasources/permission_datasource.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('PermissionDataSource', () {
    test('AC1: getStatus delegates to checkStatusFn and returns status', () async {
      final dataSource = PermissionDataSource(
        checkStatusFn: (permission) async {
          expect(permission, Permission.microphone);
          return PermissionStatus.granted;
        },
      );

      final status = await dataSource.getStatus(Permission.microphone);
      expect(status, PermissionStatus.granted);
    });

    test('AC1: request delegates to requestFn and returns status', () async {
      final dataSource = PermissionDataSource(
        requestFn: (permission) async {
          expect(permission, Permission.camera);
          return PermissionStatus.denied;
        },
      );

      final status = await dataSource.request(Permission.camera);
      expect(status, PermissionStatus.denied);
    });

    test('AC4: openSettings delegates to openAppSettingsFn and returns result', () async {
      final dataSource = PermissionDataSource(
        openAppSettingsFn: () async => true,
      );

      final result = await dataSource.openSettings();
      expect(result, isTrue);
    });
  });
}
