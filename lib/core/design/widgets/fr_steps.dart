import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';

/// Pasos de un recorrido (bienvenida, nombre y permisos).
///
/// Los pasos son puntos de 6 px: el actual es una píldora de señal de 22 px,
/// los anteriores van en `tx2` y los siguientes en `tx4`. La píldora pasa al
/// paso nuevo con el resorte `organic`; con movimiento reducido, sin resorte.
class FrSteps extends StatelessWidget {
  /// Crea [count] pasos con [current] encendido (desde 0).
  const FrSteps({required this.count, required this.current, super.key});

  /// Número de pasos.
  final int count;

  /// Paso actual, desde 0.
  final int current;

  static const double _dot = 6;
  static const double _pill = 22;
  static const Duration _travel = Duration(milliseconds: 520);

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final reduce = context.reduceMotion;
    final curve = reduce
        ? Curves.linear
        : FrSpringCurve(fr.motion.springOrganic, _travel);
    final duration = reduce ? fr.motion.quick : _travel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: _dot),
          TweenAnimationBuilder<double>(
            key: ValueKey('fr-step-$i'),
            tween: Tween<double>(end: i == current ? _pill : _dot),
            duration: duration,
            curve: curve,
            builder: (context, width, child) =>
                SizedBox(width: width, height: _dot, child: child),
            child: _dotBox(fr, i),
          ),
        ],
      ],
    );
  }

  Widget _dotBox(FrTheme fr, int index) {
    final c = fr.colors;
    final ring = c.ledRing;
    final on = index == current;
    final color = on
        ? c.signal
        : index < current
        ? c.tx2
        : c.tx4;
    return AnimatedContainer(
      duration: fr.motion.smooth,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_dot / 2),
        border: on && ring != null
            ? Border.all(color: ring, width: 1.25)
            : null,
      ),
    );
  }
}
