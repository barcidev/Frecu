import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/features/permissions/presentation/providers/onboarding_permissions_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Fila de un permiso (`.perm`): su ícono, para qué se usa y su estado.
///
/// Concedido enciende el ícono y una marca de señal; negado pinta el borde de
/// alerta y ofrece «Ajustes» para concederlo desde el teléfono.
class PermissionRow extends StatelessWidget {
  /// Crea la fila del permiso [title] en el estado [state].
  const PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.state,
    this.onOpenSettings,
    super.key,
  });

  /// Ícono del permiso.
  final FrIconData icon;

  /// Nombre del permiso.
  final String title;

  /// Para qué se usa.
  final String description;

  /// Estado actual.
  final PermissionState state;

  /// Abre los ajustes de la app; lo usa la fila negada.
  final VoidCallback? onOpenSettings;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final denied = state == PermissionState.denied;
    return Stack(
      children: [
        AnimatedContainer(
          duration: fr.motion.smooth,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.bg1,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(
              color: denied ? c.alert.withValues(alpha: 0.4) : c.line1,
            ),
          ),
          child: _content(fr),
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
    );
  }

  Widget _content(FrTheme fr) {
    final c = fr.colors;
    return Row(
      children: [
        _PermissionIcon(icon: icon, state: state),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: fr.type.title.copyWith(
                  color: c.tx1,
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: const FontWeight(620),
                  fontVariations: const [
                    FontVariation.weight(620),
                    FontVariation.width(106),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: fr.type.bodyS.copyWith(
                  color: c.tx2,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        PermissionStatusMark(state: state, onOpenSettings: onOpenSettings),
      ],
    );
  }
}

/// Caja de 46 px con el ícono del permiso.
class _PermissionIcon extends StatelessWidget {
  const _PermissionIcon({required this.icon, required this.state});

  final FrIconData icon;
  final PermissionState state;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final (background, border, color) = switch (state) {
      PermissionState.granted => (
        c.signal.withValues(alpha: 0.07 * c.washK),
        c.signal.withValues(alpha: 0.45),
        c.signalFg,
      ),
      PermissionState.denied => (c.bg2, c.line1, c.alert),
      PermissionState.pending => (c.bg2, c.line1, c.tx1),
    };
    return AnimatedContainer(
      duration: fr.motion.smooth,
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: FrIcon(icon, size: 22, color: color),
    );
  }
}

/// Estado de un permiso a la derecha de su fila: un círculo vacío si está
/// pendiente, la marca de señal si está concedido (entra con el resorte
/// `organic`, o con un fundido si se pide reducir el movimiento) y la
/// píldora «Ajustes» si está negado.
class PermissionStatusMark extends StatelessWidget {
  /// Crea la marca del estado [state].
  const PermissionStatusMark({
    required this.state,
    this.onOpenSettings,
    super.key,
  });

  /// Estado del permiso.
  final PermissionState state;

  /// Abre los ajustes de la app desde la píldora del estado negado.
  final VoidCallback? onOpenSettings;

  static const double _size = 30;
  static const Duration _pop = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final status = t.permissions.status;
    return switch (state) {
      PermissionState.pending => Semantics(
        label: status.pending,
        child: _circle(context, granted: false),
      ),
      PermissionState.granted => Semantics(
        label: status.granted,
        child: _granted(context),
      ),
      PermissionState.denied => Semantics(
        label: status.denied,
        child: _settings(context),
      ),
    };
  }

  Widget _granted(BuildContext context) {
    final fr = context.fr;
    final reduce = context.reduceMotion;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduce ? fr.motion.quick : _pop,
      curve: reduce
          ? Curves.linear
          : FrSpringCurve(fr.motion.springOrganic, _pop),
      builder: (context, value, child) => reduce
          ? Opacity(opacity: value, child: child)
          : Transform.scale(scale: value, child: child),
      child: _circle(context, granted: true),
    );
  }

  Widget _circle(BuildContext context, {required bool granted}) {
    final c = context.fr.colors;
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: granted ? c.signal : null,
        border: granted ? null : Border.all(color: c.line2),
        boxShadow: granted
            ? [
                BoxShadow(
                  color: c.signal.withValues(alpha: 0.8),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: granted
          ? FrIcon(FrIcons.check, size: 16, color: c.signalInk)
          : null,
    );
  }

  Widget _settings(BuildContext context) {
    final fr = context.fr;
    final alert = fr.colors.alert;
    return FrPressable(
      onPressed: onOpenSettings,
      builder: (context, pressed, _) => Container(
        height: _size,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: alert.withValues(alpha: 0.4)),
        ),
        child: Text(
          t.permissions.openSettings.toUpperCase(),
          style: fr.type.labelS.copyWith(color: alert),
        ),
      ),
    );
  }
}
