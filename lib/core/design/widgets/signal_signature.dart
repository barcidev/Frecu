import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';

const double _tau = math.pi * 2;

/// Razones a:b de las figuras de Lissajous (`RATIOS` de `engine.js`).
const List<(int, int)> _ratios = [
  (1, 2), (2, 3), (3, 4), (3, 2), (1, 3), //
  (2, 5), (4, 5), (3, 5), (5, 4), (4, 3),
];

/// Estado de la firma: en reposo, hablando, silenciada, sin conexión o
/// enlazando.
enum SignatureMode {
  /// En reposo: respira despacio.
  idle,

  /// Hablando: crece, ondula y brilla con el nivel de voz.
  speak,

  /// Silenciada: la figura se aplana.
  muted,

  /// Sin conexión: casi plana y tenue, sin estela.
  off,

  /// Enlazando: trazo punteado.
  link,
}

/// Parámetros de la figura de Lissajous que identifica a una persona.
///
/// Salen del hash de su nombre (en minúsculas y sin espacios en los extremos),
/// así que son iguales en todos los teléfonos sin enviar nada por la red.
@immutable
class SignatureParams {
  /// Crea unos parámetros explícitos.
  const SignatureParams({
    required this.a,
    required this.b,
    required this.phase,
    required this.rot,
    required this.drift,
  });

  /// Parámetros de [name], como `sigParams` del prototipo; sin nombre usa "·".
  factory SignatureParams.fromName(String name) {
    final seed = frHash((name.isEmpty ? '·' : name).trim().toLowerCase());
    final random = FrRandom(seed);
    final (a, b) = _ratios[seed % _ratios.length];
    return SignatureParams(
      a: a,
      b: b,
      phase: random.next() * _tau,
      rot: (random.next() - 0.5) * 0.7,
      drift: 0.07 + random.next() * 0.09,
    );
  }

  /// Marca de Frecu (`DRAW.brand` del prototipo): Lissajous 2:3 con fase
  /// 0,6, sin giro y deriva 0,12.
  static const SignatureParams brand = SignatureParams(
    a: 2,
    b: 3,
    phase: 0.6,
    rot: 0,
    drift: 0.12,
  );

  /// Frecuencia horizontal.
  final int a;

  /// Frecuencia vertical.
  final int b;

  /// Desfase inicial en radianes.
  final double phase;

  /// Giro de la figura en radianes.
  final double rot;

  /// Velocidad de deriva de la fase en reposo.
  final double drift;

  @override
  bool operator ==(Object other) =>
      other is SignatureParams &&
      other.a == a &&
      other.b == b &&
      other.phase == phase &&
      other.rot == rot &&
      other.drift == drift;

  @override
  int get hashCode => Object.hash(a, b, phase, rot, drift);
}

/// Firma de señal: la figura de Lissajous animada de una persona.
///
/// Respira en reposo y ondula y brilla con el nivel de voz. Sin [color] es la
/// firma propia, en la señal: de noche, lima; de día, trazo en tinta
/// (`signalFg`) con el brillo verde (D8). Con movimiento reducido queda en un
/// cuadro fijo.
class SignalSignature extends StatelessWidget {
  /// Firma de [name] en un cuadrado de [size] px.
  const SignalSignature({
    required this.name,
    this.size = 64,
    this.color,
    this.glow,
    this.mode = SignatureMode.idle,
    this.level = 0,
    this.levelOf,
    this.radius = 0.42,
    super.key,
  }) : params = null,
       points = 220;

  /// Marca de Frecu (`DRAW.brand` del prototipo): la Lissajous 2:3 de
  /// [SignatureParams.brand] trazada con 180 puntos, en la señal salvo que
  /// reciba [color].
  const SignalSignature.brand({
    this.size = 64,
    this.color,
    this.glow,
    this.mode = SignatureMode.idle,
    this.level = 0,
    this.levelOf,
    this.radius = 0.42,
    super.key,
  }) : name = 'frecu',
       params = SignatureParams.brand,
       points = 180;

  /// Nombre del que sale la figura.
  final String name;

  /// Parámetros fijos de la figura; si son nulos, salen de [name].
  final SignatureParams? params;

  /// Puntos con los que se traza la curva.
  final int points;

  /// Lado del cuadrado en px.
  final double size;

  /// Color del trazo; por defecto `signalFg` (la señal como trazo).
  final Color? color;

  /// Color del brillo al hablar; por defecto el de [color] según
  /// `FrColors.glowOf`: verde si el trazo es la señal, aunque sea tinta.
  final Color? glow;

  /// Estado de la firma.
  final SignatureMode mode;

  /// Nivel de voz fijo, de 0 a 1.
  final double level;

  /// Nivel de voz según el tiempo en segundos; si existe, manda sobre
  /// [level] (p. ej. `(t) => frVoice(t) * 0.55`).
  final double Function(double seconds)? levelOf;

