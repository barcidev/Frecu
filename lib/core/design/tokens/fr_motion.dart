import 'package:flutter/material.dart';

/// Movimiento de Portadora: duraciones, curvas y resortes.
///
/// Los resortes se usan con `SpringSimulation`; las curvas, en transiciones
/// con duración fija. Ninguno se interpola entre temas.
class FrMotion extends ThemeExtension<FrMotion> {
  /// Crea un juego de movimiento.
  const FrMotion({
    required this.springPress,
    required this.springFlow,
    required this.springOrganic,
    this.instant = const Duration(milliseconds: 90),
    this.quick = const Duration(milliseconds: 160),
    this.smooth = const Duration(milliseconds: 280),
    this.flow = const Duration(milliseconds: 460),
    this.breath = const Duration(milliseconds: 4200),
    this.easeOut = const Cubic(0.16, 1, 0.3, 1),
    this.easeInOut = const Cubic(0.65, 0, 0.35, 1),
    this.easeIn = const Cubic(0.7, 0, 0.84, 0),
    this.easeSheet = const Cubic(0.32, 0.72, 0, 1),
  });

  FrMotion._fromValues(List<Object> v)
    : this(
        springPress: v[0] as SpringDescription,
        springFlow: v[1] as SpringDescription,
        springOrganic: v[2] as SpringDescription,
        instant: v[3] as Duration,
        quick: v[4] as Duration,
        smooth: v[5] as Duration,
        flow: v[6] as Duration,
        breath: v[7] as Duration,
        easeOut: v[8] as Curve,
        easeInOut: v[9] as Curve,
        easeIn: v[10] as Curve,
        easeSheet: v[11] as Curve,
      );

  /// Movimiento del prototipo (`--t-*`, `--e-*` y `spring.*`).
  static final FrMotion standard = FrMotion(
    springPress: SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: 600,
      ratio: 0.62,
    ),
    springFlow: SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: 220,
      ratio: 0.9,
    ),
    springOrganic: SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: 160,
      ratio: 0.5,
    ),
  );

  /// Responde: botones y teclas hunden rápido y rebotan apenas.
  final SpringDescription springPress;

  /// Fluye: navegación, hojas y aguja del sintonizador, sin rebote visible.
  final SpringDescription springFlow;

  /// Orgánico: pulgares líquidos, isla de estado y nodos de la malla.
  final SpringDescription springOrganic;

  /// 90 ms: respuesta inmediata.
  final Duration instant;

  /// 160 ms: cambios rápidos y salidas.
  final Duration quick;

  /// 280 ms: entradas suaves.
  final Duration smooth;

  /// 460 ms: entradas amplias.
  final Duration flow;

  /// 4,2 s: ciclo de respiración en reposo.
  final Duration breath;

  /// Entra: rápido al inicio y suave al final.
  final Curve easeOut;

  /// Cambio de estado simétrico.
  final Curve easeInOut;

  /// Sale: acelera y no compite con lo que entra.
  final Curve easeIn;

  /// Hojas modales.
  final Curve easeSheet;

  List<Object> get _values => [
    // dart format off
    springPress, springFlow, springOrganic, instant, quick, smooth,
    flow, breath, easeOut, easeInOut, easeIn, easeSheet,
    // dart format on
  ];

  @override
  FrMotion copyWith({
    // dart format off
    SpringDescription? springPress, SpringDescription? springFlow,
    SpringDescription? springOrganic, Duration? instant, Duration? quick,
    Duration? smooth, Duration? flow, Duration? breath, Curve? easeOut,
    Curve? easeInOut, Curve? easeIn, Curve? easeSheet,
    // dart format on
  }) {
    final overrides = <Object?>[
      // dart format off
      springPress, springFlow, springOrganic, instant, quick, smooth,
      flow, breath, easeOut, easeInOut, easeIn, easeSheet,
      // dart format on
    ];
    return FrMotion._fromValues([
      for (final (i, value) in _values.indexed) overrides[i] ?? value,
    ]);
  }

  @override
  FrMotion lerp(covariant ThemeExtension<FrMotion>? other, double t) {
    if (other is! FrMotion) return this;
    return t < 0.5 ? this : other;
  }
}
