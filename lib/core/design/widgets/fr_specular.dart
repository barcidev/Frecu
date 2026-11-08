import 'package:flutter/widgets.dart';

/// Filo especular de Portadora («Filo especular» del prototipo, `inset 0 1px
/// 0 var(--spec)`): una línea de luz de 1 px en el canto superior interior de
/// [shape] que sigue sus esquinas, como el aluminio mecanizado.
///
/// Se pinta con `CustomPaint(painter: …)` entre la decoración y el contenido,
/// del tamaño de la caja. Con [depth] negativo pinta el canto inferior (el
/// `inset 0 -2px 0` del botón principal).
class FrSpecularPainter extends CustomPainter {
  /// Pinta el canto de [shape] en [color].
  const FrSpecularPainter({
    required this.shape,
    required this.color,
    this.depth = 1,
  });

  /// Forma de la caja: su contorno exterior guía la línea.
  final ShapeBorder shape;

  /// Color de la línea, normalmente `spec`.
  final Color color;

  /// Grosor en px: positivo, el canto superior; negativo, el inferior.
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0 || size.isEmpty || depth == 0) return;
    final outer = shape.getOuterPath(Offset.zero & size);
    final edge = Path.combine(
      PathOperation.difference,
      outer,
      outer.shift(Offset(0, depth)),
    );
    canvas.drawPath(edge, Paint()..color = color);
  }

  @override
  bool shouldRepaint(FrSpecularPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.color != color ||
      oldDelegate.depth != depth;
}
