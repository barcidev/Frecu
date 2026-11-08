import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_specular.dart';

/// Opción de un [FrSegmented].
@immutable
class FrSegment<T> {
  /// Crea una opción con su [value] y su [label].
  const FrSegment({required this.value, required this.label, this.icon});

  /// Valor que entrega al elegirla.
  final T value;

  /// Etiqueta; se muestra en mayúsculas.
  final String label;

  /// Ícono antes de la etiqueta.
  final Widget? icon;
}

/// Selector segmentado de Portadora (modo de habla, tema, sistema).
///
/// El pulgar viaja hasta el segmento elegido con el resorte `organic` y se
/// estira al salir. [signal] lo pinta de señal con el texto en `signalInk`.
/// Sin [onChanged] se ve al 38 % y no responde. Con movimiento reducido el
/// pulgar cambia de lugar sin resorte ni estiramiento.
///
/// Necesita un ancho acotado: sus segmentos se reparten el ancho por igual.
/// Cada etiqueta usa el segmento entero salvo 4 px por lado y, si aun así no
/// cabe, se achica lo justo en lugar de cortarse (en el prototipo la columna
/// crece hasta que cabe, `grid-auto-columns: 1fr`).
class FrSegmented<T> extends StatefulWidget {
  /// Crea un selector con [segments] y [value] elegido.
  const FrSegmented({
    required this.segments,
    required this.value,
    required this.onChanged,
    this.signal = false,
    this.height = 48,
    super.key,
  });

  /// Opciones, de izquierda a derecha.
  final List<FrSegment<T>> segments;

  /// Valor elegido.
  final T value;

  /// Llamado con el valor del segmento tocado; nulo si no responde.
  final ValueChanged<T>? onChanged;

  /// Pulgar de señal.
  final bool signal;

  /// Alto en px: 48, o 40 en las filas de Ajustes (`.v-settings .row
  /// .seg`).
  final double height;

  @override
  State<FrSegmented<T>> createState() => _FrSegmentedState<T>();
}

class _FrSegmentedState<T> extends State<FrSegmented<T>>
    with TickerProviderStateMixin {
  static const double _pad = 4;
  static const double _thumbRadius = 12;

  /// Margen mínimo de la etiqueta a cada lado, dentro de su segmento.
  static const double _labelPad = 4;

  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: _index.toDouble(),
  );
  late final AnimationController _stretch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );

  int get _index =>
      math.max(0, widget.segments.indexWhere((s) => s.value == widget.value));

  @override
  void didUpdateWidget(FrSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _index.toDouble();
    if (target == _position.value && !_position.isAnimating) return;
    if (context.reduceMotion) {
      _position.value = target;
      _stretch.value = 1;
      return;
    }
    _position.animateWith(
      SpringSimulation(
        context.fr.motion.springOrganic,
        _position.value,
        target,
        _position.velocity,
        snapToEnd: true,
      ),
    );
    _stretch.forward(from: 0);
  }

  @override
  void dispose() {
    _position.dispose();
    _stretch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Opacity(
      opacity: widget.onChanged == null ? 0.38 : 1,
      // `DecoratedBox` y no `Container`: el borde no debe restar espacio al
      // pulgar, como el `inset` del prototipo.
      child: SizedBox(
        height: widget.height,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.bg1,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(fr.radii.m),
              side: BorderSide(color: c.line1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: _track(fr),
          ),
        ),
      ),
    );
  }

  Widget _track(FrTheme fr) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth / widget.segments.length;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          _thumb(fr, width),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, segment) in widget.segments.indexed)
                  Expanded(child: _segment(fr, i, segment)),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _thumb(FrTheme fr, double width) {
    final c = fr.colors;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(_thumbRadius),
      side: widget.signal ? BorderSide.none : BorderSide(color: c.line2),
    );
    final box = DecoratedBox(
      key: const ValueKey('fr-segmented-thumb'),
      decoration: ShapeDecoration(
        color: widget.signal ? c.signal : c.bg3,
        shape: shape,
        shadows: [
          if (widget.signal)
            BoxShadow(
              color: c.signal.withValues(alpha: 0.8),
              blurRadius: 22,
              spreadRadius: -6,
            )
          else
            BoxShadow(
              color: c.shadow.withValues(alpha: 0.8 * c.shadow.a),
              offset: const Offset(0, 4),
              blurRadius: 14,
              spreadRadius: -6,
            ),
        ],
      ),
      // Filo especular (en la señal, un brillo blanco al 50 %).
      child: CustomPaint(
        size: Size.infinite,
        painter: FrSpecularPainter(
          shape: shape,
          color: widget.signal ? const Color(0x80FFFFFF) : c.spec,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([_position, _stretch]),
      builder: (context, child) {
        final (scaleX, scaleY) = _stretchScale(fr);
        return Positioned(
          left: _position.value * width,
          top: 0,
          bottom: 0,
          width: width,
          child: Transform.scale(scaleX: scaleX, scaleY: scaleY, child: child),
        );
      },
      child: box,
    );
  }

  /// Estiramiento al salir (`@keyframes stretch`): 1,16 × 0,86 al 35 %.
  (double, double) _stretchScale(FrTheme fr) {
    if (!_stretch.isAnimating) return (1, 1);
    final t = _stretch.value;
    final curve = fr.motion.easeOut;
    final k = t < 0.35
        ? curve.transform(t / 0.35)
        : 1 - curve.transform((t - 0.35) / 0.65);
    return (1 + 0.16 * k, 1 - 0.14 * k);
  }

  Widget _segment(FrTheme fr, int index, FrSegment<T> segment) {
    final c = fr.colors;
    final selected = index == _index;
    final onChanged = widget.onChanged;
    final select = onChanged == null || selected
        ? null
        : () => onChanged(segment.value);
    final color = !selected
        ? c.tx3
        : widget.signal
        ? c.signalInk
        : c.tx1;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      enabled: onChanged != null,
      label: segment.label,
      onTap: select,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('fr-segment-$index'),
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: select,
        child: AnimatedDefaultTextStyle(
          duration: context.reduceMotion ? fr.motion.quick : fr.motion.smooth,
          style: fr.type.label.copyWith(color: color, letterSpacing: 0.66),
          child: _label(segment, color),
        ),
      ),
    );
  }

  /// Ícono y etiqueta en mayúsculas, centrados; si no caben, se achican
  /// juntos en vez de cortar la etiqueta.
  static Widget _label(FrSegment<Object?> segment, Color color) {
    final icon = segment.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _labelPad),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(color: color, size: 18),
                  child: icon,
                ),
                const SizedBox(width: 7),
              ],
              Text(segment.label.toUpperCase(), maxLines: 1, softWrap: false),
            ],
          ),
        ),
      ),
    );
  }
}
