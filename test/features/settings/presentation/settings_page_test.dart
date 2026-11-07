// AC1: CUANDO se abre Ajustes ENTONCES se ve en Portadora (`FrScaffold`) con el botón Atrás, el título, la tarjeta del nombre, las secciones Voz y Apariencia con el modo de habla y el tema guardados ya elegidos y el pie «100 % local · sin internet», con todos los textos desde slang en español y en inglés; Atrás vuelve a la pantalla anterior.
// AC2: CUANDO el usuario elige Auto, Claro u Oscuro en el selector de tema ENTONCES toda la app pasa a ese tema de Portadora al instante (Auto sigue al sistema) y la elección se conserva al reabrir la app.
// AC3: CUANDO el usuario elige PTT o Abierto en el modo de habla por defecto ENTONCES queda elegido y se conserva al reabrir la app.
// AC4: CUANDO no se puede guardar el tema o el modo de habla ENTONCES aparece un aviso de error (`FrToast`) y el selector sigue en el valor guardado.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/presentation/pages/settings_page.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
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

void _setSystemBrightness(WidgetTester tester, Brightness brightness) {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

/// Abre la app como `bootstrap` en un teléfono de 390 × 844 con movimiento
/// reducido (la firma no anima sin fin) y entra a Ajustes.
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

/// Preferencias que lee la app al reabrirse sobre el mismo almacenamiento.
Future<Preferences?> _reopen() async {
  final container = await createAppContainer();
  addTearDown(container.dispose);
  return container.read(preferencesProvider).value;
}

/// Colores del tema que ve Ajustes.
ColorScheme _colorsOf(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(SettingsPage))).colorScheme;

FrSegmented<ThemePreference> _themeSelector(WidgetTester tester) =>
    tester.widget(find.byType(FrSegmented<ThemePreference>));

FrSegmented<TalkMode> _talkModeSelector(WidgetTester tester) =>
    tester.widget(find.byType(FrSegmented<TalkMode>));

Finder get _backButton => find.byWidgetPredicate(
  (widget) => widget is FrIconButton && widget.semanticLabel == t.settings.back,
);

/// Aviso visible con [message].
Finder _toast(String message) => find.byWidgetPredicate(
  (widget) => widget is FrToast && widget.message == message,
);

