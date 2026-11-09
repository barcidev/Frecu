// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_hotspot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Si este teléfono crea la red de la frecu desde la app: solo Android (en
/// Android 7, el intento falla con `unsupported`).

@ProviderFor(localHotspotAvailable)
final localHotspotAvailableProvider = LocalHotspotAvailableProvider._();

/// Si este teléfono crea la red de la frecu desde la app: solo Android (en
/// Android 7, el intento falla con `unsupported`).

final class LocalHotspotAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Si este teléfono crea la red de la frecu desde la app: solo Android (en
  /// Android 7, el intento falla con `unsupported`).
  LocalHotspotAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localHotspotAvailableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localHotspotAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return localHotspotAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$localHotspotAvailableHash() =>
    r'21df506965489f8ffac059e027ed1feef2b1c0fb';

/// La red de la frecu que crea el anfitrión Android: se crea al tocar
/// «Crear la red» y se apaga al cerrar la frecu o al salir de la creación
/// sin abrirla.

@ProviderFor(LocalHotspotNotifier)
final localHotspotProvider = LocalHotspotNotifierProvider._();

/// La red de la frecu que crea el anfitrión Android: se crea al tocar
/// «Crear la red» y se apaga al cerrar la frecu o al salir de la creación
/// sin abrirla.
final class LocalHotspotNotifierProvider
    extends $NotifierProvider<LocalHotspotNotifier, LocalHotspotState> {
  /// La red de la frecu que crea el anfitrión Android: se crea al tocar
  /// «Crear la red» y se apaga al cerrar la frecu o al salir de la creación
  /// sin abrirla.
  LocalHotspotNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localHotspotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localHotspotNotifierHash();

  @$internal
  @override
  LocalHotspotNotifier create() => LocalHotspotNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalHotspotState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalHotspotState>(value),
    );
  }
}

String _$localHotspotNotifierHash() =>
    r'f9c2092e61d010567aac2a80df9429303b361c0a';

/// La red de la frecu que crea el anfitrión Android: se crea al tocar
/// «Crear la red» y se apaga al cerrar la frecu o al salir de la creación
/// sin abrirla.

abstract class _$LocalHotspotNotifier extends $Notifier<LocalHotspotState> {
  LocalHotspotState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocalHotspotState, LocalHotspotState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocalHotspotState, LocalHotspotState>,
              LocalHotspotState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
