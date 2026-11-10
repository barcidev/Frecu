import 'dart:async';
import 'dart:ui' show Color, VoidCallback;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/location/presentation/location_labels.dart';
import 'package:frecu/features/location/presentation/providers/location_provider.dart';
import 'package:frecu/features/messages/presentation/providers/messages_provider.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/pages/room_state.dart';
import 'package:frecu/features/room/presentation/providers/reconnect_countdown_provider.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/features/room/presentation/widgets/room_notification_art.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

/// SOS sin atender que muestra la tarjeta: de quién ([id], [name]) y, si
/// las dos ubicaciones se comparten, hacia dónde ([where]).
@immutable
class RoomNotificationSos {
  /// Crea el SOS.
  const RoomNotificationSos({required this.id, required this.name, this.where});

  /// Id en la frecu de quien pide ayuda.
  final String id;

  /// Su nombre.
  final String name;

  /// «120 m hacia el noreste», si se sabe.
  final String? where;
}

/// Lo que va a mostrar la tarjeta de la frecu: el contenido sin la
/// carátula, que se dibuja aparte ([art]).
@immutable
class RoomNotificationScene {
  /// Crea la escena.
  const RoomNotificationScene({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.buttons,
    required this.art,
    this.note,
    this.tapInvites = false,
  });

  /// Título: la frecu o quién pide ayuda.
  final String title;

  /// Subtítulo: lo que dice la isla.
  final String subtitle;

  /// Color del estado.
  final Color accent;

  /// Botones, el del micrófono primero.
  final List<RoomNotificationButton> buttons;

  /// Carátula que dibujar.
  final RoomNotificationArt art;

  /// Nota de la frecu («Sol4»).
  final String? note;

  /// Tocar la tarjeta abre el QR.
  final bool tapInvites;

  /// El contenido para el servicio, con la carátula [png] ya dibujada.
  RoomNotificationContent content(Uint8List? png) => RoomNotificationContent(
    title: title,
    subtitle: subtitle,
    note: note,
    accent: accent.toARGB32(),
    art: png,
    buttons: buttons,
    tapInvites: tapInvites,
  );

  @override
  bool operator ==(Object other) =>
      other is RoomNotificationScene &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.accent == accent &&
      listEquals(other.buttons, buttons) &&
      other.art == art &&
      other.note == note &&
      other.tapInvites == tapInvites;

  @override
  int get hashCode => Object.hash(
    title,
    subtitle,
    accent,
    Object.hashAll(buttons),
    art,
    note,
    tapInvites,
  );
}

