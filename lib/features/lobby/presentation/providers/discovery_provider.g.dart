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

/// Caso de uso que retira el anuncio mDNS de la frecu de este teléfono.

@ProviderFor(stopPublishingRoom)
final stopPublishingRoomProvider = StopPublishingRoomProvider._();

/// Caso de uso que retira el anuncio mDNS de la frecu de este teléfono.

final class StopPublishingRoomProvider
    extends
        $FunctionalProvider<
          StopPublishingRoom,
          StopPublishingRoom,
          StopPublishingRoom
        >
    with $Provider<StopPublishingRoom> {
  /// Caso de uso que retira el anuncio mDNS de la frecu de este teléfono.
  StopPublishingRoomProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stopPublishingRoomProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stopPublishingRoomHash();

  @$internal
  @override
  $ProviderElement<StopPublishingRoom> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StopPublishingRoom create(Ref ref) {
    return stopPublishingRoom(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StopPublishingRoom value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StopPublishingRoom>(value),
    );
  }
}

String _$stopPublishingRoomHash() =>
    r'a7ae0e885921425c6ea1ff2997698ca5f5c42546';

/// Stream reactivo de las frecus cercanas anunciadas en la red local.
///
/// Con una frecu activa la búsqueda queda en pausa (el inicio sigue debajo
/// de la sala) y se conserva la última lista; al terminar la frecu se busca
/// de nuevo desde cero. Si la búsqueda no puede empezar queda en error, sin
/// reintentos automáticos: los programa el inicio.

@ProviderFor(nearbyRooms)
final nearbyRoomsProvider = NearbyRoomsProvider._();

/// Stream reactivo de las frecus cercanas anunciadas en la red local.
///
/// Con una frecu activa la búsqueda queda en pausa (el inicio sigue debajo
/// de la sala) y se conserva la última lista; al terminar la frecu se busca
/// de nuevo desde cero. Si la búsqueda no puede empezar queda en error, sin
/// reintentos automáticos: los programa el inicio.

final class NearbyRoomsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NearbyRoom>>,
          List<NearbyRoom>,
          Stream<List<NearbyRoom>>
        >
    with $FutureModifier<List<NearbyRoom>>, $StreamProvider<List<NearbyRoom>> {
  /// Stream reactivo de las frecus cercanas anunciadas en la red local.
  ///
  /// Con una frecu activa la búsqueda queda en pausa (el inicio sigue debajo
  /// de la sala) y se conserva la última lista; al terminar la frecu se busca
  /// de nuevo desde cero. Si la búsqueda no puede empezar queda en error, sin
  /// reintentos automáticos: los programa el inicio.
  NearbyRoomsProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryFromLobby,
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

String _$nearbyRoomsHash() => r'3f1745aa8a019c4f104b8fc6b33cd8bbba2be99f';
