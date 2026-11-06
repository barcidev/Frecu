// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Proveedor global singleton del repositorio de descubrimiento.

@ProviderFor(discoveryRepository)
final discoveryRepositoryProvider = DiscoveryRepositoryProvider._();

/// Proveedor global singleton del repositorio de descubrimiento.

final class DiscoveryRepositoryProvider
    extends
        $FunctionalProvider<
          DiscoveryRepository,
          DiscoveryRepository,
          DiscoveryRepository
        >
    with $Provider<DiscoveryRepository> {
  /// Proveedor global singleton del repositorio de descubrimiento.
  DiscoveryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'discoveryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$discoveryRepositoryHash();

  @$internal
  @override
  $ProviderElement<DiscoveryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiscoveryRepository create(Ref ref) {
    return discoveryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiscoveryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiscoveryRepository>(value),
    );
  }
}

String _$discoveryRepositoryHash() =>
    r'c255a36e457177b55d3a743d2aa1f980b0aaec50';

/// Stream reactivo de las frecus cercanas anunciadas en la red local.

@ProviderFor(nearbyRooms)
final nearbyRoomsProvider = NearbyRoomsProvider._();

/// Stream reactivo de las frecus cercanas anunciadas en la red local.

final class NearbyRoomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NearbyRoom>>,
          List<NearbyRoom>,
          Stream<List<NearbyRoom>>
        >
    with $FutureModifier<List<NearbyRoom>>, $StreamProvider<List<NearbyRoom>> {
  /// Stream reactivo de las frecus cercanas anunciadas en la red local.
  NearbyRoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyRoomsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyRoomsHash();

  @$internal
  @override
  $StreamProviderElement<List<NearbyRoom>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NearbyRoom>> create(Ref ref) {
    return nearbyRooms(ref);
  }
}

String _$nearbyRoomsHash() => r'9fdf7f0c1af827ca35d0e691ee3682b811ec9559';
