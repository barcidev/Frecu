import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';

const _home = Key('home');
const _next = Key('next');

/// El gesto es de iOS.
final _ios = TargetPlatformVariant.only(TargetPlatform.iOS);

/// Inicio con una segunda pantalla de Portadora encima, entrada del todo.
Future<NavigatorState> pumpPushed(
  WidgetTester tester, {
  FrTransition transition = FrTransition.slide,
  bool canPop = true,
}) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: AppTheme.dark,
      home: const ColoredBox(key: _home, color: Colors.black),
    ),
  );
  unawaited(
    navigator.currentState!.push(
      FrPageRoute<void>(
        transition: transition,
        builder: (_) => PopScope(
          canPop: canPop,
          child: const ColoredBox(key: _next, color: Colors.white),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(_next), findsOneWidget);
  return navigator.currentState!;
}

void main() {
  group('Gesto de volver desde el borde (iOS)', () {
    testWidgets('deslizar desde el borde más allá de la mitad vuelve atrás', (
      tester,
    ) async {
      await pumpPushed(tester);

      await tester.timedDragFrom(
        const Offset(5, 300),
        const Offset(500, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(_next), findsNothing);
      expect(find.byKey(_home), findsOneWidget);
    }, variant: _ios);

    testWidgets('un lanzamiento corto hacia atrás también vuelve', (
      tester,
    ) async {
      await pumpPushed(tester, transition: FrTransition.wave);

      await tester.flingFrom(const Offset(5, 300), const Offset(120, 0), 1500);
      await tester.pumpAndSettle();

      expect(find.byKey(_next), findsNothing);
    }, variant: _ios);

    testWidgets('un arrastre corto y lento deja la pantalla donde estaba', (
      tester,
    ) async {
      final navigator = await pumpPushed(tester);

      await tester.timedDragFrom(
        const Offset(5, 300),
        const Offset(60, 0),
        const Duration(milliseconds: 800),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(_next), findsOneWidget);
      expect(navigator.userGestureInProgress, isFalse);
    }, variant: _ios);

    testWidgets('fuera del borde no empieza el gesto', (tester) async {
      await pumpPushed(tester);

      await tester.timedDragFrom(
        const Offset(200, 300),
        const Offset(500, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(_next), findsOneWidget);
    }, variant: _ios);

    testWidgets('si la pantalla no deja salir (PopScope) no vuelve', (
      tester,
    ) async {
      await pumpPushed(tester, canPop: false);

      await tester.timedDragFrom(
        const Offset(5, 300),
        const Offset(500, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(_next), findsOneWidget);
    }, variant: _ios);
  });

  testWidgets('en Android no hay gesto desde el borde', (tester) async {
    await pumpPushed(tester);

    await tester.timedDragFrom(
      const Offset(5, 300),
      const Offset(500, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_next), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
