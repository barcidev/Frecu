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
  }) = _RoomInvite;

  /// Deserializa desde JSON.
  factory RoomInvite.fromJson(Map<String, dynamic> json) =>
      _$RoomInviteFromJson(json);
}
