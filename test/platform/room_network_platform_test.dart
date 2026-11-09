// Red de Frecu en la plataforma: Android declara los permisos para crear la red (dispositivos cercanos sin ubicación, y ubicación solo hasta Android 12) y para conectar al invitado y atar la app a la red; MainActivity instala los canales `frecu/hotspot` y `frecu/wifi`, que crean la red con LocalOnlyHotspot (avisando cuando Android la apaga) y conectan con WifiNetworkSpecifier atando el proceso a la red. En iOS, la app tiene la capacidad Hotspot Configuration en las tres configuraciones y conecta con NEHotspotConfiguration sin joinOnce, olvidando al salir solo la red que conectó.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

File _findFile(String relativePath) {
  final file = File(relativePath);
  if (file.existsSync()) return file;
  final parentRelative = File('../$relativePath');
  if (parentRelative.existsSync()) return parentRelative;
  return file;
}

String _read(String path) => _findFile(path).readAsStringSync();

const _kotlin = 'android/app/src/main/kotlin/com/frecu/frecu';

void main() {
  group('Red de Frecu · Android', () {
    test('el manifiesto declara los permisos de la red', () {
      final manifest = _read('android/app/src/main/AndroidManifest.xml')
          .replaceAll(RegExp(r'\s+'), ' ');

      for (final permission in [
        'android.permission.CHANGE_WIFI_STATE',
        'android.permission.CHANGE_NETWORK_STATE',
      ]) {
        expect(manifest, contains('android:name="$permission"'));
      }
      expect(
        manifest,
        contains(
          'android:name="android.permission.NEARBY_WIFI_DEVICES" '
          'android:usesPermissionFlags="neverForLocation"',
        ),
      );
      // Crear la red en Android 12 o anterior exige la ubicación; va sin
      // `maxSdkVersion` porque la ubicación compartida la usa en todas.
      for (final location in [
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
      ]) {
        expect(
          manifest,
          contains('android:name="android.permission.$location" />'),
          reason: location,
        );
        expect(manifest, isNot(contains('maxSdkVersion')), reason: location);
      }
    });

    test('MainActivity instala los dos canales de la red', () {
      final activity = _read('$_kotlin/MainActivity.kt');

      expect(activity, contains('LocalHotspot.install(this, messenger)'));
      expect(activity, contains('FrecuWifi.install(this, messenger)'));
    });

    test(
      'frecu/hotspot crea la red con LocalOnlyHotspot y avisa al apagarse',
      () {
        final hotspot = _read('$_kotlin/LocalHotspot.kt');

        expect(hotspot, contains('"frecu/hotspot"'));
        expect(hotspot, contains('startLocalOnlyHotspot('));
        expect(hotspot, contains('invokeMethod("stopped", null)'));
        for (final code in [
          'unsupported',
          'permission_nearby',
          'permission_location',
          'location_off',
          'incompatible_mode',
        ]) {
          expect(hotspot, contains('"$code"'), reason: code);
        }
        expect(hotspot, contains('Manifest.permission.NEARBY_WIFI_DEVICES'));
        expect(hotspot, contains('Manifest.permission.ACCESS_FINE_LOCATION'));
      },
    );

    test(
      'frecu/wifi conecta con WifiNetworkSpecifier y ata la app a la red',
      () {
        final wifi = _read('$_kotlin/FrecuWifi.kt');

        expect(wifi, contains('"frecu/wifi"'));
        for (final method in ['"route"', '"join"', '"release"']) {
          expect(wifi, contains(method));
        }
        expect(wifi, contains('WifiNetworkSpecifier.Builder()'));
        expect(wifi, contains('requestNetwork('));
        expect(wifi, contains('bindProcessToNetwork('));
        expect(
          wifi,
          contains(
            'removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)',
          ),
        );
        expect(wifi, contains('"declined"'));
      },
    );
  });

  group('Red de Frecu · iOS', () {
    test('la app tiene la capacidad Hotspot Configuration', () {
      final entitlements = _read('ios/Runner/Runner.entitlements')
          .replaceAll(RegExp(r'\s+'), '');
      final project = _read('ios/Runner.xcodeproj/project.pbxproj');

      expect(
        entitlements,
        contains(
          '<key>com.apple.developer.networking.HotspotConfiguration</key>'
          '<true/>',
        ),
      );
      expect(
        'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'.allMatches(
          project,
        ),
        hasLength(3),
      );
    });

    test('frecu/wifi conecta con NEHotspotConfiguration sin joinOnce y olvida '
        'solo la red que conectó', () {
      final delegate = _read('ios/Runner/AppDelegate.swift');

      expect(delegate, contains('import NetworkExtension'));
      expect(delegate, contains('FrecuWifi.install(messenger:'));
      expect(delegate, contains('"frecu/wifi"'));
      expect(delegate, contains('NEHotspotConfiguration('));
      expect(delegate, contains('configuration.joinOnce = false'));
      expect(delegate, contains('case .alreadyAssociated:'));
      expect(delegate, contains('case .userDenied:'));
      expect(delegate, contains('removeConfiguration(forSSID: ssid)'));
    });
  });
}
