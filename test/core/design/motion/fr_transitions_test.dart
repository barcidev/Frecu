// AC3: CUANDO se navega con las transiciones de Portadora ENTONCES onda revela la pantalla nueva en un círculo que crece desde el último toque con un aro de señal en 760 ms mientras la anterior se encoge y se oscurece; deslizamiento la trae desde la derecha en 560 ms mientras la anterior se corre al −28 % y se oscurece; expansión hace crecer la superficie de la hoja desde su rectángulo hasta ocupar la pantalla y luego funde la pantalla nueva; y volver desliza la pantalla hacia la derecha.
// AC6: CUANDO el sistema pide reducir el movimiento ENTONCES onda, deslizamiento, expansión y hoja pasan a un fundido de 280 ms sin desplazamientos ni escalas, la pantalla de abajo no se aleja, la isla cambia sin resorte y su punto no parpadea, el aviso y el toast solo se funden, y ningún estado ni texto se oculta.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';

const screen = Rect.fromLTWH(0, 0, 800, 600);
const keyA = ValueKey<String>('A');
const keyB = ValueKey<String>('B');

Widget page(Key key, Color color) => ColoredBox(
  color: color,
  child: SizedBox.expand(
    key: key,
    child: Center(child: Text((key as ValueKey<String>).value)),
  ),
);

Future<NavigatorState> pumpApp(
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
      home: page(keyA, Colors.black),
    ),
  );
  return navigator.currentState!;
}

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

/// Recortes activos (con `clipper` y sin `Clip.none`) sobre [finder].
List<Path> clipsOf(WidgetTester tester, Finder finder) => [
  for (final element
      in find.ancestor(of: finder, matching: find.byType(ClipPath)).evaluate())
    if ((element.widget as ClipPath).clipBehavior != Clip.none &&
        (element.widget as ClipPath).clipper != null)
      (element.widget as ClipPath).clipper!.getClip(
        (element.renderObject! as RenderBox).size,
      ),
];

