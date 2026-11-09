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

Mientras la frecu esté activa, corre un servicio en primer plano de tipo `microphone` con una notificación persistente que permita salir de la frecu.

## iOS (`Info.plist`)

- `NSMicrophoneUsageDescription`
- `NSLocalNetworkUsageDescription`
- `NSBonjourServices`: `_frecu._tcp`
- `NSCameraUsageDescription` (escáner QR)
- `UIBackgroundModes`: `audio`

En iOS el anfitrión solo es viable con Personal Hotspot activado manualmente. Prioriza Android como anfitrión en la UI y en las guías.

Textos de permisos en español e inglés, explicando para qué se usa cada uno.
