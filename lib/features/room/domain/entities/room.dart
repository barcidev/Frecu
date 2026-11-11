import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
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

    /// Nota musical de la frecu, calculada con su hora de apertura.
    @RoomNoteConverter() RoomNote? note,

    /// Red de la frecu, si el anfitrión la creó con Frecu: la que creó este
    /// teléfono o la que traía la invitación. Va en el QR para invitar.
    WifiCredentials? wifi,

    /// Id de la frecu en el punto de encuentro, si es por internet. Va en el
    /// QR y en el enlace para invitar.
    String? internetId,

    /// Si este teléfono la creó (es el anfitrión). Solo vale en este
    /// teléfono: no viaja en JSON.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool hosting,
  }) = _Room;

  const Room._();

  /// Deserializa desde JSON.
  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  /// Cómo se une el grupo: por internet si tiene id en el punto de
  /// encuentro; si no, local.
  RoomReach get reach =>
      internetId == null ? RoomReach.local : RoomReach.internet;
}
