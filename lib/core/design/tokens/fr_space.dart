import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Espaciado de Portadora sobre una rejilla de 4 pt.
class FrSpace extends ThemeExtension<FrSpace> {
  /// Crea una escala de espaciado.
  const FrSpace({
    this.s1 = 4,
    this.s2 = 8,
    this.s3 = 12,
    this.s4 = 16,
    this.s5 = 20,
    this.s6 = 24,
    this.s8 = 32,
    this.s10 = 40,
    this.s14 = 56,
    this.s18 = 72,
  });

  FrSpace._fromValues(List<double> v)
    : this(
        s1: v[0],
        s2: v[1],
        s3: v[2],
        s4: v[3],
        s5: v[4],
        s6: v[5],
        s8: v[6],
        s10: v[7],
        s14: v[8],
        s18: v[9],
      );

  /// Escala del prototipo (`--s1` a `--s18`).
  static const FrSpace standard = FrSpace();

  /// 4 pt.
  final double s1;

  /// 8 pt.
  final double s2;

  /// 12 pt.
  final double s3;

  /// 16 pt.
  final double s4;

  /// 20 pt: margen de pantalla (`.pad` y el dock del prototipo).
  final double s5;

  /// 24 pt.
  final double s6;

  /// 32 pt.
  final double s8;

  /// 40 pt.
  final double s10;

  /// 56 pt: objetivo táctil mínimo (con guantes, «56 dp o más»).
  final double s14;

  /// 72 pt.
  final double s18;

  List<double> get _values => [s1, s2, s3, s4, s5, s6, s8, s10, s14, s18];

  @override
  FrSpace copyWith({
    // dart format off
    double? s1, double? s2, double? s3, double? s4, double? s5,
    double? s6, double? s8, double? s10, double? s14, double? s18,
    // dart format on
  }) {
    final overrides = [s1, s2, s3, s4, s5, s6, s8, s10, s14, s18];
    return FrSpace._fromValues([
      for (final (i, value) in _values.indexed) overrides[i] ?? value,
    ]);
  }

  @override
  FrSpace lerp(covariant ThemeExtension<FrSpace>? other, double t) {
    if (other is! FrSpace) return this;
    final to = other._values;
    return FrSpace._fromValues([
      for (final (i, from) in _values.indexed) lerpDouble(from, to[i], t)!,
    ]);
  }
}
