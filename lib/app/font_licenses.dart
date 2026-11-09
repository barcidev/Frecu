import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Fuentes de Portadora empaquetadas como assets, con la ruta de su licencia
/// OFL (declarada en `pubspec.yaml`).
const Map<String, String> fontLicenseAssets = {
  'Archivo': 'assets/fonts/archivo/OFL.txt',
  'Martian Mono': 'assets/fonts/martianmono/OFL.txt',
  'Doto': 'assets/fonts/doto/OFL.txt',
};

/// Registra la licencia OFL de cada fuente en [LicenseRegistry], para que
/// salgan en la pantalla de licencias junto a las de los paquetes.
///
/// Los textos se leen de [bundle] solo cuando se abre esa pantalla.
void registerFontLicenses([AssetBundle? bundle]) {
  LicenseRegistry.addLicense(() async* {
    final assets = bundle ?? rootBundle;
    for (final MapEntry(key: family, value: path)
        in fontLicenseAssets.entries) {
      yield LicenseEntryWithLineBreaks([family], await assets.loadString(path));
    }
  });
}
