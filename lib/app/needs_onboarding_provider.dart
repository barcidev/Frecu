import 'package:frecu/features/permissions/presentation/providers/onboarding_permissions_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'needs_onboarding_provider.g.dart';

/// Si al abrir la app hace falta el recorrido de la primera vez (bienvenida,
/// nombre y permisos): no hay nombre guardado, o algún permiso del recorrido
/// sigue por pedir.
///
/// Un permiso negado para siempre no cuenta como por pedir: solo se concede
/// desde los ajustes del teléfono. Los permisos solo se leen si hay nombre.
@riverpod
Future<bool> needsOnboarding(Ref ref) async {
  final preferences = await ref.watch(preferencesProvider.future);
  if (preferences.displayName == null) return true;
  final permissions = await ref.watch(onboardingPermissionsProvider.future);
  return onboardingPermissions.any(
    (permission) => permissions.stateOf(permission) == PermissionState.pending,
  );
}
