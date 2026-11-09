// Zona Wi-Fi: CUANDO el teléfono comparte su zona Wi-Fi ENTONCES WebRTC también junta candidatos en esa interfaz: MainActivity instala, antes de la primera conexión, un detector de redes que la reporta con la red sin especificar (0) sin quitar las redes de Android, compilado contra la misma WebRTC que trae flutter_webrtc.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

File _findFile(String relativePath) {
  final file = File(relativePath);
  if (file.existsSync()) return file;
  final parentRelative = File('../$relativePath');
  if (parentRelative.existsSync()) return parentRelative;
  return file;
}

const _kotlin = 'android/app/src/main/kotlin/com/frecu/frecu';

/// Versión de `io.github.webrtc-sdk:android` declarada en [gradle].
String? _webrtcVersion(String gradle) =>
    RegExp(r'io\.github\.webrtc-sdk:android:([\d.]+)')
        .firstMatch(gradle)
        ?.group(1);

/// `android/build.gradle` del flutter_webrtc que resolvió `pub get`.
File _flutterWebrtcGradle() {
  final config = _findFile('.dart_tool/package_config.json');
  final packages =
      (jsonDecode(config.readAsStringSync())
              as Map<String, dynamic>)['packages']
          as List<dynamic>;
  final webrtc = packages.cast<Map<String, dynamic>>().firstWhere(
    (package) => package['name'] == 'flutter_webrtc',
  );
  final rootUri = webrtc['rootUri'] as String;
  final root = config.absolute.uri.resolve(
    rootUri.endsWith('/') ? rootUri : '$rootUri/',
  );
  return File.fromUri(root.resolve('android/build.gradle'));
}

void main() {
  group('Zona Wi-Fi · la voz sale por el punto de acceso', () {
    test('Zona Wi-Fi: MainActivity instala el detector antes de configurar '
        'el motor (y con él, la primera conexión)', () {
      final activity = _findFile('$_kotlin/MainActivity.kt').readAsStringSync();
      final install = activity.indexOf('HotspotNetworkDetector.install()');

      expect(install, greaterThan(-1));
      expect(
        install,
        lessThan(activity.indexOf('super.configureFlutterEngine')),
      );
    });

    test('Zona Wi-Fi: el detector suma la interfaz de la zona Wi-Fi con la '
        'red sin especificar y conserva el detector de WebRTC', () {
      final detector = _findFile('$_kotlin/HotspotNetworkDetector.kt')
          .readAsStringSync();

      expect(detector, contains('setNetworkChangeDetectorFactory'));
      expect(detector, contains('const val UNSPECIFIED_HANDLE = 0L'));
      expect(
        detector,
        contains('NetworkMonitorAutoDetect(ForwardingObserver(), context)'),
      );
      // Si algo falla, WebRTC sigue con su detector de siempre.
      expect(detector, contains('NetworkMonitorAutoDetect(observer, context)'));
      for (final name in ['swlan', 'softap', 'ap_br_wlan', 'wlan', 'rndis']) {
        expect(detector, contains(name), reason: name);
      }
    });

    test('Zona Wi-Fi: se compila contra la misma WebRTC que trae '
        'flutter_webrtc, sin empaquetar otra copia', () {
      final app = _findFile('android/app/build.gradle.kts').readAsStringSync();
      final plugin = _flutterWebrtcGradle().readAsStringSync();

      expect(app, contains('compileOnly("io.github.webrtc-sdk:android:'));
      expect(app, isNot(contains('implementation("io.github.webrtc-sdk')));
      expect(_webrtcVersion(plugin), isNotNull);
      expect(_webrtcVersion(app), _webrtcVersion(plugin));
    });
  });
}
