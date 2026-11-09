import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/domain/entities/locale_preference.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'preferences.freezed.dart';

/// Preferencias del usuario guardadas en el teléfono.
@freezed
sealed class Preferences with _$Preferences {
  /// Crea las preferencias; sin argumentos son los valores por defecto.
  const factory Preferences({
    /// Nombre visible en las frecus; nulo si aún no se pidió.
    String? displayName,

    /// Tema de la app: Auto (sigue al sistema), Claro u Oscuro.
    @Default(ThemePreference.auto) ThemePreference themePreference,

    /// Modo de habla con el que se entra a una frecu.
    @Default(TalkMode.pushToTalk) TalkMode defaultTalkMode,

    /// Idioma de la app: Auto (sigue al teléfono), español o inglés.
    @Default(LocalePreference.auto) LocalePreference localePreference,

    /// Vibrar al transmitir, cuando alguien empieza a hablar y si se pierde
    /// la conexión.
    @Default(true) bool vibration,

    /// Hablar con el botón de volumen (solo Android), apagado por defecto.
    @Default(false) bool volumePtt,
  }) = _Preferences;

  /// Largo máximo del nombre visible, en caracteres.
  static const int displayNameMaxLength = 20;

  /// Devuelve [raw] sin espacios alrededor, o nulo si queda vacío o pasa de
  /// [displayNameMaxLength] caracteres.
  static String? normalizeDisplayName(String raw) {
    final name = raw.trim();
    final length = name.runes.length;
    if (length == 0 || length > displayNameMaxLength) return null;
    return name;
  }
}
