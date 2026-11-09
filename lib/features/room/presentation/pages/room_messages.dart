import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/core/haptics/haptics.dart';
import 'package:frecu/features/messages/domain/entities/quick_message.dart';
import 'package:frecu/features/messages/presentation/providers/messages_provider.dart';
import 'package:frecu/features/messages/presentation/widgets/quick_message_sheet.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/features/settings/presentation/providers/vibration_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Mensajes rápidos en la frecu activa: abrir la hoja y enviar el elegido, y
/// avisar en la isla (con vibración) de los que llegan. Los SOS que llegan
/// los muestra la capa de alarma de SOS.
class RoomMessages {
  /// Crea los mensajes; [showEvent] muestra un aviso en la isla y [colorOf]
  /// da el color de la firma de cada persona.
  RoomMessages({required this.showEvent, required this.colorOf});

  /// Muestra un aviso en la isla.
  final void Function(RoomIslandEvent event) showEvent;

  /// Color de la firma de cada participante en la malla.
  final Color Function(Participant participant) colorOf;

  /// Escucha los mensajes que llegan con [ref] (en el `build`).
  void listen(WidgetRef ref) {
    ref.listen<AsyncValue<QuickMessage>>(incomingQuickMessagesProvider, (
      _,
      next,
    ) {
      final message = next.value;
      if (message == null || message.kind == QuickMessageKind.sos) return;
      final people = ref.read(roomParticipantsProvider).value ?? const [];
      final sender = people.where((p) => p.id == message.senderId).firstOrNull;
      if (sender == null) return;
      showEvent(
        RoomIslandEvent.message(
          name: sender.displayName,
          color: colorOf(sender),
          text: quickMessageText(message.kind),
        ),
      );
      unawaited(ref.read(vibrationProvider)(HapticPattern.talk));
    });
  }

  /// Abre la hoja de mensajes y envía el que se elija.
  Future<void> open(BuildContext context, WidgetRef ref) async {
    final kind = await QuickMessageSheet.show(context);
    if (kind == null) return;
    final result = await ref.read(messagesRepositoryProvider).send(kind);
    if (!context.mounted) return;
    if (result.isFailure) {
      showFrToast(context, FrToast(message: t.messages.sendError));
      return;
    }
    showEvent(
      kind == QuickMessageKind.sos
          ? const RoomIslandEvent.sosSent()
          : RoomIslandEvent.sent(text: quickMessageText(kind)),
    );
    unawaited(ref.read(vibrationProvider)(HapticPattern.tick));
  }
}
