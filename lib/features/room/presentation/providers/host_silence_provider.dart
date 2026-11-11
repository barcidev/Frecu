import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/widgets/host_silence.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'host_silence_provider.g.dart';

/// Espera de la frecu activa si su anfitrión dejó de responder y la frecu
/// admite traspaso ([HostSilence.find]), o nula. La sucesión se lee al
/// cambiar el estado: es la que mandó el anfitrión antes de caerse.
@riverpod
HostSilence? hostSilence(Ref ref) {
  final repository = ref.watch(roomRepositoryProvider);
  final status = ref.watch(roomStatusProvider).value;
  final participants =
      ref.watch(roomParticipantsProvider).value ?? const <Participant>[];
  return HostSilence.find(
    status: status,
    succession: ref.watch(roomHandoverProvider)?.succession,
    participants: participants,
    localId: repository.localParticipantId,
  );
}

/// Segundos que lleva sin responder el anfitrión de la espera («Andrés no
/// responde · 3 s»), o nulo sin espera. Sube cada segundo desde 0 y vuelve
/// a empezar con otra espera.
@riverpod
class HostSilenceClock extends _$HostSilenceClock {
  @override
  int? build() {
    final host = ref.watch(hostSilenceProvider.select((s) => s?.hostId));
    if (host == null) return null;
    final timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => state = timer.tick,
    );
    ref.onDispose(timer.cancel);
    return 0;
  }
}
