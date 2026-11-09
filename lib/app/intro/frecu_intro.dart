import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/settings/presentation/providers/app_version_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Intro de Frecu al arrancar (`V.splash` y `drawSplash` del prototipo): la
/// portadora plana crece, se modula y se pliega en la marca de Frecu; luego
/// aparecen «frecu», «Voz de grupo. Sin internet.» y el pie «v0.1.0 · Red
/// local · Malla P2P».
///
/// Va siempre en noche, como el splash nativo que la precede. Cubre la app
/// mientras se abre la primera ruta debajo y, a los [duration] o con un
/// toque, se funde y deja ver esa ruta. Con movimiento reducido queda quieta
/// en su último cuadro durante [reducedDuration].
class FrecuIntroGate extends StatefulWidget {
  /// Muestra la intro sobre [child] (el navegador de la app).
  const FrecuIntroGate({required this.child, super.key});

  /// La app que la intro deja ver al terminar.
  final Widget child;

  /// Lo que dura la intro antes de fundirse (`after('splash')`: 3,9 s).
  static const Duration duration = Duration(milliseconds: 3900);

  /// Lo que se queda quieta con movimiento reducido.
  static const Duration reducedDuration = Duration(milliseconds: 1500);

  /// Fundido a la primera ruta (`fade` del prototipo).
  static const Duration exitDuration = Duration(milliseconds: 620);

  /// Fundido con movimiento reducido.
  static const Duration reducedExitDuration = Duration(milliseconds: 280);

  @override
  State<FrecuIntroGate> createState() => _FrecuIntroGateState();
}

