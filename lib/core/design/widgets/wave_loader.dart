import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';

/// Loader de onda de Portadora: reemplaza a los spinners.
///
/// Dos senos con envolvente que corren hacia la derecha (`drawWave` del
/// prototipo). Con movimiento reducido queda en un cuadro fijo y visible.
class WaveLoader extends StatelessWidget {
  /// Crea un loader de [width] × [height] px.
  const WaveLoader({
    this.width = 64,
    this.height = 22,
    this.color,
    this.semanticLabel,
    super.key,
  });

  /// Ancho en px.
  final double width;

  /// Alto en px.
  final double height;

  /// Color de la onda; por defecto `signal`.
  final Color? color;

  /// Etiqueta accesible, si el loader no acompaña a otro texto.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.fr.colors.signal;
    final wave = SizedBox(
      width: width,
      height: height,
      child: RepaintBoundary(
        child: FrLoop(
          builder: (context, seconds) =>
              CustomPaint(painter: _WavePainter(seconds, ink)),
        ),
      ),
    );
    final label = semanticLabel;
    return label == null ? wave : Semantics(label: label, child: wave);
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.seconds, this.color) : super(repaint: seconds);

  static const double _amplitude = 0.36;

  final ValueListenable<double> seconds;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    for (var k = 0; k < 2; k++) {
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 1) {
        final envelope = math.sin(math.pi * x / size.width);
        final y =
            size.height / 2 +
            math.sin(x / size.width * math.pi * 2 * 1.6 - t * 7 - k * 1.2) *
                size.height *
                _amplitude *
                envelope *
                (k == 1 ? 0.55 : 1);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = k == 1 ? 1.2 : 2
          ..color = color.withValues(alpha: (k == 1 ? 0.35 : 0.95) * color.a),
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.seconds != seconds || oldDelegate.color != color;
}
