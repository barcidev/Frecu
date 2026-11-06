import 'dart:async';

import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'room_provider.g.dart';

/// Proveedor global singleton del repositorio de sala.
@Riverpod(keepAlive: true)
RoomRepository roomRepository(Ref ref) {
  final server = SignalingServerDataSource();
  final client = SignalingClientDataSource();
  final repository = RoomRepositoryImpl(
    serverDataSource: server,
    clientDataSource: client,
  );
  ref.onDispose(repository.dispose);
  return repository;
}

/// Stream de los participantes de la sala activa.
@riverpod
Stream<List<Participant>> roomParticipants(Ref ref) {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.watchParticipants();
}

/// Stream del estado de conexión de la sala.
@riverpod
Stream<RoomStatus> roomStatus(Ref ref) {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.watchStatus();
}

/// Dirección IP local del dispositivo.
@riverpod
Future<String?> localIp(Ref ref) {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getLocalIpAddress();
}

/// Alias para consistencia de nomenclatura con la clase Notifier.
RoomNotifierProvider get roomNotifierProvider => roomProvider;

/// Gestor del ciclo de vida y estado de la sala activa.
@Riverpod(keepAlive: true)
class RoomNotifier extends _$RoomNotifier {
  @override
  Room? build() => null;

  /// Crea una nueva frecu como anfitrión.
  Future<Result<Room>> createRoom({
    required String name,
    required String accessCode,
    String? displayName,
  }) async {
    final repository = ref.read(roomRepositoryProvider);
    final result = await repository.createRoom(
      name: name,
      accessCode: accessCode,
      displayName: displayName,
    );
    if (result.isSuccess) {
      state = result.dataOrNull;
    }
    return result;
  }

  /// Se une a una frecu remota por IP y código de acceso.
  Future<Result<Room>> joinRoom({
    required String hostAddress,
    required int port,
    required String accessCode,
    required String displayName,
  }) async {
    final repository = ref.read(roomRepositoryProvider);
    final result = await repository.joinRoom(
      hostAddress: hostAddress,
      port: port,
      accessCode: accessCode,
      displayName: displayName,
    );
    if (result.isSuccess) {
      state = result.dataOrNull;
    }
    return result;
  }

  /// Abandona la frecu activa.
  Future<Result<void>> leaveRoom() async {
    final repository = ref.read(roomRepositoryProvider);
    final result = await repository.leaveRoom();
    state = null;
    return result;
  }
}
