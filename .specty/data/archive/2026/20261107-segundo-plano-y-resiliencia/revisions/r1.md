---
kind: epic
---

# Segundo plano y resiliencia

## Objetivo

Garantizar que una frecu activa permanezca conectada y transmitiendo/recibiendo voz en segundo plano y con la pantalla apagada mediante un servicio en primer plano (foreground service) con notificación persistente, incorporando monitoreo de liveness (heartbeats ping/pong), reconexión automática resiliente con backoff exponencial y cierre ordenado de la sala si el anfitrión se desconecta.

## Fuera de alcance

- Migración de anfitrión (si el anfitrión se desconecta o sale de la frecu, la frecu se cierra para todos los participantes según AGENTS.md).
- Onboarding inicial de permisos y guía de configuración de hotspot (Fase 6).

## Supuestos

- A1: En Android, un Foreground Service de tipo `microphone` / `connectedDevice` con notificación permanente evita que el sistema operativo mate el proceso o suspenda la CPU y el socket de red local cuando la pantalla se apaga.
  - impacto: alto
- A2: El intercambio periódico de `ping` y `pong` cada 5 segundos permite detectar la pérdida de enlace antes de que el socket TCP/WebSocket reporte timeout.
- A3: Tras una pérdida de conexión no intencional, el cliente participante intenta reconectarse automáticamente hasta 5 veces con backoff exponencial antes de declarar la sala como cerrada o inalcanzable.

## Criterios de aceptación

- AC1: CUANDO la aplicación pasa a segundo plano o se apaga la pantalla durante una frecu activa ENTONCES el servicio en primer plano mantiene activos los sockets de señalización y las pistas de audio WebRTC sin interrupciones perceptibles.
- AC2: CUANDO el cliente o el servidor no reciben respuesta de `ping`/`pong` dentro del umbral de timeout ENTONCES la conexión se marca como interrumpida y se activa el estado `reconnecting`.
- AC3: CUANDO un participante sufre una desconexión temporal de la red WiFi ENTONCES el cliente intenta reconectarse automáticamente con backoff exponencial y reestablece la sesión y las conexiones peer WebRTC si el anfitrión sigue disponible.
- AC4: CUANDO el anfitrión abandona la frecu o se cierra el servidor ENTONCES todos los participantes reciben la notificación `room_closed`, detienen sus conexiones y servicio foreground, y regresan al Lobby informando el motivo del cierre.

## Diseño

La épica se estructura en dos cortes verticales:
1. **C1 (Heartbeats, reconexión con backoff y cierre de frecu)**:
   - Dominio: Estado `RoomStatus.reconnecting`, use cases y políticas de backoff exponencial y watchdog de heartbeats (`ping`/`pong`).
   - Datos: Implementación de timer de heartbeats en `SignalingClientDataSource` y `SignalingServerDataSource`, y ciclo de reconexión automática en `RoomRepositoryImpl`.
   - Presentación: Notificaciones visuales de estado de conexión en `RoomPage` (reconectando, reconectado o sala cerrada con diálogo informativo).
2. **C2 (Servicio foreground y persistencia en segundo plano)**:
   - Integración del plugin `flutter_foreground_task` con notificación de estado de sala ("Frecu activa").
   - Configuración de ciclo de vida de la app para iniciar el foreground task al unirse/crear la frecu y detenerlo al salir.
   - Verificación de permisos y capacidades de background audio.

## Cortes

- C1: Heartbeats, reconexión con backoff y cierre de frecu
  - ac: AC2, AC3, AC4
- C2: Servicio foreground y persistencia en segundo plano
  - ac: AC1
  - depends: C1

## Riesgos

- R1: Agresividad de los fabricantes de Android en la gestión de batería que matan procesos en segundo plano — mitigación: Foreground Service con notificación permanente, wake lock controlado y `androidAudioFocusGainType: gainTransient` en `audio_session`.
