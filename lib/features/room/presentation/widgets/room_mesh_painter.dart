import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';

/// Pinta la malla como `drawMesh` del prototipo: aristas, paquetes de voz,
/// lugares libres, halos, relleno y anillo de cada nodo. Las firmas y las
/// etiquetas van encima, como widgets.
class RoomMeshPainter extends CustomPainter {
  /// Pinta [nodes] con el tiempo de [seconds] y avanza [motion] en cada
  /// cuadro.
  RoomMeshPainter({
    required this.nodes,
    required this.motion,
    required this.seconds,
    required this.bornAt,
    required this.colors,
    required this.reduced,
  }) : super(repaint: seconds);

  /// Los 6 lugares.
  final List<MeshNode?> nodes;

  /// Niveles y paquetes.
  final MeshMotion motion;

  /// Tiempo del bucle en segundos.
  final ValueListenable<double> seconds;

  /// Segundo en que llegó cada nodo, por id.
  final Map<String, double> bornAt;

  /// Colores del tema.
  final FrColors colors;

  /// Movimiento reducido: sin resorte ni fundidos.
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    motion.advance(t, nodes, reduced: reduced);
    final slots = meshSlots(size);
    _paintEdges(canvas, slots, t);
    _paintPackets(canvas, slots, t);
    for (var i = 0; i < meshSlotCount; i++) {
      final node = nodes[i];
      if (node == null) {
        _paintFreeSlot(canvas, slots[i]);
      } else {
        _paintNode(canvas, slots[i], node, t);
      }
    }
  }

  double _age(MeshNode node, double t) => t - (bornAt[node.id] ?? t);

  void _paintEdges(Canvas canvas, List<Offset> slots, double t) {
    for (final edge in meshEdges(nodes)) {
      final a = nodes[edge.from]!;
      final b = nodes[edge.to]!;
      final alpha = reduced
          ? 1.0
          : math.min(meshEdgeAlpha(_age(a, t)), meshEdgeAlpha(_age(b, t)));
      final la = motion.levelOf(edge.from);
      final lb = motion.levelOf(edge.to);
      final level = math.max(la, lb);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      if (level > 0.04) {
        final fromA = la >= lb;
        final color = meshNodeColor(colors, fromA ? a : b);
        final start = slots[fromA ? edge.from : edge.to];
        final end = slots[fromA ? edge.to : edge.from];
        paint
          ..strokeWidth = 1 + level
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: (0.2 + 0.5 * level) * alpha),
              color.withValues(alpha: 0.05 * alpha),
            ],
          ).createShader(Rect.fromPoints(start, end));
      } else {
        paint.color = edge.weak
            ? colors.warn.withValues(alpha: 0.22 * alpha)
            : colors.ink.withValues(alpha: 0.08 * alpha);
      }
      final line = Path()
        ..moveTo(slots[edge.from].dx, slots[edge.from].dy)
        ..lineTo(slots[edge.to].dx, slots[edge.to].dy);
      canvas.drawPath(edge.weak ? _dashed(line, 3, 5) : line, paint);
    }
  }

  void _paintPackets(Canvas canvas, List<Offset> slots, double t) {
    for (final packet in motion.packets) {
      final node = nodes[packet.from];
      if (node == null) continue;
      final k = packet.progress(t);
      final position = Offset.lerp(slots[packet.from], slots[packet.to], k)!;
      final alpha = 0.9 * math.sin(math.pi * k);
      canvas
        ..drawCircle(
          position,
          3,
          Paint()
            ..color = meshGlowColor(colors, node).withValues(alpha: alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        )
        ..drawCircle(
          position,
          1.8,
          Paint()..color = meshNodeColor(colors, node).withValues(alpha: alpha),
        );
    }
  }

  void _paintFreeSlot(Canvas canvas, Offset center) {
    final ring = Path()..addOval(Rect.fromCircle(center: center, radius: 22));
    canvas
      ..drawPath(
        _dashed(ring, 2, 4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = colors.ink.withValues(alpha: 0.16),
      )
      ..drawPath(
        Path()
          ..moveTo(center.dx - 5, center.dy)
          ..lineTo(center.dx + 5, center.dy)
          ..moveTo(center.dx, center.dy - 5)
          ..lineTo(center.dx, center.dy + 5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..color = colors.ink.withValues(alpha: 0.28),
      );
  }

  void _paintNode(Canvas canvas, Offset center, MeshNode node, double t) {
    final scale = reduced ? 1.0 : meshAppearScale(_age(node, t));
    if (scale < 0.04) return;
    final level = motion.levelOf(node.slot);
    final radius = (27 + level * 3) * scale;
    final color = meshNodeColor(colors, node);
    if (level > 0.04) {
      final glow = meshGlowColor(colors, node);
      canvas.drawCircle(
        center,
        radius * 2.2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              glow.withValues(alpha: 0.22 * level + 0.05),
              glow.withValues(alpha: 0.22 * level + 0.05),
              glow.withValues(alpha: 0),
            ],
            stops: const [0, 0.6 / 2.2, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2)),
      );
    }
    canvas.drawCircle(center, radius, Paint()..color = colors.bg1);
    final reconnecting = node.link == MeshLink.rec;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = level > 0.04 ? 1.5 : 1
      ..color = reconnecting
          ? colors.warn.withValues(alpha: 0.7)
          : level > 0.04
          ? color.withValues(alpha: 0.5 + 0.5 * level)
          : node.isMe
          ? color.withValues(alpha: 0.45)
          : colors.ink.withValues(alpha: 0.13);
    final circle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(
      reconnecting ? _dashed(circle, 4, 4, offset: t * 12) : circle,
      ring,
    );
  }

  /// Trazo punteado de [source] con tramos de [dash] y huecos de [gap],
  /// corrido [offset] a lo largo del trazo.
  static Path _dashed(
    Path source,
    double dash,
    double gap, {
    double offset = 0,
  }) {
    final dashed = Path();
    final period = dash + gap;
    for (final metric in source.computeMetrics()) {
      for (var d = -(offset % period); d < metric.length; d += period) {
        dashed.addPath(
          metric.extractPath(math.max(0, d), math.max(0, d + dash)),
          Offset.zero,
        );
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(RoomMeshPainter oldDelegate) =>
      !listEquals(oldDelegate.nodes, nodes) ||
      oldDelegate.motion != motion ||
      oldDelegate.seconds != seconds ||
      oldDelegate.colors != colors ||
      oldDelegate.reduced != reduced;
}
