import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/domain/entities/locale_preference.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/domain/repositories/preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementación de [PreferencesRepository] con `shared_preferences`.
///
/// Los enums se guardan como texto con su `name`; un valor que no se
/// reconoce se lee como el valor por defecto.
class PreferencesRepositoryImpl implements PreferencesRepository {
  /// Constructor con inyección del almacenamiento de `shared_preferences`.
  PreferencesRepositoryImpl({required SharedPreferencesAsync preferences})
    : _storage = preferences;

  /// Clave del nombre visible.
  static const displayNameKey = 'settings.displayName';

  /// Clave del tema de la app.
  static const themePreferenceKey = 'settings.themePreference';

  /// Clave del modo de habla por defecto.
  static const defaultTalkModeKey = 'settings.defaultTalkMode';

  /// Clave del idioma de la app.
  static const localePreferenceKey = 'settings.localePreference';

  /// Clave de la vibración (`true` o `false`).
  static const vibrationKey = 'settings.vibration';

  /// Clave del botón de volumen para hablar (`true` o `false`).
  static const volumePttKey = 'settings.volumePtt';

  final SharedPreferencesAsync _storage;

  @override
  Future<Result<Preferences>> load() async {
    try {
      final displayName = await _storage.getString(displayNameKey);
      final theme = await _storage.getString(themePreferenceKey);
      final talkMode = await _storage.getString(defaultTalkModeKey);
      final locale = await _storage.getString(localePreferenceKey);
      final vibration = await _storage.getString(vibrationKey);
      final volumePtt = await _storage.getString(volumePttKey);
      const defaults = Preferences();
      return Result.success(
        Preferences(
          displayName: displayName == null
              ? null
              : Preferences.normalizeDisplayName(displayName),
          themePreference:
              ThemePreference.values.asNameMap()[theme] ??
              defaults.themePreference,
          defaultTalkMode:
              TalkMode.values.asNameMap()[talkMode] ?? defaults.defaultTalkMode,
          localePreference:
              LocalePreference.values.asNameMap()[locale] ??
              defaults.localePreference,
          vibration: _boolOf(vibration) ?? defaults.vibration,
          volumePtt: _boolOf(volumePtt) ?? defaults.volumePtt,
        ),
      );
    } on Object catch (e, st) {
      AppLogger.e('Error reading preferences', e, st);
      return Result.failure(
        Failure.unexpected(message: e.toString(), error: e),
      );
    }
  }

  @override
  Future<Result<String>> saveDisplayName(String displayName) async {
    final name = Preferences.normalizeDisplayName(displayName);
    if (name == null) {
      return const Result.failure(
        Failure.unexpected(message: 'Invalid display name'),
      );
    }
    final saved = await _save(displayNameKey, name);
    return switch (saved) {
      Success() => Result.success(name),
      FailureResult(:final failure) => Result.failure(failure),
    };
  }

  @override
  Future<Result<void>> saveThemePreference(ThemePreference themePreference) =>
      _save(themePreferenceKey, themePreference.name);

  @override
  Future<Result<void>> saveDefaultTalkMode(TalkMode talkMode) =>
      _save(defaultTalkModeKey, talkMode.name);

  @override
  Future<Result<void>> saveLocalePreference(
    LocalePreference localePreference,
  ) => _save(localePreferenceKey, localePreference.name);

  @override
  Future<Result<void>> saveVibration({required bool enabled}) =>
      _save(vibrationKey, '$enabled');

  @override
  Future<Result<void>> saveVolumePtt({required bool enabled}) =>
      _save(volumePttKey, '$enabled');

  /// `true` o `false` guardados como texto; nulo si es otra cosa.
  static bool? _boolOf(String? raw) => switch (raw) {
    'true' => true,
    'false' => false,
    _ => null,
  };

  Future<Result<void>> _save(String key, String value) async {
    try {
      await _storage.setString(key, value);
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error saving preference $key', e, st);
      return Result.failure(
        Failure.unexpected(message: e.toString(), error: e),
      );
    }
  }
}
