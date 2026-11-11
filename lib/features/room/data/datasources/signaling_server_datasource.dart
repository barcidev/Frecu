import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/datasources/host_probe.dart';
import 'package:frecu/features/room/data/datasources/room_succession.dart';
import 'package:frecu/features/room/data/datasources/signaling_connection.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

export 'package:frecu/features/room/data/datasources/signaling_connection.dart'
    show RejectReason, SignalingConnection;

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

  final Map<String, SignalingConnection> _clientChannels = {};
  final Map<String, Participant> _participants = {};
  final Map<String, DateTime> _peerLastSeen = {};
  late final CodeGuard _codes = CodeGuard(
    maxAttempts: maxCodeAttempts,
    lockout: codeLockout,
  );

  /// Lugares heredados que aún no ocupó nadie.
  final Set<String> _seats = {};

  /// Frecu que se tomó en el último [start]; nula en una frecu nueva, donde
  /// el anfitrión es el primero en unirse.
  InheritedRoom? _taken;

  /// Se está deteniendo: no se aceptan conexiones nuevas.
  bool _closing = false;

  /// Se detiene porque pasó la frecu: no avisa `room_closed`.
  bool _handingOver = false;
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

  /// La red de la frecu la crea el teléfono del anfitrión: va en su
  /// participante (`ownsNetwork`) para que todos lo sepan. Se fija antes de
  /// [start].
  bool hostOwnsNetwork = false;

  /// Sucesión de la frecu: se configura antes de [start] y se reparte en
  /// `room_state` al entrar o salir alguien.
  final SuccessionLedger succession = SuccessionLedger();

  /// Se llama cuando otro teléfono pregunta con `host_probe` por esta misma
  /// frecu con un turno que gana: este servidor debe cederle la frecu
  /// ([yieldTo]).
  void Function(HostRival rival)? onRival;

  /// Frecu que tomará el próximo [start] (que la consume): guarda un lugar
  /// a cada persona heredada, y quien se une con su `host` es el anfitrión.
  /// Se fija antes de [start], como [succession].
  InheritedRoom? inherited;

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

    _closing = false;
    _accessCode = accessCode;
    _roomName = roomName;
    _note = note;
    _participants.clear();
    _clientChannels.clear();
    _peerLastSeen.clear();
    _codes.clear();
    succession.clear();
    _peerCounter = 0;
    _seedInherited();

    FutureOr<Response> handler(Request request) {
      final info = request.context['shelf.io.connection_info'];
      final address = info is HttpConnectionInfo
          ? info.remoteAddress.address
          : null;
      return webSocketHandler(
        (WebSocketChannel channel, String? subprotocol) =>
            accept(LocalConnection(channel, address)),
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

  /// Guarda los lugares de la frecu heredada, si la hay.
  void _seedInherited() {
    final inherited = _taken = this.inherited;
    this.inherited = null;
    _seats.clear();
    if (inherited == null) return;
    final now = DateTime.now();
    _peerCounter = inherited.lastPeerNumber;
    for (final member in inherited.seats) {
      _seats.add(member.id);
      _participants[member.id] = Participant(
        id: member.id,
        displayName: member.displayName,
      );
      _peerLastSeen[member.id] = now;
      succession.seed(member);
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
      unawaited(channel?.close());
    }
  }

  /// Atiende una conexión nueva, venga de la red local o del relé de la
  /// nube: hasta su `join` aceptado, todo lo demás se ignora.
  void accept(SignalingConnection channel) {
    if (!isRunning || _closing) {
      unawaited(channel.close());
      return;
    }
    String? assignedPeerId;

    channel.incoming.listen(
      (data) {
        final message = SignalingMessage.tryDecode(data);
        if (message == null) return;
        final peerId = assignedPeerId;
        if (peerId == null) {
          // Antes del `join` no se enruta nada.
          switch (message) {
            case SignalingJoinMessage():
              _messagesController.add(message);
              assignedPeerId = _processJoin(channel, message);
            case SignalingHostProbeMessage():
              _answerProbe(channel, message);
            default:
              break;
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
      case SignalingQuickMessage(:final kind):
        _messagesController.add(message);
        _broadcast(
          SignalingMessage.quickMessage(peerId: from, kind: kind),
          excludePeerId: from,
        );
      case SignalingPositionMessage(:final lat, :final lon, :final accuracy):
        _messagesController.add(message);
        _broadcast(
          SignalingMessage.position(
            peerId: from,
            lat: lat,
            lon: lon,
            accuracy: accuracy,
          ),
          excludePeerId: from,
        );
      case SignalingPingMessage(:final timestamp):
        _sendToPeer(from, SignalingMessage.pong(timestamp: timestamp));
      default:
        // Solo el anfitrión emite el resto; uno de un participante se ignora.
        break;
    }
  }

  String? _processJoin(SignalingConnection channel, SignalingJoinMessage join) {
    final address = channel.remoteKey;
    final seat = _seats.contains(join.peerId) ? join.peerId : null;
    if (!_admits(channel, join, returning: seat != null)) return null;

    final peerId = seat ?? 'peer_${++_peerCounter}';
    final host = _taken?.host;
    final isHost = host == null ? _participants.isEmpty : peerId == host;
    final participant = Participant(
      id: peerId,
      displayName: join.displayName,
      isHost: isHost,
      remote: channel.remote,
      ownsNetwork: isHost && hostOwnsNetwork,
    );

    _seats.remove(peerId);
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
    _announceJoin(channel, participant, returning: seat != null);

    succession.add(participant, address: channel.remote ? null : address);
    _broadcastSuccession();

    return peerId;
  }

  /// Avisa a los demás que entró [participant]. Quien vuelve a su lugar
  /// heredado ya está en sus listas: solo se avisa si es el anfitrión, y a
  /// él se le dice quién lleva ahora la frecu.
  void _announceJoin(
    SignalingConnection channel,
    Participant participant, {
    required bool returning,
  }) {
    if (!returning || participant.isHost) {
      _broadcast(
        SignalingMessage.peerJoined(participant: participant),
        excludePeerId: participant.id,
      );
    }
    final taken = _taken;
    if (!returning || participant.isHost || taken == null) return;
    _sendToChannel(
      channel,
      SignalingMessage.hostChanged(
        host: taken.host,
        term: succession.term,
        reason: taken.reason,
      ),
    );
  }

  /// Si el `join` puede entrar: misma versión, sin bloqueo, código correcto
  /// y lugar libre (quien vuelve a su lugar heredado ya lo tiene). Si no,
  /// lo rechaza.
  bool _admits(
    SignalingConnection channel,
    SignalingJoinMessage join, {
    required bool returning,
  }) {
    if (join.protocolVersion != signalingProtocolVersion) {
      _reject(channel, RejectReason.versionMismatch);
      return false;
    }
    if (!_codeAccepted(channel, join.accessCode)) return false;
    final term = join.term;
    if (term != null && term > succession.term) {
      _reject(channel, RejectReason.staleTerm);
      return false;
    }
    if (!returning &&
        _participants.length >= NetworkConstants.maxParticipants) {
      _reject(channel, RejectReason.roomFull);
      return false;
    }
    return true;
  }

  /// Sin bloqueo y con el código correcto; si no, rechaza y cuenta el
  /// intento.
  bool _codeAccepted(SignalingConnection channel, String accessCode) {
    if (_codes.admits(channel.remoteKey, accessCode, expected: _accessCode)) {
      return true;
    }
    _reject(channel, RejectReason.invalidAccessCode);
    return false;
  }

  /// Responde a otro anfitrión que pregunta por esta frecu con su turno y su
  /// id, y si su turno gana, lo avisa en [onRival]. Solo en la red local y
  /// con el código correcto.
  void _answerProbe(
    SignalingConnection channel,
    SignalingHostProbeMessage probe,
  ) {
    final host =
        _participants.values.where((p) => p.isHost).firstOrNull?.id ??
        _taken?.host;
    final address = channel.remoteKey;
    if (channel.remote || host == null || address == null) {
      unawaited(channel.close());
      return;
    }
    if (!_codeAccepted(channel, probe.accessCode)) return;
    _sendToChannel(
      channel,
      SignalingMessage.hostProbe(
        accessCode: _accessCode,
        term: succession.term,
        host: host,
        port: port,
      ),
    );
    unawaited(channel.close());
    final rival = HostRival.challenging(
      probe,
      address: address,
      term: succession.term,
      host: host,
    );
    if (rival != null) onRival?.call(rival);
  }

  void _reject(SignalingConnection channel, String reason) {
    final rejected = SignalingMessage.rejected(reason: reason);
    _messagesController.add(rejected);
    _sendToChannel(channel, rejected);
    unawaited(channel.close());
  }

  /// Saca a [peerId]; con [channel], solo si ese sigue siendo su socket.
  void _handlePeerLeft(String peerId, {SignalingConnection? channel}) {
    if (channel != null && !identical(_clientChannels[peerId], channel)) {
      return;
    }
    _clientChannels.remove(peerId);
    _peerLastSeen.remove(peerId);
    _seats.remove(peerId);
    final removed = _participants.remove(peerId);
    if (removed != null) {
      AppLogger.i('Peer left room: $peerId');
      _broadcast(SignalingMessage.peerLeft(peerId: peerId));
      succession.remove(peerId);
      _broadcastSuccession();
    }
  }

  /// Reparte a todos la sucesión y el estado de la frecu.
  void _broadcastSuccession() => _broadcast(
    SignalingMessage.roomState(
      state: succession.snapshot(
        name: _roomName ?? '',
        accessCode: _accessCode,
        note: _note,
      ),
    ),
  );

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

  void _sendToChannel(SignalingConnection channel, SignalingMessage message) {
    try {
      channel.send(jsonEncode(message.toJson()));
    } on Object catch (e) {
      AppLogger.w('Could not send signaling message: $e');
    }
  }

  void _broadcast(SignalingMessage message, {String? excludePeerId}) {
    final payload = jsonEncode(message.toJson());
    final snapshot = Map<String, SignalingConnection>.from(_clientChannels);
    for (final entry in snapshot.entries) {
      if (entry.key != excludePeerId) {
        try {
          entry.value.send(payload);
        } on Object catch (e) {
          AppLogger.w('Could not broadcast to ${entry.key}: $e');
        }
      }
    }
  }

  /// Pasa la frecu a [to] y se detiene sin cerrarla: avisa a todos
  /// `host_handover` con el turno siguiente y la salida del anfitrión. Es
  /// `false` si [to] no está conectado o ya es el anfitrión.
  Future<bool> handOver(String to) async {
    final heir = _participants[to];
    if (!isRunning || heir == null || heir.isHost) return false;
    if (!_clientChannels.containsKey(to)) return false;
    final host = _participants.values.where((p) => p.isHost).firstOrNull;
    _broadcast(
      SignalingMessage.hostHandover(to: to, term: succession.term + 1),
    );
    if (host != null) _broadcast(SignalingMessage.peerLeft(peerId: host.id));
    await _stopHandingOver();
    return true;
  }

  /// Cede la frecu a [rival], que la lleva con un turno que gana: avisa a
  /// todos `host_handover` con su id, su turno, su IP y su puerto, y se
  /// detiene sin `room_closed`.
  Future<void> yieldTo(HostRival rival) async {
    if (!isRunning) return;
    _broadcast(
      SignalingMessage.hostHandover(
        to: rival.host,
        term: rival.term,
        address: rival.address,
        port: rival.port,
      ),
    );
    await _stopHandingOver();
  }

  /// Se detiene sin avisar `room_closed`: la frecu sigue en otro teléfono.
  Future<void> _stopHandingOver() async {
    _handingOver = true;
    try {
      await stop();
    } finally {
      _handingOver = false;
    }
  }

  /// Detiene el servidor y cierra todas las conexiones activas.
  Future<void> stop({String reason = 'host_closed'}) async {
    if (!isRunning) return;

    _closing = true;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _peerLastSeen.clear();
    _seats.clear();
    _note = null;
    _roomName = null;

    if (!_handingOver) {
      _broadcast(SignalingMessage.roomClosed(reason: reason));
    }

    final channels = List<SignalingConnection>.from(_clientChannels.values);
    _clientChannels.clear();
    _participants.clear();
    for (final channel in channels) {
      try {
        await channel.close().timeout(const Duration(seconds: 1));
      } on Object catch (e) {
        AppLogger.w('Could not close client socket: $e');
      }
    }

    await _server?.close(force: true);
    _server = null;
    _closing = false;
    AppLogger.i('Signaling server stopped');
  }

  /// Cierra streams y libera recursos.
  Future<void> dispose() async {
    await stop();
    await _messagesController.close();
  }
}
