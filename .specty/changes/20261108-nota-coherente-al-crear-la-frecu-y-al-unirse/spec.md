---
kind: standard
epic: 20261108-pendientes-portadora
slice: C3
---

# Nota coherente al crear la frecu y al unirse por IP, y nueva frecu partida

## Objetivo

Que la frecu suene en la nota que el anfitrión vio en pantalla y que quien se une por IP vea esa misma nota. Hoy la nueva frecu muestra una nota y `RoomNotifier.createRoom` calcula otra con su propio reloj (R3 de C17). Además, la unión por IP llega sin nota: el servidor arranca sin ella y `joinRoom` descarta la de `welcome`. De paso, el héroe de la nueva frecu pasa a su propio archivo (P94). Cubre AC2, AC3 y la parte de `new_room_step.dart` de AC6 de la épica.

## Fuera de alcance

- La hoja de unión por IP (`ip_join_sheet.dart`) y sus íconos, que son de C2.
- El nombre de la frecu al unirse por IP (llega como «Frecu», porque `welcome` no lo trae).
- El ícono de Material del aviso de fallo de la nueva frecu (`FrToast`), fuera de los íconos que señala la épica.
- Calcular la nota antes de crear cuando `createRoom` llega sin ella, para que también viaje en `welcome`. La app siempre la pasa desde la nueva frecu.

## Supuestos

- A1: `RoomNotifier.createRoom` recibe `RoomNote? note`. Con ella, se la pasa a `RoomRepository.createRoom(note:)`, que ya la acepta desde P64 y hace que el servidor la mande en `welcome`, y la frecu activa la lleva tal cual, sin recalcularla. Sin nota, la calcula como hoy con `createdAt` y `nearbyNotes`, y el servidor arranca sin nota.
  - impacto: alto
- A2: La nueva frecu pasa la nota que pinta en su último `build`, la del reloj que se relee cada 15 s y las frecus cercanas, y no otra calculada al tocar. Deja de pasar `nearbyNotes`.
- A3: Hoy la unión por IP pierde la nota por dos huecos, y se corrigen los dos: `RoomNotifier.createRoom` no se la da al servidor, así que `welcome` va sin nota, y `RoomNotifier.joinRoom` sobrescribe la nota de `welcome` con la de la invitación, que es nula por IP.
  - impacto: alto
- A4: Al unirse, la nota de `welcome` manda sobre la de la invitación (mDNS o QR), porque es la del anfitrión. Si `welcome` no la trae, por ejemplo con un anfitrión anterior a P64, vale la de la invitación.
- A5: Las pruebas aprobadas de cortes anteriores que crean una frecu con dobles de `RoomRepository` (`new_room_test`, `room_note_flow_test`, `room_flow_test` y `saved_name_test`) no cambian ninguna aserción: suman `note: any(named: 'note')` a los dobles y verificaciones de `createRoom`, `new_room_test` importa `NewRoomHero` desde su archivo nuevo y `room_note_flow_test` fija el reloj de la nueva frecu a las 04:30, la hora de su frecu de prueba.
  - impacto: alto
- A6: La prueba de punta a punta usa un anfitrión real (`RoomNotifier` con `RoomRepositoryImpl` y su servidor de señalización en 127.0.0.1, en un puerto libre y no en el 47800, para no chocar con otras pruebas ni worktrees) y un invitado real (la app con un `RoomRepositoryImpl` cuyo cliente se conecta a ese puerto en lugar del 47800 fijo de la hoja de IP). La voz y el descubrimiento van con dobles, y la red real corre en `tester.runAsync`.

## Criterios de aceptación

- AC1: CUANDO el anfitrión toca «Abrir frecu» en la nueva frecu ENTONCES la frecu abierta lleva exactamente la nota que mostraba la pantalla en ese momento, aunque la hora haya cambiado desde que se calculó. La publica con esa nota en mDNS y se la da al servidor para `welcome`, y la cabecera de la frecu activa la muestra.
- AC2: CUANDO alguien se une por IP manual, sin mDNS ni QR, ENTONCES la frecu activa muestra en la cabecera la nota del anfitrión. CUANDO la invitación trae una nota y `welcome` trae otra ENTONCES la frecu activa lleva la de `welcome`.
- AC3: CUANDO se revisa el código ENTONCES `NewRoomHero`, `_HeroBox` y `_NoteReading` están en `new_room_hero.dart` y `new_room_step.dart` queda bajo el aviso de 300 líneas de código.
  - test: manual

## Diseño

- **`RoomNotifier`** (`room_provider.dart`):
  - `createRoom({name, accessCode, displayName, nearbyNotes, RoomNote? note})` llama a `repository.createRoom(..., note: note)` y deja `data.copyWith(note: note ?? AssignRoomNote().assign(createdAt: data.createdAt, nearbyNotes: nearbyNotes))`.
  - `joinRoom` deja `data.copyWith(note: data.note ?? note)`.
