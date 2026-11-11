import 'dart:async';
import 'dart:convert';

import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/network/network_return.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Relé del anfitrión con el punto de encuentro en la nube.
///
/// El anfitrión abre un WebSocket con el Durable Object de su frecu. El
/// relé le avisa de cada invitado con sobres `{t:'open',c,k}`,
/// `{t:'msg',c,d}` y `{t:'close',c}`, y cada invitado llega al servidor de
/// señalización como una [SignalingConnection] más, igual que uno de la red
/// local. Si el socket se cae, cierra a todos sus invitados y vuelve a
/// conectar con espera creciente mientras la frecu siga abierta.
class CloudRelayDataSource {
  /// Crea el relé; [channelFactory] permite inyectar un canal en pruebas.
  CloudRelayDataSource({
    WebSocketChannel Function(Uri uri)? channelFactory,
    this.connectTimeout = const Duration(seconds: 5),
    this.reconnectBaseDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 15),
    NetworkReturnWatcher? networkWatcher,
  }) : _channelFactory = channelFactory ?? WebSocketChannel.connect,
       _networkReturn = networkWatcher ?? NetworkReturnWatcher();

  final WebSocketChannel Function(Uri uri) _channelFactory;

  /// Adelanta la espera de reconexión si el teléfono recupera la red.
  final NetworkReturnWatcher _networkReturn;

  /// Espera máxima para abrir el socket.
  final Duration connectTimeout;

  /// Primera espera antes de reconectar.
  final Duration reconnectBaseDelay;

  /// Espera máxima entre reconexiones.
  final Duration maxReconnectDelay;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Uri? _uri;
  void Function(SignalingConnection connection)? _onGuest;
  int _attempt = 0;
  int _generation = 0;
  final Map<String, _RelayConnection> _guests = {};
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Si el relé está conectado con la nube.
  bool get isConnected => _channel != null;

  /// Cambios de conexión con la nube.
  Stream<bool> get connectionState => _connectionController.stream;

  /// Abre el relé en [uri] y entrega cada invitado a [onGuest].
  ///
  /// Lanza el error si la primera conexión falla; las siguientes caídas se
  /// reintentan solas hasta [stop].
  Future<void> start(
    Uri uri, {
    required void Function(SignalingConnection connection) onGuest,
  }) async {
    await stop();
    _uri = uri;
    _onGuest = onGuest;
    _attempt = 0;
    await _connect(++_generation);
  }

  Future<void> _connect(int generation) async {
    final uri = _uri;
    if (uri == null) return;
    final channel = _channelFactory(uri);
    try {
      await channel.ready.timeout(connectTimeout);
    } on Object {
      unawaited(channel.sink.close());
      rethrow;
    }
    if (generation != _generation) {
      unawaited(channel.sink.close());
      return;
    }
    _channel = channel;
    _attempt = 0;
    _connectionController.add(true);
    AppLogger.i('Cloud relay connected');
    _subscription = channel.stream.listen(
      _onEnvelope,
      onDone: () => _onDropped(channel, generation),
      onError: (Object error) {
        AppLogger.w('Cloud relay error: $error');
        _onDropped(channel, generation);
      },
    );
  }

  void _onEnvelope(dynamic data) {
    if (data is! String) return;
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(data) as Map<String, dynamic>;
    } on Object {
      return;
    }
    final id = envelope['c'];
    if (id is! String) return;
    switch (envelope['t']) {
      case 'open':
        final key = envelope['k'];
        final guest = _RelayConnection(this, id, key is String ? key : null);
        _guests[id]?._end();
        _guests[id] = guest;
        _onGuest?.call(guest);
      case 'msg':
        final payload = envelope['d'];
        if (payload is String) _guests[id]?._receive(payload);
      case 'close':
        _guests.remove(id)?._end();
    }
  }

  void _onDropped(WebSocketChannel channel, int generation) {
    if (!identical(_channel, channel)) return;
    _channel = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _endGuests();
    _connectionController.add(false);
    if (generation != _generation || _uri == null) return;
    AppLogger.w('Cloud relay dropped: reconnecting');
    _scheduleReconnect(generation);
  }

  void _scheduleReconnect(int generation) {
    final factor = 1 << _attempt.clamp(0, 4);
    final delay = reconnectBaseDelay * factor;
    _attempt++;
    unawaited(
      _reconnectAfter(
        delay > maxReconnectDelay ? maxReconnectDelay : delay,
        generation,
      ),
    );
  }

  /// Espera [delay], o menos si vuelve la red, y vuelve a conectar.
  Future<void> _reconnectAfter(Duration delay, int generation) async {
    await _networkReturn.wait(
      delay,
      cancelled: () => generation != _generation,
    );
    if (generation != _generation) return;
    try {
      await _connect(generation);
    } on Object catch (e) {
      AppLogger.w('Cloud relay reconnect failed: $e');
      if (generation == _generation) _scheduleReconnect(generation);
    }
  }

  void _send(Map<String, String> envelope) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(envelope));
    } on Object catch (e) {
      AppLogger.w('Could not send through cloud relay: $e');
    }
  }

  void _endGuests() {
    final guests = List<_RelayConnection>.from(_guests.values);
    _guests.clear();
    for (final guest in guests) {
      guest._end();
    }
  }

  /// Cierra el relé y a todos sus invitados; no vuelve a conectar.
  Future<void> stop() async {
    _generation++;
    _uri = null;
    _onGuest = null;
    _endGuests();
    final channel = _channel;
    _channel = null;
    await _subscription?.cancel();
    _subscription = null;
    if (channel != null) {
      _connectionController.add(false);
      try {
        await channel.sink.close().timeout(const Duration(seconds: 1));
      } on Object catch (e) {
        AppLogger.w('Could not close cloud relay: $e');
      }
    }
  }

  /// Cierra el relé y libera sus streams.
  Future<void> dispose() async {
    await stop();
    await _connectionController.close();
  }
}

/// Un invitado que llega por el relé de la nube.
class _RelayConnection implements SignalingConnection {
  _RelayConnection(this._relay, this._id, this.remoteKey);

  final CloudRelayDataSource _relay;
  final String _id;
  final StreamController<Object?> _incoming = StreamController<Object?>();

  @override
  final String? remoteKey;

  @override
  bool get remote => true;

  @override
  Stream<Object?> get incoming => _incoming.stream;

  @override
  void send(String data) {
    if (_incoming.isClosed) return;
    _relay._send({'t': 'msg', 'c': _id, 'd': data});
  }

  @override
  Future<void> close() async {
    if (_incoming.isClosed) return;
    _relay._send({'t': 'close', 'c': _id});
    if (identical(_relay._guests[_id], this)) _relay._guests.remove(_id);
    _end();
  }

  void _receive(String data) {
    if (!_incoming.isClosed) _incoming.add(data);
  }

  void _end() {
    if (!_incoming.isClosed) unawaited(_incoming.close());
  }
}
