// Tarjetas del inicio con la entrada `rise` del prototipo (screens.css:66-68): suben 18 px, crecen desde 0,98 y aparecen con el resorte `flow` en 700 ms tras su escalonado; con movimiento reducido solo se funden.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/features/lobby/presentation/widgets/rise_in.dart';

const _tile = Key('tile');

void main() {
  Future<void> pumpRise(
    WidgetTester tester, {
    Duration delay = Duration.zero,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Center(
        child: RiseIn(
          delay: delay,
          child: const SizedBox(key: _tile, width: 100, height: 60),
        ),
      ),
    ),
  );

  double opacity(WidgetTester tester) => tester
      .widget<Opacity>(
        // El tema añade la transición de página: vale el Opacity más cercano.
        find
            .ancestor(of: find.byKey(_tile), matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  /// Desplazamiento vertical: el primer Transform de la entrada.
  double lift(WidgetTester tester) => tester
      .widget<Transform>(
        find
            .descendant(
              of: find.byType(RiseIn),
              matching: find.byType(Transform),
            )
            .first,
      )
      .transform
      .getTranslation()
      .y;

  test('el escalonado es 0, 80 y 160 ms y no pasa de ahí', () {
    expect(
      [for (var i = 0; i < 5; i++) RiseIn.staggerOf(i).inMilliseconds],
      [0, 80, 160, 160, 160],
    );
  });

  testWidgets('sube 18 px y aparece tras su escalonado, y queda quieta', (
    tester,
  ) async {
    await pumpRise(tester, delay: const Duration(milliseconds: 80));

    expect(opacity(tester), 0);
    expect(lift(tester), closeTo(18, 0.01));

    await tester.pump(const Duration(milliseconds: 70));
    expect(opacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 250));
    expect(opacity(tester), inExclusiveRange(0, 1));
    expect(lift(tester), inExclusiveRange(0, 18));

    await tester.pump(const Duration(milliseconds: 500));
    expect(opacity(tester), 1);
    expect(lift(tester), 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('con movimiento reducido solo se funde, sin moverse', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpRise(tester);

    expect(lift(tester), 0);
    await tester.pumpAndSettle();
    expect(opacity(tester), 1);
  });
}
