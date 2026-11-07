import 'package:frecu/features/permissions/data/datasources/permission_datasource.dart';
import 'package:frecu/features/permissions/data/repositories/permission_repository_impl.dart';
import 'package:frecu/features/permissions/domain/repositories/permission_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_provider.g.dart';

/// Proveedor del datasource de permisos del sistema.
@Riverpod(keepAlive: true)
PermissionDataSource permissionDataSource(Ref ref) {
  return PermissionDataSource();
}

/// Proveedor del repositorio de verificación y solicitud de permisos.
@Riverpod(keepAlive: true)
PermissionRepository permissionRepository(Ref ref) {
  final dataSource = ref.watch(permissionDataSourceProvider);
  return PermissionRepositoryImpl(dataSource: dataSource);
}
