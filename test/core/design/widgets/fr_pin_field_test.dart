// AC1: CUANDO se muestra un `FrPinField` con algunos dígitos ENTONCES dibuja 4 celdas de 64 × 78 px con los dígitos en Doto, un punto `tx4` en las vacías y el cursor de señal (borde de señal y barra `signalFg` que parpadea cada 1,05 s) en la siguiente; el dígito recién escrito aparece con el resorte `organic` desde 0,7, y en solo lectura no hay cursor y el borde es `line2` sin relleno.
// AC2: CUANDO el `FrPinField` pasa a `busy`, `ok` o `error` ENTONCES en `busy` las celdas laten escalonadas con el borde de señal, en `ok` se rellenan de `signal` con los dígitos en `signalInk` y una ola escalonada de 70 ms, y en `error` los dígitos y bordes van en alerta y la fila tiembla una vez durante 560 ms.
// AC3: CUANDO se toca una tecla de `FrKeypad` ENTONCES la tecla (56 px de alto, 3 columnas: 1–9, función opcional, 0 y borrar) se hunde a 0,93 con el resorte `press` y pasa a `bg3`, y el teclado llama a `onDigit` con su dígito, a `onDelete` o a la acción de la tecla de función; borrar y la función tienen su etiqueta accesible.
// AC7: CUANDO el sistema pide reducir el movimiento ENTONCES el cursor del PIN queda fijo y visible, el dígito no salta, la fila no tiembla, la ola de `ok` no se mueve y `busy` queda quieto con su borde de señal; las teclas no se hunden, el pulgar y la perilla cambian de lugar sin resorte ni estiramiento, el halo de la píldora se apaga y su arco se detiene, sin ocultar ningún estado (cursor, ocupado, correcto, error, selección y encendido).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/core/design/widgets/fr_keypad.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';

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

Finder cell(int index) => find.byKey(ValueKey('fr-pin-cell-$index'));

Finder dot(int index) => find.byKey(ValueKey('fr-pin-dot-$index'));

final Finder caret = find.byKey(const ValueKey('fr-pin-caret'));

Finder key(String id) => find.byKey(ValueKey('fr-key-$id'));

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

Color borderOf(WidgetTester tester, int index) =>
    sideOf(decorationOf(tester, cell(index))).color;

TextStyle digitStyle(WidgetTester tester, String digit) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.byType(FrPinField), matching: find.text(digit)),
  );
  return (paragraph.text as TextSpan).style!;
}

void expectNear(Color actual, Color expected) {
  expect(actual.a, closeTo(expected.a, 0.02));
  expect(actual.r, closeTo(expected.r, 0.02));
  expect(actual.g, closeTo(expected.g, 0.02));
  expect(actual.b, closeTo(expected.b, 0.02));
}

FrKeypad keypad({
  ValueChanged<int>? onDigit,
  VoidCallback? onDelete,
  VoidCallback? onLeading,
}) => FrKeypad(
  onDigit: onDigit ?? (_) {},
  onDelete: onDelete ?? () {},
  deleteLabel: 'Borrar',
  leading: const Icon(Icons.refresh),
  leadingLabel: 'Generar otro',
  onLeading: onLeading ?? () {},
);

