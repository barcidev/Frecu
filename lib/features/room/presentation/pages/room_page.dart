import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/link_quality.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/pages/room_haptics.dart';
import 'package:frecu/features/room/presentation/providers/reconnect_countdown_provider.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/audio_route_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/invite_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/leave_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/mic_control_section.dart';
import 'package:frecu/features/room/presentation/widgets/room_closed_view.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla de la frecu activa (comunicador de voz).
@RoutePage()
class RoomPage extends ConsumerStatefulWidget {
  /// Constructor constante.
  const RoomPage({@pathParam required this.roomId, super.key});

  /// Identificador de la sala activa.
  final String roomId;

  @override
  ConsumerState<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends ConsumerState<RoomPage> {
  /// Lugar de cada participante en la malla, con la misma secuencia que
  /// [RoomMesh], para dar a la isla y al núcleo el color de quien habla.
  Map<String, int> _slots = const {};

  /// Mayor número de personas que hubo a la vez en la malla.
  int _peak = 0;

  /// Vibración con los cambios de la frecu.
  final RoomHaptics _haptics = RoomHaptics();

  /// Resumen del cierre; mientras no es nulo se ve la pantalla de cierre.
  RoomClosure? _closure;

  /// Gestor de la frecu, guardado para poder salir al desmontar la pantalla.
  late final RoomNotifier _rooms;

  /// Hay frecu activa (según el último build).
  bool _inRoom = false;

  /// Esta pantalla ya está saliendo de la frecu.
  bool _leaving = false;

  /// La persona propia es la anfitriona y cuántas más hay (último build).
  bool _host = false;
  int _others = 0;

  /// El micrófono no se pudo usar y el aviso no se cerró.
  bool _micUnavailable = false;

  /// Evento pasajero de la isla y su reloj.
  RoomIslandEvent? _event;
  Timer? _eventTimer;

  /// Ids que fueron de la persona propia (cambian al reconectar).
  final Set<String> _ownIds = {};

  @override
  void initState() {
    super.initState();
    _rooms = ref.read(roomNotifierProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_startVoice()),
    );
  }

  @override
  void dispose() {
    _eventTimer?.cancel();
    // Si la pantalla se va sin salir de la frecu, sale: nunca deja servidor,
    // anuncio, servicio ni micrófono vivos.
    if (_inRoom && !_leaving && _closure == null) {
      _leaving = true;
      // Después del desmontaje: salir cambia la frecu activa y avisa a
      // quienes la miran, y esta pantalla ya no puede reconstruirse.
      final rooms = _rooms;
      scheduleMicrotask(() => unawaited(rooms.leaveRoom()));
    }
    super.dispose();
  }

  /// Prepara el audio y aplica el modo de habla por defecto de Ajustes si es
  /// distinto del actual, sin abrir el micrófono. Si el micrófono no se
  /// puede usar, lo avisa con un acceso a los ajustes.
  Future<void> _startVoice() async {
    final voice = ref.read(voiceNotifierProvider.notifier);
    final audio = await voice.initialize();
    if (!mounted) return;
    if (audio.isFailure) setState(() => _micUnavailable = true);
    final preferences = await ref.read(preferencesProvider.future);
    if (!mounted) return;
    final mode = preferences.defaultTalkMode;
    if (ref.read(voiceNotifierProvider).talkMode == mode) return;
    // El modo por defecto nunca impide quedarse en la frecu.
    try {
      await voice.setTalkMode(mode);
    } on Object catch (error, stackTrace) {
      AppLogger.w('Could not apply the default talk mode', error, stackTrace);
    }
  }

  /// Confirma la salida con la hoja de salir: quien no es anfitrión vuelve
  /// al inicio y el anfitrión cierra la frecu y ve la pantalla de cierre.
  Future<void> _confirmLeave({required bool host, required int others}) async {
    final confirmed = await LeaveSheet.show(
      context,
      host: host,
      others: others,
    );
    if (!confirmed) return;
    await _leave(host: host);
  }

  /// Sale de la frecu como al confirmar la hoja de salir: el anfitrión la
  /// cierra para todos y ve el cierre; quien se unió vuelve al inicio.
  Future<void> _leave({required bool host}) async {
    if (!mounted || _leaving || _closure != null) return;
    if (host) return _close(RoomClosureKind.hostClosed);
    _leaving = true;
    await _rooms.leaveRoom();
    if (!mounted) return;
    // Ya fuera de la frecu: sale aunque la pantalla bloquee el Atrás.
    final router = context.router;
    if (router.canPop()) {
      router.pop();
    } else {
      unawaited(router.replaceAll([const LobbyRoute()]));
    }
  }

