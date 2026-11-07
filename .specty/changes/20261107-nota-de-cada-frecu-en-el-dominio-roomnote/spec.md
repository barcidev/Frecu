---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C3
---

# Nota de cada frecu en el dominio (`RoomNote`, `AssignRoomNote` y nota opcional en `Room`, `NearbyRoom` y `RoomInvite`)

## Objetivo

Cada frecu tendrá una nota musical calculada con su hora de apertura sobre el círculo de quintas, que sirve de canal reconocible en voz alta ("estamos en Mi"). Este corte deja la regla en el dominio, en Dart puro y probada: la entidad `RoomNote`, el caso de uso `AssignRoomNote` y una nota opcional en `Room`, `NearbyRoom` y `RoomInvite`, lista para que los cortes de red y de pantallas la publiquen y la muestren.

## Fuera de alcance

- Publicar y leer la nota en el TXT de mDNS (`n`) y en el QR (`MdnsDataSource`, `BuildInviteQr`, `ParseInviteFromQr`) y actualizar `docs/protocolo.md`: C14.
- Calcular la nota al crear la frecu (`CreateRoom`, `RoomRepository`) y pasar las notas de las frecus cercanas: C14 y C17.
- Mostrar la nota en pantallas (sintonizador, lista de frecus, reloj de quintas, cabecera de la frecu activa): C4, C15 y C17.
- Nombres de nota en inglés (C, G…) y formato de la frecuencia con coma ("659,3 Hz"): presentación con slang en los cortes de UI.
- Diapasón al entrar (sonar la nota al unirse).

## Supuestos

- A1: La nota se guarda solo como semitono desde Do4 (0–23), la misma forma con la que viajará como `n` (A2 de la épica); nombre, octava, clase de altura, MIDI, posición en el círculo de quintas y Hz se derivan de él, así que no pueden contradecirse.
  - impacto: alto
- A2: El nombre de la nota en el dominio es el de solfeo con las alteraciones del prototipo (Do, Re♭, Re, Mi♭, Mi, Fa, Fa♯, Sol, La♭, La, Si♭, Si).
- A3: Solo cuenta la hora (0–23) de `createdAt` en hora local; los minutos no cambian la nota, como `noteAt` del prototipo.
- A4: Una nota está ocupada si una frecu cercana tiene la misma clase de altura y la misma octava (el mismo semitono). Si las 12 notas de esa octava están ocupadas, se queda con la de su hora, como el bucle de `noteAt`.
- A5: En JSON la nota es el entero `note` (semitono) y un semitono fuera de 0–23 se lee como sin nota. Ningún mensaje de red usa hoy `Room.toJson`, `NearbyRoom.toJson` ni `RoomInvite.toJson`, así que el protocolo no cambia.

## Criterios de aceptación

- AC1: CUANDO se asigna la nota a una frecu abierta a la hora H (0–23) sin frecus cercanas ENTONCES la nota es la de la posición H mod 12 del círculo de quintas (12→Do, 1→Sol, 2→Re, 3→La, 4→Mi, 5→Si, 6→Fa♯, 7→Re♭, 8→La♭, 9→Mi♭, 10→Si♭, 11→Fa), en octava 4 de 0 a 11 h y en octava 5 de 12 a 23 h, sin importar los minutos (16:24 → Mi5; 15:05 → La5).
- AC2: CUANDO se lee una nota ENTONCES expone su nombre, octava, clase de altura (0–11), semitono desde Do4 (0–23), posición en el círculo de quintas y frecuencia en Hz con La4 = 440 Hz y temperamento igual (Do4 ≈ 261,63 Hz; Mi5 ≈ 659,26 Hz; La5 = 880 Hz); se reconstruye desde su semitono y un semitono fuera de 0–23 no da nota.
- AC3: CUANDO una frecu cercana ya usa la nota y la octava de la hora ENTONCES se asigna la siguiente quinta libre de la misma octava, dando la vuelta de Fa a Do; la misma nota en la otra octava no la ocupa, y si las 12 notas de esa octava están ocupadas se queda con la de su hora.
- AC4: CUANDO se crea un `Room`, un `NearbyRoom` o un `RoomInvite` sin nota ENTONCES su nota es nula y lo demás no cambia; con nota, la conserva y sobrevive a `toJson`/`fromJson` como el semitono `note`, y un `note` ausente, nulo o fuera de 0–23 se lee como sin nota.

## Diseño

