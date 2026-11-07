import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/invite_qr_dialog.dart';
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
            _MicControlSection(voiceState: voiceState),
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

class _MicControlSection extends ConsumerWidget {
  const _MicControlSection({required this.voiceState});

  final VoiceState voiceState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTalking = voiceState.isTalking;
    final theme = Theme.of(context);

    return Card(
      color: isTalking ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTalking ? t.room.speaking : t.room.muted,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isTalking ? theme.colorScheme.primary : null,
                  ),
                ),
                Text(
                  voiceState.talkMode == TalkMode.openMic
                      ? t.room.openMic
                      : t.room.pushToTalk,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            FilledButton.icon(
              key: const Key('mic_toggle_button'),
              icon: Icon(isTalking ? Icons.mic : Icons.mic_off),
              label: Text(isTalking ? t.room.muted : t.room.speaking),
              style: FilledButton.styleFrom(
                backgroundColor: isTalking
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              onPressed: () {
                ref.read(voiceNotifierProvider.notifier).toggleMicrophone();
              },
            ),
          ],
        ),
      ),
    );
  }
}
