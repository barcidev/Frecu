import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';

/// Fase del anillo [ring] (0–3) en el segundo [seconds]: de 0, cuando nace
/// junto al teléfono, a 1, cuando se desvanece lejos.
double hotspotRingPhase(double seconds, int ring) =>
    (seconds * 0.35 + ring / 4) % 1;

/// Colores de la ilustración.
typedef HotspotLook = ({Color signal, Color signalFg, Color ink, Color bg2});

/// Ilustración del punto de acceso (`drawHotspot` del prototipo): el
/// teléfono emisor con anillos orgánicos que se alejan y tres satélites con
/// su firma de señal.
///
/// Un [FrLoop] la anima; con movimiento reducido queda quieta.
class HotspotIllustration extends StatelessWidget {
  /// Crea la ilustración.
  const HotspotIllustration({super.key});

  /// Alto de la ilustración.
  static const double height = 190;

  /// Semillas de las firmas de los satélites (no se muestran).
  static const List<String> _seeds = ['Ana', 'Leo', 'Sofi'];

  /// Ángulos de los satélites sobre la elipse de 128 × 66.
  static const List<double> _angles = [-2.4, -0.8, 0.8];

  static const double _satelliteRadius = 15;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final look = (
      signal: c.signal,
      signalFg: c.signalFg,
      ink: c.ink,
      bg2: c.bg2,
    );
    final channels = [c.p1, c.p2, c.p3];
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final center = Offset(box.maxWidth / 2, height / 2);
          return Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: FrLoop(
                    builder: (context, seconds) => CustomPaint(
                      painter: HotspotPainter(seconds: seconds, look: look),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < _seeds.length; i++)
                Positioned(
                  left:
                      center.dx + math.cos(_angles[i]) * 128 - _satelliteRadius,
                  top: center.dy + math.sin(_angles[i]) * 66 - _satelliteRadius,
                  child: _Satellite(seed: _seeds[i], color: channels[i]),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Satélite: un círculo `bg0` con la firma de una persona del grupo.
class _Satellite extends StatelessWidget {
  const _Satellite({required this.seed, required this.color});

  final String seed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    return Container(
      width: HotspotIllustration._satelliteRadius * 2,
      height: HotspotIllustration._satelliteRadius * 2,
      decoration: BoxDecoration(
        color: c.bg0,
        shape: BoxShape.circle,
        border: Border.all(color: c.ink.withValues(alpha: 0.14)),
      ),
      child: SignalSignature(
        name: seed,
        size: HotspotIllustration._satelliteRadius * 2,
        color: color,
        radius: 1 / 3,
      ),
    );
  }
}

/// Port de `drawHotspot`: los anillos y el teléfono emisor.
class HotspotPainter extends CustomPainter {
  /// Crea el pintor; repinta con cada cambio de [seconds].
  HotspotPainter({required this.seconds, required this.look})
    : super(repaint: seconds);

  /// Tiempo del bucle en segundos.
  final ValueListenable<double> seconds;

  /// Colores.
  final HotspotLook look;

  static const int _ringPoints = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    final center = size.center(Offset.zero);
    for (var ring = 0; ring < 4; ring++) {
      _paintRing(canvas, center, ring, t);
    }
    _paintPhone(canvas, center);
  }

  void _paintRing(Canvas canvas, Offset center, int ring, double t) {
    final phase = hotspotRingPhase(t, ring);
    final radius = 34 + phase * 110;
    final path = Path();
    for (var i = 0; i <= _ringPoints; i++) {
      final a = i / _ringPoints * 2 * math.pi;
      final noise = frNoise2(math.cos(a) + ring * 3, math.sin(a) + t * 0.6);
      final r = radius + noise * 6 * phase;
      final x = center.dx + math.cos(a) * r;
      final y = center.dy + math.sin(a) * r * 0.62;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path..close(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = look.signalFg.withValues(alpha: (1 - phase) * 0.5),
    );
  }

  void _paintPhone(Canvas canvas, Offset center) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 38, height: 68),
      const Radius.circular(9),
    );
    final dot = center.translate(0, -6);
    canvas
      ..drawRRect(body, Paint()..color = look.bg2)
      ..drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = look.ink.withValues(alpha: 0.3),
      )
      ..drawCircle(
        dot,
        3.5,
        Paint()
          ..color = look.signal
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawCircle(dot, 3.5, Paint()..color = look.signal);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = look.signalFg.withValues(alpha: 0.9);
    for (var r = 1; r <= 2; r++) {
      canvas.drawArc(
        Rect.fromCircle(center: dot, radius: 6.0 * r + 2),
        math.pi * 1.2,
        math.pi * 0.6,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(HotspotPainter oldDelegate) =>
      oldDelegate.seconds != seconds || oldDelegate.look != look;
}
