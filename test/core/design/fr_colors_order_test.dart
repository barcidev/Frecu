// AC3: CUANDO se comparan los pares de texto y fondo de ambos temas ENTONCES … de día `signalFg` es tinta (#0C0F0D) mientras el verde queda para rellenos, halos y marcatexto.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';

List<Object?> tokens(FrColors c) => [
  c.bg0,
  c.bg1,
  c.bg2,
  c.bg3,
  c.bg4,
  c.line1,
  c.line2,
  c.line3,
  c.spec,
  c.tx1,
  c.tx2,
  c.tx3,
  c.tx4,
  c.signal,
  c.signalInk,
  c.signalFg,
  c.signalHi,
  c.ink,
  c.washK,
  c.warn,
  c.alert,
  c.warnTx,
  c.alertTx,
  c.warnFg,
  c.alertFg,
  c.scrim,
  c.sheetA,
  c.sheetB,
  c.coreHi,
  c.coreLo,
  c.touch,
  c.shadow,
  c.p1,
  c.p2,
  c.p3,
  c.p4,
  c.p5,
  c.signalMark,
  c.ledRing,
];

void main() {
  test('AC3: copyWith y lerp conservan cada token en su lugar', () {
    for (final colors in [FrColors.dark, FrColors.light]) {
      expect(tokens(colors.copyWith()), tokens(colors));
    }
    expect(
      tokens(FrColors.dark.lerp(FrColors.light, 1)),
      tokens(FrColors.light),
    );
    expect(
      tokens(FrColors.light.lerp(FrColors.dark, 1)),
      tokens(FrColors.dark),
    );
  });
}
