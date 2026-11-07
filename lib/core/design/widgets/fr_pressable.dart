import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';

/// Construye el contenido de un [FrPressable] según si está presionado y el
/// punto de contacto (en coordenadas del contenido, sin escalar).
typedef FrPressBuilder = Widget Function(
  BuildContext context,
  bool pressed,
  Offset? touch,
);

/// Superficie que se hunde con el resorte `press` al presionarla.
///
/// Escala a [pressedScale] al tocar y vuelve a 1 al soltar o cancelar; llama
/// a [onPressed] al soltar. Sin [onPressed] no responde. Con movimiento
/// reducido no escala, pero sigue respondiendo.
class FrPressable extends StatefulWidget {
  /// Crea una superficie presionable.
  const FrPressable({
    required this.onPressed,
    required this.builder,
    this.pressedScale = 0.965,
    this.semanticLabel,
    super.key,
  });

  /// Acción al soltar; nula si no responde.
  final VoidCallback? onPressed;

  /// Contenido de la superficie.
  final FrPressBuilder builder;

  /// Escala mientras se presiona.
  final double pressedScale;

  /// Etiqueta accesible; si existe, reemplaza a la del contenido.
  final String? semanticLabel;

  @override
  State<FrPressable> createState() => _FrPressableState();
}

class _FrPressableState extends State<FrPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  bool _pressed = false;
  Offset? _touch;

  bool get _enabled => widget.onPressed != null;

  void _animateTo(double target) {
    if (context.reduceMotion) {
      _scale.value = 1;
      return;
    }
    _scale.animateWith(
      SpringSimulation(
        context.fr.motion.springPress,
        _scale.value,
        target,
        _scale.velocity,
      ),
    );
  }

  void _down(TapDownDetails details) {
    setState(() {
      _pressed = true;
      _touch = details.localPosition;
    });
    _animateTo(widget.pressedScale);
  }

  void _release() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    _animateTo(1);
  }

  @override
  void didUpdateWidget(FrPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _pressed) {
      _pressed = false;
      _scale.value = 1;
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.semanticLabel;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: label,
      excludeSemantics: label != null,
      onTap: widget.onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: _enabled ? _down : null,
        onTapUp: _enabled ? (_) => _release() : null,
        onTapCancel: _enabled ? _release : null,
        onTap: widget.onPressed,
        child: ScaleTransition(
          scale: _scale,
          child: widget.builder(context, _pressed, _touch),
        ),
      ),
    );
  }
}
