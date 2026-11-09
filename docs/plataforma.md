# Configuración de plataforma — Frecu

## Android (`AndroidManifest.xml`)

Permisos:
- `RECORD_AUDIO`, `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`
- `CHANGE_WIFI_MULTICAST_STATE` (adquirir `MulticastLock` para mDNS)
- `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`
- `POST_NOTIFICATIONS` (Android 13+)
- `BLUETOOTH_CONNECT` (Android 12+)
- Invitar por Bluetooth: `BLUETOOTH_SCAN` con `neverForLocation` y `BLUETOOTH_ADVERTISE` (Android 12+), y `BLUETOOTH` y `BLUETOOTH_ADMIN` con `maxSdkVersion="30"`. `android.hardware.bluetooth_le` no es obligatorio. No hace falta el tipo de servicio `connectedDevice`: anunciar por BLE no lo exige.
- `WAKE_LOCK`
- `VIBRATE` (avisos de la frecu con la pantalla apagada)
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` y `FOREGROUND_SERVICE_LOCATION` (ubicación compartida, solo si se activa). Sin `maxSdkVersion`: en Android 12 o anterior, crear la red de la frecu también exige la ubicación precisa (y la ubicación encendida).
- Red de la frecu:
  - `NEARBY_WIFI_DEVICES` con `neverForLocation` (Android 13+), para crear la red con `LocalOnlyHotspot`; se pide al tocar «Crear la red».
  - `CHANGE_WIFI_STATE` y `CHANGE_NETWORK_STATE` (normales), para conectar al invitado con `WifiNetworkSpecifier` y atar la app a la red.

Mientras la frecu esté activa, corre un servicio en primer plano de tipo `microphone` con una notificación persistente que permita salir de la frecu. Al activar «Compartir mi ubicación» se reinicia con los tipos `microphone|location`: Android solo fija los tipos al arrancar y sin `location` no da la ubicación con la pantalla apagada. Google Play pide declarar los dos tipos con un video. La red de Frecu vive en el proceso: sigue al aire mientras corre ese servicio.

Canales nativos de la red (en `MainActivity`): `frecu/hotspot` (`LocalHotspot.kt`: crea y apaga la red; avisa con `stopped` si Android la apaga) y `frecu/wifi` (`FrecuWifi.kt`: `route`, `join` y `release`).

## iOS (`Info.plist`)

- `NSMicrophoneUsageDescription`
- `NSLocalNetworkUsageDescription`
- `NSBonjourServices`: `_frecu._tcp`
- `NSCameraUsageDescription` (escáner QR)
- `NSBluetoothAlwaysUsageDescription` (invitar por Bluetooth: buscar frecus cercanas). CoreBluetooth lo pide la primera vez que se busca; `permission_handler` no pide Bluetooth en iOS (sin `PERMISSION_BLUETOOTH`).
- `UIBackgroundModes`: `audio` y `location`
- `NSLocationWhenInUseUsageDescription` (solo «mientras se usa»; geolocator con `BYPASS_PERMISSION_LOCATION_ALWAYS=1` en el Podfile)

En iOS el anfitrión solo es viable con Personal Hotspot activado manualmente: iOS no deja que una app cree la red. Prioriza Android como anfitrión en la UI y en las guías.

Capacidad **Hotspot Configuration** (`Runner.entitlements`, `com.apple.developer.networking.HotspotConfiguration`, en Debug, Release y Profile): el invitado iPhone entra a la red de la frecu con `NEHotspotConfiguration` (canal `frecu/wifi` en `AppDelegate.swift`). Hay que activarla en el App ID de la cuenta de Apple (la firma automática de Xcode lo hace al compilar para un teléfono). No funciona en el simulador.

Textos de permisos en español e inglés, explicando para qué se usa cada uno.
