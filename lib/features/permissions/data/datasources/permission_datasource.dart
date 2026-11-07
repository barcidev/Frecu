import 'package:permission_handler/permission_handler.dart';

/// Fuente de datos para interactuar con los permisos nativos del sistema.
class PermissionDataSource {
  /// Constructor con funciones inyectables para pruebas unitarias.
  PermissionDataSource({
    Future<PermissionStatus> Function(Permission permission)? checkStatusFn,
    Future<PermissionStatus> Function(Permission permission)? requestFn,
    Future<bool> Function()? openAppSettingsFn,
  }) : _checkStatusFn = checkStatusFn ?? _defaultCheckStatus,
       _requestFn = requestFn ?? _defaultRequest,
       _openAppSettingsFn = openAppSettingsFn ?? openAppSettings;

  final Future<PermissionStatus> Function(Permission permission) _checkStatusFn;
  final Future<PermissionStatus> Function(Permission permission) _requestFn;
  final Future<bool> Function() _openAppSettingsFn;

  static Future<PermissionStatus> _defaultCheckStatus(Permission permission) =>
      permission.status;

  static Future<PermissionStatus> _defaultRequest(Permission permission) =>
      permission.request();

  /// Obtiene el estado actual del permiso [permission].
  Future<PermissionStatus> getStatus(Permission permission) =>
      _checkStatusFn(permission);

  /// Solicita el permiso [permission] al sistema.
  Future<PermissionStatus> request(Permission permission) =>
      _requestFn(permission);

  /// Abre la pantalla de ajustes de la aplicación en el sistema.
  Future<bool> openSettings() => _openAppSettingsFn();
}
