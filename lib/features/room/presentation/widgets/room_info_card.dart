import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';

/// Tarjeta de información técnica y estado de conexión de la sala activa.
class RoomInfoCard extends StatelessWidget {
  /// Constructor constante.
  const RoomInfoCard({
    required this.room,
    required this.statusAsync,
    super.key,
  });

  /// Sala activa con datos de red y anfitrión.
  final Room? room;

  /// Estado asíncrono de la conexión en la sala.
  final AsyncValue<RoomStatus> statusAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final host = room?.hostAddress ?? '127.0.0.1';
    final code = room?.accessCode ?? '1234';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anfitrión IP: $host', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('Código PIN: $code', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            statusAsync.when(
              data: (status) => Text(
                'Estado: ${status.runtimeType}',
                style: theme.textTheme.bodySmall,
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
