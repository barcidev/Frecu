// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_permissions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lee, pide y vuelve a leer los permisos del recorrido.
///
/// Al leer, `denied` cuenta como pendiente (Android no distingue «nunca
/// pedido») y `permanentlyDenied` o `restricted` como negado; tras pedirlo,
/// lo que no queda concedido es negado. En iOS la red local no tiene
/// permiso que pedir (lo pide el sistema al buscar); la fila de dispositivos
/// cercanos pide ahí el de Bluetooth, para encontrar frecus por Bluetooth.

@ProviderFor(OnboardingPermissions)
final onboardingPermissionsProvider = OnboardingPermissionsProvider._();

/// Lee, pide y vuelve a leer los permisos del recorrido.
///
/// Al leer, `denied` cuenta como pendiente (Android no distingue «nunca
/// pedido») y `permanentlyDenied` o `restricted` como negado; tras pedirlo,
/// lo que no queda concedido es negado. En iOS la red local no tiene
/// permiso que pedir (lo pide el sistema al buscar); la fila de dispositivos
/// cercanos pide ahí el de Bluetooth, para encontrar frecus por Bluetooth.
final class OnboardingPermissionsProvider
    extends
        $AsyncNotifierProvider<
          OnboardingPermissions,
          OnboardingPermissionsState
        > {
  /// Lee, pide y vuelve a leer los permisos del recorrido.
  ///
  /// Al leer, `denied` cuenta como pendiente (Android no distingue «nunca
  /// pedido») y `permanentlyDenied` o `restricted` como negado; tras pedirlo,
  /// lo que no queda concedido es negado. En iOS la red local no tiene
  /// permiso que pedir (lo pide el sistema al buscar); la fila de dispositivos
  /// cercanos pide ahí el de Bluetooth, para encontrar frecus por Bluetooth.
  OnboardingPermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingPermissionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingPermissionsHash();

  @$internal
  @override
  OnboardingPermissions create() => OnboardingPermissions();
}

String _$onboardingPermissionsHash() =>
    r'41e44d7e131164ab5067515a75d44d393187cc14';

/// Lee, pide y vuelve a leer los permisos del recorrido.
///
/// Al leer, `denied` cuenta como pendiente (Android no distingue «nunca
/// pedido») y `permanentlyDenied` o `restricted` como negado; tras pedirlo,
/// lo que no queda concedido es negado. En iOS la red local no tiene
/// permiso que pedir (lo pide el sistema al buscar); la fila de dispositivos
/// cercanos pide ahí el de Bluetooth, para encontrar frecus por Bluetooth.

abstract class _$OnboardingPermissions
    extends $AsyncNotifier<OnboardingPermissionsState> {
  FutureOr<OnboardingPermissionsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<OnboardingPermissionsState>,
              OnboardingPermissionsState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<OnboardingPermissionsState>,
                OnboardingPermissionsState
              >,
              AsyncValue<OnboardingPermissionsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
