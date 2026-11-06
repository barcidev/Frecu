import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';

/// Parámetros para unirse a una frecu.
final class JoinRoomParams {
  /// Constructor.
  const JoinRoomParams({
    required this.hostAddress,
    required this.accessCode,
    required this.displayName,
    this.port = NetworkConstants.signalingPort,
  });

  /// Dirección IP o host del anfitrión.
  final String hostAddress;

  /// Puerto de señalización.
  final int port;

  /// Código de acceso (PIN).
  final String accessCode;

  /// Nombre del participante.
  final String displayName;
}

/// Caso de uso para unirse a una frecu existente.
final class JoinRoom implements UseCase<Room, JoinRoomParams> {
  /// Constructor con inyección del repositorio.
  const JoinRoom(this._repository);

  final RoomRepository _repository;

  @override
  String get name => 'JoinRoom';

  @override
  Future<Result<Room>> call(JoinRoomParams params) {
    return _repository.joinRoom(
      hostAddress: params.hostAddress,
      port: params.port,
      accessCode: params.accessCode,
      displayName: params.displayName,
    );
  }
}