/// Arma la tarjeta de la frecu [roomName] como la isla de estado: el
/// subtítulo dice lo mismo que ella ([talk], [onAirFor], [retryIn] y el
/// [event] pasajero), la carátula muestra la malla ([nodes]) con el brillo
/// del estado y los botones son el micrófono, la salida de audio ([route])
/// y salir. Un [sos] sin atender manda sobre todo.
RoomNotificationScene roomNotificationScene({
  required String roomName,
  required RoomTalk talk,
  required List<MeshNode?> nodes,
  required AudioRoute route,
  RoomNote? note,
  bool host = false,
  String? bluetoothName,
  Duration? onAirFor,
  int? retryIn,
  RoomIslandEvent? event,
  RoomNotificationSos? sos,
}) {
  const c = FrColors.dark;
  final copy = t.room.notification;
  final island = t.room.talk.island;
  final count = '${talk.count}';
  const max = '$meshSlotCount';
  final speaker = talk.speaker;

  final (String subtitle, Color glow, double intensity) = switch (talk) {
    _ when sos != null => (
      copy.sos(where: sos.where ?? roomName),
      c.alert,
      .65,
    ),
    _ when talk.link == TalkLink.reconnecting => (
      retryIn != null && retryIn > 0
          ? island.reconnectingIn(seconds: '$retryIn')
          : island.reconnecting,
      c.warn,
      .4,
    ),
    _ when talk.link == TalkLink.connecting => (island.connecting, c.tx3, .25),
    _ when event != null => (event.label, _eventColor(event), .45),
    _ => switch (talk.islandPhase) {
      IslandPhase.onAir => (
        island.onAir(time: formatOnAir(onAirFor ?? Duration.zero)),
        c.signal,
        .75,
      ),
      IslandPhase.receiving when speaker != null => (
        island.receiving(name: speaker.name),
        meshGlowColor(c, speaker),
        .55,
      ),
      IslandPhase.openMic => (
        island.openMic(count: count, max: max),
        c.signal,
        .5,
      ),
      IslandPhase.muted => (island.muted(count: count, max: max), c.tx3, .3),
      IslandPhase.waiting => (island.waiting, c.signal, .38),
      _ => (island.online(count: count, max: max), c.signal, .38),
    },
  };

  // Como la cabecera: Sol4 en español, G4 en inglés.
  final label = note == null
      ? null
      : '${t.room.noteNames[note.pitchClass]}${note.octave}';
  return RoomNotificationScene(
    title: sos != null
        ? t.messages.sos.title(name: sos.name)
        : roomName.isEmpty
        ? copy.title
        : roomName,
    subtitle: subtitle,
    accent: glow,
    note: label,
    tapInvites: sos == null && talk.enabled && talk.alone,
    buttons: _buttons(
      talk: talk,
      route: route,
      host: host,
      bluetoothName: bluetoothName,
      sos: sos != null,
    ),
    art: RoomNotificationArt(
      nodes: [for (final node in nodes) _artNode(node, sosFrom: sos?.id)],
      glow: glow,
      background: c.bg1,
      intensity: intensity,
      note: label,
    ),
  );
}

Color _eventColor(RoomIslandEvent event) {
  const c = FrColors.dark;
  return event.color ??
      switch (event.kind) {
        RoomIslandEventKind.weak || RoomIslandEventKind.behind => c.warn,
        RoomIslandEventKind.sosSent => c.alert,
        _ => c.signal,
      };
}

RoomArtNode? _artNode(MeshNode? node, {String? sosFrom}) {
  if (node == null) return null;
  final state = switch (node) {
    _ when node.id == sosFrom => RoomArtNodeState.alert,
    _ when node.link != MeshLink.ok || node.weak => RoomArtNodeState.weak,
    _ when node.muted => RoomArtNodeState.muted,
    _ when node.onAir => RoomArtNodeState.hot,
    _ => RoomArtNodeState.idle,
  };
  return RoomArtNode(meshGlowColor(FrColors.dark, node), state);
}

List<RoomNotificationButton> _buttons({
  required RoomTalk talk,
  required AudioRoute route,
  required bool host,
  required bool sos,
  String? bluetoothName,
}) {
  final copy = t.room.notification;
  final leave = RoomNotificationButton(
    RoomNotificationAction.leave,
    RoomNotificationIcon.exit,
    host ? copy.close : copy.leave,
  );
  if (sos) {
    return [
      RoomNotificationButton(
        RoomNotificationAction.sosGo,
        RoomNotificationIcon.check,
        copy.sosGo,
      ),
      RoomNotificationButton(
        RoomNotificationAction.sosAck,
        RoomNotificationIcon.close,
        copy.sosAck,
      ),
      leave,
    ];
  }
  if (!talk.enabled) return [leave];
  final (micIcon, micLabel) = switch (talk.mode) {
    TalkMode.pushToTalk when talk.talking => (
      RoomNotificationIcon.stop,
      copy.cut,
    ),
    TalkMode.pushToTalk => (RoomNotificationIcon.mic, copy.talk),
    TalkMode.openMic when talk.talking => (RoomNotificationIcon.mic, copy.mute),
    TalkMode.openMic => (RoomNotificationIcon.micOff, copy.unmute),
  };
  return [
    RoomNotificationButton(RoomNotificationAction.mic, micIcon, micLabel),
    RoomNotificationButton(RoomNotificationAction.route, switch (route) {
      AudioRoute.speaker => RoomNotificationIcon.speaker,
      AudioRoute.earpiece => RoomNotificationIcon.earpiece,
      AudioRoute.bluetooth => RoomNotificationIcon.headset,
    }, copy.route(route: audioRouteName(route, deviceName: bluetoothName))),
    leave,
  ];
}

