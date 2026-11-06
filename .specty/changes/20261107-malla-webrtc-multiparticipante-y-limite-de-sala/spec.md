---
kind: standard
epic: 20261107-frecu-multiparticipante-y-topologia-mesh
slice: C1
---

# Malla WebRTC multiparticipante y límite de sala

## Objetivo

Habilitar la topología de malla WebRTC completa (mesh) de hasta 6 participantes concurrentes en una frecu local sin internet, verificando la señalización punto a punto de ofertas SDP, respuestas e ICE entre múltiples pares, y asegurando el límite estricto de sala con rechazo (`roomFull`) y notificación visual para intentos excedentes.

## Fuera de alcance

- Visualización enriquecida de lista de participantes e indicador animado de habla en RoomPage (C2).
- Servidores de mezcla SFU o MCU en el anfitrión (el diseño es mesh puro descentralizado).
- Servidores STUN o TURN en la nube (comunicación exclusiva en red local).
- Botones de volumen físicos para PTT y ruteo a audífonos Bluetooth (Fase 4).

## Supuestos

- A1: Todos los participantes están en la misma red local WiFi / hotspot sin servidores STUN/TURN (`iceServers: []`).
  - impacto: alto
- A2: La topología mesh previene el _glare_ haciendo que el nuevo participante entrante cree las ofertas SDP hacia los participantes existentes recibidos en el mensaje `welcome`.
- A3: El número máximo de participantes concurrentes en una frecu es 6 (`NetworkConstants.maxParticipants = 6`). Intentos posteriores reciben `rejected` con motivo `roomFull`.

## Criterios de aceptación

- AC1: CUANDO hasta 6 participantes se unen a la frecu ENTONCES cada nuevo participante negocia y establece una conexión WebRTC independiente con todos los participantes ya presentes en la sala formando una malla completa (mesh).
- AC4: CUANDO un séptimo participante intenta unirse a una frecu con 6 participantes activos ENTONCES el servidor de señalización rechaza la conexión con motivo `roomFull` y la aplicación del participante muestra la notificación de sala llena.

## Diseño

- **Data / WebRTC Mesh**:
  - `SignalingServerDataSource`: Validación del límite de 6 participantes (`NetworkConstants.maxParticipants`), enrutamiento punto a punto de mensajes `offer`, `answer` e `ice`, difusión de `peer_joined` y `peer_left`, y rechazo con `roomFull`.
  - `PeerConnectionDataSource`: Gestión concurrente de hasta 5 `RTCPeerConnection`s por cliente, inyección de pistas locales de audio, aislamiento de candidatos ICE por par remoto y liberación de recursos en desconexión.
  - `VoiceRepositoryImpl`: Negociación automática con todos los pares existentes al recibir `welcome`, propagación de estado de habla a todos los pares y limpieza en salida de participantes.
- **Presentation**:
  - `FailureLocalization` (extensión de `Failure`): Mapeo localizado de fallas a mensajes de usuario (`t.errors.roomFull`, etc.).
  - `LobbyPage` y `ScanQrPage`: Manejo amigable de la falla `roomFull` presentando un SnackBar informativo con el mensaje localizado.

## Archivos

- crear lib/features/room/presentation/extensions/failure_extension.dart — extensión para localizar fallas en la interfaz
- modificar lib/features/lobby/presentation/pages/lobby_page.dart — mostrar mensaje localizado de sala llena al fallar la unión
- modificar lib/features/lobby/presentation/pages/scan_qr_page.dart — mostrar mensaje localizado de sala llena al fallar la unión por QR
- modificar test/features/room/data/signaling_server_test.dart — pruebas de señalización multipar hasta 6 participantes y rechazo roomFull al 7mo
- crear test/features/room/data/peer_connection_datasource_test.dart — pruebas unitarias de malla WebRTC con múltiples conexiones concurrentes
- modificar test/features/room/data/voice_repository_test.dart — pruebas de negociación mesh multipar y desconexión en repositorio de voz
- crear test/features/lobby/presentation/room_full_flow_test.dart — pruebas de presentación para la notificación de sala llena

## Tareas

- [ ] T1: Señalización multipar y límite de sala en servidor con pruebas unitarias exhaustivas
  - files: test/features/room/data/signaling_server_test.dart
  - ac: AC1, AC4
  - verify: fvm flutter test test/features/room/data/signaling_server_test.dart
- [ ] T2: Malla WebRTC multiparticipante (hasta 5 conexiones simultáneas) en PeerConnectionDataSource y VoiceRepository
  - files: test/features/room/data/peer_connection_datasource_test.dart, test/features/room/data/voice_repository_test.dart
  - ac: AC1
  - verify: fvm flutter test test/features/room/data/peer_connection_datasource_test.dart test/features/room/data/voice_repository_test.dart
- [ ] T3: Notificación de sala llena en la interfaz de usuario al recibir roomFull
  - files: lib/features/room/presentation/extensions/failure_extension.dart, lib/features/lobby/presentation/pages/lobby_page.dart, lib/features/lobby/presentation/pages/scan_qr_page.dart, test/features/lobby/presentation/room_full_flow_test.dart
  - ac: AC4
  - verify: fvm flutter test test/features/lobby/presentation/room_full_flow_test.dart

## Riesgos

- R1: La topología de malla WebRTC con 6 nodos requiere N*(N-1)/2 = 15 conexiones bidireccionales en total — mitigación: audio mono sin video a bajo bitrate y cancelación de eco de hardware reduce el consumo de CPU y memoria.
