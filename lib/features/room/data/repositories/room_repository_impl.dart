import 'dart:async';
import 'dart:io';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';

/// Implementación concreta de [RoomRepository].
class RoomRepositoryImpl implements RoomRepository {
  /// Constructor con inyección de datasources.
  RoomRepositoryImpl({
    required SignalingServerDataSource serverDataSource,
    required SignalingClientDataSource clientDataSource,
    Future<List<NetworkInterface>> Function()? networkInterfacesProvider,
  }) : _server = serverDataSource,
       _client = clientDataSource,
       _networkInterfacesProvider =
           networkInterfacesProvider ?? NetworkInterface.list;

  final SignalingServerDataSource _server;
  final SignalingClientDataSource _client;
  final Future<List<NetworkInterface>> Function() _networkInterfacesProvider;

  final StreamController<List<Participant>> _participantsController =
      StreamController<List<Participant>>.broadcast();
  final StreamController<RoomStatus> _statusController =
      StreamController<RoomStatus>.broadcast();

  StreamSubscription<SignalingMessage>? _clientSubscription;
  List<Participant> _participants = [];
  bool _isHost = false;

  @override
  Stream<List<Participant>> watchParticipants() =>
      _participantsController.stream;

  @override
  Stream<RoomStatus> watchStatus() => _statusController.stream;

  @override
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await _networkInterfacesProvider();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
      return '192.168.43.1';
    } on Object catch (e) {
      AppLogger.w('Failed to get local IP: $e');
      return '192.168.43.1';
    }
  }

  @override
  Future<Result<Room>> createRoom({
    required String name,
    required String accessCode,
    String? displayName,
  }) async {
    try {
      final hostIp = await getLocalIpAddress() ?? '127.0.0.1';
      await _server.start(accessCode: accessCode);

      _isHost = true;
      final serverUri = Uri.parse('ws://127.0.0.1:${_server.port}');
      await _client.connect(serverUri);

      final welcomeCompleter = Completer<Result<Room>>();
      _subscribeToClientMessages(welcomeCompleter, name, accessCode, hostIp);

      _client.send(
        SignalingMessage.join(
          displayName: displayName ?? 'Anfitrión',
          accessCode: accessCode,
        ),
      );

      return await welcomeCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => const Result.failure(Failure.hostUnreachable()),
      );
    } on Object catch (e, st) {
      AppLogger.e('Error creating room', e, st);
      return Result.failure(Failure.unexpected(error: e));
    }
  }

  @override
  Future<Result<Room>> joinRoom({
    required String hostAddress,
    required int port,
    required String accessCode,
    required String displayName,
  }) async {
    try {
      _isHost = false;
      final serverUri = Uri.parse('ws://$hostAddress:$port');
      await _client.connect(serverUri);

      final welcomeCompleter = Completer<Result<Room>>();
      _subscribeToClientMessages(
        welcomeCompleter,
        'Frecu',
        accessCode,
        hostAddress,
      );

      _client.send(
        SignalingMessage.join(displayName: displayName, accessCode: accessCode),
      );

      return await welcomeCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => const Result.failure(Failure.hostUnreachable()),
      );
    } on Object catch (e, st) {
      AppLogger.e('Error joining room', e, st);
      return Result.failure(Failure.unexpected(error: e));
    }
  }

  void _subscribeToClientMessages(
    Completer<Result<Room>> welcomeCompleter,
    String roomName,
    String accessCode,
    String hostAddress,
  ) {
    _clientSubscription?.cancel();
    _clientSubscription = _client.messages.listen(
      (message) {
        message.when(
          welcome: (peerId, participants, _) {
            _onWelcome(
              welcomeCompleter,
              roomName,
              accessCode,
              hostAddress,
              participants,
            );
          },
          rejected: (reason, _) => _onRejected(welcomeCompleter, reason),
          peerJoined: (p, _) => _onPeerJoined(p),
          peerLeft: (peerId, _) => _onPeerLeft(peerId),
          roomClosed: (reason, _) => _onRoomClosed(reason),
          offer: (_, __, ___, ____) {},
          answer: (_, __, ___, ____) {},
          ice: (_, __, ___, ____, _____, ______) {},
          talkState: (_, __, ___) {},
          ping: (_, __) {},
          pong: (_, __) {},
          join: (_, __, ___, ____) {},
        );
      },
      onError: (Object error) {
        AppLogger.w('Client message error: $error');
        if (!welcomeCompleter.isCompleted) {
          welcomeCompleter.complete(
            const Result.failure(Failure.hostUnreachable()),
          );
        }
      },
    );
  }

  void _onWelcome(
    Completer<Result<Room>> completer,
    String roomName,
    String accessCode,
    String hostAddress,
    List<Participant> participants,
  ) {
    _participants = List<Participant>.from(participants);
    _participantsController.add(_participants);
    _statusController.add(const RoomStatus.connected());

    final room = Room(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: roomName,
      hostAddress: hostAddress,
      port: _server.isRunning ? _server.port : NetworkConstants.signalingPort,
      accessCode: accessCode,
      createdAt: DateTime.now(),
    );

    if (!completer.isCompleted) {
      completer.complete(Result.success(room));
    }
  }

  void _onRejected(Completer<Result<Room>> completer, String reason) {
    _statusController.add(RoomStatus.closed(reason: reason));
    final Failure failure;
    if (reason == 'invalidAccessCode') {
      failure = const Failure.invalidAccessCode();
    } else if (reason == 'roomFull') {
      failure = const Failure.roomFull();
    } else {
      failure = Failure.unexpected(message: reason);
    }
    if (!completer.isCompleted) {
      completer.complete(Result.failure(failure));
    }
  }

  void _onPeerJoined(Participant participant) {
    _participants = [
      ..._participants.where((p) => p.id != participant.id),
      participant,
    ];
    _participantsController.add(_participants);
  }

  void _onPeerLeft(String peerId) {
    _participants = _participants.where((p) => p.id != peerId).toList();
    _participantsController.add(_participants);
  }

  void _onRoomClosed(String reason) {
    _statusController.add(RoomStatus.closed(reason: reason));
    _participants = [];
    _participantsController.add(_participants);
  }

  @override
  Future<Result<void>> leaveRoom() async {
    try {
      await _clientSubscription?.cancel();
      _clientSubscription = null;

      if (_isHost) {
        await _server.stop();
        _isHost = false;
      }
      await _client.disconnect();

      _statusController.add(const RoomStatus.closed(reason: 'user_left'));
      _participants = [];
      _participantsController.add(_participants);

      return const Result<void>.success(null);
    } on Object catch (e, st) {
      AppLogger.e('Error leaving room', e, st);
      return Result.failure(Failure.unexpected(error: e));
    }
  }

  /// Libera streams y recursos.
  Future<void> dispose() async {
    await leaveRoom();
    await _participantsController.close();
    await _statusController.close();
  }
}
