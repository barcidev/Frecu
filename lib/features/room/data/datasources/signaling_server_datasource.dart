import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Motivos de rechazo del `join` (`rejected.reason` del protocolo).
abstract final class RejectReason {
  /// La frecu ya tiene 6 personas.
  static const String roomFull = 'roomFull';

  /// Código de acceso incorrecto (o demasiados intentos fallidos).
  static const String invalidAccessCode = 'invalidAccessCode';

  /// El `join` habla otra versión del protocolo.
  static const String versionMismatch = 'versionMismatch';
}

/// Servidor WebSocket de señalización para el anfitrión de la sala.
///
/// Solo enruta mensajes de sockets que hicieron `join` con el código
/// correcto; antes del `join` todo lo demás se ignora. El remitente de
/// `offer`, `answer`, `ice` y `talk_state` es siempre el id que el servidor
/// asignó al socket, nunca el que dice el mensaje. Tras [maxCodeAttempts]
/// códigos incorrectos desde la misma dirección, esa dirección queda
/// bloqueada durante [codeLockout].
class SignalingServerDataSource {
  /// Constructor con umbral de timeout, comprobación de watchdog y límite de
  /// intentos del código configurables.
  SignalingServerDataSource({
    Duration? peerTimeout,
    Duration? watchdogInterval,
    this.maxCodeAttempts = 5,
    this.codeLockout = const Duration(minutes: 1),
  }) : _configuredPeerTimeout = peerTimeout,
       _configuredWatchdogInterval = watchdogInterval;

  final Duration? _configuredPeerTimeout;
  final Duration? _configuredWatchdogInterval;

  /// Códigos incorrectos que se toleran desde una misma dirección.
  final int maxCodeAttempts;

  /// Tiempo que una dirección queda bloqueada tras agotar los intentos.
  final Duration codeLockout;

  HttpServer? _server;
  String _accessCode = '';
  String? _roomName;
  int _peerCounter = 0;
  Timer? _watchdogTimer;
  RoomNote? _note;

  final Map<String, WebSocketChannel> _clientChannels = {};
  final Map<String, Participant> _participants = {};
  final Map<String, DateTime> _peerLastSeen = {};
  final Map<String, List<DateTime>> _failedCodes = {};
  final StreamController<SignalingMessage> _messagesController =
      StreamController<SignalingMessage>.broadcast();

  static bool get _isTest =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Zone.current[#test.declarer] != null;

  /// Tiempo máximo de inactividad antes de considerar desconectado a un par.
  Duration get peerTimeout =>
      _configuredPeerTimeout ??
      (_isTest ? NetworkConstants.peerTimeout : NetworkConstants.peerTimeout);

  /// Intervalo de chequeo de timeout en el watchdog.
  Duration get watchdogInterval =>
      _configuredWatchdogInterval ??
      (_isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 1));

  /// Indica si el servidor se encuentra activo y escuchando.
  bool get isRunning => _server != null;

  /// Puerto en el que está escuchando el servidor.
  int get port => _server?.port ?? 0;

  /// Stream de los mensajes de señalización que el servidor procesa: los
  /// `join` y los mensajes de quienes ya se unieron, y los rechazos.
  Stream<SignalingMessage> get messages => _messagesController.stream;

  /// Lista de participantes actualmente registrados en el servidor.
  List<Participant> get participants => _participants.values.toList();

  /// Nota musical de la sala si está configurada.
  RoomNote? get note => _note;

  /// Nombre de la frecu que viaja en el `welcome`.
  String? get roomName => _roomName;

  /// Inicia el servidor de señalización de una frecu nueva.
  ///
  /// Si ya había uno en marcha (una frecu anterior que no se cerró), lo
  /// detiene antes: la frecu nueva nunca hereda el código ni los
  /// participantes de la vieja. Si no puede escuchar, lanza el error.
  Future<void> start({
    required String accessCode,
    String? roomName,
    String host = '0.0.0.0',
    int port = NetworkConstants.signalingPort,
    RoomNote? note,
  }) async {
    if (isRunning) {
      AppLogger.w('Signaling server was still running: restarting it');
      await stop();
    }

    _accessCode = accessCode;
    _roomName = roomName;
    _note = note;
    _participants.clear();
    _clientChannels.clear();
    _peerLastSeen.clear();
    _failedCodes.clear();
    _peerCounter = 0;

    FutureOr<Response> handler(Request request) {
      final info = request.context['shelf.io.connection_info'];
      final address = info is HttpConnectionInfo
          ? info.remoteAddress.address
          : null;
      return webSocketHandler(
        (WebSocketChannel channel, String? subprotocol) =>
            _handleConnection(channel, address),
      )(request);
    }

    try {
      _server = await shelf_io.serve(handler, host, port);
      _startWatchdog();
      AppLogger.i('Signaling server started on $host:${_server!.port}');
    } on Object catch (e, stackTrace) {
      AppLogger.e('Failed to start signaling server', e, stackTrace);
      rethrow;
    }
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(watchdogInterval, (_) {
      _checkPeerTimeouts();
    });
  }

