import 'dart:async';
import 'dart:convert';

import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Cliente WebSocket para conectarse al servidor de señalización de una sala.
class SignalingClientDataSource {
  /// Constructor.
  SignalingClientDataSource();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final StreamController<SignalingMessage> _messagesController =
      StreamController<SignalingMessage>.broadcast();

  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  /// Indica si el cliente está conectado activamente al servidor.
  bool get isConnected => _channel != null;

  /// Stream reactivo de mensajes recibidos desde el servidor.
  Stream<SignalingMessage> get messages => _messagesController.stream;

  /// Stream reactivo del estado de conexión (true: conectado, false: desconectado).
  Stream<bool> get connectionState => _connectionStateController.stream;

  /// Conecta con el servidor de señalización en la URI indicada.
  Future<void> connect(Uri uri) async {
    await disconnect();

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _connectionStateController.add(true);
      AppLogger.i('Connected to signaling server at $uri');

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final jsonMap = jsonDecode(data as String) as Map<String, dynamic>;
            final message = SignalingMessage.fromJson(jsonMap);
            _messagesController.add(message);
          } on Object catch (e, stackTrace) {
            AppLogger.e(
              'Failed to parse signaling message: $data',

              e,

              stackTrace,
            );
          }
        },
        onDone: () {
          AppLogger.i('Signaling client stream closed');
          _handleDisconnected();
        },
        onError: (Object error) {
          AppLogger.w('Signaling client error: $error');
          _handleDisconnected();
        },
      );
    } on Object catch (e, stackTrace) {
      AppLogger.e(
        'Failed to connect to signaling server at $uri',

        e,

        stackTrace,
      );
      _handleDisconnected();
      rethrow;
    }
  }

  /// Envía un mensaje de señalización al servidor.
  void send(SignalingMessage message) {
    if (!isConnected) {
      AppLogger.w('Cannot send message: client is not connected');
      return;
    }

    try {
      final payload = jsonEncode(message.toJson());
      _channel!.sink.add(payload);
    } on Object catch (e, stackTrace) {
      AppLogger.e('Failed to send signaling message', e, stackTrace);
    }
  }

  void _handleDisconnected() {
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _connectionStateController.add(false);
  }

  /// Desconecta el cliente del servidor.
  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel?.sink.close();
      _handleDisconnected();
      AppLogger.i('Disconnected from signaling server');
    }
  }

  /// Libera recursos y cierra los controladores de stream.
  Future<void> dispose() async {
    await disconnect();
    await _messagesController.close();
    await _connectionStateController.close();
  }
}
