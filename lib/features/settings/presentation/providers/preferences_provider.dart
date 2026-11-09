import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/locale_preference.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/domain/repositories/preferences_repository.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_provider.g.dart';

/// Proveedor global singleton del repositorio de preferencias.
@Riverpod(keepAlive: true)
PreferencesRepository preferencesRepository(Ref ref) =>
    PreferencesRepositoryImpl(preferences: SharedPreferencesAsync());

/// Aplica [preference] al idioma de la app y devuelve el que queda en uso.
///
/// Auto usa el idioma del teléfono; el inglés se carga diferido, así que
/// hay que esperarlo.
Future<AppLocale> applyLocalePreference(LocalePreference preference) =>
    switch (preference) {
      LocalePreference.auto => LocaleSettings.useDeviceLocale(),
      LocalePreference.es => LocaleSettings.setLocale(AppLocale.es),
      LocalePreference.en => LocaleSettings.setLocale(AppLocale.en),
    };

/// Preferencias guardadas del usuario: nombre visible, tema, modo de habla
/// por defecto e idioma.
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

  /// Guarda si el teléfono vibra con los avisos de la frecu.
  Future<Result<void>> setVibration({required bool enabled}) async {
    await future;
    final result = await _repository.saveVibration(enabled: enabled);
    if (result.isSuccess) {
      _update((preferences) => preferences.copyWith(vibration: enabled));
    }
    return result;
  }

  /// Guarda si el botón de volumen sirve para hablar (Android).
  Future<Result<void>> setVolumePtt({required bool enabled}) async {
    await future;
    final result = await _repository.saveVolumePtt(enabled: enabled);
    if (result.isSuccess) {
      _update((preferences) => preferences.copyWith(volumePtt: enabled));
    }
    return result;
  }

  /// Guarda si el audio pasa al auricular al acercar el teléfono a la oreja.
  Future<Result<void>> setEarpieceOnRaise({required bool enabled}) async {
    await future;
    final result = await _repository.saveEarpieceOnRaise(enabled: enabled);
    if (result.isSuccess) {
      _update((preferences) => preferences.copyWith(earpieceOnRaise: enabled));
    }
    return result;
  }

  /// Guarda el idioma de la app y, solo si se guardó, lo aplica al instante.
  Future<Result<void>> setLocalePreference(
    LocalePreference localePreference,
  ) async {
    await future;
    final result = await _repository.saveLocalePreference(localePreference);
    if (result.isSuccess) {
      await applyLocalePreference(localePreference);
      _update(
        (preferences) =>
            preferences.copyWith(localePreference: localePreference),
      );
    }
    return result;
  }

  void _update(Preferences Function(Preferences preferences) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }
}
