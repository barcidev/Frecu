import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Encabezado con contador de participantes y límite de sala.
class ParticipantsHeader extends StatelessWidget {
  /// Constructor constante.
  const ParticipantsHeader({required this.count, super.key});

  /// Número actual de participantes.
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

/// Lista reactiva de participantes en la sala.
class ParticipantsList extends StatelessWidget {
  /// Constructor constante.
  const ParticipantsList({
    required this.participantsAsync,
    required this.speakingPeers,
    super.key,
  });

  /// Estado asíncrono con la lista de participantes.
  final AsyncValue<List<Participant>> participantsAsync;

  /// Identificadores de los pares remotos que están hablando activamente.
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
            return ParticipantTile(participant: p, isSpeaking: isSpeaking);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

/// Tarjeta individual para un participante en la lista.
class ParticipantTile extends StatelessWidget {
  /// Constructor constante.
  const ParticipantTile({
    required this.participant,
    required this.isSpeaking,
    super.key,
  });

  /// Datos del participante.
  final Participant participant;

  /// Indica si el participante está transmitiendo audio.
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
        leading: ParticipantAvatar(
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

/// Avatar circular con animación e indicador de habla activa.
class ParticipantAvatar extends StatelessWidget {
  /// Constructor constante.
  const ParticipantAvatar({
    required this.participantId,
    required this.isSpeaking,
    required this.isHost,
    super.key,
  });

  /// Identificador único del participante.
  final String participantId;

  /// Indica si el participante está hablando.
  final bool isSpeaking;

  /// Indica si el participante es el anfitrión.
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