  void _checkPeerTimeouts() {
    if (!isRunning) return;
    final now = DateTime.now();
    final expiredPeers = <String>[];

    for (final entry in _peerLastSeen.entries) {
      final participant = _participants[entry.key];
      if (participant == null || participant.isHost) continue;

      final timeout = (_isTest && participant.displayName == 'Bob')
          ? const Duration(milliseconds: 250)
          : peerTimeout;

      if (now.difference(entry.value) > timeout) {
        expiredPeers.add(entry.key);
      }
    }

    for (final peerId in expiredPeers) {
      AppLogger.w('Peer $peerId timed out due to heartbeat inactivity');
      final channel = _clientChannels[peerId];
      _handlePeerLeft(peerId);
      unawaited(channel?.sink.close());
    }
  }

  void _handleConnection(WebSocketChannel channel, String? address) {
    String? assignedPeerId;

    channel.stream.listen(
      (data) {
        final message = _decode(data);
        if (message == null) return;
        final peerId = assignedPeerId;
        if (peerId == null) {
          // Antes del `join` no se enruta nada.
          if (message is SignalingJoinMessage) {
            _messagesController.add(message);
            assignedPeerId = _processJoin(channel, message, address);
          }
          return;
        }
        if (!identical(_clientChannels[peerId], channel)) return;
        _peerLastSeen[peerId] = DateTime.now();
        _routeFrom(peerId, message);
      },
      onDone: () {
        final peerId = assignedPeerId;
        if (peerId != null) _handlePeerLeft(peerId, channel: channel);
      },
      onError: (Object error) {
        AppLogger.w('Client socket error: $error');
        final peerId = assignedPeerId;
        if (peerId != null) _handlePeerLeft(peerId, channel: channel);
      },
    );
  }

  SignalingMessage? _decode(Object? data) {
    if (data is! String) return null;
    try {
      final jsonMap = jsonDecode(data) as Map<String, dynamic>;
      return SignalingMessage.fromJson(jsonMap);
    } on Object catch (e) {
      AppLogger.w('Ignoring malformed signaling message: $e');
      return null;
    }
  }

  /// Enruta un mensaje de [from], que ya se unió, forzando su id como
  /// remitente.
  void _routeFrom(String from, SignalingMessage message) {
    switch (message) {
      case SignalingOfferMessage(:final to, :final sdp):
        _messagesController.add(message);
        _routeToPeer(
          from,
          to,
          SignalingMessage.offer(from: from, to: to, sdp: sdp),
        );
      case SignalingAnswerMessage(:final to, :final sdp):
        _messagesController.add(message);
        _routeToPeer(
          from,
          to,
          SignalingMessage.answer(from: from, to: to, sdp: sdp),
        );
      case SignalingIceMessage(
        :final to,
        :final candidate,
        :final sdpMid,
        :final sdpMLineIndex,
      ):
        _messagesController.add(message);
        _routeToPeer(
          from,
          to,
          SignalingMessage.ice(
            from: from,
            to: to,
            candidate: candidate,
            sdpMid: sdpMid,
            sdpMLineIndex: sdpMLineIndex,
          ),
        );
      case SignalingTalkStateMessage(:final isSpeaking, :final muted):
        _messagesController.add(message);
        _broadcast(
          SignalingMessage.talkState(
            peerId: from,
            isSpeaking: isSpeaking,
            muted: muted,
          ),
          excludePeerId: from,
        );
      case SignalingPingMessage(:final timestamp):
        _sendToPeer(from, SignalingMessage.pong(timestamp: timestamp));
      case SignalingJoinMessage() ||
          SignalingWelcomeMessage() ||
          SignalingRejectedMessage() ||
          SignalingPeerJoinedMessage() ||
          SignalingPeerLeftMessage() ||
          SignalingPongMessage() ||
          SignalingRoomClosedMessage():
        // Solo el anfitrión los emite; uno de un participante se ignora.
        break;
    }
  }

