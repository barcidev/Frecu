import 'dart:async';
import 'dart:convert';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Cliente WebSocket para conectarse al servidor de señalización de una sala.
class SignalingClientDataSource {
  /// Constructor con intervalos de heartbeat y límite de conexión
  /// configurables; [channelFactory] abre el canal (para pruebas).
  SignalingClientDataSource({
    this.heartbeatInterval = NetworkConstants.heartbeatInterval,
    this.peerTimeout = NetworkConstants.peerTimeout,
    this.connectTimeout = defaultConnectTimeout,
    WebSocketChannel Function(Uri uri)? channelFactory,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  /// Límite por defecto para abrir el WebSocket: sin él, una IP sin
  /// anfitrión deja la conexión colgada hasta el límite del sistema (75 s o
  /// más).
  static const Duration defaultConnectTimeout = Duration(seconds: 5);

  /// Intervalo entre envíos periódicos de ping.
  final Duration heartbeatInterval;

  /// Tiempo máximo sin actividad antes de desconectar.
  final Duration peerTimeout;

  /// Tiempo máximo para que el WebSocket quede abierto.
  final Duration connectTimeout;

  final WebSocketChannel Function(Uri uri) _channelFactory;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _watchdogTimer;
  DateTime? _lastReceivedTime;

  /// Sube con cada `connect`: un intento que abre cuando ya hay otro más
  /// nuevo se descarta en lugar de pisar al canal nuevo.
  int _connectGeneration = 0;

  final StreamController<SignalingMessage> _messagesController =
      StreamController<SignalingMessage>.broadcast();

  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  /// Indica si el cliente está conectado activamente al servidor: solo
  /// después de que el WebSocket quedó abierto.
  bool get isConnected => _channel != null;

  /// Stream reactivo de mensajes recibidos desde el servidor.
  Stream<SignalingMessage> get messages => _messagesController.stream;

  /// Stream reactivo del estado de conexión (true: conectado, false:
  /// desconectado). Un intento que no llega a abrir no emite nada.
  Stream<bool> get connectionState => _connectionStateController.stream;

  /// Conecta con el servidor de señalización en la URI indicada.
  ///
  /// Espera como mucho [connectTimeout] a que el WebSocket abra; si no abre
  /// lanza la excepción del intento (`TimeoutException`,
  /// `WebSocketChannelException`, `SocketException`…) y el cliente queda
  /// desconectado sin haber emitido nada.
  Future<void> connect(Uri uri) async {
    final generation = ++_connectGeneration;
    await _close();

    WebSocketChannel? pending;
    try {
      pending = _channelFactory(uri);
      await pending.ready.timeout(connectTimeout);
    } on Object catch (e) {
      AppLogger.w('Failed to connect to signaling server at $uri: $e');
      // Si abre tarde, que no quede un socket huérfano.
      pending?.sink.close().ignore();
      rethrow;
    }

    final channel = pending;
    if (generation != _connectGeneration) {
      channel.sink.close().ignore();
      throw StateError('Connection to $uri superseded by a newer one');
    }
    _channel = channel;
    _lastReceivedTime = DateTime.now();
    _startHeartbeatTimers();
    _connectionStateController.add(true);
    AppLogger.i('Connected to signaling server at $uri');

    _subscription = channel.stream.listen(
      _onDataReceived,
      onDone: () {
        AppLogger.i('Signaling client stream closed');
        _handleDisconnected(channel);
      },
      onError: (Object error) {
        AppLogger.w('Signaling client error: $error');
        _handleDisconnected(channel);
      },
    );
  }

  void _startHeartbeatTimers() {
    _heartbeatTimer?.cancel();
    _watchdogTimer?.cancel();

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (isConnected) {
        send(
          SignalingMessage.ping(
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    });

    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkWatchdogTimeout();
    });
  }

  void _checkWatchdogTimeout() {
    final channel = _channel;
    if (channel == null || _lastReceivedTime == null) return;
    final elapsed = DateTime.now().difference(_lastReceivedTime!);
    if (elapsed > peerTimeout) {
      AppLogger.w(
        'Signaling client heartbeat watchdog timeout: '
        '$elapsed > $peerTimeout',
      );
      channel.sink.close().ignore();
      _handleDisconnected(channel);
    }
  }

  void _onDataReceived(dynamic data) {
    _lastReceivedTime = DateTime.now();
    try {
      final jsonMap = jsonDecode(data as String) as Map<String, dynamic>;
      final message = SignalingMessage.fromJson(jsonMap);
      if (!_messagesController.isClosed) _messagesController.add(message);
    } on Object catch (e, stackTrace) {
      AppLogger.e('Failed to parse signaling message: $data', e, stackTrace);
    }
  }

  /// Envía un mensaje de señalización al servidor.
  void send(SignalingMessage message) {
    final channel = _channel;
    if (channel == null) {
      AppLogger.w('Cannot send message: client is not connected');
      return;
    }

    try {
      final payload = jsonEncode(message.toJson());
      channel.sink.add(payload);
    } on Object catch (e, stackTrace) {
      AppLogger.e('Failed to send signaling message', e, stackTrace);
    }
  }

  /// Suelta [channel] si sigue siendo el canal activo y avisa una sola vez
  /// de la desconexión; un canal viejo ya reemplazado no hace nada.
  void _handleDisconnected(WebSocketChannel channel) {
    if (!identical(_channel, channel)) return;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _lastReceivedTime = null;

    _channel = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(false);
    }
  }

  /// Desconecta el cliente del servidor y descarta cualquier `connect` en
  /// curso.
  Future<void> disconnect() async {
    _connectGeneration++;
    await _close();
  }

  Future<void> _close() async {
    final channel = _channel;
    if (channel == null) return;
    _handleDisconnected(channel);
    try {
      await channel.sink.close().timeout(const Duration(seconds: 2));
    } on Object catch (e) {
      AppLogger.w('Signaling client close failed: $e');
    }
    AppLogger.i('Disconnected from signaling server');
  }

  /// Libera recursos y cierra los controladores de stream.
  Future<void> dispose() async {
    await disconnect();
    await _messagesController.close();
    await _connectionStateController.close();
  }
}
