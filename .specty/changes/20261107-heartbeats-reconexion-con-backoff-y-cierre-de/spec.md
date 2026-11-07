---
kind: standard
epic: 20261107-segundo-plano-y-resiliencia
slice: C1
---

# Heartbeats, reconexión con backoff y cierre de frecu

## Objetivo

Implementar el monitoreo continuo de conexión mediante heartbeats periódicos (`ping`/`pong`), la transición y recuperación automática con backoff exponencial ante interrupciones de red local (`RoomStatus.reconnecting`), y el cierre limpio de la sala (`room_closed`) informando a los participantes en la interfaz cuando el anfitrión finaliza la frecu o se pierde el servidor.

## Fuera de alcance

- Servicio foreground de Android y soporte de pantalla apagada (Corte C2).
- Migración de anfitrión (si el anfitrión se desconecta, la sala finaliza para todos).
- STUN/TURN o señalización en la nube (comunicación exclusiva en red de área local).

## Supuestos

- A1: El intervalo de heartbeats es de 5 segundos (`NetworkConstants.heartbeatInterval`) y el umbral de desconexión por inactividad es de 15 segundos (`NetworkConstants.peerTimeout`).
  - impacto: alto
- A2: Los clientes intentan reconectarse automáticamente al anfitrión hasta 5 veces con backoff exponencial duplicando el retardo hasta un máximo de 15 segundos (`NetworkConstants.maxReconnectBackoff`).
- A3: Cuando el anfitrión sale o el servidor se detiene, emite el mensaje `room_closed` a todos los clientes antes de cerrar los canales de comunicación.
- A4: En `RoomPage`, el estado `RoomStatus.reconnecting` muestra un indicador visible de reconexión y `RoomStatus.closed` alerta al usuario permitiendo volver al Lobby.

## Criterios de aceptación

- AC2: CUANDO el cliente o el servidor no reciben actividad ni respuesta de `ping`/`pong` dentro del umbral de timeout ENTONCES la conexión se marca como interrumpida y se activa el estado `reconnecting`.
- AC3: CUANDO un participante sufre una desconexión temporal de la red local ENTONCES el cliente intenta reconectarse automáticamente con backoff exponencial y reestablece la sesión y el estado de la sala si el anfitrión vuelve a estar disponible.
- AC4: CUANDO el anfitrión abandona la frecu o se cierra el servidor ENTONCES todos los participantes reciben la notificación `room_closed`, transicionan a `RoomStatus.closed` y `RoomPage` alerta al usuario para salir al Lobby.

## Diseño

- **Data / Signaling**:
  - `SignalingClientDataSource`: Temporizador periódico para el envío de `SignalingMessage.ping` y watchdog de recepción de datos/`pong` que dispara la desconexión ante timeout. Intervalos configurables para pruebas unitarias rápidas.
  - `SignalingServerDataSource`: Monitoreo de actividad por par mediante watchdog de `peerTimeout` y respuesta automática a `ping` con `pong`. Cierre ordenado con difusión de `room_closed(reason)` en `stop()`.
- **Data / Repository**:
  - `RoomRepositoryImpl`: Persistencia en memoria de los parámetros de conexión de sala activa para permitir la reconexión. Detección de pérdida de conexión en el cliente y ejecución del bucle de reconexión con backoff exponencial. Transición a `RoomStatus.reconnecting()` y regreso a `RoomStatus.connected()` tras reestablecerse, o `RoomStatus.closed(reason: 'host_unreachable')` al agotarse los intentos.
- **Presentation**:
  - `RoomInfoCard` / `RoomPage`: Señalización visual reactiva cuando el estado pasa a `reconnecting` (banner o texto de reconexión) y diálogo/alerta informativa cuando la sala pasa a `closed`, redirigiendo al usuario al Lobby.
  - `i18n`: Nuevas cadenas de traducción para reconexión y estados en español e inglés.

## Archivos

- modificar lib/features/room/data/datasources/signaling_client_datasource.dart — latidos periódicos ping/pong y watchdog de timeout
- modificar lib/features/room/data/datasources/signaling_server_datasource.dart — watchdog de inactividad de pares y respuesta a pongs
- modificar lib/features/room/data/repositories/room_repository_impl.dart — gestión de reconexión con backoff exponencial y cierre de sala
- modificar lib/features/room/presentation/pages/room_page.dart — visualización de reconexión y alerta de cierre de sala
- modificar lib/features/room/presentation/widgets/room_info_card.dart — indicador visual de reconectando
- modificar lib/i18n/strings.i18n.json — textos de reconexión en español
- modificar lib/i18n/strings_en.i18n.json — textos de reconexión en inglés
- modificar lib/i18n/strings.g.dart — clases generadas de traducción
- modificar lib/i18n/strings_en.g.dart — clases generadas de traducción en inglés
- modificar lib/i18n/strings_es.g.dart — clases generadas de traducción en español
- modificar test/features/room/data/signaling_server_test.dart — pruebas de heartbeats y detección de timeout en servidor
- modificar test/features/room/data/room_repository_test.dart — pruebas de reconexión con backoff y cierre de sala
- modificar test/features/room/presentation/room_flow_test.dart — pruebas de flujo de UI para reconexión y cierre de sala

## Tareas

- [x] T1: Monitoreo de liveness con heartbeats y watchdog en SignalingClientDataSource y SignalingServerDataSource
  - files: lib/features/room/data/datasources/signaling_client_datasource.dart, lib/features/room/data/datasources/signaling_server_datasource.dart, test/features/room/data/signaling_server_test.dart
  - ac: AC2
  - verify: cd '/Users/innovacloud/Jorge Palacio/Proyectos/Frecu/.worktrees/20261107-heartbeats-reconexion-con-backoff-y-cierre-de' && fvm flutter test test/features/room/data/signaling_server_test.dart
- [x] T2: Reconexión automática con backoff exponencial y propagación de cierre de sala en RoomRepositoryImpl
  - files: lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/room_repository_test.dart
  - ac: AC2, AC3, AC4
  - verify: cd '/Users/innovacloud/Jorge Palacio/Proyectos/Frecu/.worktrees/20261107-heartbeats-reconexion-con-backoff-y-cierre-de' && fvm flutter test test/features/room/data/room_repository_test.dart
- [x] T3: Indicadores de reconexión y diálogo de cierre de sala en RoomPage y RoomInfoCard
  - files: lib/features/room/presentation/pages/room_page.dart, lib/features/room/presentation/widgets/room_info_card.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_en.g.dart, lib/i18n/strings_es.g.dart, test/features/room/presentation/room_flow_test.dart
  - ac: AC3, AC4
  - verify: cd '/Users/innovacloud/Jorge Palacio/Proyectos/Frecu/.worktrees/20261107-heartbeats-reconexion-con-backoff-y-cierre-de' && fvm flutter test test/features/room/presentation/room_flow_test.dart

## Riesgos

- R1: Reintentos de reconexión rápidos podrían saturar la red o colisionar en reconexiones simultáneas — mitigación: el backoff exponencial con duplicación gradual (1s, 2s, 4s...) y tope de 15 segundos evita tormentas de reconexión.
