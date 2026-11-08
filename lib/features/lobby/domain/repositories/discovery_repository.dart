import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Contrato del repositorio para el descubrimiento y anuncio local de salas.
abstract interface class DiscoveryRepository {
  /// Stream reactivo de las salas descubiertas activamente en la red local.
  Stream<List<NearbyRoom>> watchNearbyRooms();

  /// Anuncia la sala local mediante mDNS en la red con sus atributos y,
  /// si la tiene, su [note].
  Future<Result<void>> publishRoom({
    required String roomId,
    required String name,
    required int port,
    RoomNote? note,
  });

  /// Detiene el anuncio mDNS de la sala activa.
  Future<Result<void>> stopPublishing();

  /// Libera recursos y cierra los servicios de descubrimiento.
  Future<void> dispose();
}
