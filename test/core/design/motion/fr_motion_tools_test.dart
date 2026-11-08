// AC1: CUANDO se dibuja la firma de señal de un nombre ENTONCES su razón a:b, fase, giro y deriva salen del hash del nombre igual que en el prototipo, el mismo nombre da la misma firma con otras mayúsculas o espacios en los extremos, y otro nombre da otra.
// AC2: CUANDO el sistema pide reducir el movimiento ENTONCES la firma de señal y el loader de onda dejan de animarse y quedan dibujados en un cuadro fijo, los botones no cambian de escala al presionarse, el campo no tiembla con un error y los pasos cambian sin resorte, sin ocultar el estado (cargando, foco, error y paso actual).
// AC5: CUANDO se muestran los pasos de un recorrido ENTONCES el paso actual es una píldora de señal de 22 × 6 px, los anteriores van en `tx2` y los siguientes en `tx4`, y la píldora pasa al paso nuevo con el resorte `organic`.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_motion.dart';

// Valores de referencia calculados con `engine.js` del prototipo.
void main() {
  group('Ruido del prototipo', () {
    test('AC1: el hash FNV-1a coincide con engine.js', () {
      expect(frHash('jorge'), 829469468);
      expect(frHash('ana'), 338283141);
      expect(frHash('andrés'), 2834231796);
      expect(frHash('·'), 2987121270);
    });

    test('AC1: el aleatorio mulberry32 coincide con engine.js', () {
      final random = FrRandom(42);
      expect(random.next(), closeTo(0.6011037519201636, 1e-15));
      expect(random.next(), closeTo(0.44829055899754167, 1e-15));
      expect(random.next(), closeTo(0.8524657934904099, 1e-15));
    });

    test('AC1: el ruido Perlin y la voz simulada coinciden con engine.js', () {
      expect(frNoise2(0.5, 0.5), closeTo(-0.25, 1e-12));
      expect(frNoise2(1.3, 2.7), closeTo(0.2614472246399999, 1e-12));
      expect(frNoise2(-3.2, 0.37), closeTo(-0.038705237619565874, 1e-12));
      expect(frNoise2(10.25, 4.75), closeTo(-0.2778053283691406, 1e-12));
      expect(frVoice(0), 0);
      expect(frVoice(1.82), closeTo(0.9980906435665062, 1e-9));
      expect(frVoice(2.73), closeTo(0.5267035248227022, 1e-9));
      expect(frVoice(0.5, 2), closeTo(0.14783798877503987, 1e-9));
    });
  });

  group('FrSpringCurve', () {
    test('AC5: va de 0 a 1 y con el resorte organic rebota', () {
      final curve = FrSpringCurve(
        FrMotion.standard.springOrganic,
        const Duration(milliseconds: 520),
      );
      expect(curve.transform(0), 0);
      expect(curve.transform(1), 1);
      expect(curve.transform(0.55), greaterThan(1));
    });

    test('AC2: con el resorte flow llega sin rebote visible', () {
      final curve = FrSpringCurve(
        FrMotion.standard.springFlow,
        const Duration(milliseconds: 460),
      );
      for (var i = 1; i < 20; i++) {
        expect(curve.transform(i / 20), lessThanOrEqualTo(1.01));
      }
    });
  });

  group('FrLoop', () {
    testWidgets(
      'AC2: con movimiento reducido no avanza ni pide cuadros y context.reduceMotion es verdadero',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        ValueListenable<double>? seconds;
        bool? reduce;

        await tester.pumpWidget(
          MaterialApp(
            home: FrLoop(
              builder: (context, time) {
                seconds = time;
                reduce = context.reduceMotion;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        expect(reduce, isTrue);
        expect(seconds!.value, 0);
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets(
      'AC2: sin movimiento reducido avanza y se congela cuando se pide',
      (tester) async {
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        ValueListenable<double>? seconds;
        bool? reduce;

        await tester.pumpWidget(
          MaterialApp(
            home: FrLoop(
              builder: (context, time) {
                seconds = time;
                reduce = context.reduceMotion;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final running = seconds!.value;
        expect(reduce, isFalse);
        expect(running, greaterThan(0.4));

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        await tester.pump();
        final frozen = seconds!.value;
        await tester.pump(const Duration(seconds: 1));

        expect(reduce, isTrue);
        expect(frozen, greaterThanOrEqualTo(running));
        expect(seconds!.value, frozen);
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );
  });
}