class _FrecuIntroGateState extends State<FrecuIntroGate>
    with TickerProviderStateMixin {
  /// Tiempo de la intro, de 0 a [FrecuIntroGate.duration].
  late final AnimationController _play = AnimationController(
    vsync: this,
    // Dura lo mismo aunque el sistema acorte las animaciones.
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onPlayStatus);

  /// Fundido de salida, de 0 a 1.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onExitStatus);

  bool _started = false;
  bool _reduce = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduce = context.reduceMotion;
    _play
      ..duration = _reduce
          ? FrecuIntroGate.reducedDuration
          : FrecuIntroGate.duration
      ..forward();
    _exit.duration = _reduce
        ? FrecuIntroGate.reducedExitDuration
        : FrecuIntroGate.exitDuration;
  }

  void _onPlayStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _leave();
  }

  void _onExitStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _done = true);
    }
  }

  /// Empieza a fundirse; un toque la adelanta.
  void _leave() {
    if (_exit.isAnimating || _exit.isCompleted) return;
    _play.stop();
    _exit.forward();
  }

  @override
  void dispose() {
    _play.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // La app es siempre el primer hijo, con los mismos envoltorios: así no se
    // vuelve a montar al terminar la intro.
    return Stack(
      fit: StackFit.expand,
      children: [
        // Barra de estado legible con el tema de la app al quitarse la intro,
        // que la deja clara.
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: AnimatedBuilder(
            animation: _exit,
            child: widget.child,
            builder: (context, child) => _entering(context, child!),
          ),
        ),
        if (!_done)
          AnimatedBuilder(
            animation: _exit,
            builder: (context, child) {
              final out = Interval(
                0,
                420 / 620,
                curve: context.fr.motion.easeOut,
              ).transform(_exit.value);
              return IgnorePointer(
                ignoring: _exit.isAnimating,
                child: Opacity(opacity: 1 - out, child: child),
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _leave,
              child: Semantics(
                button: true,
                onTapHint: t.splash.skip,
                child: FrecuIntro(
                  seconds: _play.drive(
                    Tween<double>(
                      begin: 0,
                      end: FrecuIntroGate.duration.inMicroseconds / 1e6,
                    ),
                  ),
                  still: _reduce,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// La primera ruta entra con el fundido de Portadora: escala 1,03 y
  /// desenfoque de 6 px que se van; con movimiento reducido, solo opacidad.
  Widget _entering(BuildContext context, Widget child) {
    final t = _done ? 1.0 : context.fr.motion.easeOut.transform(_exit.value);
    final blur = _reduce ? 0.0 : 6 * (1 - t);
    return Opacity(
      opacity: t,
      child: ImageFiltered(
        enabled: blur > 0,
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Transform.scale(
          scale: _reduce ? 1 : 1.03 - 0.03 * t,
          child: child,
        ),
      ),
    );
  }
}

/// Pantalla de la intro en el instante [seconds] (o quieta en su último
/// cuadro si [still]), siempre con los colores de noche.
class FrecuIntro extends ConsumerWidget {
  /// Crea la intro.
  const FrecuIntro({required this.seconds, this.still = false, super.key});

  /// Segundos desde que empezó.
  final Animation<double> seconds;

  /// Quieta en el cuadro final (movimiento reducido).
  final bool still;

  /// Segundo del cuadro final: la firma ya se plegó y se asentó.
  static const double stillAt = 3.2;

  static final ThemeData _night = AppTheme.dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: _night,
        child: Builder(
          builder: (context) {
            final fr = context.fr;
            return ColoredBox(
              color: fr.colors.bg0,
              child: AnimatedBuilder(
                animation: seconds,
                builder: (context, _) {
                  final t = still ? stillAt : seconds.value;
                  return LayoutBuilder(
                    builder: (context, constraints) =>
                        _frame(fr, constraints.biggest, t, version),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _frame(FrTheme fr, Size size, double t, String? version) {
    final c = fr.colors;
    final center = IntroCurve.centerOf(size);
    final mark = still ? 1.0 : _keyframe(fr, t, 2.08, 2.704);
    final foot = still ? 1.0 : _keyframe(fr, t, 2.6, 3.12, ease: false);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          key: const Key('frecu_intro_carrier'),
          painter: _IntroPainter(
            seconds: t,
            ink: c.signalFg,
            glow: c.glowOf(c.signalFg),
            ticks: c.ink,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: center.dy + 132,
          child: _Mark(progress: mark),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 44,
          child: Opacity(
            opacity: foot,
            child: _Foot(version: version, style: fr.type.labelS, color: c.tx3),
          ),
        ),
      ],
    );
  }

  /// Avance de 0 a 1 entre [from] y [to] segundos, con `ease-out` (o
  /// `ease` si no [ease]).
  static double _keyframe(
    FrTheme fr,
    double t,
    double from,
    double to, {
    bool ease = true,
  }) {
    final k = ((t - from) / (to - from)).clamp(0.0, 1.0);
    return ease ? fr.motion.easeOut.transform(k) : Curves.ease.transform(k);
  }
}

/// «frecu» y «Voz de grupo. Sin internet.», que suben 14 px y se enfocan.
class _Mark extends StatelessWidget {
  const _Mark({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final blur = 8 * (1 - progress);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.splash.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: FrFonts.ui,
            fontSize: 46,
            height: 1,
            letterSpacing: -1.84,
            fontWeight: const FontWeight(790),
            fontVariations: const [
              FontVariation.weight(790),
              FontVariation.width(125),
            ],
            color: fr.colors.tx1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          t.splash.tagline,
          textAlign: TextAlign.center,
          style: fr.type.body.copyWith(height: 1, color: fr.colors.tx2),
        ),
      ],
    );
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - progress)),
        child: blur > 0.01
            ? ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: content,
              )
            : content,
      ),
    );
  }
}

/// Pie: versión, «Red local» y «Malla P2P» separados por puntos.
class _Foot extends StatelessWidget {
  const _Foot({
    required this.version,
    required this.style,
    required this.color,
  });

  final String? version;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final version = this.version;
    final items = [
      if (version != null) t.splash.version(version: version),
      t.splash.localNetwork,
      t.splash.mesh,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 18,
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i > 0) Text('·', style: style.copyWith(color: color)),
          Text(item.toUpperCase(), style: style.copyWith(color: color)),
        ],
      ],
    );
  }
}

