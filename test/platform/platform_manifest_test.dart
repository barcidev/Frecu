import 'dart:io';
import 'dart:typed_data';

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
        'android.permission.BLUETOOTH_ADVERTISE',
        'android.permission.CAMERA',
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.FOREGROUND_SERVICE_MICROPHONE',
        'android.permission.FOREGROUND_SERVICE_LOCATION',
        'android.permission.ACCESS_FINE_LOCATION',
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
      // Buscar frecus por Bluetooth no usa la ubicación.
      expect(
        content,
        matches(
          RegExp(
            r'android\.permission\.BLUETOOTH_SCAN"\s+'
            'android:usesPermissionFlags="neverForLocation"',
          ),
        ),
      );

      expect(
        content.contains(
          'com.pravera.flutter_foreground_task.service.ForegroundService',
        ),
        isTrue,
      );
      expect(
        // Micrófono siempre; ubicación solo mientras se comparte (la app
        // elige los tipos al arrancar el servicio).
        content.contains('android:foregroundServiceType="microphone|location"'),
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

    // F3: sin su macro, permission_handler_apple compila el permiso como
    // desconocido y lo da por negado para siempre sin mostrar el diálogo.
    test('F3: el Podfile activa en permission_handler los permisos que pide la '
        'app, cada uno con su texto en Info.plist', () {
      final podfile = _findFile('ios/Podfile').readAsStringSync();
      final plist = _findFile('ios/Runner/Info.plist').readAsStringSync();

      expect(podfile, contains('post_install do |installer|'));
      expect(podfile, contains("'GCC_PREPROCESSOR_DEFINITIONS'"));
      expect(
        podfile,
        contains("'permission_handler_apple' => PERMISSION_HANDLER_MACROS"),
      );
      // geolocator sin el permiso «siempre», que App Store pide justificar.
      expect(podfile, contains("'geolocator_apple' => GEOLOCATOR_MACROS"));
      expect(podfile, contains("'BYPASS_PERMISSION_LOCATION_ALWAYS=1'"));
      const required = {
        'PERMISSION_MICROPHONE': 'NSMicrophoneUsageDescription',
        'PERMISSION_NOTIFICATIONS': null,
        'PERMISSION_CAMERA': 'NSCameraUsageDescription',
        'PERMISSION_LOCATION_WHENINUSE': 'NSLocationWhenInUseUsageDescription',
      };
      for (final MapEntry(key: macro, value: usage) in required.entries) {
        expect(
          podfile,
          contains("'$macro=1'"),
          reason: 'Falta activar $macro en el Podfile',
        );
        if (usage != null) {
          expect(
            plist,
            contains('<key>$usage</key>'),
            reason: '$macro necesita $usage en Info.plist',
          );
        }
      }
      // permission_handler no pide Bluetooth en iOS: lo pide CoreBluetooth
      // al buscar o anunciar frecus (invitar por Bluetooth), con su texto.
      expect(podfile, isNot(contains('PERMISSION_BLUETOOTH=1')));
      expect(plist, contains('<key>NSBluetoothAlwaysUsageDescription</key>'));
    });

    // P69: el splash nativo va en la noche de Portadora, sin destello blanco.
    test('P69: el splash nativo de iOS y Android usa el vacío de noche', () {
      const night =
          'red="0.023529411764705882" '
          'green="0.027450980392156862" blue="0.031372549019607843"';
      for (final storyboard in [
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
        'ios/Runner/Base.lproj/Main.storyboard',
      ]) {
        final content = _findFile(storyboard).readAsStringSync();
        expect(content, contains(night), reason: storyboard);
        expect(content, isNot(contains('white="1"')), reason: storyboard);
        expect(
          content,
          isNot(contains('red="1" green="1" blue="1"')),
          reason: storyboard,
        );
      }

      const res = 'android/app/src/main/res';
      final colors = _findFile('$res/values/colors.xml').readAsStringSync();
      expect(colors, contains('<color name="portadora_night">#FF060708'));
      for (final background in [
        '$res/drawable/launch_background.xml',
        '$res/drawable-v21/launch_background.xml',
      ]) {
        final content = _findFile(background).readAsStringSync();
        expect(content, contains('@color/portadora_night'), reason: background);
        expect(content, isNot(contains('white')), reason: background);
        expect(content, isNot(contains('colorBackground')), reason: background);
      }
      final styles = _findFile('$res/values/styles.xml').readAsStringSync();
      expect(styles, isNot(contains('Theme.Light')));
      expect(styles, contains('@color/portadora_night'));
      final android12 = _findFile('$res/values-v31/styles.xml')
          .readAsStringSync();
      const splashBackground =
          '<item name="android:windowSplashScreenBackground">@color/portadora_night</item>';
      expect(android12, contains(splashBackground));
      expect(android12, contains('android:windowSplashScreenAnimatedIcon'));
      // Sin variante de noche: la ventana va en noche en los dos modos.
      expect(_findFile('$res/values-night/styles.xml').existsSync(), isFalse);
    });

    // P69: el ícono es la marca de Frecu.
    test('P69: los íconos de la app son la marca de Frecu', () {
      const res = 'android/app/src/main/res';
      final adaptive = _findFile('$res/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync();
      expect(adaptive, contains('@drawable/ic_launcher_foreground'));
      expect(adaptive, contains('@color/ic_launcher_background'));
      final foreground = _findFile('$res/drawable/ic_launcher_foreground.xml')
          .readAsStringSync();
      expect(foreground, contains('@color/portadora_signal'));

      // PNG: ancho, alto y tipo de color de la cabecera IHDR.
      (int, int, int) header(String path) {
        final bytes = _findFile(path).readAsBytesSync();
        final data = ByteData.sublistView(bytes);
        return (data.getUint32(16), data.getUint32(20), bytes[25]);
      }

      const iconSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final marketing = header('$iconSet/Icon-App-1024x1024@1x.png');
      // La tienda rechaza el ícono grande con canal alfa (tipo 2: RGB).
      expect(marketing, (1024, 1024, 2));
      expect(header('$iconSet/Icon-App-60x60@3x.png').$1, 180);
      for (final (density, size) in [
        ('mdpi', 48),
        ('hdpi', 72),
        ('xhdpi', 96),
        ('xxhdpi', 144),
        ('xxxhdpi', 192),
      ]) {
        final (width, height, _) = header(
          '$res/mipmap-$density/ic_launcher.png',
        );
        expect((width, height), (size, size), reason: density);
      }
    });

    // F16: los textos de los permisos del sistema, en español e inglés.
    test('F16: Info.plist tiene sus textos en español e inglés', () {
      const keys = [
        'NSMicrophoneUsageDescription',
        'NSLocalNetworkUsageDescription',
        'NSCameraUsageDescription',
        'NSBluetoothAlwaysUsageDescription',
      ];
      for (final locale in ['es', 'en']) {
        final strings = _findFile('ios/Runner/$locale.lproj/InfoPlist.strings')
            .readAsStringSync();
        for (final key in keys) {
          expect(strings, contains('"$key" = "Frecu '), reason: '$locale $key');
        }
      }
      final project = _findFile('ios/Runner.xcodeproj/project.pbxproj')
          .readAsStringSync();
      expect(project, contains('path = es.lproj/InfoPlist.strings;'));
      expect(project, contains('path = en.lproj/InfoPlist.strings;'));
      expect(project, contains('/* InfoPlist.strings in Resources */,'));
      expect(project, matches(RegExp(r'knownRegions = \([^)]*\bes,')));
      final plist = _findFile('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('<key>CFBundleLocalizations</key>'));
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
