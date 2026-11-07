---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C14
---

# Nota en el TXT de mDNS y en el QR

## Objetivo

La nota de cada frecu (`RoomNote`, C3) empieza a viajar por la red: el anfitrión la calcula una sola vez al abrir la frecu, con su hora local y las notas de las frecus cercanas, y la publica como dato aditivo `n` (semitono 0–23 desde Do4) en el TXT de mDNS y en el QR de invitación. Quien descubre o escanea la frecu ve la misma nota y frecuencia que el anfitrión, sin recalcularla; si la invitación no trae nota, la frecu queda sin nota y la unión funciona igual.

## Fuera de alcance

- Mostrar la nota en pantallas (lista y sintonizador del inicio, escáner, reloj de quintas, cabecera de la frecu activa): C4, C15, C16 y C17.
- Elegir la nota a mano o con el reloj de quintas en la pantalla de nueva frecu: C17.
- Llevar la nota en los mensajes de señalización WebSocket (`welcome`): quien se une por IP manual queda sin nota.
- Cambiar la versión del protocolo (`v=1`) o los parámetros existentes del TXT y del QR.
- Cambiar el contrato de `RoomRepository` o de `CreateRoom`.

## Supuestos

- A1: `n` viaja como texto con el entero decimal del semitono desde Do4 (`"0"` a `"23"`), igual en el TXT de mDNS que en el parámetro `n` del QR, y solo se añade cuando la frecu tiene nota; así un teléfono sin esta versión ignora `n` y uno con ella lee las invitaciones viejas sin nota (A2 de la épica).
  - impacto: alto
- A2: Un `n` ausente, vacío, que no sea un entero o que esté fuera de 0–23 se lee como sin nota (`RoomNote.tryFromSemitone`); nunca invalida la frecu ni la invitación.
- A3: La nota se calcula en `RoomNotifier.createRoom` con `AssignRoomNote` sobre `Room.createdAt` (la hora de apertura que pone el repositorio) y las notas de las `NearbyRoom` descubiertas en ese momento; no se recalcula después ni en los teléfonos que se unen (A3 de la épica).
  - impacto: alto
- A4: Las frecus cercanas que cuentan son las de `nearbyRoomsProvider` al pulsar crear; si el descubrimiento aún no encontró ninguna, la nota es la de la hora sin choques.
- A5: Quien se une desde una frecu descubierta o desde un QR guarda en su `Room` la nota que trae la invitación (`RoomNotifier.joinRoom(note:)`); quien se une por IP manual no tiene de dónde leerla y queda sin nota.

## Criterios de aceptación

- AC1: CUANDO el anfitrión publica su frecu con nota ENTONCES el TXT de mDNS lleva `n` con su semitono (por ejemplo `"16"` para Mi5) además de `roomId`, `name` y `v` = `"1"`; sin nota, el TXT tiene solo `roomId`, `name` y `v`, como antes.
- AC2: CUANDO un teléfono descubre por mDNS una frecu cuyo TXT trae `n` entre 0 y 23 ENTONCES la frecu cercana tiene esa nota, con el mismo nombre, octava y Hz que la del anfitrión; si `n` falta, está vacío, no es un entero o está fuera de 0–23, la frecu cercana aparece sin nota y con su `roomId`, nombre, dirección, puerto y versión intactos.
- AC3: CUANDO se construye el QR de una invitación con nota ENTONCES la URI es `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>&n=<semitono>`, y sin nota es la misma URI de antes sin `n`; CUANDO se escanea una URI con `n` entre 0 y 23 ENTONCES la invitación trae esa nota, y si `n` falta o es inválido la invitación es válida, sin nota y con los demás datos iguales.
- AC4: CUANDO el anfitrión abre una frecu ENTONCES su nota se calcula una vez con la hora local de apertura y las notas de las frecus cercanas descubiertas (si una ya usa la nota de su hora, toma la siguiente quinta libre), queda en la frecu activa y se publica con esa misma nota en el TXT de mDNS y en el QR de invitación.
- AC5: CUANDO un participante se une a una frecu descubierta por mDNS o escaneada por QR ENTONCES su frecu activa lleva la nota que trajo la invitación, sin recalcularla con su propia hora; si la invitación no trae nota, o se une por IP, la frecu activa queda sin nota y la unión funciona igual.

## Diseño

- **mDNS (`features/lobby/data/datasources/mdns_datasource.dart`)**: `publish` suma `RoomNote? note` y, si hay nota, la clave TXT `n` con `utf8` del semitono. `_buildNearbyRoom` lee `n` con `int.tryParse` y `RoomNote.tryFromSemitone`, decodificando con `allowMalformed` para que un valor raro solo deje la frecu sin nota.
- **Repositorio de descubrimiento**: `DiscoveryRepository.publishRoom` y su implementación suman `RoomNote? note` opcional; `PublishRoomParams` suma `note` y `PublishRoom` la pasa. Los mocks existentes siguen valiendo porque el parámetro es opcional y nulo por defecto.
- **QR**: `BuildInviteQr.buildUri` añade `'n'` al final del mapa de parámetros solo si `invite.note` no es nula. `ParseInviteFromQr` lee `n` (recortado) con `int.tryParse` y `RoomNote.tryFromSemitone` y lo pone en `RoomInvite.note`; no añade fallos nuevos.
- **Nota al abrir y al unirse (`features/room/presentation/providers/room_provider.dart`)**: `RoomNotifier.createRoom` suma `Iterable<RoomNote> nearbyNotes = const []`; con éxito, asigna `const AssignRoomNote().assign(createdAt: room.createdAt, nearbyNotes: nearbyNotes)`, guarda `room.copyWith(note: …)` en el estado y lo devuelve. `RoomNotifier.joinRoom` suma `RoomNote? note` y guarda `room.copyWith(note: note)`, sin llamar a `AssignRoomNote`.
- **Pantallas actuales**: `CreateRoomPage` observa `nearbyRoomsProvider`, pasa `nearby.map((r) => r.note).nonNulls` a `createRoom` y publica con `note: data.note`. `InviteQrDialog` pasa `room.note` a `RoomInvite`. El diálogo de PIN de `LobbyPage` pasa `widget.room.note` y `ScanQrPage` pasa `invite.note` a `joinRoom`; la unión por IP no pasa nota.
- **Documentación**: `docs/protocolo.md` describe `n` en el TXT y en el QR, su rango, que es opcional y que `v` sigue en `1`.

