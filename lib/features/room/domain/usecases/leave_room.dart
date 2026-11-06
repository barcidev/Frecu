import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';

/// Caso de uso para abandonar la frecu activa.
final class LeaveRoom implements UseCase<void, NoParams> {
  /// Constructor con inyección del repositorio.
  const LeaveRoom(this._repository);

  final RoomRepository _repository;

  @override
  String get name => 'LeaveRoom';

  @override
  Future<Result<void>> call(NoParams params) {
    return _repository.leaveRoom();
  }
}
