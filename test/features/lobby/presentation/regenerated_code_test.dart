// «Generar otro» (app.js:483-485): el código nuevo aparece con un pop escalonado de sus celdas, cada 60 ms, de 0,7 y casi transparentes a su tamaño; en reposo es un solo FrPinField de solo lectura y con movimiento reducido cambia sin animar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/features/lobby/presentation/widgets/regenerated_code.dart';

void main() {
  Future<void> pumpCode(WidgetTester tester, String code) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: RegeneratedCode(code: code, semanticLabel: 'Código'),
        ),
      ),
    ),
  );

  List<double> scales(WidgetTester tester) => [
    for (final cell in tester.widgetList<FrPinField>(find.byType(FrPinField)))
      tester
          .widget<Transform>(
            find
                .ancestor(
                  of: find.byWidget(cell),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .entry(0, 0),
  ];

  testWidgets('en reposo es un solo código de solo lectura', (tester) async {
    await pumpCode(tester, '4827');

    final pin = tester.widget<FrPinField>(find.byType(FrPinField));
    expect(pin.value, '4827');
    expect(pin.readOnly, isTrue);
    expect(pin.semanticLabel, 'Código');
  });

  testWidgets('al cambiar, las celdas aparecen escalonadas y vuelve a ser un '
      'solo código', (tester) async {
    await pumpCode(tester, '4827');
    await pumpCode(tester, '1593');
    await tester.pump(const Duration(milliseconds: 90));

    final cells = tester.widgetList<FrPinField>(find.byType(FrPinField));
    expect(cells.map((cell) => cell.value), ['1', '5', '9', '3']);
    final popped = scales(tester);
    // La primera ya creció; la última aún no empieza.
    expect(popped.first, greaterThan(popped.last));
    expect(popped.last, closeTo(0.7, 0.001));

    await tester.pumpAndSettle();

    final pin = tester.widget<FrPinField>(find.byType(FrPinField));
    expect(pin.value, '1593');
    expect(pin.length, 4);
  });

  testWidgets('con movimiento reducido el código cambia sin animar', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpCode(tester, '4827');
    await pumpCode(tester, '1593');

    expect(find.byType(FrPinField), findsOneWidget);
    expect(tester.widget<FrPinField>(find.byType(FrPinField)).value, '1593');

    await tester.pump(const Duration(milliseconds: 90));
    expect(find.byType(FrPinField), findsOneWidget);
  });
}
