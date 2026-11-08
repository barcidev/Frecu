import 'dart:async';

import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/data/datasources/mdns_datasource.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Implementación concreta de [DiscoveryRepository] usando mDNS.
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  /// Constructor con inyección del datasource mDNS.
  DiscoveryRepositoryImpl({required MdnsDataSource mdnsDataSource})
    : _mdns = mdnsDataSource;

  final MdnsDataSource _mdns;

  /// Streams de [watchNearbyRooms] escuchados ahora: la búsqueda se detiene
  /// cuando no queda ninguno.
  int _watchers = 0;

  @override
  Stream<List<NearbyRoom>> watchNearbyRooms() {
    StreamSubscription<List<NearbyRoom>>? rooms;
    late final StreamController<List<NearbyRoom>> controller;
    controller = StreamController<List<NearbyRoom>>(
      onListen: () {
        _watchers++;
        rooms = _mdns.nearbyRooms.listen(controller.add);
        unawaited(_search(controller));
      },
      onCancel: () async {
        _watchers--;
        await rooms?.cancel();
        if (_watchers == 0) await _mdns.stopDiscovery();
      },
    );
    return controller.stream;
  }

  /// Empieza la búsqueda y, si arrancó, da las frecus que ya conoce; si no
  /// pudo, da el fallo para que el inicio lo muestre y reintente.
  Future<void> _search(StreamController<List<NearbyRoom>> controller) async {
    try {
      await _mdns.startDiscovery();
      if (!controller.isClosed) controller.add(_mdns.rooms);
    } on Object catch (e, st) {
      AppLogger.e('Error starting mDNS discovery', e, st);
      if (!controller.isClosed) {
        controller.addError(Failure.network(message: e.toString()), st);
      }
    }
  }

  @override
  Future<Result<void>> publishRoom({
    required String roomId,
    required String name,
    required int port,
    RoomNote? note,
  }) async {
    try {
      await _mdns.publish(roomId: roomId, name: name, port: port, note: note);
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error publishing room on mDNS', e, st);
      return Result.failure(Failure.network(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> stopPublishing() async {
    try {
      await _mdns.stopPublishing();
      return const Result.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error stopping room publication', e, st);
      return Result.failure(Failure.network(message: e.toString()));
    }
  }

  @override
  Future<void> dispose() => _mdns.dispose();
}
