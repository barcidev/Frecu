import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';

/// Cómo se ve un lugar de la malla en la carátula.
enum RoomArtNodeState {
  /// Presente, en reposo.
  idle,

  /// Hablando (o transmitiendo, si es la propia): se enciende.
  hot,

  /// Silenciado: atenuado y tachado.
  muted,

  /// Enlace caído o débil: en ámbar.
  weak,

  /// Pide ayuda (SOS): en rojo y encendido.
  alert,
}

/// Persona en un lugar de la carátula: su [color] de canal y su [state].
@immutable
class RoomArtNode {
  /// Crea el nodo.
  const RoomArtNode(this.color, this.state);

  /// Color de su canal.
  final Color color;

  /// Cómo está.
  final RoomArtNodeState state;

  @override
  bool operator ==(Object other) =>
      other is RoomArtNode && other.color == color && other.state == state;

  @override
  int get hashCode => Object.hash(color, state);
}

/// Carátula de la tarjeta de la frecu (como la de una canción): la malla de
/// 6 lugares, la firma de Frecu y la nota, sobre grafito con el brillo del
/// estado. Android tiñe la tarjeta con sus colores.
@immutable
class RoomNotificationArt {
  /// Crea la carátula.
  const RoomNotificationArt({
    required this.nodes,
    required this.glow,
    required this.background,
    this.intensity = 0.4,
    this.note,
  });

  /// Los 6 lugares, nulos los libres.
  final List<RoomArtNode?> nodes;

  /// Color del brillo y de la firma.
  final Color glow;

  /// Fondo.
  final Color background;

  /// Fuerza del brillo (0–1).
  final double intensity;

  /// Nota de la frecu («Sol4»).
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is RoomNotificationArt &&
      listEquals(other.nodes, nodes) &&
      other.glow == glow &&
      other.background == background &&
      other.intensity == intensity &&
      other.note == note;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(nodes), glow, background, intensity, note);
}

/// Colores de los avisos sobre grafito: ámbar y bengala (`FrColors.dark`).
const Color _warn = Color(0xFFFFB547);
const Color _alert = Color(0xFFFF5A4E);

/// Dibuja [art] en un PNG de [size] × [size] px.
///
/// Android recorta la carátula a lo ancho de la tarjeta (queda a la vista
/// menos de la mitad central, de alto), así que lo importante va en esa
/// franja: la malla un poco a la derecha (a la izquierda van el título y el
/// subtítulo) y la nota a su lado.
Future<Uint8List?> paintRoomNotificationArt(
  RoomNotificationArt art, {
  int size = 512,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  canvas.drawRect(Offset.zero & Size(s, s), Paint()..color = art.background);

  final center = Offset(s * 0.62, s * 0.46);
  final glow = art.glow;
  final k = art.intensity.clamp(0, 1).toDouble();
  canvas.drawCircle(
    center,
    s * 0.72,
    Paint()
      ..shader = ui.Gradient.radial(
        center,
        s * 0.72,
        [
          glow.withValues(alpha: 0.55 * k),
          glow.withValues(alpha: 0.14 * k),
          glow.withValues(alpha: 0),
        ],
        [0, 0.55, 1],
      ),
  );

  _paintBrand(canvas, center.translate(-s * 0.04, 0), s * 0.36, glow);
  _paintMesh(canvas, center, s * 0.145, s, art.nodes);

  final note = art.note;
  if (note != null && note.isNotEmpty) _paintNote(canvas, note, s, glow);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  picture.dispose();
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Firma de Frecu (Lissajous 2:3, fase 0,6), grande y tenue detrás.
void _paintBrand(Canvas canvas, Offset center, double radius, Color color) {
  const brand = SignatureParams.brand;
  const steps = 240;
  final path = Path();
  for (var i = 0; i <= steps; i++) {
    final u = i / steps * 2 * math.pi;
    final point = Offset(
      center.dx + math.sin(brand.a * u + brand.phase) * radius,
      center.dy + math.sin(brand.b * u) * radius * 0.96,
    );
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  canvas.drawPath(
    path..close(),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.018
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: 0.3),
  );
}

/// Malla de 6 lugares, en los mismos ángulos que la de la frecu.
void _paintMesh(
  Canvas canvas,
  Offset center,
  double radius,
  double s,
  List<RoomArtNode?> nodes,
) {
  const degrees = [90.0, 150.0, 210.0, 270.0, 330.0, 30.0];
  final points = [
    for (final d in degrees)
      center + Offset.fromDirection(d * math.pi / 180, radius),
  ];
  final present = [
    for (var i = 0; i < meshSlotCount; i++)
      if (i < nodes.length && nodes[i] != null) i,
  ];
  for (var a = 0; a < present.length; a++) {
    for (var b = a + 1; b < present.length; b++) {
      final i = present[a];
      final j = present[b];
      final weak =
          nodes[i]!.state == RoomArtNodeState.weak ||
          nodes[j]!.state == RoomArtNodeState.weak;
      canvas.drawLine(
        points[i],
        points[j],
        Paint()
          ..strokeWidth = s * 0.004
          ..color = weak
              ? _warn.withValues(alpha: 0.45)
              : const Color(0x33FFFFFF),
      );
    }
  }
  final nodeRadius = s * 0.032;
  for (var i = 0; i < meshSlotCount; i++) {
    final point = points[i];
    final node = i < nodes.length ? nodes[i] : null;
    if (node == null) {
      canvas.drawCircle(
        point,
        nodeRadius * 0.8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.003
          ..color = const Color(0x40FFFFFF),
      );
      continue;
    }
    final color = switch (node.state) {
      RoomArtNodeState.weak => _warn,
      RoomArtNodeState.alert => _alert,
      _ => node.color,
    };
    final lit =
        node.state == RoomArtNodeState.hot ||
        node.state == RoomArtNodeState.alert;
    if (lit) {
      canvas.drawCircle(
        point,
        nodeRadius * 2.2,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, nodeRadius),
      );
    }
    final alpha = node.state == RoomArtNodeState.muted ? 0.45 : 1.0;
    canvas
      ..drawCircle(
        point,
        lit ? nodeRadius * 1.15 : nodeRadius,
        Paint()..color = lit ? color : const Color(0xFF0C0E10),
      )
      ..drawCircle(
        point,
        lit ? nodeRadius * 1.15 : nodeRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.008
          ..color = color.withValues(alpha: alpha),
      );
    if (node.state == RoomArtNodeState.muted) {
      final d = nodeRadius * 0.8;
      canvas.drawLine(
        point.translate(-d, d),
        point.translate(d, -d),
        Paint()
          ..strokeWidth = s * 0.006
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: alpha),
      );
    }
  }
}

/// Nota de la frecu en Martian Mono, a la derecha de la malla.
void _paintNote(Canvas canvas, String note, double s, Color color) {
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.right,
            fontFamily: 'Martian Mono',
            fontSize: s * 0.056,
            fontWeight: FontWeight.w500,
          ),
        )
        ..pushStyle(
          ui.TextStyle(
            color: color.withValues(alpha: 0.85),
            letterSpacing: s * 0.008,
          ),
        )
        ..addText(note.toUpperCase());
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: s * 0.3));
  canvas.drawParagraph(paragraph, Offset(s * 0.94 - s * 0.3, s * 0.54));
}
