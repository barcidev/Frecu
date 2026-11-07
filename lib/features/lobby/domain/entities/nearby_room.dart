import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'nearby_room.freezed.dart';
part 'nearby_room.g.dart';

/// Representa una sala (frecu) descubierta en la red local mediante mDNS.
@freezed
sealed class NearbyRoom with _$NearbyRoom {
  /// Constructor constante para la entidad NearbyRoom.
  const factory NearbyRoom({
    required String roomId,
    required String name,
    required String hostAddress,
    required int port,
    @Default(1) int protocolVersion,

    /// Nota musical anunciada por el anfitrión; nula si no la publica.
    @RoomNoteConverter() RoomNote? note,
  }) = _NearbyRoom;

  /// Crea una instancia desde un mapa JSON.
  factory NearbyRoom.fromJson(Map<String, dynamic> json) =>
      _$NearbyRoomFromJson(json);
}
