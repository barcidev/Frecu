---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C6
---

# Traspaso por internet: Worker con gracia, turno y sucesor; voluntario y por caída

## Objetivo

Una frecu por internet sobrevive a la salida o a la caída de su anfitrión, como ya pasa en una Wi-Fi compartida. El Worker la mantiene abierta unos 10 s sin anfitrión y acepta como anfitrión al sucesor que presenta el mismo secreto con un turno mayor. En la app, «tomar la frecu» por internet es abrir el relé de anfitrión con ese secreto y el turno siguiente, y los demás vuelven por su socket de invitado con su mismo id. El enlace y el QR no cambian.

## Fuera de alcance

- Desplegar el Worker (`wrangler deploy`): lo decide la persona. Hasta entonces, el Worker desplegado ignora el turno y cierra a los invitados como hoy.
- Que el anfitrión anterior que vuelve por internet con un turno menor entre como invitado: el Worker lo rechaza (409), pero la app no lo convierte en invitado (sigue reintentando su relé).
- Que la voz no se corte durante el traspaso (C7) y las pruebas en teléfonos reales (AC12).
- Cambiar el contrato `RoomRepository`, `SignalingMessage.welcome`, `CloudConfig`, las pantallas o los textos.

## Supuestos

- A1: El Durable Object puede mantener abiertos los sockets de los invitados sin anfitrión y cerrar la sala con una alarma al acabar la gracia (10 s).
  - impacto: alto
- A2: Los cambios son aditivos. El Worker desplegado ignora el parámetro `term`. Una app anterior descarta `{"t":"host_lost"}` (no es un mensaje del protocolo) y, sin `term`, el Worker cierra a sus invitados como hoy.
  - impacto: alto
- A3: Durante la gracia no hay cola en el Worker: un invitado que se conecta sin anfitrión recibe 404 y reintenta según su plan.
- A4: El sucesor abre su servidor de señalización en un puerto libre cualquiera: por internet nadie se conecta a él directamente, solo su propio cliente y el relé.

## Criterios de aceptación

- AC11: CUANDO el anfitrión de una frecu por internet, conectado con su turno (`?term=N`), se cae ENTONCES el Worker no cierra a los invitados durante la gracia (10 s) y les envía `{"t":"host_lost"}`. Acepta como anfitrión a quien presenta el mismo secreto con un turno igual o mayor, y si hay uno conectado con un turno menor lo retira (4000) y cierra a sus invitados. Rechaza con 409 a quien llega con un turno menor que el vigente. Si nadie toma la frecu en la gracia, cierra a los invitados (1001) y no admite invitados nuevos (404). Un anfitrión sin turno (app anterior) sigue como hoy: al caer, se cierran sus invitados.
- AC7: CUANDO el anfitrión de una frecu por internet la pasa a otra persona ENTONCES quien la recibe abre el relé de anfitrión con el mismo id, el mismo secreto y el turno siguiente, y emite `HostChange(you: true, reason: left)` con el nombre del anterior. Los demás vuelven por su socket de invitado con su mismo id, ven a quien la recibe como anfitrión y sin el anterior, y emiten `HostChange(reason: left)` con su nombre. La frecu conserva su id por internet (el enlace y el QR siguen sirviendo).
- AC8: CUANDO el anfitrión de una frecu por internet se cae ENTONCES cada invitado, al recibir `host_lost` (o al perder el socket), sigue el plan de caída con la sucesión: reintenta dos veces y luego la toma la primera persona de la sucesión que tiene red, abriendo el relé con el turno siguiente y razón `lost`. Los demás vuelven por su socket de invitado con su mismo id y emiten `HostChange(reason: lost)` con el nombre de quien la lleva.

## Diseño

