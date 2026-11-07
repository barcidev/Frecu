// AC4: CUANDO se elige otro segmento de `FrSegmented` ENTONCES llama a `onChanged` con su valor, el pulgar viaja hasta él con el resorte `organic` y se estira (1,16 × 0,86) al salir, el texto elegido pasa a `tx1` (a `signalInk` sobre el pulgar de señal en la variante de señal) y el resto queda en `tx3`; sin `onChanged` se ve al 38 % y no responde.
// AC5: CUANDO se toca un `FrToggle` ENTONCES llama a `onChanged` con el valor contrario; encendido es un relleno `signal` con la perilla en `signalInk` a la derecha y apagado es `bg3` con la perilla en `tx2` a la izquierda, la perilla viaja con el resorte `organic` y se estira a 34 px mientras se presiona, y expone su estado a la accesibilidad; sin `onChanged` se ve al 38 % y no responde.
// AC7: CUANDO el sistema pide reducir el movimiento ENTONCES el cursor del PIN queda fijo y visible, el dígito no salta, la fila no tiembla, la ola de `ok` no se mueve y `busy` queda quieto con su borde de señal; las teclas no se hunden, el pulgar y la perilla cambian de lugar sin resorte ni estiramiento, el halo de la píldora se apaga y su arco se detiene, sin ocultar ningún estado (cursor, ocupado, correcto, error, selección y encendido).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/design/widgets/fr_toggle.dart';

const colors = FrColors.dark;

