---
kind: epic
---

# Prueba de concepto de audio

## Objetivo

Implementar la Fase 1 de Frecu: prueba de concepto de voz grupal offline entre dos teléfonos (anfitrión y participante con IP ingresada manualmente) mediante un servidor de señalización WebSocket local en el anfitrión y audio en tiempo real con WebRTC en modo micrófono abierto.

## Fuera de alcance

- Descubrimiento automático por mDNS y escaneo de códigos QR (Fase 2).
- Topología mesh para más de dos participantes (Fase 3).
- Modo Push-to-Talk (PTT) y ruteo dinámico de hardware Bluetooth (Fase 4).
- Servicio en primer plano y reconexión en segundo plano (Fase 5).

## Supuestos

- A1: Ambos dispositivos se encuentran en la misma subred local (hotspot WiFi del anfitrión o router WiFi sin acceso a internet).
- A2: La IP del anfitrión se puede consultar en su interfaz de red y mostrar en pantalla para que el participante la escriba a mano.
- A3: WebRTC opera estrictamente con `iceServers: []` utilizando candidatos locales sin servidores STUN ni TURN.

## Criterios de aceptación

- AC1: CUANDO el anfitrión inicia la sala ENTONCES se ejecuta el servidor WebSocket de señalización en el puerto 47800 y responde a los mensajes de protocolo local.
- AC2: CUANDO un participante introduce la IP del anfitrión y solicita unirse ENTONCES el cliente WebSocket se conecta, valida el protocolo con mensajes `join`/`welcome` y la interfaz refleja el estado conectado de ambos participantes.
- AC3: CUANDO ambos dispositivos se encuentran conectados en la sala ENTONCES se negocia una conexión WebRTC punto a punto con pistas de audio locales y se establece transmisión bidireccional en modo micrófono abierto.
- AC4: CUANDO un participante o el anfitrión decide salir de la sala ENTONCES se cierran limpiamente las conexiones WebRTC, los WebSockets y se liberan las sesiones de audio.

## Diseño

- La épica se divide en tres cortes verticales de tamaño controlado:
  1. **C1 (Protocolo y señalización WebSocket)**: Entidades base de Room, DTOs de señalización Freezed, servidor Shelf WebSocket y cliente WebSocket con loopback para anfitrión.
  2. **C2 (Gestión de sala y conexión por IP)**: Repositorio de sala, notifiers de Riverpod y pantallas de anfitrión/participante para crear sala con IP visible o unirse ingresando IP a mano.
  3. **C3 (Audio WebRTC bidireccional)**: Conexión RTCPeerConnection mesh offline (`iceServers: []`), `audio_session` en modo voiceChat, negociación SDP/ICE y transmisión con micrófono abierto.

## Cortes

- C1: Protocolo y señalización WebSocket
  - ac: AC1
- C2: Gestión de sala y conexión por IP
  - ac: AC2
  - depends: C1
- C3: Audio WebRTC bidireccional con micrófono abierto
  - ac: AC3, AC4
  - depends: C2

## Riesgos

- R1: El emulador o simulador puede no contar con dispositivos físicos de audio — mitigación: abstraer el acceso a hardware en datasources para permitir pruebas unitarias con transporte simulado y dobles de prueba.

## Cierre

### Resumen

Se completaron satisfactoriamente los 3 cortes verticales de la Fase 1 (Prueba de concepto de audio):

- **C1**: Implementación de entidades de dominio de sala y participantes, modelos de mensajes de señalización con discriminador Freezed, servidor Shelf WebSocket en puerto 47800 y cliente WebSocket reactivo.
- **C2**: Repositorio de sala, detección automática de IP local IPv4 del anfitrión, providers de Riverpod (`RoomNotifier`) y pantallas `CreateRoomPage`, `LobbyPage` (modal de unión por IP) y `RoomPage`.
- **C3**: Configuración de `audio_session`, `PeerConnectionDataSource` para WebRTC mesh local con candidatos directos (`iceServers: []`), `VoiceRepositoryImpl` para control de transmisión/muteo sin renegociación WebRTC, `VoiceNotifier` y controles de interfaz de micrófono en `RoomPage`.
- Todos los criterios de aceptación (AC1 a AC4) quedaron verificados con 29 pruebas automatizadas pasando con éxito.

### Desviaciones

- Ninguna respecto al alcance planificado de la Fase 1. Las ampliaciones menores de alcance durante las tareas correspondieron al desacoplamiento para inyección de dependencias (`signalingClientProvider`).

### Decisiones

- Se adoptó una arquitectura estricta Clean Architecture por feature (`domain`, `data`, `presentation`), manteniendo `domain` libre de plugins nativos o dependencias de Flutter.
- WebRTC opera exclusivamente con candidatos ICE de red de área local (`iceServers: []`) sin servidores STUN ni TURN externos para garantizar funcionamiento 100% autónomo sobre Hotspot.
- La gestión de estado y DI se basa en la sintaxis de generador de Riverpod (`@riverpod`, `Notifier`), y la inmutabilidad en Freezed 3 (`sealed class`).

### Pendientes

- Fase 2: Descubrimiento de salas por mDNS (`nsd`) y respaldo por código QR (`mobile_scanner` / `qr_flutter`).
- Fase 2/3: Soporte para más de 2 participantes en malla completa (hasta 6) y modo PTT con botones de hardware.
- Fase 5: Servicio foreground en Android para mantener transmisión con pantalla apagada.
