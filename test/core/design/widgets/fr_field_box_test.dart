// P133: CUANDO se muestra un `FrField` con el tema de la app (claro u oscuro), con o sin foco ENTONCES el texto no hereda ningún borde ni relleno del `inputDecorationTheme` (solo se ve la caja del campo, sin un segundo borde ni un segundo aro de foco), y la caja lleva el filo especular arriba salvo con error.
// P135: CUANDO se escribe en un `FrField` ENTONCES el texto normal va en Archivo de 17 px con peso 500, el mono en Martian Mono de 16 px y el contador `n/máx` va dentro de la caja, a la derecha, en mono de 11 px y `tx3` (`.field-box` del prototipo); con error, la ayuda va en `alertFg`, que de día llega a 4,5:1 sobre el fondo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_specular.dart';

Future<void> pumpField(
  WidgetTester tester,
  Widget field, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: field,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _box => find.byKey(const ValueKey('fr-field-box'));

/// Decoración efectiva del texto: la del campo con lo que aporta el tema.
InputDecoration effectiveDecoration(WidgetTester tester) => tester
    .widget<InputDecorator>(
      find.descendant(
        of: find.byType(FrField),
        matching: find.byType(InputDecorator),
      ),
    )
    .decoration;

void expectNoThemeBox(WidgetTester tester, String reason) {
  final decoration = effectiveDecoration(tester);
  for (final (name, border) in [
    ('border', decoration.border),
    ('enabledBorder', decoration.enabledBorder),
    ('focusedBorder', decoration.focusedBorder),
    ('disabledBorder', decoration.disabledBorder),
    ('errorBorder', decoration.errorBorder),
    ('focusedErrorBorder', decoration.focusedErrorBorder),
  ]) {
    expect(border, InputBorder.none, reason: '$name ($reason)');
  }
  expect(decoration.filled, isFalse, reason: reason);
  expect(decoration.contentPadding, EdgeInsets.zero, reason: reason);
}

/// Llamadas de pintura del filo especular de la caja.
Iterable<FrSpecularPainter> specularOf(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.ancestor(of: _box, matching: find.byType(CustomPaint)),
    )
    .map((paint) => paint.foregroundPainter)
    .whereType<FrSpecularPainter>();

void main() {
  group('FrField sin doble borde', () {
    for (final (name, theme) in [
      ('noche', AppTheme.dark),
      ('día', AppTheme.light),
    ]) {
      testWidgets(
        'P133: el tema no pinta un segundo borde, sin foco ni con foco ($name)',
        (tester) async {
          // El tema sí define bordes: son los que antes se colaban.
          expect(
            theme.inputDecorationTheme.enabledBorder,
            isA<OutlineInputBorder>(),
          );
          expect(
            theme.inputDecorationTheme.focusedBorder,
            isA<OutlineInputBorder>(),
          );
          await pumpField(
            tester,
            const FrField(label: 'Nombre visible', maxLength: 20),
            theme: theme,
          );

          expectNoThemeBox(tester, 'sin foco');

          await tester.tap(find.byType(EditableText));
          await tester.pumpAndSettle();

          expectNoThemeBox(tester, 'con foco');
          expect(
            find.descendant(
              of: find.byType(InputDecorator),
              matching: find.byType(DecoratedBox),
            ),
            findsNothing,
          );
        },
      );
    }

    testWidgets('P133: la caja lleva el filo especular y con error no', (
      tester,
    ) async {
      await pumpField(tester, const FrField(label: 'Nombre visible'));

      expect(specularOf(tester).single.color, FrColors.dark.spec);
      expect(specularOf(tester).single.depth, 1);

      await pumpField(
        tester,
        const FrField(label: 'Nombre visible', error: 'Escribe tu nombre'),
      );

      expect(specularOf(tester).single.color.a, 0);
    });
  });

  group('FrField como el prototipo', () {
    testWidgets('P135: el texto normal es Archivo de 17 px con peso 500', (
      tester,
    ) async {
      await pumpField(tester, const FrField(label: 'Nombre visible'));

      final style = tester.widget<TextField>(find.byType(TextField)).style!;
      expect(style.fontSize, 17);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.fontVariations, contains(const FontVariation.weight(500)));
    });

    testWidgets('P135: el texto mono es Martian Mono de 16 px', (tester) async {
      await pumpField(
        tester,
        const FrField(label: 'IP del anfitrión', mono: true),
      );

      final style = tester.widget<TextField>(find.byType(TextField)).style!;
      expect(style.fontFamily, 'Martian Mono');
      expect(style.fontSize, 16);
    });

    testWidgets(
      'P135: el contador va dentro de la caja, a la derecha del texto',
      (tester) async {
        await pumpField(
          tester,
          const FrField(label: 'Nombre visible', maxLength: 20),
        );
        await tester.enterText(find.byType(EditableText), 'Jorge');
        await tester.pump();

        final counter = find.descendant(of: _box, matching: find.text('5/20'));
        expect(counter, findsOneWidget);
        final box = tester.getRect(_box);
        final count = tester.getRect(counter);
        // 16 px de relleno y 1 px del borde de la caja.
        expect(count.right, closeTo(box.right - 17, 0.5));
        expect(count.center.dy, closeTo(box.center.dy, 1));
        expect(
          count.left,
          greaterThan(tester.getRect(find.byType(EditableText)).right),
        );
        final style = tester.widget<Text>(counter).style!;
        expect(style.fontFamily, 'Martian Mono');
        expect(style.fontSize, 11);
        expect(style.color, FrColors.dark.tx3);
      },
    );

    testWidgets('P135: de día la ayuda de error va en alertFg', (tester) async {
      await pumpField(
        tester,
        const FrField(label: 'Nombre visible', error: 'Escribe tu nombre'),
        theme: AppTheme.light,
      );

      final help = tester.widget<Text>(find.text('Escribe tu nombre'));
      expect(help.style?.color, FrColors.light.alertFg);
    });
  });
}
