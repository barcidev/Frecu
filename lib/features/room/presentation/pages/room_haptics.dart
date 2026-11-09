import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/haptics/haptics.dart';
import 'package:frecu/features/room/domain/entities/link_quality.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/settings/presentation/providers/vibration_provider.dart';

/// Lo que vibra en la frecu activa, para enterarse sin mirar el teléfono:
///
/// - un toque al empezar y al dejar de transmitir, y al volver la conexión;
/// - dos toques suaves cuando alguien empieza a hablar (como mucho uno cada
///   [talkGap], para no vibrar sin parar en micrófono abierto);
/// - dos toques firmes al perder la conexión o cuando un enlace llega débil.
///
/// Respeta la vibración de Ajustes. Se escucha desde el `build` de la
/// pantalla, que la guarda para recordar el último aviso.
class RoomHaptics {
  /// Tiempo mínimo entre dos avisos de «alguien habla».
  static const Duration talkGap = Duration(seconds: 3);

  DateTime? _lastTalk;

  /// Escucha los cambios de la frecu con [ref] (en el `build`).
  void listen(WidgetRef ref) {
    void play(HapticPattern pattern) =>
        unawaited(ref.read(vibrationProvider)(pattern));

    bool reconnecting() =>
        ref
            .read(roomStatusProvider)
            .value
            ?.maybeWhen(reconnecting: (_, _) => true, orElse: () => false) ??
        false;

    ref
      ..listen<bool>(voiceNotifierProvider.select((voice) => voice.isTalking), (
        previous,
        next,
      ) {
        // Al perder la conexión la voz deja de transmitir sola: ya vibra el
        // aviso de reconexión.
        if (previous == null || previous == next || reconnecting()) return;
        play(HapticPattern.tick);
      })
      ..listen<Set<String>>(
        voiceNotifierProvider.select((voice) => voice.speakingPeers),
        (previous, next) {
          final started = next.difference(previous ?? const {});
          if (started.isEmpty || ref.read(voiceNotifierProvider).isTalking) {
            return;
          }
          final now = DateTime.now();
          final last = _lastTalk;
          if (last != null && now.difference(last) < talkGap) return;
          _lastTalk = now;
          play(HapticPattern.talk);
        },
      )
      ..listen<Map<String, LinkQuality>>(
        voiceNotifierProvider.select((voice) => voice.peerQuality),
        (previous, next) {
          final before = previous ?? const {};
          final worse = next.entries.any(
            (e) => e.value == LinkQuality.weak && before[e.key] != e.value,
          );
          if (worse) play(HapticPattern.alert);
        },
      )
      ..listen<AsyncValue<RoomStatus>>(roomStatusProvider, (previous, next) {
        bool isReconnecting(RoomStatus? status) =>
            status?.maybeWhen(
              reconnecting: (_, _) => true,
              orElse: () => false,
            ) ??
            false;
        bool isConnected(RoomStatus? status) =>
            status?.maybeWhen(connected: () => true, orElse: () => false) ??
            false;
        final before = previous?.value;
        final after = next.value;
        if (isConnected(before) && isReconnecting(after)) {
          play(HapticPattern.alert);
        } else if (isReconnecting(before) && isConnected(after)) {
          play(HapticPattern.tick);
        }
      });
  }
}
