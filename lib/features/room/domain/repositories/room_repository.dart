import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';

/// Contrato del repositorio para la gestión de salas (frecus).
abstract interface class RoomRepository {
  /// Crea una nueva frecu actuando como anfitrión en el puerto especificado.
  Future<Result<Room>> createRoom({
    required String name,
    required String accessCode,
    String? displayName,
    RoomNote? note,
  });

  /// Se une a una frecu existente dada la dirección del anfitrión y credenciales.
  Future<Result<Room>> joinRoom({
    required String hostAddress,
    required int port,
    required String accessCode,
    required String displayName,
  });

  /// Abandona la frecu activa de forma limpia.
  Future<Result<void>> leaveRoom();

  /// Stream reactivo de la lista de participantes de la frecu.
  Stream<List<Participant>> watchParticipants();

  /// Stream reactivo del estado de la frecu.
  Stream<RoomStatus> watchStatus();

  /// Id que el anfitrión asignó a este teléfono en la última bienvenida
  /// (cambia al reconectar), o `null` sin frecu activa.
  String? get localParticipantId;

  /// Obtiene la dirección IP local de la interfaz de red activa.
  Future<String?> getLocalIpAddress();
}
