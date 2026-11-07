// AC3: CUANDO se pinta un `FrIcon` ENTONCES usa puntas y uniones redondeadas con el grosor del prototipo según su tamaño, rellena solo las formas con relleno (`dot`), y toma el color, la opacidad y el tamaño de `IconTheme` salvo que reciba los suyos; con `semanticLabel` se anuncia con ese texto.
// AC4: CUANDO un `FrButton` o un `FrIconButton` se crea con `.drawn` y un ícono de `FrIcons` ENTONCES lo dibuja a 22 px con el color de primer plano de su variante, y con `IconData` se comportan como antes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';

const ink = Color(0xFF123456);

Future<void> pumpBare(WidgetTester tester, Widget child) => tester.pumpWidget(
  Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

Future<void> pumpHost(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  ),
);

/// Lo que pinta el [index]-ésimo `FrIcon` de la pantalla.
RenderObject paintOf(WidgetTester tester, {int index = 0}) =>
    tester.renderObject(
      find
          .descendant(
            of: find.byType(FrIcon).at(index),
            matching: find.byType(CustomPaint),
          )
          .first,
    );

bool roundStroke(Symbol method, List<dynamic> arguments) {
  if (method != #drawPath) return false;
  final paint = arguments[1] as Paint;
  return paint.style == PaintingStyle.stroke &&
      paint.strokeCap == StrokeCap.round &&
      paint.strokeJoin == StrokeJoin.round;
}

void main() {
  group('FrIcon', () {
    testWidgets(
      'AC3: escala la rejilla de 24 y traza con puntas y uniones redondas',
      (tester) async {
        await pumpBare(tester, const FrIcon(FrIcons.mic, size: 22, color: ink));
        expect(tester.getSize(find.byType(FrIcon)), const Size(22, 22));
        expect(
          paintOf(tester),
          paints
            ..scale(x: 22 / 24, y: 22 / 24)
            ..path(style: PaintingStyle.stroke, strokeWidth: 1.6, color: ink),
        );
        expect(paintOf(tester), paints..something(roundStroke));
      },
    );

    test('AC3: el grosor sigue al prototipo según el tamaño', () {
      expect(FrIcon.strokeFor(12), 1.8);
      expect(FrIcon.strokeFor(16), 1.8);
      expect(FrIcon.strokeFor(18), 1.6);
      expect(FrIcon.strokeFor(22), 1.6);
      expect(FrIcon.strokeFor(27), 1.6);
      expect(FrIcon.strokeFor(28), 1.5);
      expect(FrIcon.strokeFor(33), 1.5);
      expect(FrIcon.strokeFor(34), 1.4);
      expect(FrIcon.strokeFor(48), 1.4);
    });

    testWidgets('AC3: pinta con el grosor de su tamaño o con el que recibe', (
      tester,
    ) async {
      await pumpBare(tester, const FrIcon(FrIcons.plus, size: 34, color: ink));
      expect(paintOf(tester), paints..path(strokeWidth: 1.4));

      await pumpBare(tester, const FrIcon(FrIcons.plus, size: 16, color: ink));
      expect(paintOf(tester), paints..path(strokeWidth: 1.8));

      await pumpBare(
        tester,
        const FrIcon(FrIcons.plus, size: 16, color: ink, strokeWidth: 2),
      );
      expect(paintOf(tester), paints..path(strokeWidth: 2));
    });

    testWidgets('AC3: solo rellena las formas con relleno', (tester) async {
      await pumpBare(tester, const FrIcon(FrIcons.mic, color: ink));
      expect(paintOf(tester), isNot(paints..path(style: PaintingStyle.fill)));

      await pumpBare(tester, const FrIcon(FrIcons.dot, color: ink));
      expect(
        paintOf(tester),
        paints
          ..path(style: PaintingStyle.fill, color: ink)
          ..path(style: PaintingStyle.stroke, color: ink),
      );
    });

    testWidgets('AC3: toma color, opacidad y tamaño de IconTheme', (
      tester,
    ) async {
      await pumpBare(
        tester,
        const IconTheme(
          data: IconThemeData(color: Color(0xFF00FF00), size: 30, opacity: 0.5),
          child: FrIcon(FrIcons.mic),
        ),
      );
      expect(tester.getSize(find.byType(FrIcon)), const Size(30, 30));
      expect(
        paintOf(tester),
        paints
          ..scale(x: 30 / 24, y: 30 / 24)
          ..path(
            color: const Color(0xFF00FF00).withValues(alpha: 0.5),
            strokeWidth: 1.5,
          ),
      );
    });

    testWidgets('AC3: sin IconTheme propio usa 24 px y el color por defecto', (
      tester,
    ) async {
      await pumpBare(tester, const FrIcon(FrIcons.mic));
      expect(tester.getSize(find.byType(FrIcon)), const Size(24, 24));
      expect(
        paintOf(tester),
        paints..path(color: const IconThemeData.fallback().color),
      );
    });

    testWidgets('AC3: el color y el tamaño propios mandan sobre IconTheme', (
      tester,
    ) async {
      await pumpBare(
        tester,
        const IconTheme(
          data: IconThemeData(color: Color(0xFF00FF00), size: 30),
          child: FrIcon(FrIcons.mic, size: 16, color: ink),
        ),
      );
      expect(tester.getSize(find.byType(FrIcon)), const Size(16, 16));
      expect(paintOf(tester), paints..path(color: ink, strokeWidth: 1.8));
    });

    testWidgets('AC3: con semanticLabel se anuncia con ese texto', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpBare(
        tester,
        const FrIcon(FrIcons.mic, semanticLabel: 'Micrófono'),
      );
      expect(find.bySemanticsLabel('Micrófono'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('Botones con íconos propios', () {
    testWidgets(
      'AC4: FrIconButton.drawn dibuja el ícono a 22 px con su primer plano',
      (tester) async {
        var taps = 0;
        await pumpHost(
          tester,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FrIconButton.drawn(
                icon: FrIcons.back,
                semanticLabel: 'Atrás',
                onPressed: () => taps++,
              ),
              FrIconButton.drawn(
                icon: FrIcons.close,
                semanticLabel: 'Cerrar',
                variant: FrIconButtonVariant.danger,
                onPressed: () {},
              ),
            ],
          ),
        );
        final icons = tester.widgetList<FrIcon>(find.byType(FrIcon)).toList();
        expect(icons.map((icon) => icon.icon), [FrIcons.back, FrIcons.close]);
        expect(tester.getSize(find.byType(FrIcon).at(0)), const Size(22, 22));
        expect(tester.getSize(find.byType(FrIcon).at(1)), const Size(22, 22));
        expect(
          paintOf(tester),
          paints..path(color: FrColors.dark.tx1, strokeWidth: 1.6),
        );
        expect(
          paintOf(tester, index: 1),
          paints..path(color: FrColors.dark.alert),
        );
        expect(find.byType(Icon), findsNothing);

        await tester.tap(find.byType(FrIconButton).first);
        await tester.pumpAndSettle();
        expect(taps, 1);
      },
    );

    testWidgets(
      'AC4: FrButton.drawn dibuja sus íconos a los lados del texto a 22 px',
      (tester) async {
        var taps = 0;
        await pumpHost(
          tester,
          FrButton.drawn(
            label: 'Seguir',
            icon: FrIcons.check,
            trailingIcon: FrIcons.arrow,
            onPressed: () => taps++,
          ),
        );
        final icons = find.byType(FrIcon);
        expect(icons, findsNWidgets(2));
        expect(tester.widgetList<FrIcon>(icons).map((icon) => icon.icon), [
          FrIcons.check,
          FrIcons.arrow,
        ]);
        final label = tester.getRect(find.text('Seguir'));
        expect(tester.getRect(icons.at(0)).right, lessThan(label.left));
        expect(tester.getRect(icons.at(1)).left, greaterThan(label.right));
        expect(tester.getSize(icons.at(0)), const Size(22, 22));
        expect(tester.getSize(icons.at(1)), const Size(22, 22));
        expect(paintOf(tester), paints..path(color: FrColors.dark.signalInk));
        expect(
          paintOf(tester, index: 1),
          paints..path(color: FrColors.dark.signalInk),
        );

        await tester.tap(find.byType(FrButton));
        await tester.pumpAndSettle();
        expect(taps, 1);
      },
    );

    testWidgets('AC4: con IconData siguen dibujando el Icon de antes', (
      tester,
    ) async {
      await pumpHost(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrIconButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Atrás',
              onPressed: () {},
            ),
            FrButton(label: 'Crear', icon: Icons.add, onPressed: () {}),
          ],
        ),
      );
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byType(FrIcon), findsNothing);
    });
  });
}