/// Dibuja la carátula de la tarjeta de la frecu; las pruebas lo reemplazan.
final roomArtPainterProvider =
    Provider<Future<Uint8List?> Function(RoomNotificationArt art)>(
      (ref) => paintRoomNotificationArt,
    );

/// Tarjeta de reproductor de la frecu activa (Android): la arma con el
/// estado de la frecu y la manda al servicio en primer plano, y atiende sus
/// botones.
///
/// Escucha los providers, no la pantalla: con la pantalla apagada Flutter no
/// dibuja, pero los providers siguen cambiando. Manda como mucho un cambio
/// cada [minGap] y dibuja cada carátula una sola vez.
class RoomNotification {
  /// Crea la tarjeta.
  RoomNotification({this.minGap = const Duration(seconds: 1)});

  /// Espera mínima entre dos cambios de la tarjeta.
  final Duration minGap;

  Future<Uint8List?> Function(RoomNotificationArt art) _paint =
      paintRoomNotificationArt;

  WidgetRef? _ref;
  ForegroundServiceDataSource? _service;
  VoidCallback? _onInvite;
  final List<ProviderSubscription<Object?>> _subscriptions = [];
  StreamSubscription<RoomNotificationAction>? _actions;

  Map<String, int> _slots = const {};
  RoomIslandEvent? _event;
  RoomTalk? _talk;
  RoomNotificationScene? _scene;
  RoomNotificationScene? _sent;

  /// Envío pendiente y espera tras el último envío.
  Timer? _timer;
  Timer? _cooldown;
  bool _running = false;
  final Map<RoomNotificationArt, Uint8List?> _arts = {};

  /// Empieza a seguir la frecu con [ref] (en el `initState`); [onInvite]
  /// abre el QR cuando el anfitrión solo toca la tarjeta.
  void start(WidgetRef ref, {required VoidCallback onInvite}) {
    final service = ref.read(foregroundServiceDataSourceProvider);
    if (!service.isAvailable) return;
    _ref = ref;
    _service = service;
    _paint = ref.read(roomArtPainterProvider);
    _onInvite = onInvite;
    _running = true;
    _actions = service.actions.listen(_onAction);
    void follow<T>(ProviderListenable<T> provider) =>
        _subscriptions.add(ref.listenManual<T>(provider, (_, _) => _refresh()));
    follow<Object?>(roomNotifierProvider);
    follow<Object?>(roomParticipantsProvider);
    follow<Object?>(roomStatusProvider);
    follow<Object?>(voiceNotifierProvider);
    follow<Object?>(onAirClockProvider);
    follow<Object?>(reconnectCountdownProvider);
    follow<Object?>(sosAlertsProvider);
    follow<Object?>(locationSharingProvider);
    _refresh();
  }

  /// Evento pasajero de la isla, que la tarjeta también dice; nulo cuando
  /// se acaba.
  void showEvent(RoomIslandEvent? value) {
    if (value == _event) return;
    _event = value;
    _refresh();
  }

