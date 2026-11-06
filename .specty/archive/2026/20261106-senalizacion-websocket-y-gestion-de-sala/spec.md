---
kind: standard
epic: 20261106-prueba-de-concepto-de-audio
slice: C1
allowedDependencies:
  - network_info_plus
  - shelf
  - shelf_web_socket
  - web_socket_channel
---

# Señalización WebSocket y gestión de sala

## Objetivo

Implementar el corte C1 de la Fase 1: infraestructura de señalización WebSocket (servidor Shelf en anfitrión y cliente WebSocket con loopback en anfitrión), protocolo de mensajes tipados y flujo de interfaz para crear una sala mostrando la IP local o unirse ingresando la IP manualmente, administrando la lista de participantes y el estado de la sala.

## Fuera de alcance

- Conexión WebRTC de audio y pistas de micrófono (Corte C2).
- Configuración de hardware de audio con audio_session (Corte C2).
- Descubrimiento por mDNS o escáner QR (Fase 2).

## Supuestos

- A1: Los dos dispositivos se encuentran en la misma subred WiFi local.
- A2: La IP del anfitrión es accesible en la interfaz local WiFi (por defecto 0.0.0.0:47800 para el bind del servidor).

## Criterios de aceptación

- AC1: CUANDO el anfitrión crea una sala ENTONCES se inicia el servidor WebSocket de señalización en el puerto 47800 y se muestra su dirección IP local para permitir la conexión.
- AC2: CUANDO un participante introduce la IP del anfitrión y solicita unirse ENTONCES el cliente WebSocket se conecta, valida el protocolo con mensajes join/welcome y la sala queda en estado connected con ambos participantes.

## Diseño

- `features/room/domain`:
  - Entidades: `Room`, `Participant`, `RoomStatus`.
  - Contrato: `RoomRepository`.
- `features/room/data`:
  - Modelos: `SignalingMessage` (Freezed union con `join`, `welcome`, `rejected`, `peer_joined`, `peer_left`, `offer`, `answer`, `ice`, `talk_state`, `ping`, `pong`, `room_closed`).
  - Datasources: `SignalingServerDataSource` (Shelf WebSocket server en `0.0.0.0:47800`), `SignalingClientDataSource` (WebSocket client hacia el host o `127.0.0.1` si es anfitrión).
  - Repositorio: `RoomRepositoryImpl`.
- `features/room/presentation`:
  - Provider: `RoomNotifier` con Riverpod.
  - UI: `CreateRoomPage` (levanta server y muestra IP), `LobbyPage` (diálogo para conectar por IP), `RoomPage` (lista de participantes y estado de sala).

## Archivos

- modificar pubspec.yaml — dependencias network_info_plus, shelf, shelf_web_socket, web_socket_channel
- crear lib/features/room/domain/entities/participant.dart — entidad Participant
- crear lib/features/room/domain/entities/room.dart — entidad Room
- crear lib/features/room/domain/entities/room_status.dart — unión sellada RoomStatus
- crear lib/features/room/domain/repositories/room_repository.dart — contrato RoomRepository
- crear lib/features/room/data/models/signaling_message.dart — unión Freezed de mensajes de señalización
- crear lib/features/room/data/datasources/signaling_server_datasource.dart — servidor WebSocket con shelf
- crear lib/features/room/data/datasources/signaling_client_datasource.dart — cliente WebSocket
- crear lib/features/room/data/repositories/room_repository_impl.dart — implementación de RoomRepository
- crear lib/features/room/presentation/providers/room_notifier.dart — notifier Riverpod de sala
- modificar lib/features/lobby/presentation/pages/lobby_page.dart — botón y diálogo para unión manual por IP
- modificar lib/features/lobby/presentation/pages/create_room_page.dart — creación de sala y visualización de IP
- modificar lib/features/room/presentation/pages/room_page.dart — estado de sala y participantes
- crear test/features/room/data/signaling_message_test.dart — pruebas de serialización JSON de señalización
- crear test/features/room/data/signaling_server_test.dart — pruebas del servidor de señalización WebSocket
- crear test/features/room/presentation/room_flow_test.dart — prueba de flujo de creación y unión a sala

## Tareas

- [ ] T1: Configurar dependencias en pubspec.yaml, entidades de dominio y DTOs de señalización Freezed con pruebas de serialización.
  - files: pubspec.yaml, lib/features/room/domain/entities/participant.dart, lib/features/room/domain/entities/room.dart, lib/features/room/domain/entities/room_status.dart, lib/features/room/domain/repositories/room_repository.dart, lib/features/room/data/models/signaling_message.dart, test/features/room/data/signaling_message_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter pub get && fvm dart run build_runner build -d && fvm flutter test test/features/room/data/signaling_message_test.dart
  - type: build
- [ ] T2: Implementar SignalingServerDataSource, SignalingClientDataSource y pruebas unitarias de intercambio de señalización.
  - files: lib/features/room/data/datasources/signaling_server_datasource.dart, lib/features/room/data/datasources/signaling_client_datasource.dart, test/features/room/data/signaling_server_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter test test/features/room/data/signaling_server_test.dart
  - type: feat
- [ ] T3: Implementar RoomRepositoryImpl, RoomNotifier y UI de creación/unión manual en CreateRoomPage, LobbyPage y RoomPage con pruebas de widget.
  - files: lib/features/room/data/repositories/room_repository_impl.dart, lib/features/room/presentation/providers/room_notifier.dart, lib/features/lobby/presentation/pages/lobby_page.dart, lib/features/lobby/presentation/pages/create_room_page.dart, lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/room_flow_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter analyze && fvm flutter test
  - type: feat

## Riesgos

- R1: La obtención de la IP local en interfaces WiFi móviles puede variar por permisos de red o hotspot — mitigación: usar network_info_plus con fallback a la IP detectada de interfaces de red activas.
