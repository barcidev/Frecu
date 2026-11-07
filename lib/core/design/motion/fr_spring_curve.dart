import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Curva que sigue un resorte de 0 a 1 durante [duration].
///
/// Sirve para animaciones implícitas con los resortes de `FrMotion` (por
/// ejemplo `springOrganic` en los pasos). Si el resorte rebota, la curva pasa
/// de 1 antes de terminar; en `t = 1` siempre vale 1.
class FrSpringCurve extends Curve {
  /// Curva del resorte [spring] recorrida en [duration].
  FrSpringCurve(this.spring, this.duration)
    : _simulation = SpringSimulation(spring, 0, 1, 0);

  /// Resorte que mueve la curva.
  final SpringDescription spring;

  /// Duración de la animación que usa la curva.
  final Duration duration;

  final SpringSimulation _simulation;

  @override
  double transformInternal(double t) => _simulation.x(
    t * duration.inMicroseconds / Duration.microsecondsPerSecond,
  );
}
