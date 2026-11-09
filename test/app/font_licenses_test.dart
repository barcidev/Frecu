// CUANDO arranca la app ENTONCES la licencia OFL de cada fuente empaquetada
// (Archivo, Martian Mono y Doto) queda registrada en LicenseRegistry con el
// texto de su asset.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registra la licencia OFL de las tres fuentes', () async {
    registerFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    for (final MapEntry(key: family, value: path)
        in fontLicenseAssets.entries) {
      final entry = entries.singleWhere(
        (entry) => entry.packages.contains(family),
      );
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('SIL OPEN FONT LICENSE'));
      expect(
        text.replaceAll(RegExp(r'\s+'), ' '),
        (await rootBundle.loadString(path))
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
        reason: family,
      );
    }
  });
}
