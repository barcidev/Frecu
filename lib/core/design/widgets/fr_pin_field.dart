import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_specular.dart';

/// Aspecto de una celda: relleno, borde, color del dígito y sombras.
typedef _CellLook = ({
  Color? fill,
  BorderSide side,
  Color ink,
  List<BoxShadow> shadows,
});

/// Estado de un [FrPinField].
enum FrPinState {
  /// Escribiendo: el cursor marca la celda siguiente.
  idle,

  /// Verificando: las celdas laten con la señal.
  busy,

  /// Código correcto: las celdas se rellenan de señal.
  ok,

  /// Código incorrecto: alerta y temblor.
  error,
}

/// Código de acceso de Portadora: celdas con dígitos en matriz de puntos.
///
/// Solo dibuja: la pantalla le pasa los dígitos ([value]) y el [state], y los
/// cambia con un `FrKeypad`. En `idle` el cursor de señal marca la celda
/// siguiente y parpadea; el dígito recién escrito aparece con el resorte
/// `organic`. En `busy` las celdas laten escalonadas, en `ok` se rellenan de
/// señal con una ola y en `error` van en alerta y la fila tiembla una vez.
///
/// Con movimiento reducido no hay saltos, ola ni temblor: el cursor queda fijo
/// y `busy` se dibuja quieto con el borde de señal, sin ocultar el estado.
class FrPinField extends StatefulWidget {
  /// Crea un código con los dígitos [value].
  const FrPinField({
    required this.value,
    this.length = 4,
    this.state = FrPinState.idle,
    this.readOnly = false,
    this.semanticLabel,
    super.key,
  });

  /// Dígitos escritos.
  final String value;

  /// Número de celdas.
  final int length;

  /// Estado del código.
  final FrPinState state;

  /// Solo lectura (código generado): sin cursor, sin relleno y borde `line2`.
  final bool readOnly;

  /// Etiqueta accesible del código.
  final String? semanticLabel;

  @override
  State<FrPinField> createState() => _FrPinFieldState();
}

class _FrPinFieldState extends State<FrPinField> with TickerProviderStateMixin {
  static const double _cellWidth = 64;
  static const double _cellHeight = 78;
  static const double _gap = 10;
  static const double _radius = 18;
  static const double _digitSize = 46;
  static const Duration _popDuration = Duration(milliseconds: 460);
  static const int _waveMs = 700;
  static const int _waveStaggerMs = 70;
  static const double _busyPeriod = 1.1;
  static const double _busyStagger = 0.11;
  static const double _blinkPeriod = 1.05;

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: _popDuration,
    value: 1,
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final AnimationController _wave = AnimationController(
    vsync: this,
    value: 1,
  );
  int? _popIndex;

  int? get _cursor =>
      widget.state == FrPinState.idle &&
          !widget.readOnly &&
          widget.value.length < widget.length
      ? widget.value.length
      : null;

