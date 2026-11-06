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

- AC1: CUANDO el anfitrión crea una sala ENTONCES se inicia el servidor WebSocket de señalización en el puerto 47800 y se muestra su dirección IP local para permitir la conexión.
- AC2: CUANDO un participante introduce la IP del anfitrión y solicita unirse ENTONCES el cliente WebSocket se conecta, valida el protocolo con mensajes `join`/`welcome` y la sala queda en estado `connected` con ambos participantes.
- AC3: CUANDO ambos dispositivos se encuentran conectados en la sala ENTONCES se negocia una conexión WebRTC punto a punto con pistas de audio locales y se establece transmisión bidireccional en modo micrófono abierto.
- AC4: CUANDO un participante o el anfitrión decide salir de la sala ENTONCES se cierran limpiamente las conexiones WebRTC, los WebSockets y se liberan las sesiones de audio.

## Diseño

- La épica se divide en dos cortes verticales:
  1. **C1 (Señalización y sala)**: Dominio de Room, DTOs de señalización, servidor Shelf WebSocket en anfitrión, cliente WebSocket con loopback para anfitrión, y UI para crear sala o unirse por IP manual con lista de participantes y estados de conexión.
  2. **C2 (Audio WebRTC bidireccional)**: Conexión RTCPeerConnection mesh offline (`iceServers: []`), configuración de `audio_session` (categoría `playAndRecord`, modo `voiceChat`), negociación de SDP/ICE vía señalización existente, y captura/reproducción de micrófono abierto.

## Cortes

- C1: Señalización WebSocket y gestión de sala
  - ac: AC1, AC2
- C2: Audio WebRTC bidireccional con micrófono abierto
  - ac: AC3, AC4
  - depends: C1

## Riesgos

- R1: El emulador o simulador puede no contar con dispositivos físicos de audio — mitigación: abstraer el acceso a hardware en datasources para permitir pruebas unitarias con transporte simulado y dobles de prueba.