void main() {
  tearDown(FrTouchOrigin.clear);

  group('FrPageRoute', () {
    test('AC3: cada transición dura lo del prototipo y volver dura 520 ms', () {
      FrPageRoute<void> route(FrTransition transition) => FrPageRoute<void>(
        transition: transition,
        builder: (_) => const SizedBox(),
      );

      expect(
        route(FrTransition.wave).transitionDuration,
        const Duration(milliseconds: 760),
      );
      expect(
        route(FrTransition.slide).transitionDuration,
        const Duration(milliseconds: 560),
      );
      expect(
        route(FrTransition.expand).transitionDuration,
        const Duration(milliseconds: 1100),
      );
      expect(
        route(FrTransition.fade).transitionDuration,
        const Duration(milliseconds: 620),
      );
      for (final transition in FrTransition.values) {
        expect(
          route(transition).reverseTransitionDuration,
          const Duration(milliseconds: 520),
        );
        expect(
          FrTransitions.durationOf(transition),
          route(transition).transitionDuration,
        );
      }
      expect(FrTransitions.backDuration, const Duration(milliseconds: 520));
      expect(FrTransitions.reducedDuration, const Duration(milliseconds: 280));
    });

    testWidgets(
      'AC3: onda revela la pantalla en un círculo desde el último toque, con aro de señal, y encoge la anterior',
      (tester) async {
        final navigator = await pumpApp(tester);
        FrTouchOrigin.record(const Offset(120, 500));
        final route = FrPageRoute<void>(
          transition: FrTransition.wave,
          builder: (_) => page(keyB, Colors.white),
        );

        unawaited(navigator.push(route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final clips = clipsOf(tester, find.byKey(keyB));
        expect(clips, isNotEmpty);
        expect(
          clips.every((clip) => clip.contains(const Offset(120, 500))),
          isTrue,
        );
        expect(
          clips.any((clip) => !clip.contains(const Offset(799, 1))),
          isTrue,
        );
        final ringed = find
            .ancestor(of: find.byKey(keyB), matching: find.byType(CustomPaint))
            .evaluate()
            .any(
              (element) =>
                  ((paints..circle(style: PaintingStyle.stroke)) as Matcher)
                      .matches(element.renderObject, <dynamic, dynamic>{}),
            );
        expect(ringed, isTrue);
        expect(tester.getRect(find.byKey(keyA)).width, lessThan(800));

        await tester.pump(const Duration(milliseconds: 700));

        expect(route.animation!.isCompleted, isTrue);
        expect(clipsOf(tester, find.byKey(keyB)), isEmpty);
        expect(tester.getRect(find.byKey(keyB)), rectMoreOrLessEquals(screen));
      },
    );

    testWidgets(
      'AC3: deslizamiento trae la pantalla desde la derecha y corre la anterior hacia el −28 %',
      (tester) async {
        final navigator = await pumpApp(tester);
        final route = FrPageRoute<void>(
          transition: FrTransition.slide,
          builder: (_) => page(keyB, Colors.white),
        );

        unawaited(navigator.push(route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        final b = tester.getRect(find.byKey(keyB));
        expect(b.left, greaterThan(0));
        expect(b.left, lessThan(800));
        expect(b.width, closeTo(800, 0.5));
        final a = tester.getRect(find.byKey(keyA));
        expect(a.left, lessThan(0));
        expect(a.left, greaterThanOrEqualTo(-0.28 * 800 - 1));

        await tester.pump(const Duration(milliseconds: 450));

        expect(route.animation!.isCompleted, isTrue);
        expect(tester.getRect(find.byKey(keyB)), rectMoreOrLessEquals(screen));
      },
    );

    testWidgets(
      'AC3: expansión hace crecer la superficie desde el rectángulo de la hoja y luego funde la pantalla nueva',
      (tester) async {
        final navigator = await pumpApp(tester);
        const from = Rect.fromLTRB(8, 320, 792, 592);
        final route = FrPageRoute<void>(
          transition: FrTransition.expand,
          from: from,
          builder: (_) => page(keyB, Colors.white),
        );
        final surface = find.byKey(FrTransitions.expandSurfaceKey);

        unawaited(navigator.push(route));
        await tester.pump();
        // El primer cuadro de un push deja la ruta fuera de escena (Hero).
        await tester.pump();

        expect(tester.getRect(surface), rectMoreOrLessEquals(from, epsilon: 1));

        await tester.pump(const Duration(milliseconds: 300));

        final growing = tester.getRect(surface);
        expect(growing.top, lessThan(320));
        expect(growing.top, greaterThan(0));
        expect(opacityOf(tester, find.byKey(keyB)), 0);

        await tester.pump(const Duration(milliseconds: 340));

        expect(
          tester.getRect(surface),
          rectMoreOrLessEquals(screen, epsilon: 4),
        );

        await tester.pump(const Duration(milliseconds: 500));

        expect(route.animation!.isCompleted, isTrue);
        expect(opacityOf(tester, find.byKey(keyB)), 1);
        expect(tester.getRect(find.byKey(keyB)), rectMoreOrLessEquals(screen));
        expect(opacityOf(tester, surface), 0);
      },
    );

    testWidgets('AC3: volver desliza la pantalla hacia la derecha', (
      tester,
    ) async {
      final navigator = await pumpApp(tester);
      final route = FrPageRoute<void>(
        transition: FrTransition.wave,
        builder: (_) => page(keyB, Colors.white),
      );
      unawaited(navigator.push(route));
      await tester.pumpAndSettle();

      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final b = tester.getRect(find.byKey(keyB));
      expect(b.left, greaterThan(0));
      expect(b.width, closeTo(800, 0.5));
      expect(clipsOf(tester, find.byKey(keyB)), isEmpty);

      await tester.pumpAndSettle();

      expect(find.byKey(keyB), findsNothing);
      expect(tester.getRect(find.byKey(keyA)), rectMoreOrLessEquals(screen));
    });
  });

  group('FrTransitions', () {
    testWidgets(
      'AC3: los constructores sirven en cualquier ruta (CustomRoute de auto_route)',
      (tester) async {
        final navigator = await pumpApp(tester);

        unawaited(
          navigator.push(
            PageRouteBuilder<void>(
              transitionDuration: FrTransitions.slideDuration,
              reverseTransitionDuration: FrTransitions.backDuration,
              transitionsBuilder: FrTransitions.slide,
              pageBuilder: (_, _, _) => page(keyB, Colors.white),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        final b = tester.getRect(find.byKey(keyB));
        expect(b.left, greaterThan(0));
        expect(b.left, lessThan(800));

        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(keyB)), rectMoreOrLessEquals(screen));
      },
    );
  });

  group('Movimiento reducido', () {
    testWidgets(
      'AC6: onda, deslizamiento, expansión y fundido pasan a un fundido de 280 ms sin desplazar ni alejar la pantalla de abajo',
      (tester) async {
        final navigator = await pumpApp(tester, reduceMotion: true);
        FrTouchOrigin.record(const Offset(120, 500));

        for (final transition in FrTransition.values) {
          final route = FrPageRoute<void>(
            transition: transition,
            from: const Rect.fromLTRB(8, 320, 792, 592),
            builder: (_) => page(keyB, Colors.white),
          );

          unawaited(navigator.push(route));
          await tester.pump();

          expect(route.transitionDuration, FrTransitions.reducedDuration);

          await tester.pump(const Duration(milliseconds: 140));

          expect(
            tester.getRect(find.byKey(keyB)),
            rectMoreOrLessEquals(screen),
            reason: '$transition',
          );
          final entering = opacityOf(tester, find.byKey(keyB));
          expect(entering, greaterThan(0), reason: '$transition');
          expect(entering, lessThan(1), reason: '$transition');
          expect(clipsOf(tester, find.byKey(keyB)), isEmpty);
          expect(
            tester.getRect(find.byKey(keyA)),
            rectMoreOrLessEquals(screen),
            reason: '$transition',
          );
          final surface = find.byKey(FrTransitions.expandSurfaceKey);
          if (surface.evaluate().isNotEmpty) {
            expect(opacityOf(tester, surface), 0);
          }

          await tester.pump(const Duration(milliseconds: 160));
          expect(route.animation!.isCompleted, isTrue, reason: '$transition');

          navigator.pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 140));

          expect(
            tester.getRect(find.byKey(keyB)),
            rectMoreOrLessEquals(screen),
            reason: '$transition',
          );
          final leaving = opacityOf(tester, find.byKey(keyB));
          expect(leaving, greaterThan(0), reason: '$transition');
          expect(leaving, lessThan(1), reason: '$transition');

          await tester.pumpAndSettle();
          expect(find.byKey(keyB), findsNothing);
        }
      },
    );

    testWidgets(
      'AC6: los constructores sueltos también son un fundido sin desplazamiento',
      (tester) async {
        // Con movimiento reducido el sistema acorta 20 veces las rutas
        // normales, así que se prueba el constructor con la animación a medias.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: Builder(
              builder: (context) => FrTransitions.slide(
                context,
                const AlwaysStoppedAnimation<double>(0.5),
                kAlwaysDismissedAnimation,
                page(keyB, Colors.white),
              ),
            ),
          ),
        );

        expect(tester.getRect(find.byKey(keyB)), rectMoreOrLessEquals(screen));
        expect(opacityOf(tester, find.byKey(keyB)), closeTo(0.5, 0.01));
      },
    );
  });
}
