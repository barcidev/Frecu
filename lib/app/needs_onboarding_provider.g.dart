// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'needs_onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Si al abrir la app hace falta el recorrido de la primera vez (bienvenida,
/// nombre y permisos): no hay nombre guardado, o el recorrido no se completó
/// (no se pulsó Continuar en los permisos).
///
/// No depende del estado de los permisos: Android nunca informa «negado para
/// siempre» al consultar, así que un permiso negado parecería siempre por
/// pedir. Lo que falte se vuelve a pedir en contexto.

@ProviderFor(needsOnboarding)
final needsOnboardingProvider = NeedsOnboardingProvider._();

/// Si al abrir la app hace falta el recorrido de la primera vez (bienvenida,
/// nombre y permisos): no hay nombre guardado, o el recorrido no se completó
/// (no se pulsó Continuar en los permisos).
///
/// No depende del estado de los permisos: Android nunca informa «negado para
/// siempre» al consultar, así que un permiso negado parecería siempre por
/// pedir. Lo que falte se vuelve a pedir en contexto.

final class NeedsOnboardingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Si al abrir la app hace falta el recorrido de la primera vez (bienvenida,
  /// nombre y permisos): no hay nombre guardado, o el recorrido no se completó
  /// (no se pulsó Continuar en los permisos).
  ///
  /// No depende del estado de los permisos: Android nunca informa «negado para
  /// siempre» al consultar, así que un permiso negado parecería siempre por
  /// pedir. Lo que falte se vuelve a pedir en contexto.
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

String _$needsOnboardingHash() => r'cc2fb1349930be1c1a0c0eea38e9cbe3b0c77347';
