import 'dart:async';

import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/presentation/providers/local_hotspot_provider.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/domain/usecases/assign_room_note.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
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
  final dataSource = ForegroundServiceDataSource(texts: roomNotificationTexts);
  unawaited(dataSource.init());
  ref.onDispose(dataSource.dispose);
  return dataSource;
}

/// Toques en «Salir» de la notificación de la frecu (Android).
@riverpod
Stream<int> notificationLeaveRequests(Ref ref) =>
    ref.watch(foregroundServiceDataSourceProvider).leaveRequests;

/// Textos de la notificación de la frecu activa en el idioma actual; sin
/// nombre (anfitrión de una versión anterior) usa el título genérico.
ForegroundNotificationTexts roomNotificationTexts() {
  final copy = t.room.notification;
  String named(String roomName) => roomName.isEmpty ? t.room.title : roomName;
  return ForegroundNotificationTexts(
    channelName: copy.channelName,
    channelDescription: copy.channelDescription,
    title: copy.title,
    connected: (roomName) => copy.connected(room: named(roomName)),
    reconnecting: (roomName) => copy.reconnecting(room: named(roomName)),
    leave: copy.leave,
  );
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
    // Con la red de Frecu al aire, su IPv4 es la de la invitación.
    preferredLanInterface: () => ref.exists(localHotspotProvider)
        ? ref.read(localHotspotProvider.notifier).interfaceName
        : null,
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
  ///
  /// Con [wifi] (la red de la frecu que creó este teléfono), la invitación
  /// la lleva.
  Future<Result<Room>> createRoom({
    required String name,
    required String accessCode,
    String? displayName,
    Iterable<RoomNote> nearbyNotes = const [],
    RoomNote? note,
    WifiCredentials? wifi,
  }) async {
    final repository = ref.read(roomRepositoryProvider);
    final voice = _voiceListening();
    final result = await repository.createRoom(
      name: name,
      accessCode: accessCode,
      displayName: displayName ?? t.room.host,
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
          wifi: wifi,
          hosting: true,
        );
        state = room;
        _joinVoice(repository, voice);
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
  ///
  /// [wifi] es la red de la frecu que traía la invitación: quien está en la
  /// frecu la comparte al invitar. Antes de conectar, en Android la app se
  /// ata a la Wi-Fi en la que está el anfitrión: sin internet, no es la red
  /// por defecto si hay datos móviles.
  Future<Result<Room>> joinRoom({
    required String hostAddress,
    required int port,
    required String accessCode,
    required String displayName,
    RoomNote? note,
    WifiCredentials? wifi,
  }) async {
    final repository = ref.read(roomRepositoryProvider);
    final voice = _voiceListening();
    await ref.read(wifiJoinRepositoryProvider).route(hostAddress);
    final result = await repository.joinRoom(
      hostAddress: hostAddress,
      port: port,
      accessCode: accessCode,
      displayName: displayName,
    );
    switch (result) {
      case Success(:final data):
        final room = data.copyWith(note: data.note ?? note, wifi: wifi);
        state = room;
        _joinVoice(repository, voice);
        return Result.success(room);
      case FailureResult():
        return result;
    }
  }

  /// Abandona la frecu activa: primero suelta la voz (enlaces, micrófono y
  /// sesión de audio) y después la señalización.
  Future<Result<void>> leaveRoom() async {
    // Con la app cerrándose, los repositorios ya se sueltan solos.
    if (!ref.mounted) return const Result<void>.success(null);
    Result<void> result;
    try {
      final repository = ref.read(roomRepositoryProvider);
      final voice = ref.exists(voiceRepositoryProvider)
          ? ref.read(voiceRepositoryProvider)
          : null;
      if (voice != null) {
        try {
          // Dejar de transmitir y cerrar los enlaces pasa ya; soltar el
          // micrófono y la sesión de audio termina por su cuenta.
          unawaited(
            voice.leaveMesh().catchError((Object error, StackTrace stack) {
              AppLogger.w('Could not leave the voice mesh', error, stack);
            }),
          );
        } on Object catch (error, stackTrace) {
          AppLogger.w('Could not leave the voice mesh', error, stackTrace);
        }
      }
      result = await repository.leaveRoom();
    } on Object catch (error, stackTrace) {
      AppLogger.e('Error leaving room', error, stackTrace);
      result = Result.failure(Failure.unexpected(error: error));
    }
    if (ref.mounted) {
      state = null;
      _releaseNetwork();
    }
    return result;
  }

  /// La red de la frecu se volvió a crear: la invitación lleva la nueva red
  /// y, si cambió, la nueva IPv4 del anfitrión.
  void useNetwork(WifiCredentials wifi, {String? hostAddress}) {
    final room = state;
    if (room == null) return;
    state = room.copyWith(
      wifi: wifi,
      hostAddress: hostAddress ?? room.hostAddress,
    );
  }

  /// Sin frecu, el teléfono suelta la red de la frecu: el invitado vuelve a
  /// su Wi-Fi y el anfitrión apaga la que creó.
  void _releaseNetwork() {
    try {
      unawaited(ref.read(wifiJoinRepositoryProvider).release());
      if (ref.exists(localHotspotProvider)) {
        unawaited(ref.read(localHotspotProvider.notifier).stop());
      }
    } on Object catch (error, stackTrace) {
      AppLogger.w('Could not release the room network', error, stackTrace);
    }
  }

  /// Repositorio de voz, creado antes de crear o unirse para que escuche el
  /// `welcome` y las offers desde el principio.
  VoiceRepository? _voiceListening() {
    try {
      return ref.read(voiceRepositoryProvider);
    } on Object catch (error, stackTrace) {
      AppLogger.w('Voice is not available', error, stackTrace);
      return null;
    }
  }

  /// Une la voz a la malla con el id local y quienes ya estaban, aunque el
  /// `welcome` se haya consumido antes de que la voz existiera. Es
  /// idempotente: si la voz ya entró con ese id, no hace nada.
  void _joinVoice(RoomRepository rooms, VoiceRepository? voice) {
    final localId = rooms.localParticipantId;
    if (voice == null || localId == null) return;
    unawaited(_joinMesh(rooms, voice, localId));
  }

  Future<void> _joinMesh(
    RoomRepository rooms,
    VoiceRepository voice,
    String localId,
  ) async {
    try {
      final present = await rooms.watchParticipants().first;
      // Quien llega ofrece a los que ya estaban, que van antes en la lista.
      final earlier = [for (final participant in present) participant.id]
          .takeWhile((id) => id != localId)
          .toList();
      await voice.joinMesh(localPeerId: localId, peerIds: earlier);
    } on Object catch (error, stackTrace) {
      AppLogger.w('Could not join the voice mesh', error, stackTrace);
    }
  }
}
