import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';

/// Lienzo de la malla del prototipo (`.mesh` de 390 × 304).
const Size meshCanvas = Size(390, 304);

/// Radio del hexágono (`R` de `meshSlots`).
const double meshRadius = 104;

/// Lugares de la malla: una frecu admite hasta 6 personas.
const int meshSlotCount = 6;

/// Nivel fijo de quien habla con movimiento reducido.
const double meshReducedLevel = 0.6;

const List<double> _slotDegrees = [90, 150, 210, 270, 330, 30];

/// Orden en que se ocupan los lugares libres (`addPeer` del prototipo): el
/// primero en llegar va arriba, frente a la persona propia, y los demás se
/// reparten alrededor. El 0 queda para la persona propia y solo se usa si no
/// se sabe quién es.
const List<int> _freeOrder = [3, 1, 5, 2, 4, 0];

/// Centros de los 6 lugares en un lienzo de [size], como `meshSlots` del
/// prototipo: el 0 abajo, cerca del pulgar, y los demás cada 60°.
List<Offset> meshSlots(Size size) {
  final center = Offset(size.width / 2, size.height / 2 - 14);
  return [
    for (final degrees in _slotDegrees)
      center + Offset.fromDirection(degrees * math.pi / 180, meshRadius),
  ];
}

/// Lugar de cada participante: la persona propia ([localId]) en el 0, quien
/// ya estaba conserva el suyo de [previous] y quien llega toma el primer
/// lugar libre. Como máximo 6.
Map<String, int> assignMeshSlots({
  required Map<String, int> previous,
  required List<Participant> participants,
  required String? localId,
}) {
  final ids = [for (final participant in participants) participant.id];
  final slots = <String, int>{
    if (localId != null && ids.contains(localId)) localId: 0,
  };
  for (final id in ids) {
    final slot = previous[id];
    if (slot != null && !slots.containsKey(id) && !slots.containsValue(slot)) {
      slots[id] = slot;
    }
  }
  for (final id in ids.where((id) => !slots.containsKey(id))) {
    final free = _freeOrder.where((slot) => !slots.containsValue(slot));
    if (free.isEmpty) break;
    slots[id] = free.first;
  }
  return slots;
}

/// Estado del enlace de un nodo.
enum MeshLink {
  /// Conectado.
  ok,

  /// Enlazando: la frecu o el participante se está conectando.
  link,

  /// Reconectando.
  rec,

  /// Sin conexión.
  off,
}

/// Persona en un lugar de la malla.
@immutable
class MeshNode {
  /// Crea el nodo de [name] en el lugar [slot].
  const MeshNode({
    required this.id,
    required this.name,
    required this.slot,
    this.isMe = false,
    this.isHost = false,
    this.speaking = false,
    this.muted = false,
    this.link = MeshLink.ok,
  });

  /// Id del participante.
  final String id;

  /// Nombre visible, del que sale su firma.
  final String name;

  /// Lugar de la malla (0–5).
  final int slot;

  /// Es la persona de este teléfono.
  final bool isMe;

  /// Es el anfitrión.
  final bool isHost;

  /// Está hablando (o transmitiendo, si es la propia).
  final bool speaking;

  /// Tiene el micrófono silenciado.
  final bool muted;

  /// Estado de su enlace.
  final MeshLink link;

  /// Se le oye: habla, no está silenciado y su enlace está bien.
  bool get onAir => speaking && !muted && link == MeshLink.ok;

  @override
  bool operator ==(Object other) =>
      other is MeshNode &&
      other.id == id &&
      other.name == name &&
      other.slot == slot &&
      other.isMe == isMe &&
      other.isHost == isHost &&
      other.speaking == speaking &&
      other.muted == muted &&
      other.link == link;

  @override
  int get hashCode =>
      Object.hash(id, name, slot, isMe, isHost, speaking, muted, link);
}

