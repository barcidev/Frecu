// AC1: CUANDO una pantalla usa `FrScaffold` ENTONCES se pinta sobre `bg0` con la retícula de puntos cada 22 px en tinta al 6 % que se desvanece hacia el 55 % del alto y con un grano generado por código (mosaico de 128 px de ruido sembrado, igual en cada arranque y creado una sola vez), en tema claro y oscuro y sin assets.
// AC3: CUANDO se navega con las transiciones de Portadora ENTONCES onda revela la pantalla nueva en un círculo que crece desde el último toque con un aro de señal en 760 ms mientras la anterior se encoge y se oscurece; deslizamiento la trae desde la derecha en 560 ms mientras la anterior se corre al −28 % y se oscurece; expansión hace crecer la superficie de la hoja desde su rectángulo hasta ocupar la pantalla y luego funde la pantalla nueva; y volver desliza la pantalla hacia la derecha.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';

Future<void> pumpScaffold(
  WidgetTester tester,
  FrScaffold scaffold, {
  ThemeData? theme,
}) => tester.pumpWidget(
  MaterialApp(theme: theme ?? AppTheme.dark, home: scaffold),
);

bool isGridCall(Symbol method, List<dynamic> arguments) =>
    method == #drawRawPoints || method == #drawPoints;

bool isGrainCall(Symbol method, List<dynamic> arguments) =>
    method == #drawRect && (arguments[1] as Paint).shader != null;

void main() {
  group('FrScaffold', () {
    testWidgets(
      'AC1: pinta bg0, la retícula y el grano en tema oscuro y claro',
      (tester) async {
        for (final (theme, colors) in [
          (AppTheme.dark, FrColors.dark),
          (AppTheme.light, FrColors.light),
        ]) {
          await pumpScaffold(
            tester,
            const FrScaffold(body: Text('Hola')),
            theme: theme,
          );

          expect(
            tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
            colors.bg0,
          );
          expect(find.text('Hola'), findsOneWidget);
          final backdrop = find.byType(FrBackdrop);
          expect(backdrop, findsOneWidget);
          expect(
            find.descendant(
              of: backdrop,
              matching: find.byType(RepaintBoundary),
            ),
            findsWidgets,
          );
          expect(
            backdrop,
            paints
              ..something(isGridCall)
              ..something(isGrainCall),
          );
        }
      },
    );

    testWidgets('AC1: la retícula y el grano se pueden apagar', (tester) async {
      await pumpScaffold(
        tester,
        const FrScaffold(body: Text('Hola'), showGrid: false, showGrain: false),
      );

      expect(find.byType(FrBackdrop), paintsNothing);
    });

    test('AC1: la retícula tiene un punto cada 22 px en tinta al 6 % que se desvanece hasta el 55 % del alto', () {
      const size = Size(390, 844);
      final dots = FrBackdrop.gridDots(size);

      expect(dots.first.center, const Offset(11, 11));
      expect(dots.first.opacity, closeTo(0.06 * (1 - 11 / (0.55 * 844)), 1e-6));
      final columns = dots.map((dot) => dot.center.dx).toSet().toList()..sort();
      expect(columns.length, 18);
      expect(columns[1] - columns[0], 22);
      final rows = dots.map((dot) => dot.center.dy).toSet().toList()..sort();
      expect(rows[1] - rows[0], 22);
      expect(dots.every((dot) => dot.center.dy < 0.55 * 844), isTrue);
      expect(
        dots.every((dot) => dot.opacity > 0 && dot.opacity <= 0.06),
        isTrue,
      );
      final lower = dots.firstWhere((dot) => dot.center.dy == rows.last);
      expect(lower.opacity, lessThan(dots.first.opacity));
    });

    test(
      'AC1: el grano es ruido sembrado de 128 × 128 px, igual en cada arranque',
      () {
        final alphas = FrGrain.alphas();

        expect(FrGrain.size, 128);
        expect(alphas.length, 128 * 128);
        expect(alphas, equals(FrGrain.alphas()));
        expect(alphas.toSet().length, greaterThan(16));
        expect(alphas.reduce(math.max), lessThanOrEqualTo((0.55 * 255).ceil()));
      },
    );

    testWidgets('AC1: el mosaico del grano se crea una sola vez', (
      tester,
    ) async {
      final tile = FrGrain.tile;

      expect(identical(tile, FrGrain.tile), isTrue);
      expect(tile.width, 128);
      expect(tile.height, 128);
    });

    testWidgets('AC1: el dock queda abajo sobre un degradado hacia bg0', (
      tester,
    ) async {
      await pumpScaffold(
        tester,
        const FrScaffold(body: Text('Contenido'), dock: Text('Dock')),
      );

      final dock = tester.getRect(find.text('Dock'));
      expect(dock.bottom, closeTo(600 - 30, 1));
      expect(dock.left, closeTo(20, 1));
      final fades = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FrScaffold),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.gradient)
          .whereType<LinearGradient>();
      expect(
        fades.any(
          (gradient) =>
              gradient.colors.last == FrColors.dark.bg0 &&
              gradient.colors.first.a == 0,
        ),
        isTrue,
      );
    });

    testWidgets('AC3: registra el último toque como origen de la onda', (
      tester,
    ) async {
      FrTouchOrigin.clear();
      addTearDown(FrTouchOrigin.clear);
      await pumpScaffold(tester, const FrScaffold(body: SizedBox.expand()));

      await tester.tapAt(const Offset(150, 420));

      expect(FrTouchOrigin.last, const Offset(150, 420));
    });
  });
}
