import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/status_island.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Enlace de la frecu para hablar.
enum TalkLink {
  /// Conectada: se puede hablar.
  ready,

  /// Conectando con el anfitrión.
  connecting,

  /// Reconectando tras perder la señal.
  reconnecting,
}

/// Lo que muestra el núcleo PTT.
enum PttPhase {
  /// En reposo: mantén para hablar.
  idle,

  /// El anfitrión está solo en su frecu.
  alone,

  /// Otra persona habla.
  receiving,

  /// Transmitiendo con el dedo en el núcleo.
  onAir,

  /// Micrófono abierto transmitiendo.
  open,

  /// Micrófono abierto en silencio.
  muted,

  /// En espera: la frecu conecta.
  connecting,

  /// En espera: la frecu reconecta.
  reconnecting;

  /// Responde a la presión (mantener para hablar).
  bool get isPush =>
      this == idle || this == alone || this == receiving || this == onAir;

  /// Responde a un toque (micrófono abierto).
  bool get isToggle => this == open || this == muted;

  /// En espera: no responde.
  bool get isWaiting => this == connecting || this == reconnecting;
}

/// Lo que dice la isla de estado.
enum IslandPhase {
  /// En línea con n/6.
  online,

  /// Anfitrión solo: al aire, esperando al grupo.
  waiting,

  /// Otra persona habla.
  receiving,

  /// Al aire en PTT, con su tiempo.
  onAir,

  /// Micrófono abierto transmitiendo.
  openMic,

  /// Micrófono abierto en silencio.
  muted,

  /// Conectando.
  connecting,

  /// Reconectando.
  reconnecting,
}

/// Estado de habla de la frecu activa: de él salen el núcleo PTT y la isla.
@immutable
class RoomTalk {
  /// Crea el estado con sus partes ya calculadas.
  const RoomTalk({
    required this.link,
    required this.mode,
    required this.talking,
    this.speaker,
    this.count = 0,
    this.alone = false,
  });

  /// Arma el estado con el [status] de la frecu, el [mode] de habla, si la
  /// persona propia [talking] transmite y los [nodes] de la malla.
  factory RoomTalk.from({
    required RoomStatus? status,
    required TalkMode mode,
    required bool talking,
    required List<MeshNode?> nodes,
  }) {
    final present = nodes.nonNulls.toList();
    final link =
        status?.maybeWhen(
          reconnecting: () => TalkLink.reconnecting,
          connecting: () => TalkLink.connecting,
          orElse: () => null,
        ) ??
        TalkLink.ready;
    return RoomTalk(
      link: link,
      mode: mode,
      talking: talking,
      speaker: present.where((node) => !node.isMe && node.onAir).firstOrNull,
      count: present.length,
      alone: present.length == 1 && present.first.isMe && present.first.isHost,
    );
  }

  /// Enlace de la frecu.
  final TalkLink link;

  /// Modo de habla.
  final TalkMode mode;

  /// La persona propia transmite.
  final bool talking;

  /// Primera persona que habla, si alguien habla.
  final MeshNode? speaker;

  /// Personas en la malla.
  final int count;

  /// El anfitrión está solo en su frecu.
  final bool alone;

  /// Se puede hablar y cambiar de modo.
  bool get enabled => link == TalkLink.ready;

  /// Fase del núcleo; [pressed] si hay un dedo apoyado en él.
  PttPhase pttPhase({bool pressed = false}) {
    if (link == TalkLink.reconnecting) return PttPhase.reconnecting;
    if (link == TalkLink.connecting) return PttPhase.connecting;
    if (mode == TalkMode.openMic) {
      return talking ? PttPhase.open : PttPhase.muted;
    }
    if (talking || pressed) return PttPhase.onAir;
    if (speaker != null) return PttPhase.receiving;
    return alone ? PttPhase.alone : PttPhase.idle;
  }

  /// Fase de la isla.
  IslandPhase get islandPhase {
    if (link == TalkLink.reconnecting) return IslandPhase.reconnecting;
    if (link == TalkLink.connecting) return IslandPhase.connecting;
    final openMic = mode == TalkMode.openMic;
    if (talking && !openMic) return IslandPhase.onAir;
    if (speaker != null) return IslandPhase.receiving;
    if (openMic) return talking ? IslandPhase.openMic : IslandPhase.muted;
    return alone ? IslandPhase.waiting : IslandPhase.online;
  }
}

/// Tiempo al aire como «mm:ss».
String formatOnAir(Duration elapsed) {
  final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Isla de estado de la frecu activa (`isleFor` del prototipo): una
/// [StatusIsland] centrada en una franja de 44 px.
class RoomStatusIsland extends StatelessWidget {
  /// Crea la isla de [talk].
  const RoomStatusIsland({required this.talk, this.onAirFor, super.key});

  /// Estado de habla de la frecu.
  final RoomTalk talk;

  /// Tiempo al aire, si se transmite en PTT.
  final Duration? onAirFor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Align(alignment: Alignment.topCenter, child: _island()),
      ),
    );
  }

  Widget _island() {
    final texts = t.room.talk.island;
    final count = '${talk.count}';
    const max = '$meshSlotCount';
    final speaker = talk.speaker;
    return switch (talk.islandPhase) {
      IslandPhase.reconnecting => StatusIsland.reconnecting(
        label: texts.reconnecting,
      ),
      IslandPhase.connecting => StatusIsland.connecting(
        label: texts.connecting,
      ),
      IslandPhase.onAir => StatusIsland.onAir(
        label: texts.onAir(time: formatOnAir(onAirFor ?? Duration.zero)),
      ),
      IslandPhase.receiving when speaker != null => StatusIsland.receiving(
        name: speaker.name,
        color: meshNodeColor(FrColors.dark, speaker),
        label: texts.receiving(name: speaker.name),
      ),
      IslandPhase.openMic => StatusIsland.online(
        label: texts.openMic(count: count, max: max),
      ),
      IslandPhase.muted => StatusIsland.online(
        label: texts.muted(count: count, max: max),
      ),
      IslandPhase.waiting => StatusIsland.online(label: texts.waiting),
      _ => StatusIsland.online(
        label: texts.online(count: count, max: max),
      ),
    };
  }
}
