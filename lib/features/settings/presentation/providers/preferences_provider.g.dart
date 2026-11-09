// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Proveedor global singleton del repositorio de preferencias.

@ProviderFor(preferencesRepository)
final preferencesRepositoryProvider = PreferencesRepositoryProvider._();

/// Proveedor global singleton del repositorio de preferencias.

final class PreferencesRepositoryProvider
    extends
        $FunctionalProvider<
          PreferencesRepository,
          PreferencesRepository,
          PreferencesRepository
        >
    with $Provider<PreferencesRepository> {
  /// Proveedor global singleton del repositorio de preferencias.
  PreferencesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferencesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferencesRepositoryHash();

  @$internal
  @override
  $ProviderElement<PreferencesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PreferencesRepository create(Ref ref) {
    return preferencesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreferencesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreferencesRepository>(value),
    );
  }
}

String _$preferencesRepositoryHash() =>
    r'ef2dfec5d49e2dd41d3cea5e976a7153501a63ea';

/// Preferencias guardadas del usuario: nombre visible, tema, modo de habla
/// por defecto e idioma.
///
/// Si la lectura falla expone los valores por defecto para que la app siga
/// funcionando. Cada cambio se guarda primero y solo entonces cambia el
/// estado; si no se pudo guardar, el estado queda como estaba.

@ProviderFor(PreferencesNotifier)
final preferencesProvider = PreferencesNotifierProvider._();

/// Preferencias guardadas del usuario: nombre visible, tema, modo de habla
/// por defecto e idioma.
///
/// Si la lectura falla expone los valores por defecto para que la app siga
/// funcionando. Cada cambio se guarda primero y solo entonces cambia el
/// estado; si no se pudo guardar, el estado queda como estaba.
final class PreferencesNotifierProvider
    extends $AsyncNotifierProvider<PreferencesNotifier, Preferences> {
  /// Preferencias guardadas del usuario: nombre visible, tema, modo de habla
  /// por defecto e idioma.
  ///
  /// Si la lectura falla expone los valores por defecto para que la app siga
  /// funcionando. Cada cambio se guarda primero y solo entonces cambia el
  /// estado; si no se pudo guardar, el estado queda como estaba.
  PreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferencesNotifierHash();

  @$internal
  @override
  PreferencesNotifier create() => PreferencesNotifier();
}

String _$preferencesNotifierHash() =>
    r'61b6b56adfe5d4f8249406f4e67f729c4afa8e19';

/// Preferencias guardadas del usuario: nombre visible, tema, modo de habla
/// por defecto e idioma.
///
/// Si la lectura falla expone los valores por defecto para que la app siga
/// funcionando. Cada cambio se guarda primero y solo entonces cambia el
/// estado; si no se pudo guardar, el estado queda como estaba.

abstract class _$PreferencesNotifier extends $AsyncNotifier<Preferences> {
  FutureOr<Preferences> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Preferences>, Preferences>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Preferences>, Preferences>,
              AsyncValue<Preferences>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
