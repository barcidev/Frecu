---
kind: standard
allowedDependencies:
  - audio_session
  - flutter_webrtc
  - network_info_plus
  - shelf
  - shelf_web_socket
  - web_socket_channel
---

# Prueba de concepto de audio

## Objetivo

Implementar la Fase 1 del proyecto Frecu: prueba de concepto de voz grupal en red local offline entre 2 teléfonos (anfitrión y cliente con IP ingresada manualmente) con servidor WebSocket en el anfitrión, señalización bidireccional y audio en tiempo real con WebRTC en modo micrófono abierto.

## Fuera de alcance

- Descubrimiento automático mDNS y escaneo/generación de QR (Fase 2).
- Topología mesh multiparticipante de más de 2 teléfonos (Fase 3).
- Modo Push-to-Talk (PTT) y ruteo dinámico de hardware Bluetooth (Fase 4).
- Servicio en primer plano persistente y reconexión en segundo plano (Fase 5).

## Supuestos

- A1: Ambos teléfonos están conectados a la misma red local (hotspot WiFi del anfitrión o router WiFi sin acceso a internet).
- A2: La IP del anfitrión puede ser consultada en su interfaz de red y mostrada en pantalla para que el cliente la ingrese manualmente.
- A3: WebRTC opera estrictamente con `iceServers: []` utilizando candidatos locales sin servidores STUN ni TURN.

## Criterios de aceptación

- AC1: CUANDO un anfitrión crea una sala ENTONCES se inicia el servidor WebSocket de señalización en el puerto 47800 y se muestra su IP local para conexión.
- AC2: CUANDO un participante introduce la IP del anfitrión y solicita unirse ENTONCES el cliente WebSocket se conecta, negocia la sesión con mensajes `join`/`welcome` y la sala queda en estado `connected`.
- AC3: CUANDO dos dispositivos están en la sala ENTONCES se establece una conexión WebRTC punto a punto con pistas de audio locales y micrófono abierto bidireccional.
- AC4: CUANDO se ejecuta `fvm flutter analyze` y `fvm flutter test` ENTONCES no hay errores ni advertencias de análisis estático y todas las pruebas pasan exitosamente.

## Diseño

- `features/room/domain`:
  - Entidades: `Room`, `Participant`, `TalkMode`, `RoomStatus`.
  - Contratos: `RoomRepository`, `VoiceRepository`.
  - Casos de uso: `CreateRoomUseCase`, `JoinRoomUseCase`, `LeaveRoomUseCase`, `StartVoiceSessionUseCase`.
- `features/room/data`:
  - Modelos y DTOs: `SignalingMessage` (unión Freezed con `@Freezed(unionKey: 'type')` para `join`, `welcome`, `rejected`, `peer_joined`, `peer_left`, `offer`, `answer`, `ice`, `talk_state`, `ping`, `pong`, `room_closed`).
  - Datasources: `SignalingServerDataSource` (Shelf WebSocket server), `SignalingClientDataSource` (WebSocket channel, loopback en host), `PeerConnectionDataSource` (RTCPeerConnection local mesh sin STUN/TURN), `AudioSessionDataSource` (audio_session en modo voiceChat).
  - Repositorios: `RoomRepositoryImpl`, `VoiceRepositoryImpl`.
- `features/room/presentation`:
  - State Notifier: `RoomNotifier` con Riverpod administrando el ciclo de vida de la sala y los participantes.
  - UI: `CreateRoomPage` (muestra IP local y estado), `JoinDialog` en `LobbyPage` (ingreso manual de IP), `RoomPage` (estado de conexión, participante remoto y botón para salir).

## Archivos