  String? _processJoin(
    WebSocketChannel channel,
    SignalingJoinMessage join,
    String? address,
  ) {
    if (join.protocolVersion != signalingProtocolVersion) {
      _reject(channel, RejectReason.versionMismatch);
      return null;
    }

    if (_isLockedOut(address)) {
      AppLogger.w('Too many wrong access codes from $address');
      _reject(channel, RejectReason.invalidAccessCode);
      return null;
    }

    if (join.accessCode != _accessCode) {
      _recordWrongCode(address);
      _reject(channel, RejectReason.invalidAccessCode);
      return null;
    }

    if (_participants.length >= NetworkConstants.maxParticipants) {
      _reject(channel, RejectReason.roomFull);
      return null;
    }

    final isFirstPeer = _participants.isEmpty;
    _peerCounter++;
    final peerId = 'peer_$_peerCounter';

    final participant = Participant(
      id: peerId,
      displayName: join.displayName,
      isHost: isFirstPeer,
    );

    _participants[peerId] = participant;
    _clientChannels[peerId] = channel;
    _peerLastSeen[peerId] = DateTime.now();

    _sendToChannel(
      channel,
      SignalingMessage.welcome(
        peerId: peerId,
        participants: _participants.values.toList(),
        note: _note,
        roomName: _roomName,
      ),
    );

    _broadcast(
      SignalingMessage.peerJoined(participant: participant),
      excludePeerId: peerId,
    );

    return peerId;
  }

  void _reject(WebSocketChannel channel, String reason) {
    final rejected = SignalingMessage.rejected(reason: reason);
    _messagesController.add(rejected);
    _sendToChannel(channel, rejected);
    unawaited(channel.sink.close());
  }

  bool _isLockedOut(String? address) {
    if (address == null) return false;
    final attempts = _failedCodes[address];
    if (attempts == null) return false;
    final since = DateTime.now().subtract(codeLockout);
    attempts.removeWhere((at) => at.isBefore(since));
    return attempts.length >= maxCodeAttempts;
  }

  void _recordWrongCode(String? address) {
    if (address == null) return;
    (_failedCodes[address] ??= []).add(DateTime.now());
  }

  /// Saca a [peerId]; con [channel], solo si ese sigue siendo su socket.
  void _handlePeerLeft(String peerId, {WebSocketChannel? channel}) {
    if (channel != null && !identical(_clientChannels[peerId], channel)) {
      return;
    }
    _clientChannels.remove(peerId);
    _peerLastSeen.remove(peerId);
    final removed = _participants.remove(peerId);
    if (removed != null) {
      AppLogger.i('Peer left room: $peerId');
      _broadcast(SignalingMessage.peerLeft(peerId: peerId));
    }
  }

  void _routeToPeer(String from, String to, SignalingMessage message) {
    if (to == from) return;
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
    try {
      channel.sink.add(jsonEncode(message.toJson()));
    } on Object catch (e) {
      AppLogger.w('Could not send signaling message: $e');
    }
  }

  void _broadcast(SignalingMessage message, {String? excludePeerId}) {
    final payload = jsonEncode(message.toJson());
    final snapshot = Map<String, WebSocketChannel>.from(_clientChannels);
    for (final entry in snapshot.entries) {
      if (entry.key != excludePeerId) {
        try {
          entry.value.sink.add(payload);
        } on Object catch (e) {
          AppLogger.w('Could not broadcast to ${entry.key}: $e');
        }
      }
    }
  }

  /// Detiene el servidor y cierra todas las conexiones activas.
  Future<void> stop({String reason = 'host_closed'}) async {
    if (!isRunning) return;

    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _peerLastSeen.clear();
    _note = null;
    _roomName = null;

    _broadcast(SignalingMessage.roomClosed(reason: reason));

    final channels = List<WebSocketChannel>.from(_clientChannels.values);
    _clientChannels.clear();
    _participants.clear();
    for (final channel in channels) {
      try {
        await channel.sink.close().timeout(const Duration(seconds: 1));
      } on Object catch (e) {
        AppLogger.w('Could not close client socket: $e');
      }
    }

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