## Archivos

- modificar lib/features/lobby/data/datasources/mdns_datasource.dart — publicar y leer `n` en el TXT.
- modificar lib/features/lobby/domain/repositories/discovery_repository.dart — nota opcional en `publishRoom`.
- modificar lib/features/lobby/data/repositories/discovery_repository_impl.dart — pasar la nota al datasource.
- modificar lib/features/lobby/domain/usecases/discovery_usecases.dart — nota en `PublishRoomParams`.
- modificar lib/features/lobby/domain/usecases/parse_invite_from_qr.dart — leer `n` del QR.
- modificar lib/features/lobby/presentation/pages/create_room_page.dart — notas cercanas al crear y publicar con nota.
- modificar lib/features/lobby/presentation/pages/lobby_page.dart — unirse con la nota de la frecu descubierta.
- modificar lib/features/lobby/presentation/pages/scan_qr_page.dart — unirse con la nota del QR.
- modificar lib/features/room/domain/usecases/build_invite_qr.dart — añadir `n` al QR.
- modificar lib/features/room/presentation/providers/room_provider.dart — asignar la nota al abrir y guardarla al unirse.
- modificar lib/features/room/presentation/widgets/invite_qr_dialog.dart — QR con la nota de la frecu.
- modificar docs/protocolo.md — clave `n` en el TXT y en el QR.
- crear test/features/lobby/data/mdns_note_test.dart — `n` al publicar y al descubrir, con valores inválidos.
- crear test/features/room/domain/invite_qr_note_test.dart — `n` al construir y al leer el QR, con valores inválidos.
- crear test/features/room/presentation/room_note_provider_test.dart — nota al abrir con frecus cercanas y al unirse sin recalcular.
- crear test/features/lobby/presentation/room_note_flow_test.dart — crear publica la nota, el QR la lleva y unirse por mDNS o QR la conserva.

## Tareas

- [x] T1: Clave `n` en el TXT de mDNS al publicar y al descubrir
  - files: lib/features/lobby/data/datasources/mdns_datasource.dart, lib/features/lobby/domain/repositories/discovery_repository.dart, lib/features/lobby/data/repositories/discovery_repository_impl.dart, lib/features/lobby/domain/usecases/discovery_usecases.dart, test/features/lobby/data/mdns_note_test.dart
  - ac: AC1, AC2
  - verify: flutter test test/features/lobby/data/mdns_note_test.dart test/features/lobby/data/discovery_repository_test.dart test/features/lobby/domain/discovery_usecases_test.dart
- [x] T2: Parámetro `n` en el QR al construir y al leer
  - files: lib/features/room/domain/usecases/build_invite_qr.dart, lib/features/lobby/domain/usecases/parse_invite_from_qr.dart, test/features/room/domain/invite_qr_note_test.dart
  - ac: AC3
  - verify: flutter test test/features/room/domain/invite_qr_note_test.dart test/features/room/domain/invite_qr_usecases_test.dart
- [x] T3: Nota asignada al abrir y conservada al unirse en `RoomNotifier`
  - files: lib/features/room/presentation/providers/room_provider.dart, test/features/room/presentation/room_note_provider_test.dart
  - ac: AC4, AC5
  - verify: flutter test test/features/room/presentation/room_note_provider_test.dart
- [ ] T4: Pantallas actuales publican, invitan y se unen con la nota; protocolo documentado
  - files: lib/features/lobby/presentation/pages/create_room_page.dart, lib/features/lobby/presentation/pages/lobby_page.dart, lib/features/lobby/presentation/pages/scan_qr_page.dart, lib/features/room/presentation/widgets/invite_qr_dialog.dart, docs/protocolo.md, test/features/lobby/presentation/room_note_flow_test.dart
  - ac: AC3, AC4, AC5
  - verify: flutter analyze && flutter test

## Riesgos

- R1: Un teléfono con una versión anterior recibe `n` — mitigación: el TXT y el QR solo suman una clave; `MdnsDataSource` y `ParseInviteFromQr` de la versión anterior leen claves por nombre e ignoran las demás, y `v` no cambia.
- R2: Los mocks de `DiscoveryRepository` de pruebas existentes dejan de casar con `publishRoom` — mitigación: `note` es opcional y nulo por defecto, y ninguna prueba existente crea una frecu con un `DiscoveryRepository` simulado; se corre la suite completa en T4.
- R3: El descubrimiento aún no encontró las frecus cercanas al pulsar crear y dos frecus quedan con la misma nota — mitigación: se acepta en este corte (A4); C17 puede esperar al descubrimiento antes de mostrar el reloj de quintas.
