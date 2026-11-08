import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_labels.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_painter.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Lado de la firma de cada nodo.
const double _signatureSize = 40;

/// Caja de cada nodo: la firma y la marca de anfitrión.
const double _nodeBox = 60;

/// Malla hexagonal de la frecu activa (`drawMesh` y `meshLabels` del
/// prototipo): la firma de cada persona en su lugar, quién habla, las aristas
/// con paquetes de voz y los lugares libres, que invitan.
class RoomMesh extends StatefulWidget {
  /// Crea la malla de [participants].
  const RoomMesh({
    required this.participants,
    this.localParticipantId,
    this.speakingPeers = const {},
    this.localTalking = false,
    this.levels = const {},
    this.status,
    this.onInvite,
    super.key,
  });

  /// Participantes de la frecu.
  final List<Participant> participants;

  /// Id de la persona de este teléfono, o `null` si aún no se sabe.
  final String? localParticipantId;

  /// Ids de quienes hablan.
  final Set<String> speakingPeers;

  /// La persona propia está transmitiendo.
  final bool localTalking;

  /// Nivel real de la voz de cada persona por id, la propia incluida, de 0
  /// a 1.
  final Map<String, double> levels;

  /// Estado de la frecu.
  final RoomStatus? status;

  /// Al tocar un lugar libre.
  final VoidCallback? onInvite;

  @override
  State<RoomMesh> createState() => _RoomMeshState();
}

class _RoomMeshState extends State<RoomMesh> {
  static const ValueListenable<double> _still = AlwaysStoppedAnimation<double>(
    0,
  );

