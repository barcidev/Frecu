import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';

/// Contrato del repositorio de preferencias guardadas en el teléfono.
abstract interface class PreferencesRepository {
  /// Lee las preferencias guardadas; lo que falta o no se reconoce vuelve con
  /// su valor por defecto.
  Future<Result<Preferences>> load();

  /// Guarda el nombre visible sin espacios alrededor y devuelve el guardado.
  ///
  /// Falla sin tocar lo guardado si el nombre queda vacío o pasa de
  /// [Preferences.displayNameMaxLength] caracteres.
  Future<Result<String>> saveDisplayName(String displayName);

  /// Guarda el tema de la app.
  Future<Result<void>> saveThemePreference(ThemePreference themePreference);

  /// Guarda el modo de habla por defecto.
  Future<Result<void>> saveDefaultTalkMode(TalkMode talkMode);
}
