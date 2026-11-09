import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';

/// Invitación por Bluetooth: el anfitrión anuncia su frecu y quien está
/// cerca, aunque no esté en su red, la ve y pide la invitación con el
/// código (ver `BluetoothInviteProtocol`).
abstract interface class BluetoothInviteRepository {
  /// Anuncia la frecu de [invite] y la entrega a quien escriba su código. Si
  /// ya se anunciaba, pasa a servir esta. Falla sin Bluetooth o sin permiso.
  Future<Result<void>> advertise(RoomInvite invite);

  /// Deja de anunciar; no hace nada si no se anunciaba.
  Future<void> stopAdvertising();

  /// Frecus anunciadas cerca. Sin Bluetooth o sin permiso, ninguna (no
  /// falla). Buscar dura mientras haya quien escuche.
  Stream<List<NearbyRoom>> watchNearbyRooms();

  /// Pide a la frecu [room] (encontrada por Bluetooth) su invitación con
  /// [accessCode]. Falla con `Failure.invalidAccessCode` si el anfitrión no
  /// acepta el código y con `Failure.hostUnreachable` si no se pudo hablar
  /// con él.
  Future<Result<RoomInvite>> requestInvite(NearbyRoom room, String accessCode);
}
