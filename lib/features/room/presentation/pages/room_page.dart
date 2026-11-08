import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
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
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';

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

  /// Resumen del cierre; mientras no es nulo se ve la pantalla de cierre.
  RoomClosure? _closure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_startVoice()),
    );
  }

  /// Prepara el audio y aplica el modo de habla por defecto de Ajustes si es
  /// distinto del actual, sin abrir el micrófono.
  Future<void> _startVoice() async {
    final voice = ref.read(voiceNotifierProvider.notifier);
    await voice.initialize();
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
    if (!confirmed || !mounted) return;
    if (host) return _close(RoomClosureKind.hostClosed);
    await ref.read(roomNotifierProvider.notifier).leaveRoom();
    if (mounted) await context.router.maybePop();
  }

  /// Cierra las hojas abiertas, suelta la frecu y muestra la pantalla de
  /// cierre de [kind].
  Future<void> _close(RoomClosureKind kind) async {
    if (_closure != null || !mounted) return;
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
    await ref.read(roomNotifierProvider.notifier).leaveRoom();
  }

  /// Muestra el cierre si la frecu se cierra sin que esta persona salga.
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
        localTalking: voice.isTalking,
        status: status,
      ),
    );
    _peak = math.max(_peak, talk.count);
    return talk;
  }

  @override
  Widget build(BuildContext context) {
    _listenForClose();
    final fr = context.fr;
    final closure = _closure;
    return AnimatedSwitcher(
      duration: context.reduceMotion ? fr.motion.quick : fr.motion.smooth,
      child: closure == null
          ? KeyedSubtree(key: const ValueKey('room'), child: _room(context))
          : RoomClosedView(
              key: const ValueKey('closure'),
              closure: closure,
              onHome: () => unawaited(context.router.maybePop()),
            ),
    );
  }

  /// Frecu activa: isla, cabecera, malla y controles.
  Widget _room(BuildContext context) {
    final room = ref.watch(roomNotifierProvider);
    final participants =
        ref.watch(roomParticipantsProvider).value ?? const <Participant>[];
    final status = ref.watch(roomStatusProvider).value;
    final voiceState = ref.watch(voiceNotifierProvider);
    final localId = ref.watch(roomRepositoryProvider).localParticipantId;
    final talk = _talkOf(
      participants: participants,
      localId: localId,
      status: status,
      voice: voiceState,
    );
    final host = participants.any((p) => p.id == localId && p.isHost);
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

  /// Isla de estado; solo ella se reconstruye con el reloj al aire.
  Widget _island(RoomTalk talk) => Consumer(
    builder: (context, ref, _) =>
        RoomStatusIsland(talk: talk, onAirFor: ref.watch(onAirClockProvider)),
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
                localTalking: voice.isTalking,
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
          child: EchoNotice(
            visible:
                voice.talkMode == TalkMode.openMic &&
                voice.audioRoute == AudioRoute.speaker,
          ),
        ),
      ],
    );
  }
}
