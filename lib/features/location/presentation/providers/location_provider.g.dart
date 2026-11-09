// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repositorio de la ubicación compartida sobre la señalización.

@ProviderFor(locationRepository)
final locationRepositoryProvider = LocationRepositoryProvider._();

/// Repositorio de la ubicación compartida sobre la señalización.

final class LocationRepositoryProvider
    extends
        $FunctionalProvider<
          LocationRepository,
          LocationRepository,
          LocationRepository
        >
    with $Provider<LocationRepository> {
  /// Repositorio de la ubicación compartida sobre la señalización.
  LocationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationRepository create(Ref ref) {
    return locationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationRepository>(value),
    );
  }
}

String _$locationRepositoryHash() =>
    r'0e1e6c1543bc8c01480c2c89b04622bce8bd7bbc';

/// Comparte la ubicación propia (si se activa), recibe la de los demás y
/// decide quién se quedó atrás. Al terminar la frecu deja de compartir.

@ProviderFor(LocationSharing)
final locationSharingProvider = LocationSharingProvider._();

/// Comparte la ubicación propia (si se activa), recibe la de los demás y
/// decide quién se quedó atrás. Al terminar la frecu deja de compartir.
final class LocationSharingProvider
    extends $NotifierProvider<LocationSharing, LocationState> {
  /// Comparte la ubicación propia (si se activa), recibe la de los demás y
  /// decide quién se quedó atrás. Al terminar la frecu deja de compartir.
  LocationSharingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationSharingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationSharingHash();

  @$internal
  @override
  LocationSharing create() => LocationSharing();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationState>(value),
    );
  }
}

String _$locationSharingHash() => r'1702cb88ce01f7b52d4736ac69403dfe7599e9f7';

/// Comparte la ubicación propia (si se activa), recibe la de los demás y
/// decide quién se quedó atrás. Al terminar la frecu deja de compartir.

abstract class _$LocationSharing extends $Notifier<LocationState> {
  LocationState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocationState, LocationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocationState, LocationState>,
              LocationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
