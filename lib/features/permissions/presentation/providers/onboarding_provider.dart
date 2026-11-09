import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/permissions/data/repositories/onboarding_repository_impl.dart';
import 'package:frecu/features/permissions/domain/repositories/onboarding_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

/// Proveedor global del registro del recorrido de la primera vez.
@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) =>
    OnboardingRepositoryImpl(preferences: SharedPreferencesAsync());

/// Si el recorrido de la primera vez ya se completó.
///
/// Si no se puede leer, cuenta como no completado: abrir la bienvenida otra
/// vez es mejor que saltarse el nombre.
@Riverpod(keepAlive: true)
class OnboardingCompleted extends _$OnboardingCompleted {
  @override
  Future<bool> build() async {
    final result = await ref.watch(onboardingRepositoryProvider).isCompleted();
    final completed = result.dataOrNull;
    if (completed != null) return completed;
    AppLogger.w('Onboarding mark unavailable', result.failureOrNull);
    return false;
  }

  /// Guarda que el recorrido se completó; el estado cambia aunque no se
  /// pueda guardar, para no reabrirlo mientras la app siga abierta.
  Future<Result<void>> markCompleted() async {
    await future;
    final result = await ref.read(onboardingRepositoryProvider).markCompleted();
    if (ref.mounted) state = const AsyncData(true);
    return result;
  }
}
