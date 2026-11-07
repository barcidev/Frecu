// AC2: CUANDO el sistema pide reducir el movimiento ENTONCES la firma de señal y el loader de onda dejan de animarse y quedan dibujados en un cuadro fijo, los botones no cambian de escala al presionarse, el campo no tiembla con un error y los pasos cambian sin resorte, sin ocultar el estado (cargando, foco, error y paso actual).
// AC3: CUANDO se presiona un `FrButton` o un `FrIconButton` ENTONCES se hunde con el resorte `press` (escala 0,965 o 0,92), se ilumina desde el punto del dedo y llama a su acción al soltar; sin acción se ve al 38 % y no responde, y cargando muestra el loader de onda en lugar del texto, conserva su etiqueta accesible y no responde.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';

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
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// Mide la escala visible de [finder] presionando en [at] durante 500 ms.
Future<double> pressedScale(
  WidgetTester tester,
  Finder finder,
  Offset at,
) async {
  final rest = tester.getRect(finder).width;
  final gesture = await tester.startGesture(at);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  final scale = tester.getRect(finder).width / rest;
  await gesture.up();
  await tester.pumpAndSettle();
  expect(tester.getRect(finder).width, closeTo(rest, 0.01));
  return scale;
}

Iterable<RadialGradient> lightsIn(WidgetTester tester, Finder button) => tester
    .widgetList<DecoratedBox>(
      find.descendant(of: button, matching: find.byType(DecoratedBox)),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .map((decoration) => decoration.gradient)
    .whereType<RadialGradient>();

void main() {
  group('FrButton', () {
    testWidgets(
      'AC3: se hunde a 0,965 al presionar y llama a su acción al soltar',
      (tester) async {
        var taps = 0;
        await pumpHost(
          tester,
          FrButton(label: 'Continuar', onPressed: () => taps++),
        );

        final scale = await pressedScale(
          tester,
          find.text('Continuar'),
          tester.getCenter(find.byType(FrButton)),
        );

        expect(scale, closeTo(0.965, 0.003));
        expect(taps, 1);
      },
    );

    testWidgets('AC3: se ilumina desde el punto del dedo', (tester) async {
      await pumpHost(tester, FrButton(label: 'Continuar', onPressed: () {}));
      final rect = tester.getRect(find.byType(FrButton));

      final gesture = await tester.startGesture(
        Offset(rect.left + 12, rect.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final lights = lightsIn(tester, find.byType(FrButton));
      expect(lights, isNotEmpty);
      final center = lights.first.center as Alignment;
      expect(center.x, lessThan(-0.5));
      expect(center.y, closeTo(0, 0.05));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('AC3: sin acción se ve al 38 % y no responde', (tester) async {
      await pumpHost(
        tester,
        const FrButton(
          label: 'Continuar',
          onPressed: null,
          variant: FrButtonVariant.secondary,
        ),
      );

      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(FrButton),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.38);

      final scale = await pressedScale(
        tester,
        find.text('Continuar'),
        tester.getCenter(find.byType(FrButton)),
      );
      expect(scale, 1);
    });

    testWidgets(
      'AC3: cargando muestra la onda, conserva su etiqueta accesible y no responde',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var taps = 0;
        await pumpHost(
          tester,
          FrButton(label: 'Continuar', loading: true, onPressed: () => taps++),
        );
        await tester.pump();

        expect(find.byType(WaveLoader), findsOneWidget);
        expect(find.text('Continuar'), findsNothing);
        expect(find.bySemanticsLabel('Continuar'), findsOneWidget);

        await tester.tap(find.byType(FrButton), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
        expect(taps, 0);

        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('FrIconButton', () {
    testWidgets(
      'AC3: se hunde a 0,92, tiene etiqueta accesible y llama a su acción al soltar',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var taps = 0;
        await pumpHost(
          tester,
          FrIconButton(
            icon: Icons.arrow_back,
            semanticLabel: 'Atrás',
            onPressed: () => taps++,
          ),
        );

        expect(find.bySemanticsLabel('Atrás'), findsOneWidget);
        final scale = await pressedScale(
          tester,
          find.byIcon(Icons.arrow_back),
          tester.getCenter(find.byType(FrIconButton)),
        );

        expect(scale, closeTo(0.92, 0.003));
        expect(taps, 1);
        semantics.dispose();
      },
    );
  });

  group('Movimiento reducido', () {
    testWidgets('AC2: los botones no escalan al presionarse pero responden', (
      tester,
    ) async {
      var taps = 0;
      await pumpHost(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FrButton(label: 'Continuar', onPressed: () => taps++),
            FrIconButton(
              icon: Icons.arrow_back,
              semanticLabel: 'Atrás',
              onPressed: () => taps++,
            ),
          ],
        ),
        reduceMotion: true,
      );

      final buttonScale = await pressedScale(
        tester,
        find.text('Continuar'),
        tester.getCenter(find.byType(FrButton)),
      );
      final iconScale = await pressedScale(
        tester,
        find.byIcon(Icons.arrow_back),
        tester.getCenter(find.byType(FrIconButton)),
      );

      expect(buttonScale, 1);
      expect(iconScale, 1);
      expect(taps, 2);
    });
  });
}
