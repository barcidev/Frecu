import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

/// Datasource que abre pantallas de Ajustes con `app_settings` (Wi-Fi y
/// punto de acceso en Android) y `permission_handler` (los de la app).
class SystemSettingsDataSource {
  /// Crea el datasource; las pruebas inyectan las funciones de los plugins.
  SystemSettingsDataSource({
    Future<void> Function(AppSettingsType type)? openSettings,
    Future<bool> Function()? openAppSettings,
  }) : _openSettings = openSettings ?? _openPanel,
       _openAppSettings = openAppSettings ?? permissions.openAppSettings;

  final Future<void> Function(AppSettingsType type) _openSettings;
  final Future<bool> Function() _openAppSettings;

  static Future<void> _openPanel(AppSettingsType type) =>
      AppSettings.openAppSettings(type: type);

  /// Ajustes de Wi-Fi; en iOS, los de la app.
  Future<void> openWifi() => _openSettings(AppSettingsType.wifi);

  /// Ajustes del punto de acceso; en iOS, los de la app.
  Future<void> openHotspot() => _openSettings(AppSettingsType.hotspot);

  /// Ajustes de la app; falso si el sistema no los abrió.
  Future<bool> openApp() => _openAppSettings();

  /// Ajustes de ubicación; en iOS, los de la app.
  Future<void> openLocation() => _openSettings(AppSettingsType.location);
}
