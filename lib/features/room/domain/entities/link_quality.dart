/// Calidad del enlace de voz con un participante remoto.
enum LinkQuality {
  /// La voz llega bien.
  good,

  /// La voz llega con pérdidas o mucho retraso: suele ser que la persona se
  /// está alejando del alcance de la red.
  weak,
}