/// Los 6 lugares de la malla (nulos los libres) con quién es quién, quién
/// habla y cómo está su enlace.
///
/// Con la frecu reconectando todos quedan en [MeshLink.rec] y conectando en
/// [MeshLink.link]; si no, cada uno sigue su `connectionState`. La persona
/// propia habla con [localTalking] y las demás con `isSpeaking` o
/// [speakingPeers].
List<MeshNode?> buildMeshNodes({
  required List<Participant> participants,
  required Map<String, int> slots,
  String? localId,
  Set<String> speakingPeers = const {},
  bool localTalking = false,
  RoomStatus? status,
}) {
  final nodes = List<MeshNode?>.filled(meshSlotCount, null);
  final roomLink = status?.maybeWhen(
    reconnecting: (_, _) => MeshLink.rec,
    connecting: () => MeshLink.link,
    orElse: () => null,
  );
  for (final participant in participants) {
    final slot = slots[participant.id];
    if (slot == null) continue;
    final isMe = participant.id == localId;
    nodes[slot] = MeshNode(
      id: participant.id,
      name: participant.displayName,
      slot: slot,
      isMe: isMe,
      isHost: participant.isHost,
      speaking: isMe
          ? localTalking
          : participant.isSpeaking || speakingPeers.contains(participant.id),
      muted: participant.isMuted,
      link: roomLink ?? _peerLink(participant.connectionState),
    );
  }
  return nodes;
}

MeshLink _peerLink(PeerConnectionState state) => switch (state) {
  PeerConnectionState.connected => MeshLink.ok,
  PeerConnectionState.connecting => MeshLink.link,
  PeerConnectionState.reconnecting => MeshLink.rec,
  PeerConnectionState.disconnected => MeshLink.off,
};

/// Leyenda bajo el nombre de un nodo.
enum MeshCaption {
  /// Sin leyenda.
  none,

  /// «Tú».
  you,

  /// «Tú · anfitrión».
  youHost,

  /// «Anfitrión».
  host,

  /// «Hablando».
  speaking,

  /// «Al aire»: la persona propia transmite.
  onAir,

  /// «Silenciado».
  muted,

  /// «Conectando».
  connecting,

  /// «Reconectando».
  reconnecting,
}

/// Leyenda de [node]: el enlace manda sobre el silencio, el silencio sobre
/// el habla y el habla sobre el papel.
MeshCaption meshCaption(MeshNode node) {
  if (node.link == MeshLink.link) return MeshCaption.connecting;
  if (node.link == MeshLink.rec) return MeshCaption.reconnecting;
  if (node.muted) return MeshCaption.muted;
  if (node.onAir) return node.isMe ? MeshCaption.onAir : MeshCaption.speaking;
  if (node.isMe) return node.isHost ? MeshCaption.youHost : MeshCaption.you;
  return node.isHost ? MeshCaption.host : MeshCaption.none;
}

/// Escala de un nodo [age] segundos después de llegar: el resorte del
/// prototipo durante 1,6 s.
double meshAppearScale(double age) {
  if (age >= 1.6) return 1;
  final a = math.max(0, age);
  return (1 - math.exp(-6 * a) * math.cos(11 * a)).clamp(0, 1.25).toDouble();
}

/// Opacidad de las aristas de un nodo [age] segundos después de llegar.
double meshEdgeAlpha(double age) => (age * 1.4).clamp(0, 1).toDouble();

/// Color de un nodo: la señal (como trazo, `signalFg`) para la persona
/// propia y `p1`…`p5` para las demás en el orden en que se ocupan los
/// lugares (el primero en llegar, arriba, es `p1`), como el prototipo.
Color meshNodeColor(FrColors colors, MeshNode node) {
  if (node.isMe) return colors.signalFg;
  return switch (node.slot) {
    3 => colors.p1,
    1 => colors.p2,
    5 => colors.p3,
    2 => colors.p4,
    4 => colors.p5,
    _ => colors.tx2,
  };
}

/// Color del brillo de un nodo: la señal siempre brilla en verde.
Color meshGlowColor(FrColors colors, MeshNode node) =>
    node.isMe ? colors.signal : meshNodeColor(colors, node);

/// Arista entre los lugares [from] y [to].
@immutable
class MeshEdge {
  /// Crea la arista; [weak] la dibuja punteada.
  const MeshEdge(this.from, this.to, {required this.weak});

  /// Lugar de origen.
  final int from;

  /// Lugar de destino.
  final int to;

  /// Alguno de sus nodos no está conectado.
  final bool weak;
}

