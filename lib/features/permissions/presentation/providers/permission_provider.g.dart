// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Proveedor del datasource de permisos del sistema.

@ProviderFor(permissionDataSource)
final permissionDataSourceProvider = PermissionDataSourceProvider._();

/// Proveedor del datasource de permisos del sistema.

final class PermissionDataSourceProvider
    extends
        $FunctionalProvider<
          PermissionDataSource,
          PermissionDataSource,
          PermissionDataSource
        >
    with $Provider<PermissionDataSource> {
  /// Proveedor del datasource de permisos del sistema.
  PermissionDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionDataSourceHash();

  @$internal
  @override
  $ProviderElement<PermissionDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PermissionDataSource create(Ref ref) {
    return permissionDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PermissionDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PermissionDataSource>(value),
    );
  }
}

String _$permissionDataSourceHash() =>
    r'6090aef32e7e606e64b51327ef2f090459633454';

/// Proveedor del repositorio de verificación y solicitud de permisos.

@ProviderFor(permissionRepository)
final permissionRepositoryProvider = PermissionRepositoryProvider._();

/// Proveedor del repositorio de verificación y solicitud de permisos.

final class PermissionRepositoryProvider
    extends
        $FunctionalProvider<
          PermissionRepository,
          PermissionRepository,
          PermissionRepository
        >
    with $Provider<PermissionRepository> {
  /// Proveedor del repositorio de verificación y solicitud de permisos.
  PermissionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionRepositoryHash();

  @$internal
  @override
  $ProviderElement<PermissionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PermissionRepository create(Ref ref) {
    return permissionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PermissionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PermissionRepository>(value),
    );
  }
}

String _$permissionRepositoryHash() =>
    r'b4210e0c7b8ec42d3e922b1019d4c7728bec6dad';