  Map<String, int> _slots = const {};
  List<MeshNode?> _nodes = List<MeshNode?>.filled(meshSlotCount, null);
  final Map<String, double> _bornAt = {};
  MeshMotion _motion = MeshMotion();

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(RoomMesh oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    _slots = assignMeshSlots(
      previous: _slots,
      participants: widget.participants,
      localId: widget.localParticipantId,
    );
    _nodes = buildMeshNodes(
      participants: widget.participants,
      slots: _slots,
      localId: widget.localParticipantId,
      speakingPeers: widget.speakingPeers,
      localTalking: widget.localTalking,
      levels: widget.levels,
      status: widget.status,
    );
    _bornAt.removeWhere((id, _) => !_slots.containsKey(id));
    // Sin nodos, el bucle se desmonta y su tiempo vuelve a empezar.
    if (_slots.isEmpty) _motion = MeshMotion();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = context.reduceMotion;
    final scene = _slots.isEmpty
        ? _scene(context, _still, reduced: reduced)
        : FrLoop(
            builder: (context, seconds) =>
                _scene(context, seconds, reduced: reduced),
          );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox.fromSize(size: meshCanvas, child: scene),
    );
  }

  Widget _scene(
    BuildContext context,
    ValueListenable<double> seconds, {
    required bool reduced,
  }) {
    for (final node in _nodes.nonNulls) {
      _bornAt.putIfAbsent(node.id, () => seconds.value);
    }
    final colors = context.fr.colors;
    final slots = meshSlots(meshCanvas);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: RoomMeshPainter(
                nodes: _nodes,
                motion: _motion,
                seconds: seconds,
                bornAt: _bornAt,
                colors: colors,
                reduced: reduced,
              ),
            ),
          ),
        ),
        for (final node in _nodes.nonNulls)
          _nodeView(node, slots[node.slot], seconds, colors, reduced: reduced),
        for (var slot = 0; slot < meshSlotCount; slot++)
          ..._slotLabel(slot, slots[slot], colors),
      ],
    );
  }

  Widget _nodeView(
    MeshNode node,
    Offset center,
    ValueListenable<double> seconds,
    FrColors colors, {
    required bool reduced,
  }) {
    final color = meshNodeColor(colors, node);
    final body = Stack(
      children: [
        Center(
          child: SignalSignature(
            name: node.name,
            size: _signatureSize,
            radius: 17 / _signatureSize,
            color: node.link == MeshLink.rec
                ? color.withValues(alpha: 0.6)
                : color,
            mode: _signatureMode(node),
            levelOf: (_) => _motion.levelOf(node.slot),
          ),
        ),
        if (node.isHost)
          const Positioned(
            left: _nodeBox / 2 + 27 * 0.72 - 9,
            top: _nodeBox / 2 - 27 * 0.72 - 9,
            child: MeshHostMark(),
          ),
      ],
    );
    return Positioned(
      key: ValueKey('mesh_node_${node.id}'),
      left: center.dx - _nodeBox / 2,
      top: center.dy - _nodeBox / 2,
      width: _nodeBox,
      height: _nodeBox,
      child: reduced
          ? body
          : ValueListenableBuilder<double>(
              valueListenable: seconds,
              child: body,
              builder: (context, t, child) => Transform.scale(
                scale: meshAppearScale(t - (_bornAt[node.id] ?? t)),
                child: child,
              ),
            ),
    );
  }

  SignatureMode _signatureMode(MeshNode node) => switch (node.link) {
    MeshLink.link || MeshLink.rec => SignatureMode.link,
    MeshLink.off => SignatureMode.off,
    MeshLink.ok => node.muted ? SignatureMode.muted : SignatureMode.idle,
  };

  List<Widget> _slotLabel(int slot, Offset center, FrColors colors) {
    final node = _nodes[slot];
    if (node == null) return _freeSlot(slot, center, colors);
    final caption = meshCaption(node);
    final onAir =
        caption == MeshCaption.speaking || caption == MeshCaption.onAir;
    final color = meshNodeColor(colors, node);
    return [
      _positionedLabel(
        key: onAir
            ? Key('speaking_indicator_${node.id}')
            : ValueKey('mesh_label_${node.id}'),
        center: center,
        top: 33,
        child: MeshLabel(
          name: node.name,
          nameColor: onAir ? color : colors.tx1,
          nameWeight: FontWeight.w600,
          caption: _captionText(caption).toUpperCase(),
          captionColor: caption == MeshCaption.reconnecting
              ? colors.warn
              : onAir
              ? color
              : colors.tx3,
        ),
      ),
    ];
  }

  List<Widget> _freeSlot(int slot, Offset center, FrColors colors) => [
    _positionedLabel(
      key: ValueKey('mesh_free_label_$slot'),
      center: center,
      top: 30,
      // «LIBRE» en mayúsculas y espaciado de etiqueta (`.nl.free b`).
      child: MeshLabel(
        name: t.room.mesh.free.toUpperCase(),
        nameColor: colors.tx4,
        nameWeight: FontWeight.w500,
        nameSpacing: 1.25,
      ),
    ),
    Positioned(
      key: Key('mesh_free_slot_$slot'),
      left: center.dx - 32,
      top: center.dy - 32,
      width: 64,
      height: 64,
      child: Semantics(
        button: true,
        label: t.room.mesh.invite,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onInvite,
        ),
      ),
    ),
  ];

  Widget _positionedLabel({
    required Key key,
    required Offset center,
    required double top,
    required Widget child,
  }) => Positioned(
    key: key,
    left: center.dx - 56,
    top: center.dy + top,
    width: 112,
    child: IgnorePointer(child: child),
  );

  String _captionText(MeshCaption caption) => switch (caption) {
    MeshCaption.none => '',
    MeshCaption.you => t.room.mesh.you,
    MeshCaption.youHost => t.room.mesh.youHost,
    MeshCaption.host => t.room.host,
    MeshCaption.speaking => t.room.speaking,
    MeshCaption.onAir => t.room.mesh.onAir,
    MeshCaption.muted => t.room.muted,
    MeshCaption.connecting => t.room.mesh.connecting,
    MeshCaption.reconnecting => t.room.mesh.reconnecting,
  };
}