Future<void> pumpHost(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
  bool light = false,
}) async {
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: light ? AppTheme.light : AppTheme.dark,
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

Decoration decorationOf(WidgetTester tester, Finder finder) => tester
    .widget<DecoratedBox>(
      find
          .descendant(
            of: finder,
            matching: find.byType(DecoratedBox),
            matchRoot: true,
          )
          .first,
    )
    .decoration;

Color? fillOf(Decoration decoration) => switch (decoration) {
  ShapeDecoration(:final color) => color,
  BoxDecoration(:final color) => color,
  _ => null,
};

BorderSide sideOf(Decoration decoration) => switch (decoration) {
  ShapeDecoration(:final shape) when shape is OutlinedBorder => shape.side,
  BoxDecoration(:final Border border) => border.top,
  _ => BorderSide.none,
};

Color? textColor(WidgetTester tester, String text) =>
    (tester.renderObject<RenderParagraph>(find.text(text)).text as TextSpan)
        .style
        ?.color;

double opacityIn(WidgetTester tester, Finder widget) => tester
    .widget<Opacity>(
      find.descendant(of: widget, matching: find.byType(Opacity)).first,
    )
    .opacity;

const List<FrSegment<String>> segments = [
  FrSegment(value: 'ptt', label: 'Ptt'),
  FrSegment(value: 'open', label: 'Abierto'),
];

final Finder thumb = find.byKey(const ValueKey('fr-segmented-thumb'));

Finder segment(int index) => find.byKey(ValueKey('fr-segment-$index'));

final Finder track = find.byKey(const ValueKey('fr-toggle-track'));

final Finder knob = find.byKey(const ValueKey('fr-toggle-knob'));

Widget segmentedHost({bool signal = false, List<String>? log}) {
  var value = 'ptt';
  return StatefulBuilder(
    builder: (context, setState) => FrSegmented<String>(
      segments: segments,
      value: value,
      signal: signal,
      onChanged: (next) {
        log?.add(next);
        setState(() => value = next);
      },
    ),
  );
}

Widget toggleHost({bool initial = false, List<bool>? log}) {
  var value = initial;
  return StatefulBuilder(
    builder: (context, setState) => FrToggle(
      value: value,
      semanticLabel: 'Vibrar al hablar',
      onChanged: (next) {
        log?.add(next);
        setState(() => value = next);
      },
    ),
  );
}

void main() {
  group('FrSegmented', () {
    testWidgets(
      'AC4: el pulgar viaja con el resorte organic, se estira al salir y llama a onChanged',
      (tester) async {
        final log = <String>[];
        await pumpHost(tester, segmentedHost(log: log));
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byType(FrSegmented<String>)).height, 48);
        final rest = tester.getRect(thumb);
        final from = tester.getRect(segment(0));
        final to = tester.getRect(segment(1));
        expect(rest.center.dx, closeTo(from.center.dx, 0.5));
        expect(rest.width, closeTo(from.width, 0.5));
        expect(rest.height, closeTo(40, 0.5));

        await tester.tap(find.text('ABIERTO'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 180));
        final stretched = tester.getRect(thumb);
        expect(stretched.height, lessThan(rest.height * 0.9));
        expect(stretched.width, greaterThan(rest.width * 1.08));

        await tester.pump(const Duration(milliseconds: 110));
        expect(tester.getRect(thumb).center.dx, greaterThan(to.center.dx + 1));

        await tester.pumpAndSettle();
        final settled = tester.getRect(thumb);
        expect(settled.center.dx, closeTo(to.center.dx, 0.5));
        expect(settled.height, closeTo(rest.height, 0.5));
        expect(settled.width, closeTo(rest.width, 0.5));
        expect(log, ['open']);
      },
    );

    testWidgets('AC4: el texto elegido va en tx1 y el resto en tx3', (
      tester,
    ) async {
      await pumpHost(tester, segmentedHost());
      await tester.pumpAndSettle();

      expect(find.text('PTT'), findsOneWidget);
      expect(textColor(tester, 'PTT'), colors.tx1);
      expect(textColor(tester, 'ABIERTO'), colors.tx3);
      expect(fillOf(decorationOf(tester, thumb)), colors.bg3);

      await tester.tap(find.text('ABIERTO'));
      await tester.pumpAndSettle();
      expect(textColor(tester, 'ABIERTO'), colors.tx1);
      expect(textColor(tester, 'PTT'), colors.tx3);
    });

    testWidgets(
      'AC4: en la variante de señal el pulgar es signal y el texto elegido signalInk, también de día',
      (tester) async {
        await pumpHost(tester, segmentedHost(signal: true));
        await tester.pumpAndSettle();

        expect(fillOf(decorationOf(tester, thumb)), colors.signal);
        expect(textColor(tester, 'PTT'), colors.signalInk);
        expect(textColor(tester, 'ABIERTO'), colors.tx3);

        const day = FrColors.light;
        await pumpHost(tester, segmentedHost(signal: true), light: true);
        await tester.pumpAndSettle();
        expect(fillOf(decorationOf(tester, thumb)), day.signal);
        expect(textColor(tester, 'PTT'), day.signalInk);
        expect(textColor(tester, 'ABIERTO'), day.tx3);
      },
    );

    testWidgets('AC4: sin onChanged se ve al 38 % y no responde', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const FrSegmented<String>(
          segments: segments,
          value: 'ptt',
          onChanged: null,
        ),
      );
      await tester.pumpAndSettle();
      expect(opacityIn(tester, find.byType(FrSegmented<String>)), 0.38);
      final before = tester.getRect(thumb);

      await tester.tap(find.text('ABIERTO'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.getRect(thumb), before);
      expect(textColor(tester, 'PTT'), colors.tx1);
    });
  });

  group('FrToggle', () {
    testWidgets(
      'AC5: apagado es bg3 con la perilla tx2 a la izquierda y encendido es signal con la perilla signalInk a la derecha',
      (tester) async {
        final log = <bool>[];
        await pumpHost(tester, toggleHost(log: log));
        await tester.pumpAndSettle();

        final rect = tester.getRect(track);
        expect(rect.size, const Size(54, 32));
        expect(fillOf(decorationOf(tester, track)), colors.bg3);
        expect(sideOf(decorationOf(tester, track)).color, colors.line2);
        expect(tester.getRect(knob).size, const Size(26, 26));
        expect(tester.getRect(knob).left, closeTo(rect.left + 3, 0.01));
        expect(fillOf(decorationOf(tester, knob)), colors.tx2);

        await tester.tap(track);
        await tester.pumpAndSettle();
        expect(fillOf(decorationOf(tester, track)), colors.signal);
        expect(fillOf(decorationOf(tester, knob)), colors.signalInk);
        expect(tester.getRect(knob).right, closeTo(rect.right - 3, 0.01));

        await tester.tap(track);
        await tester.pumpAndSettle();
        expect(tester.getRect(knob).left, closeTo(rect.left + 3, 0.01));
        expect(log, [true, false]);
      },
    );

    testWidgets(
      'AC5: la perilla viaja con el resorte organic y se estira a 34 px mientras se presiona',
      (tester) async {
        await pumpHost(tester, toggleHost());
        await tester.pumpAndSettle();
        final rect = tester.getRect(track);

        final press = await tester.startGesture(rect.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getRect(knob).width, closeTo(34, 0.01));
        expect(tester.getRect(knob).left, closeTo(rect.left + 3, 0.01));

        await press.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 290));
        expect(tester.getRect(knob).left, greaterThan(rect.left + 25.5));

        await tester.pumpAndSettle();
        expect(tester.getRect(knob).left, closeTo(rect.left + 25, 0.01));
        expect(tester.getRect(knob).width, closeTo(26, 0.01));

        final again = await tester.startGesture(rect.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getRect(knob).width, closeTo(34, 0.01));
        expect(tester.getRect(knob).right, closeTo(rect.right - 3, 0.01));
        await again.cancel();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('AC5: expone su estado a la accesibilidad', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHost(tester, toggleHost(initial: true));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Vibrar al hablar')),
        isSemantics(
          label: 'Vibrar al hablar',
          hasToggledState: true,
          isToggled: true,
        ),
      );

      await tester.tap(track);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Vibrar al hablar')),
        isSemantics(hasToggledState: true, isToggled: false),
      );
      semantics.dispose();
    });

    testWidgets('AC5: sin onChanged se ve al 38 % y no responde', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const FrToggle(
          value: false,
          onChanged: null,
          semanticLabel: 'Vibrar al hablar',
        ),
      );
      await tester.pumpAndSettle();
      expect(opacityIn(tester, find.byType(FrToggle)), 0.38);
      final before = tester.getRect(knob);

      await tester.tap(track, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.getRect(knob), before);
      expect(fillOf(decorationOf(tester, track)), colors.bg3);
    });
  });

  group('Movimiento reducido', () {
    testWidgets(
      'AC7: el pulgar cambia de lugar sin resorte ni estiramiento y muestra la selección',
      (tester) async {
        await pumpHost(tester, segmentedHost(), reduceMotion: true);
        await tester.pumpAndSettle();
        final rest = tester.getRect(thumb);
        final to = tester.getRect(segment(1));

        await tester.tap(find.text('ABIERTO'));
        await tester.pump();
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          final now = tester.getRect(thumb);
          expect(now.center.dx, lessThanOrEqualTo(to.center.dx + 0.01));
          expect(now.height, closeTo(rest.height, 0.01));
          expect(now.width, closeTo(rest.width, 0.01));
        }

        await tester.pumpAndSettle();
        expect(tester.getRect(thumb).center.dx, closeTo(to.center.dx, 0.5));
        expect(textColor(tester, 'ABIERTO'), colors.tx1);
      },
    );

    testWidgets(
      'AC7: la perilla cambia de lugar sin resorte ni estiramiento y muestra el encendido',
      (tester) async {
        await pumpHost(tester, toggleHost(), reduceMotion: true);
        await tester.pumpAndSettle();
        final rect = tester.getRect(track);

        final press = await tester.startGesture(rect.center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getRect(knob).width, closeTo(26, 0.01));

        await press.up();
        await tester.pump();
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 40));
          expect(
            tester.getRect(knob).left,
            lessThanOrEqualTo(rect.left + 25.01),
          );
          expect(tester.getRect(knob).width, closeTo(26, 0.01));
        }

        await tester.pumpAndSettle();
        expect(tester.getRect(knob).left, closeTo(rect.left + 25, 0.01));
        expect(fillOf(decorationOf(tester, track)), colors.signal);
        expect(fillOf(decorationOf(tester, knob)), colors.signalInk);
      },
    );
  });
}
