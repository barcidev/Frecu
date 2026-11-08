// AC2: CUANDO se abre Ajustes ENTONCES entre «Voz» y «Apariencia» aparece el grupo «General» con la fila «Idioma», que muestra la elección guardada (Auto con el idioma en uso, Español o English), el código del idioma en uso (ES o EN) y un chevron, con sus textos en español y en inglés.
// AC3: CUANDO el usuario toca «Idioma» ENTONCES se abre una hoja con Auto, Español y English, con la elección actual marcada; CUANDO elige una ENTONCES la hoja se cierra y Ajustes y el resto de la app pasan a ese idioma al instante, sin reiniciar (Auto: el idioma del teléfono).
// AC5: CUANDO no se puede guardar el idioma ENTONCES aparece el aviso de error y el idioma de la app y la fila «Idioma» siguen como estaban.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/locale_preference.dart';
import 'package:frecu/features/settings/presentation/pages/settings_page.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/features/settings/presentation/widgets/language_sheet.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Almacenamiento que lee bien pero falla al guardar.
final class _FailingWrites extends InMemorySharedPreferencesAsync {
  _FailingWrites() : super.empty();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async => throw StateError('No se pudo guardar $key');
}

/// Deja [data] guardado antes de abrir la app.
void _useStorage(Map<String, Object> data) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(data);
}

/// Pone el teléfono en [locale] hasta el final de la prueba.
void _setDeviceLocale(WidgetTester tester, Locale locale) {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

/// Abre la app como `bootstrap` (preferencias leídas e idioma guardado
/// aplicado) en un teléfono de 390 × 844 con movimiento reducido (la firma no
/// anima sin fin) y entra a Ajustes.
Future<void> _openSettings(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final container = await createAppContainer();
  addTearDown(container.dispose);
  // El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
  await tester.runAsync(() => applySavedLocale(container));
  final router = AppRouter();
  await tester.pumpWidget(
    TranslationProvider(
      child: UncontrolledProviderScope(
        container: container,
        child: FrecuApp(appRouter: router),
      ),
    ),
  );
  await tester.pumpAndSettle();

  unawaited(router.push(const SettingsRoute()));
  await tester.pumpAndSettle();
}

/// Idioma que lee la app al reabrirse sobre el mismo almacenamiento.
Future<LocalePreference?> _reopen() async {
  final container = await createAppContainer();
  addTearDown(container.dispose);
  return container.read(preferencesProvider).value?.localePreference;
}

Finder get _row => find.byType(LanguageRow);

Finder get _sheet => find.byType(LanguageSheet);

Finder _option(LocalePreference value) =>
    find.byKey(Key('language_option_${value.name}'));

/// Texto [text] dentro de la fila «Idioma».
Finder _inRow(String text) =>
    find.descendant(of: _row, matching: find.text(text));

/// Abre la hoja desde la fila «Idioma».
Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(_row);
  await tester.pumpAndSettle();
}

