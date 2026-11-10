// Invitar por NFC y enlaces frecu:// (corte 9 de la épica de hardware V1): la configuración de Android e iOS.
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

void main() {
  group('Android', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');

    test('NFC es opcional y los enlaces frecu://join los lee app_links', () {
      expect(manifest, contains('android:name="android.permission.NFC"'));
      expect(
        manifest,
        matches(RegExp(r'android\.hardware\.nfc"\s+android:required="false"')),
      );
      expect(
        manifest,
        matches(
          RegExp(r'android\.hardware\.nfc\.hce"\s+android:required="false"'),
        ),
      );
      expect(
        manifest,
        matches(
          RegExp(r'flutter_deeplinking_enabled"\s+android:value="false"'),
        ),
      );
      for (final action in [
        'android.intent.action.VIEW',
        'android.nfc.action.NDEF_DISCOVERED',
      ]) {
        expect(manifest, contains('<action android:name="$action" />'));
      }
      expect(
        RegExp('android:scheme="frecu" android:host="join"')
            .allMatches(manifest),
        hasLength(2),
      );
    });

    test('el teléfono hace de etiqueta NDEF tipo 4 con su servicio', () {
      expect(manifest, contains('android:name=".FrecuNfcHostService"'));
      expect(
        manifest,
        contains('android:permission="android.permission.BIND_NFC_SERVICE"'),
      );
      expect(
        manifest,
        contains('android.nfc.cardemulation.action.HOST_APDU_SERVICE'),
      );
      final service = _read(
        'android/app/src/main/res/xml/frecu_apdu_service.xml',
      );
      expect(service, contains('<aid-filter android:name="D2760000850101" />'));
      final activity = _read(
        'android/app/src/main/kotlin/com/frecu/frecu/MainActivity.kt',
      );
      expect(
        activity,
        contains('FrecuNfcHostService.install(this, messenger)'),
      );
      final host = _read(
        'android/app/src/main/kotlin/com/frecu/frecu/FrecuNfcHost.kt',
      );
      expect(host, contains('"frecu/nfc_host"'));
    });
  });

  group('iOS', () {
    final plist = _read('ios/Runner/Info.plist');

    test('el esquema frecu, el texto de NFC y la aplicación NDEF', () {
      expect(plist, contains('<string>frecu</string>'));
      expect(plist, contains('<key>FlutterDeepLinkingEnabled</key>'));
      expect(plist, contains('<key>NFCReaderUsageDescription</key>'));
      expect(
        plist,
        contains(
          '<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>',
        ),
      );
      expect(plist, contains('<string>D2760000850101</string>'));
      for (final locale in ['es', 'en']) {
        expect(
          _read('ios/Runner/$locale.lproj/InfoPlist.strings'),
          contains('"NFCReaderUsageDescription" = "Frecu '),
          reason: locale,
        );
      }
    });

    test('la capacidad de leer NFC (NDEF y etiquetas)', () {
      final entitlements = _read('ios/Runner/Runner.entitlements');
      expect(
        entitlements,
        contains('com.apple.developer.nfc.readersession.formats'),
      );
      expect(entitlements, contains('<string>NDEF</string>'));
      expect(entitlements, contains('<string>TAG</string>'));
    });
  });
}
