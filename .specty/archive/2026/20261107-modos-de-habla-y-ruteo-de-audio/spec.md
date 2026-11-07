---
kind: epic
---

# Modos de habla y ruteo de audio

## Objetivo

Permitir a los participantes elegir entre el modo Push-to-Talk (PTT) y micrófono abierto para transmitir su voz sin cortes ni renegociaciones, y conmutar el destino del audio entre el altavoz del teléfono, el auricular y dispositivos Bluetooth conectados en tiempo real.

## Fuera de alcance

- Servicio foreground de Android para captura con pantalla apagada (Fase 5).
- Reconexión automática con backoff exponencial tras pérdida de red WiFi (Fase 5).
- Activación por voz con umbral de decibelios (VOX) (fuera de alcance del MVP según AGENTS.md).

## Supuestos

- A1: El paquete `audio_session` y la API WebRTC permiten redirigir la salida de audio hacia el altavoz o dispositivos Bluetooth sin reiniciar la pista de audio o la conexión peer.
  - impacto: alto
- A2: La activación/silenciamiento de PTT se realiza mediante `track.enabled = true/false` de forma instantánea sin requerir renegociación SDP ni generar clics perceptibles.
- A3: Si un dispositivo Bluetooth se conecta o desconecta durante una frecu activa, la sesión de audio actualiza automáticamente la ruta disponible y notifica el cambio a la interfaz.

## Criterios de aceptación

- AC1: CUANDO el usuario conmuta la salida de audio entre altavoz, auricular y Bluetooth ENTONCES la sesión de audio redirige la salida al dispositivo seleccionado y actualiza el icono de ruta de audio en tiempo real.
- AC2: CUANDO se conecta o desconecta un accesorio de audio (auriculares cableados o Bluetooth) ENTONCES el sistema detecta el cambio de periférico y actualiza la ruta de audio activa.
- AC3: CUANDO el usuario opera en modo Push-to-Talk (PTT) ENTONCES el micrófono solo transmite mientras se mantiene presionado el control (en pantalla o mediante botón de hardware) y se silencia inmediatamente al soltarlo sin cortes de audio ni renegociación WebRTC.
- AC4: CUANDO el usuario cambia entre el modo PTT y micrófono abierto ENTONCES la interfaz actualiza los controles visuales correspondientes y el estado de habla se sincroniza con todos los participantes de la sala.

## Diseño

La épica se estructura en dos cortes verticales:
1. **C1 (Ruteo de audio a altavoz, auricular y Bluetooth)**:
   - Dominio: Entidad `AudioRoute` (`speaker`, `earpiece`, `bluetooth`), contrato `VoiceRepository` con `setSpeakerOn(bool)` y `watchAudioRoute()`.
   - Datos: Implementación en `AudioSessionDataSource` y `VoiceRepositoryImpl` para escuchar cambios en periféricos de audio y controlar la ruta de reproducción.
   - Presentación: Control visual en `RoomPage` para alternar la salida de audio y reflejar el dispositivo conectado actual.
2. **C2 (Modos de habla PTT interactivo y micrófono abierto)**:
   - Dominio: Casos de uso de cambio de modo de habla y control de habla reactivo.
   - Presentación: Botón PTT gestual (`onPointerDown`/`onPointerUp`) con respuesta táctil y soporte de teclas físicas de hardware en `RoomPage`, selector de modo de habla y persistencia del modo por defecto en ajustes.

## Cortes

- C1: Ruteo de audio a altavoz, auricular y Bluetooth
  - ac: AC1, AC2
- C2: Modos de habla PTT interactivo y micrófono abierto
  - ac: AC3, AC4
  - depends: C1

## Riesgos

- R1: El comportamiento de ruteo Bluetooth varía según el fabricante y versión de Android/iOS — mitigación: configurar `AudioSession` con `AVAudioSessionCategoryOptions.allowBluetooth` y `AndroidAudioUsage.voiceCommunication` para delegar la conmutación a la capa del sistema operativo con fallback seguro a altavoz.

## Cierre

### Resumen

Se completó en su totalidad la **Fase 4: Modos de habla y ruteo de audio** a través de sus dos cortes verticales:
- **Corte C1 (Ruteo de audio a altavoz, auricular y Bluetooth)**: Conmutación dinámica de ruta de reproducción en `AudioSessionDataSource` y `VoiceRepositoryImpl`, reactividad en `voice_provider` y botón de acción en `RoomPage` con iconos contextuales (`volume_up`, `phone_in_talk`, `bluetooth_audio`) y fallback a altavoz ante desconexiones.
- **Corte C2 (Modos de habla PTT interactivo y micrófono abierto)**: Implementación de botón PTT táctil/gestual (`Listener` con `onPointerDown` y `onPointerUp`/`onPointerCancel`) con respuesta háptica y animaciones, selector de modo de habla (`TalkMode.pushToTalk` vs `TalkMode.openMic`) conmutando instantáneamente sin renegociaciones WebRTC, y refactorización modular de `RoomPage` extrayendo `_PttButton`, `_OpenMicControl` y `_TalkModeSelector` para preservar la legibilidad y cumplir límites de líneas.
- Se verificaron todos los criterios de aceptación (AC1, AC2, AC3, AC4) con una suite completa de pruebas unitarias y de widgets en Flutter (61 pruebas pasando al 100%) y 0 advertencias de análisis estático con `very_good_analysis`.

### Desviaciones

- Ninguna respecto al alcance ni diseño previsto.

### Decisiones

- **Control PTT basado en Pointer events**: Se utilizaron eventos `Listener.onPointerDown` y `onPointerUp/Cancel` en lugar de `GestureDetector.onTapDown` para garantizar una respuesta táctil inmediata y segura ante deslizamientos accidentales o cancelaciones del sistema.
- **Modulación de volumen y silencio sin renegociación**: La activación y corte de voz conmuta puramente `track.enabled` en la pista de audio local, asegurando latencia cero y cero consumo innecesario de señalización.

### Pendientes

- **Fase 5 (Segundo plano y resiliencia)**: Servicio foreground con notificación permanente en Android, background audio en iOS, heartbeats (`ping`/`pong`), reconexión automática con backoff exponencial y gestión robusta de desconexiones imprevistas del anfitrión.
