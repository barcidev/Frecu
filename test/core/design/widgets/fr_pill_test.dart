// AC6: CUANDO se muestra una `FrPill` o una `FrTag` ENTONCES la píldora de 28 px lleva el texto en mayúsculas y un punto del color de su tono (`ok`, `warn`, `alert`, `off`) con un halo que late cada 2,4 s (1,1 s en `warn`, sin halo en `off`) o, si está ocupada, un arco que gira; la etiqueta de 20 px va en mayúsculas en neutro (`bg3` y `tx2`), señal (relleno `signal` al 12 % × `washK` y texto `signalFg`) o aviso; en el tema claro ningún texto ni trazo de estos widgets usa `signal`, salvo el halo del punto conectado, que es un brillo y va en verde (D8); ocupada, el anillo y el arco van en ámbar de 1,5 px (`.pill.busy`).
// AC7: CUANDO el sistema pide reducir el movimiento ENTONCES el cursor del PIN queda fijo y visible, el dígito no salta, la fila no tiembla, la ola de `ok` no se mueve y `busy` queda quieto con su borde de señal; las teclas no se hunden, el pulgar y la perilla cambian de lugar sin resorte ni estiramiento, el halo de la píldora se apaga y su arco se detiene, sin ocultar ningún estado (cursor, ocupado, correcto, error, selección y encendido).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_pill.dart';
import 'package:frecu/core/design/widgets/fr_tag.dart';

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

final Finder halo = find.byKey(const ValueKey('fr-pill-halo'));

final Finder dot = find.byKey(const ValueKey('fr-pill-dot'));

final Finder arc = find.byKey(const ValueKey('fr-pill-arc'));

