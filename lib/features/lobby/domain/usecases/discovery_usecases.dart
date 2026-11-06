import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';

/// Caso de uso para observar salas cercanas descubiertas por mDNS.
class DiscoverRooms {
  /// Constructor con repositorio.
  const DiscoverRooms(this._repository);

  final DiscoveryRepository _repository;

  /// Retorna un stream reactivo con las salas detectadas.
  Stream<List<NearbyRoom>> call() => _repository.watchNearbyRooms();
}

/// Parámetros para publicar una sala local.
class PublishRoomParams {
  /// Constructor de parámetros.
  const PublishRoomParams({
    required this.roomId,
    required this.name,
    required this.port,
  });

  /// Identificador único de la sala.
  final String roomId;

  /// Nombre legible de la sala.
  final String name;

  /// Puerto del servicio WebSocket.
  final int port;
}

/// Caso de uso para publicar la sala en mDNS como anfitrión.
class PublishRoom extends UseCase<void, PublishRoomParams> {
  /// Constructor con repositorio.
  const PublishRoom(this._repository);

  final DiscoveryRepository _repository;

  @override
  Future<Result<void>> call(PublishRoomParams params) => _repository
      .publishRoom(roomId: params.roomId, name: params.name, port: params.port);
}

/// Caso de uso para detener el anuncio mDNS de la sala.
class StopPublishingRoom extends UseCase<void, NoParams> {
  /// Constructor con repositorio.
  const StopPublishingRoom(this._repository);

  final DiscoveryRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.stopPublishing();
}
