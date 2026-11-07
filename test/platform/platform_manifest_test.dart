import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

File _findFile(String relativePath) {
  final file = File(relativePath);
  if (file.existsSync()) return file;
  final parentRelative = File('../$relativePath');
  if (parentRelative.existsSync()) return parentRelative;
  return file;
}

void main() {
  group('Platform Manifests & Permissions', () {
    // AC1
    test('AC1: AndroidManifest.xml contains required permissions', () {
      final file = _findFile('android/app/src/main/AndroidManifest.xml');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      const expectedPermissions = [
        'android.permission.RECORD_AUDIO',
        'android.permission.INTERNET',
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.ACCESS_WIFI_STATE',
        'android.permission.CHANGE_WIFI_MULTICAST_STATE',
        'android.permission.BLUETOOTH_CONNECT',
        'android.permission.CAMERA',
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.FOREGROUND_SERVICE_MICROPHONE',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.WAKE_LOCK',
      ];

      for (final permission in expectedPermissions) {
        expect(
          content.contains('android:name="$permission"'),
          isTrue,
          reason: 'Missing permission: $permission',
        );
      }

      expect(
        content.contains(
          'com.pravera.flutter_foreground_task.service.ForegroundService',
        ),
        isTrue,
      );
      expect(
        content.contains('android:foregroundServiceType="microphone"'),
        isTrue,
      );
    });

    // AC2
    test('AC2: Info.plist contains descriptions and audio background', () {
      final file = _findFile('ios/Runner/Info.plist');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      const expectedKeys = [
        '<key>NSMicrophoneUsageDescription</key>',
        '<key>NSLocalNetworkUsageDescription</key>',
        '<key>NSCameraUsageDescription</key>',
        '<key>NSBonjourServices</key>',
        '<key>UIBackgroundModes</key>',
      ];

      for (final key in expectedKeys) {
        expect(content.contains(key), isTrue, reason: 'Missing key: $key');
      }

      expect(content.contains('<string>_frecu._tcp</string>'), isTrue);
      expect(content.contains('<string>audio</string>'), isTrue);
    });

    // AC3
    test('AC3: platform manifest test validates all manifests', () {
      final androidContent = _findFile(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final iosContent = _findFile('ios/Runner/Info.plist').readAsStringSync();

      expect(
        androidContent.contains('android.permission.RECORD_AUDIO'),
        isTrue,
        reason: 'Android manifest must have RECORD_AUDIO',
      );
      expect(
        iosContent.contains('NSMicrophoneUsageDescription'),
        isTrue,
        reason: 'iOS Info.plist must have NSMicrophoneUsageDescription',
      );
    });
  });
}
