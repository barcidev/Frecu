import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Servidor WebSocket de señalización para el anfitrión de la sala.
class SignalingServerDataSource {
  /// Constructor.
  SignalingServerDataSource();

  HttpServer? _server;
  String _accessCode = '';
  int _peerCounter = 0;

  final Map<String, WebSocketChannel> _clientChannels = {};
  final Map<String, Participant> _participants = {};
  final StreamController<SignalingMessage> _messagesController =
      StreamController<SignalingMessage>.broadcast();

  /// Indica si el servidor se encuentra activo y escuchando.
  bool get isRunning => _server != null;

  /// Puerto en el que está escuchando el servidor.
  int get port => _server?.port ?? 0;

  /// Stream de todos los mensajes de señalización procesados por el servidor.
  Stream<SignalingMessage> get messages => _messagesController.stream;

  /// Lista de participantes actualmente registrados en el servidor.
  List<Participant> get participants => _participants.values.toList();

  /// Inicia el servidor de señalización.
  Future<void> start({
    required String accessCode,
    String host = '0.0.0.0',
    int port = NetworkConstants.signalingPort,
  }) async {
    if (isRunning) return;

    _accessCode = accessCode;
    _participants.clear();
    _clientChannels.clear();
    _peerCounter = 0;

    final handler = webSocketHandler((
      WebSocketChannel channel,
      String? subprotocol,
    ) {
      _handleConnection(channel);
    });

    try {
      _server = await shelf_io.serve(handler, host, port);
      AppLogger.i('Signaling server started on $host:${_server!.port}');
    } on Object catch (e, stackTrace) {
      AppLogger.e('Failed to start signaling server', e, stackTrace);
      rethrow;
    }
  }

  void _handleConnection(WebSocketChannel channel) {
    String? assignedPeerId;

    channel.stream.listen(
      (data) {
        final newId = _onClientData(channel, data as String, assignedPeerId);
        if (newId != null) {
          assignedPeerId = newId;
        }
      },
      onDone: () {
        if (assignedPeerId != null) _handlePeerLeft(assignedPeerId!);
      },
      onError: (Object error) {
        AppLogger.w('Client socket error: $error');
        if (assignedPeerId != null) _handlePeerLeft(assignedPeerId!);
      },
    );
  }

  String? _onClientData(
    WebSocketChannel channel,
    String rawData,
    String? assignedPeerId,
  ) {
    try {
      final jsonMap = jsonDecode(rawData) as Map<String, dynamic>;
      final message = SignalingMessage.fromJson(jsonMap);
      _messagesController.add(message);

      return message.when(
        join: (displayName, code, version, type) =>
            _processJoin(channel, displayName, code),
        welcome: (_, __, ___) => null,
        rejected: (_, __) => null,
        peerJoined: (_, __) => null,
        peerLeft: (_, __) => null,
        offer: (_, to, __, ___) => _routeAndReturn(to, message),
        answer: (_, to, __, ___) => _routeAndReturn(to, message),
        ice: (_, to, __, ___, ____, _____) => _routeAndReturn(to, message),
        talkState: (peerId, _, __) {
          _broadcast(message, excludePeerId: peerId);
          return null;
        },
        ping: (timestamp, _) {
          if (assignedPeerId != null) {
            _sendToPeer(
              assignedPeerId,
              SignalingMessage.pong(timestamp: timestamp),
            );
          }
          return null;
        },
        pong: (_, __) => null,
        roomClosed: (_, __) => null,
      );
    } on Object catch (e, stackTrace) {
      AppLogger.e('Error handling signaling message', e, stackTrace);
      return null;
    }
  }

  String? _routeAndReturn(String to, SignalingMessage message) {
    _routeToPeer(to, message);
    return null;
  }

  String? _processJoin(
    WebSocketChannel channel,
    String displayName,
    String code,
  ) {
    if (code != _accessCode) {
      _sendToChannel(
        channel,
        const SignalingMessage.rejected(reason: 'invalidAccessCode'),
      );
      unawaited(channel.sink.close());
      return null;
    }

    if (_participants.length >= NetworkConstants.maxParticipants) {
      _sendToChannel(
        channel,
        const SignalingMessage.rejected(reason: 'roomFull'),
      );
      unawaited(channel.sink.close());
      return null;
    }

    final isFirstPeer = _participants.isEmpty;
    _peerCounter++;
    final peerId = 'peer_$_peerCounter';

    final participant = Participant(
      id: peerId,
      displayName: displayName,
      isHost: isFirstPeer,
    );

    _participants[peerId] = participant;
    _clientChannels[peerId] = channel;

    _sendToChannel(
      channel,
      SignalingMessage.welcome(
        peerId: peerId,
        participants: _participants.values.toList(),
      ),
    );

    _broadcast(
      SignalingMessage.peerJoined(participant: participant),
      excludePeerId: peerId,
    );

    return peerId;
  }

  void _handlePeerLeft(String peerId) {
    _clientChannels.remove(peerId);
    final removed = _participants.remove(peerId);
    if (removed != null) {
      AppLogger.i('Peer left room: $peerId');
      _broadcast(SignalingMessage.peerLeft(peerId: peerId));
    }
  }

  void _routeToPeer(String to, SignalingMessage message) {
    final targetChannel = _clientChannels[to];
    if (targetChannel != null) {
      _sendToChannel(targetChannel, message);
    } else {
      AppLogger.w('Target peer not found for routing: $to');
    }
  }

  void _sendToPeer(String peerId, SignalingMessage message) {
    final channel = _clientChannels[peerId];
    if (channel != null) {
      _sendToChannel(channel, message);
    }
  }

  void _sendToChannel(WebSocketChannel channel, SignalingMessage message) {
    final payload = jsonEncode(message.toJson());
    channel.sink.add(payload);
  }

  void _broadcast(SignalingMessage message, {String? excludePeerId}) {
    final payload = jsonEncode(message.toJson());
    final snapshot = Map<String, WebSocketChannel>.from(_clientChannels);
    for (final entry in snapshot.entries) {
      if (entry.key != excludePeerId) {
        entry.value.sink.add(payload);
      }
    }
  }

  /// Detiene el servidor y cierra todas las conexiones activas.
  Future<void> stop({String reason = 'host_closed'}) async {
    if (!isRunning) return;

    _broadcast(SignalingMessage.roomClosed(reason: reason));

    final channels = List<WebSocketChannel>.from(_clientChannels.values);
    for (final channel in channels) {
      await channel.sink.close();
    }
    _clientChannels.clear();
    _participants.clear();

    await _server?.close(force: true);
    _server = null;
    AppLogger.i('Signaling server stopped');
  }

  /// Cierra streams y libera recursos.
  Future<void> dispose() async {
    await stop();
    await _messagesController.close();
  }
}
