import 'package:flutter/foundation.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:frecu/features/permissions/domain/repositories/permission_repository.dart';
import 'package:frecu/features/permissions/presentation/providers/permission_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_permissions_provider.freezed.dart';
part 'onboarding_permissions_provider.g.dart';

/// Permisos que pide el recorrido, en orden: micrófono, red local y
/// dispositivos cercanos (Bluetooth) y notificaciones.
const List<AppPermission> onboardingPermissions = [
  AppPermission.microphone,
  AppPermission.bluetoothConnect,
  AppPermission.notification,
];

/// Estado de un permiso en el recorrido.
enum PermissionState {
  /// Aún no se pidió, o el sistema permite volver a pedirlo.
  pending,

  /// Concedido (también con acceso limitado o provisional).
  granted,

  /// Negado: se concede desde los ajustes de la app.
  denied,
}

/// Permisos del recorrido: el estado de cada uno y si ya se pidieron.
///
/// El mapa no se envuelve en una vista inmodificable: solo se reemplaza con
/// `copyWith`.
@Freezed(makeCollectionsUnmodifiable: false)
abstract class OnboardingPermissionsState with _$OnboardingPermissionsState {
  /// Crea el estado; sin argumentos, todo pendiente y sin pedir.
  const factory OnboardingPermissionsState({
    /// Estado de cada permiso; el que falta está pendiente.
    @Default(<AppPermission, PermissionState>{})
    Map<AppPermission, PermissionState> states,

    /// Se están pidiendo los permisos que faltan.
    @Default(false) bool requesting,

    /// Ya se pidieron una vez, con cualquier resultado.
    @Default(false) bool requested,
  }) = _OnboardingPermissionsState;

  const OnboardingPermissionsState._();

  /// Estado de [permission].
  PermissionState stateOf(AppPermission permission) =>
      states[permission] ?? PermissionState.pending;

  /// Todos los permisos del recorrido están concedidos.
  bool get allGranted => onboardingPermissions.every(
    (permission) => stateOf(permission) == PermissionState.granted,
  );

  /// El recorrido puede seguir: ya se pidieron, o ya estaban concedidos.
  bool get canContinue => requested || allGranted;
}

/// Lee, pide y vuelve a leer los permisos del recorrido.
///
/// Al leer, `denied` cuenta como pendiente (Android no distingue «nunca
/// pedido») y `permanentlyDenied` o `restricted` como negado; tras pedirlo,
/// lo que no queda concedido es negado. En iOS no hay permiso de ejecución
/// para la red local ni para audífonos Bluetooth: no se pide y cuenta como
/// concedido.
@riverpod
class OnboardingPermissions extends _$OnboardingPermissions {
  @override
  Future<OnboardingPermissionsState> build() async {
    final repository = ref.watch(permissionRepositoryProvider);
    final states = <AppPermission, PermissionState>{};
    for (final permission in onboardingPermissions) {
      states[permission] = await _check(repository, permission);
    }
    return OnboardingPermissionsState(states: states);
  }

  OnboardingPermissionsState get _current => state.requireValue;

  /// Pide uno por uno los permisos que faltan; cada fila cambia en cuanto
  /// llega su resultado.
  ///
  /// Devuelve si alguno quedó negado para siempre (`permanentlyDenied`), que
  /// ya solo se concede desde los ajustes de la app.
  Future<bool> requestMissing() async {
    final current = await future;
    if (!ref.mounted || current.requesting) return false;
    state = AsyncData(current.copyWith(requesting: true));
    var permanentlyDenied = false;
    for (final permission in onboardingPermissions) {
      if (_current.stateOf(permission) == PermissionState.granted) continue;
      final result = await ref
          .read(permissionRepositoryProvider)
          .request(permission);
      if (!ref.mounted) return false;
      final status = result.dataOrNull;
      if (status == AppPermissionStatus.permanentlyDenied) {
        permanentlyDenied = true;
      }
      _set(
        permission,
        status != null && _isGranted(status)
            ? PermissionState.granted
            : PermissionState.denied,
      );
    }
    state = AsyncData(_current.copyWith(requesting: false, requested: true));
    return permanentlyDenied;
  }

  /// Desde Ajustes: pide los que faltan y abre los ajustes de la app si
  /// alguno quedó negado para siempre, o si ya estaban todos concedidos y no
  /// queda nada que pedir.
  Future<void> requestOrOpenSettings() async {
    final current = await future;
    if (!ref.mounted || current.requesting) return;
    final open = current.allGranted || await requestMissing();
    if (open && ref.mounted) await openSettings();
  }

  /// Vuelve a leer los estados, p. ej. al volver de los ajustes del teléfono;
  /// un permiso negado no vuelve a pendiente.
  Future<void> refresh() async {
    final current = await future;
    if (!ref.mounted || current.requesting) return;
    for (final permission in onboardingPermissions) {
      final next = await _check(
        ref.read(permissionRepositoryProvider),
        permission,
      );
      if (!ref.mounted) return;
      final keep =
          next == PermissionState.pending &&
          _current.stateOf(permission) == PermissionState.denied;
      if (!keep) _set(permission, next);
    }
  }

  /// Abre los ajustes de la app en el teléfono.
  Future<bool> openSettings() =>
      ref.read(permissionRepositoryProvider).openAppSettings();

  void _set(AppPermission permission, PermissionState next) {
    state = AsyncData(
      _current.copyWith(states: {..._current.states, permission: next}),
    );
  }

  static Future<PermissionState> _check(
    PermissionRepository repository,
    AppPermission permission,
  ) async {
    if (_notAsked(permission)) return PermissionState.granted;
    final result = await repository.checkStatus(permission);
    return switch (result.dataOrNull) {
      null => PermissionState.pending,
      final status when _isGranted(status) => PermissionState.granted,
      AppPermissionStatus.permanentlyDenied ||
      AppPermissionStatus.restricted => PermissionState.denied,
      _ => PermissionState.pending,
    };
  }

  static bool _notAsked(AppPermission permission) =>
      permission == AppPermission.bluetoothConnect &&
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool _isGranted(AppPermissionStatus status) => switch (status) {
    AppPermissionStatus.granted ||
    AppPermissionStatus.limited ||
    AppPermissionStatus.provisional => true,
    AppPermissionStatus.denied ||
    AppPermissionStatus.permanentlyDenied ||
    AppPermissionStatus.restricted => false,
  };
}
