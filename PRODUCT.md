# Frecu

## Qué es

Frecu convierte varios teléfonos en un intercomunicador de voz grupal que funciona sin internet. Un teléfono actúa como anfitrión: crea la red Wi-Fi del grupo (en Android, Frecu la crea; si no, comparte su punto de acceso) y crea una frecu (sala). Los demás teléfonos se conectan a esa red, se unen a la frecu y hablan entre todos en tiempo real.

Con señal, la frecu también puede abrirse **por internet**: quien está lejos se une con un enlace o el QR, sin servidor propio (punto de encuentro, STUN y TURN en Cloudflare). Una frecu por internet acepta a la vez a quien está cerca en la red local.

## Para quién

Para grupos de personas como caravanas de motos, senderistas, ciclistas o equipos de trabajo que necesitan comunicarse por voz en tiempo real sin depender de conexión a internet ni cobertura celular.

## Alcance del MVP

- Crear una frecu como anfitrión y unirse como participante.
- Red de la frecu creada desde la app en Android (`LocalOnlyHotspot`): el QR lleva la red y su clave, y el invitado entra con un escaneo. En iPhone, o si el anfitrión lo prefiere, se usa el punto de acceso manual con la guía.
- Descubrimiento automático en la red local (mDNS) y unión por código QR como respaldo.
- Voz grupal de hasta 6 participantes en topología mesh.
- Modos de habla: PTT (push-to-talk, por defecto) y micrófono abierto.
- Lista de participantes con indicador de quién está hablando.
- Funcionamiento con pantalla apagada y app en segundo plano.
- Soporte de audífonos Bluetooth y altavoz.
- Reconexión automática cuando un participante sale y vuelve al rango.
- Interfaz en español (idioma base) e inglés.
- Aviso de señal débil por persona (pérdidas o retraso del enlace de voz).
- Vibración con los avisos de la frecu (transmitir, alguien habla, conexión perdida), que se apaga en Ajustes.
- Mensajes rápidos predefinidos para toda la frecu y SOS con alarma.
- Ubicación compartida voluntaria: distancia y rumbo a cada persona y aviso de quién se quedó atrás.
- Hablar con el botón de volumen (solo Android, opcional).
- Auricular al acercar el teléfono a la oreja y filtro de viento en el micrófono (los dos se apagan en Ajustes).
- Unirse por Bluetooth sin estar aún en la red del anfitrión: el código entrega la red y su clave.
- Invitar por NFC (acercar el teléfono del anfitrión Android o una etiqueta grabada) y enlaces `frecu://join`.

## Fuera de alcance del MVP

- Migración de anfitrión: si el anfitrión sale, la frecu se cierra.
- Topología SFU o mezcla en el anfitrión.
- Video, chat de texto libre (solo hay mensajes predefinidos), grabación, cuentas de usuario. (El registro y los 30 min gratis del modo internet son la fase siguiente.)
- Activación por voz (VOX).
- UWB, detección de caídas, app de reloj y botones PTT Bluetooth dedicados.

## Stack

- **Framework**: Flutter (Dart)
- **Estado y DI**: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`
- **Modelos y uniones**: `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation`
- **Navegación**: `auto_route`, `auto_route_generator`
- **i18n**: `slang`, `slang_flutter`, `slang_build_runner`
- **Audio RTC**: `flutter_webrtc` (solo audio, mesh; STUN/TURN solo en el modo internet)
- **Sesión de audio**: `audio_session`
- **Señalización host**: `shelf`, `shelf_web_socket`
- **Señalización cliente**: `web_socket_channel`
- **Descubrimiento mDNS**: `nsd`
- **QR**: `qr_flutter` (generar), `mobile_scanner` (leer)
- **Permisos**: `permission_handler`
- **Bluetooth (BLE)**: `bluetooth_low_energy`
- **NFC**: `nfc_manager`, `nfc_manager_ndef`
- **Enlaces**: `app_links`
- **Ubicación**: `geolocator`
- **Foreground Service (Android)**: servicio propio en Kotlin (`FrecuRoomService`) con notificación de medios (`androidx.media`)
- **IP local**: `network_info_plus`
- **Identificadores**: `uuid`
- **Logs**: `logger`
- **Linter**: `very_good_analysis`
- **Pruebas**: `flutter_test`, `mocktail`

## Despliegue

Android e iOS.

## Restricciones

- Clean Architecture por feature: `presentation -> domain <- data`.
- `domain` es Dart puro: prohibido importar `flutter` o plugins nativos.
- El modo local sigue 100% offline: sin internet, ni STUN/TURN, ni nube. El modo internet es opcional y solo existe si la app se compila con `FRECU_CLOUD_URL`.
