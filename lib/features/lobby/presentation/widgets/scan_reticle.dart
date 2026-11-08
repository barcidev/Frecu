import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';

/// Retícula del escáner (`.reticle` del prototipo), a pantalla completa
/// sobre la cámara: el velo alrededor de un hueco redondeado, las cuatro
/// esquinas que respiran y el haz que barre de arriba abajo.
///
/// Cerrada ([locked]) sobre un QR, el hueco se encoge con el resorte
/// `organic`, las esquinas pasan a la señal con brillo, el haz se apaga y
/// aparece el check al centro. Con movimiento reducido las esquinas no
/// respiran, el haz queda quieto al medio y el cierre es un fundido corto;
/// cerrada o con movimiento reducido no pide cuadros.
class ScanReticle extends StatelessWidget {
  /// Crea la retícula; [locked] la cierra sobre el QR leído.
  const ScanReticle({required this.locked, super.key});

  /// Cerrada sobre un QR.
  final bool locked;

  /// Alto, en fracción de la pantalla, del centro del hueco.
  static const double centerFraction = 0.39;

  /// Lado del hueco abierto y cerrado.
  static const double openSide = 250;

  /// Lado del hueco cerrado sobre el QR.
  static const double lockedSide = 196;

  /// Duración nominal del cierre.
  static const Duration lockDuration = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final reduce = context.reduceMotion;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: locked ? 1 : 0),
      duration: reduce ? fr.motion.quick : lockDuration,
      curve: reduce
          ? fr.motion.easeOut
          : FrSpringCurve(fr.motion.springOrganic, lockDuration),
      builder: (context, lock, _) => LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final center = Offset(size.width / 2, size.height * centerFraction);
          Widget paint(ValueListenable<double>? seconds) => CustomPaint(
            size: size,
            painter: _ReticlePainter(
              colors: fr.colors,
              curve: fr.motion.easeInOut,
              center: center,
              lock: lock,
              still: reduce,
              seconds: seconds,
            ),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: reduce || locked
                      ? paint(null)
                      : FrLoop(builder: (context, seconds) => paint(seconds)),
                ),
              ),
              Positioned(
                left: center.dx - _Check.side / 2,
                top: center.dy - _Check.side / 2,
                child: _Check(shown: locked),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Check al centro de la retícula cerrada: aparece con el resorte `organic`.
class _Check extends StatelessWidget {
  const _Check({required this.shown});

  static const double side = 64;

  final bool shown;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final reduce = context.reduceMotion;
    const pop = Duration(milliseconds: 600);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: shown ? 1 : 0,
        duration: reduce ? fr.motion.quick : const Duration(milliseconds: 550),
        curve: reduce ? fr.motion.easeOut : const Interval(0.45, 1),
        child: AnimatedScale(
          scale: shown || reduce ? 1 : 0.7,
          duration: reduce ? Duration.zero : pop,
          curve: FrSpringCurve(fr.motion.springOrganic, pop),
          child: SizedBox.square(
            dimension: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.signal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.signal.withValues(alpha: 0.8),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Center(
                child: FrIcon(FrIcons.check, size: 28, color: c.signalInk),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinta el velo, las esquinas y el haz de la retícula.
class _ReticlePainter extends CustomPainter {
  _ReticlePainter({
    required this.colors,
    required this.curve,
    required this.center,
    required this.lock,
    required this.still,
    this.seconds,
  }) : super(repaint: seconds);

  final FrColors colors;
  final Curve curve;
  final Offset center;

  /// Cierre sobre el QR, de 0 a 1 (puede pasarse con el resorte).
  final double lock;

  /// Movimiento reducido: haz quieto al medio.
  final bool still;

  /// Tiempo del bucle; nulo si no anima.
  final ValueListenable<double>? seconds;

  static const double _cornerBox = 46;
  static const double _stroke = 3;
  static const double _breathPeriod = 2.8;
  static const double _beamPeriod = 2.4;

  @override
  void paint(Canvas canvas, Size size) {
    final time = seconds?.value;
    final side = lerpDouble(
      ScanReticle.openSide,
      ScanReticle.lockedSide,
      lock,
    )!;
    final radius = lerpDouble(36, 26, lock)!;
    final hole = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: side, height: side),
      Radius.circular(radius),
    );
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(hole),
      Paint()..color = colors.scrim.withValues(alpha: 0.62),
    );
    _corners(canvas, side / 2, radius, time);
    _beam(canvas, hole.outerRect, time);
  }

  /// Las cuatro esquinas en L, reflejadas desde la de arriba a la izquierda.
  void _corners(Canvas canvas, double half, double radius, double? time) {
    final locked = lock.clamp(0.0, 1.0);
    final color = Color.lerp(colors.tx1, colors.signalFg, locked)!;
    final breath = time == null
        ? 0.0
        : 0.5 - 0.5 * math.cos(2 * math.pi * time / _breathPeriod);
    final scale = 1 + 0.04 * curve.transform(breath);
    final path = _corner(half, radius);
    final boxCenter = Offset(
      -half - _stroke + _cornerBox / 2,
      -half - _stroke + _cornerBox / 2,
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = color;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = colors.signal.withValues(alpha: 0.8 * locked)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (final (sx, sy) in const [
      (1.0, 1.0),
      (-1.0, 1.0),
      (1.0, -1.0),
      (-1.0, -1.0),
    ]) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..scale(sx, sy)
        ..translate(boxCenter.dx, boxCenter.dy)
        ..scale(scale)
        ..translate(-boxCenter.dx, -boxCenter.dy);
      if (locked > 0) canvas.drawPath(path, glow);
      canvas
        ..drawPath(path, line)
        ..restore();
    }
  }

  /// Esquina de arriba a la izquierda, con el centro de la retícula en el
  /// origen: el borde va 1,5 px por fuera del hueco.
  static Path _corner(double half, double radius) {
    const inset = _stroke / 2;
    final x = -half - inset;
    final y = -half - inset;
    final arc = math.max(0, radius - inset).toDouble();
    const reach = _cornerBox - inset;
    return Path()
      ..moveTo(x, y + reach)
      ..lineTo(x, y + arc)
      ..arcToPoint(Offset(x + arc, y), radius: Radius.circular(arc))
      ..lineTo(x + reach, y);
  }

  /// Haz de 2 px que barre del 10 % al 88 % y vuelve; se apaga al cerrar.
  void _beam(Canvas canvas, Rect hole, double? time) {
    final alpha = (1 - lock).clamp(0.0, 1.0);
    if (alpha == 0 || (time == null && !still)) return;
    final double travel;
    if (time == null) {
      travel = 0.5;
    } else {
      final phase = (time / _beamPeriod) % 2;
      travel = 0.1 + 0.78 * curve.transform(phase <= 1 ? phase : 2 - phase);
    }
    final beam = Rect.fromLTWH(
      hole.left + 16,
      hole.top + hole.height * travel,
      hole.width - 32,
      2,
    );
    final ink = colors.signalFg;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(beam.inflate(2), const Radius.circular(2)),
        Paint()
          ..color = colors.signal.withValues(alpha: 0.55 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(beam, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              ink.withValues(alpha: 0),
              ink.withValues(alpha: alpha),
              ink.withValues(alpha: 0),
            ],
          ).createShader(beam),
      );
  }

  @override
  bool shouldRepaint(_ReticlePainter old) =>
      old.colors != colors ||
      old.center != center ||
      old.lock != lock ||
      old.still != still ||
      old.seconds != seconds;
}
