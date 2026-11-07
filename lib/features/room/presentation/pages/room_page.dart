import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/invite_qr_dialog.dart';
import 'package:frecu/features/room/presentation/widgets/mic_control_section.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceNotifierProvider.notifier).initialize();
    });
  }

  Future<void> _handleLeave() async {
    await ref.read(roomNotifierProvider.notifier).leaveRoom();
    if (mounted) {
      await context.router.maybePop();
    }
  }

  Future<void> _showInviteQrDialog(BuildContext context, Room room) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => InviteQrDialog(room: room),
    );
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

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomNotifierProvider);
    final participants =
        ref.watch(roomParticipantsProvider).value ?? const <Participant>[];
    final status = ref.watch(roomStatusProvider).value;
    final voiceState = ref.watch(voiceNotifierProvider);
    final localId = ref.watch(roomRepositoryProvider).localParticipantId;

    _listenForClose(context);

    final onInvite = room == null
        ? null
        : () => unawaited(_showInviteQrDialog(context, room));

    return FrScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoomHeader(
            room: room,
            participants: participants,
            localParticipantId: localId,
            audioRoute: voiceState.audioRoute,
            onCycleAudioRoute: () => unawaited(
              ref.read(voiceNotifierProvider.notifier).cycleAudioRoute(),
            ),
            onInvite: onInvite,
            onLeave: () => unawaited(_handleLeave()),
          ),
          Expanded(
            child: Center(
              child: RoomMesh(
                participants: participants,
                localParticipantId: localId,
                speakingPeers: voiceState.speakingPeers,
                localTalking: voiceState.isTalking,
                status: status,
                onInvite: onInvite,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: MicControlSection(voiceState: voiceState),
          ),
        ],
      ),
    );
  }
}
