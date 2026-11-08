// P53: CUANDO se navega con las transiciones de Portadora ENTONCES la onda entra con un brillo de 1,5 que baja a 1 (`brightness(1.5)`), el fundido entra desde un desenfoque de 6 px (`blur(6px)`) y, al volver de cualquier transición, la pantalla de abajo regresa desde el −28 % con el brillo al 0,45 sin escalarse (`back` de `app.js`).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';

const keyA = ValueKey<String>('A');
const keyB = ValueKey<String>('B');

Widget page(Key key, Color color) => ColoredBox(
  color: color,
  child: SizedBox.expand(key: key),
);

Future<NavigatorState> pumpApp(WidgetTester tester) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: AppTheme.dark,
      home: page(keyA, Colors.black),
    ),
  );
  return navigator.currentState!;
}

/// Pinta un gris en `colorDodge` (el brillo de la onda) sobre [finder].
bool brightens(WidgetTester tester, Finder finder) => find
    .ancestor(of: finder, matching: find.byType(CustomPaint))
    .evaluate()
    .any(
      (element) =>
          ((paints..something(
                    (method, arguments) =>
                        method == #drawRect &&
                        (arguments[1] as Paint).blendMode ==
                            BlendMode.colorDodge,
                  ))
                  as Matcher)
              .matches(element.renderObject, <dynamic, dynamic>{}),
    );

/// Gris del brillo de la onda sobre [finder]: `1 − 1 / brillo`.
double dodgeOf(WidgetTester tester, Finder finder) {
  for (final element
      in find
          .ancestor(of: finder, matching: find.byType(CustomPaint))
          .evaluate()) {
    double? gray;
    final matcher =
        (paints..something((method, arguments) {
              if (method != #drawRect) return false;
              final paint = arguments[1] as Paint;
              if (paint.blendMode != BlendMode.colorDodge) return false;
              gray = paint.color.r;
              return true;
            }))
            as Matcher;
    if (matcher.matches(element.renderObject, <dynamic, dynamic>{})) {
      return gray!;
    }
  }
  return 0;
}

void main() {
  tearDown(FrTouchOrigin.clear);

  testWidgets('P53: la onda entra con brillo 1,5 que baja a 1', (tester) async {
    final navigator = await pumpApp(tester);
    FrTouchOrigin.record(const Offset(400, 300));
    unawaited(
      navigator.push(
        FrPageRoute<void>(
          transition: FrTransition.wave,
          builder: (_) => page(keyB, Colors.white),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // Brillo b: el gris del `colorDodge` es 1 − 1/b.
    final early = 1 / (1 - dodgeOf(tester, find.byKey(keyB)));
    expect(early, greaterThan(1.3));
    expect(early, lessThanOrEqualTo(FrTransitions.waveBrightness + 1e-6));

    await tester.pump(const Duration(milliseconds: 200));
    final later = 1 / (1 - dodgeOf(tester, find.byKey(keyB)));
    expect(later, lessThan(early));

    await tester.pumpAndSettle();
    expect(brightens(tester, find.byKey(keyB)), isFalse);
  });

  testWidgets('P53: el fundido entra desde un desenfoque de 6 px', (
    tester,
  ) async {
    final navigator = await pumpApp(tester);
    unawaited(
      navigator.push(
        FrPageRoute<void>(
          transition: FrTransition.fade,
          builder: (_) => page(keyB, Colors.white),
        ),
      ),
    );
    await tester.pump();
    // El primer cuadro de un push deja la ruta fuera de escena (Hero).
    await tester.pump(const Duration(milliseconds: 16));

    expect(FrTransitions.fadeBlur, 6);
    final blurred = find.ancestor(
      of: find.byKey(keyB),
      matching: find.byType(ImageFiltered),
    );
    expect(blurred, findsOneWidget);
    expect(
      tester.widget<ImageFiltered>(blurred).imageFilter.toString(),
      contains('blur'),
    );

    await tester.pumpAndSettle();
    expect(
      find.ancestor(of: find.byKey(keyB), matching: find.byType(ImageFiltered)),
      findsNothing,
    );
  });

  for (final transition in [
    FrTransition.wave,
    FrTransition.slide,
    FrTransition.fade,
  ]) {
    testWidgets(
      'P53: al volver de $transition la pantalla de abajo regresa desde el '
      '−28 % sin escalarse',
      (tester) async {
        final navigator = await pumpApp(tester);
        unawaited(
          navigator.push(
            FrPageRoute<void>(
              transition: transition,
              builder: (_) => page(keyB, Colors.white),
            ),
          ),
        );
        await tester.pumpAndSettle();

        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        final start = tester.getRect(find.byKey(keyA));
        expect(start.width, closeTo(800, 0.5), reason: 'sin escala');
        expect(start.left, lessThan(-0.2 * 800));
        expect(start.left, greaterThanOrEqualTo(-0.28 * 800 - 1));

        await tester.pump(const Duration(milliseconds: 200));
        final middle = tester.getRect(find.byKey(keyA));
        expect(middle.left, greaterThan(start.left));
        expect(middle.left, lessThanOrEqualTo(0));
        expect(middle.width, closeTo(800, 0.5));

        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(keyA)),
          rectMoreOrLessEquals(const Rect.fromLTWH(0, 0, 800, 600)),
        );
      },
    );
  }
}