  /// Radio de la figura como fracción del lado.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.fr.colors;
    final params = this.params ?? SignatureParams.fromName(name);
    final ink = color ?? colors.signalFg;
    return SizedBox.square(
      dimension: size,
      child: RepaintBoundary(
        child: FrLoop(
          builder: (context, seconds) => CustomPaint(
            painter: _SignaturePainter(
              params: params,
              seconds: seconds,
              color: ink,
              glow: glow ?? colors.glowOf(ink),
              pointCount: points,
              mode: mode,
              level: level,
              levelOf: levelOf,
              radius: radius,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({
    required this.params,
    required this.seconds,
    required this.color,
    required this.glow,
    required this.pointCount,
    required this.mode,
    required this.level,
    required this.levelOf,
    required this.radius,
  }) : super(repaint: seconds);

  static const int _cometSegments = 30;

  final SignatureParams params;
  final ValueListenable<double> seconds;
  final Color color;
  final Color glow;
  final int pointCount;
  final SignatureMode mode;
  final double level;
  final double Function(double seconds)? levelOf;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    final lvl = (levelOf?.call(t) ?? level).clamp(0.0, 1.0);
    final active = mode == SignatureMode.idle && lvl > 0.04
        ? SignatureMode.speak
        : mode;
    final r = math.min(size.width, size.height) * radius;
    final points = _curve(r, t, lvl, active);
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(params.rot);
    _drawCurve(canvas, points, r, lvl, active);
    if (active != SignatureMode.off) {
      _drawComet(canvas, points, r, t, lvl, active);
    }
    canvas.restore();
  }

  List<Offset> _curve(double r, double t, double lvl, SignatureMode mode) {
    final flat = switch (mode) {
      SignatureMode.muted => 0.05,
      SignatureMode.off => 0.02,
      _ => 1.0,
    };
    final amp = r * (0.74 + 0.2 * lvl);
    final d = params.phase + t * (params.drift + lvl * 1.4);
    return List<Offset>.generate(pointCount + 1, (i) {
      final u = i / pointCount * _tau;
      final wob = lvl == 0
          ? 1.0
          : 1 +
                lvl *
                    (0.09 * math.sin(u * 9 + t * 13) +
                        0.06 *
                            frNoise2(
                              math.cos(u) * 1.4 + t * 2.2,
                              math.sin(u) * 1.4,
                            ));
      return Offset(
        math.sin(params.a * u + d) * amp * wob,
        math.sin(params.b * u) * amp * wob * flat,
      );
    });
  }

  void _drawCurve(
    Canvas canvas,
    List<Offset> points,
    double r,
    double lvl,
    SignatureMode mode,
  ) {
    final base = switch (mode) {
      SignatureMode.off => 0.16,
      SignatureMode.link => 0.32,
      SignatureMode.muted => 0.45,
      _ => 0.4 + 0.55 * lvl,
    };
    final width = math.max(0.9, r * 0.032) * (1 + lvl * 0.9);
    final path = Path()..addPolygon(points, false);
    final stroke = _stroke(width, color.withValues(alpha: base * color.a));
    if (lvl > 0.02 && mode == SignatureMode.speak) {
      final sigma = (4 + 16 * lvl) / 2;
      canvas.drawPath(
        path,
        _stroke(width, glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
      );
    }
    canvas.drawPath(
      mode == SignatureMode.link ? _dashed(path, r * 0.06, r * 0.1) : path,
      stroke,
    );
  }

  void _drawComet(
    Canvas canvas,
    List<Offset> points,
    double r,
    double t,
    double lvl,
    SignatureMode mode,
  ) {
    const length = 0.2;
    final head = (t * (0.16 + lvl * 0.7) + params.phase) % 1;
    final peak = mode == SignatureMode.link ? 0.5 : 0.95;
    final paint = _stroke(math.max(1.2, r * 0.05) * (1 + lvl * 0.6), color);
    for (var k = 0; k < _cometSegments; k++) {
      final f = ((head - length * k / _cometSegments) % 1 + 1) % 1;
      final i = (f * pointCount).floor();
      paint.color = color.withValues(
        alpha: (1 - k / _cometSegments) * peak * color.a,
      );
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  Paint _stroke(double width, Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color;

  Path _dashed(Path source, double dash, double gap) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        dashed.addPath(metric.extractPath(d, d + dash), Offset.zero);
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) =>
      oldDelegate.params != params ||
      oldDelegate.seconds != seconds ||
      oldDelegate.color != color ||
      oldDelegate.glow != glow ||
      oldDelegate.pointCount != pointCount ||
      oldDelegate.mode != mode ||
      oldDelegate.level != level ||
      oldDelegate.levelOf != levelOf ||
      oldDelegate.radius != radius;
}
