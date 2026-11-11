---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C5
---

# Traspaso por caída en Wi-Fi compartida, solo datos

## Objetivo

En una frecu local sobre una Wi-Fi que no depende del teléfono del anfitrión, si el anfitrión deja de responder, los demás lo reintentan unos 4 s y luego la toma la primera persona de la sucesión que responda, sin volver a escribir el código; si esa no responde, la siguiente. Los avisos de C4 para la razón `lost` («se desconectó») ya existen: aquí solo cambia la capa de datos. Prototipo aprobado: `docs/diseno/prototipo/anfitrion.js`, grupo «Router o internet · el anfitrión se cae» (en la carpeta principal).

## Fuera de alcance

- La espera en pantalla: isla ««anfitrión» no responde · N s», pista con el sucesor y solo el anfitrión en reconectando (C9).
- El regreso del anfitrión anterior y dos anfitriones a la vez (C10).
- Traspaso por internet y el Worker (C6): una frecu por internet sigue reconectando como hoy.
- Que la voz no se corte durante el traspaso, y volver con el mismo id en una reconexión normal (P158), en C7.
- Cambiar el contrato `RoomRepository`, los campos de `welcome` o las firmas de `start` y `stop` del servidor.

## Supuestos

- A1: Todos detectan la caída del anfitrión con pocos segundos de diferencia (cierre del socket o latido del cliente, `peerTimeout`). Cada uno sigue el mismo plan con la misma sucesión, así que llegan a la misma persona sin hablar entre ellos.
  - impacto: alto
- A2: Quien toma la frecu por caída lo hace sin esperar en su turno del plan; los demás le dan 2 intentos (esperas de 1 s) antes de pasar al siguiente, tiempo de sobra para abrir el servidor.
  - impacto: alto
- A3: «Su red sigue arriba» es que el teléfono tiene alguna dirección que no es loopback (`NetworkReturnWatcher.addresses`).

## Criterios de aceptación

- AC8: CUANDO el anfitrión de una frecu local en una Wi-Fi compartida deja de responder ENTONCES cada invitado lo reintenta dos veces (unos 4 s, en `reconnecting`) y, si no vuelve, sigue la sucesión en orden sin el anfitrión: a cada persona le da 2 intentos en su IP con su mismo id, y si la persona es este teléfono y su red sigue arriba, toma la frecu con el turno siguiente y la razón `lost` (si su red no está arriba, pasa a la siguiente). Quien la recibe emite un `HostChange` propio con razón `lost` y el nombre del anfitrión anterior, y los demás vuelven a ella con su mismo id y emiten un `HostChange` con razón `lost`, el anterior y quien la lleva, sin que la frecu se cierre. Todo `join` lleva el turno que conoce, y un servidor con un turno menor lo rechaza con `stale_term`.

## Diseño

- **Protocolo (aditivo).** `join` gana `term` (opcional, se omite si es nulo): el turno de la sucesión que conoce quien entra. El servidor rechaza con `stale_term` un `join` cuyo `term` supera el suyo; sin `term` (app anterior) entra como hoy. `welcome` no cambia.
- **Plan de caída** (`FailoverPlan` en `room_reconnection.dart`). Con la sucesión (`RoomSuccession`) de una frecu local con traspaso, el anfitrión que se cayó y este teléfono, arma los pasos: 2 reintentos al anfitrión (esperas de 1 s y 2 s, como hoy), y por cada persona de la sucesión sin el anfitrión, 2 intentos a su IP (esperas de 1 s) o, si es este teléfono, tomarla (sin espera). Las esperas escalan con la espera base de las pruebas.
- **`RejoinLoop`.** `run` acepta, opcionales, el número de intentos y la espera de cada uno; sin ellos, se comporta como hoy. `networkUp()` dice si el teléfono tiene red.
- **Repositorio.** Al perder el socket, si conoce la sucesión de una frecu local con traspaso y no está siguiendo un `host_handover`, reconecta con el plan: en los pasos de otra persona apunta la reconexión a su IP con su mismo id (y recuerda el nombre del anfitrión anterior para el `HostChange`); en el suyo, si `networkUp()`, toma la frecu con `_takeOver` de C4 con `term + 1` y la razón `lost`. Sin plan (otras frecus, sin sucesión o tras `host_handover`) reconecta como hoy. `_join` y los reintentos envían el `term` conocido.
- **Toma por caída.** `HostTakeover.openServer` recibe la razón y la pasa a `InheritedRoom`, así el servidor de quien la toma responde `host_changed` con `lost` a quien vuelve a su lugar. `_rejoinAsHost` anuncia la razón que recibe.

## Archivos

- modificar lib/features/room/data/models/signaling_message.dart — `term` del `join` y `RejectReason.staleTerm`.
- modificar lib/features/room/data/models/signaling_message.freezed.dart — regenerado por build_runner.
- modificar lib/features/room/data/models/signaling_message.g.dart — regenerado por build_runner.
- modificar lib/features/room/data/datasources/signaling_server_datasource.dart — rechazo por turno.
- modificar lib/features/room/data/repositories/room_reconnection.dart — `FailoverPlan`, pasos de `RejoinLoop`, `networkUp` y razón de la toma.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — reconexión con el plan, toma por caída y `term` en el `join`.
- crear test/features/room/data/signaling_term_test.dart — `term` en el `join` y rechazo `stale_term` (AC8).
- crear test/features/room/data/host_failover_test.dart — caída, toma por el primero de la sucesión y salto al siguiente, con servidores reales en 127.0.0.1 (AC8).
- modificar docs/protocolo.md — `term` del `join` y `stale_term`.

## Tareas

- [x] T1: Turno en el `join` y rechazo `stale_term`
  - files: lib/features/room/data/models/signaling_message.dart, lib/features/room/data/models/signaling_message.freezed.dart, lib/features/room/data/models/signaling_message.g.dart, lib/features/room/data/datasources/signaling_server_datasource.dart, test/features/room/data/signaling_term_test.dart, docs/protocolo.md
  - ac: AC8
  - verify: flutter test test/features/room/data/signaling_term_test.dart test/features/room/data/signaling_access_test.dart test/features/room/data/signaling_server_test.dart
- [ ] T2: Plan de caída: reintentos al anfitrión, sucesión en orden y toma por quien siga en la red
  - files: lib/features/room/data/repositories/room_reconnection.dart, lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/host_failover_test.dart
  - ac: AC8
  - verify: flutter test test/features/room/data/host_failover_test.dart test/features/room/data/room_handover_test.dart test/features/room/data/room_reconnect_test.dart test/features/room/data/room_succession_test.dart

## Riesgos

- R1: Dos teléfonos toman la frecu a la vez por una partición — queda para C10 (gana el turno mayor); aquí el plan es el mismo para todos.
- R2: El sucesor no puede abrir el puerto 47800 o no tiene red — su toma falla (`_giveUp`) o se salta, y los demás pasan al siguiente tras 2 intentos.
- R3: `room_repository_impl.dart` ya es grande (P159, P162) — el plan y sus pasos viven en `room_reconnection.dart`; el repositorio solo los conecta.
- R4: En pruebas todos están en 127.0.0.1 y en el mismo puerto — la caída se simula con un proxy TCP que se corta delante del anfitrión, y quien la toma abre su servidor en el puerto del proxy.
