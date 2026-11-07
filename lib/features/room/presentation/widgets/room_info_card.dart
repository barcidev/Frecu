import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/i18n/strings.g.dart';

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

  Widget _buildStatusWidget(BuildContext context, RoomStatus status) {
    final theme = Theme.of(context);
    return status.maybeWhen(
      reconnecting: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 14, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Text(
            t.room.reconnecting,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      connected: () =>
          Text('Estado: Conectado', style: theme.textTheme.bodySmall),
      closed: (reason) =>
          Text('Estado: Cerrada ($reason)', style: theme.textTheme.bodySmall),
      orElse: () =>
          Text('Estado: Conectando...', style: theme.textTheme.bodySmall),
    );
  }

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
              data: (status) => _buildStatusWidget(context, status),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
