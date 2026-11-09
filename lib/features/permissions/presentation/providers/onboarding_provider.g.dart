// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Proveedor global del registro del recorrido de la primera vez.

@ProviderFor(onboardingRepository)
final onboardingRepositoryProvider = OnboardingRepositoryProvider._();

/// Proveedor global del registro del recorrido de la primera vez.

final class OnboardingRepositoryProvider
    extends
        $FunctionalProvider<
          OnboardingRepository,
          OnboardingRepository,
          OnboardingRepository
        >
    with $Provider<OnboardingRepository> {
  /// Proveedor global del registro del recorrido de la primera vez.
  OnboardingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingRepositoryHash();

  @$internal
  @override
  $ProviderElement<OnboardingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnboardingRepository create(Ref ref) {
    return onboardingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingRepository>(value),
    );
  }
}

String _$onboardingRepositoryHash() =>
    r'5dd14c8bc89b5620c9be63f0eaf194e8471c4327';

/// Si el recorrido de la primera vez ya se completó.
///
/// Si no se puede leer, cuenta como no completado: abrir la bienvenida otra
/// vez es mejor que saltarse el nombre.

@ProviderFor(OnboardingCompleted)
final onboardingCompletedProvider = OnboardingCompletedProvider._();

/// Si el recorrido de la primera vez ya se completó.
///
/// Si no se puede leer, cuenta como no completado: abrir la bienvenida otra
/// vez es mejor que saltarse el nombre.
final class OnboardingCompletedProvider
    extends $AsyncNotifierProvider<OnboardingCompleted, bool> {
  /// Si el recorrido de la primera vez ya se completó.
  ///
  /// Si no se puede leer, cuenta como no completado: abrir la bienvenida otra
  /// vez es mejor que saltarse el nombre.
  OnboardingCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCompletedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCompletedHash();

  @$internal
  @override
  OnboardingCompleted create() => OnboardingCompleted();
}

String _$onboardingCompletedHash() =>
    r'8c39c75029520248b4fcbcd3cb24de3c419ee2be';

/// Si el recorrido de la primera vez ya se completó.
///
/// Si no se puede leer, cuenta como no completado: abrir la bienvenida otra
/// vez es mejor que saltarse el nombre.

abstract class _$OnboardingCompleted extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