/// Una arista entre cada par de nodos.
List<MeshEdge> meshEdges(List<MeshNode?> nodes) => [
  for (var i = 0; i < nodes.length; i++)
    for (var j = i + 1; j < nodes.length; j++)
      if (nodes[i] case final a?)
        if (nodes[j] case final b?)
          MeshEdge(i, j, weak: a.link != MeshLink.ok || b.link != MeshLink.ok),
];

/// Paquete de voz que viaja de [from] a [to].
@immutable
class MeshPacket {
  /// Crea un paquete que sale en el segundo [start].
  const MeshPacket({required this.from, required this.to, required this.start});

  /// Segundos que tarda en llegar.
  static const double lifetime = 0.75;

  /// Lugar de origen.
  final int from;

  /// Lugar de destino.
  final int to;

  /// Segundo de salida.
  final double start;

  /// Avance de 0 a 1 en el segundo [t] (`easeInOut`).
  double progress(double t) {
    final k = ((t - start) / lifetime).clamp(0, 1).toDouble();
    return k < 0.5
        ? 8 * k * k * k * k
        : 1 - math.pow(-2 * k + 2, 4).toDouble() / 2;
  }
}

/// Niveles de voz suavizados y paquetes de la malla (el estado de
/// `drawMesh`).
class MeshMotion {
  final List<double> _levels = List<double>.filled(meshSlotCount, 0);
  final List<double> _lastEmit = List<double>.filled(
    meshSlotCount,
    double.negativeInfinity,
  );
  final List<MeshPacket> _packets = [];
  double? _time;

  /// Nivel de voz de cada lugar, de 0 a 1.
  List<double> get levels => List.unmodifiable(_levels);

  /// Paquetes en viaje.
  List<MeshPacket> get packets => List.unmodifiable(_packets);

  /// Nivel de voz del lugar [slot].
  double levelOf(int slot) => _levels[slot];

  /// Avanza al segundo [t] con los [nodes] de ahora.
  ///
  /// Quien está al aire sigue la voz simulada de su lugar (fija en 0,6 con
  /// [reduced]); sube y baja suavizado, salvo con [reduced] o si su enlace no
  /// está bien. Cada nodo con nivel de 0,18 o más lanza paquetes hacia los
  /// demás nodos conectados; con [reduced] no hay paquetes.
  void advance(double t, List<MeshNode?> nodes, {bool reduced = false}) {
    final dt = _time == null ? 0.0 : math.max(0, t - _time!).toDouble();
    _time = t;
    for (var i = 0; i < meshSlotCount; i++) {
      _advanceLevel(i, _nodeAt(nodes, i), t, dt, reduced: reduced);
    }
    _packets.removeWhere(
      (packet) =>
          t - packet.start >= MeshPacket.lifetime ||
          !_isOnline(nodes, packet.from) ||
          !_isOnline(nodes, packet.to),
    );
    if (reduced) {
      _packets.clear();
      return;
    }
    for (var i = 0; i < meshSlotCount; i++) {
      _emit(i, nodes, t);
    }
  }

  void _advanceLevel(
    int slot,
    MeshNode? node,
    double t,
    double dt, {
    required bool reduced,
  }) {
    final onAir = node?.onAir ?? false;
    final target = !onAir
        ? 0.0
        : reduced
        ? meshReducedLevel
        : frVoice(t, slot + 1);
    if (reduced || node == null || node.link != MeshLink.ok) {
      _levels[slot] = target;
      return;
    }
    final rate = target > _levels[slot] ? 0.4 : 0.1;
    final k = 1 - math.pow(1 - rate, dt * 60);
    _levels[slot] += (target - _levels[slot]) * k;
  }

  void _emit(int slot, List<MeshNode?> nodes, double t) {
    final level = _levels[slot];
    if (!_isOnline(nodes, slot) || level < 0.18) return;
    if (t - _lastEmit[slot] <= 0.16 - level * 0.08) return;
    _lastEmit[slot] = t;
    for (var to = 0; to < meshSlotCount; to++) {
      if (to != slot && _isOnline(nodes, to)) {
        _packets.add(MeshPacket(from: slot, to: to, start: t));
      }
    }
  }

  static MeshNode? _nodeAt(List<MeshNode?> nodes, int slot) =>
      slot < nodes.length ? nodes[slot] : null;

  static bool _isOnline(List<MeshNode?> nodes, int slot) =>
      _nodeAt(nodes, slot)?.link == MeshLink.ok;
}

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
