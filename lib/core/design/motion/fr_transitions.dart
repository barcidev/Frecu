import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/gestures.dart' show HorizontalDragGestureRecognizer;
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_motion.dart';

/// Transiciones de pantalla de Portadora.
enum FrTransition {
  /// Entrar a un modo (crear, escanear, unirse): la pantalla nueva se revela
  /// en un círculo desde el dedo con un frente de onda luminoso, bajando de
  /// un brillo de 1,5 a 1.
  wave,

  /// Jerarquía (ajustes, guía): entra de lado con paralaje y la anterior se
  /// oscurece.
  slide,

  /// Código correcto: la superficie de la hoja crece hasta ocupar la pantalla
  /// y se convierte en la pantalla nueva.
  expand,

  /// Cambio sin dirección: la pantalla nueva se funde sobre la anterior,
  /// desde un desenfoque de 6 px y una escala de 1,03.
  fade,
}

/// Último toque en la pantalla, en coordenadas globales: es el origen de la
/// onda. Lo registra `FrScaffold`.
abstract final class FrTouchOrigin {
  static Offset? _last;

  /// Posición del último toque; nula si todavía no hubo ninguno.
  static Offset? get last => _last;

  /// Registra un toque en [position]; ignora posiciones no finitas.
  static void record(Offset position) {
    if (!position.isFinite) return;
    _last = position;
  }

  /// Olvida el último toque.
  static void clear() => _last = null;
}

/// Hoja desde la que crece la próxima pantalla (`FrTransition.expand`).
///
/// Con el código correcto la hoja de unión se convierte en la frecu: antes de
/// cerrarse anota su rectángulo y la ruta que entra a continuación con la
/// onda crece desde ahí. Caduca en [ttl] para no colarse en otra entrada.
abstract final class FrExpandOrigin {
  static Rect? _rect;
  static DateTime? _at;

  /// Cuánto vale un rectángulo anotado.
  static const Duration ttl = Duration(seconds: 2);

  /// Anota [rect] (global) como origen de la próxima expansión.
  static void record(Rect rect) {
    if (!rect.isFinite || rect.isEmpty) return;
    _rect = rect;
    _at = DateTime.now();
  }

  /// Devuelve el origen anotado si sigue vigente y lo olvida.
  static Rect? take() {
    final rect = _rect;
    final at = _at;
    _rect = null;
    _at = null;
    if (rect == null || at == null) return null;
    return DateTime.now().difference(at) <= ttl ? rect : null;
  }

  /// Anota el rectángulo global de la caja de [context], si ya tiene tamaño.
  static void recordFrom(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    record(box.localToGlobal(Offset.zero) & box.size);
  }
}

/// Constructores de las transiciones de Portadora.
///
/// Cada uno es un `RouteTransitionsBuilder`: sirve en `PageRouteBuilder` o en
/// `CustomRoute(transitionsBuilder: …)` de auto_route, con la duración de
/// [durationOf] y [backDuration] al volver. También aplica su efecto de salida
/// a la pantalla que queda abajo; al volver, esa pantalla regresa siempre
/// desde el −28 % con el brillo al 0,45 (`back` del prototipo). Con
/// movimiento reducido todas son un fundido sin desplazamiento.
abstract final class FrTransitions {
  /// Onda: 760 ms.
  static const Duration waveDuration = Duration(milliseconds: 760);

  /// Deslizamiento: 560 ms.
  static const Duration slideDuration = Duration(milliseconds: 560);

  /// Expansión: la superficie crece en 620 ms y la pantalla entra en 520 ms.
  static const Duration expandDuration = Duration(milliseconds: 1100);

  /// Fundido: 620 ms.
  static const Duration fadeDuration = Duration(milliseconds: 620);

  /// Volver: la pantalla sale hacia la derecha en 520 ms.
  static const Duration backDuration = Duration(milliseconds: 520);

  /// Cualquier transición con movimiento reducido: 280 ms de fundido.
  static const Duration reducedDuration = Duration(milliseconds: 280);

  /// Clave de la superficie que crece en la expansión.
  static const Key expandSurfaceKey = ValueKey<String>('frExpandSurface');

