// AC4: CUANDO un texto usa los estilos del tema ENTONCES lleva la familia (Archivo, Martian Mono o Doto), el tamaño, el interlineado, el espaciado y los ejes variables (`wght`, `wdth`, `ROND`) de la escala del prototipo.
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/tokens/fr_motion.dart';
import 'package:frecu/core/design/tokens/fr_radii.dart';
import 'package:frecu/core/design/tokens/fr_space.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';

double? axis(TextStyle style, String tag) {
  for (final variation in style.fontVariations ?? const <FontVariation>[]) {
    if (variation.axis == tag) return variation.value;
  }
  return null;
}

void expectStyle(
  TextStyle style, {
  required String family,
  required double size,
  required double lineHeight,
  required int weight,
  double letterSpacing = 0,
  double? width,
  double? round,
}) {
  expect(style.fontFamily, family);
  expect(style.fontSize, size);
  expect(style.height! * size, closeTo(lineHeight, 0.001));
  expect(style.fontWeight?.value, weight);
  expect(axis(style, 'wght'), weight.toDouble());
  expect(style.letterSpacing ?? 0, closeTo(letterSpacing, 0.001));
  if (width != null) expect(axis(style, 'wdth'), width);
  if (round != null) expect(axis(style, 'ROND'), round);
}

void main() {
  group('FrType', () {
    const type = FrType.standard;

    test('AC4: familias de Portadora', () {
      expect(FrFonts.ui, 'Archivo');
      expect(FrFonts.mono, 'Martian Mono');
      expect(FrFonts.dot, 'Doto');
    });

    test('AC4: escala de Archivo para titulares y lectura', () {
      expectStyle(
        type.display,
        family: FrFonts.ui,
        size: 34,
        lineHeight: 38,
        weight: 720,
        letterSpacing: -0.51,
        width: 125,
      );
      expectStyle(
        type.titleL,
        family: FrFonts.ui,
        size: 24,
        lineHeight: 28,
        weight: 650,
        letterSpacing: -0.24,
        width: 118,
      );
      expectStyle(
        type.title,
        family: FrFonts.ui,
        size: 18,
        lineHeight: 24,
        weight: 620,
        width: 110,
      );
      expectStyle(
        type.bodyL,
        family: FrFonts.ui,
        size: 17,
        lineHeight: 25,
        weight: 400,
        width: 100,
      );
      expectStyle(
        type.body,
        family: FrFonts.ui,
        size: 15,
        lineHeight: 22,
        weight: 400,
        width: 100,
      );
      expectStyle(
        type.bodyS,
        family: FrFonts.ui,
        size: 13,
        lineHeight: 18,
        weight: 400,
        width: 100,
      );
      expectStyle(
        type.button,
        family: FrFonts.ui,
        size: 16,
        lineHeight: 16,
        weight: 640,
        letterSpacing: -0.08,
        width: 112,
      );
    });

    test('AC4: escala de Martian Mono para etiquetas y datos', () {
      expectStyle(
        type.label,
        family: FrFonts.mono,
        size: 11,
        lineHeight: 14,
        weight: 500,
        letterSpacing: 0.88,
        width: 87.5,
      );
      expectStyle(
        type.labelS,
        family: FrFonts.mono,
        size: 9.5,
        lineHeight: 12,
        weight: 500,
        letterSpacing: 0.95,
        width: 87.5,
      );
      expectStyle(
        type.data,
        family: FrFonts.mono,
        size: 13,
        lineHeight: 18,
        weight: 400,
        width: 87.5,
      );
    });

    test('AC4: numerales de señal en Doto redondeada', () {
      expect(type.digits.fontFamily, FrFonts.dot);
      expect(type.digits.fontWeight?.value, 800);
      expect(axis(type.digits, 'wght'), 800);
      expect(axis(type.digits, 'ROND'), 100);
      expect(
        type.digits.letterSpacing,
        closeTo(type.digits.fontSize! * 0.02, 0.001),
      );
    });

    test('AC4: lerp entre extremos devuelve el destino', () {
      final other = type.copyWith(body: type.body.copyWith(fontSize: 20));
      expect(type.lerp(other, 1).body.fontSize, 20);
      expect(type.lerp(other, 0).body.fontSize, 15);
    });
  });

  group('FrSpace, FrRadii y FrMotion', () {
    test('AC4: rejilla de 4 pt', () {
      const space = FrSpace.standard;
      expect(
        [
          space.s1,
          space.s2,
          space.s3,
          space.s4,
          space.s5,
          space.s6,
          space.s8,
          space.s10,
          space.s14,
          space.s18,
        ],
        [4, 8, 12, 16, 20, 24, 32, 40, 56, 72],
      );
    });

    test('AC4: radios de etiquetas a hojas', () {
      const radii = FrRadii.standard;
      expect(
        [radii.xs, radii.s, radii.m, radii.btn, radii.l, radii.xl, radii.sheet],
        [6, 10, 16, 18, 24, 32, 40],
      );
    });

    test('AC4: duraciones, curvas y resortes del prototipo', () {
      final motion = FrMotion.standard;
      expect(motion.instant, const Duration(milliseconds: 90));
      expect(motion.quick, const Duration(milliseconds: 160));
      expect(motion.smooth, const Duration(milliseconds: 280));
      expect(motion.flow, const Duration(milliseconds: 460));
      expect(motion.breath, const Duration(milliseconds: 4200));
      expect(motion.easeOut, const Cubic(0.16, 1, 0.3, 1));
      expect(motion.easeInOut, const Cubic(0.65, 0, 0.35, 1));
      expect(motion.easeIn, const Cubic(0.7, 0, 0.84, 0));
      expect(motion.easeSheet, const Cubic(0.32, 0.72, 0, 1));

      void expectSpring(
        SpringDescription spring,
        double stiffness,
        double ratio,
      ) {
        expect(spring.mass, 1);
        expect(spring.stiffness, stiffness);
        expect(
          spring.damping,
          closeTo(ratio * 2 * math.sqrt(stiffness), 0.0001),
        );
      }

      expectSpring(motion.springPress, 600, 0.62);
      expectSpring(motion.springFlow, 220, 0.9);
      expectSpring(motion.springOrganic, 160, 0.5);
    });

    test('AC4: lerp de espacio y radios', () {
      expect(FrSpace.standard.lerp(FrSpace.standard, 0.5).s4, 16);
      expect(FrRadii.standard.lerp(FrRadii.standard, 0.5).btn, 18);
      final motion = FrMotion.standard;
      expect(motion.lerp(motion, 0.5).flow, motion.flow);
    });
  });
}
