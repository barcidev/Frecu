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
/// lo que no queda concedido es negado. En iOS no hay permiso de ejecución
/// para la red local ni para audífonos Bluetooth: no se pide y cuenta como
/// concedido.

@ProviderFor(OnboardingPermissions)
final onboardingPermissionsProvider = OnboardingPermissionsProvider._();

/// Lee, pide y vuelve a leer los permisos del recorrido.
///
/// Al leer, `denied` cuenta como pendiente (Android no distingue «nunca
/// pedido») y `permanentlyDenied` o `restricted` como negado; tras pedirlo,
/// lo que no queda concedido es negado. En iOS no hay permiso de ejecución
/// para la red local ni para audífonos Bluetooth: no se pide y cuenta como
/// concedido.
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
  /// lo que no queda concedido es negado. En iOS no hay permiso de ejecución
  /// para la red local ni para audífonos Bluetooth: no se pide y cuenta como
  /// concedido.
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
    r'45733911e21617ce11c6f20bf43d3ca712b8e14c';

/// Lee, pide y vuelve a leer los permisos del recorrido.
///
/// Al leer, `denied` cuenta como pendiente (Android no distingue «nunca
/// pedido») y `permanentlyDenied` o `restricted` como negado; tras pedirlo,
/// lo que no queda concedido es negado. En iOS no hay permiso de ejecución
/// para la red local ni para audífonos Bluetooth: no se pide y cuenta como
/// concedido.

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
