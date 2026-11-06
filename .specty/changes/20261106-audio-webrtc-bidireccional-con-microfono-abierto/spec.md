---
kind: standard
epic: 20261106-prueba-de-concepto-de-audio
slice: C3
allowedDependencies:
  - flutter_webrtc
  - audio_session
  - permission_handler
---

# Audio WebRTC bidireccional con micrófono abierto

## Objetivo

Establecer la transmisión de audio bidireccional punto a punto (WebRTC mesh) entre dos teléfonos en la misma frecu sin conexión a internet, soportando captura y reproducción de voz en modo micrófono abierto, control de muteo y visualización en tiempo real de qué participante está hablando.

## Fuera de alcance

- PTT avanzado con botones físicos de volumen (Fase 2).
- Múltiples canales o salas concurrentes.
- Servicio en segundo plano de Android (`flutter_foreground_task`) (Fase 2).
- Más de 6 participantes concurrentes.

## Supuestos

- A1: No se requieren servidores STUN ni TURN (`iceServers: []`), ya que la comunicación ocurre exclusivamente en la red de área local (WiFi Hotspot).
- A2: La negociación WebRTC utiliza el servidor WebSocket de señalización ya implementado en C1 y C2 para intercambiar ofertas SDP, respuestas SDP y candidatos ICE locales.
- A3: Para evitar colisiones (_glare_), el participante recién llegado genera la oferta (`offer`) hacia los participantes preexistentes recibidos en el mensaje `welcome`.

## Criterios de aceptación

- AC1: CUANDO un participante se une a la sala del anfitrión ENTONCES se negocia automáticamente una conexión WebRTC mesh directa (SDP offer/answer e ICE local) entre ambos extremos sin servidores STUN/TURN.
- AC2: CUANDO ambos extremos tienen el micrófono activado en modo abierto ENTONCES la captura local de audio transmite en tiempo real hacia el otro teléfono y se emite señalización de estado de habla (`talk_state`).
- AC3: CUANDO un participante silencia su micrófono ENTONCES se desactiva la pista local de audio (`track.enabled = false`) sin renegociar la sesión WebRTC y se notifica a la sala el cese de habla.

## Diseño

- **Domain**:
  - Entidad `TalkMode`: `pushToTalk` | `openMic`.
  - Contrato `VoiceRepository`: `initializeAudio()`, `startTalking()`, `stopTalking()`, `setTalkMode()`, `watchIsTalking()`, `watchSpeakingPeers()`, `dispose()`.
  - Casos de uso `StartTalking`, `StopTalking` agrupados en `voice_usecases.dart`.
- **Data**:
  - `AudioSessionDataSource`: Configura la sesión nativa con `audio_session` (baja latencia, altavoz, cancelación de eco).
  - `PeerConnectionDataSource`: Envoltorio de `flutter_webrtc` que gestiona `RTCPeerConnection` mesh, añade pistas locales, bufferiza candidatos ICE tempranos e interactúa con el cliente de señalización.
  - `VoiceRepositoryImpl`: Implementa `VoiceRepository` orquestando audio y WebRTC.
- **Presentation**:
  - Notifier `VoiceNotifier` en Riverpod.
  - Actualización de `RoomPage` con indicador de habla (quién está hablando) y control de micrófono abierto / silenciado.

## Archivos

- modificar pubspec.yaml — añadir flutter_webrtc, audio_session y permission_handler
- crear lib/features/room/domain/entities/talk_mode.dart — unión o enum TalkMode
- crear lib/features/room/domain/repositories/voice_repository.dart — contrato VoiceRepository
- crear lib/features/room/domain/usecases/voice_usecases.dart — casos de uso StartTalking y StopTalking
- crear test/features/room/domain/voice_usecases_test.dart — pruebas unitarias de casos de uso de voz
- crear lib/features/room/data/datasources/audio_session_datasource.dart — configuración de audio_session
- crear lib/features/room/data/datasources/peer_connection_datasource.dart — gestión de WebRTC mesh
- crear lib/features/room/data/repositories/voice_repository_impl.dart — implementación de VoiceRepository
- crear test/features/room/data/voice_repository_test.dart — pruebas de repositorio de voz
- crear lib/features/room/presentation/providers/voice_provider.dart — StateNotifier de voz en Riverpod
- modificar lib/features/room/presentation/pages/room_page.dart — controles de habla e indicador de participantes hablando
- crear test/features/room/presentation/voice_flow_test.dart — pruebas de widgets y flujo de audio

## Tareas

- [x] T1: Configurar dependencias en pubspec.yaml, TalkMode, VoiceRepository y casos de uso con pruebas unitarias.
  - files: pubspec.yaml, lib/features/room/domain/entities/talk_mode.dart, lib/features/room/domain/repositories/voice_repository.dart, lib/features/room/domain/usecases/voice_usecases.dart, test/features/room/domain/voice_usecases_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter test test/features/room/domain/voice_usecases_test.dart
  - type: build
- [x] T2: Implementar datasources de AudioSession, PeerConnection y VoiceRepositoryImpl con pruebas.
  - files: lib/features/room/data/datasources/audio_session_datasource.dart, lib/features/room/data/datasources/peer_connection_datasource.dart, lib/features/room/data/repositories/voice_repository_impl.dart, test/features/room/data/voice_repository_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter test test/features/room/data/voice_repository_test.dart
  - type: feat
- [x] T3: Proveedores de Riverpod (VoiceNotifier), controles en RoomPage y pruebas de interfaz de habla.
  - files: lib/features/room/presentation/providers/voice_provider.dart, lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/voice_flow_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter analyze && fvm flutter test
  - type: feat

## Riesgos

- R1: El plugin flutter_webrtc puede fallar en entornos headless de pruebas de CI — mitigación: encapsular llamadas nativas tras abstracciones testeables y usar dobles de prueba para RTCPeerConnection en tests unitarios.