  /// Deja de seguir la frecu (en el `dispose`).
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    _cooldown?.cancel();
    _cooldown = null;
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    _subscriptions.clear();
    unawaited(_actions?.cancel());
    _actions = null;
    _ref = null;
  }

  void _onAction(RoomNotificationAction action) {
    final ref = _ref;
    if (ref == null) return;
    switch (action) {
      case RoomNotificationAction.mic:
        // También el play/pausa de los audífonos: solo con la frecu lista.
        if (!(_talk?.enabled ?? false)) return;
        unawaited(ref.read(voiceNotifierProvider.notifier).toggleMicrophone());
      case RoomNotificationAction.route:
        unawaited(ref.read(voiceNotifierProvider.notifier).cycleAudioRoute());
      case RoomNotificationAction.sosGo || RoomNotificationAction.sosAck:
        final alerts = ref.read(sosAlertsProvider);
        if (alerts.isEmpty) return;
        unawaited(
          ref
              .read(sosAlertsProvider.notifier)
              .dismiss(
                alerts.first.senderId,
                onMyWay: action == RoomNotificationAction.sosGo,
              ),
        );
      case RoomNotificationAction.invite:
        _onInvite?.call();
      case RoomNotificationAction.leave:
        // Lo atiende la pantalla, que sabe salir y cerrar.
        break;
    }
  }

  void _refresh() {
    final ref = _ref;
    if (!_running || ref == null) return;
    final room = ref.read(roomNotifierProvider);
    if (room == null) return;
    final voice = ref.read(voiceNotifierProvider);
    final localId = ref.read(roomRepositoryProvider).localParticipantId;
    final participants = participantsWithVoice(
      ref.read(roomParticipantsProvider).value ?? const [],
      localId,
      voice,
    );
    final status = negotiatingStatus(
      ref.read(roomStatusProvider).value,
      participants,
      localId,
    );
    _slots = assignMeshSlots(
      previous: _slots,
      participants: participants,
      localId: localId,
    );
    final nodes = buildMeshNodes(
      participants: participants,
      slots: _slots,
      localId: localId,
      speakingPeers: voice.speakingPeers,
      localTalking: voice.selfSpeaking,
      status: status,
    );
    final talk = RoomTalk.from(
      status: status,
      mode: voice.talkMode,
      talking: voice.isTalking,
      nodes: nodes,
    );
    _talk = talk;
    _scene = roomNotificationScene(
      roomName: room.name,
      note: room.note,
      talk: talk,
      nodes: nodes,
      route: voice.audioRoute,
      bluetoothName: voice.bluetoothName,
      host: participants.any((p) => p.id == localId && p.isHost),
      onAirFor: ref.read(onAirClockProvider),
      retryIn: ref.read(reconnectCountdownProvider),
      event: _event,
      sos: _sos(ref, participants.map((p) => (p.id, p.displayName))),
    );
    _schedule();
  }

  RoomNotificationSos? _sos(WidgetRef ref, Iterable<(String, String)> people) {
    final alerts = ref.read(sosAlertsProvider);
    if (alerts.isEmpty) return null;
    final id = alerts.first.senderId;
    final towards = ref.read(locationSharingProvider).towards(id);
    return RoomNotificationSos(
      id: id,
      name: people.where((p) => p.$1 == id).map((p) => p.$2).firstOrNull ?? '',
      where: towards == null
          ? null
          : t.room.notification.towards(
              distance: distanceLabel(towards.meters),
              direction: compassLongLabel(towards.bearing),
            ),
    );
  }

  void _schedule() {
    if (_timer != null || _cooldown != null || _scene == _sent) return;
    _timer = Timer(Duration.zero, () => unawaited(_flush()));
  }

  Future<void> _flush() async {
    _timer = null;
    final scene = _scene;
    final service = _service;
    if (!_running || scene == null || service == null || scene == _sent) {
      return;
    }
    _sent = scene;
    // Lo que cambie mientras tanto sale al terminar la espera.
    _cooldown = Timer(minGap, () {
      _cooldown = null;
      _schedule();
    });
    final png = await _artFor(scene.art);
    if (!_running) return;
    await service.show(scene.content(png));
  }

  Future<Uint8List?> _artFor(RoomNotificationArt art) async {
    if (_arts.containsKey(art)) return _arts[art];
    Uint8List? png;
    try {
      png = await _paint(art);
    } on Object catch (e, st) {
      AppLogger.w('Could not paint the room artwork: $e', e, st);
    }
    // Pocas carátulas distintas: quien habla, el estado y poco más.
    if (_arts.length >= 12) _arts.remove(_arts.keys.first);
    _arts[art] = png;
    return png;
  }
}
