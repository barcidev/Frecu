import 'package:flutter/material.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Diálogo modal con código QR e información de acceso para invitar participantes.
class InviteQrDialog extends StatelessWidget {
  /// Constructor constante.
  const InviteQrDialog({required this.room, super.key});

  /// Sala para generar la invitación.
  final Room room;

  @override
  Widget build(BuildContext context) {
    final invite = RoomInvite(
      host: room.hostAddress,
      port: room.port,
      roomId: room.id,
      accessCode: room.accessCode,
      note: room.note,
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
