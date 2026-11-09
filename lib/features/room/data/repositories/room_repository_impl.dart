import 'dart:async';
import 'dart:io';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/network/lan_address.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/current_then.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Implementación concreta de [RoomRepository].
///
/// Cada `createRoom`, `joinRoom` o `leaveRoom` abre una sesión nueva: lo que
/// llega tarde de una sesión anterior (mensajes, intentos de reconexión) se
/// descarta. `watchParticipants` y `watchStatus` entregan primero el valor
/// actual, así que una pantalla que se abre después del `welcome` no queda
/// vacía.
class RoomRepositoryImpl implements RoomRepository {
  /// Constructor con inyección de datasources; los tiempos son
  /// configurables para pruebas.
  RoomRepositoryImpl({
    required SignalingServerDataSource serverDataSource,
    required SignalingClientDataSource clientDataSource,
    ForegroundServiceDataSource? foregroundServiceDataSource,
    Future<List<NetworkInterface>> Function()? networkInterfacesProvider,
    String? Function()? preferredLanInterface,
    Duration? reconnectBaseDelay,
    this.maxReconnectAttempts = 5,
    this.welcomeTimeout = const Duration(seconds: 5),
    this.rejoinWelcomeTimeout = const Duration(seconds: 3),
  }) : _server = serverDataSource,
       _client = clientDataSource,
       _foregroundService =
           foregroundServiceDataSource ?? ForegroundServiceDataSource(),
       _networkInterfacesProvider =
           networkInterfacesProvider ?? NetworkInterface.list,
       _lanInterfaceHint = preferredLanInterface,
       _reconnectBaseDelay =
           reconnectBaseDelay ??
           (_isTest
               ? const Duration(milliseconds: 50)
               : const Duration(seconds: 1)) {
    _connectionStateSub = _client.connectionState.listen(
      _handleClientConnectionChange,
    );
  }

  final SignalingServerDataSource _server;
  final SignalingClientDataSource _client;
  final ForegroundServiceDataSource _foregroundService;
  final Future<List<NetworkInterface>> Function() _networkInterfacesProvider;

  /// Interfaz de la red de la frecu que creó este teléfono, si la hay: su
  /// IPv4 es la que va en la invitación.
  final String? Function()? _lanInterfaceHint;
  final Duration _reconnectBaseDelay;

  /// Intentos de reconexión antes de dar la frecu por perdida.
  final int maxReconnectAttempts;

  /// Espera máxima del `welcome` al crear o unirse.
  final Duration welcomeTimeout;

  /// Espera máxima del `welcome` en cada intento de reconexión.
  final Duration rejoinWelcomeTimeout;

  final StreamController<List<Participant>> _participantsController =
      StreamController<List<Participant>>.broadcast();
  final StreamController<RoomStatus> _statusController =
      StreamController<RoomStatus>.broadcast();

  StreamSubscription<bool>? _connectionStateSub;
  StreamSubscription<SignalingMessage>? _clientSubscription;
  List<Participant> _participants = const [];
  RoomStatus _status = const RoomStatus.idle();
  bool _isHost = false;
  bool _isDeliberateLeave = false;
  bool _isClosed = false;

  /// Hubo `welcome` en esta sesión: solo entonces se reconecta.
  bool _joined = false;

  /// Hay algo abierto (socket, servidor o notificación) que soltar.
  bool _live = false;
  int _session = 0;
  int? _reconnectSession;
  String? _localParticipantId;
  String _roomName = '';
  _JoinTarget? _target;

