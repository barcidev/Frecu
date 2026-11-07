// AC1: CUANDO se dibuja la firma de señal de un nombre ENTONCES su razón a:b, fase, giro y deriva salen del hash del nombre igual que en el prototipo, el mismo nombre da la misma firma con otras mayúsculas o espacios en los extremos, y otro nombre da otra.
// AC2: CUANDO el sistema pide reducir el movimiento ENTONCES la firma de señal y el loader de onda dejan de animarse y quedan dibujados en un cuadro fijo, los botones no cambian de escala al presionarse, el campo no tiembla con un error y los pasos cambian sin resorte, sin ocultar el estado (cargando, foco, error y paso actual).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';

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
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Finder painterOf(Type type) => find
    .descendant(of: find.byType(type), matching: find.byType(CustomPaint))
    .first;

// Valores de referencia calculados con `sigParams` de `engine.js`.
void main() {
  group('SignatureParams', () {
    test(
      'AC1: la firma de un nombre sale del hash igual que en el prototipo',
      () {
        final jorge = SignatureParams.fromName('Jorge');
        expect(jorge.a, 5);
        expect(jorge.b, 4);
        expect(jorge.phase, closeTo(1.9318240922733172, 1e-12));
        expect(jorge.rot, closeTo(0.08674794703256339, 1e-12));
        expect(jorge.drift, closeTo(0.13210715621244162, 1e-12));

        final andres = SignatureParams.fromName('Andrés');
        expect(andres.a, 4);
        expect(andres.b, 5);
        expect(andres.phase, closeTo(5.403594661658606, 1e-12));
        expect(andres.rot, closeTo(0.31155825743917376, 1e-12));
        expect(andres.drift, closeTo(0.131760540145915, 1e-12));
      },
    );

    test('AC1: mayúsculas y espacios en los extremos no cambian la firma; otro nombre sí', () {
      final jorge = SignatureParams.fromName('Jorge');
      expect(SignatureParams.fromName('  jorge '), jorge);
      expect(SignatureParams.fromName('JORGE'), jorge);

      final ana = SignatureParams.fromName('Ana');
      expect(ana, isNot(jorge));
      expect(ana.a, 2);
      expect(ana.b, 3);
      expect(ana.phase, closeTo(5.308513405599787, 1e-12));
    });

    test('AC1: sin nombre usa la firma de "·" como el prototipo', () {
      final empty = SignatureParams.fromName('');
      expect(empty.a, 1);
      expect(empty.b, 2);
      expect(empty.phase, closeTo(5.859201837926262, 1e-12));
    });
  });

  group('SignalSignature y WaveLoader', () {
    testWidgets('AC1: dibuja la curva de la firma con el tamaño pedido', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const SignalSignature(name: 'Jorge', size: 120),
        reduceMotion: true,
      );
      await tester.pump();

      expect(
        tester.getSize(find.byType(SignalSignature)),
        const Size(120, 120),
      );
      expect(painterOf(SignalSignature), paints..path());
    });

    testWidgets('AC2: sin movimiento reducido la firma y la onda se animan', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SignalSignature(name: 'Ana', size: 96, mode: SignatureMode.speak),
            WaveLoader(),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'AC2: con movimiento reducido la firma y la onda quedan dibujadas en un cuadro fijo',
      (tester) async {
        await pumpHost(
          tester,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SignalSignature(name: 'Ana', size: 96, mode: SignatureMode.speak),
              WaveLoader(),
            ],
          ),
          reduceMotion: true,
        );
        await tester.pump(const Duration(seconds: 1));

        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(
          tester.getSize(find.byType(SignalSignature)),
          const Size(96, 96),
        );
        expect(tester.getSize(find.byType(WaveLoader)), const Size(64, 22));
        expect(painterOf(SignalSignature), paints..path());
        expect(painterOf(WaveLoader), paints..path());
      },
    );
  });
}
