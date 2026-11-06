import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomNotifierProvider);
    final participantsAsync = ref.watch(roomParticipantsProvider);
    final statusAsync = ref.watch(roomStatusProvider);
    final voiceState = ref.watch(voiceNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(room?.name ?? t.room.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: t.room.leave,
            onPressed: _handleLeave,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RoomInfoCard(room: room, statusAsync: statusAsync),
            const SizedBox(height: 12),
            Text(
              t.room.participants,
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isSpeaking ? Colors.green.shade100 : null,
                child: Icon(
                  isSpeaking
                      ? Icons.volume_up
                      : (p.isHost ? Icons.star : Icons.person),
                  color: isSpeaking ? Colors.green.shade800 : null,
                  size: 18,
                ),
              ),
              title: Text(p.displayName),
              subtitle: isSpeaking
                  ? Text(
                      t.room.speaking,
                      style: const TextStyle(color: Colors.green),
                    )
                  : null,
              trailing: p.isHost ? Chip(label: Text(t.room.host)) : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
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
