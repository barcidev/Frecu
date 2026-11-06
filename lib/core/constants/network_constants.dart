/// Constantes globales de red y protocolo de señalización para Frecu.
abstract final class NetworkConstants {
  /// Puerto del servidor WebSocket de señalización en el anfitrión.
  static const int signalingPort = 47800;

  /// Tipo de servicio mDNS para descubrimiento en la red local.
  static const String mdnsServiceType = '_frecu._tcp';

  /// Límite máximo de participantes permitidos en topología mesh.
  static const int maxParticipants = 6;

  /// Intervalo entre pulsos de heartbeat (ping/pong).
  static const Duration heartbeatInterval = Duration(seconds: 5);

  /// Timeout tras el cual un participante sin heartbeat se considera perdido.
  static const Duration peerTimeout = Duration(seconds: 15);

  /// Tope máximo para la espera de reconexión con backoff exponencial.
  static const Duration maxReconnectBackoff = Duration(seconds: 15);
}
