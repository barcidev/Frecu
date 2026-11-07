import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Radios de Portadora para esquinas continuas (`RoundedSuperellipseBorder`).
class FrRadii extends ThemeExtension<FrRadii> {
  /// Crea una escala de radios.
  const FrRadii({
    this.xs = 6,
    this.s = 10,
    this.m = 16,
    this.btn = 18,
    this.l = 24,
    this.xl = 32,
    this.sheet = 40,
  });

  FrRadii._fromValues(List<double> v)
    : this(
        xs: v[0],
        s: v[1],
        m: v[2],
        btn: v[3],
        l: v[4],
        xl: v[5],
        sheet: v[6],
      );

  /// Escala del prototipo (`--r-*` y tabla de radios).
  static const FrRadii standard = FrRadii();

  /// 6: etiquetas.
  final double xs;

  /// 10: chips.
  final double s;

  /// 16: campos y teclas.
  final double m;

  /// 18: botones.
  final double btn;

  /// 24: tarjetas.
  final double l;

  /// 32: paneles.
  final double xl;

  /// 40: hojas.
  final double sheet;

  List<double> get _values => [xs, s, m, btn, l, xl, sheet];

  @override
  FrRadii copyWith({
    // dart format off
    double? xs, double? s, double? m, double? btn,
    double? l, double? xl, double? sheet,
    // dart format on
  }) {
    final overrides = [xs, s, m, btn, l, xl, sheet];
    return FrRadii._fromValues([
      for (final (i, value) in _values.indexed) overrides[i] ?? value,
    ]);
  }

  @override
  FrRadii lerp(covariant ThemeExtension<FrRadii>? other, double t) {
    if (other is! FrRadii) return this;
    final to = other._values;
    return FrRadii._fromValues([
      for (final (i, from) in _values.indexed) lerpDouble(from, to[i], t)!,
    ]);
  }
}
