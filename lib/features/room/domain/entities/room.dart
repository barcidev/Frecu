import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.freezed.dart';
part 'room.g.dart';

/// Representa una sala de voz activa (frecu).
@freezed
sealed class Room with _$Room {
  /// Constructor de la entidad inmutable.
  const factory Room({
    required String id,
    required String name,
    required String hostAddress,
    required int port,
    required String accessCode,
    required DateTime createdAt,
    @Default(6) int maxParticipants,
  }) = _Room;

  /// Deserializa desde JSON.
  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}
