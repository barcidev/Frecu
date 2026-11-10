# Configuración de plataforma — Frecu

## Android (`AndroidManifest.xml`)

Permisos:
- `RECORD_AUDIO`, `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`
- `CHANGE_WIFI_MULTICAST_STATE` (adquirir `MulticastLock` para mDNS)
- `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`
- `POST_NOTIFICATIONS` (Android 13+)
- `BLUETOOTH_CONNECT` (Android 12+)
- Invitar por NFC: `NFC` (normal); `android.hardware.nfc` y `android.hardware.nfc.hce` no obligatorios. Servicio `FrecuNfcHostService` (`BIND_NFC_SERVICE`, `res/xml/frecu_apdu_service.xml` con la aplicación NDEF `D2760000850101` en la categoría `other`), canal `frecu/nfc_host`. `intent-filter` `VIEW` y `NDEF_DISCOVERED` para `frecu://join` y `flutter_deeplinking_enabled` apagado (los enlaces los lee `app_links`).
- Invitar por Bluetooth: `BLUETOOTH_SCAN` con `neverForLocation` y `BLUETOOTH_ADVERTISE` (Android 12+), y `BLUETOOTH` y `BLUETOOTH_ADMIN` con `maxSdkVersion="30"`. `android.hardware.bluetooth_le` no es obligatorio. No hace falta el tipo de servicio `connectedDevice`: anunciar por BLE no lo exige.
- `WAKE_LOCK`
- `VIBRATE` (avisos de la frecu con la pantalla apagada)
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` y `FOREGROUND_SERVICE_LOCATION` (ubicación compartida, solo si se activa). Sin `maxSdkVersion`: en Android 12 o anterior, crear la red de la frecu también exige la ubicación precisa (y la ubicación encendida).
- Red de la frecu:
  - `NEARBY_WIFI_DEVICES` con `neverForLocation` (Android 13+), para crear la red con `LocalOnlyHotspot`; se pide al tocar «Crear la red».
  - `CHANGE_WIFI_STATE` y `CHANGE_NETWORK_STATE` (normales), para conectar al invitado con `WifiNetworkSpecifier` y atar la app a la red.

Mientras la frecu esté activa, corre un servicio en primer plano propio, `FrecuRoomService.kt` (canal `frecu/room_service`), de tipo `microphone`, con un bloqueo parcial de CPU para que la voz siga con la pantalla apagada. Al activar «Compartir mi ubicación» vuelve a pasar a primer plano con los tipos `microphone|location`: sin `location`, Android no da la ubicación con la pantalla apagada. Si Android no deja sumar la ubicación, sigue solo con el micrófono. Google Play pide declarar los dos tipos con un video. La red de Frecu vive en el proceso: sigue al aire mientras corre ese servicio. Cerrar la app desde recientes, o que se suelte el motor de Flutter, termina la frecu y el servicio; no se reinicia solo.

La notificación es de medios, como la de una app de música: Android la muestra como una tarjeta de reproductor en la cortina y en la pantalla bloqueada (en Android 12 o anterior, compacta en la lista). Su contenido lo arma la pantalla de la frecu (`RoomNotification`, en `room_notification.dart`) a partir de los providers, no de la pantalla, porque con la pantalla apagada Flutter no dibuja:

- **Título:** el nombre de la frecu. **Subtítulo:** lo mismo que la isla de estado. **Álbum:** la nota («Sol4»).
- **Carátula:** un PNG de 512 px que dibuja la app (`room_notification_art.dart`): la malla de 6 lugares, la firma de Frecu y la nota, con el brillo del estado o del color de quien habla. Android tiñe la tarjeta con sus colores. Cada carátula se dibuja una vez y se guarda.
- **Botones** (acciones propias de la sesión, con dibujables `ic_nt_*` copiados de `FrIcons`): micrófono (hablar y cortar en PTT, silenciarse y activarlo en micrófono abierto), salida de audio y salir (cerrar, para el anfitrión). Con un SOS sin atender: «Voy en camino», «Entendido» y salir. Mientras se conecta o reconecta, solo salir.
- **Tocarla** abre la frecu; si el anfitrión está solo, con el QR para invitar.
- La sesión está siempre «sonando» y sin play/pausa: así no aparece el botón de reproducir, que Android no deja cambiar de ícono, y Android no esconde la tarjeta por llevar minutos en pausa. El play/pausa de unos audífonos hace de botón del micrófono.
- Se actualiza como mucho una vez por segundo, sin sonido ni vibración (canal `frecu_foreground_service`, importancia baja).

Es la misma sesión de medios del botón de volumen (`FrecuMediaSession.kt`): con dos, una le quitaría las teclas a la otra.

Canales nativos de la red (en `MainActivity`): `frecu/hotspot` (`LocalHotspot.kt`: crea y apaga la red; avisa con `stopped` si Android la apaga) y `frecu/wifi` (`FrecuWifi.kt`: `route`, `join` y `release`).

## iOS (`Info.plist`)

- `NSMicrophoneUsageDescription`
- `NSLocalNetworkUsageDescription`
- `NSBonjourServices`: `_frecu._tcp`
- `NSCameraUsageDescription` (escáner QR)
- `NFCReaderUsageDescription` y `com.apple.developer.nfc.readersession.iso7816.select-identifiers` con `D2760000850101` (leer el teléfono Android del anfitrión, que hace de etiqueta tipo 4). Capacidad **NFC Tag Reading** (`com.apple.developer.nfc.readersession.formats`: `NDEF` y `TAG` en `Runner.entitlements`): hay que activarla en el App ID; no funciona en el simulador.
- `CFBundleURLTypes` con el esquema `frecu` y `FlutterDeepLinkingEnabled` en falso (los enlaces los lee `app_links`).
- `NSBluetoothAlwaysUsageDescription` (invitar por Bluetooth: buscar frecus cercanas). CoreBluetooth lo pide la primera vez que se busca; `permission_handler` no pide Bluetooth en iOS (sin `PERMISSION_BLUETOOTH`).
- `UIBackgroundModes`: `audio` y `location`
- `NSLocationWhenInUseUsageDescription` (solo «mientras se usa»; geolocator con `BYPASS_PERMISSION_LOCATION_ALWAYS=1` en el Podfile)

En iOS no hay notificación de la frecu: la voz sigue por `UIBackgroundModes` `audio` y el sistema muestra su indicador de micrófono. (Antes, el plugin del servicio en primer plano lanzaba un banner nuevo en cada cambio de estado.)

En iOS el anfitrión solo es viable con Personal Hotspot activado manualmente: iOS no deja que una app cree la red. Prioriza Android como anfitrión en la UI y en las guías.

Capacidad **Hotspot Configuration** (`Runner.entitlements`, `com.apple.developer.networking.HotspotConfiguration`, en Debug, Release y Profile): el invitado iPhone entra a la red de la frecu con `NEHotspotConfiguration` (canal `frecu/wifi` en `AppDelegate.swift`). Hay que activarla en el App ID de la cuenta de Apple (la firma automática de Xcode lo hace al compilar para un teléfono). No funciona en el simulador.

Textos de permisos en español e inglés, explicando para qué se usa cada uno.
