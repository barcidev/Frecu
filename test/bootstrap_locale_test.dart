// AC4: CUANDO se elige un idioma ENTONCES queda guardado y la app vuelve a abrir en ese idioma aunque el teléfono esté en otro; CUANDO la elección es Auto, no hay nada guardado, lo guardado no se reconoce o no se pudieron leer las preferencias ENTONCES abre en el idioma del teléfono.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Pone el teléfono en [locale] hasta el final de la prueba.
void _setDeviceLocale(Locale locale) {
  final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
    ..localesTestValue = [locale];
  addTearDown(dispatcher.clearLocalesTestValue);
}

/// Deja [data] guardado antes de abrir la app.
void _useStorage(Map<String, Object> data) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(data);
}

/// Arranca como `bootstrap`: lee las preferencias y aplica el idioma.
Future<AppLocale> _start() async {
  final container = await createAppContainer();
  addTearDown(container.dispose);
  return applySavedLocale(container);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('applySavedLocale', () {
    test('AC4: abre en inglés si se guardó English, aunque el teléfono esté '
        'en español', () async {
      _setDeviceLocale(const Locale('es', 'CO'));
      _useStorage({PreferencesRepositoryImpl.localePreferenceKey: 'en'});

      expect(await _start(), AppLocale.en);
      expect(LocaleSettings.currentLocale, AppLocale.en);
    });

    test('AC4: abre en español si se guardó Español, aunque el teléfono esté '
        'en inglés', () async {
      _setDeviceLocale(const Locale('en', 'US'));
      _useStorage({PreferencesRepositoryImpl.localePreferenceKey: 'es'});

      expect(await _start(), AppLocale.es);
      expect(LocaleSettings.currentLocale, AppLocale.es);
    });

    final cases = <String, Map<String, Object>>{
      'Auto': {PreferencesRepositoryImpl.localePreferenceKey: 'auto'},
      'nada guardado': {},
      'un valor desconocido': {
        PreferencesRepositoryImpl.localePreferenceKey: 'fr',
      },
    };
    for (final MapEntry(key: name, value: data) in cases.entries) {
      test('AC4: con $name abre en el idioma del teléfono', () async {
        _useStorage(data);

        _setDeviceLocale(const Locale('en', 'US'));
        expect(await _start(), AppLocale.en);
        expect(LocaleSettings.currentLocale, AppLocale.en);

        _setDeviceLocale(const Locale('es', 'MX'));
        expect(await _start(), AppLocale.es);
        expect(LocaleSettings.currentLocale, AppLocale.es);
      });
    }

    test('AC4: sin almacenamiento disponible abre en el idioma del teléfono, '
        'sin lanzar', () async {
      SharedPreferencesAsyncPlatform.instance = null;
      _setDeviceLocale(const Locale('en', 'GB'));

      expect(await _start(), AppLocale.en);
      expect(LocaleSettings.currentLocale, AppLocale.en);
    });
  });
}
