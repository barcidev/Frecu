import 'dart:async';
import 'dart:io';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
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
    ForegroundServiceDataSource? foregroundServiceDataSource,
    Future<List<NetworkInterface>> Function()? networkInterfacesProvider,
  }) : _server = serverDataSource,
       _client = clientDataSource,
       _foregroundService =
           foregroundServiceDataSource ?? ForegroundServiceDataSource(),
       _networkInterfacesProvider =
           networkInterfacesProvider ?? NetworkInterface.list {
    _connectionStateSub = _client.connectionState.listen(
      _handleClientConnectionChange,
    );
  }

  final SignalingServerDataSource _server;
  final SignalingClientDataSource _client;
  final ForegroundServiceDataSource _foregroundService;
  final Future<List<NetworkInterface>> Function() _networkInterfacesProvider;

  final StreamController<List<Participant>> _participantsController =
      StreamController<List<Participant>>.broadcast();
  final StreamController<RoomStatus> _statusController =
      StreamController<RoomStatus>.broadcast();

  StreamSubscription<dynamic>? _connectionStateSub;
  StreamSubscription<SignalingMessage>? _clientSubscription;
  List<Participant> _participants = [];
  bool _isHost = false;
  bool _isDeliberateLeave = false;
  bool _isClosed = false;
  String? _localParticipantId;

  String? _lastHostAddress;
  int? _lastPort;
  String? _lastAccessCode;
  String? _lastDisplayName;
  String? _lastRoomName;

  static bool get _isTest =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Zone.current[#test.declarer] != null;

  bool get _canReconnect =>
      !_isDeliberateLeave &&
      !_isClosed &&
      !_isHost &&
      _lastHostAddress != null &&
      _lastPort != null;

  @override
  String? get localParticipantId => _localParticipantId;

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
      _isDeliberateLeave = false;
      _isClosed = false;
      _isHost = true;
      _lastRoomName = name;
      final hostIp = await getLocalIpAddress() ?? '127.0.0.1';
      await _server.start(accessCode: accessCode);

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
      _isDeliberateLeave = false;
      _isClosed = false;
      _isHost = false;
      _lastHostAddress = hostAddress;
      _lastPort = port;
      _lastAccessCode = accessCode;
      _lastDisplayName = displayName;
      _lastRoomName = 'Frecu';

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

  void _handleClientConnectionChange(bool isConnected) {
    if (isConnected || !_canReconnect) return;
    _statusController.add(const RoomStatus.reconnecting());
    unawaited(
      _foregroundService.updateNotification(
        roomName: _lastRoomName ?? 'Frecu',
        status: 'Reconectando...',
      ),
    );
    unawaited(_startReconnectLoop());
  }

  Future<void> _startReconnectLoop() async {
    var delay = _isTest
        ? const Duration(milliseconds: 50)
        : const Duration(seconds: 1);
    const maxAttempts = 5;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (!_canReconnect) return;

      await Future<void>.delayed(delay);
      if (!_canReconnect) return;

      final success = await _attemptSingleReconnect(attempt);
      if (success) return;

      delay = _nextBackoffDelay(delay);
    }

    _finalizeReconnectFailure();
  }

  Duration _nextBackoffDelay(Duration current) {
    return Duration(
      milliseconds: (current.inMilliseconds * 2).clamp(
        0,
        NetworkConstants.maxReconnectBackoff.inMilliseconds,
      ),
    );
  }

  void _finalizeReconnectFailure() {
    if (_canReconnect) {
      _localParticipantId = null;
      unawaited(_foregroundService.stopService());
      _statusController.add(
        const RoomStatus.closed(reason: 'host_unreachable'),
      );
    }
  }

  Future<bool> _attemptSingleReconnect(int attempt) async {
    try {
      final serverUri = Uri.parse('ws://$_lastHostAddress:$_lastPort');
      await _client.connect(serverUri);

      final welcomeCompleter = Completer<Result<Room>>();
      _subscribeToClientMessages(
        welcomeCompleter,
        'Frecu',
        _lastAccessCode ?? '',
        _lastHostAddress ?? '',
      );

      _client.send(
        SignalingMessage.join(
          displayName: _lastDisplayName ?? 'Participante',
          accessCode: _lastAccessCode ?? '',
        ),
      );

      final result = await welcomeCompleter.future.timeout(
        const Duration(seconds: 3),
      );
      return result.isSuccess;
    } on Object catch (e) {
      AppLogger.w('Reconnect attempt $attempt failed: $e');
      return false;
    }
  }

  void _subscribeToClientMessages(
    Completer<Result<Room>>? welcomeCompleter,
    String roomName,
    String accessCode,
    String hostAddress,
  ) {
    _clientSubscription?.cancel();
    _clientSubscription = _client.messages.listen(
      (message) {
        message.when(
          welcome: (peerId, participants, _) {
            _localParticipantId = peerId;
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
        if (welcomeCompleter != null && !welcomeCompleter.isCompleted) {
          welcomeCompleter.complete(
            const Result.failure(Failure.hostUnreachable()),
          );
        }
      },
    );
  }

  void _onWelcome(
    Completer<Result<Room>>? completer,
    String roomName,
    String accessCode,
    String hostAddress,
    List<Participant> participants,
  ) {
    _isClosed = false;
    _participants = List<Participant>.from(participants);
    _participantsController.add(_participants);
    _statusController.add(const RoomStatus.connected());
    unawaited(
      _foregroundService.startService(roomName: roomName, status: 'Conectado'),
    );

    final room = Room(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: roomName,
      hostAddress: hostAddress,
      port: _server.isRunning ? _server.port : NetworkConstants.signalingPort,
      accessCode: accessCode,
      createdAt: DateTime.now(),
    );

    if (completer != null && !completer.isCompleted) {
      completer.complete(Result.success(room));
    }
  }

  void _onRejected(Completer<Result<Room>>? completer, String reason) {
    _isClosed = true;
    _localParticipantId = null;
    unawaited(_foregroundService.stopService());
    _statusController.add(RoomStatus.closed(reason: reason));
    final Failure failure;
    if (reason == 'invalidAccessCode') {
      failure = const Failure.invalidAccessCode();
    } else if (reason == 'roomFull') {
      failure = const Failure.roomFull();
    } else {
      failure = Failure.unexpected(message: reason);
    }
    if (completer != null && !completer.isCompleted) {
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
    _isClosed = true;
    _localParticipantId = null;
    unawaited(_foregroundService.stopService());
    _statusController.add(RoomStatus.closed(reason: reason));
    _participants = [];
    _participantsController.add(_participants);
  }

  @override
  Future<Result<void>> leaveRoom() async {
    try {
      _isDeliberateLeave = true;
      _isClosed = true;
      _localParticipantId = null;
      await _clientSubscription?.cancel();
      _clientSubscription = null;

      await _foregroundService.stopService();

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
    await _connectionStateSub?.cancel();
    _connectionStateSub = null;
    await _participantsController.close();
    await _statusController.close();
  }
}
