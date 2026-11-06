---
kind: epic
---

# Frecu multiparticipante y topología mesh

## Objetivo

Habilitar conversaciones grupales de voz en tiempo real con topología mesh (malla completa) de hasta 6 participantes simultáneos sin internet en una frecu activa, sincronizando la lista de participantes, indicadores de habla en tiempo real y gestionando el límite de sala y la salida o desconexión de participantes.

## Fuera de alcance

- Botones de volumen físicos para PTT y ruteo a audífonos Bluetooth (Fase 4).
- Servicio foreground en Android y audio background en iOS para supervivencia con pantalla apagada (Fase 5).
- Reconexión automática con backoff exponencial al salir y volver de rango WiFi (Fase 5).
- Servidor de mezcla SFU o MCU en el anfitrión (el diseño es mesh puro descentralizado para audio según AGENTS.md).

## Supuestos

- A1: Todos los participantes están conectados a la misma red local WiFi / Hotspot del anfitrión, permitiendo conexiones WebRTC directas peer-to-peer sin requerir servidores STUN o TURN.
  - impacto: alto
- A2: La topología mesh previene el *glare* haciendo que el nuevo participante entrante cree las ofertas SDP hacia los participantes existentes recibidos en el mensaje `welcome`.
- A3: El número máximo de participantes concurrentes en una frecu es 6 (`NetworkConstants.maxParticipants = 6`). Intentos posteriores recibirán un mensaje `rejected` con motivo `roomFull`.

## Criterios de aceptación

- AC1: CUANDO hasta 6 participantes se unen a la frecu ENTONCES cada nuevo participante negocia y establece una conexión WebRTC independiente con todos los participantes ya presentes en la sala formando una malla completa (mesh).
- AC2: CUANDO un participante habla en la frecu ENTONCES su voz se transmite simultáneamente a todos los demás participantes de la malla y su indicador de habla se activa en tiempo real en la lista de participantes de todos los dispositivos.
- AC3: CUANDO un participante abandona o pierde la conexión con la frecu ENTONCES los demás participantes reciben la notificación `peer_left`, liberan la conexión WebRTC asociada y actualizan la lista de participantes en la interfaz.
- AC4: CUANDO un séptimo participante intenta unirse a una frecu con 6 participantes activos ENTONCES el servidor de señalización rechaza la conexión con motivo `roomFull` y la aplicación del participante muestra la notificación de sala llena.

## Diseño

La épica se estructura en dos cortes verticales:
1. **C1 (Malla WebRTC multiparticipante y límite de sala)**:
   - Verificación y consolidación de la señalización multipar en `SignalingServerDataSource` y enrutamiento punto a punto de `offer`, `answer` e `ice` para hasta 6 participantes concurrentes con rechazo estricto de `roomFull`.
   - Gestión concurrente de hasta 5 `RTCPeerConnection`s en `PeerConnectionDataSource` y `VoiceRepositoryImpl`, configuración de pistas de audio y limpieza en desconexión.
2. **C2 (Lista reactiva de participantes e indicador de habla)**:
   - Integración visual en `RoomPage` con visualización de participantes (hasta 6), distintivo de anfitrión, contador de sala y animación/indicador de habla reactivo (`isSpeaking`).
   - Sincronización en tiempo real de eventos `peer_joined` y `peer_left` en la interfaz de la sala.

## Cortes

- C1: Malla WebRTC multiparticipante y límite de sala
  - ac: AC1, AC4
- C2: Lista reactiva de participantes e indicador de habla
  - ac: AC2, AC3
  - depends: C1

## Riesgos

- R1: La topología mesh para N participantes implica N-1 conexiones de audio por dispositivo — mitigación: límite estricto de 6 participantes y restricciones de audio mono de bajo ancho de banda (echoCancellation, noiseSuppression, autoGainControl) sin video.
