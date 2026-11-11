import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';

/// Parámetros para crear una frecu.
final class CreateRoomParams {
  /// Constructor.
  const CreateRoomParams({
    required this.name,
    required this.accessCode,
    this.displayName,
    this.note,
    this.reach = RoomReach.local,
  });

  /// Nombre de la frecu.
  final String name;

  /// Código de acceso (PIN).
  final String accessCode;

  /// Nombre del anfitrión mostrado a los participantes.
  final String? displayName;

  /// Nota musical de la frecu si está asignada.
  final RoomNote? note;

  /// Cómo se une el grupo: en la red local o por internet.
  final RoomReach reach;
}

/// Caso de uso para crear una nueva frecu como anfitrión.
final class CreateRoom implements UseCase<Room, CreateRoomParams> {
  /// Constructor con inyección del repositorio.
  const CreateRoom(this._repository);

  final RoomRepository _repository;

  @override
  String get name => 'CreateRoom';

  @override
  Future<Result<Room>> call(CreateRoomParams params) {
    return _repository.createRoom(
      name: params.name,
      accessCode: params.accessCode,
      displayName: params.displayName,
      note: params.note,
      reach: params.reach,
    );
  }
}
