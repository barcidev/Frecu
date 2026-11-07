// AC2: CUANDO se abre una hoja con `showFrSheet` ENTONCES el velo `scrim` aparece desenfocando el fondo, la `FrSheet` (radio 40, asa, título, mensaje y contenido) sube desde abajo con el resorte `flow` y la pantalla de abajo se aleja (escala 0,93) y se oscurece; al tocar el velo o volver, la hoja baja, el velo se va y la pantalla de abajo vuelve a su lugar.
// AC6: CUANDO el sistema pide reducir el movimiento ENTONCES onda, deslizamiento, expansión y hoja pasan a un fundido de 280 ms sin desplazamientos ni escalas, la pantalla de abajo no se aleja, la isla cambia sin resorte y su punto no parpadea, el aviso y el toast solo se funden, y ningún estado ni texto se oculta.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_motion.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';

const screen = Rect.fromLTWH(0, 0, 800, 600);
const keyA = ValueKey<String>('A');

late BuildContext homeContext;

Future<NavigatorState> pumpBase(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) {
          homeContext = context;
          return const ColoredBox(
            color: Colors.black,
            child: SizedBox.expand(
              key: keyA,
              child: Center(child: Text('A')),
            ),
          );
        },
      ),
    ),
  );
  return navigator.currentState!;
}

Widget invite(BuildContext context) => const FrSheet(
  title: 'Invitar',
  message: 'Comparte el código con tu grupo.',
  children: [Text('QR')],
);

/// Opacidad visible de [finder]: producto de sus `Opacity` y `FadeTransition`
/// y las de sus ancestros.
double opacityOf(WidgetTester tester, Finder finder) {
  final element = finder.evaluate().first;
  var value = 1.0;
  void apply(Widget widget) {
    if (widget is Opacity) value *= widget.opacity;
    if (widget is FadeTransition) value *= widget.opacity.value;
  }

  apply(element.widget);
  element.visitAncestorElements((ancestor) {
    apply(ancestor.widget);
    return true;
  });
  return value;
}

double? radiusOf(Decoration decoration) => switch (decoration) {
  BoxDecoration(:final BorderRadius borderRadius) => borderRadius.topLeft.x,
  ShapeDecoration(shape: RoundedSuperellipseBorder(:final borderRadius)) ||
  ShapeDecoration(
    shape: RoundedRectangleBorder(:final borderRadius),
  ) => borderRadius.resolve(TextDirection.ltr).topLeft.x,
  _ => null,
};

bool hasBoxOfSize(WidgetTester tester, Finder of, Size size) => find
    .descendant(of: of, matching: find.byWidgetPredicate((_) => true))
    .evaluate()
    .any((element) {
      final box = element.renderObject;
      return box is RenderBox && box.hasSize && box.size == size;
    });

void main() {
  group('FrSheetRoute', () {
    testWidgets(
      'AC2: la hoja sube con el resorte flow sobre el velo y la pantalla de abajo se aleja',
      (tester) async {
        final navigator = await pumpBase(tester);
        final route = FrSheetRoute<void>(builder: invite);

        unawaited(navigator.push(route));
        await tester.pump();

        expect(
          tester.getRect(find.byType(FrSheet)).top,
          greaterThanOrEqualTo(592),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final spring = SpringSimulation(FrMotion.standard.springFlow, 0, 1, 0);
        expect(route.animation!.value, closeTo(spring.x(0.1), 0.02));

        await tester.pumpAndSettle();

        final sheet = tester.getRect(find.byType(FrSheet));
        expect(sheet.bottom, closeTo(592, 0.5));
        expect(sheet.left, closeTo(8, 0.5));
        expect(sheet.right, closeTo(792, 0.5));
        expect(find.text('Invitar'), findsOneWidget);
        expect(find.text('Comparte el código con tu grupo.'), findsOneWidget);
        expect(find.text('QR'), findsOneWidget);
        expect(find.byType(BackdropFilter), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ColoredBox && widget.color == FrColors.dark.scrim,
          ),
          findsOneWidget,
        );
        expect(tester.getRect(find.byKey(keyA)).width, closeTo(800 * 0.93, 1));
      },
    );

    testWidgets('AC2: la hoja tiene radio 40 y asa de 38 × 5', (tester) async {
      await pumpBase(tester);

      unawaited(showFrSheet<void>(homeContext, builder: invite));
      await tester.pumpAndSettle();

      final radii = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FrSheet),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => radiusOf(box.decoration));
      expect(radii, contains(40));
      expect(
        hasBoxOfSize(tester, find.byType(FrSheet), const Size(38, 5)),
        isTrue,
      );
    });

    testWidgets(
      'AC2: tocar el velo baja la hoja en 400 ms y la pantalla de abajo vuelve a su lugar',
      (tester) async {
        final navigator = await pumpBase(tester);
        final route = FrSheetRoute<void>(builder: invite);
        unawaited(navigator.push(route));
        await tester.pumpAndSettle();

        await tester.tapAt(const Offset(400, 40));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(FrSheet), findsOneWidget);
        expect(tester.getRect(find.byType(FrSheet)).bottom, greaterThan(592));

        await tester.pump(const Duration(milliseconds: 250));

        expect(route.animation!.isDismissed, isTrue);
        await tester.pumpAndSettle();
        expect(find.byType(FrSheet), findsNothing);
        expect(find.byType(BackdropFilter), findsNothing);
        expect(tester.getRect(find.byKey(keyA)), rectMoreOrLessEquals(screen));
      },
    );

    testWidgets('AC2: volver cierra la hoja', (tester) async {
      await pumpBase(tester);
      unawaited(showFrSheet<void>(homeContext, builder: invite));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(FrSheet), findsNothing);
      expect(tester.getRect(find.byKey(keyA)), rectMoreOrLessEquals(screen));
    });

    testWidgets(
      'AC6: con movimiento reducido la hoja se funde en su lugar en 280 ms y la pantalla de abajo no se aleja',
      (tester) async {
        final navigator = await pumpBase(tester, reduceMotion: true);
        final route = FrSheetRoute<void>(builder: invite);

        unawaited(navigator.push(route));
        await tester.pump();

        expect(route.transitionDuration, FrTransitions.reducedDuration);

        await tester.pump(const Duration(milliseconds: 140));

        final sheet = tester.getRect(find.byType(FrSheet));
        expect(sheet.bottom, closeTo(592, 0.5));
        expect(sheet.left, closeTo(8, 0.5));
        final entering = opacityOf(tester, find.byType(FrSheet));
        expect(entering, greaterThan(0));
        expect(entering, lessThan(1));
        expect(tester.getRect(find.byKey(keyA)), rectMoreOrLessEquals(screen));

        await tester.pump(const Duration(milliseconds: 160));

        expect(route.animation!.isCompleted, isTrue);
        expect(find.text('Invitar'), findsOneWidget);
        expect(tester.getRect(find.byKey(keyA)), rectMoreOrLessEquals(screen));

        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 140));

        expect(tester.getRect(find.byType(FrSheet)).bottom, closeTo(592, 0.5));
        final leaving = opacityOf(tester, find.byType(FrSheet));
        expect(leaving, greaterThan(0));
        expect(leaving, lessThan(1));

        await tester.pumpAndSettle();
        expect(find.byType(FrSheet), findsNothing);
      },
    );
  });
}