/// Curva de la intro (`drawSplash`): en el segundo `t`, la portadora plana
/// crece desde el centro (0–0,55 s), se modula (0,5–1,4 s), se pliega en la
/// marca de Frecu (1,35–2,35 s) y se asienta en un radio de 62 px
/// (2,2–3 s).
abstract final class IntroCurve {
  /// Puntos de la curva.
  static const int points = 260;

  /// Centro de la curva en una pantalla de [size]: al 40 % del alto.
  static Offset centerOf(Size size) =>
      Offset(size.width / 2, size.height * 0.4);

  /// Punto [i] de [points] en el segundo [t] en una pantalla de [size].
  static Offset pointAt(int i, double t, Size size) {
    const brand = SignatureParams.brand;
    final center = centerOf(size);
    final half = size.width * 0.36;
    final grow = _easeOut(t / 0.55);
    final amp = _easeInOut((t - 0.5) / 0.9) * 54;
    final m = _easeInOut((t - 1.35) / 1);
    final settle = _easeInOut((t - 2.2) / 0.8);
    final radius = lerpDouble(90, 62, settle)!;
    final u = i / points;
    final turn = u * math.pi * 2;
    final wave = Offset(
      center.dx + (u - 0.5) * 2 * half * grow,
      center.dy + math.sin(turn * 3 - t * 3.2) * amp * math.sin(math.pi * u),
    );
    final sign = Offset(
      center.dx + math.sin(brand.a * turn + brand.phase + t * 0.25) * radius,
      center.dy + math.sin(brand.b * turn) * radius,
    );
    return Offset.lerp(wave, sign, m)!;
  }

  /// Opacidad del dial de marcas: aparece entre 0,1 y 0,8 s.
  static double dialAt(double t) => _smooth(0.1, 0.8, t);

  static double _easeOut(double x) {
    final rest = 1 - x.clamp(0.0, 1.0);
    return 1 - rest * rest * rest * rest;
  }

  static double _easeInOut(double x) {
    final t = x.clamp(0.0, 1.0);
    if (t < 0.5) return 8 * t * t * t * t;
    final rest = -2 * t + 2;
    return 1 - rest * rest * rest * rest / 2;
  }

  static double _smooth(double a, double b, double v) {
    final t = ((v - a) / (b - a)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }
}

/// Pinta la curva con su brillo verde y el dial de 90 marcas.
class _IntroPainter extends CustomPainter {
  _IntroPainter({
    required this.seconds,
    required this.ink,
    required this.glow,
    required this.ticks,
  });

  final double seconds;
  final Color ink;
  final Color glow;
  final Color ticks;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds;
    final path = Path();
    for (var i = 0; i <= IntroCurve.points; i++) {
      final point = IntroCurve.pointAt(i, t, size);
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas
      ..drawPath(
        path,
        stroke(glow.withValues(alpha: 0.9))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      )
      ..drawPath(path, stroke(ink.withValues(alpha: 0.9)));
    _paintDial(canvas, size, IntroCurve.dialAt(t));
  }

  void _paintDial(Canvas canvas, Size size, double alpha) {
    if (alpha <= 0) return;
    final center = IntroCurve.centerOf(size);
    final tick = Paint()..strokeWidth = 1;
    for (var i = 0; i < 90; i++) {
      final angle = i / 90 * math.pi * 2;
      final major = i % 5 == 0;
      final direction = Offset(math.cos(angle), math.sin(angle));
      tick.color = ticks.withValues(alpha: (major ? 0.22 : 0.1) * alpha);
      canvas.drawLine(
        center + direction * 132,
        center + direction * (major ? 141 : 136),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_IntroPainter oldDelegate) =>
      oldDelegate.seconds != seconds ||
      oldDelegate.ink != ink ||
      oldDelegate.glow != glow ||
      oldDelegate.ticks != ticks;
}