  /// Desenfoque inicial del fundido, en px (desviación típica, como
  /// `blur()` de CSS).
  static const double fadeBlur = 6;

  /// Brillo inicial de la pantalla que entra con la onda.
  static const double waveBrightness = 1.5;

  /// Duración de [transition] al entrar.
  static Duration durationOf(FrTransition transition) => switch (transition) {
    FrTransition.wave => waveDuration,
    FrTransition.slide => slideDuration,
    FrTransition.expand => expandDuration,
    FrTransition.fade => fadeDuration,
  };

  /// Onda desde el último toque ([FrTouchOrigin]).
  static Widget wave(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _view(FrTransition.wave, animation, secondaryAnimation, child);

  /// Deslizamiento desde la derecha.
  static Widget slide(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _view(FrTransition.slide, animation, secondaryAnimation, child);

  /// Expansión desde la parte baja de la pantalla, donde suelen estar las
  /// hojas; `FrPageRoute` acepta el rectángulo exacto.
  static Widget expand(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _view(FrTransition.expand, animation, secondaryAnimation, child);

  /// Fundido con una leve escala.
  static Widget fade(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _view(FrTransition.fade, animation, secondaryAnimation, child);

  static Widget _view(
    FrTransition transition,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _FrTransitionView(
    transition: transition,
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );

  /// Efecto de la pantalla que queda bajo una hoja: se aleja (escala 0,93 y
  /// 10 px abajo), baja su brillo a 0,55 y redondea sus esquinas a 46 px. Es
  /// un `DelegatedTransitionBuilder` para `ModalRoute.delegatedTransition`.
  static final DelegatedTransitionBuilder recede = _delegate(_Under.recede);

  // Cada efecto es un único objeto: dos rutas del mismo tipo se reconocen.
  static final DelegatedTransitionBuilder _underWave = _delegate(_Under.wave);
  static final DelegatedTransitionBuilder _underSlide = _delegate(_Under.slide);
  static final DelegatedTransitionBuilder _underFade = _delegate(_Under.fade);
  static final DelegatedTransitionBuilder _underNone = _delegate(null);

  static DelegatedTransitionBuilder _delegate(_Under? kind) =>
      (context, animation, secondaryAnimation, allowSnapshotting, child) {
        if (kind == null || child == null || context.reduceMotion) {
          return child;
        }
        return _UnderView(
          kind: kind,
          animation: secondaryAnimation,
          child: child,
        );
      };

  static DelegatedTransitionBuilder _delegateOf(FrTransition transition) =>
      switch (transition) {
        FrTransition.wave => _underWave,
        FrTransition.slide => _underSlide,
        FrTransition.expand => _underNone,
        FrTransition.fade => _underFade,
      };
}

/// Ruta de página con una transición de Portadora.
///
/// Además de animar su entrada, le dice a la pantalla de abajo cómo apartarse
/// (`delegatedTransition`), aunque sea una página de otro tipo. Con
/// movimiento reducido dura [FrTransitions.reducedDuration] y es un fundido.
/// Con auto_route se usa desde `CustomRoute(customRouteBuilder: …)` pasando
/// la página como [settings].
class FrPageRoute<T> extends PageRoute<T> {
  /// Crea una ruta que construye su pantalla con [builder].
  FrPageRoute({
    required this.builder,
    required this.transition,
    this.origin,
    this.from,
    this.maintainState = true,
    super.settings,
    super.fullscreenDialog,
    super.allowSnapshotting,
  });

  /// Construye la pantalla.
  final WidgetBuilder builder;

  /// Transición de entrada.
  final FrTransition transition;

  /// Origen global de la onda; por defecto, el último toque.
  final Offset? origin;

  /// Rectángulo global desde el que crece la expansión (la hoja).
  final Rect? from;

  @override
  final bool maintainState;

  bool _reduce = false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => _reduce
      ? FrTransitions.reducedDuration
      : FrTransitions.durationOf(transition);

  @override
  Duration get reverseTransitionDuration =>
      _reduce ? FrTransitions.reducedDuration : FrTransitions.backDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      FrTransitions._delegateOf(transition);

  /// También se aparta bajo las hojas, que no son páginas pero le dicen cómo.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      super.canTransitionTo(nextRoute) ||
      (nextRoute is ModalRoute && nextRoute.delegatedTransition != null);

  /// Con movimiento reducido el sistema acorta las animaciones normales; el
  /// fundido conserva sus 280 ms.
  @override
  AnimationController createAnimationController() => AnimationController(
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    debugLabel: debugLabel,
    vsync: navigator!,
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void install() {
    final media = navigator?.context
        .getInheritedWidgetOfExactType<MediaQuery>();
    _reduce = media?.data.disableAnimations ?? false;
    super.install();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final view = _FrTransitionView(
      transition: transition,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      origin: origin,
      from: from,
      child: child,
    );
    // En iOS se vuelve deslizando desde el borde, como en las páginas de
    // Cupertino; donde no se puede salir (PopScope) el gesto no empieza.
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.iOS && platform != TargetPlatform.macOS) {
      return view;
    }
    return _FrBackSwipe(route: this, child: view);
  }

  /// El dedo lleva la ruta hacia atrás una [fraction] del ancho.
  void _swipeBy(double fraction) {
    final c = controller;
    if (c == null) return;
    c.value -= fraction;
  }

  /// Suelta el gesto con [velocity] (anchos de pantalla por segundo): vuelve
  /// si se lanzó hacia atrás o pasó la mitad; si no, la pantalla se queda.
  void _swipeEnd(double velocity) {
    final c = controller;
    final nav = navigator;
    if (c == null || nav == null) return;
    const curve = Curves.fastEaseInToSlowEaseOut;
    final bool stay;
    if (!isCurrent) {
      stay = isActive;
    } else if (velocity.abs() >= _kBackSwipeFling) {
      stay = velocity <= 0;
    } else {
      stay = c.value > 0.5;
    }
    if (stay) {
      unawaited(c.animateTo(1, duration: _kBackSwipeSettle, curve: curve));
    } else {
      if (isCurrent) nav.pop();
      if (c.isAnimating) {
        unawaited(c.animateBack(0, duration: _kBackSwipeSettle, curve: curve));
      }
    }
    if (c.isAnimating) {
      late AnimationStatusListener done;
      done = (_) {
        nav.didStopUserGesture();
        c.removeStatusListener(done);
      };
      c.addStatusListener(done);
    } else {
      nav.didStopUserGesture();
    }
  }
}

/// Ancho del borde desde el que empieza el gesto de volver.
const double _kBackSwipeEdge = 20;

/// Velocidad (anchos de pantalla por segundo) que cuenta como lanzamiento.
const double _kBackSwipeFling = 1;

/// Lo que tarda la pantalla en asentarse al soltar el gesto.
const Duration _kBackSwipeSettle = Duration(milliseconds: 350);

/// Gesto de volver desde el borde izquierdo para [FrPageRoute] en iOS.
class _FrBackSwipe extends StatefulWidget {
  const _FrBackSwipe({required this.route, required this.child});

  final FrPageRoute<dynamic> route;
  final Widget child;

  @override
  State<_FrBackSwipe> createState() => _FrBackSwipeState();
}

class _FrBackSwipeState extends State<_FrBackSwipe> {
  late final HorizontalDragGestureRecognizer _drag =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _start
        ..onUpdate = _update
        ..onEnd = _end
        ..onCancel = _cancel;

  bool _dragging = false;

  double get _width => context.size?.width ?? 1;

  double get _direction =>
      Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  @override
  void dispose() {
    _drag.dispose();
    if (_dragging) {
      // La pantalla se fue a mitad del gesto: el navegador deja de esperarlo.
      _dragging = false;
      widget.route.navigator?.didStopUserGesture();
    }
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event) {
    if (widget.route.popGestureEnabled) _drag.addPointer(event);
  }

  void _start(DragStartDetails details) {
    _dragging = true;
    widget.route.navigator?.didStartUserGesture();
  }

  void _update(DragUpdateDetails details) {
    if (!_dragging) return;
    widget.route._swipeBy(_direction * details.primaryDelta! / _width);
  }

  void _end(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    widget.route._swipeEnd(
      _direction * details.velocity.pixelsPerSecond.dx / _width,
    );
  }

  void _cancel() {
    if (!_dragging) return;
    _dragging = false;
    widget.route._swipeEnd(0);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final edge = math.max(rtl ? padding.right : padding.left, _kBackSwipeEdge);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: edge,
          child: Listener(
            onPointerDown: _pointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// Transición de Portadora para las rutas de página que no son
/// [FrPageRoute] (`PageTransitionsTheme` del tema): por defecto, el
/// deslizamiento de la jerarquía, con su efecto sobre la pantalla de abajo.
/// Así ninguna ruta de Material o Cupertino entra con una transición
/// genérica.
class FrPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Crea el constructor de [transition].
  const FrPageTransitionsBuilder([this.transition = FrTransition.slide]);

  /// Transición de entrada.
  final FrTransition transition;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      FrTransitions._delegateOf(transition);

  @override
  Duration get transitionDuration => FrTransitions.durationOf(transition);

  @override
  Duration get reverseTransitionDuration => FrTransitions.backDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _FrTransitionView(
    transition: transition,
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );
}

/// Efecto de salida de la pantalla que queda abajo.
enum _Under { wave, slide, fade, recede }

double _progress(Animation<double> animation, Curve curve) =>
    animation.status == AnimationStatus.reverse
    ? curve.flipped.transform(animation.value)
    : curve.transform(animation.value);

/// Negro puro: bajar el brillo es pintar un velo negro encima.
Color get _black => FrColors.dark.shadow;

const Alignment _viewOrigin = Alignment(0, -0.2);

class _UnderView extends StatelessWidget {
  const _UnderView({
    required this.kind,
    required this.animation,
    required this.child,
  });

  final _Under kind;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final e = _effect(fr);
        return CustomPaint(
          foregroundPainter: _VeilPainter(e.veil),
          child: Transform(
            alignment: _viewOrigin,
            transform: Matrix4.translationValues(0, e.dy, 0)
              ..multiply(Matrix4.diagonal3Values(e.scale, e.scale, 1)),
            child: Opacity(
              opacity: e.opacity,
              child: FractionalTranslation(
                translation: Offset(e.dx, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(e.corner),
                  clipBehavior: e.corner > 0 ? Clip.antiAlias : Clip.none,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Escala, desplazamiento, velo, opacidad y radio en el instante actual.
  _Effect _effect(FrTheme fr) {
    final motion = fr.motion;
    final v = animation.value;
    final reversing = animation.status == AnimationStatus.reverse;
    // Al volver, la pantalla de abajo regresa desde el −28 % con el brillo al
    // 0,45, venga de la transición que venga (`back` del prototipo).
    if (reversing && kind != _Under.recede) {
      final t = _progress(animation, _backCurve(motion));
      return _Effect(dx: -0.28 * t, veil: 0.55 * t);
    }
    switch (kind) {
      case _Under.wave:
        final t = motion.easeOut.transform(v);
        return _Effect(scale: 1 - 0.1 * t, veil: 0.65 * t);
      case _Under.slide:
        final t = _progress(animation, _slideCurve(motion));
        return _Effect(dx: -0.28 * t, veil: 0.55 * t);
      case _Under.fade:
        final out = Interval(0, 420 / 620, curve: motion.easeOut).transform(v);
        return _Effect(opacity: 1 - out);
      case _Under.recede:
        final corner = (fr.radii.sheet + 6) * v;
        return _Effect(
          scale: 1 - 0.07 * v,
          dy: 10 * v,
          veil: 0.45 * v,
          corner: corner,
        );
    }
  }
}

/// Efecto de salida en un instante; sin valores, la pantalla queda igual.
class _Effect {
  const _Effect({
    this.scale = 1,
    this.dx = 0,
    this.dy = 0,
    this.veil = 0,
    this.opacity = 1,
    this.corner = 0,
  });

  final double scale;
  final double dx;
  final double dy;
  final double veil;
  final double opacity;
  final double corner;
}

Curve _slideCurve(FrMotion motion) =>
    FrSpringCurve(motion.springFlow, FrTransitions.slideDuration);

Curve _backCurve(FrMotion motion) =>
    FrSpringCurve(motion.springFlow, FrTransitions.backDuration);

Curve _growCurve(FrMotion motion) =>
    FrSpringCurve(motion.springFlow, const Duration(milliseconds: 620));

class _FrTransitionView extends StatefulWidget {
  const _FrTransitionView({
    required this.transition,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.origin,
    this.from,
  });

  final FrTransition transition;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Offset? origin;
  final Rect? from;
  final Widget child;

  @override
  State<_FrTransitionView> createState() => _FrTransitionViewState();
}

class _FrTransitionViewState extends State<_FrTransitionView> {
  late final Offset? _origin = widget.origin ?? FrTouchOrigin.last;

  _Under? get _under => switch (widget.transition) {
    FrTransition.wave => _Under.wave,
    FrTransition.slide => _Under.slide,
    FrTransition.fade => _Under.fade,
    FrTransition.expand => null,
  };

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) {
      return FadeTransition(opacity: widget.animation, child: widget.child);
    }
    final under = _under;
    final entering = AnimatedBuilder(
      animation: widget.animation,
      child: widget.child,
      builder: (context, child) => _enter(context, child!),
    );
    if (under == null) return entering;
    return _UnderView(
      kind: under,
      animation: widget.secondaryAnimation,
      child: entering,
    );
  }

  Widget _enter(BuildContext context, Widget child) {
    final motion = context.fr.motion;
    final a = widget.animation;
    final back = a.status == AnimationStatus.reverse;
    final dx = back
        ? _backCurve(motion).transform(1 - a.value)
        : widget.transition == FrTransition.slide
        ? 1 - _slideCurve(motion).transform(a.value)
        : 0.0;
    final body = switch (widget.transition) {
      FrTransition.wave => _wave(context, child, back),
      FrTransition.expand => _expand(context, child, back),
      FrTransition.fade => _fade(context, child, back),
      FrTransition.slide => child,
    };
    return FractionalTranslation(translation: Offset(dx, 0), child: body);
  }

  Widget _wave(BuildContext context, Widget child, bool back) {
    final t = back
        ? 1.0
        : context.fr.motion.easeOut.transform(widget.animation.value);
    final scale = 1.08 - 0.08 * t;
    // Entra con brillo 1,5 que baja a 1 (`filter: brightness(1.5)`).
    final brightness =
        FrTransitions.waveBrightness - (FrTransitions.waveBrightness - 1) * t;
    return CustomPaint(
      foregroundPainter: _RingPainter(
        origin: _origin,
        progress: t,
        color: context.fr.colors.signal,
      ),
      child: ClipPath(
        clipper: _CircleClipper(_origin, t),
        clipBehavior: t < 1 ? Clip.antiAlias : Clip.none,
        child: CustomPaint(
          foregroundPainter: _BrightnessPainter(brightness),
          child: Transform.scale(
            scale: scale,
            alignment: _viewOrigin,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _expand(BuildContext context, Widget child, bool back) {
    final fr = context.fr;
    final a = widget.animation.value;
    const growEnd = 620 / 1100;
    final grow = back
        ? 1.0
        : _growCurve(fr.motion).transform(math.min(1, a / growEnd));
    final surface = back
        ? 0.0
        : 1 - const Interval(growEnd, 1040 / 1100).transform(a);
    final page = back
        ? 1.0
        : Interval(580 / 1100, 1, curve: fr.motion.easeOut).transform(a);
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = Offset.zero & constraints.biggest;
        final from =
            widget.from ??
            Rect.fromLTRB(8, full.height / 2, full.width - 8, full.height - 8);
        return Stack(
          children: [
            Positioned.fromRect(
              rect: Rect.lerp(from, full, grow)!,
              child: Opacity(
                opacity: surface,
                child: _ExpandSurface(grow: grow),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: page,
                child: Transform.scale(scale: 0.97 + 0.03 * page, child: child),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fade(BuildContext context, Widget child, bool back) {
    final t = back
        ? 1.0
        : context.fr.motion.easeOut.transform(widget.animation.value);
    // Entra desde un desenfoque de 6 px (`filter: blur(6px)`).
    final blur = FrTransitions.fadeBlur * (1 - t);
    final scaled = Transform.scale(scale: 1.03 - 0.03 * t, child: child);
    return Opacity(
      opacity: t,
      child: blur > 0
          ? ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: scaled,
            )
          : scaled,
    );
  }
}

/// Centro de la onda: [origin] o, sin toque, abajo al centro (195, 640 de
/// 390 × 844, como el prototipo).
Offset _centerOf(Offset? origin, Size size) =>
    origin ?? Offset(size.width / 2, size.height * 640 / 844);

/// Radio que cubre toda la pantalla desde [center], con 20 px de margen.
double _coverRadius(Offset center, Size size) {
  final dx = math.max(center.dx, size.width - center.dx);
  final dy = math.max(center.dy, size.height - center.dy);
  return math.sqrt(dx * dx + dy * dy) + 20;
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper(this.origin, this.progress);

  final Offset? origin;
  final double progress;

  @override
  Path getClip(Size size) {
    final center = _centerOf(origin, size);
    final radius = _coverRadius(center, size) * progress;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleClipper oldClipper) =>
      oldClipper.origin != origin || oldClipper.progress != progress;
}

/// Frente de onda: aro de señal de 1,5 px al 85 % con halo al 30 % y brillo
/// interior al 12 %, que se apaga al crecer.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.origin,
    required this.progress,
    required this.color,
  });

  final Offset? origin;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = 1 - progress;
    if (fade <= 0 || progress <= 0) return;
    final center = _centerOf(origin, size);
    final radius = _coverRadius(center, size) * progress;
    // Brillo interior, halo y aro: desplazamiento, grosor, opacidad y desenfoque.
    const layers = [
      (-10.0, 20.0, 0.12, 20.0),
      (4.0, 8.0, 0.3, 17.0),
      (0.75, 1.5, 0.85, 0.0),
    ];
    for (final (offset, width, alpha, blur) in layers) {
      canvas.drawCircle(
        center,
        math.max(0, radius + offset),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = color.withValues(alpha: alpha * fade)
          ..maskFilter = blur > 0
              ? MaskFilter.blur(BlurStyle.normal, blur)
              : null,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.origin != origin ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}

/// Brillo de CSS (`filter: brightness()`) sobre el contenido opaco que ya
/// está pintado debajo: un gris en `colorDodge` divide cada canal por
/// `1 − gris`, es decir, lo multiplica por [factor]. Sin capas extra.
class _BrightnessPainter extends CustomPainter {
  _BrightnessPainter(this.factor);

  final double factor;

  @override
  void paint(Canvas canvas, Size size) {
    if (factor <= 1) return;
    final dodge = 1 - 1 / factor;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = Color.from(alpha: 1, red: dodge, green: dodge, blue: dodge)
        ..blendMode = BlendMode.colorDodge,
    );
  }

  @override
  bool shouldRepaint(_BrightnessPainter oldDelegate) =>
      oldDelegate.factor != factor;
}

/// Velo negro de opacidad [alpha] sobre el contenido.
class _VeilPainter extends CustomPainter {
  _VeilPainter(this.alpha);

  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _black.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_VeilPainter oldDelegate) => oldDelegate.alpha != alpha;
}

/// Superficie de la hoja que crece en la expansión: su degradado, con el
/// radio de la hoja que se endereza al ocupar la pantalla.
class _ExpandSurface extends StatelessWidget {
  const _ExpandSurface({required this.grow});

  final double grow;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return DecoratedBox(
      key: FrTransitions.expandSurfaceKey,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fr.colors.sheetA, fr.colors.sheetB],
          stops: const [0, 0.3],
        ),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(
            lerpDouble(fr.radii.sheet, 0, grow)!,
          ),
        ),
      ),
    );
  }
}
