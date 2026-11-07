import 'package:flutter/material.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_motion.dart';
import 'package:frecu/core/design/tokens/fr_radii.dart';
import 'package:frecu/core/design/tokens/fr_space.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';

/// Tokens de Portadora del tema activo, agrupados para leerlos con
/// `context.fr`.
@immutable
class FrTheme {
  /// Agrupa los tokens de un tema.
  const FrTheme({
    required this.colors,
    required this.type,
    required this.space,
    required this.radii,
    required this.motion,
  });

  /// Lee los tokens registrados en el [Theme] de [context]. Si el tema no los
  /// trae, usa los de Portadora según su brillo.
  factory FrTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return FrTheme(
      colors:
          theme.extension<FrColors>() ??
          (isDark ? FrColors.dark : FrColors.light),
      type: theme.extension<FrType>() ?? FrType.standard,
      space: theme.extension<FrSpace>() ?? FrSpace.standard,
      radii: theme.extension<FrRadii>() ?? FrRadii.standard,
      motion: theme.extension<FrMotion>() ?? FrMotion.standard,
    );
  }

  /// Colores de noche o de día.
  final FrColors colors;

  /// Escala tipográfica.
  final FrType type;

  /// Espaciado.
  final FrSpace space;

  /// Radios.
  final FrRadii radii;

  /// Duraciones, curvas y resortes.
  final FrMotion motion;
}

/// Acceso a los tokens de Portadora desde cualquier widget.
extension FrThemeContext on BuildContext {
  /// Tokens del tema activo.
  FrTheme get fr => FrTheme.of(this);
}
