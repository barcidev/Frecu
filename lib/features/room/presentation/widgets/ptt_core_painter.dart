import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';

/// Marcas del bisel del núcleo.
const int pttTickCount = 72;

const double _tau = math.pi * 2;

/// Marcas encendidas del bisel con el [level] propio al aire ([onAir]) o el
/// de quien habla.
int pttLitTicks(double level, {required bool onAir}) => onAir
    ? (pttTickCount * (0.08 + 0.92 * level)).round()
    : (pttTickCount * level * 0.9).round();

/// Qué dibuja el núcleo en un cuadro.
@immutable
class PttLook {
  /// Crea el aspecto del núcleo.
  const PttLook({
    this.onAir = false,
    this.waiting = false,
    this.level = 0,
    this.levelScale = 1,
    this.rxColor,
    this.rxLevel = 0,
  });

  /// La persona propia transmite (PTT o micrófono abierto).
  final bool onAir;

  /// En espera: sin barrido y con marcas tenues.
  final bool waiting;

  /// Nivel real de la voz propia, de 0 a 1.
  final double level;

  /// Escala de la voz propia (0,7 con micrófono abierto).
  final double levelScale;

  /// Color de quien habla, si alguien habla.
  final Color? rxColor;

  /// Nivel real de la voz de quien habla, de 0 a 1.
  final double rxLevel;

  /// Transmite y no está en espera.
  bool get transmitting => onAir && !waiting;

  /// Alguien habla y no está en espera.
  bool get receiving => rxColor != null && !waiting;

  @override
  bool operator ==(Object other) =>
      other is PttLook &&
      other.onAir == onAir &&
      other.waiting == waiting &&
      other.level == level &&
      other.levelScale == levelScale &&
      other.rxColor == rxColor &&
      other.rxLevel == rxLevel;

  @override
  int get hashCode =>
      Object.hash(onAir, waiting, level, levelScale, rxColor, rxLevel);
}

/// Onda que sale del núcleo en el segundo [start].
@immutable
class PttRipple {
  /// Crea una onda de [color] con opacidad [alpha].
  const PttRipple({
    required this.start,
    required this.color,
    required this.alpha,
  });

  /// Segundos que dura.
  static const double lifetime = 1.4;

  /// Segundo de salida.
  final double start;

  /// Color.
  final Color color;

  /// Opacidad inicial.
  final double alpha;
}

/// Niveles suavizados y ondas del núcleo (el estado de `drawPtt`).
class PttMotion {
  double _level = 0;
  double _rxLevel = 0;
  double _lastRipple = double.negativeInfinity;
  double? _time;
  final List<PttRipple> _ripples = [];

  /// Nivel de la voz propia, de 0 a 1.
  double get level => _level;

  /// Nivel de quien habla, de 0 a 1.
  double get rxLevel => _rxLevel;

  /// Ondas en viaje.
  List<PttRipple> get ripples => List.unmodifiable(_ripples);

  /// Avanza al segundo [t] con el aspecto [look]: los niveles siguen los de
  /// [look] con su resorte, o tal cual y sin ondas con [reduced]. [glow] es
  /// el color de las ondas propias y [dayK] refuerza su opacidad de día.
  void advance(
    double t,
    PttLook look, {
    required Color glow,
    double dayK = 1,
    bool reduced = false,
  }) {
    final dt = _elapse(t);
    final target = look.transmitting
        ? math.max(0.12, look.level * look.levelScale)
        : 0.0;
    final rxTarget = look.receiving ? look.rxLevel : 0.0;
    if (reduced) {
      _level = target;
      _rxLevel = rxTarget;
      _ripples.clear();
      return;
    }
    _level = _ease(_level, target, target > _level ? 0.35 : 0.12, dt);
    _rxLevel = _ease(_rxLevel, rxTarget, 0.25, dt);
    _ripples.removeWhere((r) => t - r.start >= PttRipple.lifetime);
    _emit(t, look, glow: glow, dayK: dayK);
  }

  /// Segundos desde el cuadro anterior.
  double _elapse(double t) {
    final last = _time;
    _time = t;
    return last == null ? 0 : math.max(0, t - last).toDouble();
  }

  /// Lanza una onda cada 0,42 s al aire o cada 0,7 s mientras alguien habla.
  void _emit(
    double t,
    PttLook look, {
    required Color glow,
    required double dayK,
  }) {
    final onAir = look.transmitting;
    final active = onAir || (look.receiving && _rxLevel > 0.02);
    if (!active || t - _lastRipple <= (onAir ? 0.42 : 0.7)) return;
    _lastRipple = t;
    _ripples.add(
      PttRipple(
        start: t,
        color: onAir ? glow : look.rxColor!,
        alpha: onAir ? math.min(1, 0.45 * dayK) : 0.45,
      ),
    );
  }

  static double _ease(double from, double to, double rate, double dt) =>
      from + (to - from) * (1 - math.pow(1 - rate, dt * 60));
}

