import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
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

    /// Red de la frecu que creó el anfitrión; nula si la invitación no la
    /// trae (la red es la de siempre).
    WifiCredentials? wifi,

    /// Id de la frecu en el punto de encuentro, si se abrió por internet
    /// (`x`). Con él, [host] y [port] pueden venir vacíos: se entra por
    /// internet.
    String? internetId,
  }) = _RoomInvite;

  /// Deserializa desde JSON.
  factory RoomInvite.fromJson(Map<String, dynamic> json) =>
      _$RoomInviteFromJson(json);
}