  /// Atrás (gesto de iOS o botón de Android) no saca de la frecu: abre la
  /// hoja de salir, que para el anfitrión cierra la frecu para todos.
  void _onBack(bool didPop, Object? result) {
    if (didPop || _leaving || _closure != null) return;
    unawaited(_confirmLeave(host: _host, others: _others));
  }

  /// Cierra las hojas abiertas, suelta la frecu y muestra la pantalla de
  /// cierre de [kind].
  Future<void> _close(RoomClosureKind kind) async {
    if (_closure != null || !mounted) return;
    _eventTimer?.cancel();
    _event = null;
    Navigator.of(context).popUntil((route) => route is! PopupRoute);
    final room = ref.read(roomNotifierProvider);
    final createdAt = room?.createdAt;
    setState(
      () => _closure = RoomClosure(
        kind: kind,
        duration: createdAt == null
            ? Duration.zero
            : DateTime.now().difference(createdAt),
        people: _peak,
        note: room?.note,
      ),
    );
    await _rooms.leaveRoom();
  }

  /// Muestra el cierre si la frecu se cierra sin que esta persona salga.
  /// «Salir» de la notificación (Android) sale sin pedir confirmación.
  void _listenForNotificationLeave() {
    ref.listen<AsyncValue<int>>(notificationLeaveRequestsProvider, (_, next) {
      if (next.hasValue) unawaited(_leave(host: _host));
    });
  }

  void _listenForClose() {
    ref.listen<AsyncValue<RoomStatus>>(roomStatusProvider, (previous, next) {
      next.value?.maybeWhen(
        closed: (reason) {
          if (reason == 'user_left') return;
          unawaited(
            _close(
              reason == 'host_unreachable'
                  ? RoomClosureKind.lostHost
                  : RoomClosureKind.closedByHost,
            ),
          );
        },
        orElse: () {},
      );
    });
  }

  /// Avisa en la isla quién entra y quién sale, por dónde sale el audio y
  /// cuándo vuelve la conexión (`App.event` del prototipo).
  void _listenForEvents() {
    ref
      ..listen<AsyncValue<List<Participant>>>(roomParticipantsProvider, (
        previous,
        next,
      ) {
        final before = previous?.value;
        final after = next.value;
        if (before == null || after == null || after.isEmpty) return;
        _onPeopleChanged(before, after);
      })
      ..listen<AudioRoute>(
        voiceNotifierProvider.select((voice) => voice.audioRoute),
        (previous, next) {
          if (previous == null || previous == next) return;
          final device = ref.read(voiceNotifierProvider).bluetoothName;
          _showEvent(
            RoomIslandEvent.route(
              name: audioRouteName(next, deviceName: device),
              icon: audioRouteIcon(next),
            ),
          );
        },
      )
      ..listen<Map<String, LinkQuality>>(
        voiceNotifierProvider.select((voice) => voice.peerQuality),
        (previous, next) => _onQualityChanged(previous ?? const {}, next),
      )
      ..listen<AsyncValue<RoomStatus>>(roomStatusProvider, (previous, next) {
        final wasReconnecting =
            previous?.value?.maybeWhen(
              reconnecting: (_, _) => true,
              orElse: () => false,
            ) ??
            false;
        final connected =
            next.value?.maybeWhen(connected: () => true, orElse: () => false) ??
            false;
        if (wasReconnecting && connected) {
          _showEvent(const RoomIslandEvent.recovered());
        }
      });
  }

  /// «X · señal débil» cuando el enlace con alguien pasa a débil; avisa una
  /// vez por cada caída, y nada mientras sigue débil.
  void _onQualityChanged(
    Map<String, LinkQuality> before,
    Map<String, LinkQuality> after,
  ) {
    final people = ref.read(roomParticipantsProvider).value ?? const [];
    for (final MapEntry(key: id, value: quality) in after.entries) {
      if (quality != LinkQuality.weak || before[id] == LinkQuality.weak) {
        continue;
      }
      final person = people.where((p) => p.id == id).firstOrNull;
      if (person == null) continue;
      _showEvent(RoomIslandEvent.weak(name: person.displayName));
      return;
    }
  }

