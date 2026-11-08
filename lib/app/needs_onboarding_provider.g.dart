// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'needs_onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Si al abrir la app hace falta el recorrido de la primera vez (bienvenida,
/// nombre y permisos): no hay nombre guardado, o algún permiso del recorrido
/// sigue por pedir.
///
/// Un permiso negado para siempre no cuenta como por pedir: solo se concede
/// desde los ajustes del teléfono. Los permisos solo se leen si hay nombre.

@ProviderFor(needsOnboarding)
final needsOnboardingProvider = NeedsOnboardingProvider._();

/// Si al abrir la app hace falta el recorrido de la primera vez (bienvenida,
/// nombre y permisos): no hay nombre guardado, o algún permiso del recorrido
/// sigue por pedir.
///
/// Un permiso negado para siempre no cuenta como por pedir: solo se concede
/// desde los ajustes del teléfono. Los permisos solo se leen si hay nombre.

final class NeedsOnboardingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Si al abrir la app hace falta el recorrido de la primera vez (bienvenida,
  /// nombre y permisos): no hay nombre guardado, o algún permiso del recorrido
  /// sigue por pedir.
  ///
  /// Un permiso negado para siempre no cuenta como por pedir: solo se concede
  /// desde los ajustes del teléfono. Los permisos solo se leen si hay nombre.
  NeedsOnboardingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'needsOnboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$needsOnboardingHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return needsOnboarding(ref);
  }
}

String _$needsOnboardingHash() => r'ecb2fa773e021f0e29325ff2f80daea357705870';
