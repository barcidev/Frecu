import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';

/// Campo de texto de Portadora: etiqueta en mayúsculas, contador, foco con la
/// señal y error con temblor.
///
/// Con foco enciende el borde de señal (de día, el anillo `ledRing`) y abre
/// una línea desde el centro. Con [error] pinta el borde y la ayuda en
/// alerta y tiembla una vez; con movimiento reducido no tiembla y la línea
/// aparece con un fundido.
class FrField extends StatefulWidget {
  /// Crea un campo con [label].
  const FrField({
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.help,
    this.error,
    this.maxLength,
    this.mono = false,
    this.icon,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    super.key,
  }) : drawnIcon = null;

  /// Crea un campo con [label] y el ícono propio [icon] de `FrIcons`.
  const FrField.drawn({
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.help,
    this.error,
    this.maxLength,
    this.mono = false,
    FrIconData? icon,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    super.key,
  }) : drawnIcon = icon,
       icon = null;

  /// Etiqueta; se muestra en mayúsculas.
  final String label;

  /// Controlador del texto; si falta, el campo crea uno.
  final TextEditingController? controller;

  /// Foco; si falta, el campo crea uno.
  final FocusNode? focusNode;

  /// Texto de ejemplo con el campo vacío.
  final String? hint;

  /// Ayuda bajo el campo.
  final String? help;

  /// Error bajo el campo; reemplaza a [help].
  final String? error;

  /// Máximo de caracteres; muestra el contador `n/máx`.
  final int? maxLength;

  /// Texto en Martian Mono (códigos e IP).
  final bool mono;

  /// Ícono de Material antes del texto; nulo si el campo se creó con
  /// `.drawn`.
  final IconData? icon;

  /// Ícono propio de `FrIcons` antes del texto, en lugar de [icon].
  final FrIconData? drawnIcon;

  /// Llamado con cada cambio del texto.
  final ValueChanged<String>? onChanged;

  /// Llamado al confirmar desde el teclado.
  final ValueChanged<String>? onSubmitted;

  /// Acción del teclado.
  final TextInputAction? textInputAction;

  /// Tipo de teclado.
  final TextInputType? keyboardType;

  /// Pide el foco al aparecer.
  final bool autofocus;

  @override
  State<FrField> createState() => _FrFieldState();
}

class _FrFieldState extends State<FrField> with SingleTickerProviderStateMixin {
  static const double _boxHeight = 58;
  static const double _gap = 9;

  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  bool _focused = false;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void didUpdateWidget(FrField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
      _focused = _focus.hasFocus;
    }
    if (oldWidget.error == null &&
        widget.error != null &&
        !context.reduceMotion) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _shake.dispose();
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final message = widget.error ?? widget.help;
    final shake = _shakeTween(fr.motion.easeOut);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(fr),
        const SizedBox(height: _gap),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(shake.evaluate(_shake), 0),
            child: child,
          ),
          child: _box(fr),
        ),
        if (message != null) ...[
          const SizedBox(height: _gap),
          Text(
            message,
            style: fr.type.bodyS.copyWith(
              color: widget.error != null ? fr.colors.alert : fr.colors.tx3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(FrTheme fr) {
    final max = widget.maxLength;
    final muted = fr.colors.tx3;
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.label.toUpperCase(),
            style: fr.type.label.copyWith(color: muted),
          ),
        ),
        if (max != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => Text(
              '${value.text.characters.length}/$max',
              style: fr.type.labelS.copyWith(color: muted),
            ),
          ),
      ],
    );
  }

  Widget _box(FrTheme fr) {
    final c = fr.colors;
    final hasError = widget.error != null;
    final ring = c.ledRing;
    final side = hasError
        ? BorderSide(color: c.alert.withValues(alpha: 0.7))
        : !_focused
        ? BorderSide(color: c.line1)
        : ring != null
        ? BorderSide(color: ring, width: 1.25)
        : BorderSide(color: c.signal.withValues(alpha: 0.55));
    final glow = hasError
        ? c.alert.withValues(alpha: 0.08)
        : c.signal.withValues(alpha: _focused ? 0.07 : 0);
    return AnimatedContainer(
      key: const ValueKey('fr-field-box'),
      duration: fr.motion.smooth,
      curve: fr.motion.easeOut,
      height: _boxHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: c.bg2,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(fr.radii.m),
          side: side,
        ),
        shadows: [BoxShadow(color: glow, spreadRadius: 4)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _input(fr)),
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 2,
            child: _line(fr),
          ),
        ],
      ),
    );
  }

  Widget _input(FrTheme fr) {
    final c = fr.colors;
    final max = widget.maxLength;
    final glyph = _glyph(c.tx3);
    final style = (widget.mono ? fr.type.data : fr.type.bodyL).copyWith(
      color: c.tx1,
    );
    return Row(
      children: [
        if (glyph != null) ...[glyph, const SizedBox(width: 10)],
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            inputFormatters: [
              if (max != null) LengthLimitingTextInputFormatter(max),
            ],
            style: style,
            cursorColor: c.signalFg,
            decoration: InputDecoration.collapsed(
              hintText: widget.hint,
              hintStyle: style.copyWith(color: c.tx4),
            ),
          ),
        ),
      ],
    );
  }

  /// Ícono propio o de Material, a 18 px con [color].
  Widget? _glyph(Color color) {
    final drawn = widget.drawnIcon;
    if (drawn != null) return FrIcon(drawn, size: 18, color: color);
    final material = widget.icon;
    if (material != null) return Icon(material, size: 18, color: color);
    return null;
  }

  /// Línea inferior: se abre desde el centro; con movimiento reducido entra
  /// con un fundido.
  Widget _line(FrTheme fr) {
    final ink = fr.colors.signalFg;
    final line = DecoratedBox(
      key: const ValueKey('fr-field-line'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [ink.withValues(alpha: 0), ink, ink.withValues(alpha: 0)],
        ),
      ),
    );
    if (context.reduceMotion) {
      return AnimatedOpacity(
        opacity: _focused ? 0.9 : 0,
        duration: fr.motion.quick,
        child: line,
      );
    }
    return Opacity(
      opacity: 0.9,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _focused ? 1 : 0),
        duration: const Duration(milliseconds: 600),
        curve: fr.motion.easeOut,
        builder: (context, scale, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(scale, 1, 1),
          child: child,
        ),
        child: line,
      ),
    );
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
