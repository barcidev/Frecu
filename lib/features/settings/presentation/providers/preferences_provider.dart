import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/domain/repositories/preferences_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_provider.g.dart';

/// Proveedor global singleton del repositorio de preferencias.
@Riverpod(keepAlive: true)
PreferencesRepository preferencesRepository(Ref ref) =>
    PreferencesRepositoryImpl(preferences: SharedPreferencesAsync());

/// Preferencias guardadas del usuario: nombre visible, tema y modo de habla
/// por defecto.
///
/// Si la lectura falla expone los valores por defecto para que la app siga
/// funcionando. Cada cambio se guarda primero y solo entonces cambia el
/// estado; si no se pudo guardar, el estado queda como estaba.
@Riverpod(keepAlive: true)
class PreferencesNotifier extends _$PreferencesNotifier {
  @override
  Future<Preferences> build() async {
    final repository = ref.watch(preferencesRepositoryProvider);
    final result = await repository.load();
    final preferences = result.dataOrNull;
    if (preferences != null) return preferences;
    AppLogger.w('Using default preferences', result.failureOrNull);
    return const Preferences();
  }

  PreferencesRepository get _repository =>
      ref.read(preferencesRepositoryProvider);

  /// Guarda el nombre visible sin espacios alrededor y devuelve el guardado.
  ///
  /// Falla sin cambiar nada si queda vacío o pasa de
  /// [Preferences.displayNameMaxLength] caracteres.
  Future<Result<String>> setDisplayName(String displayName) async {
    await future;
    final result = await _repository.saveDisplayName(displayName);
    if (result case Success(:final data)) {
      _update((preferences) => preferences.copyWith(displayName: data));
    }
    return result;
  }

  /// Guarda el tema de la app.
  Future<Result<void>> setThemePreference(
    ThemePreference themePreference,
  ) async {
    await future;
    final result = await _repository.saveThemePreference(themePreference);
    if (result.isSuccess) {
      _update(
        (preferences) => preferences.copyWith(themePreference: themePreference),
      );
    }
    return result;
  }

  /// Guarda el modo de habla por defecto.
  Future<Result<void>> setDefaultTalkMode(TalkMode talkMode) async {
    await future;
    final result = await _repository.saveDefaultTalkMode(talkMode);
    if (result.isSuccess) {
      _update((preferences) => preferences.copyWith(defaultTalkMode: talkMode));
    }
    return result;
  }

  void _update(Preferences Function(Preferences preferences) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }
}
