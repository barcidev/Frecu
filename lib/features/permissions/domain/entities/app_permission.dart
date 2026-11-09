/// Permisos de sistema utilizados por la aplicación.
enum AppPermission {
  /// Acceso al micrófono para captura de audio.
  microphone,

  /// Acceso a la cámara para escaneo de códigos QR.
  camera,

  /// Permiso para enviar notificaciones al usuario.
  notification,

  /// Permiso para conexión con periféricos Bluetooth cercanos.
  bluetoothConnect,

  /// Ubicación mientras se usa la app, para compartirla con la frecu. Se
  /// pide solo al activar «Compartir mi ubicación».
  location,
}

/// Estado de resolución de un permiso de sistema.
enum AppPermissionStatus {
  /// El permiso ha sido concedido por el usuario.
  granted,

  /// El permiso fue denegado por el usuario.
  denied,

  /// El permiso fue denegado permanentemente (requiere ir a ajustes).
  permanentlyDenied,

  /// El permiso está restringido por políticas del sistema o control parental.
  restricted,

  /// El permiso ha sido concedido con acceso limitado.
  limited,

  /// El permiso ha sido otorgado de manera provisional.
  provisional,
}
