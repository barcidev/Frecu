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
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` y `FOREGROUND_SERVICE_LOCATION` (ubicación compartida, solo si se activa)

Mientras la frecu esté activa, corre un servicio en primer plano de tipo `microphone` con una notificación persistente que permita salir de la frecu. Al activar «Compartir mi ubicación» se reinicia con los tipos `microphone|location`: Android solo fija los tipos al arrancar y sin `location` no da la ubicación con la pantalla apagada. Google Play pide declarar los dos tipos con un video.

## iOS (`Info.plist`)

- `NSMicrophoneUsageDescription`
- `NSLocalNetworkUsageDescription`
- `NSBonjourServices`: `_frecu._tcp`
- `NSCameraUsageDescription` (escáner QR)
- `UIBackgroundModes`: `audio` y `location`
- `NSLocationWhenInUseUsageDescription` (solo «mientras se usa»; geolocator con `BYPASS_PERMISSION_LOCATION_ALWAYS=1` en el Podfile)

En iOS el anfitrión solo es viable con Personal Hotspot activado manualmente. Prioriza Android como anfitrión en la UI y en las guías.

Textos de permisos en español e inglés, explicando para qué se usa cada uno.
