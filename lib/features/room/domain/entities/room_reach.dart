/// Cómo se une el grupo a una frecu. Se elige al crearla y las dos formas
/// no se mezclan.
enum RoomReach {
  /// Todos en la misma Wi-Fi, sin internet: se entra por la IP del
  /// anfitrión (QR, mDNS, Bluetooth o NFC).
  local,

  /// Desde cualquier lugar, por el punto de encuentro en la nube: se entra
  /// con el QR o el enlace, nunca por la red local.
  internet,
}