  static bool get _isTest =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Zone.current[#test.declarer] != null;

  bool get _canReconnect =>
      _joined &&
      !_isDeliberateLeave &&
      !_isClosed &&
      !_isHost &&
      _target != null;

  @override
  String? get localParticipantId => _localParticipantId;

  @override
  Stream<List<Participant>> watchParticipants() =>
      currentThen(() => _participants, _participantsController.stream);

  @override
  Stream<RoomStatus> watchStatus() =>
      currentThen(() => _status, _statusController.stream);

  @override
  Future<String?> getLocalIpAddress() async {
    try {
      // Solo Wi-Fi o punto de acceso: nunca datos móviles ni VPN. Con la
      // red de Frecu al aire, la suya.
      final interfaces = await _networkInterfacesProvider();
      return selectLanAddress(
            interfaces.map(LanInterface.fromIo),
            prefer: _lanInterfaceHint?.call(),
          )?.address ??
          '192.168.43.1';
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
    RoomNote? note,
  }) async {
    final session = await _beginSession(host: true);
    _roomName = name;
    try {
      final hostIp = await getLocalIpAddress() ?? '127.0.0.1';
      await _server.start(accessCode: accessCode, roomName: name, note: note);
      await _client.connect(Uri.parse('ws://127.0.0.1:${_server.port}'));
      final result = await _join(
        session,
        displayName: displayName ?? '',
        accessCode: accessCode,
        hostAddress: hostIp,
        port: _server.port,
      );
      if (result.isFailure) await _abortSession(session);
      return result;
    } on Object catch (e, st) {
      AppLogger.e('Error creating room', e, st);
      await _abortSession(session);
      return Result.failure(
        e is SocketException
            ? const Failure.network()
            : Failure.unexpected(error: e),
      );
    }
  }

  @override
  Future<Result<Room>> joinRoom({
    required String hostAddress,
    required int port,
    required String accessCode,
    required String displayName,
  }) async {
    final session = await _beginSession(host: false);
    _roomName = '';
    _target = _JoinTarget(
      host: hostAddress,
      port: port,
      accessCode: accessCode,
      displayName: displayName,
    );
    try {
      await _client.connect(Uri.parse('ws://$hostAddress:$port'));
      final result = await _join(
        session,
        displayName: displayName,
        accessCode: accessCode,
        hostAddress: hostAddress,
        port: port,
      );
      if (result.isFailure) await _abortSession(session);
      return result;
    } on Object catch (e, st) {
      AppLogger.w('Error joining room at $hostAddress:$port: $e', e, st);
      await _abortSession(session);
      return Result.failure(_joinFailure(e));
    }
  }

  /// Fallo de unirse: sin respuesta, socket caído o handshake roto es que el
  /// anfitrión no responde.
  static Failure _joinFailure(Object error) => switch (error) {
    TimeoutException() ||
    SocketException() ||
    WebSocketChannelException() ||
    WebSocketException() ||
    HandshakeException() ||
    HttpException() ||
    FormatException() ||
    ArgumentError() => const Failure.hostUnreachable(),
    _ => Failure.unexpected(error: error),
  };

  /// Abre una sesión nueva y cierra la anterior si seguía viva (p. ej. una
  /// frecu que se dejó con Atrás), sin reconectarla.
  Future<int> _beginSession({required bool host}) async {
    final session = ++_session;
    _joined = false;
    _target = null;
    _isDeliberateLeave = true;
    if (_live) await _teardownConnection();
    _live = true;
    _isDeliberateLeave = false;
    _isClosed = false;
    _isHost = host;
    _localParticipantId = null;
    _setParticipants(const []);
    _setStatus(const RoomStatus.connecting());
    return session;
  }

  /// Deshace un intento fallido de crear o unirse.
  Future<void> _abortSession(int session) async {
    if (session != _session) return;
    _joined = false;
    _target = null;
    _localParticipantId = null;
    _isDeliberateLeave = true;
    await _teardownConnection();
    _isDeliberateLeave = false;
    _setParticipants(const []);
    _setStatus(const RoomStatus.idle());
  }

  /// Suelta la conexión de la sesión actual: mensajes, notificación,
  /// servidor (si es anfitrión) y socket.
  Future<void> _teardownConnection() async {
    _live = false;
    // Dejar de escuchar es inmediato; no hace falta esperar.
    unawaited(_clientSubscription?.cancel());
    _clientSubscription = null;
    await _foregroundService.stopService();
    if (_isHost || _server.isRunning) await _server.stop();
    _isHost = false;
    await _client.disconnect();
  }

  /// Envía el `join` y espera el `welcome` como mucho [welcomeTimeout].
  Future<Result<Room>> _join(
    int session, {
    required String displayName,
    required String accessCode,
    required String hostAddress,
    required int port,
  }) async {
    final welcome = Completer<Result<Room>>();
    _listen(
      session,
      welcome: welcome,
      rejoin: false,
      accessCode: accessCode,
      hostAddress: hostAddress,
      port: port,
    );
    _client.send(
      SignalingMessage.join(displayName: displayName, accessCode: accessCode),
    );
    return welcome.future.timeout(
      welcomeTimeout,
      onTimeout: () => const Result.failure(Failure.hostUnreachable()),
    );
  }

  void _handleClientConnectionChange(bool isConnected) {
    if (isConnected || !_canReconnect) return;
    final session = _session;
    // Un solo bucle de reconexión por sesión.
    if (_reconnectSession == session) return;
    _reconnectSession = session;
    unawaited(
      _reconnect(session).whenComplete(() {
        if (_reconnectSession == session) _reconnectSession = null;
      }),
    );
  }

  bool _stillReconnecting(int session) => session == _session && _canReconnect;

  Future<void> _reconnect(int session) async {
    var delay = _reconnectBaseDelay;
    try {
      for (var attempt = 1; attempt <= maxReconnectAttempts; attempt++) {
        if (!_stillReconnecting(session)) return;
        _setStatus(RoomStatus.reconnecting(retryIn: delay, attempt: attempt));
        unawaited(
          _foregroundService.updateNotification(
            roomName: _roomName,
            status: ForegroundStatus.reconnecting,
          ),
        );
        await Future<void>.delayed(delay);
        if (!_stillReconnecting(session)) return;
        if (await _attemptRejoin(session, attempt)) return;
        delay = _nextBackoffDelay(delay);
      }
      if (_stillReconnecting(session)) _giveUp();
    } on Object catch (e, st) {
      AppLogger.e('Reconnect loop failed', e, st);
      if (_stillReconnecting(session)) _giveUp();
    }
  }

  Duration _nextBackoffDelay(Duration current) {
    return Duration(
      milliseconds: (current.inMilliseconds * 2).clamp(
        0,
        NetworkConstants.maxReconnectBackoff.inMilliseconds,
      ),
    );
  }

  /// Un intento de volver a la frecu; `true` si volvió o si ya no hay que
  /// seguir intentando.
  Future<bool> _attemptRejoin(int session, int attempt) async {
    final target = _target;
    if (target == null) return true;
    try {
      await _client.connect(Uri.parse('ws://${target.host}:${target.port}'));
      if (!_stillReconnecting(session)) return true;

      final welcome = Completer<Result<Room>>();
      _listen(
        session,
        welcome: welcome,
        rejoin: true,
        accessCode: target.accessCode,
        hostAddress: target.host,
        port: target.port,
      );
      _client.send(
        SignalingMessage.join(
          displayName: target.displayName,
          accessCode: target.accessCode,
        ),
      );
      final result = await welcome.future.timeout(
        rejoinWelcomeTimeout,
        onTimeout: () => const Result.failure(Failure.hostUnreachable()),
      );
      if (result.isSuccess || !_stillReconnecting(session)) return true;
      // Sin welcome a tiempo: se suelta ese socket antes del próximo intento.
      await _client.disconnect();
      return false;
    } on Object catch (e) {
      AppLogger.w('Reconnect attempt $attempt failed: $e');
      return !_stillReconnecting(session);
    }
  }

  /// Se agotaron los intentos: la frecu queda cerrada sin anfitrión.
  void _giveUp() {
    _isClosed = true;
    _joined = false;
    _localParticipantId = null;
    unawaited(_foregroundService.stopService());
    unawaited(_clientSubscription?.cancel());
    _clientSubscription = null;
    unawaited(_client.disconnect());
    _setStatus(const RoomStatus.closed(reason: 'host_unreachable'));
    _setParticipants(const []);
  }

  void _listen(
    int session, {
    required Completer<Result<Room>> welcome,
    required bool rejoin,
    required String accessCode,
    required String hostAddress,
    required int port,
  }) {
    unawaited(_clientSubscription?.cancel());
    _clientSubscription = _client.messages.listen(
      (message) {
        if (session != _session) return;
        switch (message) {
          case SignalingWelcomeMessage(
            :final peerId,
            :final participants,
            :final note,
            :final roomName,
          ):
            // Un intento de reconexión que ya se dio por fallido no revive.
            if (rejoin && welcome.isCompleted) return;
            // Al reconectar, el lugar viejo propio puede seguir en la lista
            // hasta que el anfitrión note que se fue: no es otra persona.
            final stale = rejoin ? _localParticipantId : null;
            _onWelcome(
              welcome,
              peerId: peerId,
              participants: [
                for (final participant in participants)
                  if (participant.id != stale) participant,
              ],
              note: note,
              roomName: roomName,
              accessCode: accessCode,
              hostAddress: hostAddress,
              port: port,
            );
          case SignalingRejectedMessage(:final reason):
            _onRejected(welcome, reason, rejoin: rejoin);
          case SignalingPeerJoinedMessage(:final participant):
            _onPeerJoined(participant);
          case SignalingPeerLeftMessage(:final peerId):
            _onPeerLeft(peerId);
          case SignalingRoomClosedMessage(:final reason):
            _onRoomClosed(reason);
          case SignalingJoinMessage() ||
              SignalingOfferMessage() ||
              SignalingAnswerMessage() ||
              SignalingIceMessage() ||
              SignalingTalkStateMessage() ||
              SignalingPingMessage() ||
              SignalingPongMessage() ||
              SignalingQuickMessage() ||
              SignalingPositionMessage():
            break;
        }
      },
      onError: (Object error) {
        AppLogger.w('Client message error: $error');
        if (!welcome.isCompleted) {
          welcome.complete(const Result.failure(Failure.hostUnreachable()));
        }
      },
    );
  }

  void _onWelcome(
    Completer<Result<Room>> completer, {
    required String peerId,
    required List<Participant> participants,
    required RoomNote? note,
    required String? roomName,
    required String accessCode,
    required String hostAddress,
    required int port,
  }) {
    _joined = true;
    _isClosed = false;
    _localParticipantId = peerId;
    if (roomName != null && roomName.isNotEmpty) _roomName = roomName;
    _setParticipants(participants);
    _setStatus(const RoomStatus.connected());
    unawaited(
      _foregroundService.startService(
        roomName: _roomName,
        status: ForegroundStatus.connected,
      ),
    );

    final room = Room(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: _roomName,
      hostAddress: hostAddress,
      port: port,
      accessCode: accessCode,
      createdAt: DateTime.now(),
      note: note,
    );

    if (!completer.isCompleted) completer.complete(Result.success(room));
  }

  void _onRejected(
    Completer<Result<Room>> completer,
    String reason, {
    required bool rejoin,
  }) {
    // Al reconectar, un rechazo (p. ej. su lugar viejo aún ocupa la frecu
    // llena) es un intento fallido más, no el final de la frecu.
    if (!rejoin) _localParticipantId = null;
    final failure = switch (reason) {
      RejectReason.invalidAccessCode => const Failure.invalidAccessCode(),
      RejectReason.roomFull => const Failure.roomFull(),
      RejectReason.versionMismatch => const Failure.versionMismatch(),
      _ => Failure.unexpected(error: 'rejected: $reason'),
    };
    if (!completer.isCompleted) completer.complete(Result.failure(failure));
  }

  void _onPeerJoined(Participant participant) {
    _setParticipants([
      ..._participants.where((p) => p.id != participant.id),
      participant,
    ]);
  }

  void _onPeerLeft(String peerId) {
    _setParticipants(_participants.where((p) => p.id != peerId).toList());
  }

  void _onRoomClosed(String reason) {
    _isClosed = true;
    _joined = false;
    _localParticipantId = null;
    unawaited(_foregroundService.stopService());
    _setStatus(RoomStatus.closed(reason: reason));
    _setParticipants(const []);
  }

  void _setStatus(RoomStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  void _setParticipants(List<Participant> participants) {
    _participants = List.unmodifiable(participants);
    if (!_participantsController.isClosed) {
      _participantsController.add(_participants);
    }
  }

  @override
  Future<Result<void>> leaveRoom() async {
    _session++;
    _isDeliberateLeave = true;
    _isClosed = true;
    _joined = false;
    _target = null;
    _localParticipantId = null;
    try {
      await _teardownConnection();
      _setStatus(const RoomStatus.closed(reason: 'user_left'));
      _setParticipants(const []);
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

/// Frecu a la que volver al reconectar.
class _JoinTarget {
  const _JoinTarget({
    required this.host,
    required this.port,
    required this.accessCode,
    required this.displayName,
  });

  final String host;
  final int port;
  final String accessCode;
  final String displayName;
}
