import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Pantalla de la frecu activa (comunicador de voz).
@RoutePage()
class RoomPage extends ConsumerWidget {
  /// Constructor constante.
  const RoomPage({@pathParam required this.roomId, super.key});

  /// Identificador de la sala activa.
  final String roomId;

  Future<void> _handleLeave(BuildContext context, WidgetRef ref) async {
    await ref.read(roomNotifierProvider.notifier).leaveRoom();
    if (context.mounted) {
      await context.router.maybePop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomNotifierProvider);
    final participantsAsync = ref.watch(roomParticipantsProvider);
    final statusAsync = ref.watch(roomStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(room?.name ?? t.room.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: t.room.leave,
            onPressed: () => _handleLeave(context, ref),
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
              child: _ParticipantsList(participantsAsync: participantsAsync),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.call_end),
              label: Text(t.room.leave),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _handleLeave(context, ref),
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
  const _ParticipantsList({required this.participantsAsync});

  final AsyncValue<List<Participant>> participantsAsync;

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
            return ListTile(
              leading: CircleAvatar(
                child: Icon(p.isHost ? Icons.star : Icons.person, size: 18),
              ),
              title: Text(p.displayName),
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
