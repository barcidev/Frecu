// AC2: CUANDO el sistema pide reducir el movimiento ENTONCES la firma de señal y el loader de onda dejan de animarse y quedan dibujados en un cuadro fijo, los botones no cambian de escala al presionarse, el campo no tiembla con un error y los pasos cambian sin resorte, sin ocultar el estado (cargando, foco, error y paso actual).
// AC4: CUANDO se escribe en un `FrField` ENTONCES muestra la etiqueta en mayúsculas y el contador `n/máx`, y no admite más caracteres que el máximo; con foco enciende el borde de señal y la línea inferior, y con error pinta el borde y la ayuda con el color de alerta.
// AC5: CUANDO se muestran los pasos de un recorrido ENTONCES el paso actual es una píldora de señal de 22 × 6 px, los anteriores van en `tx2` y los siguientes en `tx4`, y la píldora pasa al paso nuevo con el resorte `organic`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_steps.dart';

const colors = FrColors.dark;

Future<void> pumpHost(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
}) async {
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: child,
          ),
        ),
      ),
    ),
  );
}

Decoration decorationOf(WidgetTester tester, Key key) => tester
    .widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(key),
            matching: find.byType(DecoratedBox),
            matchRoot: true,
          )
          .first,
    )
    .decoration;

Color borderOf(WidgetTester tester) {
  final decoration = decorationOf(tester, const ValueKey('fr-field-box'));
  if (decoration is ShapeDecoration) {
    return (decoration.shape as OutlinedBorder).side.color;
  }
  return ((decoration as BoxDecoration).border! as Border).top.color;
}

double lineWidth(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('fr-field-line'))).width;

double boxLeft(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey('fr-field-box'))).left;

Size dotSize(WidgetTester tester, int index) =>
    tester.getSize(find.byKey(ValueKey('fr-step-$index')));

Color dotColor(WidgetTester tester, int index) =>
    (decorationOf(tester, ValueKey('fr-step-$index')) as BoxDecoration).color!;

FrField nameField({String? error}) => FrField(
  label: 'Nombre visible',
  help: 'Puedes cambiarlo cuando quieras',
  error: error,
  maxLength: 20,
);

void main() {
  group('FrField', () {
    testWidgets(
      'AC4: muestra la etiqueta en mayúsculas, el contador y no admite más del máximo',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await pumpHost(
          tester,
          FrField(
            label: 'Nombre visible',
            controller: controller,
            maxLength: 20,
          ),
        );

        expect(find.text('NOMBRE VISIBLE'), findsOneWidget);
        expect(find.text('0/20'), findsOneWidget);

        await tester.enterText(find.byType(EditableText), 'Jorge');
        await tester.pump();
        expect(find.text('5/20'), findsOneWidget);

        await tester.enterText(
          find.byType(EditableText),
          'abcdefghijklmnopqrstuvwxyz',
        );
        await tester.pump();
        expect(controller.text, 'abcdefghijklmnopqrst');
        expect(find.text('20/20'), findsOneWidget);
      },
    );

    testWidgets(
      'AC4: con foco enciende el borde de señal y la línea inferior',
      (tester) async {
        await pumpHost(tester, nameField());
        await tester.pumpAndSettle();

        expect(borderOf(tester), colors.line1);
        expect(lineWidth(tester), 0);

        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(borderOf(tester), colors.signal.withValues(alpha: 0.55));
        expect(lineWidth(tester), greaterThan(0));
      },
    );

    testWidgets(
      'AC4: con error pinta el borde y la ayuda con el color de alerta y tiembla',
      (tester) async {
        await pumpHost(tester, nameField());
        await tester.pumpAndSettle();
        final rest = boxLeft(tester);

        await pumpHost(tester, nameField(error: 'Escribe tu nombre'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect((boxLeft(tester) - rest).abs(), greaterThan(1));

        await tester.pumpAndSettle();
        expect(boxLeft(tester), closeTo(rest, 0.01));
        expect(borderOf(tester), colors.alert.withValues(alpha: 0.7));
        final help = tester.widget<Text>(find.text('Escribe tu nombre'));
        expect(help.style?.color, colors.alert);
        expect(find.text('Puedes cambiarlo cuando quieras'), findsNothing);
      },
    );

    testWidgets(
      'AC2: con movimiento reducido el error no tiembla y se sigue viendo',
      (tester) async {
        await pumpHost(tester, nameField(), reduceMotion: true);
        await tester.pumpAndSettle();
        final rest = boxLeft(tester);

        await pumpHost(
          tester,
          nameField(error: 'Escribe tu nombre'),
          reduceMotion: true,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(boxLeft(tester), closeTo(rest, 0.01));

        await tester.pumpAndSettle();
        expect(borderOf(tester), colors.alert.withValues(alpha: 0.7));
        expect(find.text('Escribe tu nombre'), findsOneWidget);
      },
    );

    testWidgets(
      'AC2: con movimiento reducido el foco sigue encendiendo el borde y la línea',
      (tester) async {
        await pumpHost(tester, nameField(), reduceMotion: true);
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(borderOf(tester), colors.signal.withValues(alpha: 0.55));
        expect(lineWidth(tester), greaterThan(0));
      },
    );
  });

  group('FrSteps', () {
    testWidgets(
      'AC5: el paso actual es una píldora de señal y los demás van en tx2 y tx4',
      (tester) async {
        await pumpHost(tester, const FrSteps(count: 3, current: 1));
        await tester.pumpAndSettle();

        expect(dotSize(tester, 0), const Size(6, 6));
        expect(dotColor(tester, 0), colors.tx2);
        expect(dotSize(tester, 1), const Size(22, 6));
        expect(dotColor(tester, 1), colors.signal);
        expect(dotSize(tester, 2), const Size(6, 6));
        expect(dotColor(tester, 2), colors.tx4);
      },
    );

    testWidgets('AC5: la píldora pasa al paso nuevo con el resorte organic', (
      tester,
    ) async {
      await pumpHost(tester, const FrSteps(count: 3, current: 1));
      await tester.pumpAndSettle();

      await pumpHost(tester, const FrSteps(count: 3, current: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 290));
      expect(dotSize(tester, 2).width, greaterThan(22));

      await tester.pumpAndSettle();
      expect(dotSize(tester, 2), const Size(22, 6));
      expect(dotColor(tester, 2), colors.signal);
      expect(dotSize(tester, 1), const Size(6, 6));
      expect(dotColor(tester, 1), colors.tx2);
    });

    testWidgets(
      'AC2: con movimiento reducido los pasos cambian sin resorte y muestran el paso actual',
      (tester) async {
        await pumpHost(
          tester,
          const FrSteps(count: 3, current: 1),
          reduceMotion: true,
        );
        await tester.pumpAndSettle();

        await pumpHost(
          tester,
          const FrSteps(count: 3, current: 2),
          reduceMotion: true,
        );
        await tester.pump();
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          expect(dotSize(tester, 2).width, lessThanOrEqualTo(22));
        }

        await tester.pumpAndSettle();
        expect(dotSize(tester, 2), const Size(22, 6));
        expect(dotColor(tester, 2), colors.signal);
      },
    );
  });
}