- modificar pubspec.yaml — añadir dependencias de audio, señalización y red
- crear lib/features/room/domain/entities/room.dart — entidad Room
- crear lib/features/room/domain/entities/participant.dart — entidad Participant
- crear lib/features/room/domain/entities/talk_mode.dart — entidad TalkMode
- crear lib/features/room/domain/entities/room_status.dart — entidad RoomStatus
- crear lib/features/room/domain/repositories/room_repository.dart — contrato de repositorio de sala
- crear lib/features/room/domain/repositories/voice_repository.dart — contrato de repositorio de voz
- crear lib/features/room/domain/usecases/create_room_usecase.dart — caso de uso crear sala
- crear lib/features/room/domain/usecases/join_room_usecase.dart — caso de uso unirse a sala
- crear lib/features/room/domain/usecases/leave_room_usecase.dart — caso de uso salir de sala
- crear lib/features/room/domain/usecases/start_voice_session_usecase.dart — caso de uso iniciar voz
- crear lib/features/room/data/models/signaling_message.dart — DTOs de señalización Freezed
- crear lib/features/room/data/datasources/signaling_server_datasource.dart — servidor WebSocket de señalización
- crear lib/features/room/data/datasources/signaling_client_datasource.dart — cliente WebSocket de señalización
- crear lib/features/room/data/datasources/peer_connection_datasource.dart — gestión de WebRTC RTCPeerConnection
- crear lib/features/room/data/datasources/audio_session_datasource.dart — configuración de audio_session
- crear lib/features/room/data/repositories/room_repository_impl.dart — implementación de RoomRepository
- crear lib/features/room/data/repositories/voice_repository_impl.dart — implementación de VoiceRepository
- crear lib/features/room/presentation/providers/room_notifier.dart — notifier Riverpod de estado de sala
- crear lib/features/room/presentation/providers/room_di.dart — inyección de dependencias de room
- modificar lib/features/lobby/presentation/pages/lobby_page.dart — diálogo para ingresar IP manual
- modificar lib/features/lobby/presentation/pages/create_room_page.dart — pantalla de anfitrión con IP local
- modificar lib/features/room/presentation/pages/room_page.dart — sala activa con voz y participantes
- modificar lib/i18n/strings.i18n.json — traducciones español de sala y voz
- modificar lib/i18n/strings_en.i18n.json — traducciones inglés de sala y voz
- crear test/features/room/data/signaling_message_test.dart — pruebas de serialización JSON de señalización
- crear test/features/room/data/signaling_server_test.dart — pruebas del servidor de señalización
- crear test/features/room/domain/room_usecases_test.dart — pruebas unitarias de casos de uso
- crear test/features/room/presentation/room_page_test.dart — pruebas de widget de sala y conexión

## Tareas

- [ ] T1: Configurar dependencias en pubspec.yaml, entidades de dominio, contratos de repositorio y DTOs de señalización con pruebas de serialización.
  - files: pubspec.yaml, pubspec.lock, lib/features/room/domain/entities/**, lib/features/room/domain/repositories/**, lib/features/room/data/models/**, test/features/room/data/signaling_message_test.dart
  - ac: AC4
  - verify: fvm flutter pub get && fvm dart run build_runner build -d && fvm flutter test test/features/room/data/signaling_message_test.dart
  - type: build
- [ ] T2: Implementar datasources de señalización (SignalingServerDataSource, SignalingClientDataSource) y pruebas unitarias con transporte en memoria.
  - files: lib/features/room/data/datasources/signaling_server_datasource.dart, lib/features/room/data/datasources/signaling_client_datasource.dart, test/features/room/data/signaling_server_test.dart
  - ac: AC1, AC2, AC4
  - verify: fvm flutter test test/features/room/data/signaling_server_test.dart
  - type: feat
- [ ] T3: Implementar PeerConnectionDataSource (WebRTC mesh offline), AudioSessionDataSource, repositorios e integración con casos de uso de dominio.
  - files: lib/features/room/data/datasources/peer_connection_datasource.dart, lib/features/room/data/datasources/audio_session_datasource.dart, lib/features/room/data/repositories/**, lib/features/room/domain/usecases/**, test/features/room/domain/room_usecases_test.dart
  - ac: AC3, AC4
  - verify: fvm flutter test test/features/room/domain/room_usecases_test.dart
  - type: feat
- [ ] T4: Implementar providers de Riverpod, UI de unión por IP en LobbyPage, CreateRoomPage y RoomPage con audio bidireccional y pruebas de widgets.
  - files: lib/features/room/presentation/**, lib/features/lobby/presentation/pages/lobby_page.dart, lib/features/lobby/presentation/pages/create_room_page.dart, lib/i18n/**, test/features/room/presentation/room_page_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: fvm flutter analyze && fvm flutter test
  - type: feat

## Riesgos

- R1: El emulador o simulador puede no tener dispositivos de entrada/salida de audio reales — mitigación: abstraer el acceso a hardware en PeerConnectionDataSource y AudioSessionDataSource para permitir su simulación en tests unitarios.
