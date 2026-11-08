import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';

/// Una hoja de unión se cerró mientras conectaba: cerrarla es cancelar.
///
/// Si el anfitrión aceptó igual y esa sigue siendo la frecu activa, sale de
/// ella para no quedar conectado a una frecu que no se ve. [container] es el
/// de la hoja, tomado antes de esperar la respuesta.
void leaveCancelledJoin(ProviderContainer container, Result<Room> result) {
  if (result case Success(:final data)
      when container.read(roomNotifierProvider)?.id == data.id) {
    unawaited(container.read(roomNotifierProvider.notifier).leaveRoom());
  }
}
