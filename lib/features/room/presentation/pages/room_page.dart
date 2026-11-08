import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/invite_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/mic_control_section.dart';
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
  bool _isDialogShowing = false;

  /// Lugar de cada participante en la malla, con la misma secuencia que
  /// [RoomMesh], para dar a la isla y al núcleo el color de quien habla.
  Map<String, int> _slots = const {};

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

  Future<void> _handleLeave() async {
    await ref.read(roomNotifierProvider.notifier).leaveRoom();
    if (mounted) {
      await context.router.maybePop();
    }
  }

  void _showRoomClosedDialog(BuildContext context, String reason) {
    if (_isDialogShowing || !mounted) return;
    _isDialogShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text(t.room.title),
        content: Text(t.room.roomClosed),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              _isDialogShowing = false;
              await _handleLeave();
            },
            child: Text(t.room.accept),
          ),
        ],
      ),
    );
  }

  void _listenForClose(BuildContext context) {
    ref.listen<AsyncValue<RoomStatus>>(roomStatusProvider, (previous, next) {
      next.value?.maybeWhen(
        closed: (reason) => _showRoomClosedDialog(context, reason),
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
    return RoomTalk.from(
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
  }

  @override
  Widget build(BuildContext context) {
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

    _listenForClose(context);

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
            onLeave: () => unawaited(_handleLeave()),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MicControlSection(
              voiceState: voiceState,
              talk: talk,
              onRoute: () => unawaited(AudioRouteSheet.show(context)),
            ),
          ),
        ],
      ),
    );
  }

  /// Isla de estado; solo ella se reconstruye con el reloj al aire.
  Widget _island(RoomTalk talk) => Consumer(
    builder: (context, ref, _) =>
        RoomStatusIsland(talk: talk, onAirFor: ref.watch(onAirClockProvider)),
  );

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
            child: RoomMesh(
              participants: participants,
              localParticipantId: localId,
              speakingPeers: voice.speakingPeers,
              localTalking: voice.isTalking,
              status: status,
              onInvite: onInvite,
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
