// AC3: CUANDO se comparan los pares de texto y fondo de ambos temas ENTONCES `tx1`, `tx2`, `tx3` y `signalFg` sobre `bg0`, `bg1` y `bg2` tienen contraste ≥ 4,5:1, `signalInk` sobre `signal` también, los canales de participantes ≥ 3:1, y de día `signalFg` es tinta (#0C0F0D) mientras el verde queda para rellenos, halos y marcatexto.
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
