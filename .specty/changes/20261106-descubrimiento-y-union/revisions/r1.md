---
kind: epic
---

# Descubrimiento y unión

## Objetivo

Permitir a los participantes encontrar y unirse a salas activas (frecus) en la misma red WiFi local sin necesidad de ingresar direcciones IP manualmente, mediante descubrimiento automático por mDNS y escaneo de códigos QR de invitación con código de acceso PIN.

## Fuera de alcance

- Topología mesh para más de 2 participantes (Fase 3).
- Modo Push-to-Talk (PTT) con botones físicos de volumen y ruteo de audífonos Bluetooth (Fase 4).
- Servicio en primer plano y reconexión en background con pantalla apagada (Fase 5).
- Creación automática del Hotspot vía LocalOnlyHotspot (el usuario lo activa manualmente según el alcance del MVP).

## Supuestos

- A1: Los dispositivos se encuentran en la misma subred local WiFi donde el tráfico mDNS (`_frecu._tcp`) no está bloqueado por el punto de acceso.
  - impacto: alto
- A2: La invitación codificada en el código QR sigue el esquema estándar de URI `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
- A3: La cámara del dispositivo está disponible para escanear el código QR y cuenta con los permisos de usuario correspondientes.

## Criterios de aceptación

- AC1: CUANDO el anfitrión crea una frecu ENTONCES se publica el servicio mDNS `_frecu._tcp` con los atributos `roomId`, `name` y versión de protocolo `v`.
- AC2: CUANDO un participante abre el lobby en la misma red local ENTONCES descubre automáticamente las frecus activas anunciadas por mDNS y las muestra en la lista de frecus cercanas.
- AC3: CUANDO un participante selecciona una frecu descubierta e ingresa el código de acceso ENTONCES se conecta a la sala si el código es válido o recibe notificación de rechazo si es incorrecto.
- AC4: CUANDO el anfitrión consulta la información de invitación de la frecu ENTONCES se genera y muestra un código QR con el formato URI `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
- AC5: CUANDO un participante escanea el código QR de invitación ENTONCES la aplicación parsea los parámetros de conexión y se une automáticamente a la sala sin ingresar la IP ni el código manualmente.

## Diseño

- La épica se divide en dos cortes verticales:
  1. **C1 (Descubrimiento local mDNS y código de acceso)**:
     - Dominio: Entidad `RoomInvite`, contrato `DiscoveryRepository` (`watchNearbyRooms`, `publishRoom`, `stopPublishing`), casos de uso `DiscoverRooms`.
     - Datos: `MdnsDataSource` con plugin `nsd` (`_frecu._tcp`, puerto y atributos TXT), `DiscoveryRepositoryImpl`.
     - Presentación: Notifiers `nearbyRoomsProvider`, visualización de lista de salas cercanas en `LobbyPage`, modal para ingresar PIN de 4 dígitos al pulsar una sala y manejo reactivo de errores de rechazo (`rejected: invalidAccessCode`).
  2. **C2 (Invitación y escaneo por código QR)**:
     - Dominio: Casos de uso `BuildInviteQr`, `ParseInviteFromQr` con validación de esquema URI `frecu://join`.
     - Datos: Generación de QR con `qr_flutter` e integración de captura de cámara con `mobile_scanner`.
     - Presentación: Diálogo/vista de QR de invitación en `RoomPage`, vista de escáner en `LobbyPage` / `ScanQrPage` y navegación automática con unión a la sala.

## Cortes

- C1: Descubrimiento local mDNS y código de acceso
  - ac: AC1, AC2, AC3
- C2: Invitación y escaneo por código QR
  - ac: AC4, AC5
  - depends: C1

## Riesgos

- R1: Algunos routers o hotspots móviles aíslan a los clientes o bloquean el tráfico multicast DNS (mDNS) — mitigación: el código QR actúa como mecanismo de respaldo infalible con conexión directa punto a punto por IP.
