// AC1: CUANDO la app arranca con el tema Claro u Oscuro guardado ENTONCES el primer cuadro ya se pinta con ese tema de Portadora, aunque el sistema esté en el otro, sin pasar por el tema del sistema.
// AC2: CUANDO el tema guardado es Auto, no hay nada guardado o no se pudieron leer las preferencias ENTONCES la app arranca igual y sigue el tema claro u oscuro del sistema, también si el sistema cambia con la app abierta.
// AC3: CUANDO el tema guardado cambia con la app abierta ENTONCES toda la app pasa a ese tema al instante, sin reiniciar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/theme_preference.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Almacenamiento del sistema que falla al leer.
final class _FailingStorage extends InMemorySharedPreferencesAsync {
  _FailingStorage() : super.empty();

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async => throw StateError('No se pudo leer $key');
}

/// Deja guardado [theme] antes de abrir la app; nulo si no hay nada guardado.
void _saveTheme(ThemePreference? theme) {
  SharedPreferencesAsyncPlatform.instance = theme == null
      ? InMemorySharedPreferencesAsync.empty()
      : InMemorySharedPreferencesAsync.withData({
          PreferencesRepositoryImpl.themePreferenceKey: theme.name,
        });
}

void _setSystemBrightness(WidgetTester tester, Brightness brightness) {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

/// Abre la app como `bootstrap`: con las preferencias ya leídas antes del
/// primer cuadro.
Future<ProviderContainer> _openApp(WidgetTester tester) async {
  final container = await createAppContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    TranslationProvider(
      child: UncontrolledProviderScope(
        container: container,
        child: FrecuApp(appRouter: AppRouter()),
      ),
    ),
  );
  return container;
}

/// Colores del tema que ve el contenido de la app.
ColorScheme _colorsOf(WidgetTester tester) {
  final router = find.byWidgetPredicate((widget) => widget is Router).first;
  return Theme.of(tester.element(router)).colorScheme;
}

void main() {
  group('Tema guardado al arrancar', () {
    testWidgets('AC1: con Oscuro guardado y el sistema claro, el primer '
        'cuadro ya es Portadora de noche', (tester) async {
      _setSystemBrightness(tester, Brightness.light);
      _saveTheme(ThemePreference.dark);

      await _openApp(tester);

      // Primer cuadro: no hubo cambio de tema, así que no hay animación.
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);

      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);
    });

    testWidgets('AC1: con Claro guardado y el sistema oscuro, el primer '
        'cuadro ya es Portadora de día', (tester) async {
      _setSystemBrightness(tester, Brightness.dark);
      _saveTheme(ThemePreference.light);

      await _openApp(tester);

      expect(_colorsOf(tester), AppTheme.light.colorScheme);

      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.light.colorScheme);
    });

    testWidgets('AC2: con Auto guardado sigue al sistema, también si cambia '
        'con la app abierta', (tester) async {
      _setSystemBrightness(tester, Brightness.dark);
      _saveTheme(ThemePreference.auto);

      await _openApp(tester);
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.light.colorScheme);
    });

    testWidgets('AC2: sin nada guardado sigue al sistema', (tester) async {
      _setSystemBrightness(tester, Brightness.dark);
      _saveTheme(null);

      await _openApp(tester);
      await tester.pumpAndSettle();

      expect(_colorsOf(tester), AppTheme.dark.colorScheme);
    });

    testWidgets('AC2: si falla la lectura abre igual y sigue al sistema', (
      tester,
    ) async {
      _setSystemBrightness(tester, Brightness.dark);
      SharedPreferencesAsyncPlatform.instance = _FailingStorage();

      await _openApp(tester);
      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.light.colorScheme);
    });

    testWidgets('AC2: sin almacenamiento disponible abre igual y sigue al '
        'sistema', (tester) async {
      _setSystemBrightness(tester, Brightness.dark);
      SharedPreferencesAsyncPlatform.instance = null;

      await _openApp(tester);
      await tester.pumpAndSettle();

      expect(_colorsOf(tester), AppTheme.dark.colorScheme);
    });

    testWidgets('AC3: al cambiar el tema guardado la app cambia al instante', (
      tester,
    ) async {
      _setSystemBrightness(tester, Brightness.light);
      _saveTheme(ThemePreference.light);

      final container = await _openApp(tester);
      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.light.colorScheme);

      final notifier = container.read(preferencesProvider.notifier);
      final dark = await notifier.setThemePreference(ThemePreference.dark);
      expect(dark.isSuccess, isTrue);
      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.dark.colorScheme);

      final auto = await notifier.setThemePreference(ThemePreference.auto);
      expect(auto.isSuccess, isTrue);
      await tester.pumpAndSettle();
      expect(_colorsOf(tester), AppTheme.light.colorScheme);
    });
  });
}
