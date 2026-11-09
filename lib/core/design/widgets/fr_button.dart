import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/core/design/widgets/fr_specular.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';

/// Estilo de un [FrButton].
enum FrButtonVariant {
  /// Relleno de señal: la acción principal de la pantalla.
  primary,

  /// Superficie `bg2` con borde: acciones secundarias.
  secondary,

  /// Sin fondo: acciones terciarias.
  ghost,

  /// Lavado de alerta: acciones destructivas.
  danger,

  /// Relleno de alerta (`.btn-danger-solid`): la confirmación de una acción
  /// destructiva, como cerrar o salir de la frecu.
  dangerSolid,
}

/// Tamaño de un [FrButton].
enum FrButtonSize {
  /// 58 px de alto (48 en `ghost`).
  regular,

  /// 44 px de alto y radio 14.
  small,
}

/// Botón de Portadora: se hunde con el resorte `press` y se ilumina desde el
/// punto del dedo.
///
/// Sin [onPressed] se ve al 38 % y no responde. Con [loading] muestra el
/// [WaveLoader] en lugar del texto y no responde, pero conserva [label] como
/// etiqueta accesible.
class FrButton extends StatelessWidget {
  /// Crea un botón con [label].
  const FrButton({
    required this.label,
    required this.onPressed,
    this.variant = FrButtonVariant.primary,
    this.size = FrButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
    super.key,
  }) : drawnIcon = null,
       drawnTrailingIcon = null;

  /// Crea un botón con [label] y los íconos propios [icon] y [trailingIcon]
  /// de `FrIcons`.
  const FrButton.drawn({
    required this.label,
    required this.onPressed,
    this.variant = FrButtonVariant.primary,
    this.size = FrButtonSize.regular,
    FrIconData? icon,
    FrIconData? trailingIcon,
    this.loading = false,
    this.expand = false,
    super.key,
  }) : drawnIcon = icon,
       drawnTrailingIcon = trailingIcon,
       icon = null,
       trailingIcon = null;

  /// Texto del botón.
  final String label;

  /// Acción al soltar; nula si el botón está deshabilitado.
  final VoidCallback? onPressed;

  /// Estilo.
  final FrButtonVariant variant;

  /// Tamaño.
  final FrButtonSize size;

  /// Ícono antes del texto.
  final IconData? icon;

  /// Ícono después del texto.
  final IconData? trailingIcon;

  /// Ícono propio antes del texto, en lugar de [icon].
  final FrIconData? drawnIcon;

  /// Ícono propio después del texto, en lugar de [trailingIcon].
  final FrIconData? drawnTrailingIcon;

  /// Muestra la onda de carga y no responde.
  final bool loading;

