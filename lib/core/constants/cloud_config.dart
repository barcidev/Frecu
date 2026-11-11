import 'dart:math';

/// Configuración del modo internet (punto de encuentro en Cloudflare).
///
/// La URL del Worker entra al compilar con
/// `--dart-define=FRECU_CLOUD_URL=https://…`. Sin ella, el modo internet no
/// está disponible y la app funciona solo en la red local.
class CloudConfig {
  /// Crea la configuración con la URL base del Worker (`https://…`).
  const CloudConfig(this.baseUrl);

  /// La configuración que trae la compilación.
  static const CloudConfig fromEnvironment = CloudConfig(
    String.fromEnvironment('FRECU_CLOUD_URL'),
  );

  /// Sin punto de encuentro: solo red local.
  static const CloudConfig disabled = CloudConfig('');

  /// URL base del Worker, sin barra final; vacía si no hay modo internet.
  final String baseUrl;

  /// Si hay punto de encuentro configurado.
  bool get isEnabled => baseUrl.isNotEmpty;

  Uri get _base {
    final trimmed = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse(trimmed);
  }

  Uri _socket(String path, [Map<String, String>? query]) {
    final base = _base;
    return base.replace(
      scheme: base.scheme == 'http' ? 'ws' : 'wss',
      path: '${base.path}$path',
      queryParameters: query,
    );
  }

  /// WebSocket del anfitrión de la frecu [roomId].
  Uri hostSocket(String roomId, String secret) =>
      _socket('/rooms/$roomId/host', {'secret': secret});

  /// WebSocket de un invitado a la frecu [roomId].
  Uri guestSocket(String roomId) => _socket('/rooms/$roomId/guest');

  /// Endpoint que emite credenciales TURN para la frecu [roomId].
  Uri turnCredentials(String roomId) =>
      _base.replace(path: '${_base.path}/rooms/$roomId/turn');

  /// Enlace https para invitar a la frecu [roomId] (el código va en el
  /// fragmento, que no llega al Worker).
  Uri inviteLink(String roomId, Map<String, String> fragment) => _base.replace(
    path: '${_base.path}/j/$roomId',
    fragment: Uri(queryParameters: fragment).query,
  );

  /// Id nuevo de frecu por internet: 128 bits en hexadecimal.
  static String newRoomId([Random? random]) => _hex(16, random);

  /// Secreto nuevo del anfitrión: 128 bits en hexadecimal.
  static String newHostSecret([Random? random]) => _hex(16, random);

  /// Si [value] tiene la forma de un id de frecu por internet.
  static bool isRoomId(String value) =>
      RegExp(r'^[0-9a-f]{32}$').hasMatch(value);

  static String _hex(int bytes, Random? random) {
    final source = random ?? Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < bytes; i++) {
      buffer.write(source.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
