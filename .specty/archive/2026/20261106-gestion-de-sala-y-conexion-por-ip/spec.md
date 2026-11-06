---
kind: standard
epic: 20261106-prueba-de-concepto-de-audio
slice: C2
---

# Gestión de sala y conexión por IP

## Objetivo

Permitir que el usuario anfitrión cree una frecu viendo su dirección IP local para compartirla con su grupo, y que otro usuario se una como participante ingresando manualmente la IP del anfitrión, manteniendo la sincronización de participantes y estado de la sala mediante la señalización WebSocket.

## Fuera de alcance

- Negociación y transmisión de pistas de audio WebRTC (Corte C3).
- Descubrimiento automático por mDNS o escaneo de QR (Fase 2).
- Persistencia en base de datos local o backend en la nube.

## Supuestos

- A1: En el anfitrión, `NetworkInterface.list()` detecta la dirección IPv4 local asignada a la interfaz del hotspot o red local (ej. 192.168.43.1).
- A2: El código de acceso por defecto para la prueba de concepto es un PIN numérico de 4 dígitos (ej. "1234").
- A3: El puerto de señalización estándar es 47800.

## Criterios de aceptación

- AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
- AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
- AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.

## Diseño

- **Domain**:
  - Contrato `RoomRepository` con métodos `createRoom`, `joinRoom`, `leaveRoom`, `watchParticipants`, `watchStatus` y `getLocalIpAddress`.
  - Casos de uso `CreateRoom`, `JoinRoom`, `LeaveRoom`.
- **Data**:
  - `RoomRepositoryImpl` que coordina `SignalingServerDataSource` (en host), `SignalingClientDataSource` (host y clientes), y resolución de IP vía `NetworkInterface.list()`.
- **Presentation**:
  - Notifier de Riverpod (`RoomNotifier`) gestionando el estado de la sala (`RoomState`).
  - Actualización de `CreateRoomPage`, `LobbyPage` (conexión manual por IP) y `RoomPage` (visualización de IP, lista de participantes y salida limpia).

## Archivos

- crear lib/features/room/domain/repositories/room_repository.dart — contrato abstracto RoomRepository
- crear lib/features/room/domain/usecases/create_room.dart — caso de uso CreateRoom
- crear lib/features/room/domain/usecases/join_room.dart — caso de uso JoinRoom
- crear lib/features/room/domain/usecases/leave_room.dart — caso de uso LeaveRoom
- crear test/features/room/domain/usecases_test.dart — pruebas unitarias de casos de uso de sala
- crear lib/features/room/data/repositories/room_repository_impl.dart — implementación de RoomRepository
- crear test/features/room/data/room_repository_test.dart — pruebas de RoomRepositoryImpl
- crear lib/features/room/presentation/providers/room_provider.dart — StateNotifier / Notifier de Riverpod
- modificar lib/features/lobby/presentation/pages/create_room_page.dart — formulario para crear sala y navegar a RoomPage
- modificar lib/features/lobby/presentation/pages/lobby_page.dart — botón y diálogo para unirse por IP
- modificar lib/features/room/presentation/pages/room_page.dart — visualización de IP, lista de participantes y botón de salida
- crear test/features/room/presentation/room_flow_test.dart — pruebas de interfaz y flujo de sala

## Tareas

- [x] T1: Contratos de dominio (RoomRepository), casos de uso (CreateRoom, JoinRoom, LeaveRoom) y pruebas unitarias.
  - files: lib/features/room/domain/repositories/room_repository.dart, lib/features/room/domain/usecases/create_room.dart, lib/features/room/domain/usecases/join_room.dart, lib/features/room/domain/usecases/leave_room.dart, test/features/room/domain/usecases_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter test test/features/room/domain/usecases_test.dart
  - type: feat
- [x] T2: Implementación de RoomRepositoryImpl con resolución de IP local y tests de integración.
  - files: lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/room_repository_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter test test/features/room/data/room_repository_test.dart
  - type: feat
- [x] T3: Proveedores de Riverpod (RoomNotifier), actualización de UI en CreateRoomPage, LobbyPage y RoomPage, y pruebas de flujo.
  - files: lib/features/room/presentation/providers/room_provider.dart, lib/features/lobby/presentation/pages/create_room_page.dart, lib/features/lobby/presentation/pages/lobby_page.dart, lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/room_flow_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter analyze && fvm flutter test
  - type: feat

## Riesgos

- R1: La IP local puede no estar disponible si el hotspot o WiFi no se han activado todavía — mitigación: retornar null o dirección por defecto ('192.168.43.1') e informar al usuario en la interfaz.

## Cierre

### Resumen

Se completó con éxito el Corte C2 ("Gestión de sala y conexión por IP") del Epic de prueba de concepto de audio:

- Capa de dominio: Contrato `RoomRepository` y casos de uso `CreateRoom`, `JoinRoom` y `LeaveRoom` en Dart puro sin dependencias de plataforma, con pruebas unitarias exhaustivas con `mocktail`.
- Capa de datos: `RoomRepositoryImpl` que orquesta `SignalingServerDataSource` (anfitrión) y `SignalingClientDataSource` (participantes y loopback), resolución de IP local mediante `NetworkInterface.list()` con fallback seguro a la subred de hotspot estándar (`192.168.43.1`), y pruebas de integración reactivas.
- Capa de presentación: Proveedores Riverpod (`RoomNotifier`, `roomRepositoryProvider`, `roomParticipantsProvider`, `roomStatusProvider`, `localIpProvider`), actualización de `CreateRoomPage` (mostrando IP local y PIN), `LobbyPage` (con modal para unirse por IP) y `RoomPage` (visualización de detalles de conexión, lista de participantes en tiempo real y salida limpia).
- Suite completa de pruebas en verde (21/21 tests pasando) y 0 incidencias en el análisis estático (`fvm flutter analyze`).

### Desviaciones

- El archivo generado por `build_runner` (`lib/features/room/presentation/providers/room_provider.g.dart`) se incluyó en el alcance de T3 y se actualizó `.specty/config.yaml` (`scope.generated`) para que las reglas de calidad ignoren directivas de analizador en código generado.

### Decisiones

- Los widgets `CreateRoomPage`, `LobbyPage` y `RoomPage` se modularizaron en componentes privados (`_RoomInfoCard`, `_ParticipantsList`, `_JoinRoomDialog`, `_buildIpBadge`) para asegurar que ninguna función supere las 50 líneas de código y mantener una alta legibilidad.
- La navegación en los flujos asíncronos de creación y unión utiliza `unawaited` y comprobaciones de `context.mounted` para cumplir estrictamente con las reglas de linting de Flutter y Very Good Analysis.

### Pendientes

- Integración de audio WebRTC bidireccional y sesión de micrófono abierto/PTT sobre la sala conectada (Corte C3).
