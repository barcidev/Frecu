import 'dart:async';
import 'dart:io';

import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/network/lan_address.dart';
import 'package:frecu/core/network/network_return.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/cloud_relay_datasource.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/current_then.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
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
    CloudRelayDataSource? cloudRelayDataSource,
    this.cloudConfig = CloudConfig.fromEnvironment,
    this.signalingPort = NetworkConstants.signalingPort,
    Future<List<NetworkInterface>> Function()? networkInterfacesProvider,
    String? Function()? preferredLanInterface,
    Duration? reconnectBaseDelay,
    Duration networkReturnPollInterval =
        NetworkConstants.networkReturnPollInterval,
    this.maxReconnectAttempts = 5,
    this.welcomeTimeout = const Duration(seconds: 5),
    this.rejoinWelcomeTimeout = const Duration(seconds: 3),
  }) : _server = serverDataSource,
       _client = clientDataSource,
       _relay =
           cloudRelayDataSource ??
           CloudRelayDataSource(
             networkWatcher: NetworkReturnWatcher(
               interfaces: networkInterfacesProvider ?? NetworkInterface.list,
               pollInterval: networkReturnPollInterval,
             ),
           ),
       _foregroundService =
           foregroundServiceDataSource ?? ForegroundServiceDataSource(),
       _networkInterfacesProvider =
           networkInterfacesProvider ?? NetworkInterface.list,
       _lanInterfaceHint = preferredLanInterface,
       _networkReturn = NetworkReturnWatcher(
         interfaces: networkInterfacesProvider ?? NetworkInterface.list,
         pollInterval: networkReturnPollInterval,
       ),
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
  final CloudRelayDataSource _relay;

  /// Punto de encuentro del modo internet.
  final CloudConfig cloudConfig;

  /// Puerto del servidor local de la frecu (0 en pruebas: uno libre).
  final int signalingPort;
  final ForegroundServiceDataSource _foregroundService;
  final Future<List<NetworkInterface>> Function() _networkInterfacesProvider;

  /// Interfaz de la red de la frecu que creó este teléfono, si la hay: su
  /// IPv4 es la que va en la invitación.
  final String? Function()? _lanInterfaceHint;

  /// Adelanta la espera de reconexión si el teléfono recupera la red.
  final NetworkReturnWatcher _networkReturn;
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

  /// Id por internet de la frecu de esta sesión, si tiene.
  String? _internetId;
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
  Future<String?> getLocalIpAddress() async =>
      (await _lanAddress())?.address ?? _fallbackLanAddress;

  /// IPv4 de la invitación si no hay red local a la vista: la habitual del
  /// punto de acceso de Android.
  static const String _fallbackLanAddress = '192.168.43.1';

  /// La red local de la frecu, o nulo si no hay ninguna a la vista.
  Future<LanAddress?> _lanAddress() async {
    try {
      // Solo Wi-Fi o punto de acceso: nunca datos móviles ni VPN. Con la
      // red de Frecu al aire, la suya.
      final interfaces = await _networkInterfacesProvider();
      return selectLanAddress(
        interfaces.map(LanInterface.fromIo),
        prefer: _lanInterfaceHint?.call(),
      );
    } on Object catch (e) {
      AppLogger.w('Failed to get local IP: $e');
      return null;
    }
  }

  /// La red de una frecu local la crea este teléfono: la red de Frecu está
  /// al aire, [lan] es su zona Wi-Fi, o no hay red local a la vista (una
  /// zona Wi-Fi de iPhone no aparece hasta que alguien se conecta, y la
  /// invitación lleva la IP de respaldo).
  bool _ownsNetwork(LanAddress? lan) =>
      _lanInterfaceHint?.call() != null || lan?.kind != LanKind.wifi;

  @override
  Future<Result<Room>> createRoom({
    required String name,
    required String accessCode,
    String? displayName,
    RoomNote? note,
    RoomReach reach = RoomReach.local,
  }) async {
    final session = await _beginSession(host: true);
    _roomName = name;
    final internet = reach == RoomReach.internet;
    try {
      if (internet && !cloudConfig.isEnabled) {
        throw StateError('Internet mode is not configured');
      }
      final hostIp = await _prepareHostAddress(internet: internet);
      await _server.start(
        accessCode: accessCode,
        roomName: name,
        note: note,
        port: signalingPort,
      );
      await _client.connect(Uri.parse('ws://127.0.0.1:${_server.port}'));
      if (internet) {
        final internetId = CloudConfig.newRoomId();
        _internetId = internetId;
        await _relay.start(
          cloudConfig.hostSocket(internetId, CloudConfig.newHostSecret()),
          onGuest: _server.accept,
        );
      }
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
      return Result.failure(_createFailure(e));
    }
  }

  /// IPv4 de la invitación de una frecu nueva, y fija si su red la crea
  /// este teléfono. Por internet no se invita por la red local: todos
  /// entran por la nube, aunque compartan la Wi-Fi del anfitrión.
  Future<String> _prepareHostAddress({required bool internet}) async {
    if (internet) {
      _server.hostOwnsNetwork = false;
      return '';
    }
    final lan = await _lanAddress();
    _server.hostOwnsNetwork = _ownsNetwork(lan);
    return lan?.address ?? _fallbackLanAddress;
  }

  /// Fallo de abrir una frecu: sin red si no se pudo escuchar o conectar.
  static Failure _createFailure(Object error) =>
      error is SocketException ||
          error is WebSocketChannelException ||
          error is TimeoutException
      ? const Failure.network()
      : Failure.unexpected(error: error);

  Future<bool> _resolves(String host) async {
    try {
      final found = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 3));
      return found.isNotEmpty;
    } on Object {
      return false;
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
    final uri = Uri.parse('ws://$hostAddress:$port');
    _target = _JoinTarget(
      uri: uri,
      host: hostAddress,
      port: port,
      accessCode: accessCode,
      displayName: displayName,
    );
    try {
      await _client.connect(uri);
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

  @override
  Future<Result<Room>> joinInternetRoom({
    required String internetId,
    required String accessCode,
    required String displayName,
  }) async {
    final session = await _beginSession(host: false);
    _roomName = '';
    if (!cloudConfig.isEnabled || !CloudConfig.isRoomId(internetId)) {
      await _abortSession(session);
      return const Result.failure(Failure.hostUnreachable());
    }
    _internetId = internetId;
    final uri = cloudConfig.guestSocket(internetId);
    _target = _JoinTarget(
      uri: uri,
      host: '',
      port: 0,
      accessCode: accessCode,
      displayName: displayName,
    );
    try {
      await _client.connect(uri);
      final result = await _join(
        session,
        displayName: displayName,
        accessCode: accessCode,
        hostAddress: '',
        port: 0,
      );
      if (result.isFailure) await _abortSession(session);
      return result;
    } on Object catch (e, st) {
      AppLogger.w('Error joining internet room: $e', e, st);
      await _abortSession(session);
      final failure = _joinFailure(e);
      // Sin poder resolver el punto de encuentro, lo que falta es internet.
      if (failure == const Failure.hostUnreachable() &&
          !await _resolves(uri.host)) {
        return const Result.failure(Failure.network());
      }
      return Result.failure(failure);
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
    _internetId = null;
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
    await _relay.stop();
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
      var baseline = await _networkReturn.addresses();
      for (var attempt = 1; attempt <= maxReconnectAttempts; attempt++) {
        if (!_stillReconnecting(session)) return;
        _setStatus(RoomStatus.reconnecting(retryIn: delay, attempt: attempt));
        unawaited(
          _foregroundService.updateNotification(
            roomName: _roomName,
            status: ForegroundStatus.reconnecting,
          ),
        );
        final networkBack = await _networkReturn.wait(
          delay,
          baseline: baseline,
          cancelled: () => !_stillReconnecting(session),
        );
        if (!_stillReconnecting(session)) return;
        if (networkBack) {
          // Volvió la red antes de tiempo: la cuenta pasa a «intentando».
          _setStatus(
            RoomStatus.reconnecting(retryIn: Duration.zero, attempt: attempt),
          );
        }
        // La referencia se renueva antes de cada intento: una misma red que
        // aparece solo adelanta un intento.
        baseline = await _networkReturn.addresses();
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
      await _client.connect(target.uri);
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
      internetId: _internetId,
      hostOwnsNetwork: participants.any((p) => p.isHost && p.ownsNetwork),
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
    required this.uri,
    required this.host,
    required this.port,
    required this.accessCode,
    required this.displayName,
  });

  final Uri uri;
  final String host;
  final int port;
  final String accessCode;
  final String displayName;
}
