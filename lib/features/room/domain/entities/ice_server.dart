/// Un servidor STUN o TURN para que la voz cruce el NAT en una frecu por
/// internet. En la red local no hace falta ninguno.
final class IceServer {
  /// Crea un servidor con sus [urls] y, si es TURN, sus credenciales.
  const IceServer({required this.urls, this.username, this.credential});

  /// STUN público de Cloudflare: gratis y sin credenciales.
  static const IceServer cloudflareStun = IceServer(
    urls: ['stun:stun.cloudflare.com:3478'],
  );

  /// Direcciones `stun:`, `turn:` o `turns:` del servidor.
  final List<String> urls;

  /// Usuario TURN (credencial que vence).
  final String? username;

  /// Clave TURN.
  final String? credential;
}
