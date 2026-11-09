// D8: CUANDO se dibuja la señal como trazo (firma propia, loader de onda y carga de los botones secundario y fantasma) ENTONCES de noche va en lima y de día en tinta (`signalFg`), y el brillo de la firma al hablar es verde en los dos temas (`engine.js`: `Theme.c('signal')` es `signal-fg` y `glow` devuelve el verde).
// P135: CUANDO se dibuja la marca de Frecu ENTONCES es la Lissajous 2:3 con fase 0,6, sin giro y deriva 0,12 trazada con 180 puntos (`DRAW.brand`), no la firma del nombre «frecu».
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';

const _green = Color(0xFFC4E05C);

Future<void> pumpIn(WidgetTester tester, ThemeData theme, Widget child) async {
  // Con movimiento reducido las animaciones quedan en un cuadro fijo.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

/// Mismo color en 8 bits por canal, sin contar la opacidad (`Paint` guarda
/// los canales en coma flotante de 32 bits).
bool sameRgb(Color a, Color b) =>
    a.toARGB32() & 0xFFFFFF == b.toARGB32() & 0xFFFFFF;

/// Predicado de `paints`: un trazo con [color] (sin contar la opacidad);
/// [blurred] elige el brillo (con `maskFilter`) o el trazo nítido.
PaintPatternPredicate strokeIn(Color color, {required bool blurred}) =>
    (method, arguments) {
      if (method != #drawPath && method != #drawLine) return false;
      final paint = arguments.last as Paint;
      return (paint.maskFilter != null) == blurred &&
          sameRgb(paint.color, color);
    };

Finder painterOf(Type type) => find
    .descendant(of: find.byType(type), matching: find.byType(CustomPaint))
    .first;

void main() {
  group('D8 · la señal como trazo', () {
    for (final (name, theme, colors) in [
      ('noche', AppTheme.dark, FrColors.dark),
      ('día', AppTheme.light, FrColors.light),
    ]) {
      testWidgets('D8: la firma propia va en signalFg y brilla en verde '
          '($name)', (tester) async {
        await pumpIn(
          tester,
          theme,
          const SignalSignature(
            name: 'Jorge',
            size: 120,
            mode: SignatureMode.speak,
            level: 1,
          ),
        );

        final painter = painterOf(SignalSignature);
        expect(
          painter,
          paints..something(strokeIn(colors.signalFg, blurred: false)),
        );
        expect(painter, paints..something(strokeIn(_green, blurred: true)));
      });

      testWidgets('D8: la firma de otro canal brilla en su color ($name)', (
        tester,
      ) async {
        await pumpIn(
          tester,
          theme,
          SignalSignature(
            name: 'Ana',
            size: 120,
            color: colors.p2,
            mode: SignatureMode.speak,
            level: 1,
          ),
        );

        expect(
          painterOf(SignalSignature),
          paints..something(strokeIn(colors.p2, blurred: true)),
        );
      });

      testWidgets('D8: la onda de carga va en signalFg ($name)', (
        tester,
      ) async {
        await pumpIn(tester, theme, const WaveLoader());

        expect(
          painterOf(WaveLoader),
          paints..something(strokeIn(colors.signalFg, blurred: false)),
        );
      });

      testWidgets('D8: la carga del secundario y del fantasma va en signalFg '
          '($name)', (tester) async {
        for (final variant in [
          FrButtonVariant.secondary,
          FrButtonVariant.ghost,
        ]) {
          await pumpIn(
            tester,
            theme,
            FrButton(
              label: 'Abrir',
              onPressed: () {},
              variant: variant,
              loading: true,
            ),
          );

          expect(
            tester.widget<WaveLoader>(find.byType(WaveLoader)).color,
            colors.signalFg,
            reason: '$variant',
          );
        }
      });
    }

    test('D8: de día la tinta de la firma no es el verde', () {
      expect(FrColors.light.signalFg, isNot(_green));
      expect(FrColors.light.signalFg, const Color(0xFF0C0F0D));
    });
  });

  group('Marca de Frecu', () {
    test('P135: la marca es la Lissajous 2:3 con fase 0,6 del prototipo', () {
      const brand = SignatureParams.brand;
      expect(brand.a, 2);
      expect(brand.b, 3);
      expect(brand.phase, 0.6);
      expect(brand.rot, 0);
      expect(brand.drift, 0.12);
      expect(brand, isNot(SignatureParams.fromName('frecu')));
    });

    testWidgets('P135: SignalSignature.brand dibuja la marca con 180 puntos', (
      tester,
    ) async {
      await pumpIn(
        tester,
        AppTheme.dark,
        const SignalSignature.brand(size: 26),
      );

      final brand = tester.widget<SignalSignature>(
        find.byType(SignalSignature),
      );
      expect(brand.params, SignatureParams.brand);
      expect(brand.points, 180);
      expect(tester.getSize(find.byType(SignalSignature)), const Size(26, 26));
      expect(
        painterOf(SignalSignature),
        paints..something(strokeIn(FrColors.dark.signalFg, blurred: false)),
      );
    });
  });
}
