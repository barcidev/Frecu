import 'dart:async';

import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/usecases/assign_room_note.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'room_provider.g.dart';

/// Cliente de señalización WebSocket compartido.
@Riverpod(keepAlive: true)
SignalingClientDataSource signalingClient(Ref ref) {
  final client = SignalingClientDataSource();
  ref.onDispose(client.dispose);
  return client;
}

/// Datasource del servicio en primer plano para persistencia.
@Riverpod(keepAlive: true)
ForegroundServiceDataSource foregroundServiceDataSource(Ref ref) {
  final dataSource = ForegroundServiceDataSource();
  unawaited(dataSource.init());
  return dataSource;
}

/// Proveedor global singleton del repositorio de sala.
@Riverpod(keepAlive: true)
RoomRepository roomRepository(Ref ref) {
  final server = SignalingServerDataSource();
  final client = ref.watch(signalingClientProvider);
  final foregroundService = ref.watch(foregroundServiceDataSourceProvider);
  final repository = RoomRepositoryImpl(
    serverDataSource: server,
    clientDataSource: client,
    foregroundServiceDataSource: foregroundService,
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
  ///
  /// La frecu lleva la [note] que mostraba la nueva frecu, sin recalcularla,
  /// y el servidor la envía en `welcome` a quien se une. Sin [note], la
  /// calcula una sola vez con su hora de apertura y las [nearbyNotes] de las
  /// frecus cercanas.
  Future<Result<Room>> createRoom({
    required String name,
    required String accessCode,
    String? displayName,
    Iterable<RoomNote> nearbyNotes = const [],
    RoomNote? note,
  }) async {
    final repository = ref.read(roomRepositoryProvider);
    final result = await repository.createRoom(
      name: name,
      accessCode: accessCode,
      displayName: displayName,
      note: note,
    );
    switch (result) {
      case Success(:final data):
        final room = data.copyWith(
          note:
              note ??
              const AssignRoomNote().assign(
                createdAt: data.createdAt,
                nearbyNotes: nearbyNotes,
              ),
        );
        state = room;
        return Result.success(room);
      case FailureResult():
        return result;
    }
  }

  /// Se une a una frecu remota por IP y código de acceso.
  ///
  /// La frecu activa lleva la nota que el anfitrión envía en `welcome`, también
  /// al unirse por IP; si no la envía, la [note] que trajo la invitación (mDNS
  /// o QR), sin recalcularla, y sin ninguna de las dos queda sin nota.
  Future<Result<Room>> joinRoom({
    required String hostAddress,
    required int port,
    required String accessCode,
    required String displayName,
    RoomNote? note,
  }) async {
    final repository = ref.read(roomRepositoryProvider);
    final result = await repository.joinRoom(
      hostAddress: hostAddress,
      port: port,
      accessCode: accessCode,
      displayName: displayName,
    );
    switch (result) {
      case Success(:final data):
        final room = data.copyWith(note: data.note ?? note);
        state = room;
        return Result.success(room);
      case FailureResult():
        return result;
    }
  }

  /// Abandona la frecu activa.
  Future<Result<void>> leaveRoom() async {
    final repository = ref.read(roomRepositoryProvider);
    final result = await repository.leaveRoom();
    state = null;
    return result;
  }
}
