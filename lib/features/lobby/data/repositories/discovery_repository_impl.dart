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

  @override
  Stream<List<NearbyRoom>> watchNearbyRooms() {
    _mdns.startDiscovery().ignore();
    return _mdns.nearbyRooms;
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
