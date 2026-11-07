import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';

/// Tono de una [FrPill].
enum FrPillTone {
  /// Conectado: punto de señal y texto `tx1`.
  ok,

  /// Aviso (conectando, reconectando): ámbar.
  warn,

  /// Alerta (sin red local): bengala.
  alert,

  /// Apagado (cerrada): punto `tx4`, texto `tx3` y sin halo.
  off,
}

/// Píldora de estado de Portadora: un punto con halo y el texto en
/// mayúsculas.
///
/// El halo late cada 2,4 s (1,1 s en `warn`); en `off` no hay halo. [busy]
/// cambia el punto por un anillo con un arco que gira. Con movimiento
/// reducido el halo se apaga y el arco se detiene; el color del tono sigue.
class FrPill extends StatelessWidget {
  /// Crea una píldora con [label].
  const FrPill({
    required this.label,
    this.tone = FrPillTone.ok,
    this.busy = false,
    super.key,
  });

  /// Texto; se muestra en mayúsculas.
  final String label;

  /// Tono del punto y del texto.
  final FrPillTone tone;

  /// Ocupada: anillo con un arco que gira en lugar del punto.
  final bool busy;

  static const double _height = 28;
  static const double _dot = 7;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final (ink, color) = switch (tone) {
      FrPillTone.ok => (c.tx1, c.signal),
      FrPillTone.warn => (c.warn, c.warn),
      FrPillTone.alert => (c.alert, c.alert),
      FrPillTone.off => (c.tx3, c.tx4),
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: c.bg1,
        shape: StadiumBorder(side: BorderSide(color: c.line1)),
      ),
      child: SizedBox(
        height: _height,
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) _BusyDot(color: color) else _dotWithHalo(fr, color),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: fr.type.labelS.copyWith(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dotWithHalo(FrTheme fr, Color color) {
    final c = fr.colors;
    final ok = tone == FrPillTone.ok;
    final ring = c.ledRing;
    final dot = SizedBox(
      key: const ValueKey('fr-pill-dot'),
      width: _dot,
      height: _dot,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: ok && ring != null
              ? Border.all(color: ring, width: 1.25)
              : null,
          boxShadow: [
            if (ok)
              BoxShadow(color: c.signal.withValues(alpha: 0.8), blurRadius: 10),
          ],
        ),
      ),
    );
    if (tone == FrPillTone.off) return dot;
    // El halo es un trazo: de día va en `signalFg`, nunca en `signal`.
    final halo = ok ? c.signalFg : color;
    return Builder(
      builder: (context) => Stack(
        clipBehavior: Clip.none,
        children: [
          dot,
          if (!context.reduceMotion)
            Positioned(
              left: -4,
              top: -4,
              right: -4,
              bottom: -4,
              child: _Halo(
                color: halo,
                period: tone == FrPillTone.warn ? 1.1 : 2.4,
                curve: fr.motion.easeOut,
              ),
            ),
        ],
      ),
    );
  }
}

/// Anillo que crece de 0,6 a 2,1 y se desvanece (`@keyframes halo`).
class _Halo extends StatelessWidget {
  const _Halo({required this.color, required this.period, required this.curve});

  final Color color;
  final double period;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return FrLoop(
      builder: (context, seconds) => ValueListenableBuilder<double>(
        valueListenable: seconds,
        builder: (context, t, child) {
          final k = curve.transform((t % period) / period);
          return Opacity(
            opacity: 0.9 * (1 - k),
            child: Transform.scale(scale: 0.6 + 1.5 * k, child: child),
          );
        },
        child: DecoratedBox(
          key: const ValueKey('fr-pill-halo'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
      ),
    );
  }
}

/// Punto ocupado: anillo tenue con un arco que gira cada 0,9 s.
class _BusyDot extends StatelessWidget {
  const _BusyDot({required this.color});

  static const double _period = 0.9;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final arc = SizedBox(
      key: const ValueKey('fr-pill-arc'),
      width: FrPill._dot,
      height: FrPill._dot,
      child: CustomPaint(painter: _ArcPainter(color)),
    );
    return SizedBox(
      width: FrPill._dot,
      height: FrPill._dot,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
            ),
          ),
          FrLoop(
            builder: (context, seconds) => ValueListenableBuilder<double>(
              valueListenable: seconds,
              builder: (context, t, child) => Transform.rotate(
                angle: (t % _period) / _period * 2 * math.pi,
                child: child,
              ),
              child: arc,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.color);

  static const double _stroke = 1.5;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    canvas.drawArc(
      rect,
      -math.pi * 3 / 4,
      math.pi / 2,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}
