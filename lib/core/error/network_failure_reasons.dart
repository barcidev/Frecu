/// Por qué no se pudo crear la red de la frecu (la zona Wi-Fi local que
/// crea Frecu en Android con `LocalOnlyHotspot`).
enum HotspotFailureReason {
  /// Este teléfono no puede crear la red: no es Android o es Android 7.
  unsupported,

  /// Falta el permiso de dispositivos cercanos (Android 13 o posterior).
  nearbyDenied,

  /// Falta el permiso de ubicación precisa (Android 12 o anterior).
  locationDenied,

  /// La ubicación está apagada: Android 12 o anterior la exige para crear
  /// la red.
  locationOff,

  /// La zona Wi-Fi de Ajustes está encendida y Android no deja las dos
  /// redes a la vez.
  hotspotOn,

  /// Cualquier otro fallo de Android (sin canal, bloqueada por política…).
  failed,
}

/// Por qué el teléfono no entró a la red de la frecu desde la app.
enum WifiJoinFailureReason {
  /// El teléfono no puede conectarse solo: Android 9 o anterior.
  unsupported,

  /// Se canceló el aviso del sistema (o, en Android, la red no apareció en
  /// él).
  declined,

  /// El teléfono no encontró la red o, ya en ella, no alcanza al anfitrión.
  notFound,

  /// Cualquier otro fallo del sistema.
  failed,
}
