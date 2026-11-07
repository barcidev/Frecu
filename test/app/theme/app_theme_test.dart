// AC1: CUANDO el sistema está en modo oscuro o claro ENTONCES la app usa el tema Portadora correspondiente: fondo `bg0`, texto `tx1`, `ColorScheme` y componentes Material construidos desde los tokens, y señal #C4E05C en ambos.
// AC2: CUANDO un widget lee `context.fr` ENTONCES obtiene los colores, la tipografía, el espacio, los radios y el movimiento del tema activo.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_motion.dart';
import 'package:frecu/core/design/tokens/fr_radii.dart';
import 'package:frecu/core/design/tokens/fr_space.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/i18n/strings.g.dart';

const signal = Color(0xFFC4E05C);

Future<ThemeData> pumpAppWith(
  WidgetTester tester,
  Brightness brightness,
) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(child: FrecuApp(appRouter: AppRouter())),
    ),
  );
  await tester.pumpAndSettle();
  return Theme.of(tester.element(find.byType(Scaffold).first));
}

void expectPortadora(ThemeData theme, FrColors colors, Brightness brightness) {
  expect(theme.brightness, brightness);
  expect(theme.scaffoldBackgroundColor, colors.bg0);
  expect(theme.colorScheme.primary, signal);
  expect(theme.colorScheme.onPrimary, colors.signalInk);
  expect(theme.colorScheme.surface, colors.bg1);
  expect(theme.colorScheme.onSurface, colors.tx1);
  expect(theme.colorScheme.error, colors.alert);
  expect(theme.textTheme.bodyMedium?.color, colors.tx1);
  expect(theme.textTheme.bodyMedium?.fontFamily, FrFonts.ui);
  expect(theme.extension<FrColors>()?.bg0, colors.bg0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => LocaleSettings.setLocale(AppLocale.es));

  group('AppTheme', () {
    testWidgets('AC1: con el sistema oscuro la app usa Portadora de noche', (
      tester,
    ) async {
      final theme = await pumpAppWith(tester, Brightness.dark);
      expectPortadora(theme, FrColors.dark, Brightness.dark);
    });

    testWidgets('AC1: con el sistema claro la app usa Portadora de día', (
      tester,
    ) async {
      final theme = await pumpAppWith(tester, Brightness.light);
      expectPortadora(theme, FrColors.light, Brightness.light);
    });

    for (final (name, theme, colors) in [
      ('noche', AppTheme.dark, FrColors.dark),
      ('día', AppTheme.light, FrColors.light),
    ]) {
      test('AC1: componentes Material desde los tokens ($name)', () {
        const states = <WidgetState>{};

        final filled = theme.filledButtonTheme.style!;
        expect(filled.backgroundColor?.resolve(states), signal);
        expect(filled.foregroundColor?.resolve(states), colors.signalInk);
        final shape = filled.shape?.resolve(states);
        expect(shape, isA<RoundedSuperellipseBorder>());
        expect(
          (shape! as RoundedSuperellipseBorder).borderRadius,
          BorderRadius.circular(FrRadii.standard.btn),
        );

        final text = theme.textButtonTheme.style!;
        expect(text.foregroundColor?.resolve(states), colors.signalFg);

        expect(theme.textSelectionTheme.cursorColor, colors.signalFg);
        final focused = theme.inputDecorationTheme.focusedBorder;
        expect(focused?.borderSide.color, colors.ledRing ?? signal);
        expect(theme.inputDecorationTheme.fillColor, colors.bg2);

        expect(theme.appBarTheme.backgroundColor, colors.bg0);
        expect(theme.cardTheme.color, colors.bg1);
        expect(theme.dividerTheme.color, colors.line1);
      });
    }

    test('AC1: el tema se interpola entre noche y día', () {
      final lerped = ThemeData.lerp(AppTheme.dark, AppTheme.light, 1);
      expect(lerped.extension<FrColors>()?.bg0, FrColors.light.bg0);
    });
  });

  group('context.fr', () {
    Future<FrTheme> readFr(WidgetTester tester, ThemeData theme) async {
      late FrTheme fr;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              fr = context.fr;
              return const SizedBox();
            },
          ),
        ),
      );
      return fr;
    }

    testWidgets('AC2: entrega los tokens del tema de noche', (tester) async {
      final fr = await readFr(tester, AppTheme.dark);
      expect(fr.colors.bg0, FrColors.dark.bg0);
      expect(fr.colors.signalFg, FrColors.dark.signalFg);
      expect(fr.type.display.fontSize, FrType.standard.display.fontSize);
      expect(fr.space.s4, FrSpace.standard.s4);
      expect(fr.radii.btn, FrRadii.standard.btn);
      expect(fr.motion.flow, FrMotion.standard.flow);
    });

    testWidgets('AC2: entrega los tokens del tema de día', (tester) async {
      final fr = await readFr(tester, AppTheme.light);
      expect(fr.colors.bg0, FrColors.light.bg0);
      expect(fr.colors.signalFg, const Color(0xFF0C0F0D));
      expect(fr.type.label.fontFamily, FrFonts.mono);
      expect(fr.space.s18, 72);
      expect(fr.radii.sheet, 40);
      expect(fr.motion.springPress.stiffness, 600);
    });
  });
}
