import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';

/// Nombre de un lugar de la malla y, debajo, su leyenda en `labelS`.
class MeshLabel extends StatelessWidget {
  /// Crea la etiqueta de [name] con su [caption], si la tiene.
  const MeshLabel({
    required this.name,
    required this.nameColor,
    required this.nameWeight,
    this.caption,
    this.captionColor,
    super.key,
  });

  /// Nombre de la persona o «Libre».
  final String name;

  /// Color del nombre.
  final Color nameColor;

  /// Peso del nombre.
  final FontWeight nameWeight;

  /// Leyenda bajo el nombre, ya en mayúsculas.
  final String? caption;

  /// Color de la leyenda.
  final Color? captionColor;

  @override
  Widget build(BuildContext context) {
    final type = context.fr.type;
    final caption = this.caption;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: type.bodyS.copyWith(
            fontSize: 12.5,
            height: 1.15,
            fontWeight: nameWeight,
            fontVariations: [
              FontVariation.weight(nameWeight.value.toDouble()),
              const FontVariation.width(104),
            ],
            color: nameColor,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 3),
          SizedBox(
            height: 12,
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: type.labelS.copyWith(color: captionColor),
            ),
          ),
        ],
      ],
    );
  }
}

/// Marca de antena del anfitrión: un círculo de 8 en `bg0` con borde `tx2`.
class MeshHostMark extends StatelessWidget {
  /// Crea la marca.
  const MeshHostMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: CustomPaint(painter: _HostMarkPainter(context.fr.colors)),
    );
  }
}

class _HostMarkPainter extends CustomPainter {
  _HostMarkPainter(this.colors);

  final FrColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = colors.tx2.withValues(alpha: 0.9);
    final top = center.translate(0, -1.5);
    canvas
      ..drawCircle(center, 8, Paint()..color = colors.bg0)
      ..drawCircle(center, 8, stroke)
      ..drawLine(center.translate(0, 3.5), top, stroke)
      ..drawArc(
        Rect.fromCircle(center: top, radius: 3),
        math.pi * 1.15,
        math.pi * 0.7,
        false,
        stroke,
      );
  }

  @override
  bool shouldRepaint(_HostMarkPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
