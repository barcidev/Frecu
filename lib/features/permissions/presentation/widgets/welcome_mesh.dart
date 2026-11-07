import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';

/// Malla de la bienvenida (`drawOrbit` del prototipo): 6 lugares con la firma
/// de cada persona que giran despacio sobre una elipse, unidos por enlaces;
/// cada [turnSeconds] habla el siguiente y salen paquetes hacia los demás.
///
/// Un único [FrLoop] mueve los enlaces, los discos y las firmas; con
/// movimiento reducido todo queda en un cuadro fijo.
class WelcomeMesh extends StatelessWidget {
  /// Crea la malla.
  const WelcomeMesh({super.key});

  /// Nombres de los lugares, como en el prototipo.
  static const List<String> names = [
    'Jorge',
    'Ana',
    'Leo',
    'Sofi',
    'Andrés',
    'Marta',
  ];

  /// Segundos que habla cada lugar antes de pasar al siguiente.
  static const double turnSeconds = 2.6;

  /// Radio del disco de cada lugar.
  static const double nodeRadius = 30;

  /// Lado de la firma de cada lugar.
  static const double signatureSize = 40;

  /// Ancho del prototipo; por debajo, la elipse se encoge.
  static const double referenceWidth = 390;

  /// Lugar que habla en el instante [seconds].
  static int speakerAt(double seconds) =>
      (seconds / turnSeconds).floor() % names.length;

  /// Nivel de voz del lugar [index] en el instante [seconds]: la voz simulada
  /// si habla y 0 si no.
  static double levelAt(int index, double seconds) =>
      speakerAt(seconds) == index ? frVoice(seconds, index) : 0;

  /// Centro del lugar [index] en el instante [seconds] dentro de [size].
  static Offset nodeCenter(int index, double seconds, Size size) {
    final scale = _scaleOf(size);
    final angle =
        -math.pi / 2 + index / names.length * 2 * math.pi + seconds * 0.06;
    final radius = (118 + 10 * math.sin(seconds * 0.5 + index)) * scale;
    return _centerOf(size) +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius * 0.86);
  }

  static double _scaleOf(Size size) => math.min(1, size.width / referenceWidth);

  static Offset _centerOf(Size size) =>
      Offset(size.width / 2, size.height / 2 + 6);

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final colors = [c.signal, c.p1, c.p2, c.p3, c.p4, c.p5];
    return RepaintBoundary(
      child: FrLoop(
        builder: (context, seconds) => Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _MeshPainter(
                seconds: seconds,
                colors: colors,
                ink: c.ink,
                disc: c.bg0,
              ),
            ),
            Flow(
              delegate: _NodesFlow(seconds),
              children: [
                for (final (index, name) in names.indexed)
                  SignalSignature(
                    name: name,
                    size: signatureSize,
                    color: colors[index],
                    levelOf: (_) => levelAt(index, seconds.value),
                    radius: 0.5,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Coloca la firma de cada lugar en su centro, sin reconstruir widgets.
class _NodesFlow extends FlowDelegate {
  _NodesFlow(this.seconds) : super(repaint: seconds);

  final ValueListenable<double> seconds;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      constraints.loosen();

  @override
  void paintChildren(FlowPaintingContext context) {
    final t = seconds.value;
    for (var i = 0; i < context.childCount; i++) {
      final center = WelcomeMesh.nodeCenter(i, t, context.size);
      final child = context.getChildSize(i) ?? Size.zero;
      context.paintChild(
        i,
        transform: Matrix4.translationValues(
          center.dx - child.width / 2,
          center.dy - child.height / 2,
          0,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_NodesFlow oldDelegate) => oldDelegate.seconds != seconds;
}

/// Anillos de medición, enlaces, paquetes y el disco de cada lugar.
class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.seconds,
    required this.colors,
    required this.ink,
    required this.disc,
  }) : super(repaint: seconds);

  final ValueListenable<double> seconds;
  final List<Color> colors;
  final Color ink;
  final Color disc;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    final count = WelcomeMesh.names.length;
    final centers = [
      for (var i = 0; i < count; i++) WelcomeMesh.nodeCenter(i, t, size),
    ];
    final speaker = WelcomeMesh.speakerAt(t);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    _paintRings(canvas, size, line);
    final voice = colors[speaker];
    for (var i = 0; i < count; i++) {
      for (var j = i + 1; j < count; j++) {
        final speaking = i == speaker || j == speaker;
        line.color = speaking
            ? voice.withValues(alpha: 0.28)
            : ink.withValues(alpha: 0.07);
        canvas.drawLine(centers[i], centers[j], line);
      }
    }
    _paintPackets(canvas, centers, speaker, t);
    final fill = Paint()..color = disc;
    for (var i = 0; i < count; i++) {
      line.color = i == speaker
          ? colors[i].withValues(alpha: 0.6)
          : ink.withValues(alpha: 0.12);
      canvas
        ..drawCircle(centers[i], WelcomeMesh.nodeRadius, fill)
        ..drawCircle(centers[i], WelcomeMesh.nodeRadius, line);
    }
  }

  void _paintRings(Canvas canvas, Size size, Paint line) {
    final scale = WelcomeMesh._scaleOf(size);
    final center = WelcomeMesh._centerOf(size);
    for (var r = 0; r < 4; r++) {
      final radius = (60 + r * 46) * scale;
      line.color = ink.withValues(alpha: 0.05 - r * 0.008);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * 2 * 0.86,
        ),
        line,
      );
    }
  }

  /// Paquetes que viajan desde quien habla hacia cada lugar.
  void _paintPackets(
    Canvas canvas,
    List<Offset> centers,
    int speaker,
    double t,
  ) {
    final voice = colors[speaker];
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final dot = Paint();
    for (var j = 0; j < centers.length; j++) {
      if (j == speaker) continue;
      final progress = (t * 1.3 + j * 0.21) % 1;
      final at = Offset.lerp(centers[speaker], centers[j], progress)!;
      final alpha = math.sin(math.pi * progress);
      glow.color = voice.withValues(alpha: alpha * 0.6);
      dot.color = voice.withValues(alpha: alpha);
      canvas
        ..drawCircle(at, 4, glow)
        ..drawCircle(at, 2, dot);
    }
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) =>
      oldDelegate.seconds != seconds ||
      !listEquals(oldDelegate.colors, colors) ||
      oldDelegate.ink != ink ||
      oldDelegate.disc != disc;
}
