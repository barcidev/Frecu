import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';

/// Tono de un [FrBanner].
enum FrBannerTone {
  /// Ámbar: reconexión y eco.
  warn,

  /// Bengala: errores.
  alert,

  /// Neutro: información.
  info,
}

/// Aviso contextual de Portadora, sin modales.
///
/// Lleva el lavado y el borde de su [tone], un ícono, [title] en negrita,
/// [message] y una acción subrayada opcional. Con [onDismiss] muestra el
/// cierre: al tocarlo se funde subiendo 6 px (solo se funde con movimiento
/// reducido) y luego llama a [onDismiss]. [floating] lo vuelve opaco y con
/// sombra para ir sobre la pantalla (aviso de eco).
class FrBanner extends StatefulWidget {
  /// Crea un aviso con el ícono de Material [icon].
  const FrBanner({
    required IconData this.icon,
    required this.tone,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.dismissLabel,
    this.dismissIcon = FrIcons.close,
    this.floating = false,
    super.key,
  }) : drawnIcon = null,
       assert(
         onDismiss == null || dismissLabel != null,
         'El cierre necesita una etiqueta accesible.',
       );

  /// Crea un aviso con el ícono propio [icon] de `FrIcons`.
  const FrBanner.drawn({
    required FrIconData icon,
    required this.tone,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.dismissLabel,
    this.dismissIcon = FrIcons.close,
    this.floating = false,
    super.key,
  }) : drawnIcon = icon,
       icon = null,
       assert(
         onDismiss == null || dismissLabel != null,
         'El cierre necesita una etiqueta accesible.',
       );

  /// Tono.
  final FrBannerTone tone;

  /// Ícono de Material a la izquierda; nulo si el aviso se creó con `.drawn`.
  final IconData? icon;

  /// Ícono propio de `FrIcons` a la izquierda, en lugar de [icon].
  final FrIconData? drawnIcon;

  /// Título en negrita.
  final String title;

  /// Mensaje tras el título.
  final String? message;

  /// Texto de la acción subrayada.
  final String? actionLabel;

  /// Acción.
  final VoidCallback? onAction;

  /// Se llama cuando termina de irse; sin él no hay cierre.
  final VoidCallback? onDismiss;

  /// Etiqueta accesible del cierre.
  final String? dismissLabel;

  /// Ícono propio del cierre; `FrIcons.close` por defecto.
  final FrIconData dismissIcon;

  /// Opaco y con sombra, para flotar sobre la pantalla.
  final bool floating;

  @override
  State<FrBanner> createState() => _FrBannerState();
}

class _FrBannerState extends State<FrBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exit =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDismiss?.call();
      });

  void _dismiss() {
    if (_exit.isAnimating || _exit.isCompleted) return;
    _exit.forward();
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return AnimatedBuilder(
      animation: _exit,
      child: _body(context),
      builder: (context, child) {
        final t = Curves.easeOut.transform(_exit.value);
        return Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: Offset(0, reduce ? 0 : -6 * t),
            child: child,
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final look = _BannerLook.of(widget.tone, fr, floating: widget.floating);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: look.background,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(fr.radii.m),
          side: BorderSide(color: look.border),
        ),
        shadows: [
          if (widget.floating)
            BoxShadow(
              color: c.shadow,
              offset: const Offset(0, 18),
              blurRadius: 40,
              spreadRadius: -16,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: DefaultTextStyle(
          style: fr.type.bodyS.copyWith(color: look.text),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 22, child: _glyph(look.icon)),
              const SizedBox(width: 10),
              Expanded(child: _BannerText(banner: widget)),
              const SizedBox(width: 10),
              SizedBox(
                width: 24,
                child: widget.onDismiss == null ? null : _close(c.tx3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ícono propio o de Material, a 18 px con [color]; el propio va al
  /// principio de su columna de 22 px, como en el prototipo.
  Widget _glyph(Color color) {
    final drawn = widget.drawnIcon;
    if (drawn == null) return Icon(widget.icon, size: 18, color: color);
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: FrIcon(drawn, size: 18, color: color),
    );
  }

  Widget _close(Color color) => FrPressable(
    onPressed: _dismiss,
    semanticLabel: widget.dismissLabel,
    pressedScale: 0.92,
    builder: (context, _, _) => SizedBox.square(
      dimension: 24,
      child: Center(child: FrIcon(widget.dismissIcon, size: 16, color: color)),
    ),
  );
}

/// Título en negrita, mensaje y acción subrayada de un [FrBanner].
class _BannerText extends StatelessWidget {
  const _BannerText({required this.banner});

  final FrBanner banner;

  static const TextStyle _bold = TextStyle(
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
  );

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final message = banner.message;
    final actionLabel = banner.actionLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: banner.title, style: _bold),
              if (message != null) ...[
                const TextSpan(text: ' '),
                TextSpan(text: message),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FrPressable(
              onPressed: banner.onAction,
              builder: (context, _, _) => Text(
                actionLabel,
                style: _bold.copyWith(
                  color: c.tx1,
                  decoration: TextDecoration.underline,
                  decorationColor: c.line3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

@immutable
class _BannerLook {
  const _BannerLook({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
  });

  factory _BannerLook.of(
    FrBannerTone tone,
    FrTheme fr, {
    required bool floating,
  }) {
    final c = fr.colors;
    Color wash(Color tint, double alpha) => floating
        ? Color.alphaBlend(tint.withValues(alpha: 0.1), c.bg1)
        : tint.withValues(alpha: alpha);
    return switch (tone) {
      FrBannerTone.warn => _BannerLook(
        background: wash(c.warn, 0.08),
        border: c.warn.withValues(alpha: floating ? 0.4 : 0.3),
        icon: c.warn,
        text: c.warnTx,
      ),
      FrBannerTone.alert => _BannerLook(
        background: wash(c.alert, 0.08),
        border: c.alert.withValues(alpha: floating ? 0.4 : 0.32),
        icon: c.alert,
        text: c.alertTx,
      ),
      FrBannerTone.info => _BannerLook(
        background: c.bg1,
        border: c.line1,
        icon: c.tx2,
        text: c.tx2,
      ),
    };
  }

  final Color background;
  final Color border;
  final Color icon;
  final Color text;
}
