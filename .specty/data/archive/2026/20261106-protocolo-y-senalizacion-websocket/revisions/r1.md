---
kind: standard
epic: 20261106-prueba-de-concepto-de-audio
slice: C1
allowedDependencies:
  - shelf
  - shelf_web_socket
  - web_socket_channel
---

# Protocolo y señalización WebSocket

## Objetivo

Implementar la infraestructura de señalización local para la prueba de concepto de Frecu: servidor WebSocket Shelf en anfitrión (puerto 47800), cliente WebSocket para participantes y loopback en anfitrión, y modelo de mensajes tipados con Freezed para la negociación de sala.

## Fuera de alcance

- Conexión e intercambio de audio WebRTC (Corte C3).
- Interfaz gráfica de usuario y pantallas de sala (Corte C2).
- Descubrimiento por mDNS o lectura de QR (Fase 2).

## Supuestos

- A1: El servidor de señalización escucha en `0.0.0.0:47800` para aceptar conexiones locales entrantes en el hotspot.
- A2: El cliente del anfitrión se conecta a `ws://127.0.0.1:47800` para reutilizar el mismo flujo de señalización que los demás clientes.

## Criterios de aceptación

- AC1: CUANDO el anfitrión inicia la sala ENTONCES se ejecuta el servidor WebSocket de señalización en el puerto 47800 y responde a los mensajes de protocolo local.

## Diseño

- Entidades de dominio en Dart puro: `Room`, `Participant`, `RoomStatus`.
- DTOs de señalización con Freezed (`SignalingMessage`) cubriendo `join`, `welcome`, `rejected`, `peer_joined`, `peer_left`, `offer`, `answer`, `ice`, `talk_state`, `ping`, `pong`, `room_closed`.
- `SignalingServerDataSource`: Servidor Shelf WebSocket que acepta conexiones, valida código de acceso y capacidad (máximo 6 participantes), asigna `peerId` y enruta mensajes punto a punto o broadcast.
- `SignalingClientDataSource`: Envoltorio de `WebSocketChannel` que envía y recibe mensajes de protocolo parseados mediante un stream reactivo.

## Archivos

- modificar pubspec.yaml — añadir shelf, shelf_web_socket y web_socket_channel
- crear lib/features/room/domain/entities/participant.dart — entidad Participant
- crear lib/features/room/domain/entities/room.dart — entidad Room
- crear lib/features/room/domain/entities/room_status.dart — unión sellada RoomStatus
- crear lib/features/room/data/models/signaling_message.dart — unión Freezed de mensajes de señalización
- crear lib/features/room/data/datasources/signaling_server_datasource.dart — servidor WebSocket shelf
- crear lib/features/room/data/datasources/signaling_client_datasource.dart — cliente WebSocket
- crear test/features/room/domain/entities_test.dart — pruebas unitarias de entidades de sala
- crear test/features/room/data/signaling_message_test.dart — pruebas de serialización JSON de señalización
- crear test/features/room/data/signaling_server_test.dart — pruebas de servidor y cliente WebSocket

## Tareas

- [ ] T1: Configurar dependencias en pubspec.yaml y entidades de dominio de Room con pruebas unitarias.
  - files: pubspec.yaml, lib/features/room/domain/entities/participant.dart, lib/features/room/domain/entities/room.dart, lib/features/room/domain/entities/room_status.dart, test/features/room/domain/entities_test.dart
  - ac: AC1
  - verify: fvm flutter pub get && fvm flutter test test/features/room/domain/entities_test.dart
  - type: build
- [ ] T2: Implementar modelo SignalingMessage con Freezed y pruebas de serialización JSON.
  - files: lib/features/room/data/models/signaling_message.dart, test/features/room/data/signaling_message_test.dart
  - ac: AC1
  - verify: fvm dart run build_runner build -d && fvm flutter test test/features/room/data/signaling_message_test.dart
  - type: feat
- [ ] T3: Implementar SignalingServerDataSource, SignalingClientDataSource y pruebas de integración de servidor/cliente WebSocket.
  - files: lib/features/room/data/datasources/signaling_server_datasource.dart, lib/features/room/data/datasources/signaling_client_datasource.dart, test/features/room/data/signaling_server_test.dart
  - ac: AC1
  - verify: fvm flutter analyze && fvm flutter test
  - type: feat

## Riesgos

- R1: El puerto 47800 podría estar ocupado si un test anterior no liberó el socket — mitigación: asegurar cierre explícito (`close`) en `tearDown` de los tests y reintentos con puertos libres en pruebas.
