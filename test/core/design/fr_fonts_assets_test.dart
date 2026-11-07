// AC1: CUANDO la app carga su bundle de assets sin red ENTONCES `FontManifest.json` declara las familias `Archivo`, `Martian Mono` y `Doto` con los mismos nombres que `FrFonts`, y el archivo de cada una carga desde los assets locales.
// AC2: CUANDO se lee cada fuente empaquetada ENTONCES es un TrueType variable válido cuyos ejes (`wght` y `wdth` en Archivo y Martian Mono; `wght` y `ROND` en Doto) cubren todos los valores de `fontVariations` de los estilos de `FrType.standard`.
// AC3: CUANDO se distribuye la app ENTONCES el `OFL.txt` de cada familia viaja en los assets y `pubspec.yaml` no depende de `google_fonts`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';

const families = [FrFonts.ui, FrFonts.mono, FrFonts.dot];

const expectedAxes = {
  FrFonts.ui: {'wght', 'wdth'},
  FrFonts.mono: {'wght', 'wdth'},
  FrFonts.dot: {'wght', 'ROND'},
};

/// Familia → rutas de sus archivos, leídas del `FontManifest.json` del bundle.
Future<Map<String, List<String>>> loadFontManifest() async {
  final manifest = await rootBundle.loadString('FontManifest.json');
  final entries = (jsonDecode(manifest) as List<dynamic>)
      .cast<Map<String, dynamic>>();
  return {
    for (final entry in entries)
      entry['family'] as String: [
        for (final font in (entry['fonts'] as List<dynamic>))
          (font as Map<String, dynamic>)['asset'] as String,
      ],
  };
}

/// Ruta del único archivo de [family] en el manifiesto.
String fontAsset(Map<String, List<String>> manifest, String family) {
  expect(
    manifest,
    contains(family),
    reason: '$family no está en FontManifest.json',
  );
  expect(manifest[family], hasLength(1), reason: family);
  return manifest[family]!.single;
}

String tagAt(ByteData data, int offset) => String.fromCharCodes([
  for (var i = 0; i < 4; i++) data.getUint8(offset + i),
]);

int checksum(ByteData data, int offset, int length, {required bool isHead}) {
  var sum = 0;
  for (var i = 0; i < length; i += 4) {
    var word = 0;
    for (var j = 0; j < 4; j++) {
      final at = i + j;
      final adjusted = isHead && at >= 8 && at < 12;
      final byte = at < length && !adjusted ? data.getUint8(offset + at) : 0;
      word = (word << 8) | byte;
    }
    sum = (sum + word) & 0xFFFFFFFF;
  }
  return sum;
}

/// Lee la cabecera sfnt, comprueba la suma de cada tabla y devuelve los ejes
/// de `fvar` con su rango (mínimo, máximo).
Map<String, (double, double)> readVariableAxes(ByteData data, String asset) {
  expect(data.getUint32(0), 0x00010000, reason: '$asset no es TrueType');
  final tables = <String, int>{};
  for (var i = 0; i < data.getUint16(4); i++) {
    final record = 12 + 16 * i;
    final tag = tagAt(data, record);
    final offset = data.getUint32(record + 8);
    final length = data.getUint32(record + 12);
    expect(offset + length, lessThanOrEqualTo(data.lengthInBytes));
    final sum = checksum(data, offset, length, isHead: tag == 'head');
    expect(sum, data.getUint32(record + 4), reason: '$asset: tabla $tag');
    tables[tag] = offset;
  }
  final fvar = tables['fvar'];
  expect(fvar, isNotNull, reason: '$asset no es una fuente variable');
  final axesOffset = data.getUint16(fvar! + 4);
  final axisSize = data.getUint16(fvar + 10);
  return {
    for (var i = 0; i < data.getUint16(fvar + 8); i++)
      tagAt(data, fvar + axesOffset + i * axisSize): (
        data.getInt32(fvar + axesOffset + i * axisSize + 4) / 65536,
        data.getInt32(fvar + axesOffset + i * axisSize + 12) / 65536,
      ),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final styles = [
    // dart format off
    FrType.standard.display, FrType.standard.titleL, FrType.standard.title,
    FrType.standard.bodyL, FrType.standard.body, FrType.standard.bodyS,
    FrType.standard.label, FrType.standard.labelS, FrType.standard.data,
    FrType.standard.digits, FrType.standard.button,
    // dart format on
  ];

  test('AC1: FontManifest.json declara Archivo, Martian Mono y Doto y sus archivos cargan desde los assets locales', () async {
    final manifest = await loadFontManifest();
    expect(manifest.keys, containsAll(families));
    expect({
      for (final style in styles) style.fontFamily,
    }, everyElement(isIn(families)));
    for (final family in families) {
      final asset = fontAsset(manifest, family);
      expect(asset, startsWith('assets/fonts/'), reason: family);
      expect(asset, endsWith('.ttf'), reason: family);
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });

  test('AC2: cada fuente es un TrueType variable válido cuyos ejes cubren las fontVariations de FrType.standard', () async {
    final manifest = await loadFontManifest();
    final axesByFamily = <String, Map<String, (double, double)>>{};
    for (final family in families) {
      final asset = fontAsset(manifest, family);
      axesByFamily[family] = readVariableAxes(
        await rootBundle.load(asset),
        asset,
      );
      expect(
        axesByFamily[family]!.keys,
        containsAll(expectedAxes[family]!),
        reason: family,
      );
    }
    for (final style in styles) {
      final axes = axesByFamily[style.fontFamily]!;
      for (final variation in style.fontVariations ?? <FontVariation>[]) {
        final reason = '${style.fontFamily} ${variation.axis}';
        expect(axes.keys, contains(variation.axis), reason: reason);
        final (min, max) = axes[variation.axis]!;
        expect(variation.value, inInclusiveRange(min, max), reason: reason);
      }
    }
  });

  test('AC3: el OFL.txt de cada familia viaja en los assets y pubspec.yaml no depende de google_fonts', () async {
    final manifest = await loadFontManifest();
    for (final family in families) {
      final asset = fontAsset(manifest, family);
      final folder = asset.substring(0, asset.lastIndexOf('/'));
      final license = await rootBundle.loadString('$folder/OFL.txt');
      expect(
        license,
        contains('SIL Open Font License, Version 1.1'),
        reason: family,
      );
      expect(license, contains(family), reason: family);
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('google_fonts')));
  });
}