/// Deja pasar el aviso hasta que se va.
Future<void> _dismissToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  group('Ajustes', () {
    testWidgets('AC1: muestra Portadora con su cabecera, las secciones Voz y '
        'Apariencia con lo guardado elegido y el pie', (tester) async {
      _useStorage({
        PreferencesRepositoryImpl.themePreferenceKey: ThemePreference.dark.name,
        PreferencesRepositoryImpl.defaultTalkModeKey: TalkMode.openMic.name,
      });

      await _openSettings(tester);

      final page = find.byType(SettingsPage);
      expect(page, findsOneWidget);
      expect(
        find.descendant(of: page, matching: find.byType(FrScaffold)),
        findsOneWidget,
      );
      expect(find.byType(AppBar), findsNothing);
      expect(_backButton, findsOneWidget);
      expect(find.text(t.settings.title), findsOneWidget);

      expect(find.text(t.settings.voice.toUpperCase()), findsOneWidget);
      expect(find.text(t.settings.defaultTalkMode), findsOneWidget);
      expect(find.text(t.settings.defaultTalkModeHelp), findsOneWidget);
      expect(
        find.text(t.settings.talkMode.pushToTalk.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(t.settings.talkMode.openMic.toUpperCase()),
        findsOneWidget,
      );
      expect(_talkModeSelector(tester).value, TalkMode.openMic);

      expect(find.text(t.settings.appearance.toUpperCase()), findsOneWidget);
      expect(find.text(t.settings.theme), findsOneWidget);
      expect(find.text(t.settings.themeHelp), findsOneWidget);
      for (final label in [
        t.settings.themeMode.auto,
        t.settings.themeMode.light,
        t.settings.themeMode.dark,
      ]) {
        expect(find.text(label.toUpperCase()), findsOneWidget);
      }
      expect(_themeSelector(tester).value, ThemePreference.dark);

      expect(find.text(t.settings.footer), findsOneWidget);
    });

    testWidgets('AC1: Atrás vuelve a la pantalla anterior', (tester) async {
      _useStorage({});
      await _openSettings(tester);

      await tester.tap(_backButton);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text(t.lobby.createRoom), findsOneWidget);
    });

    testWidgets('AC1: en inglés los textos salen de la traducción en', (
      tester,
    ) async {
      // El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
      _useStorage({});

      await _openSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('VOICE'), findsOneWidget);
      expect(find.text('Default talk mode'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('LIGHT'), findsOneWidget);
      expect(find.text('DARK'), findsOneWidget);
      expect(find.text('100% local · no internet'), findsOneWidget);
      expect(
        _backButton.evaluate().single.widget,
        isA<FrIconButton>().having(
          (button) => button.semanticLabel,
          'semanticLabel',
          'Back',
        ),
      );
    });

    testWidgets('AC2: Claro, Oscuro y Auto cambian toda la app al instante y '
        'se conservan al reabrir', (tester) async {
      _setSystemBrightness(tester, Brightness.dark);
      _useStorage({});
      await _openSettings(tester);
      expect(_themeSelector(tester).value, ThemePreference.auto);
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);

      await tester.tap(find.text(t.settings.themeMode.light.toUpperCase()));
      await tester.pumpAndSettle();
      expect(_themeSelector(tester).value, ThemePreference.light);
      expect(_colorsOf(tester), AppTheme.light.colorScheme);
      expect((await _reopen())?.themePreference, ThemePreference.light);

      await tester.tap(find.text(t.settings.themeMode.dark.toUpperCase()));
      await tester.pumpAndSettle();
      expect(_themeSelector(tester).value, ThemePreference.dark);
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);
      expect((await _reopen())?.themePreference, ThemePreference.dark);

      // Con Oscuro elegido, el sistema en claro no cambia nada; Auto lo sigue.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);

      await tester.tap(find.text(t.settings.themeMode.auto.toUpperCase()));
      await tester.pumpAndSettle();
      expect(_themeSelector(tester).value, ThemePreference.auto);
      expect(_colorsOf(tester), AppTheme.light.colorScheme);
      expect((await _reopen())?.themePreference, ThemePreference.auto);
    });

    testWidgets('AC3: PTT o Abierto quedan elegidos y se conservan al '
        'reabrir', (tester) async {
      _useStorage({});
      await _openSettings(tester);
      expect(_talkModeSelector(tester).value, TalkMode.pushToTalk);

      await tester.tap(find.text(t.settings.talkMode.openMic.toUpperCase()));
      await tester.pumpAndSettle();
      expect(_talkModeSelector(tester).value, TalkMode.openMic);
      expect((await _reopen())?.defaultTalkMode, TalkMode.openMic);

      await tester.tap(find.text(t.settings.talkMode.pushToTalk.toUpperCase()));
      await tester.pumpAndSettle();
      expect(_talkModeSelector(tester).value, TalkMode.pushToTalk);
      expect((await _reopen())?.defaultTalkMode, TalkMode.pushToTalk);
    });

    testWidgets('AC4: si no se puede guardar avisa y cada selector sigue en '
        'lo guardado', (tester) async {
      _setSystemBrightness(tester, Brightness.dark);
      SharedPreferencesAsyncPlatform.instance = _FailingWrites();
      await _openSettings(tester);
      expect(_toast(t.settings.saveError), findsNothing);

      await tester.tap(find.text(t.settings.themeMode.light.toUpperCase()));
      await tester.pumpAndSettle();
      expect(_toast(t.settings.saveError), findsOneWidget);
      expect(_themeSelector(tester).value, ThemePreference.auto);
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);
      await _dismissToast(tester);
      expect(_toast(t.settings.saveError), findsNothing);

      await tester.tap(find.text(t.settings.talkMode.openMic.toUpperCase()));
      await tester.pumpAndSettle();
      expect(_toast(t.settings.saveError), findsOneWidget);
      expect(_talkModeSelector(tester).value, TalkMode.pushToTalk);
      await _dismissToast(tester);
    });
  });
}