- **`RoomNote` (`features/room/domain/entities/room_note.dart`)**: Freezed 3 (`abstract class` con `const RoomNote._()`) con un único campo `semitone` (0–23, con `@Assert`). Getters derivados: `octave` (4 + s ~/ 12), `pitchClass` (s % 12), `midi` (60 + s), `name` (solfeo por clase de altura), `fifthsPosition` (pitchClass·7 mod 12, la hora del reloj de quintas con 0 = 12 h) y `hz` (440·2^((midi−69)/12), con `dart:math`). Constantes `RoomNote.circleOfFifths` (clases de altura 0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5) y `RoomNote.semitoneCount` (24). `RoomNote.tryFromSemitone(int?)` devuelve `null` si falta o está fuera de rango. `RoomNoteConverter` (`JsonConverter<RoomNote?, int?>`) guarda la nota como semitono en JSON.
- **`AssignRoomNote` (`features/room/domain/usecases/assign_room_note.dart`)**: replica `BuildInviteQr`: implementa `UseCase<RoomNote, AssignRoomNoteParams>` y expone el método síncrono `assign({required DateTime createdAt, Iterable<RoomNote> nearbyNotes})`. Toma `createdAt.toLocal().hour`, parte de la posición hora mod 12 en la octava de su mitad del día y avanza por `circleOfFifths` hasta el primer semitono libre, con un máximo de 12 pasos.
- **Nota opcional**: `Room`, `RoomInvite` y `NearbyRoom` suman `@RoomNoteConverter() RoomNote? note`; los constructores existentes siguen igual. `NearbyRoom` (feature `lobby`) importa la entidad del dominio de `room`, como ya hace `ParseInviteFromQr` con `RoomInvite`.
- **Glosario**: `docs/dominio.md` suma el término Nota (`RoomNote`).

## Archivos

- crear lib/features/room/domain/entities/room_note.dart — entidad `RoomNote`, círculo de quintas y `RoomNoteConverter`.
- crear lib/features/room/domain/entities/room_note.freezed.dart — código generado por Freezed.
- crear lib/features/room/domain/usecases/assign_room_note.dart — caso de uso `AssignRoomNote`.
- modificar lib/features/room/domain/entities/room.dart — nota opcional.
- modificar lib/features/room/domain/entities/room.freezed.dart — regenerado.
- modificar lib/features/room/domain/entities/room.g.dart — regenerado.
- modificar lib/features/room/domain/entities/room_invite.dart — nota opcional.
- modificar lib/features/room/domain/entities/room_invite.freezed.dart — regenerado.
- modificar lib/features/room/domain/entities/room_invite.g.dart — regenerado.
- modificar lib/features/lobby/domain/entities/nearby_room.dart — nota opcional.
- modificar lib/features/lobby/domain/entities/nearby_room.freezed.dart — regenerado.
- modificar lib/features/lobby/domain/entities/nearby_room.g.dart — regenerado.
- modificar docs/dominio.md — término Nota (`RoomNote`).
- crear test/features/room/domain/room_note_test.dart — las 24 notas, Hz y semitonos inválidos.
- crear test/features/room/domain/assign_room_note_test.dart — las 24 horas, minutos y choques con frecus cercanas.
- crear test/features/room/domain/room_note_fields_test.dart — `Room` y `RoomInvite` con y sin nota, y JSON.
- crear test/features/lobby/domain/nearby_room_note_test.dart — `NearbyRoom` con y sin nota, y JSON.

## Tareas

- [x] T1: Entidad `RoomNote` con sus valores derivados
  - files: lib/features/room/domain/entities/room_note.dart, lib/features/room/domain/entities/room_note.freezed.dart, test/features/room/domain/room_note_test.dart
  - ac: AC2
  - verify: flutter test test/features/room/domain/room_note_test.dart
- [x] T2: Caso de uso `AssignRoomNote` con la hora y los choques
  - files: lib/features/room/domain/usecases/assign_room_note.dart, test/features/room/domain/assign_room_note_test.dart
  - ac: AC1, AC3
  - verify: flutter test test/features/room/domain/assign_room_note_test.dart
- [x] T3: Nota opcional en `Room`, `RoomInvite` y `NearbyRoom`
  - files: lib/features/room/domain/entities/room.dart, lib/features/room/domain/entities/room.freezed.dart, lib/features/room/domain/entities/room.g.dart, lib/features/room/domain/entities/room_invite.dart, lib/features/room/domain/entities/room_invite.freezed.dart, lib/features/room/domain/entities/room_invite.g.dart, lib/features/lobby/domain/entities/nearby_room.dart, lib/features/lobby/domain/entities/nearby_room.freezed.dart, lib/features/lobby/domain/entities/nearby_room.g.dart, docs/dominio.md, test/features/room/domain/room_note_fields_test.dart, test/features/lobby/domain/nearby_room_note_test.dart
  - ac: AC4
  - verify: flutter analyze && flutter test

## Riesgos

- R1: `json_serializable` con un conversor anulable podría generar una lectura que falle con `note` ausente — mitigación: las pruebas de AC4 leen JSON sin `note`, con `null` y fuera de rango.
- R2: Regenerar con `build_runner` podría reescribir otros archivos generados — mitigación: revisar `git status` tras generar y dejar solo los de este alcance.