  /// «X se unió» o «X salió»; los ids propios (que cambian al reconectar) no
  /// cuentan.
  void _onPeopleChanged(List<Participant> before, List<Participant> after) {
    final localId = ref.read(roomRepositoryProvider).localParticipantId;
    if (localId != null) _ownIds.add(localId);
    final beforeIds = {for (final p in before) p.id};
    final afterIds = {for (final p in after) p.id};
    final joined = [
      for (final p in after)
        if (!beforeIds.contains(p.id) && !_ownIds.contains(p.id)) p,
    ];
    final left = [
      for (final p in before)
        if (!afterIds.contains(p.id) && !_ownIds.contains(p.id)) p,
    ];
    if (joined.isNotEmpty) {
      final person = joined.last;
      final slots = assignMeshSlots(
        previous: _slots,
        participants: after,
        localId: localId,
      );
      final node = MeshNode(
        id: person.id,
        name: person.displayName,
        slot: slots[person.id] ?? 0,
      );
      _showEvent(
        RoomIslandEvent.joined(
          name: person.displayName,
          color: meshNodeColor(FrColors.dark, node),
        ),
      );
    } else if (left.isNotEmpty) {
      _showEvent(RoomIslandEvent.left(name: left.last.displayName));
    }
  }

  void _showEvent(RoomIslandEvent event) {
    if (!mounted || _closure != null) return;
    _eventTimer?.cancel();
    setState(() => _event = event);
    _eventTimer = Timer(RoomIslandEvent.duration, () {
      if (mounted) setState(() => _event = null);
    });
  }

  /// Participantes con lo que sabe la voz: quién se silenció en micrófono
  /// abierto (también la persona propia) y cómo va el enlace con cada uno.
  static List<Participant> _withVoice(
    List<Participant> participants,
    String? localId,
    VoiceState voice,
  ) {
    final selfMuted = voice.talkMode == TalkMode.openMic && !voice.isTalking;
    return [
      for (final participant in participants)
        if (participant.id == localId)
          participant.copyWith(isMuted: participant.isMuted || selfMuted)
        else
          participant.copyWith(
            isMuted:
                participant.isMuted ||
                voice.mutedPeers.contains(participant.id),
            connectionState:
                voice.peerLinks[participant.id] ?? participant.connectionState,
            linkQuality: voice.peerQuality[participant.id] ?? LinkQuality.good,
          ),
    ];
  }

  /// Mientras se negocian los enlaces de voz y ninguno está arriba, la frecu
  /// está conectando (3.0 del prototipo).
  static RoomStatus? _negotiating(
    RoomStatus? status,
    List<Participant> participants,
    String? localId,
  ) {
    final connected =
        status?.maybeWhen(connected: () => true, orElse: () => false) ?? false;
    if (!connected) return status;
    final others = participants.where((p) => p.id != localId).toList();
    final linking =
        others.isNotEmpty &&
        others.every(
          (p) => p.connectionState == PeerConnectionState.connecting,
        );
    return linking ? const RoomStatus.connecting() : status;
  }

  /// Estado de habla con los lugares de la malla al día.
  RoomTalk _talkOf({
    required List<Participant> participants,
    required String? localId,
    required RoomStatus? status,
    required VoiceState voice,
  }) {
    _slots = assignMeshSlots(
      previous: _slots,
      participants: participants,
      localId: localId,
    );
    final talk = RoomTalk.from(
      status: status,
      mode: voice.talkMode,
      talking: voice.isTalking,
      nodes: buildMeshNodes(
        participants: participants,
        slots: _slots,
        localId: localId,
        speakingPeers: voice.speakingPeers,
        localTalking: voice.selfSpeaking,
        status: status,
      ),
    );
    _peak = math.max(_peak, talk.count);
    return talk;
  }

  @override
  Widget build(BuildContext context) {
    _listenForClose();
    _listenForNotificationLeave();
    _listenForEvents();
    _haptics.listen(ref);
    final fr = context.fr;
    final closure = _closure;
    return PopScope<Object?>(
      canPop: closure != null || _leaving,
      onPopInvokedWithResult: _onBack,
      child: AnimatedSwitcher(
        duration: context.reduceMotion ? fr.motion.quick : fr.motion.smooth,
        child: closure == null
            ? KeyedSubtree(key: const ValueKey('room'), child: _room(context))
            : RoomClosedView(
                key: const ValueKey('closure'),
                closure: closure,
                onHome: () => unawaited(context.router.maybePop()),
              ),
      ),
    );
  }

