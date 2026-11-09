# Frecu

## Qué es

Frecu convierte varios teléfonos en un intercomunicador de voz grupal que funciona sin internet. Un teléfono actúa como anfitrión: comparte su red WiFi (hotspot) y crea una frecu (sala). Los demás teléfonos se conectan a esa red, se unen a la frecu y hablan entre todos en tiempo real.

## Para quién

Para grupos de personas como caravanas de motos, senderistas, ciclistas o equipos de trabajo que necesitan comunicarse por voz en tiempo real sin depender de conexión a internet ni cobertura celular.

## Alcance del MVP

- Crear una frecu como anfitrión y unirse como participante.
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

## Fuera de alcance del MVP

- Crear el hotspot desde la app (`LocalOnlyHotspot`). En el MVP el usuario lo activa manualmente y la app lo guía.
- Migración de anfitrión: si el anfitrión sale, la frecu se cierra.
- Topología SFU o mezcla en el anfitrión.
- Video, chat de texto libre (solo hay mensajes predefinidos), grabación, cuentas de usuario, backend en la nube.
- Activación por voz (VOX).

## Stack

- **Framework**: Flutter (Dart)
- **Estado y DI**: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`
- **Modelos y uniones**: `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation`
- **Navegación**: `auto_route`, `auto_route_generator`
- **i18n**: `slang`, `slang_flutter`, `slang_build_runner`
- **Audio RTC**: `flutter_webrtc` (solo audio local mesh, sin STUN/TURN)
- **Sesión de audio**: `audio_session`
- **Señalización host**: `shelf`, `shelf_web_socket`
- **Señalización cliente**: `web_socket_channel`
- **Descubrimiento mDNS**: `nsd`
- **QR**: `qr_flutter` (generar), `mobile_scanner` (leer)
- **Permisos**: `permission_handler`
- **Foreground Service (Android)**: `flutter_foreground_task`
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
- 100% offline: cero dependencias de internet (sin servidores STUN/TURN, sin nubes).
