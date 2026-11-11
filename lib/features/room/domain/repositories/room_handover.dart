import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_handover.freezed.dart';

/// Por qué cambió el anfitrión de la frecu.
enum HostChangeReason {
  /// El anfitrión anterior la pasó al salir.
  left,

  /// El anfitrión anterior se desconectó.
  lost,

  /// Este teléfono llevaba la frecu y otro la lleva con un turno que gana:
  /// entró como invitado.
  outranked,
}

/// Otra persona lleva ahora la frecu.
@freezed
sealed class HostChange with _$HostChange {
  /// Constructor de la entidad inmutable.
  const factory HostChange({
    /// Id de quien lleva ahora la frecu.
    required String hostId,

    /// Nombre de quien lleva ahora la frecu.
    required String hostName,

    /// La lleva este teléfono.
    required bool you,

    /// Por qué cambió.
    required HostChangeReason reason,

    /// IPv4 de quien la lleva, para la invitación.
    required String hostAddress,

    /// Puerto de su servidor.
    required int port,

    /// Nombre de quien la llevaba, si se conoce.
    String? previousHost,
  }) = _HostChange;
}

/// Traspaso de la frecu entre anfitriones. Lo implementa el repositorio de
/// la frecu aparte de `RoomRepository`, cuyo contrato no cambia.
abstract interface class RoomHandover {
  /// Sucesión, turno y estado de la frecu que mandó el anfitrión, o nula sin
  /// frecu o antes de que llegue.
  RoomSuccession? get succession;

  /// [succession] y sus cambios: empieza con la actual.
  Stream<RoomSuccession?> watchSuccession();

  /// Cada vez que otra persona (o este teléfono) toma la frecu.
  Stream<HostChange> watchHostChanges();

  /// El anfitrión pasa la frecu a [peerId] y sale de ella.
  Future<Result<void>> handOver(String peerId);
}