/// Elige [value] en la hoja y espera a que el idioma se cargue y la hoja se
/// cierre.
Future<void> _choose(WidgetTester tester, LocalePreference value) async {
  await tester.tap(_option(value));
  // El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('Grupo General', () {
    testWidgets('AC2: General va entre Voz y Apariencia con la fila Idioma en '
        'Auto, el código del idioma en uso y un chevron', (tester) async {
      _setDeviceLocale(tester, const Locale('es', 'CO'));
      _useStorage({});
      await _openSettings(tester);

      final voice = find.text(t.settings.voice.toUpperCase());
      final general = find.text(t.settings.general.toUpperCase());
      final appearance = find.text(t.settings.appearance.toUpperCase());
      expect(general, findsOneWidget);
      expect(
        tester.getTopLeft(voice).dy,
        lessThan(tester.getTopLeft(general).dy),
      );
      expect(
        tester.getTopLeft(general).dy,
        lessThan(tester.getTopLeft(_row).dy),
      );
      expect(
        tester.getTopLeft(_row).dy,
        lessThan(tester.getTopLeft(appearance).dy),
      );

      expect(_inRow(t.settings.language.title), findsOneWidget);
      expect(
        _inRow(t.settings.language.autoValue(language: t.settings.language.es)),
        findsOneWidget,
      );
      expect(_inRow('ES'), findsOneWidget);
      expect(
        find.descendant(
          of: _row,
          matching: find.byWidgetPredicate(
            (widget) => widget is FrIcon && widget.icon == FrIcons.chevron,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SettingsPage),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    });

    testWidgets('AC2: muestra Español o English guardado', (tester) async {
      _setDeviceLocale(tester, const Locale('en', 'US'));
      _useStorage({PreferencesRepositoryImpl.localePreferenceKey: 'es'});
      await _openSettings(tester);

      expect(_inRow(t.settings.language.es), findsOneWidget);
      expect(_inRow('ES'), findsOneWidget);
    });

    testWidgets('AC2: en inglés los textos salen de la traducción en', (
      tester,
    ) async {
      _setDeviceLocale(tester, const Locale('es', 'CO'));
      _useStorage({PreferencesRepositoryImpl.localePreferenceKey: 'en'});
      await _openSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('GENERAL'), findsOneWidget);
      expect(_inRow('Language'), findsOneWidget);
      expect(_inRow('English'), findsOneWidget);
      expect(_inRow('EN'), findsOneWidget);

      await _openSheet(tester);
      expect(
        find.descendant(of: _sheet, matching: find.text('Language')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _sheet,
          matching: find.text("Auto uses your phone's language."),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _sheet, matching: find.text('FOLLOWS YOUR PHONE')),
        findsOneWidget,
      );
    });
  });

  group('Hoja de idioma', () {
    testWidgets('AC3: muestra Auto, Español y English con la elección actual '
        'marcada', (tester) async {
      _setDeviceLocale(tester, const Locale('es', 'CO'));
      _useStorage({PreferencesRepositoryImpl.localePreferenceKey: 'es'});
      await _openSettings(tester);

      await _openSheet(tester);

      expect(_sheet, findsOneWidget);
      expect(
        find.descendant(
          of: _sheet,
          matching: find.text(t.settings.language.title),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _sheet,
          matching: find.text(t.settings.language.message),
        ),
        findsOneWidget,
      );
      for (final (value, name) in [
        (LocalePreference.auto, t.settings.language.auto),
        (LocalePreference.es, t.settings.language.es),
        (LocalePreference.en, t.settings.language.en),
      ]) {
        expect(
          find.descendant(of: _option(value), matching: find.text(name)),
          findsOneWidget,
        );
        expect(
          tester.widget<LanguageOption>(_option(value)).selected,
          value == LocalePreference.es,
        );
      }
      expect(
        find.descendant(
          of: _option(LocalePreference.auto),
          matching: find.text(t.settings.language.autoHelp.toUpperCase()),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC3: elegir un idioma cierra la hoja, cambia Ajustes y el '
        'resto de la app al instante y se conserva al reabrir', (tester) async {
      _setDeviceLocale(tester, const Locale('es', 'CO'));
      _useStorage({});
      await _openSettings(tester);

      await _openSheet(tester);
      await _choose(tester, LocalePreference.en);

      expect(_sheet, findsNothing);
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Ajustes'), findsNothing);
      expect(_inRow('Language'), findsOneWidget);
      expect(_inRow('English'), findsOneWidget);
      expect(_inRow('EN'), findsOneWidget);
      expect(await tester.runAsync(_reopen), LocalePreference.en);

      await _openSheet(tester);
      expect(
        tester.widget<LanguageOption>(_option(LocalePreference.en)).selected,
        isTrue,
      );
      await _choose(tester, LocalePreference.es);

      expect(_sheet, findsNothing);
      expect(LocaleSettings.currentLocale, AppLocale.es);
      expect(find.text('Ajustes'), findsOneWidget);
      expect(_inRow('Español'), findsOneWidget);
      expect(_inRow('ES'), findsOneWidget);
      expect(await tester.runAsync(_reopen), LocalePreference.es);

      // El resto de la app también cambia, sin reiniciar.
      await _openSheet(tester);
      await _choose(tester, LocalePreference.en);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is FrIconButton && widget.semanticLabel == 'Back',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text(t.lobby.createRoom), findsOneWidget);
    });

    testWidgets('AC3: Auto pasa al idioma del teléfono', (tester) async {
      _setDeviceLocale(tester, const Locale('en', 'US'));
      _useStorage({PreferencesRepositoryImpl.localePreferenceKey: 'es'});
      await _openSettings(tester);
      expect(find.text('Ajustes'), findsOneWidget);

      await _openSheet(tester);
      await _choose(tester, LocalePreference.auto);

      expect(_sheet, findsNothing);
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(find.text('Settings'), findsOneWidget);
      expect(_inRow('Auto · English'), findsOneWidget);
      expect(_inRow('EN'), findsOneWidget);
      expect(await tester.runAsync(_reopen), LocalePreference.auto);
    });

    testWidgets('AC3: cerrar la hoja sin elegir no cambia nada', (
      tester,
    ) async {
      _setDeviceLocale(tester, const Locale('es', 'CO'));
      _useStorage({});
      await _openSettings(tester);

      await _openSheet(tester);
      await tester.tapAt(const Offset(195, 60));
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      expect(LocaleSettings.currentLocale, AppLocale.es);
      expect(
        _inRow(t.settings.language.autoValue(language: t.settings.language.es)),
        findsOneWidget,
      );
      expect(await tester.runAsync(_reopen), LocalePreference.auto);
    });

    testWidgets('AC5: si no se puede guardar avisa y el idioma y la fila '
        'siguen como estaban', (tester) async {
      _setDeviceLocale(tester, const Locale('es', 'CO'));
      SharedPreferencesAsyncPlatform.instance = _FailingWrites();
      await _openSettings(tester);

      await _openSheet(tester);
      await _choose(tester, LocalePreference.en);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is FrToast && widget.message == t.settings.saveError,
        ),
        findsOneWidget,
      );
      expect(LocaleSettings.currentLocale, AppLocale.es);
      expect(find.text('Ajustes'), findsOneWidget);
      expect(
        _inRow(t.settings.language.autoValue(language: t.settings.language.es)),
        findsOneWidget,
      );
      expect(_inRow('ES'), findsOneWidget);

      // Deja pasar el aviso hasta que se va.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
