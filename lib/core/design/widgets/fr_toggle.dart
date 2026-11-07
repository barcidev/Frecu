import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';

/// Interruptor de Portadora.
///
/// Encendido es un relleno de señal con la perilla en `signalInk` a la
/// derecha; apagado, `bg3` con la perilla en `tx2` a la izquierda. La perilla
/// viaja con el resorte `organic` y se estira a 34 px mientras se presiona.
/// Sin [onChanged] se ve al 38 % y no responde. Con movimiento reducido la
/// perilla cambia de lugar sin resorte ni estiramiento.
class FrToggle extends StatefulWidget {
  /// Crea un interruptor en [value].
  const FrToggle({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  /// Encendido.
  final bool value;

  /// Llamado con el valor contrario al tocarlo; nulo si no responde.
  final ValueChanged<bool>? onChanged;

  /// Etiqueta accesible.
  final String? semanticLabel;

  @override
  State<FrToggle> createState() => _FrToggleState();
}

class _FrToggleState extends State<FrToggle> with TickerProviderStateMixin {
  static const double _width = 54;
  static const double _height = 32;
  static const double _inset = 3;
  static const double _knob = 26;
  static const double _stretch = 8;
  static const double _travel = _width - _knob - 2 * _inset;

  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  bool get _enabled => widget.onChanged != null;

  @override
  void didUpdateWidget(FrToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    final target = widget.value ? 1.0 : 0.0;
    if (context.reduceMotion) {
      _position.value = target;
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
  }

  @override
  void dispose() {
    _position.dispose();
    _press.dispose();
    super.dispose();
  }

  void _down() {
    if (!context.reduceMotion) _press.forward();
  }

  void _release() => _press.reverse();

  void _toggle() => widget.onChanged?.call(!widget.value);

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final on = widget.value;
    final duration = context.reduceMotion ? fr.motion.quick : fr.motion.smooth;
    return Opacity(
      opacity: _enabled ? 1 : 0.38,
      child: Semantics(
        container: true,
        toggled: on,
        enabled: _enabled,
        label: widget.semanticLabel,
        onTap: _enabled ? _toggle : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: _enabled ? (_) => _down() : null,
          onTapUp: _enabled ? (_) => _release() : null,
          onTapCancel: _enabled ? _release : null,
          onTap: _enabled ? _toggle : null,
          // La perilla va sobre la pista y no dentro de su `Container`, para
          // que el borde no la desplace (como el `inset` del prototipo).
          child: SizedBox(
            width: _width,
            height: _height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: _track(c, duration)),
                _knobOf(fr, duration),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Perilla: viaja con el resorte y se estira hacia el centro al presionar.
  Widget _knobOf(FrTheme fr, Duration duration) {
    final c = fr.colors;
    return AnimatedBuilder(
      animation: Listenable.merge([_position, _press]),
      builder: (context, child) {
        final stretch = fr.motion.easeOut.transform(_press.value);
        return Positioned(
          left: _inset + _position.value * (_travel - _stretch * stretch),
          top: _inset,
          width: _knob + _stretch * stretch,
          height: _knob,
          child: child!,
        );
      },
      child: AnimatedContainer(
        key: const ValueKey('fr-toggle-knob'),
        duration: duration,
        decoration: BoxDecoration(
          color: widget.value ? c.signalInk : c.tx2,
          borderRadius: BorderRadius.circular(_knob / 2),
        ),
      ),
    );
  }

  Widget _track(FrColors c, Duration duration) {
    final on = widget.value;
    return AnimatedContainer(
      key: const ValueKey('fr-toggle-track'),
      duration: duration,
      decoration: ShapeDecoration(
        color: on ? c.signal : c.bg3,
        shape: StadiumBorder(
          side: on ? BorderSide.none : BorderSide(color: c.line2),
        ),
        shadows: [
          if (on)
            BoxShadow(
              color: c.signal.withValues(alpha: 0.7),
              blurRadius: 20,
              spreadRadius: -6,
            ),
        ],
      ),
    );
  }
}
