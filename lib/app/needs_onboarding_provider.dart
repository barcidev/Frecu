import 'package:frecu/features/permissions/presentation/providers/onboarding_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'needs_onboarding_provider.g.dart';

/// Si al abrir la app hace falta el recorrido de la primera vez (bienvenida,
/// nombre y permisos): no hay nombre guardado, o el recorrido no se completó
/// (no se pulsó Continuar en los permisos).
///
/// No depende del estado de los permisos: Android nunca informa «negado para
/// siempre» al consultar, así que un permiso negado parecería siempre por
/// pedir. Lo que falte se vuelve a pedir en contexto.
@riverpod
Future<bool> needsOnboarding(Ref ref) async {
  final preferences = await ref.watch(preferencesProvider.future);
  if (preferences.displayName == null) return true;
  return !await ref.watch(onboardingCompletedProvider.future);
}
