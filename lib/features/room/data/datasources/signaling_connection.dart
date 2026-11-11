import 'package:frecu/core/logging/app_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Una conexión de un participante con el servidor de señalización, sea cual
/// sea su transporte: un WebSocket de la red local o un invitado que llega
/// por el relé de la nube.
abstract interface class SignalingConnection {
  /// Mensajes de texto que manda el participante; termina al cerrarse.
  Stream<Object?> get incoming;

  /// Clave del origen para el bloqueo por códigos incorrectos (la IP en la
  /// red local, un resumen de la IP por internet), o `null` si no se conoce.
  String? get remoteKey;

  /// Si llega por internet (el relé de la nube) y no por la red local.
  bool get remote;

  /// Manda un mensaje de texto al participante.
  void send(String data);

  /// Cierra la conexión.
  Future<void> close();
}

/// [SignalingConnection] sobre un WebSocket aceptado por el servidor local.
class LocalConnection implements SignalingConnection {
  /// Envuelve [_channel], que llega desde [remoteKey].
  LocalConnection(this._channel, this.remoteKey);

  final WebSocketChannel _channel;

  @override
  final String? remoteKey;

  @override
  bool get remote => false;

  @override
  Stream<Object?> get incoming => _channel.stream;

  @override
  void send(String data) => _channel.sink.add(data);

  @override
  Future<void> close() async => _channel.sink.close();
}

/// Motivos de rechazo del `join` (`rejected.reason` del protocolo).
abstract final class RejectReason {
  /// La frecu ya tiene 6 personas.
  static const String roomFull = 'roomFull';

  /// Código de acceso incorrecto (o demasiados intentos fallidos).
  static const String invalidAccessCode = 'invalidAccessCode';

  /// El `join` habla otra versión del protocolo.
  static const String versionMismatch = 'versionMismatch';

  /// El `join` conoce un turno mayor que el de este servidor: otra persona
  /// ya tomó la frecu.
  static const String staleTerm = 'stale_term';
}

/// Bloqueo por códigos incorrectos: tras [maxAttempts] desde una misma
/// dirección en [lockout], esa dirección queda bloqueada hasta que pase.
class CodeGuard {
  /// Crea el bloqueo con su umbral y su duración.
  CodeGuard({required this.maxAttempts, required this.lockout});

  /// Códigos incorrectos que se toleran desde una misma dirección.
  final int maxAttempts;

  /// Tiempo que una dirección queda bloqueada tras agotar los intentos.
  final Duration lockout;

  final Map<String, List<DateTime>> _failed = {};

  /// Si [address] no está bloqueada y trae el código [expected]; si trae
  /// otro, cuenta el intento.
  bool admits(String? address, String code, {required String expected}) {
    if (_isLockedOut(address)) {
      AppLogger.w('Too many wrong access codes from $address');
      return false;
    }
    if (code == expected) return true;
    if (address != null) (_failed[address] ??= []).add(DateTime.now());
    return false;
  }

  /// Olvida los intentos (frecu nueva).
  void clear() => _failed.clear();

  bool _isLockedOut(String? address) {
    if (address == null) return false;
    final attempts = _failed[address];
    if (attempts == null) return false;
    final since = DateTime.now().subtract(lockout);
    attempts.removeWhere((at) => at.isBefore(since));
    return attempts.length >= maxAttempts;
  }
}
