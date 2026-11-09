import 'package:package_info_plus/package_info_plus.dart';

/// Fuente de los datos de la app instalada, con `package_info_plus`: la
/// versión del paquete (Android) o del bundle (iOS).
class AppInfoDataSource {
  /// Constructor con la lectura del paquete inyectable para pruebas.
  AppInfoDataSource({Future<PackageInfo> Function()? read})
    : _read = read ?? PackageInfo.fromPlatform;

  final Future<PackageInfo> Function() _read;

  /// Versión de la app (p. ej. `0.1.0`): la de `pubspec.yaml` con la que se
  /// compiló, sin el número de compilación. Lanza si no se puede leer.
  Future<String> version() async => (await _read()).version.trim();
}
