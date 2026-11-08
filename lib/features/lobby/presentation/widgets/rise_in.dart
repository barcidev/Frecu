import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';

/// Entrada `rise` del prototipo (`.list .rtile`): al aparecer, [child] sube
/// 18 px, crece desde 0,98 y se enciende con el resorte `flow` en 700 ms,
/// tras [delay].
///
/// Solo anima al montarse: si [child] cambia después, no vuelve a entrar.
/// Con movimiento reducido solo se funde, sin moverse.
class RiseIn extends StatefulWidget {
  /// Hace entrar a [child] tras [delay].
  const RiseIn({required this.child, this.delay = Duration.zero, super.key});

  /// Lo que entra.
  final Widget child;

  /// Espera antes de entrar (el escalonado de la lista).
  final Duration delay;

  /// Duración de la subida.
  static const Duration duration = Duration(milliseconds: 700);

  /// Escalonado entre tarjetas: la segunda espera 80 ms y la tercera y
  /// siguientes, 160 ms.
  static Duration staggerOf(int index) =>
      Duration(milliseconds: 80 * index.clamp(0, 2));

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: widget.delay + RiseIn.duration,
  )..forward();

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final reduce = context.reduceMotion;
    final total = _rise.duration!.inMicroseconds;
    final start = total == 0 ? 0.0 : widget.delay.inMicroseconds / total;
    final curve = Interval(
      start,
      1,
      curve: reduce
          ? fr.motion.easeOut
          : FrSpringCurve(fr.motion.springFlow, RiseIn.duration),
    );
    return AnimatedBuilder(
      animation: _rise,
      child: widget.child,
      builder: (context, child) {
        // La misma estructura de principio a fin: el contenido no se vuelve
        // a crear al terminar.
        final shown = _rise.isCompleted ? 1.0 : curve.transform(_rise.value);
        final move = reduce ? 1.0 : shown;
        return Opacity(
          opacity: shown.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - move)),
            child: Transform.scale(scale: 0.98 + 0.02 * move, child: child),
          ),
        );
      },
    );
  }
}
