---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C11
---

# Por internet, el anfitrión anterior que vuelve con un turno menor entra como invitado en lugar de reintentar su relé

## Objetivo

Por internet, cuando el anfitrión anterior recupera la red después de que otra persona tomó la frecu con un turno mayor, la nube rechaza su relé (409) y hoy él lo reintenta sin fin, solo en su frecu. Con este cambio deja de ser anfitrión, vuelve a la frecu como invitado por el mismo enlace, con su mismo id, y ve «Volviste como invitado · «nombre» lleva la frecu» (P180).

## Fuera de alcance

- Cambios en el Worker (`cloud/`): el 409 ya basta para saber que otro lleva la frecu, y el cliente no necesita el turno vigente. No se despliega nada (P179).
- Que el sucesor que toma la frecu por caída y recibe un 409 al abrir su relé (otro la tomó antes) entre como invitado: sigue como hoy (da la frecu por perdida).
- El regreso del anfitrión anterior en una frecu local (ya en C10) y la voz durante el traspaso (C7).
- Cambios en el contrato `RoomRepository`, en `SignalingMessage` o en las pantallas: se reutiliza `HostChangeReason.outranked` y su aviso de C10.

## Supuestos

- A1: El 409 al abrir el relé de anfitrión solo significa que otro lleva la frecu con un turno mayor (contrato del Worker de C6).
  - impacto: alto
- A2: El cierre 4000 («Anfitrión reemplazado») en el socket vigente del relé significa que otro anfitrión con el mismo secreto y un turno igual o mayor tomó la sala. Cuando es el mismo teléfono el que reconecta, el 4000 llega al socket viejo, que el relé ya no usa, y se ignora.
  - impacto: alto
- A3: `IOWebSocketChannel.connect` (dart:io) conserva el código HTTP del rechazo en `WebSocketException.httpStatusCode`; `WebSocketChannel.connect` lo pierde. La app solo corre en Android e iOS.
  - impacto: alto
- A4: El servidor de quien lleva la frecu acepta que el anterior vuelva con su id en `join.peerId`, como en C10; si no le guarda el lugar, entra con un id nuevo.

## Criterios de aceptación

- AC1: CUANDO el anfitrión anterior de una frecu por internet recupera la red y la nube rechaza su relé con 409 porque otro la tomó con un turno mayor ENTONCES deja de reintentar el relé, cierra su servidor, vuelve por el socket de invitado de la frecu (`guestSocket(internetId)`) con su mismo id y sin volver a escribir el código, y emite `HostChange(you: false, reason: outranked)` con el id y el nombre de quien la lleva. Quien la lleva lo ve como invitado, y la nube no vuelve a recibir su turno viejo.
- AC2: CUANDO la nube cierra el socket vigente del relé del anfitrión con el código 4000 (otro anfitrión con el mismo secreto tomó la sala) ENTONCES el relé no vuelve a conectar y avisa, igual que con el 409.
- AC3: CUANDO el relé falla por otra causa (sin red, 403, 404, 503 o un cierre con otro código) ENTONCES sigue reconectando como hoy, sin avisar.

## Diseño

- **Relé (`cloud_relay_datasource.dart`).** Gana `onOutranked` (callback, como `onRival` del servidor). Un intento de reconexión que falla con `httpStatusCode == 409`, o el socket vigente que se cierra con 4000, detiene la reconexión (la generación queda sin `uri`) y llama a `onOutranked` una vez. El canal por defecto pasa a `IOWebSocketChannel.connect` para leer el código HTTP. `CloudRelayDataSource.isOutranked(error)` reconoce el 409 dentro de `WebSocketChannelException.inner`.
- **Repositorio.** En el constructor, `_relay.onOutranked = _onRelayOutranked`. `_yieldTo` (C10) se generaliza: si la frecu es por internet, detiene el relé y el servidor (sin `host_handover`: sus invitados ya volvieron solos a la nube), y apunta la reconexión al socket de invitado con su id; el resto (dejar de ser anfitrión, `_following`, el aviso `outranked` al llegar el `welcome`) es el de C10. La lógica nueva va en el relé; el repositorio solo suma el enlace y la rama de internet.
- **Pruebas.** Un punto de encuentro falso con `shelf` (como el de `internet_handover_test.dart`) que puede dejar sin red al anfitrión anterior mientras otro toma la frecu, y pruebas del relé con un servidor `shelf` que responde 409, 404 o cierra con 4000.

## Archivos

- modificar lib/features/room/data/datasources/cloud_relay_datasource.dart — reconocer el 409 y el cierre 4000, dejar de reconectar y avisar con `onOutranked`; canal con código HTTP.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — al aviso del relé, ceder como en C10 y volver por el socket de invitado.
- crear test/features/room/data/cloud_relay_outranked_test.dart — 409, 4000 y otras caídas en el relé (AC2, AC3).
- crear test/features/room/data/internet_outranked_test.dart — el anfitrión anterior vuelve por internet y entra como invitado (AC1).

## Tareas

- [ ] T1: El relé reconoce el 409 y el cierre 4000, deja de reconectar y avisa
  - files: lib/features/room/data/datasources/cloud_relay_datasource.dart, test/features/room/data/cloud_relay_outranked_test.dart
  - ac: AC2, AC3
  - verify: flutter test test/features/room/data/cloud_relay_outranked_test.dart test/features/room/data/internet_room_test.dart
- [ ] T2: El anfitrión anterior cede por internet y vuelve como invitado
  - files: lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/internet_outranked_test.dart
  - ac: AC1
  - verify: flutter test test/features/room/data/internet_outranked_test.dart test/features/room/data/internet_handover_test.dart test/features/room/data/host_rivalry_test.dart test/features/room/data/room_succession_test.dart

## Riesgos

- R1: Un 4000 que no viene de otro anfitrión haría ceder al anfitrión legítimo — solo cuenta en el socket vigente, y el mismo teléfono que reconecta recibe el 4000 en el socket viejo, que se ignora. Ceder deja la frecu en manos de quien la lleva, sin cerrarla.
- R2: Cambiar el canal por defecto del relé — `IOWebSocketChannel` usa el mismo `WebSocket.connect` de dart:io que `WebSocketChannel.connect` en Android e iOS; las pruebas de la frecu por internet lo cubren.
- R3: `room_repository_impl.dart` ya es grande (P162) — la detección vive en el relé y el repositorio reutiliza `_yieldTo` de C10 en lugar de sumar otro camino.