- **Worker (`cloud/src/room.ts`).** El socket del anfitrión acepta `term` (entero ≥ 1, opcional; mal formado → 400). Se guarda el turno vigente (`term` en el almacenamiento) y el adjunto del socket lleva su turno. Un anfitrión con un turno menor que el vigente → 409. Con uno igual o mayor, retira al anterior (4000) y cierra a sus invitados (1012), como hoy; si es mayor, el turno vigente sube. Sin `term` cuenta como 0, así que una app anterior sigue igual en sus propias salas. Al caer un anfitrión con turno empieza la gracia: los invitados siguen abiertos, reciben `{"t":"host_lost"}`, se guarda la marca de gracia y se pone la alarma a 10 s (`HOST_GRACE_MS`). Si la alarma llega sin anfitrión y con la marca, cierra a los invitados (1001, «El anfitrión no volvió») y programa el olvido de 24 h de siempre. Un anfitrión que llega quita la marca y la alarma.
- **Cliente (`signaling_client_datasource.dart`).** Un `{"t":"host_lost"}` del Worker cierra el socket como una caída: el repositorio entra en su reconexión o en su plan de caída de siempre.
- **Pieza nueva `internet_handover.dart` (`data/repositories`).** `InternetHandover.hostSocket(config, id, secret, term)` arma el socket del anfitrión con `term`, y `InternetHandover.openRelay(relay, config, state, term, onGuest:)` abre el relé de quien toma la frecu con el `internetId` y el `hostSecret` de `room_state`. El anfitrión que crea la frecu ya se conecta con `term=1`.
- **Plan de caída (`room_reconnection.dart`).** `FailoverPlan` incluye por internet a todas las personas de la sucesión, aunque no tengan IP (`internet`). `HostTakeover.openServer` no guarda una IP vacía como la del anfitrión.
- **Repositorio.** Sin lógica nueva más allá de elegir la rama de internet: el plan de caída rige también por internet (si hay `hostSecret`). Seguir a alguien por internet es volver al mismo socket de invitado con `join.peerId`; tomar la frecu es `openServer` (puerto libre, sin IP) y `InternetHandover.openRelay`, y luego unirse a sí mismo como hoy. `host_handover` por internet no necesita la IP de quien la recibe.

## Archivos

- modificar cloud/src/room.ts — turno vigente, gracia con `host_lost` y alarma, 409 a un turno menor.
- crear cloud/test/handover.test.ts — gracia, sucesor con turno mayor, 409, cierre al acabar la gracia y anfitrión sin turno (AC11).
- modificar cloud/README.md — contrato del Worker: `term`, gracia y `host_lost`.
- crear lib/features/room/data/repositories/internet_handover.dart — socket del anfitrión con turno y relé de quien toma la frecu.
- modificar lib/features/room/data/repositories/room_reconnection.dart — plan de caída por internet y `openServer` sin IP.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — rama de internet en el traspaso, la caída y la creación con turno.
- modificar lib/features/room/data/datasources/signaling_client_datasource.dart — `host_lost` cierra el socket.
- crear test/features/room/data/internet_handover_test.dart — traspaso voluntario y por caída por internet con un punto de encuentro falso con turno y gracia (AC7, AC8).
- modificar docs/protocolo.md — traspaso por internet, `term` y `host_lost`.

## Tareas

- [x] T1: Worker con turno, gracia y sucesor
  - files: cloud/src/room.ts, cloud/test/handover.test.ts, cloud/README.md
  - ac: AC11
  - verify: cd cloud && npm test && npm run typecheck
- [ ] T2: La app toma la frecu por internet, de forma voluntaria y por caída
  - files: lib/features/room/data/repositories/internet_handover.dart, lib/features/room/data/repositories/room_reconnection.dart, lib/features/room/data/repositories/room_repository_impl.dart, lib/features/room/data/datasources/signaling_client_datasource.dart, test/features/room/data/internet_handover_test.dart, docs/protocolo.md
  - ac: AC7, AC8
  - verify: flutter test test/features/room/data/internet_handover_test.dart test/features/room/data/internet_room_test.dart test/features/room/data/host_failover_test.dart test/features/room/data/room_handover_test.dart test/features/room/data/room_reconnect_test.dart

## Riesgos

- R1: Un teléfono apagado puede dejar abierto su socket con el Worker un buen rato — los invitados también lo notan por su latido (15 s) y siguen el mismo plan; el Worker lo nota al cerrarse el socket.
- R2: El sucesor tarda más que la gracia (p. ej. el primero no tiene red y le toca al tercero) — el plan por internet da dos pasos de 1 s y 2 s a cada persona, y la gracia de 10 s cubre al primero y al segundo. Si nadie llega, la frecu se cierra para todos, como hoy.
- R3: `room_repository_impl.dart` ya es grande (P162) — el socket con turno y el relé del sucesor viven en `internet_handover.dart`; el repositorio solo elige la rama.
- R4: El Worker nuevo cambia el comportamiento para apps anteriores solo si se conectan con `term`, y ninguna lo hace.
