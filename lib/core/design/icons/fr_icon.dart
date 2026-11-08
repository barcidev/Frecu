import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';

/// Ícono de Portadora dibujado en código desde sus trazos SVG.
///
/// Como [Icon], toma el tamaño, el color y la opacidad de [IconTheme] salvo
/// que reciba [size] o [color] (24 px y negro si no hay tema). Traza con
/// puntas y uniones redondeadas y el grosor del prototipo para su tamaño
/// ([strokeFor]), en unidades de la rejilla de 24.
class FrIcon extends StatelessWidget {
  /// Crea el ícono [icon].
  const FrIcon(
    this.icon, {
    this.size,
    this.color,
    this.strokeWidth,
    this.semanticLabel,
    super.key,
  });

  /// Ícono a dibujar, de `FrIcons`.
  final FrIconData icon;

  /// Lado en píxeles lógicos; si es nulo, el de [IconTheme].
  final double? size;

  /// Color; si es nulo, el de [IconTheme].
  final Color? color;

  /// Grosor en unidades de la rejilla; si es nulo, [strokeFor] del tamaño.
  final double? strokeWidth;

  /// Texto con el que se anuncia; sin él, el ícono no se lee.
  final String? semanticLabel;

  /// Grosor del trazo del prototipo para un ícono de [size] px: 1,8 hasta
  /// 16 px, 1,6 por defecto, 1,5 desde 28 px y 1,4 desde 34 px.
  static double strokeFor(double size) {
    if (size <= 16) return 1.8;
    if (size >= 34) return 1.4;
    if (size >= 28) return 1.5;
    return 1.6;
  }

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final extent = size ?? theme.size ?? 24;
    final opacity = theme.opacity ?? 1;
    var ink = color ?? theme.color ?? const Color(0xFF000000);
    if (opacity != 1) ink = ink.withValues(alpha: ink.a * opacity);
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: extent,
          child: CustomPaint(
            painter: FrIconPainter(
              icon: icon,
              color: ink,
              strokeWidth: strokeWidth ?? strokeFor(extent),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinta un [FrIconData] escalando su rejilla al tamaño disponible.
class FrIconPainter extends CustomPainter {
  /// Crea el pintor de [icon].
  const FrIconPainter({
    required this.icon,
    required this.color,
    required this.strokeWidth,
  });

  /// Ícono.
  final FrIconData icon;

  /// Color de trazo y relleno.
  final Color color;

  /// Grosor del trazo en unidades de la rejilla.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = icon.geometry;
    canvas
      ..save()
      ..scale(size.width / FrIconData.grid, size.height / FrIconData.grid);
    if (geometry.hasFill) {
      canvas.drawPath(geometry.fill, Paint()..color = color);
    }
    canvas
      ..drawPath(
        geometry.stroke,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(FrIconPainter oldDelegate) =>
      oldDelegate.icon != icon ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
