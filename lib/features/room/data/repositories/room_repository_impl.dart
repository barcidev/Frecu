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
import 'package:frecu/features/room/data/datasources/host_probe.dart';
import 'package:frecu/features/room/data/datasources/room_succession.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/current_then.dart';
import 'package:frecu/features/room/data/repositories/internet_handover.dart';
import 'package:frecu/features/room/data/repositories/room_reconnection.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'room_repository_messages.dart';
part 'room_repository_reconnection.dart';
part 'room_repository_takeover.dart';

/// Implementación concreta de [RoomRepository] y del traspaso de la frecu
/// ([RoomHandover]).
///
/// Cada `createRoom`, `joinRoom` o `leaveRoom` abre una sesión nueva: lo que
/// llega tarde de una sesión anterior (mensajes, intentos de reconexión) se
/// descarta. `watchParticipants` y `watchStatus` entregan primero el valor
/// actual, así que una pantalla que se abre después del `welcome` no queda
/// vacía.
class RoomRepositoryImpl implements RoomRepository, RoomHandover {
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
    int maxReconnectAttempts = 5,
    this.welcomeTimeout = const Duration(seconds: 5),
    this.rejoinWelcomeTimeout = const Duration(seconds: 3),
    HostProbe? hostProbe,
  }) : _server = serverDataSource,
       _probe = hostProbe ?? HostProbe(),
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
       _rejoin = RejoinLoop(
         networkReturn: NetworkReturnWatcher(
           interfaces: networkInterfacesProvider ?? NetworkInterface.list,
           pollInterval: networkReturnPollInterval,
         ),
         baseDelay:
             reconnectBaseDelay ??
             (_isTest
                 ? const Duration(milliseconds: 50)
                 : const Duration(seconds: 1)),
         maxAttempts: maxReconnectAttempts,
       ) {
    _connectionStateSub = _client.connectionState.listen(
      _handleClientConnectionChange,
    );
    _server.onRival = _onRival;
    _relay.onOutranked = _onRelayOutranked;
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

  /// Reintentos para volver a la frecu tras perder el socket.
  final RejoinLoop _rejoin;

  /// Traspaso de la frecu entre anfitriones.
  final HostTakeover _takeover = HostTakeover();

  /// Pregunta, mientras este teléfono lleva la frecu, si otro la lleva con
  /// un turno que gana.
  final HostProbe _probe;

  /// Otro teléfono lleva la frecu con un turno que gana: este teléfono le
  /// cedió la suya y entra como invitado.
  HostRival? _outranked;

  /// Intentos de reconexión antes de dar la frecu por perdida.
  int get maxReconnectAttempts => _rejoin.maxAttempts;

  /// Espera máxima del `welcome` al crear o unirse.
  final Duration welcomeTimeout;

  /// Espera máxima del `welcome` en cada intento de reconexión.
  final Duration rejoinWelcomeTimeout;

  final StreamController<List<Participant>> _participantsController =
      StreamController<List<Participant>>.broadcast();
  final StreamController<RoomStatus> _statusController =
      StreamController<RoomStatus>.broadcast();

  final KnownSuccession _succession = KnownSuccession();
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

  /// Sigue un `host_handover`: la reconexión va a quien recibe la frecu, sin
  /// plan de caída.
  bool _following = false;
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
  RoomSuccession? get succession => _succession.current;

  @override
  Stream<RoomSuccession?> watchSuccession() => _succession.watch();

  @override
  Stream<HostChange> watchHostChanges() => _takeover.watch();

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
      final internetId = internet ? CloudConfig.newRoomId() : null;
      final hostSecret = internet ? CloudConfig.newHostSecret() : null;
      final hostIp = await _prepareHostAddress(
        internetId: internetId,
        hostSecret: hostSecret,
      );
      await _server.start(
        accessCode: accessCode,
        roomName: name,
        note: note,
        port: signalingPort,
      );
      await _client.connect(Uri.parse('ws://127.0.0.1:${_server.port}'));
      if (internetId != null && hostSecret != null) {
        _internetId = internetId;
        // Con el primer turno: si se cae, la nube espera a su sucesor.
        await _relay.start(
          InternetHandover.hostSocket(cloudConfig, internetId, hostSecret, 1),
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
  /// este teléfono y su sucesión. Por internet ([internetId] y
  /// [hostSecret]) no se invita por la red local: todos entran por la nube,
  /// aunque compartan la Wi-Fi del anfitrión.
  Future<String> _prepareHostAddress({
    String? internetId,
    String? hostSecret,
  }) async {
    final internet = internetId != null;
    final lan = internet ? null : await _lanAddress();
    _server.hostOwnsNetwork = !internet && _ownsNetwork(lan);
    final hostIp = internet ? '' : lan?.address ?? _fallbackLanAddress;
    _server.succession.configure(
      reach: internet ? RoomReach.internet : RoomReach.local,
      hostOwnsNetwork: _server.hostOwnsNetwork,
      hostAddress: internet ? null : hostIp,
      internetId: internetId,
      hostSecret: hostSecret,
    );
    return hostIp;
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

  @override
  Future<Result<void>> handOver(String peerId) async {
    if (!_isHost || !await _server.handOver(peerId)) {
      return Result.failure(
        Failure.unexpected(error: 'Cannot hand the room over to $peerId'),
      );
    }
    return leaveRoom();
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
    _takeover.forget();
    try {
      await _teardownConnection();
      _setStatus(const RoomStatus.closed(reason: 'user_left'));
      _succession.update(null);
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
    // `leaveRoom` ya soltó los mensajes; esto solo cubre un cierre a medias.
    await _clientSubscription?.cancel();
    _clientSubscription = null;
    await _connectionStateSub?.cancel();
    _connectionStateSub = null;
    await _participantsController.close();
    await _statusController.close();
    await _succession.dispose();
    await _takeover.dispose();
  }
}
