# Configuración de plataforma — Frecu

## Android (`AndroidManifest.xml`)

Permisos:
- `RECORD_AUDIO`, `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`
- `CHANGE_WIFI_MULTICAST_STATE` (adquirir `MulticastLock` para mDNS)
- `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`
- `POST_NOTIFICATIONS` (Android 13+)
- `BLUETOOTH_CONNECT` (Android 12+)
- `WAKE_LOCK`
- `VIBRATE` (avisos de la frecu con la pantalla apagada)
- Red de la frecu:
  - `NEARBY_WIFI_DEVICES` con `neverForLocation` (Android 13+), para crear la red con `LocalOnlyHotspot`; se pide al tocar «Crear la red».
  - `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION` con `maxSdkVersion="32"`: en Android 12 o anterior, crear la red exige la ubicación precisa, y la ubicación encendida. Si otra función necesita la ubicación en Android 13+, hay que quitar el `maxSdkVersion`.
  - `CHANGE_WIFI_STATE` y `CHANGE_NETWORK_STATE` (normales), para conectar al invitado con `WifiNetworkSpecifier` y atar la app a la red.

Mientras la frecu esté activa, corre un servicio en primer plano de tipo `microphone` con una notificación persistente que permita salir de la frecu. La red de Frecu vive en el proceso: sigue al aire mientras corre ese servicio.

Canales nativos de la red (en `MainActivity`): `frecu/hotspot` (`LocalHotspot.kt`: crea y apaga la red; avisa con `stopped` si Android la apaga) y `frecu/wifi` (`FrecuWifi.kt`: `route`, `join` y `release`).

## iOS (`Info.plist`)

- `NSMicrophoneUsageDescription`
- `NSLocalNetworkUsageDescription`
- `NSBonjourServices`: `_frecu._tcp`
- `NSCameraUsageDescription` (escáner QR)
- `UIBackgroundModes`: `audio`

En iOS el anfitrión solo es viable con Personal Hotspot activado manualmente: iOS no deja que una app cree la red. Prioriza Android como anfitrión en la UI y en las guías.

Capacidad **Hotspot Configuration** (`Runner.entitlements`, `com.apple.developer.networking.HotspotConfiguration`, en Debug, Release y Profile): el invitado iPhone entra a la red de la frecu con `NEHotspotConfiguration` (canal `frecu/wifi` en `AppDelegate.swift`). Hay que activarla en el App ID de la cuenta de Apple (la firma automática de Xcode lo hace al compilar para un teléfono). No funciona en el simulador.

Textos de permisos en español e inglés, explicando para qué se usa cada uno.
