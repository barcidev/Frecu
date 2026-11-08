// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Proveedor del datasource de interfaces de red del sistema.

@ProviderFor(networkInterfaceDataSource)
final networkInterfaceDataSourceProvider =
    NetworkInterfaceDataSourceProvider._();

/// Proveedor del datasource de interfaces de red del sistema.

final class NetworkInterfaceDataSourceProvider
    extends
        $FunctionalProvider<
          NetworkInterfaceDataSource,
          NetworkInterfaceDataSource,
          NetworkInterfaceDataSource
        >
    with $Provider<NetworkInterfaceDataSource> {
  /// Proveedor del datasource de interfaces de red del sistema.
  NetworkInterfaceDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkInterfaceDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkInterfaceDataSourceHash();

  @$internal
  @override
  $ProviderElement<NetworkInterfaceDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NetworkInterfaceDataSource create(Ref ref) {
    return networkInterfaceDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkInterfaceDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkInterfaceDataSource>(value),
    );
  }
}

String _$networkInterfaceDataSourceHash() =>
    r'fed3c5be338d74d8c6428b649942b9a139a1edef';

/// Proveedor del repositorio de verificación e inspección de interfaces de red.

@ProviderFor(networkRepository)
final networkRepositoryProvider = NetworkRepositoryProvider._();

/// Proveedor del repositorio de verificación e inspección de interfaces de red.

final class NetworkRepositoryProvider
    extends
        $FunctionalProvider<
          NetworkRepository,
          NetworkRepository,
          NetworkRepository
        >
    with $Provider<NetworkRepository> {
  /// Proveedor del repositorio de verificación e inspección de interfaces de red.
  NetworkRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkRepositoryHash();

  @$internal
  @override
  $ProviderElement<NetworkRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NetworkRepository create(Ref ref) {
    return networkRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkRepository>(value),
    );
  }
}

String _$networkRepositoryHash() => r'44a554179a201ea47001f5006b98e65c9cf46e54';

/// Proveedor del stream continuo del estado de conectividad e interfaces de red.

@ProviderFor(networkStateStream)
final networkStateStreamProvider = NetworkStateStreamProvider._();

/// Proveedor del stream continuo del estado de conectividad e interfaces de red.

final class NetworkStateStreamProvider
    extends
        $FunctionalProvider<
          Raw<Stream<NetworkState>>,
          Raw<Stream<NetworkState>>,
          Raw<Stream<NetworkState>>
        >
    with $Provider<Raw<Stream<NetworkState>>> {
  /// Proveedor del stream continuo del estado de conectividad e interfaces de red.
  NetworkStateStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkStateStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkStateStreamHash();

  @$internal
  @override
  $ProviderElement<Raw<Stream<NetworkState>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<Stream<NetworkState>> create(Ref ref) {
    return networkStateStream(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<Stream<NetworkState>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<Stream<NetworkState>>>(value),
    );
  }
}

String _$networkStateStreamHash() =>
    r'882a0337cf8b33dcdb95431ed2f6e7386f3edf7e';

/// Proveedor de los Ajustes del sistema (Wi-Fi, punto de acceso y los de la
/// app).

@ProviderFor(systemSettingsRepository)
final systemSettingsRepositoryProvider = SystemSettingsRepositoryProvider._();

/// Proveedor de los Ajustes del sistema (Wi-Fi, punto de acceso y los de la
/// app).

final class SystemSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SystemSettingsRepository,
          SystemSettingsRepository,
          SystemSettingsRepository
        >
    with $Provider<SystemSettingsRepository> {
  /// Proveedor de los Ajustes del sistema (Wi-Fi, punto de acceso y los de la
  /// app).
  SystemSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemSettingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SystemSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SystemSettingsRepository create(Ref ref) {
    return systemSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SystemSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemSettingsRepository>(value),
    );
  }
}

String _$systemSettingsRepositoryHash() =>
    r'46be98e6f825445e1ee3a7c48a5ec79ebd7e10e3';
