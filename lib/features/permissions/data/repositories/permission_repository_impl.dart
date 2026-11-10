import 'package:flutter/foundation.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/permissions/data/datasources/permission_datasource.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:frecu/features/permissions/domain/repositories/permission_repository.dart';
import 'package:permission_handler/permission_handler.dart';

/// Implementación del contrato [PermissionRepository] utilizando [PermissionDataSource].
class PermissionRepositoryImpl implements PermissionRepository {
  /// Constructor con inyección de [dataSource].
  const PermissionRepositoryImpl({required PermissionDataSource dataSource})
    : _permissionDataSource = dataSource;

  final PermissionDataSource _permissionDataSource;

  @override
  Future<Result<AppPermissionStatus>> checkStatus(
    AppPermission permission,
  ) async {
    try {
      final nativePermission = _mapPermission(permission);
      final status = await _permissionDataSource.getStatus(nativePermission);
      return Result.success(_mapStatus(status));
    } on Object catch (e) {
      return Result.failure(
        Failure.unexpected(message: e.toString(), error: e),
      );
    }
  }

  @override
  Future<Result<AppPermissionStatus>> request(AppPermission permission) async {
    try {
      final nativePermission = _mapPermission(permission);
      final status = await _permissionDataSource.request(nativePermission);
      return Result.success(_mapStatus(status));
    } on Object catch (e) {
      return Result.failure(
        Failure.unexpected(message: e.toString(), error: e),
      );
    }
  }

  @override
  Future<Result<Map<AppPermission, AppPermissionStatus>>> requestAll(
    List<AppPermission> permissions,
  ) async {
    try {
      final results = <AppPermission, AppPermissionStatus>{};
      for (final permission in permissions) {
        final nativePermission = _mapPermission(permission);
        final status = await _permissionDataSource.request(nativePermission);
        results[permission] = _mapStatus(status);
      }
      return Result.success(results);
    } on Object catch (e) {
      return Result.failure(
        Failure.unexpected(message: e.toString(), error: e),
      );
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await _permissionDataSource.openSettings();
    } on Object catch (_) {
      return false;
    }
  }

  Permission _mapPermission(AppPermission permission) {
    return switch (permission) {
      AppPermission.microphone => Permission.microphone,
      AppPermission.camera => Permission.camera,
      AppPermission.notification => Permission.notification,
      // En iOS no hay «dispositivos cercanos»: es el permiso de Bluetooth
      // (buscar frecus por Bluetooth y audífonos).
      AppPermission.bluetoothConnect =>
        defaultTargetPlatform == TargetPlatform.iOS
            ? Permission.bluetooth
            : Permission.bluetoothConnect,
      AppPermission.location => Permission.locationWhenInUse,
    };
  }

  AppPermissionStatus _mapStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted => AppPermissionStatus.granted,
      PermissionStatus.denied => AppPermissionStatus.denied,
      PermissionStatus.permanentlyDenied =>
        AppPermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => AppPermissionStatus.restricted,
      PermissionStatus.limited => AppPermissionStatus.limited,
      PermissionStatus.provisional => AppPermissionStatus.provisional,
    };
  }
}
