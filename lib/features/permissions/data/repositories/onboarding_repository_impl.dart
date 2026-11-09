import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/permissions/domain/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementación de [OnboardingRepository] con `shared_preferences`, junto a
/// las preferencias del usuario.
class OnboardingRepositoryImpl implements OnboardingRepository {
  /// Constructor con inyección del almacenamiento de `shared_preferences`.
  OnboardingRepositoryImpl({required SharedPreferencesAsync preferences})
    : _storage = preferences;

  /// Clave de la marca de recorrido completado.
  static const completedKey = 'onboarding.completed';

  final SharedPreferencesAsync _storage;

  @override
  Future<Result<bool>> isCompleted() async {
    try {
      return Result.success(await _storage.getBool(completedKey) ?? false);
    } on Object catch (e, st) {
      AppLogger.e('Error reading the onboarding mark', e, st);
      return Result.failure(
        Failure.unexpected(message: e.toString(), error: e),
      );
    }
  }

  @override
  Future<Result<void>> markCompleted() async {
    try {
      await _storage.setBool(completedKey, true);
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error saving the onboarding mark', e, st);
      return Result.failure(
        Failure.unexpected(message: e.toString(), error: e),
      );
    }
  }
}