/// Pinta el núcleo como `drawPtt` del prototipo: ondas, bisel de 72 marcas
/// (VU circular) y anillo líquido. El botón va encima, como widget.
class PttCorePainter extends CustomPainter {
  /// Pinta [look] con el tiempo de [seconds] y avanza [motion] en cada cuadro.
  PttCorePainter({
    required this.look,
    required this.motion,
    required this.seconds,
    required this.colors,
    this.dayK = 1,
    this.reduced = false,
  }) : super(repaint: seconds);

  /// Aspecto del núcleo.
  final PttLook look;

  /// Niveles y ondas.
  final PttMotion motion;

  /// Tiempo del bucle en segundos.
  final ValueListenable<double> seconds;

  /// Colores del tema.
  final FrColors colors;

  /// Refuerzo de las ondas de señal de día.
  final double dayK;

  /// Movimiento reducido: cuadro fijo.
  final bool reduced;

  bool get _onAir => look.transmitting;

  bool get _rx => look.receiving;

  Color get _active => _onAir ? colors.signal : look.rxColor ?? colors.tx3;

  bool get _isActive => _onAir || (_rx && motion.rxLevel > 0.02);

  @override
  void paint(Canvas canvas, Size size) {
    final t = reduced ? 0.0 : seconds.value;
    motion.advance(t, look, glow: colors.signal, dayK: dayK, reduced: reduced);
    final center = size.center(Offset.zero);
    _paintRipples(canvas, center, t);
    _paintBezel(canvas, center, t);
    _paintRing(canvas, center, t);
  }

  void _paintRipples(Canvas canvas, Offset center, double t) {
    for (final ripple in motion.ripples) {
      final k = ((t - ripple.start) / PttRipple.lifetime).clamp(0.0, 1.0);
      final radius = 82 + k * 42;
      final path = _wobble(
        center,
        96,
        (a) =>
            radius +
            frNoise2(math.cos(a) * 1.2 + ripple.start, math.sin(a) * 1.2 + t) *
                4 *
                (1 - k),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 + (1 - k) * 1.5
          ..color = ripple.color.withValues(
            alpha: math.min(1, (1 - k) * ripple.alpha),
          ),
      );
    }
  }

  /// Marcas encendidas del bisel en este cuadro.
  int get _lit {
    if (_onAir) return pttLitTicks(motion.level, onAir: true);
    return _rx ? pttLitTicks(motion.rxLevel, onAir: false) : 0;
  }

  /// Opacidad de la marca [i] apagada: el barrido de 4 s la aviva en reposo.
  double _tickAlpha(int i, double sweep) {
    if (look.waiting) return 0.08;
    final base = i % 6 == 0 ? 0.28 : 0.14;
    if (_isActive || reduced) return base;
    final d = (i / pttTickCount - sweep).abs();
    return base + math.max(0, 0.5 - math.min(d, 1 - d) * 9) * 0.6;
  }

  void _paintBezel(Canvas canvas, Offset center, double t) {
    final lit = _lit;
    final sweep = (t * 0.25) % 1;
    final glowPath = Path();
    for (var i = 0; i < pttTickCount; i++) {
      final angle = -math.pi / 2 + i / pttTickCount * _tau;
      final major = i % 6 == 0;
      final from = center + Offset.fromDirection(angle, 113);
      final to = center + Offset.fromDirection(angle, major ? 122 : 118);
      final on = i < lit;
      if (on) {
        glowPath
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy);
      }
      canvas.drawLine(
        from,
        to,
        Paint()
          ..strokeWidth = major ? 1.6 : 1.2
          ..color = on
              ? _active.withValues(alpha: 0.95)
              : colors.ink.withValues(alpha: _tickAlpha(i, sweep)),
      );
    }
    if (lit == 0) return;
    canvas.drawPath(
      glowPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _active.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _paintRing(Canvas canvas, Offset center, double t) {
    final amp = _onAir
        ? 3 + 9 * motion.level
        : _rx
        ? 2 + 7 * motion.rxLevel
        : 1.3;
    final speed = _onAir ? 1.6 : 0.5;
    final path = _wobble(
      center,
      140,
      (a) =>
          94 +
          frNoise2(
                math.cos(a) * 1.6 + t * speed,
                math.sin(a) * 1.6 - t * speed * 0.7,
              ) *
              amp,
    );
    final active = _isActive;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 1.8 : 1.2
      ..color = active
          ? _active.withValues(alpha: 0.85)
          : colors.ink.withValues(alpha: 0.16);
    if (active) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = _active.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawPath(path, stroke);
  }

  static Path _wobble(
    Offset center,
    int steps,
    double Function(double angle) radius,
  ) {
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final a = i / steps * _tau;
      final p = center + Offset.fromDirection(a, radius(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(PttCorePainter oldDelegate) =>
      oldDelegate.look != look ||
      oldDelegate.motion != motion ||
      oldDelegate.seconds != seconds ||
      oldDelegate.colors != colors ||
      oldDelegate.dayK != dayK ||
      oldDelegate.reduced != reduced;
}
