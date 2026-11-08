// AC3: CUANDO el usuario toca «Idioma» ENTONCES se abre una hoja con Auto, Español y English, con la elección actual marcada; CUANDO elige una ENTONCES la hoja se cierra y Ajustes y el resto de la app pasan a ese idioma al instante, sin reiniciar (Auto: el idioma del teléfono).
// AC4: CUANDO se elige un idioma ENTONCES queda guardado y la app vuelve a abrir en ese idioma aunque el teléfono esté en otro; CUANDO la elección es Auto, no hay nada guardado, lo guardado no se reconoce o no se pudieron leer las preferencias ENTONCES abre en el idioma del teléfono.
// AC5: CUANDO no se puede guardar el idioma ENTONCES aparece el aviso de error y el idioma de la app y la fila «Idioma» siguen como estaban.
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/locale_preference.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/repositories/preferences_repository.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Almacenamiento que falla en cualquier lectura o escritura.
class _FailingPreferences extends Fake implements SharedPreferencesAsync {}

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

/// Pone el teléfono en [locale] hasta el final de la prueba.
void _setDeviceLocale(Locale locale) {
  final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
    ..localesTestValue = [locale];
  addTearDown(dispatcher.clearLocalesTestValue);
}

PreferencesRepositoryImpl _openRepository() =>
    PreferencesRepositoryImpl(preferences: SharedPreferencesAsync());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('LocalePreference guardado', () {
    test('AC4: por defecto es Auto, también sin nada guardado', () async {
      expect(LocalePreference.values, [
        LocalePreference.auto,
        LocalePreference.es,
        LocalePreference.en,
      ]);
      expect(const Preferences().localePreference, LocalePreference.auto);

      final result = await _openRepository().load();

      expect(result.dataOrNull?.localePreference, LocalePreference.auto);
    });

    test('AC4: el idioma guardado se lee igual al reabrir, sin tocar las '
        'demás preferencias', () async {
      final repository = _openRepository();
      expect((await repository.saveDisplayName('Ana')).isSuccess, isTrue);

      for (final locale in [
        LocalePreference.en,
        LocalePreference.es,
        LocalePreference.auto,
      ]) {
        expect(
          (await repository.saveLocalePreference(locale)).isSuccess,
          isTrue,
        );

        final reopened = await _openRepository().load();

        expect(reopened.dataOrNull?.localePreference, locale);
        expect(reopened.dataOrNull?.displayName, 'Ana');
      }
    });

    test(
      'AC4: un idioma guardado que no se reconoce se lee como Auto',
      () async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferencesRepositoryImpl.localePreferenceKey: 'fr',
            });

        final result = await _openRepository().load();

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.localePreference, LocalePreference.auto);
      },
    );

    test(
      'AC5: si el almacenamiento falla devuelve un fallo sin lanzar',
      () async {
        final repository = PreferencesRepositoryImpl(
          preferences: _FailingPreferences(),
        );

        final result = await repository.saveLocalePreference(
          LocalePreference.en,
        );

        expect(result.isFailure, isTrue);
      },
    );
  });

  group('preferencesProvider.setLocalePreference', () {
    test('AC3: aplica el idioma al instante, lo expone y lo conserva al '
        'reabrir', () async {
      _setDeviceLocale(const Locale('es'));
      final container = ProviderContainer.test();
      final notifier = container.read(preferencesProvider.notifier);

      final english = await notifier.setLocalePreference(LocalePreference.en);

      expect(english.isSuccess, isTrue);
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(
        container.read(preferencesProvider).value?.localePreference,
        LocalePreference.en,
      );
      final reopened = ProviderContainer.test();
      expect(
        (await reopened.read(preferencesProvider.future)).localePreference,
        LocalePreference.en,
      );

      expect(
        (await notifier.setLocalePreference(LocalePreference.es)).isSuccess,
        isTrue,
      );
      expect(LocaleSettings.currentLocale, AppLocale.es);
      expect(
        container.read(preferencesProvider).value?.localePreference,
        LocalePreference.es,
      );
    });

    test('AC3: Auto pasa al idioma del teléfono', () async {
      final container = ProviderContainer.test();
      final notifier = container.read(preferencesProvider.notifier);

      _setDeviceLocale(const Locale('en', 'US'));
      expect(
        (await notifier.setLocalePreference(LocalePreference.auto)).isSuccess,
        isTrue,
      );
      expect(LocaleSettings.currentLocale, AppLocale.en);

      await notifier.setLocalePreference(LocalePreference.es);
      _setDeviceLocale(const Locale('es', 'CO'));
      await notifier.setLocalePreference(LocalePreference.en);
      expect(LocaleSettings.currentLocale, AppLocale.en);

      await notifier.setLocalePreference(LocalePreference.auto);

      expect(LocaleSettings.currentLocale, AppLocale.es);
      expect(
        container.read(preferencesProvider).value?.localePreference,
        LocalePreference.auto,
      );
    });

    test(
      'AC5: si no se puede guardar no cambia ni el idioma ni el estado',
      () async {
        const saved = Preferences(localePreference: LocalePreference.es);
        const failure = Failure.unexpected(message: 'disco lleno');
        final repository = _MockPreferencesRepository();
        when(repository.load)
            .thenAnswer((_) async => const Result.success(saved));
        when(() => repository.saveLocalePreference(LocalePreference.en))
            .thenAnswer((_) async => const Result<void>.failure(failure));
        final container = ProviderContainer.test(
          overrides: [
            preferencesRepositoryProvider.overrideWithValue(repository),
          ],
        );
        expect(await container.read(preferencesProvider.future), saved);

        final result = await container
            .read(preferencesProvider.notifier)
            .setLocalePreference(LocalePreference.en);

        expect(result.isFailure, isTrue);
        expect(LocaleSettings.currentLocale, AppLocale.es);
        expect(container.read(preferencesProvider).value, saved);
      },
    );
  });
}
