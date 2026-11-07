import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';

/// Estilo de un [FrIconButton].
enum FrIconButtonVariant {
  /// Superficie `bg1` con borde `line1`.
  filled,

  /// Sin fondo ni borde.
  ghost,

  /// Como `filled`, con el ícono en alerta.
  danger,
}

/// Botón de ícono de Portadora: escala a 0,92 con el resorte `press` y pasa a
/// `bg3` mientras se presiona.
///
/// [selected] lo enciende con la señal. Sin [onPressed] se ve al 38 % y no
/// responde. [semanticLabel] es obligatoria porque el ícono no se lee.
class FrIconButton extends StatelessWidget {
  /// Crea un botón con el ícono de Material [icon].
  const FrIconButton({
    required IconData this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = FrIconButtonVariant.filled,
    this.selected = false,
    this.compact = false,
    super.key,
  }) : drawnIcon = null;

  /// Crea un botón con el ícono propio [icon] de `FrIcons`.
  const FrIconButton.drawn({
    required FrIconData icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = FrIconButtonVariant.filled,
    this.selected = false,
    this.compact = false,
    super.key,
  }) : drawnIcon = icon,
       icon = null;

  /// Ícono de Material; nulo si el botón se creó con `.drawn`.
  final IconData? icon;

  /// Ícono propio de `FrIcons`; nulo si el botón usa [icon].
  final FrIconData? drawnIcon;

  /// Etiqueta accesible.
  final String semanticLabel;

  /// Acción al soltar; nula si está deshabilitado.
  final VoidCallback? onPressed;

  /// Estilo.
  final FrIconButtonVariant variant;

  /// Encendido con la señal.
  final bool selected;

  /// 40 px en lugar de 48.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.38 : 1,
      child: FrPressable(
        onPressed: onPressed,
        semanticLabel: semanticLabel,
        pressedScale: 0.92,
        builder: (context, pressed, _) => _body(context.fr, pressed),
      ),
    );
  }

  Widget _body(FrTheme fr, bool pressed) {
    final c = fr.colors;
    final extent = compact ? 40.0 : 48.0;
    final ghost = variant == FrIconButtonVariant.ghost;
    final wash = c.signal.withValues(alpha: math.max(0, 0.06 * c.washK - 0.06));
    final background = pressed
        ? c.bg3
        : selected
        ? wash
        : ghost
        ? c.bg1.withValues(alpha: 0)
        : c.bg1;
    final side = selected
        ? BorderSide(color: c.signal.withValues(alpha: 0.55))
        : ghost
        ? BorderSide.none
        : BorderSide(color: c.line1);
    final foreground = selected
        ? c.signalFg
        : variant == FrIconButtonVariant.danger
        ? c.alert
        : c.tx1;
    return AnimatedContainer(
      duration: fr.motion.instant,
      width: extent,
      height: extent,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(fr.radii.m * extent / 48),
          side: side,
        ),
        shadows: [
          if (selected)
            BoxShadow(
              color: c.signal.withValues(alpha: 0.6),
              blurRadius: 22,
              spreadRadius: -6,
            ),
        ],
      ),
      child: _glyph(foreground),
    );
  }

  Widget _glyph(Color color) {
    final drawn = drawnIcon;
    return drawn == null
        ? Icon(icon, size: 22, color: color)
        : FrIcon(drawn, size: 22, color: color);
  }
}
