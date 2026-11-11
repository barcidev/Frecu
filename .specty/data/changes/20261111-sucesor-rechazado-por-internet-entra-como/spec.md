---
kind: standard
---

# Sucesor rechazado por internet entra como invitado

## Objetivo

Por internet, cuando a quien le toca tomar la frecu por caída abre su relé y la nube lo rechaza con 409 (otro ya la lleva con un turno mayor), hoy da la frecu por perdida y la cierra en su teléfono. Con este cambio cierra el servidor que acababa de abrir y vuelve a la frecu como invitado por el mismo socket de invitado, con su id y sin volver a escribir el código, y ve el aviso de C10/C11 con quien la lleva.

## Fuera de alcance

- Cambios en el Worker (`cloud/`): el 409 ya dice que otro lleva la frecu.
- Otros fallos al tomar la frecu (sin red, 403, 404, 503, sin secreto): siguen dando la frecu por perdida como hoy.
- El traspaso voluntario (`host_handover`) y la frecu local.
- Textos o pantallas nuevos: se reutiliza `HostChangeReason.outranked` y su aviso.

## Supuestos

- A1: El 409 al abrir el relé de quien toma la frecu solo significa que otro la lleva con un turno mayor (contrato del Worker de C6, como en C11).
  - impacto: alto
- A2: `InternetHandover.openRelay` lanza el error de la primera conexión del relé, y `CloudRelayDataSource.isOutranked` lo reconoce (C11).
  - impacto: alto
- A3: El aviso «Volviste como invitado · «nombre» lleva la frecu» (`HostChangeReason.outranked`) sirve también para quien no llegó a llevarla.

## Criterios de aceptación

- AC1: CUANDO quien toma una frecu por internet por caída recibe un 409 al abrir su relé ENTONCES no la da por perdida: cierra su servidor, deja de ser anfitrión, vuelve por el socket de invitado de la frecu (`guestSocket(internetId)`) con su id y sin volver a escribir el código, y emite `HostChange(you: false, reason: outranked)` con el id y el nombre de quien la lleva; quien la lleva lo ve como invitado y la nube no recibe otro intento de su relé.
- AC2: CUANDO al tomar la frecu por internet el relé falla por otra causa (por ejemplo 503) ENTONCES la da por perdida como hoy (`RoomStatus.closed`).

## Diseño

- En el `catch` de `_takeOver` (`room_repository_impl.dart`), si la frecu es por internet y `CloudRelayDataSource.isOutranked(e)`, llama a un método nuevo `_joinAsGuestAfterRefusal` en lugar de `_giveUp`: detiene relé y servidor, `_isHost = false`, `_following = true`, `_outranked` con un `HostRival` vacío (para el aviso al llegar el `welcome`, como en C11), `_target` al socket de invitado con su id, y arranca la reconexión con `_handleClientConnectionChange(false)`. Con `_following`, `_failoverPlan` es nulo y la reconexión es la normal.
- Prueba con el punto de encuentro falso de `internet_outranked_test.dart`: Ana lleva la frecu, la nube corta solo el socket de invitado de Beto y le rechaza el socket de invitado hasta su primer 409, y su turno vigente es mayor que el que pedirá Beto.

## Archivos

- modificar lib/features/room/data/repositories/room_repository_impl.dart — al 409 al tomar la frecu por internet, volver como invitado en lugar de darla por perdida.
- crear test/features/room/data/internet_successor_refused_test.dart — el sucesor rechazado entra como invitado (AC1) y otro fallo la da por perdida (AC2).

## Tareas

- [x] T1: El sucesor rechazado por la nube entra como invitado
  - files: lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/internet_successor_refused_test.dart
  - ac: AC1, AC2
  - verify: flutter test test/features/room/data/internet_successor_refused_test.dart test/features/room/data/internet_outranked_test.dart test/features/room/data/internet_handover_test.dart

## Riesgos

- R1: `room_repository_impl.dart` ya es grande (P162) — el cambio reutiliza `_outranked`, `_afterWelcome` y la reconexión normal, y suma un método corto.