void main() {
  group('FrPinField', () {
    testWidgets(
      'AC1: dibuja 4 celdas de 64 × 78 con los dígitos en Doto, un punto en las vacías y el cursor en la siguiente',
      (tester) async {
        await pumpHost(tester, const FrPinField(value: '48'));
        await tester.pump(const Duration(milliseconds: 200));

        for (var i = 0; i < 4; i++) {
          expect(tester.getSize(cell(i)), const Size(64, 78));
        }
        expect(cell(4), findsNothing);

        final style = digitStyle(tester, '4');
        expect(style.fontFamily, FrFonts.dot);
        expect(style.fontSize, 46);
        expect(style.color, colors.tx1);
        expect(digitStyle(tester, '8').color, colors.tx1);
        expect(fillOf(decorationOf(tester, cell(0))), colors.bg2);
        expect(borderOf(tester, 0), colors.line1);

        expect(borderOf(tester, 2), colors.signal.withValues(alpha: 0.6));
        expect(find.descendant(of: cell(2), matching: caret), findsOneWidget);
        expect(tester.getSize(caret), const Size(2, 30));
        expect(fillOf(decorationOf(tester, caret)), colors.signalFg);
        expect(dot(2), findsNothing);

        expect(borderOf(tester, 3), colors.line1);
        expect(tester.getSize(dot(3)), const Size(6, 6));
        expect(fillOf(decorationOf(tester, dot(3))), colors.tx4);
        expect(dot(0), findsNothing);
      },
    );

    testWidgets('AC1: el cursor parpadea cada 1,05 s', (tester) async {
      await pumpHost(tester, const FrPinField(value: '4'));

      await tester.pump(const Duration(milliseconds: 200));
      expect(caret, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      expect(caret, findsNothing);
      expect(borderOf(tester, 1), colors.signal.withValues(alpha: 0.6));

      await tester.pump(const Duration(milliseconds: 400));
      expect(caret, findsOneWidget);
    });

    testWidgets(
      'AC1: el dígito recién escrito aparece con el resorte organic desde 0,7',
      (tester) async {
        await pumpHost(tester, const FrPinField(value: '4'));
        await tester.pump(const Duration(milliseconds: 100));

        await pumpHost(tester, const FrPinField(value: '48'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final early = tester.getRect(cell(1)).width;
        expect(early, greaterThan(64 * 0.65));
        expect(early, lessThan(64 * 0.8));
        expect(tester.getRect(cell(0)).width, closeTo(64, 0.01));

        await tester.pump(const Duration(milliseconds: 274));
        expect(tester.getRect(cell(1)).width, greaterThan(64));

        await tester.pump(const Duration(seconds: 1));
        expect(tester.getRect(cell(1)).width, closeTo(64, 0.01));
      },
    );

    testWidgets(
      'AC1: en solo lectura no hay cursor y el borde es line2 sin relleno',
      (tester) async {
        await pumpHost(tester, const FrPinField(value: '48', readOnly: true));
        await tester.pumpAndSettle();

        expect(caret, findsNothing);
        for (var i = 0; i < 4; i++) {
          expect(borderOf(tester, i), colors.line2);
          final fill = fillOf(decorationOf(tester, cell(i)));
          expect(fill == null || fill.a == 0, isTrue);
        }
      },
    );

    testWidgets(
      'AC2: ocupado, las celdas laten escalonadas con el borde de señal',
      (tester) async {
        await pumpHost(
          tester,
          const FrPinField(value: '4827', state: FrPinState.busy),
        );

        await tester.pump(const Duration(milliseconds: 550));
        final first = borderOf(tester, 0);
        expectNear(first, colors.signal.withValues(alpha: 0.6));
        expect(borderOf(tester, 3).a, lessThan(first.a - 0.15));

        await tester.pump(const Duration(milliseconds: 550));
        expect(borderOf(tester, 0).a, lessThan(0.2));
      },
    );

    testWidgets(
      'AC2: correcto, se rellenan de señal con los dígitos en signalInk tras una ola escalonada',
      (tester) async {
        await pumpHost(tester, const FrPinField(value: '4827'));
        await tester.pumpAndSettle();
        final rest = [for (var i = 0; i < 4; i++) tester.getRect(cell(i)).top];

        await pumpHost(
          tester,
          const FrPinField(value: '4827', state: FrPinState.ok),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.getRect(cell(0)).top, lessThan(rest[0] - 1));
        expect(tester.getRect(cell(3)).top, closeTo(rest[3], 0.01));

        await tester.pumpAndSettle();
        for (var i = 0; i < 4; i++) {
          expect(tester.getRect(cell(i)).top, closeTo(rest[i], 0.01));
          expect(fillOf(decorationOf(tester, cell(i))), colors.signal);
        }
        expect(digitStyle(tester, '4').color, colors.signalInk);
        expect(digitStyle(tester, '7').color, colors.signalInk);
      },
    );

    testWidgets(
      'AC2: con error los dígitos y bordes van en alerta y la fila tiembla una vez',
      (tester) async {
        await pumpHost(tester, const FrPinField(value: '4827'));
        await tester.pumpAndSettle();
        final rest = tester.getRect(cell(0)).left;

        await pumpHost(
          tester,
          const FrPinField(value: '4827', state: FrPinState.error),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect((tester.getRect(cell(0)).left - rest).abs(), greaterThan(1));

        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.getRect(cell(0)).left, closeTo(rest, 0.01));

        await tester.pumpAndSettle();
        expect(borderOf(tester, 0), colors.alert.withValues(alpha: 0.65));
        expect(borderOf(tester, 3), colors.alert.withValues(alpha: 0.65));
        expect(digitStyle(tester, '4').color, colors.alert);
      },
    );
  });

  group('FrKeypad', () {
    testWidgets(
      'AC3: teclas de 56 px en 3 columnas: 1–9, función, 0 y borrar',
      (tester) async {
        await pumpHost(tester, keypad());

        for (var d = 0; d <= 9; d++) {
          expect(tester.getSize(key('$d')).height, 56);
          expect(
            find.descendant(of: key('$d'), matching: find.text('$d')),
            findsOneWidget,
          );
        }
        expect(tester.getSize(key('fn')).height, 56);
        expect(tester.getSize(key('del')).height, 56);

        const rows = [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['fn', '0', 'del'],
        ];
        for (final (r, row) in rows.indexed) {
          for (final (c, id) in row.indexed) {
            final rect = tester.getRect(key(id));
            expect(
              rect.top,
              closeTo(tester.getRect(key(rows[r][0])).top, 0.01),
            );
            expect(
              rect.left,
              closeTo(tester.getRect(key(rows[0][c])).left, 0.01),
            );
          }
          if (r > 0) {
            expect(
              tester.getRect(key(row[0])).top,
              greaterThan(tester.getRect(key(rows[r - 1][0])).bottom),
            );
          }
        }
        expect(
          tester.getRect(key('2')).left,
          greaterThan(tester.getRect(key('1')).right),
        );
        expect(
          tester.getRect(key('3')).left,
          greaterThan(tester.getRect(key('2')).right),
        );
      },
    );

    testWidgets(
      'AC3: la tecla se hunde a 0,93 con el resorte press, pasa a bg3 y entrega su dígito',
      (tester) async {
        final digits = <int>[];
        await pumpHost(tester, keypad(onDigit: digits.add));
        final rest = tester.getRect(key('7')).width;
        expect(fillOf(decorationOf(tester, key('7'))), colors.bg1);

        final gesture = await tester.startGesture(tester.getCenter(key('7')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.getRect(key('7')).width / rest, closeTo(0.93, 0.003));
        expect(fillOf(decorationOf(tester, key('7'))), colors.bg3);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.getRect(key('7')).width, closeTo(rest, 0.01));
        expect(fillOf(decorationOf(tester, key('7'))), colors.bg1);
        expect(digits, [7]);
      },
    );

    testWidgets(
      'AC3: borrar y la tecla de función llaman a su acción y tienen etiqueta accesible',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final digits = <int>[];
        var deletes = 0;
        var leads = 0;
        await pumpHost(
          tester,
          keypad(
            onDigit: digits.add,
            onDelete: () => deletes++,
            onLeading: () => leads++,
          ),
        );

        expect(find.bySemanticsLabel('Borrar'), findsOneWidget);
        expect(find.bySemanticsLabel('Generar otro'), findsOneWidget);

        await tester.tap(key('del'));
        await tester.pumpAndSettle();
        await tester.tap(key('fn'));
        await tester.pumpAndSettle();
        await tester.tap(key('0'));
        await tester.pumpAndSettle();

        expect(deletes, 1);
        expect(leads, 1);
        expect(digits, [0]);
        semantics.dispose();
      },
    );
  });

  group('Movimiento reducido', () {
    testWidgets(
      'AC7: el cursor queda fijo y visible y el dígito nuevo no salta',
      (tester) async {
        await pumpHost(
          tester,
          const FrPinField(value: '4'),
          reduceMotion: true,
        );
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 230));
          expect(caret, findsOneWidget);
        }

        await pumpHost(
          tester,
          const FrPinField(value: '48'),
          reduceMotion: true,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.getRect(cell(1)).width, closeTo(64, 0.01));

        await tester.pump(const Duration(milliseconds: 300));
        expect(find.descendant(of: cell(2), matching: caret), findsOneWidget);
        expect(borderOf(tester, 2), colors.signal.withValues(alpha: 0.6));
      },
    );

    testWidgets(
      'AC7: el error no tiembla y la ola de correcto no se mueve, pero los estados se ven',
      (tester) async {
        await pumpHost(
          tester,
          const FrPinField(value: '4827'),
          reduceMotion: true,
        );
        await tester.pumpAndSettle();
        final rest = tester.getRect(cell(0));

        await pumpHost(
          tester,
          const FrPinField(value: '4827', state: FrPinState.error),
          reduceMotion: true,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.getRect(cell(0)).left, closeTo(rest.left, 0.01));
        await tester.pumpAndSettle();
        expect(borderOf(tester, 0), colors.alert.withValues(alpha: 0.65));
        expect(digitStyle(tester, '4').color, colors.alert);

        await pumpHost(
          tester,
          const FrPinField(value: '4827', state: FrPinState.ok),
          reduceMotion: true,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.getRect(cell(0)).top, closeTo(rest.top, 0.01));
        await tester.pumpAndSettle();
        expect(fillOf(decorationOf(tester, cell(0))), colors.signal);
        expect(digitStyle(tester, '4').color, colors.signalInk);
      },
    );

    testWidgets('AC7: ocupado queda quieto con su borde de señal', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const FrPinField(value: '4827', state: FrPinState.busy),
        reduceMotion: true,
      );
      await tester.pumpAndSettle();

      for (final wait in [0, 300, 550]) {
        await tester.pump(Duration(milliseconds: wait));
        for (var i = 0; i < 4; i++) {
          expectNear(borderOf(tester, i), colors.signal.withValues(alpha: 0.6));
        }
        expectNear(digitStyle(tester, '4').color!, colors.signalFg);
      }
    });

    testWidgets('AC7: las teclas no se hunden y siguen respondiendo', (
      tester,
    ) async {
      final digits = <int>[];
      await pumpHost(tester, keypad(onDigit: digits.add), reduceMotion: true);
      final rest = tester.getRect(key('5')).width;

      final gesture = await tester.startGesture(tester.getCenter(key('5')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getRect(key('5')).width, closeTo(rest, 0.01));
      expect(fillOf(decorationOf(tester, key('5'))), colors.bg3);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(digits, [5]);
    });
  });
}
