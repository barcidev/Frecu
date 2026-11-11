import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_succession.freezed.dart';
part 'room_succession.g.dart';

/// Lo que cada participante sabe para heredar la frecu: si admite traspaso,
/// el turno vigente, el orden de sucesión y el estado de la frecu. Lo manda
/// el anfitrión al entrar cada uno y en cada cambio.
@Freezed(makeCollectionsUnmodifiable: false)
sealed class RoomSuccession with _$RoomSuccession {
  /// Constructor de la entidad inmutable.
  const factory RoomSuccession({
    /// Turno del anfitrión vigente: 1 al abrir la frecu; sube con cada
    /// traspaso y, entre dos anfitriones, gana el mayor.
    required int term,

    /// La frecu sobrevive a la salida del anfitrión.
    required bool handover,

    /// Nombre de la frecu.
    required String name,

    /// Código de acceso de la frecu.
    required String accessCode,

    /// Quienes están en la frecu, en orden de sucesión (de llegada): el
    /// anfitrión primero.
    required List<RoomMember> members,

    /// Nota musical de la frecu.
    @RoomNoteConverter() RoomNote? note,

    /// Cómo se une el grupo: local o por internet.
    @Default(RoomReach.local) RoomReach reach,

    /// Id de la frecu en el punto de encuentro, si es por internet.
    @JsonKey(includeIfNull: false) String? internetId,

    /// Secreto de anfitrión en el punto de encuentro, si es por internet:
    /// con él, el sucesor toma la frecu.
    @JsonKey(includeIfNull: false) String? hostSecret,
  }) = _RoomSuccession;

  const RoomSuccession._();

  /// Deserializa desde JSON.
  factory RoomSuccession.fromJson(Map<String, dynamic> json) =>
      _$RoomSuccessionFromJson(json);

  /// Ids de quienes están en la frecu, en orden de sucesión.
  List<String> get order => [for (final member in members) member.id];
}

/// Un participante en la sucesión de la frecu.
@freezed
sealed class RoomMember with _$RoomMember {
  /// Constructor de la entidad inmutable.
  const factory RoomMember({
    required String id,
    required String displayName,

    /// Cuándo llegó a la frecu.
    required DateTime joinedAt,

    /// Su IPv4 en la red local, si entró por ella; por internet, nula.
    @JsonKey(includeIfNull: false) String? address,
  }) = _RoomMember;

  /// Deserializa desde JSON.
  factory RoomMember.fromJson(Map<String, dynamic> json) =>
      _$RoomMemberFromJson(json);
}
