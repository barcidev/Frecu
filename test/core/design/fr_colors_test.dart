// AC3: CUANDO se comparan los pares de texto y fondo de ambos temas ENTONCES `tx1`, `tx2`, `tx3` y `signalFg` sobre `bg0`, `bg1` y `bg2` tienen contraste ≥ 4,5:1, `signalInk` sobre `signal` también, los canales de participantes ≥ 3:1, y de día `signalFg` es tinta (#0C0F0D) mientras el verde queda para rellenos, halos y marcatexto.
// R4: CUANDO se usa un color de estado como texto pequeño (ayuda de error, etiqueta de aviso, aviso, botón de alerta y píldora) ENTONCES llega a 4,5:1 sobre su fondo o su lavado en ambos temas; de día el texto de error y de aviso usa los tokens de texto (`alertFg` y `warnFg`).
// D8: CUANDO algo se traza con la señal ENTONCES su brillo es el verde también de día, cuando el trazo es tinta (`glowOf`).
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';

/// Contraste WCAG 2.x entre dos colores opacos.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const signal = Color(0xFFC4E05C);
  const themes = {'noche': FrColors.dark, 'día': FrColors.light};

  group('FrColors', () {
    for (final MapEntry(key: name, value: colors) in themes.entries) {
      test('AC3: textos sobre fondos con contraste ≥ 4,5:1 ($name)', () {
        final texts = {
          'tx1': colors.tx1,
          'tx2': colors.tx2,
          'tx3': colors.tx3,
          'signalFg': colors.signalFg,
        };
        final backgrounds = {
          'bg0': colors.bg0,
          'bg1': colors.bg1,
          'bg2': colors.bg2,
        };
        for (final text in texts.entries) {
          for (final background in backgrounds.entries) {
            expect(
              contrast(text.value, background.value),
              greaterThanOrEqualTo(4.5),
              reason: '${text.key} sobre ${background.key} ($name)',
            );
          }
        }
        expect(
          contrast(colors.signalInk, colors.signal),
          greaterThanOrEqualTo(4.5),
          reason: 'signalInk sobre signal ($name)',
        );
      });

      // R4: el texto pequeño en color de estado también llega a 4,5:1, sobre
      // los fondos y sobre los lavados en los que se usa.
      test('R4: textos de estado con contraste ≥ 4,5:1 ($name)', () {
        final surfaces = {
          'bg0': colors.bg0,
          'bg1': colors.bg1,
          'bg2': colors.bg2,
          'sheetA': colors.sheetA,
          'sheetB': colors.sheetB,
        };
        Color wash(Color tint, double alpha, Color under) =>
            Color.alphaBlend(tint.withValues(alpha: alpha), under);
        final pairs = <String, (Color, Color)>{
          // Ayuda de error de `FrField` y estilo de error del tema.
          for (final surface in surfaces.entries)
            'alertFg sobre ${surface.key}': (colors.alertFg, surface.value),
          // `FrTag` de aviso: lavado al 12 % sobre las tarjetas y las hojas.
          for (final surface in surfaces.entries)
            'warnFg sobre el lavado de aviso en ${surface.key}': (
              colors.warnFg,
              wash(colors.warn, 0.12, surface.value),
            ),
          // `FrBanner`: lavado al 8 %.
          for (final surface in surfaces.entries) ...{
            'warnTx sobre el aviso en ${surface.key}': (
              colors.warnTx,
              wash(colors.warn, 0.08, surface.value),
            ),
            'alertTx sobre la alerta en ${surface.key}': (
              colors.alertTx,
              wash(colors.alert, 0.08, surface.value),
            ),
          },
          // `FrButton` de alerta: lavado al 12 %.
          for (final surface in surfaces.entries)
            'alertTx sobre el botón de alerta en ${surface.key}': (
              colors.alertTx,
              wash(colors.alert, 0.12, surface.value),
            ),
          // `FrPill` de aviso y de alerta: texto sobre su fondo `bg1`.
          'warn sobre la píldora': (colors.warn, colors.bg1),
          'alert sobre la píldora': (colors.alert, colors.bg1),
        };
        for (final MapEntry(key: pair, value: (text, background))
            in pairs.entries) {
          expect(
            contrast(text, background),
            greaterThanOrEqualTo(4.5),
            reason: '$pair ($name)',
          );
        }
      });

      test('AC3: canales de participantes con contraste ≥ 3:1 ($name)', () {
        expect(colors.channels, hasLength(5));
        for (final (index, channel) in colors.channels.indexed) {
          for (final background in [colors.bg0, colors.bg1, colors.bg2]) {
            expect(
              contrast(channel, background),
              greaterThanOrEqualTo(3),
              reason: 'p${index + 1} ($name)',
            );
          }
        }
      });
    }

    test('R4: de día el texto de error y de aviso usa los tokens de texto', () {
      expect(FrColors.dark.alertFg, FrColors.dark.alert);
      expect(FrColors.dark.warnFg, FrColors.dark.warn);
      expect(FrColors.light.alertFg, FrColors.light.alertTx);
      expect(FrColors.light.warnFg, FrColors.light.warnTx);
    });

    test('D8: el brillo de la señal siempre es verde', () {
      for (final colors in themes.values) {
        expect(colors.glowOf(colors.signalFg), signal);
        expect(colors.glowOf(colors.p2), colors.p2);
        expect(colors.glowOf(colors.warn), colors.warn);
      }
      final half = FrColors.light.glowOf(
        FrColors.light.signalFg.withValues(alpha: 0.5),
      );
      expect(half.withValues(alpha: 1), signal);
      expect(half.a, closeTo(0.5, 1e-6));
    });

    test('AC3: el mismo verde de señal en noche y día', () {
      expect(FrColors.dark.signal, signal);
      expect(FrColors.light.signal, signal);
    });

    test('AC3: de noche la señal es letra y no hay marcatexto', () {
      expect(FrColors.dark.signalFg, signal);
      expect(FrColors.dark.signalMark, isNull);
      expect(FrColors.dark.ledRing, isNull);
    });

    test(
      'AC3: de día signalFg es tinta y el verde queda de relleno y marcatexto',
      () {
        expect(FrColors.light.signalFg, const Color(0xFF0C0F0D));
        expect(FrColors.light.signalMark, signal);
        expect(FrColors.light.ledRing, const Color(0xFF0C0F0D));
        expect(contrast(signal, FrColors.light.bg1), lessThan(3));
      },
    );

    test('AC3: copyWith y lerp entre noche y día', () {
      final changed = FrColors.dark.copyWith(tx1: const Color(0xFF123456));
      expect(changed.tx1, const Color(0xFF123456));
      expect(changed.bg0, FrColors.dark.bg0);

      final lerped = FrColors.dark.lerp(FrColors.light, 1);
      expect(lerped.bg0, FrColors.light.bg0);
      expect(lerped.signalFg, FrColors.light.signalFg);
      expect(lerped.washK, FrColors.light.washK);
    });
  });
}
