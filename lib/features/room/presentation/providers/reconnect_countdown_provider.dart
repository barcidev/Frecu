import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reconnect_countdown_provider.g.dart';

/// Segundos que faltan para el próximo intento de reconexión («Reconectando
/// · 4 s»), o nulo si la frecu no reconecta. Baja cada segundo hasta 0, que
/// es mientras se intenta.
@riverpod
class ReconnectCountdown extends _$ReconnectCountdown {
  @override
  int? build() {
    final retryIn = ref.watch(
      roomStatusProvider.select(
        (status) => status.value?.maybeWhen(
          reconnecting: (retryIn, attempt) => (retryIn, attempt),
          orElse: () => null,
        ),
      ),
    );
    final delay = retryIn?.$1;
    if (delay == null) return null;
    final seconds = (delay.inMilliseconds / 1000).ceil();
    if (seconds <= 0) return 0;
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = seconds - timer.tick;
      state = left > 0 ? left : 0;
      if (left <= 0) timer.cancel();
    });
    ref.onDispose(timer.cancel);
    return seconds;
  }
}
