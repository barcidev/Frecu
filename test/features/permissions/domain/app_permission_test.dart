import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';

void main() {
  group('AppPermission Domain Entities', () {
    test('AC1: AppPermission contains all required permissions', () {
      expect(
        AppPermission.values,
        containsAll([
          AppPermission.microphone,
          AppPermission.camera,
          AppPermission.notification,
          AppPermission.bluetoothConnect,
        ]),
      );
    });

    test('AC1: AppPermissionStatus contains all permission statuses', () {
      expect(
        AppPermissionStatus.values,
        containsAll([
          AppPermissionStatus.granted,
          AppPermissionStatus.denied,
          AppPermissionStatus.permanentlyDenied,
          AppPermissionStatus.restricted,
          AppPermissionStatus.limited,
          AppPermissionStatus.provisional,
        ]),
      );
    });
  });
}
