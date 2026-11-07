import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';

/// Contrato abstracto para la verificación y solicitud de permisos del sistema.
abstract interface class PermissionRepository {
  /// Consulta el estado actual del permiso [permission].
  Future<Result<AppPermissionStatus>> checkStatus(AppPermission permission);

  /// Solicita el permiso [permission] al usuario.
  Future<Result<AppPermissionStatus>> request(AppPermission permission);

  /// Solicita una lista de permisos [permissions] en lote.
  Future<Result<Map<AppPermission, AppPermissionStatus>>> requestAll(
    List<AppPermission> permissions,
  );

  /// Abre la pantalla de ajustes de la aplicación en el sistema operativo.
  Future<bool> openAppSettings();
}
