import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
      builder: (ctx) => _InviteQrDialog(room: room),
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
            _RoomInfoCard(room: room, statusAsync: statusAsync),
            const SizedBox(height: 12),
            _ParticipantsHeader(count: participantsCount),
            const SizedBox(height: 8),
            Expanded(
              child: _ParticipantsList(
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

class _InviteQrDialog extends StatelessWidget {
  const _InviteQrDialog({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final invite = RoomInvite(
      host: room.hostAddress,
      port: room.port,
      roomId: room.id,
      accessCode: room.accessCode,
    );
    final qrData = const BuildInviteQr().buildUri(invite);

    return AlertDialog(
      title: const Text('Código QR de invitación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(data: qrData, size: 200),
            ),
            const SizedBox(height: 12),
            SelectableText(
              qrData,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text('PIN: ${room.accessCode}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _RoomInfoCard extends StatelessWidget {
  const _RoomInfoCard({required this.room, required this.statusAsync});

  final Room? room;
  final AsyncValue<RoomStatus> statusAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anfitrión IP: ${room?.hostAddress ?? "127.0.0.1"}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Código PIN: ${room?.accessCode ?? "1234"}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            statusAsync.when(
              data: (status) => Text(
                'Estado: ${status.runtimeType}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsHeader extends StatelessWidget {
  const _ParticipantsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${t.room.participants} ($count/${NetworkConstants.maxParticipants})',
          key: const Key('participants_header'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _ParticipantsList extends StatelessWidget {
  const _ParticipantsList({
    required this.participantsAsync,
    required this.speakingPeers,
  });

  final AsyncValue<List<Participant>> participantsAsync;
  final Set<String> speakingPeers;

  @override
  Widget build(BuildContext context) {
    return participantsAsync.when(
      data: (participants) {
        if (participants.isEmpty) {
          return const Center(child: Text('Sin participantes'));
        }
        return ListView.builder(
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final p = participants[index];
            final isSpeaking = p.isSpeaking || speakingPeers.contains(p.id);
            return _ParticipantTile(participant: p, isSpeaking: isSpeaking);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant, required this.isSpeaking});

  final Participant participant;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHost = participant.isHost;

    return Card(
      key: Key('participant_tile_${participant.id}'),
      elevation: isSpeaking ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSpeaking
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: _ParticipantAvatar(
          participantId: participant.id,
          isSpeaking: isSpeaking,
          isHost: isHost,
        ),
        title: Text(
          participant.displayName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSpeaking ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: isSpeaking
            ? Text(
                t.room.speaking,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        trailing: isHost
            ? Chip(
                avatar: const Icon(Icons.star, size: 14),
                label: Text(t.room.host),
                backgroundColor: theme.colorScheme.secondaryContainer,
              )
            : null,
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({
    required this.participantId,
    required this.isSpeaking,
    required this.isHost,
  });

  final String participantId;
  final bool isSpeaking;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      key: isSpeaking ? Key('speaking_indicator_$participantId') : null,
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSpeaking ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: isSpeaking
            ? theme.colorScheme.primaryContainer
            : (isHost
                  ? theme.colorScheme.secondaryContainer
                  : theme.colorScheme.surfaceContainerHighest),
        child: Icon(
          isSpeaking ? Icons.volume_up : (isHost ? Icons.star : Icons.person),
          color: isSpeaking
              ? theme.colorScheme.primary
              : (isHost
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant),
          size: 20,
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
