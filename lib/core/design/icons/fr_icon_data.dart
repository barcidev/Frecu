import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:frecu/core/design/icons/svg_path_parser.dart';

/// Forma de un ícono de Portadora en la rejilla de 24, igual que el elemento
/// SVG del prototipo del que sale.
@immutable
sealed class FrIconShape {
  const FrIconShape();
}

/// Trazo `<path d="…">`.
final class FrIconPath extends FrIconShape {
  /// Crea un trazo con el atributo [d] de SVG.
  const FrIconPath(this.d);

  /// Atributo `d`, tal cual en el prototipo.
  final String d;

  @override
  bool operator ==(Object other) => other is FrIconPath && other.d == d;

  @override
  int get hashCode => Object.hash(FrIconPath, d);

  @override
  String toString() => "FrIconPath('$d')";
}

/// Rectángulo `<rect>` con esquinas redondeadas de radio [rx].
final class FrIconRect extends FrIconShape {
  /// Crea un rectángulo desde su esquina superior izquierda.
  const FrIconRect(this.x, this.y, this.width, this.height, {this.rx = 0});

  /// Borde izquierdo.
  final double x;

  /// Borde superior.
  final double y;

  /// Ancho.
  final double width;

  /// Alto.
  final double height;

  /// Radio de las esquinas.
  final double rx;

  @override
  bool operator ==(Object other) =>
      other is FrIconRect &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height &&
      other.rx == rx;

  @override
  int get hashCode => Object.hash(FrIconRect, x, y, width, height, rx);

  @override
  String toString() => 'FrIconRect($x, $y, $width, $height, rx: $rx)';
}

/// Círculo `<circle>`; con [filled] también se rellena
/// (`fill="currentColor"`).
final class FrIconCircle extends FrIconShape {
  /// Crea un círculo de centro ([cx], [cy]) y radio [r].
  const FrIconCircle(this.cx, this.cy, this.r, {this.filled = false});

  /// Centro, eje x.
  final double cx;

  /// Centro, eje y.
  final double cy;

  /// Radio.
  final double r;

  /// Se rellena además de trazarse.
  final bool filled;

  @override
  bool operator ==(Object other) =>
      other is FrIconCircle &&
      other.cx == cx &&
      other.cy == cy &&
      other.r == r &&
      other.filled == filled;

  @override
  int get hashCode => Object.hash(FrIconCircle, cx, cy, r, filled);

  @override
  String toString() => 'FrIconCircle($cx, $cy, $r, filled: $filled)';
}

/// Ícono de Portadora: formas SVG en una rejilla de [grid] × [grid] que
/// `FrIcon` traza en código.
@immutable
class FrIconData {
  /// Crea un ícono llamado [name] con sus [shapes].
  const FrIconData(this.name, this.shapes);

  /// Lado de la rejilla en la que están las formas.
  static const double grid = 24;

  /// Nombre, el mismo del prototipo.
  final String name;

  /// Formas, en el orden del SVG.
  final List<FrIconShape> shapes;

  /// Trazados en la rejilla, calculados la primera vez y reutilizados.
  FrIconGeometry get geometry =>
      _geometries[this] ??= FrIconGeometry.fromShapes(shapes);

  @override
  String toString() => 'FrIconData($name)';
}

final _geometries = Expando<FrIconGeometry>('FrIconData.geometry');

/// Trazados de un ícono en su rejilla.
@immutable
class FrIconGeometry {
  /// Agrupa los trazados de línea y de relleno.
  const FrIconGeometry({
    required this.stroke,
    required this.fill,
    required this.hasFill,
  });

  /// Traduce [shapes] a trazados.
  factory FrIconGeometry.fromShapes(List<FrIconShape> shapes) {
    final stroke = Path();
    final fill = Path();
    var hasFill = false;
    for (final shape in shapes) {
      final path = _pathOf(shape);
      stroke.addPath(path, Offset.zero);
      if (shape case FrIconCircle(filled: true)) {
        fill.addPath(path, Offset.zero);
        hasFill = true;
      }
    }
    return FrIconGeometry(stroke: stroke, fill: fill, hasFill: hasFill);
  }

  /// Todas las formas, para trazar su línea.
  final Path stroke;

  /// Solo las formas con relleno.
  final Path fill;

  /// Hay alguna forma con relleno.
  final bool hasFill;

  static Path _pathOf(FrIconShape shape) => switch (shape) {
    FrIconPath(:final d) => buildSvgPath(parseSvgPathData(d)),
    FrIconRect(:final x, :final y, :final width, :final height, :final rx) =>
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, width, height),
          Radius.circular(math.min(rx, math.min(width, height) / 2)),
        ),
      ),
    FrIconCircle(:final cx, :final cy, :final r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
  };
}
