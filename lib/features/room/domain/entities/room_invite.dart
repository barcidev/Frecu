import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_invite.freezed.dart';
part 'room_invite.g.dart';

/// Datos de conexión para invitar a una frecu mediante código QR o mDNS.
@freezed
sealed class RoomInvite with _$RoomInvite {
  /// Constructor inmutable de la invitación a la sala.
  const factory RoomInvite({
    required String host,
    required int port,
    required String roomId,
    required String accessCode,

    /// Nota musical de la frecu; nula si la invitación no la trae.
    @RoomNoteConverter() RoomNote? note,

    /// Nombre de la frecu; nulo si la invitación no lo trae (QR anteriores).
    String? name,
  }) = _RoomInvite;

  /// Deserializa desde JSON.
  factory RoomInvite.fromJson(Map<String, dynamic> json) =>
      _$RoomInviteFromJson(json);
}
