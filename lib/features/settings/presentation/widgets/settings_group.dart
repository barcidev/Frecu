import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';

/// Título de una sección de Ajustes, en mayúsculas (`.set-label`).
class SettingsSectionLabel extends StatelessWidget {
  /// Crea el título de sección [label].
  const SettingsSectionLabel(this.label, {super.key});

  /// Texto; se muestra en mayúsculas.
  final String label;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 10),
      child: Text(
        label.toUpperCase(),
        style: fr.type.labelS.copyWith(color: fr.colors.tx3),
      ),
    );
  }
}

/// Grupo de filas de Ajustes (`.group`): superficie `bg1` con borde, filo
/// especular arriba y una línea entre filas.
class SettingsGroup extends StatelessWidget {
  /// Crea un grupo con [children].
  const SettingsGroup({required this.children, super.key});

  /// Filas del grupo.
  final List<Widget> children;

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: c.bg1,
          shape: shape.copyWith(side: BorderSide(color: c.line1)),
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, child) in children.indexed) ...[
                    if (index > 0) Divider(height: 1, color: c.line1),
                    child,
                  ],
                ],
              ),
              // Filo especular arriba.
              Positioned(
                top: 1,
                left: _radius * 0.6,
                right: _radius * 0.6,
                height: 1,
                child: ColoredBox(color: c.spec),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de Ajustes (`.row`): título, subtítulo opcional y un control a la
/// derecha; [below] va debajo, a todo el ancho.
///
/// Con [onPressed] toda la fila responde al toque, se anuncia como botón y
/// termina en un chevron, después de [trailing] (`.rv` del prototipo).
class SettingsRow extends StatelessWidget {
  /// Crea una fila con [title].
  const SettingsRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.below,
    this.onPressed,
    super.key,
  });

  /// Título.
  final String title;

  /// Explicación bajo el título.
  final String? subtitle;

  /// Control a la derecha.
  final Widget? trailing;

  /// Control debajo del texto, a todo el ancho.
  final Widget? below;

  /// Acción al tocar la fila; nula si la fila no responde.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final trailing = this.trailing;
    final below = this.below;
    final onPressed = this.onPressed;
    final row = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Expanded(child: _texts(fr)),
                if (trailing != null) ...[const SizedBox(width: 12), trailing],
                if (onPressed != null) ...[
                  SizedBox(width: trailing == null ? 12 : 8),
                  FrIcon(FrIcons.chevron, size: 18, color: fr.colors.tx3),
                ],
              ],
            ),
          ),
        ),
        if (below != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: below,
          ),
      ],
    );
    if (onPressed == null) return row;
    return FrPressable(
      onPressed: onPressed,
      pressedScale: 0.98,
      builder: (_, _, _) => row,
    );
  }

  /// Título en Archivo 560 a 15 px y subtítulo en `bodyS` a 12,5 px.
  Widget _texts(FrTheme fr) {
    final c = fr.colors;
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: fr.type.body.copyWith(
            color: c.tx1,
            fontSize: 15,
            height: 1.25,
            fontWeight: const FontWeight(560),
            fontVariations: const [
              FontVariation.weight(560),
              FontVariation.width(100),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: fr.type.bodyS.copyWith(
              color: c.tx3,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
