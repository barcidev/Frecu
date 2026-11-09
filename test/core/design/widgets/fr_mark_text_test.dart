// D8: CUANDO se destaca un texto con la señal (`FrMarkText`, `.cs` del prototipo) ENTONCES de noche va en lima y sin marcatexto, y de día va en tinta (`signalFg`) con el marcatexto verde detrás: una franja de 0,5 em que empieza 0,3 em sobre la línea base de cada renglón y ocupa su ancho (`--mark-deco: underline #C4E05C .5em`, `text-underline-offset: -.3em`).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/core/design/widgets/fr_mark_text.dart';

Future<void> pumpMark(
  WidgetTester tester,
  ThemeData theme,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Color? colorOf(WidgetTester tester, String text) =>
    (tester.renderObject<RenderParagraph>(find.text(text)).text as TextSpan)
        .style
        ?.color;

Finder get _mark => find.ancestor(
  of: find.byType(RichText),
  matching: find.byType(CustomPaint),
);

void main() {
  testWidgets('D8: de noche va en lima y sin marcatexto', (tester) async {
    await pumpMark(tester, AppTheme.dark, const FrMarkText('2 señales'));

    expect(colorOf(tester, '2 señales'), FrColors.dark.signalFg);
    expect(
      find.descendant(
        of: find.byType(FrMarkText),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('D8: de día va en tinta con la franja verde bajo la línea base', (
    tester,
  ) async {
    final style = FrType.standard.labelS;
    await pumpMark(
      tester,
      AppTheme.light,
      FrMarkText('Frecu encontrada', style: style),
    );

    expect(colorOf(tester, 'Frecu encontrada'), FrColors.light.signalFg);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Frecu encontrada'),
    );
    final shown = TextPainter(
      text: paragraph.text,
      textDirection: TextDirection.ltr,
    )..layout();
    addTearDown(shown.dispose);
    final baseline = shown.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final em = style.fontSize!;
    final width = paragraph.size.width;
    expect(
      find.descendant(
        of: find.byType(FrMarkText),
        matching: find.byType(CustomPaint),
      ),
      paints..something((method, arguments) {
        if (method != #drawRect) return false;
        final rect = arguments[0] as Rect;
        final paint = arguments[1] as Paint;
        // El espaciado entre letras corre el renglón medio espacio.
        return paint.color.toARGB32() ==
                FrColors.light.signalMark!.toARGB32() &&
            rect.left.abs() <= 1 &&
            (rect.width - width).abs() <= 1 &&
            (rect.top - (baseline - 0.3 * em)).abs() < 0.01 &&
            (rect.height - 0.5 * em).abs() < 0.01;
      }),
    );
    expect(FrMarkText.thickness, 0.5);
    expect(FrMarkText.rise, 0.3);
  });

  testWidgets('D8: de día marca cada renglón', (tester) async {
    await pumpMark(
      tester,
      AppTheme.light,
      const SizedBox(width: 80, child: FrMarkText('Código correcto entrando')),
    );

    var marks = 0;
    expect(
      _mark.first,
      paints..everything((method, arguments) {
        if (method == #drawRect) marks++;
        return true;
      }),
    );
    expect(marks, greaterThan(1));
  });
}