  @override
  void didUpdateWidget(FrPinField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduce = context.reduceMotion;
    final typed =
        widget.value.length == oldWidget.value.length + 1 &&
        widget.value.startsWith(oldWidget.value);
    if (typed && !reduce) {
      _popIndex = widget.value.length - 1;
      _pop.forward(from: 0);
    }
    if (widget.state == oldWidget.state || reduce) return;
    if (widget.state == FrPinState.error) {
      _shake.forward(from: 0);
    } else if (widget.state == FrPinState.ok) {
      final cells = math.max(1, math.min(widget.value.length, widget.length));
      _wave
        ..duration = Duration(
          milliseconds: _waveMs + _waveStaggerMs * (cells - 1),
        )
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _shake.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final reduce = context.reduceMotion;
    final pulsing = widget.state == FrPinState.busy && !reduce;
    final row = pulsing
        ? FrLoop(builder: (context, seconds) => _animatedRow(fr, seconds))
        : _animatedRow(fr, null);
    final shake = _shakeTween(fr.motion.easeOut);
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: '${math.min(widget.value.length, widget.length)}/${widget.length}',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(shake.evaluate(_shake), 0),
            child: child,
          ),
          child: row,
        ),
      ),
    );
  }

  Widget _animatedRow(FrTheme fr, ValueListenable<double>? seconds) =>
      AnimatedBuilder(
        animation: Listenable.merge([_pop, _wave, ?seconds]),
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: _gap),
              _cell(fr, i, seconds?.value),
            ],
          ],
        ),
      );

  Widget _cell(FrTheme fr, int index, double? seconds) {
    final reduce = context.reduceMotion;
    final look = _look(fr, index, seconds);
    final waving = _wave.isAnimating && widget.state == FrPinState.ok;
    final instant = widget.state == FrPinState.busy || waving;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(_radius),
      side: look.side,
    );
    // Filo especular solo en la celda en reposo (`.pin i`): la del cursor,
    // la de solo lectura, la correcta y la de error no lo llevan.
    final specular =
        !widget.readOnly &&
        index != _cursor &&
        (widget.state == FrPinState.idle || widget.state == FrPinState.busy);
    final cell = CustomPaint(
      foregroundPainter: specular
          ? FrSpecularPainter(shape: shape, color: fr.colors.spec)
          : null,
      child: AnimatedContainer(
        key: ValueKey('fr-pin-cell-$index'),
        duration: instant
            ? Duration.zero
            : reduce
            ? fr.motion.quick
            : fr.motion.smooth,
        curve: fr.motion.easeOut,
        width: _cellWidth,
        height: _cellHeight,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: look.fill,
          shape: shape,
          shadows: look.shadows,
        ),
        child: _content(fr, index, look.ink),
      ),
    );
    final lift = waving ? _lift(fr, _waveProgress(index)) : 0.0;
    final pop = index == _popIndex && _pop.isAnimating
        ? FrSpringCurve(
            fr.motion.springOrganic,
            _popDuration,
          ).transform(_pop.value)
        : null;
    return Opacity(
      opacity: pop == null ? 1 : (0.2 + 0.8 * pop).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, -6 * lift),
        child: Transform.scale(
          scale: pop == null ? 1 + 0.04 * lift : 0.7 + 0.3 * pop,
          child: cell,
        ),
      ),
    );
  }

  /// Dígito, cursor o punto vacío de la celda [index].
  Widget _content(FrTheme fr, int index, Color ink) {
    if (index < widget.value.length) {
      return Text(
        widget.value[index],
        style: fr.type.digits.copyWith(fontSize: _digitSize, color: ink),
      );
    }
    if (index == _cursor) return _caret(fr, context.reduceMotion);
    return _dot(fr, index);
  }

  /// Relleno, borde, color del dígito y sombras de la celda [index].
  _CellLook _look(FrTheme fr, int index, double? seconds) {
    final c = fr.colors;
    final base = _restLook(fr, cursor: index == _cursor);
    switch (widget.state) {
      case FrPinState.idle:
        return base;
      case FrPinState.busy:
        final level = context.reduceMotion
            ? 1.0
            : _busyLevel(seconds ?? 0, index, fr);
        final border = c.signal.withValues(alpha: 0.6);
        return (
          fill: base.fill,
          side: BorderSide(color: _mix(base.side.color, border, level)),
          ink: _mix(c.tx1, c.signalFg, level),
          shadows: base.shadows,
        );
      case FrPinState.ok:
        final level = fr.motion.easeOut.transform(_waveProgress(index));
        return (
          fill: _mix(c.bg2, c.signal, level),
          side: BorderSide.none,
          ink: _mix(c.tx1, c.signalInk, level),
          shadows: [
            BoxShadow(
              color: c.signal.withValues(alpha: 0.8 * level),
              blurRadius: 26,
              spreadRadius: -6,
            ),
          ],
        );
      case FrPinState.error:
        return (
          fill: base.fill,
          side: BorderSide(color: c.alert.withValues(alpha: 0.65)),
          ink: c.alert,
          shadows: const [],
        );
    }
  }

  /// Celda en reposo; con [cursor], borde de señal (de día, `ledRing`) y
  /// halo.
  _CellLook _restLook(FrTheme fr, {required bool cursor}) {
    final c = fr.colors;
    final fill = widget.readOnly ? null : c.bg2;
    if (!cursor) {
      final line = widget.readOnly ? c.line2 : c.line1;
      return (
        fill: fill,
        side: BorderSide(color: line),
        ink: c.tx1,
        shadows: const [],
      );
    }
    final ring = c.ledRing;
    return (
      fill: fill,
      side: ring != null
          ? BorderSide(color: ring, width: 1.25)
          : BorderSide(color: c.signal.withValues(alpha: 0.6)),
      ink: c.tx1,
      shadows: [
        BoxShadow(color: c.signal.withValues(alpha: 0.06), spreadRadius: 4),
      ],
    );
  }

  /// Ola de `ok`: sube 6 px y escala a 1,04 al 40 % y vuelve.
  static double _lift(FrTheme fr, double wave) {
    if (wave <= 0 || wave >= 1) return 0;
    final curve = fr.motion.easeOut;
    return wave < 0.4
        ? curve.transform(wave / 0.4)
        : 1 - curve.transform((wave - 0.4) / 0.6);
  }

  /// Barra del cursor: parpadea cada 1,05 s; con movimiento reducido, fija.
  Widget _caret(FrTheme fr, bool reduce) {
    final caret = SizedBox(
      key: const ValueKey('fr-pin-caret'),
      width: 2,
      height: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fr.colors.signalFg,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
    if (reduce) return caret;
    return FrLoop(
      builder: (context, seconds) => ValueListenableBuilder<double>(
        valueListenable: seconds,
        builder: (context, t, _) => t % _blinkPeriod < _blinkPeriod / 2
            ? caret
            : const SizedBox(width: 2, height: 30),
      ),
    );
  }

  Widget _dot(FrTheme fr, int index) => SizedBox(
    key: ValueKey('fr-pin-dot-$index'),
    width: 6,
    height: 6,
    child: DecoratedBox(
      decoration: BoxDecoration(color: fr.colors.tx4, shape: BoxShape.circle),
    ),
  );

  /// Avance de la ola de `ok` en la celda [index], de 0 a 1.
  double _waveProgress(int index) {
    if (!_wave.isAnimating) return 1;
    final total = _wave.duration!.inMilliseconds;
    final elapsed = _wave.value * total - _waveStaggerMs * index;
    return (elapsed / _waveMs).clamp(0.0, 1.0);
  }

  /// Latido de `busy` en la celda [index]: sube y baja en 1,1 s.
  double _busyLevel(double seconds, int index, FrTheme fr) {
    final local = seconds - _busyStagger * index;
    if (local <= 0) return 0;
    final phase = (local % _busyPeriod) / _busyPeriod;
    final curve = fr.motion.easeInOut;
    return phase < 0.5
        ? curve.transform(phase * 2)
        : 1 - curve.transform((phase - 0.5) * 2);
  }

  static Color _mix(Color from, Color to, double t) {
    if (t <= 0) return from;
    if (t >= 1) return to;
    return Color.lerp(from, to, t)!;
  }

  /// Temblor de error (`@keyframes shake` del prototipo), en px.
  static Animatable<double> _shakeTween(Curve curve) => TweenSequence<double>([
    for (final (begin, end, weight) in const [
      (0.0, -9.0, 15.0),
      (-9.0, 7.0, 15.0),
      (7.0, -5.0, 15.0),
      (-5.0, 3.0, 15.0),
      (3.0, -1.5, 15.0),
      (-1.5, 0.0, 25.0),
    ])
      TweenSequenceItem(
        tween: Tween<double>(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve)),
        weight: weight,
      ),
  ]);
}