void main() {
  group('FrPill', () {
    testWidgets(
      'AC6: mide 28 px, va en mayúsculas y su punto y su texto siguen el tono',
      (tester) async {
        final tones = [
          (FrPillTone.ok, colors.signal, colors.tx1),
          (FrPillTone.warn, colors.warn, colors.warn),
          (FrPillTone.alert, colors.alert, colors.alert),
          (FrPillTone.off, colors.tx4, colors.tx3),
        ];
        for (final (tone, dotColor, labelColor) in tones) {
          await pumpHost(
            tester,
            FrPill(key: ValueKey(tone), label: 'Conectado', tone: tone),
          );
          await tester.pump(const Duration(milliseconds: 500));

          expect(tester.getSize(find.byType(FrPill)).height, 28);
          expect(find.text('CONECTADO'), findsOneWidget);
          expect(textColor(tester, 'CONECTADO'), labelColor);
          expect(tester.getSize(dot), const Size(7, 7));
          expect(fillOf(decorationOf(tester, dot)), dotColor);
        }
      },
    );

    testWidgets(
      'AC6: el halo late cada 2,4 s, cada 1,1 s en aviso y no existe en apagado',
      (tester) async {
        await pumpHost(tester, const FrPill(label: 'Conectado'));
        await tester.pump(const Duration(milliseconds: 2300));
        expect(tester.getRect(halo).width, greaterThan(25));
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.getRect(halo).width, lessThan(15));

        await pumpHost(
          tester,
          const FrPill(
            key: ValueKey('warn'),
            label: 'Reconectando',
            tone: FrPillTone.warn,
          ),
        );
        await tester.pump(const Duration(milliseconds: 1000));
        expect(tester.getRect(halo).width, greaterThan(25));
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.getRect(halo).width, lessThan(15));

        await pumpHost(
          tester,
          const FrPill(
            key: ValueKey('off'),
            label: 'Cerrada',
            tone: FrPillTone.off,
          ),
        );
        await tester.pumpAndSettle();
        expect(halo, findsNothing);
      },
    );

    testWidgets('AC6: ocupada, el punto se cambia por un arco que gira', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const FrPill(label: 'Conectando', tone: FrPillTone.warn, busy: true),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final before = tester.getTopLeft(arc);

      await tester.pump(const Duration(milliseconds: 200));
      expect((tester.getTopLeft(arc) - before).distance, greaterThan(1));
      expect(halo, findsNothing);
    });
  });

  group('FrTag', () {
    testWidgets(
      'AC6: mide 20 px, va en mayúsculas y usa el relleno y el texto de su tono',
      (tester) async {
        final tones = [
          (FrTagTone.neutral, colors.bg3, colors.tx2),
          (
            FrTagTone.signal,
            colors.signal.withValues(alpha: 0.12 * colors.washK),
            colors.signalFg,
          ),
          (FrTagTone.warn, colors.warn.withValues(alpha: 0.12), colors.warn),
        ];
        for (final (tone, fill, labelColor) in tones) {
          await pumpHost(tester, FrTag(label: 'Anfitrión', tone: tone));
          await tester.pumpAndSettle();

          expect(tester.getSize(find.byType(FrTag)).height, 20);
          expect(find.text('ANFITRIÓN'), findsOneWidget);
          expect(fillOf(decorationOf(tester, find.byType(FrTag))), fill);
          expect(textColor(tester, 'ANFITRIÓN'), labelColor);
        }
      },
    );
  });

  testWidgets(
    'AC6: en el tema claro ningún texto ni trazo de la píldora o la etiqueta '
    'usa signal, salvo el halo verde del punto conectado',
    (tester) async {
      const day = FrColors.light;
      const column = ValueKey('day');
      await pumpHost(
        tester,
        const Column(
          key: column,
          mainAxisSize: MainAxisSize.min,
          children: [
            FrPill(label: 'Conectado'),
            FrPill(label: 'Conectando', tone: FrPillTone.warn, busy: true),
            FrPill(label: 'Sin red local', tone: FrPillTone.alert),
            FrPill(label: 'Cerrada', tone: FrPillTone.off),
            FrTag(label: 'Anfitrión'),
            FrTag(label: '3/3', tone: FrTagTone.signal),
            FrTag(label: 'v1', tone: FrTagTone.warn),
          ],
        ),
        light: true,
      );
      await tester.pump(const Duration(milliseconds: 500));

      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byKey(column),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraphs, isNotEmpty);
      for (final paragraph in paragraphs) {
        expect((paragraph.text as TextSpan).style?.color, isNot(day.signal));
      }
      expect(textColor(tester, '3/3'), day.signalFg);

      final boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(column),
          matching: find.byType(DecoratedBox),
        ),
      );
      for (final box in boxes) {
        if (box.key == const ValueKey('fr-pill-halo')) continue;
        final side = sideOf(box.decoration);
        if (side.style != BorderStyle.none) {
          expect(side.color, isNot(day.signal));
        }
      }
      final firstHalo = find
          .descendant(of: find.byType(FrPill).first, matching: halo)
          .first;
      expect(sideOf(decorationOf(tester, firstHalo)).color, day.signal);
      final busyRing = find.descendant(
        of: find.byType(FrPill).at(1),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox && sideOf(widget.decoration).width == 1.5,
        ),
      );
      expect(busyRing, findsOneWidget);
      expect(
        sideOf(tester.widget<DecoratedBox>(busyRing).decoration).color,
        day.warn,
      );
    },
  );

  group('Movimiento reducido', () {
    testWidgets(
      'AC7: el halo se apaga y el arco se detiene sin ocultar el estado',
      (tester) async {
        await pumpHost(
          tester,
          const FrPill(label: 'Conectado'),
          reduceMotion: true,
        );
        await tester.pumpAndSettle();
        expect(halo, findsNothing);
        expect(fillOf(decorationOf(tester, dot)), colors.signal);

        await pumpHost(
          tester,
          const FrPill(
            key: ValueKey('busy'),
            label: 'Conectando',
            tone: FrPillTone.warn,
            busy: true,
          ),
          reduceMotion: true,
        );
        await tester.pumpAndSettle();
        expect(arc, findsOneWidget);
        final before = tester.getTopLeft(arc);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getTopLeft(arc), before);
      },
    );
  });
}
