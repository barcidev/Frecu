import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_status.freezed.dart';

/// Estado del ciclo de vida de la sala.
@freezed
sealed class RoomStatus with _$RoomStatus {
  /// Estado inicial sin sala activa.
  const factory RoomStatus.idle() = _RoomStatusIdle;

  /// Conectándose a la sala / levantando servidor.
  const factory RoomStatus.connecting() = _RoomStatusConnecting;

  /// Conectado y operativo en la sala.
  const factory RoomStatus.connected() = _RoomStatusConnected;

  /// Reconectando tras pérdida temporal de señal: el intento [attempt]
  /// empieza dentro de [retryIn] (nulo si no se sabe).
  const factory RoomStatus.reconnecting({
    Duration? retryIn,
    @Default(0) int attempt,
  }) = _RoomStatusReconnecting;

  /// Sala cerrada por el anfitrión o desconexión definitiva.
  const factory RoomStatus.closed({required String reason}) = _RoomStatusClosed;
}