- **`NewRoomStep`** (`new_room_step.dart`): `build` calcula la nota como hoy y se la pasa a `_dock(note)`. «Abrir frecu» llama a `_open(note)`, que crea con `note: note`, y lo demás no cambia.
- **`new_room_hero.dart`**: `NewRoomHero` (pública), `_HeroBox` y `_NoteReading`, movidos sin cambios con sus imports (`dart:math`, `fr_theme`, `fifths_clock`, `room_note_label`, `room_note` y `strings.g.dart`).
- **Pruebas**:
  - `room_note_coherence_test.dart`: `RoomNotifier` con un doble de `RoomRepository`. Comprueba la nota recibida al crear, que llega al repositorio, y la nota de `welcome` al unirse por IP o con invitación.
  - `new_room_note_test.dart`: monta `FrecuApp` como `new_room_test`, con el reloj a las 04:30 (Mi4). Sin esperar los 15 s, mueve el reloj a las 16:24 y comprueba que «Abrir frecu» abre en Mi4, que es la que se ve. Tras releer el reloj, comprueba que abre en Mi5. El doble devuelve la frecu abierta a otra hora, para que no coincida por casualidad.
  - `ip_join_note_test.dart`: la prueba de punta a punta de A6. Une por la hoja de IP y comprueba el `RoomNoteChip` y su etiqueta en la cabecera de la frecu activa.
- **Documentación**: `docs/protocolo.md` y `docs/dominio.md` dicen que la nota la calcula la nueva frecu y la frecu abre con ella.

## Archivos

- modificar lib/features/room/presentation/providers/room_provider.dart — `createRoom` recibe la nota y se la da al repositorio; `joinRoom` conserva la nota de `welcome`.
- modificar lib/features/lobby/presentation/widgets/new_room_step.dart — «Abrir frecu» pasa la nota que pinta; sin el héroe.
- crear lib/features/lobby/presentation/widgets/new_room_hero.dart — `NewRoomHero`, `_HeroBox` y `_NoteReading` (P94).
- crear test/features/room/presentation/room_note_coherence_test.dart — nota recibida al crear y nota de `welcome` al unirse.
- crear test/features/room/presentation/ip_join_note_test.dart — anfitrión real, unión por la hoja de IP y nota en la cabecera.
- crear test/features/lobby/presentation/new_room_note_test.dart — «Abrir frecu» lleva la nota que se ve aunque cambie la hora.
- modificar test/features/lobby/presentation/new_room_test.dart — import de `NewRoomHero` y `note` en los dobles de `createRoom`.
- modificar test/features/lobby/presentation/room_note_flow_test.dart — reloj de la nueva frecu a las 04:30 y `note` en los dobles de `createRoom`.
- modificar test/features/room/presentation/room_flow_test.dart — `note` en los dobles de `createRoom`.
- modificar test/features/lobby/presentation/saved_name_test.dart — `note` en los dobles de `createRoom`.
- modificar docs/protocolo.md — la nota la calcula la nueva frecu y viaja en `welcome`.
- modificar docs/dominio.md — la nota la calcula la nueva frecu.

## Tareas

- [x] T1: `RoomNotifier` con la nota de la nueva frecu y la de `welcome`
  - files: lib/features/room/presentation/providers/room_provider.dart, test/features/room/presentation/room_note_coherence_test.dart, test/features/room/presentation/ip_join_note_test.dart, docs/protocolo.md, docs/dominio.md
  - ac: AC1, AC2
  - verify: flutter test test/features/room/presentation/room_note_coherence_test.dart test/features/room/presentation/ip_join_note_test.dart test/features/room/presentation/room_note_provider_test.dart
- [x] T2: La nueva frecu abre con la nota que muestra y su héroe en `new_room_hero.dart`
  - files: lib/features/lobby/presentation/widgets/new_room_step.dart, lib/features/lobby/presentation/widgets/new_room_hero.dart, test/features/lobby/presentation/new_room_note_test.dart, test/features/lobby/presentation/new_room_test.dart, test/features/lobby/presentation/room_note_flow_test.dart
  - ac: AC1, AC3
  - verify: flutter test test/features/lobby/presentation/new_room_note_test.dart test/features/lobby/presentation/new_room_test.dart test/features/lobby/presentation/room_note_flow_test.dart
- [x] T3: Pruebas de crear de otros cortes con la nota en los dobles
  - files: test/features/room/presentation/room_flow_test.dart, test/features/lobby/presentation/saved_name_test.dart
  - ac: —
  - verify: flutter test && flutter analyze
  - type: test

## Riesgos

- R1: C2 trabaja a la vez en `features/lobby`, y sus pruebas de unión pueden tocar `room_note_flow_test` o `saved_name_test` — mitigación: aquí solo se tocan los dobles de `createRoom` y el reloj, y si chocan al cerrar se resuelve tomando los dos lados.
- R2: La prueba con red real puede ser inestable — mitigación: corre en 127.0.0.1 en un puerto libre, nunca en el 47800, espera con un límite acotado dentro de `tester.runAsync` y cierra el anfitrión y el invitado al terminar.