  /// Ocupa todo el ancho disponible.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = _ButtonStyle.of(variant, context.fr);
    final button = FrPressable(
      onPressed: loading ? null : onPressed,
      semanticLabel: label,
      builder: (context, pressed, touch) => _ButtonBody(
        button: this,
        style: style,
        pressed: pressed,
        touch: touch,
      ),
    );
    return Opacity(
      opacity: onPressed == null ? 0.38 : 1,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// Tinta sobre el relleno de alerta (`.btn-danger-solid` del prototipo).
const Color _alertInk = Color(0xFF1A0503);

/// Blanco de los brillos interiores de los rellenos.
const Color _white = Color(0xFFFFFFFF);

/// Negro del canto inferior del botón principal.
const Color _black = Color(0xFF000000);

@immutable
class _ButtonStyle {
  const _ButtonStyle({
    required this.background,
    required this.foreground,
    required this.light,
    required this.loader,
    this.side = BorderSide.none,
    this.shadows = const [],
    this.topEdge,
    this.bottomEdge,
  });

  factory _ButtonStyle.of(FrButtonVariant variant, FrTheme fr) {
    final c = fr.colors;
    return switch (variant) {
      FrButtonVariant.primary => _ButtonStyle(
        background: c.signal,
        foreground: c.signalInk,
        light: c.signalHi.withValues(alpha: 0.5),
        loader: c.signalInk,
        shadows: [
          BoxShadow(
            color: c.signal.withValues(alpha: 0.7),
            offset: const Offset(0, 10),
            blurRadius: 32,
            spreadRadius: -12,
          ),
        ],
        topEdge: _white.withValues(alpha: 0.6),
        bottomEdge: _black.withValues(alpha: 0.14),
      ),
      FrButtonVariant.secondary => _ButtonStyle(
        background: c.bg2,
        foreground: c.tx1,
        light: c.touch,
        loader: c.signalFg,
        side: BorderSide(color: c.line2),
        topEdge: c.spec,
      ),
      FrButtonVariant.ghost => _ButtonStyle(
        background: c.bg2.withValues(alpha: 0),
        foreground: c.tx2,
        light: c.touch,
        loader: c.signalFg,
      ),
      FrButtonVariant.danger => _ButtonStyle(
        background: c.alert.withValues(alpha: 0.12),
        foreground: c.alertTx,
        light: c.touch,
        loader: c.alert,
        side: BorderSide(color: c.alert.withValues(alpha: 0.38)),
      ),
      FrButtonVariant.dangerSolid => _ButtonStyle(
        background: c.alert,
        foreground: _alertInk,
        light: _white.withValues(alpha: 0.35),
        loader: _alertInk,
        shadows: [
          BoxShadow(
            color: c.alert.withValues(alpha: 0.7),
            offset: const Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -12,
          ),
        ],
        topEdge: _white.withValues(alpha: 0.4),
      ),
    };
  }

  final Color background;
  final Color foreground;
  final Color light;
  final Color loader;
  final BorderSide side;
  final List<BoxShadow> shadows;

  /// Brillo de 1 px en el canto superior (filo especular).
  final Color? topEdge;

  /// Sombra de 2 px en el canto inferior.
  final Color? bottomEdge;
}

class _ButtonBody extends StatelessWidget {
  const _ButtonBody({
    required this.button,
    required this.style,
    required this.pressed,
    required this.touch,
  });

  final FrButton button;
  final _ButtonStyle style;
  final bool pressed;
  final Offset? touch;

  bool get _small => button.size == FrButtonSize.small;

  double get _height => _small
      ? 44
      : button.variant == FrButtonVariant.ghost
      ? 48
      : 58;

  double get _padding => _small
      ? 16
      : button.variant == FrButtonVariant.ghost
      ? 14
      : 22;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(_small ? _smallRadius : fr.radii.btn),
      side: style.side,
    );
    final top = style.topEdge;
    final bottom = style.bottomEdge;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: style.background,
        shape: shape,
        shadows: style.shadows,
      ),
      child: ClipPath.shape(
        shape: shape,
        child: Stack(
          children: [
            Positioned.fill(child: _light(fr)),
            SizedBox(
              height: _height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _padding),
                child: Row(
                  mainAxisSize: button.expand
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _content(fr),
                ),
              ),
            ),
            if (top != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: FrSpecularPainter(shape: shape, color: top),
                ),
              ),
            if (bottom != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: FrSpecularPainter(
                    shape: shape,
                    color: bottom,
                    depth: -2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Radio del botón pequeño (`.btn-s`).
  static const double _smallRadius = 14;

  /// Luz que nace en el dedo: entra en 60 ms y sale en 420 ms.
  Widget _light(FrTheme fr) => IgnorePointer(
    child: AnimatedOpacity(
      opacity: pressed ? 1 : 0,
      duration: Duration(milliseconds: pressed ? 60 : 420),
      curve: fr.motion.easeOut,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final at = touch;
          final center = at == null
              ? Alignment.center
              : Alignment(
                  at.dx / size.width * 2 - 1,
                  at.dy / size.height * 2 - 1,
                );
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: center,
                radius: 160 / size.shortestSide,
                colors: [style.light, style.light.withValues(alpha: 0)],
                stops: const [0, 0.7],
              ),
            ),
          );
        },
      ),
    ),
  );

  List<Widget> _content(FrTheme fr) {
    if (button.loading) {
      return [WaveLoader(width: 46, height: 18, color: style.loader)];
    }
    final text = fr.type.button.copyWith(
      color: style.foreground,
      fontSize: _small ? 14.5 : null,
    );
    final leading = _glyph(button.icon, button.drawnIcon);
    final trailing = _glyph(button.trailingIcon, button.drawnTrailingIcon);
    return [
      if (leading != null) ...[leading, const SizedBox(width: 10)],
      Text(button.label, style: text, maxLines: 1, softWrap: false),
      if (trailing != null) ...[const SizedBox(width: 10), trailing],
    ];
  }

  /// Ícono de Material o propio, a 22 px con el primer plano del estilo.
  Widget? _glyph(IconData? material, FrIconData? drawn) {
    if (drawn != null) {
      return FrIcon(drawn, size: 22, color: style.foreground);
    }
    if (material != null) {
      return Icon(material, size: 22, color: style.foreground);
    }
    return null;
  }
}
