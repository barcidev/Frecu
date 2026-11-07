import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/invite_qr_dialog.dart';
import 'package:frecu/features/room/presentation/widgets/mic_control_section.dart';
import 'package:frecu/features/room/presentation/widgets/participants_list.dart';
import 'package:frecu/features/room/presentation/widgets/room_info_card.dart';
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

  AppBar _buildAppBar(BuildContext context, Room? room, AudioRoute audioRoute) {
    final IconData routeIcon;
    final String tooltip;
    switch (audioRoute) {
      case AudioRoute.bluetooth:
        routeIcon = Icons.bluetooth_audio;
        tooltip = t.room.bluetooth;
      case AudioRoute.earpiece:
        routeIcon = Icons.phone_in_talk;
        tooltip = t.room.earpiece;
      case AudioRoute.speaker:
        routeIcon = Icons.volume_up;
        tooltip = t.room.speaker;
    }

    return AppBar(
      title: Text(room?.name ?? t.room.title),
      actions: [
        IconButton(
          key: const Key('audio_route_button'),
          icon: Icon(routeIcon),
          tooltip: tooltip,
          onPressed: () {
            unawaited(
              ref.read(voiceNotifierProvider.notifier).cycleAudioRoute(),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.qr_code),
          tooltip: 'Código QR de invitación',
          onPressed: room != null
              ? () => _showInviteQrDialog(context, room)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          tooltip: t.room.leave,
          onPressed: _handleLeave,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomNotifierProvider);
    final participantsAsync = ref.watch(roomParticipantsProvider);
    final statusAsync = ref.watch(roomStatusProvider);
    final voiceState = ref.watch(voiceNotifierProvider);
    final participantsCount = participantsAsync.value?.length ?? 0;

    ref.listen<AsyncValue<RoomStatus>>(roomStatusProvider, (previous, next) {
      final status = next.value;
      if (status != null) {
        status.maybeWhen(
          closed: (reason) {
            _showRoomClosedDialog(context, reason);
          },
          orElse: () {},
        );
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context, room, voiceState.audioRoute),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoomInfoCard(room: room, statusAsync: statusAsync),
            const SizedBox(height: 12),
            ParticipantsHeader(count: participantsCount),
            const SizedBox(height: 8),
            Expanded(
              child: ParticipantsList(
                participantsAsync: participantsAsync,
                speakingPeers: voiceState.speakingPeers,
              ),
            ),
            MicControlSection(voiceState: voiceState),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.call_end),
              label: Text(t.room.leave),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: _handleLeave,
            ),
          ],
        ),
      ),
    );
  }
}