  /// Frecu activa: isla, cabecera, malla y controles.
  Widget _room(BuildContext context) {
    final room = ref.watch(roomNotifierProvider);
    _inRoom = room != null;
    final voiceState = ref.watch(voiceNotifierProvider);
    final localId = ref.watch(roomRepositoryProvider).localParticipantId;
    if (localId != null) _ownIds.add(localId);
    final participants = _withVoice(
      ref.watch(roomParticipantsProvider).value ?? const <Participant>[],
      localId,
      voiceState,
    );
    final status = _negotiating(
      ref.watch(roomStatusProvider).value,
      participants,
      localId,
    );
    final talk = _talkOf(
      participants: participants,
      localId: localId,
      status: status,
      voice: voiceState,
    );
    final host = participants.any((p) => p.id == localId && p.isHost);
    _host = host;
    _others = talk.count - 1;
    final onInvite = room == null
        ? null
        : () => unawaited(InviteSheet.show(context, room));

    return FrScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _island(talk),
          RoomHeader(
            room: room,
            participants: participants,
            localParticipantId: localId,
            onInvite: onInvite,
            onLeave: () =>
                unawaited(_confirmLeave(host: host, others: talk.count - 1)),
          ),
          Expanded(
            child: _meshArea(
              participants,
              localId,
              status,
              voiceState,
              onInvite,
            ),
          ),
          _controls(voiceState, talk),
        ],
      ),
    );
  }

  /// Pastilla de ruta, selector de modo y núcleo PTT.
  Widget _controls(VoiceState voice, RoomTalk talk) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: MicControlSection(
      voiceState: voice,
      talk: talk,
      onRoute: () => unawaited(AudioRouteSheet.show(context)),
    ),
  );

  /// Isla de estado; solo ella se reconstruye con el reloj al aire y la
  /// cuenta atrás de la reconexión.
  Widget _island(RoomTalk talk) => Consumer(
    builder: (context, ref, _) => RoomStatusIsland(
      talk: talk,
      onAirFor: ref.watch(onAirClockProvider),
      event: _event,
      retryIn: ref.watch(reconnectCountdownProvider),
    ),
  );

  /// Nivel de voz de cada persona por id: el de los pares y, con [localId],
  /// el propio.
  static Map<String, double> _voiceLevels(WidgetRef ref, String? localId) => {
    ...?ref.watch(peerVoiceLevelsProvider).value,
    if (localId != null) localId: ref.watch(localVoiceLevelProvider).value ?? 0,
  };

  /// Malla de la frecu con quién habla y, encima, el aviso de eco
  /// (micrófono abierto con altavoz).
  Widget _meshArea(
    List<Participant> participants,
    String? localId,
    RoomStatus? status,
    VoiceState voice,
    VoidCallback? onInvite,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            // Solo la malla se reconstruye con los niveles de voz.
            child: Consumer(
              builder: (context, ref, _) => RoomMesh(
                participants: participants,
                localParticipantId: localId,
                speakingPeers: voice.speakingPeers,
                localTalking: voice.selfSpeaking,
                levels: _voiceLevels(ref, localId),
                status: status,
                onInvite: onInvite,
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          top: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (_micUnavailable) _micNotice(),
              EchoNotice(
                visible:
                    voice.talkMode == TalkMode.openMic &&
                    voice.audioRoute == AudioRoute.speaker,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Aviso de micrófono no disponible, con acceso a los ajustes.
  Widget _micNotice() {
    final copy = t.room.talk.mic;
    return FrBanner.drawn(
      key: const Key('mic_notice'),
      icon: FrIcons.micOff,
      tone: FrBannerTone.alert,
      title: copy.title,
      message: copy.message,
      actionLabel: copy.settings,
      onAction: () => unawaited(
        ref.read(voiceNotifierProvider.notifier).openMicrophoneSettings(),
      ),
      floating: true,
      dismissLabel: copy.dismiss,
      onDismiss: () => setState(() => _micUnavailable = false),
    );
  }
}
