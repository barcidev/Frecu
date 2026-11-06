---
kind: standard
epic: 20261107-frecu-multiparticipante-y-topologia-mesh
slice: C2
---

# Lista reactiva de participantes e indicador de habla

## Objetivo

Proporcionar a los usuarios de una frecu activa una visualización clara y reactiva de los participantes de la sala (hasta 6), mostrando el contador de ocupación, distintivo visual de anfitrión y un indicador animado en tiempo real que refleja con precisión quién se encuentra hablando (`isSpeaking`), además de reflejar inmediatamente las uniones (`peer_joined`) y salidas (`peer_left`) de participantes.

## Fuera de alcance

- Servidores de mezcla SFU o MCU en el anfitrión (el diseño es mesh puro descentralizado).
- Servidores STUN o TURN en la nube (comunicación exclusiva en red local).
- Botones de volumen físicos para PTT y ruteo a audífonos Bluetooth (Fase 4).
- Servicio foreground en Android y audio background en iOS (Fase 5).

## Supuestos

- A1: Todos los participantes están conectados a la misma red local WiFi / hotspot del anfitrión y la sala admite hasta 6 participantes concurrentes (`NetworkConstants.maxParticipants = 6`).
  - impacto: alto
- A2: Los eventos de señalización `peer_joined`, `peer_left` y `talk_state` son recibidos y difundidos por el repositorio de sala y el repositorio de voz a través de streams reactivos de Riverpod.
- A3: El estado de habla de cada participante se deriva tanto de la propiedad `isSpeaking` del objeto `Participant` como del conjunto de pares remotos transmitiendo voz `speakingPeers` emitido por `voiceNotifierProvider`.

## Criterios de aceptación

- AC2: CUANDO un participante habla en la frecu ENTONCES su voz se transmite simultáneamente a todos los demás participantes de la malla y su indicador de habla se activa en tiempo real en la lista de participantes de todos los dispositivos.
- AC3: CUANDO un participante abandona o pierde la conexión con la frecu ENTONCES los demás participantes reciben la notificación `peer_left`, liberan la conexión WebRTC asociada y actualizan la lista de participantes en la interfaz.

## Diseño

- **Presentation (`RoomPage`)**:
  - `_ParticipantsHeader`: Muestra el título de participantes junto con el contador reactivo de sala formateado como `(${participants.length}/${NetworkConstants.maxParticipants})`.
  - `_ParticipantsList` y `_ParticipantTile`: Renderizan cada participante de forma reactiva escuchando `roomParticipantsProvider` y `voiceNotifierProvider`.
  - Distintivo de anfitrión: `Chip` con icono distintivo de estrella y etiqueta `t.room.host` cuando `p.isHost` es verdadero.
  - Indicador animado de habla: Avatar dinámico con borde animado (`AnimatedContainer`), color primario y volumen (`Icons.volume_up`), tarjeta resaltada con borde primario y subtítulo `t.room.speaking` activo cuando el participante está transmitiendo audio.
  - Sincronización en tiempo real: Se actualiza dinámicamente con los eventos `peer_joined` y `peer_left`, manteniendo una experiencia fluida sin parpadeos.

## Archivos

- modificar lib/features/room/presentation/pages/room_page.dart — contador de sala, distintivo de anfitrión e indicador reactivo animado de habla en lista de participantes
- modificar test/features/room/presentation/room_flow_test.dart — pruebas de lista reactiva de participantes, contador de sala y badge de anfitrión
- modificar test/features/room/presentation/voice_flow_test.dart — pruebas de indicador de habla reactivo en tiempo real al hablar participantes remotos

## Tareas

- [x] T1: Componentes de UI reactivos en RoomPage con contador de ocupación y distintivo de anfitrión
  - files: lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/room_flow_test.dart
  - ac: AC3
  - verify: fvm flutter test test/features/room/presentation/room_flow_test.dart
- [ ] T2: Indicador y animación de habla en tiempo real para participantes
  - files: lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/voice_flow_test.dart
  - ac: AC2
  - verify: fvm flutter test test/features/room/presentation/voice_flow_test.dart

## Riesgos

- R1: Parpadeos visuales al cambiar rápidamente el estado de habla (talk_state) — mitigación: uso de transiciones suaves con AnimatedContainer y estado derivado eficiente en memoria sin recreaciones innecesarias de árbol de widgets.
