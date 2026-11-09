import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
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
          reconnecting: (_, _) => TalkLink.reconnecting,
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

/// Evento pasajero de la isla (`App.event` del prototipo): alguien se unió
/// o salió, la salida de audio cambió o volvió la conexión. Dura
/// [duration] y manda sobre todo menos la reconexión.
@immutable
class RoomIslandEvent {
  /// [name] se unió; su firma va en [color], el de su lugar.
  const RoomIslandEvent.joined({required this.name, required Color this.color})
    : kind = RoomIslandEventKind.joined,
      icon = null,
      text = null;

  /// [name] salió.
  const RoomIslandEvent.left({required this.name})
    : kind = RoomIslandEventKind.left,
      color = null,
      icon = null,
      text = null;

  /// El audio sale ahora por [name], con el ícono de su ruta.
  const RoomIslandEvent.route({
    required this.name,
    required FrIconData this.icon,
  }) : kind = RoomIslandEventKind.route,
       color = null,
       text = null;

  /// El enlace de voz con [name] llega débil.
  const RoomIslandEvent.weak({required this.name})
    : kind = RoomIslandEventKind.weak,
      color = null,
      icon = null,
      text = null;

  /// [name] mandó el mensaje rápido [text]; su firma va en [color].
  const RoomIslandEvent.message({
    required this.name,
    required Color this.color,
    required String this.text,
  }) : kind = RoomIslandEventKind.message,
       icon = null;

  /// Se envió el mensaje rápido [text].
  const RoomIslandEvent.sent({required String this.text})
    : kind = RoomIslandEventKind.sent,
      name = '',
      color = null,
      icon = null;

  /// Se envió un SOS al grupo.
  const RoomIslandEvent.sosSent()
    : kind = RoomIslandEventKind.sosSent,
      name = '',
      color = null,
      icon = null,
      text = null;

  /// Volvió la conexión con el anfitrión.
  const RoomIslandEvent.recovered()
    : kind = RoomIslandEventKind.recovered,
      name = '',
      color = null,
      icon = null,
      text = null;

  /// Lo que dura el evento en la isla (2,6 s, como el prototipo).
  static const Duration duration = Duration(milliseconds: 2600);

  /// Qué pasó.
  final RoomIslandEventKind kind;

  /// Persona o ruta del evento.
  final String name;

  /// Color de la firma de quien se unió.
  final Color? color;

  /// Ícono de la ruta de audio.
  final FrIconData? icon;

  /// Texto del mensaje rápido.
  final String? text;

  /// Texto de la isla.
  String get label {
    final texts = t.room.talk.island;
    return switch (kind) {
      RoomIslandEventKind.joined => texts.joined(name: name),
      RoomIslandEventKind.left => texts.left(name: name),
      RoomIslandEventKind.route => texts.route(route: name),
      RoomIslandEventKind.recovered => texts.recovered,
      RoomIslandEventKind.weak => texts.weak(name: name),
      RoomIslandEventKind.message => t.messages.received(
        name: name,
        text: text ?? '',
      ),
      RoomIslandEventKind.sent => t.messages.sent(text: text ?? ''),
      RoomIslandEventKind.sosSent => t.messages.sosSent,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is RoomIslandEvent &&
      other.kind == kind &&
      other.name == name &&
      other.color == color &&
      other.icon == icon &&
      other.text == text;

  @override
  int get hashCode => Object.hash(kind, name, color, icon, text);
}

/// Tipo de [RoomIslandEvent].
enum RoomIslandEventKind {
  /// Alguien se unió.
  joined,

  /// Alguien salió.
  left,

  /// Cambió la salida de audio.
  route,

  /// Volvió la conexión.
  recovered,

  /// El enlace con alguien llega débil.
  weak,

  /// Llegó un mensaje rápido.
  message,

  /// Se envió un mensaje rápido.
  sent,

  /// Se envió un SOS.
  sosSent,
}

/// Isla de estado de la frecu activa (`isleFor` del prototipo): una
/// [StatusIsland] centrada en una franja de 44 px.
///
/// Como `isleSync` del prototipo, la reconexión (con la cuenta atrás
/// [retryIn]) manda sobre el [event] pasajero, y este sobre el resto.
class RoomStatusIsland extends StatelessWidget {
  /// Crea la isla de [talk].
  const RoomStatusIsland({
    required this.talk,
    this.onAirFor,
    this.event,
    this.retryIn,
    super.key,
  });

  /// Estado de habla de la frecu.
  final RoomTalk talk;

  /// Tiempo al aire, si se transmite en PTT.
  final Duration? onAirFor;

  /// Evento pasajero que mostrar, si hay uno.
  final RoomIslandEvent? event;

  /// Segundos para el próximo intento de reconexión.
  final int? retryIn;

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
    final phase = talk.islandPhase;
    if (phase == IslandPhase.reconnecting) {
      final seconds = retryIn;
      return StatusIsland.reconnecting(
        label: seconds != null && seconds > 0
            ? texts.reconnectingIn(seconds: '$seconds')
            : texts.reconnecting,
      );
    }
    final event = this.event;
    if (event != null) {
      // La señal débil es un aviso: va en ámbar, como reconectando.
      if (event.kind == RoomIslandEventKind.weak) {
        return StatusIsland(
          label: event.label,
          tone: StatusIslandTone.warn,
          leading: _eventLead(event),
        );
      }
      // El SOS enviado va en rojo, con el punto que parpadea.
      if (event.kind == RoomIslandEventKind.sosSent) {
        return StatusIsland(label: event.label, tone: StatusIslandTone.alert);
      }
      return StatusIsland.event(label: event.label, leading: _eventLead(event));
    }
    return switch (phase) {
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

  /// Lo que va antes del texto del evento; la isla es siempre de noche.
  static Widget? _eventLead(RoomIslandEvent event) {
    const c = FrColors.dark;
    return switch (event.kind) {
      RoomIslandEventKind.joined || RoomIslandEventKind.message =>
        SignalSignature(name: event.name, size: 24, color: event.color),
      RoomIslandEventKind.left => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: FrIcon(FrIcons.exit, size: 16, color: c.tx3),
      ),
      RoomIslandEventKind.route => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: FrIcon(event.icon ?? FrIcons.speaker, size: 16, color: c.signal),
      ),
      RoomIslandEventKind.recovered => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: FrIcon(FrIcons.check, size: 16, color: c.signal),
      ),
      RoomIslandEventKind.weak => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: FrIcon(FrIcons.signal, size: 16, color: c.warn),
      ),
      RoomIslandEventKind.sent => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: FrIcon(FrIcons.check, size: 16, color: c.signal),
      ),
      RoomIslandEventKind.sosSent => null,
    };
  }
}
