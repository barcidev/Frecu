---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C3
---

# Sucesión, turno y estado compartido en el protocolo (`welcome`, `room_state`)

## Objetivo

Cada participante de una frecu conoce, sin que nadie lo pida, lo necesario para heredarla: si admite traspaso, el turno vigente, el orden de sucesión y el estado de la frecu (nombre, código, nota, modo y participantes con su IP local y hora de llegada; por internet, también el secreto de anfitrión). El anfitrión lo envía en un mensaje nuevo `room_state` al entrar cada invitado y en cada cambio. Es la base de C4 y C5.

## Fuera de alcance

- Tomar la frecu, pasarla al salir, reconectar a otro anfitrión o resolver dos anfitriones por turno (C4, C5).
- Interfaz y textos del traspaso (C4, C5).
- El Worker de la nube (C6): solo reenvía el mensaje como cualquier otro.
- Campos nuevos en `welcome`: cambian la firma posicional de `maybeWhen` de pruebas aprobadas (P149).
- Exponer la sucesión en el contrato `RoomRepository` del dominio: lo implementan muchas pruebas aprobadas con dobles; se expone en `RoomRepositoryImpl`.

## Supuestos

- A1: Un mensaje de tipo desconocido se descarta al decodificarlo (`SignalingClientDataSource` lo ignora y registra un aviso), así que una app anterior ignora `room_state` y sigue sin traspaso (A4 de la épica).
- A2: El orden de sucesión es el orden de llegada al servidor del anfitrión, con el anfitrión primero (A5 de la épica). Cada reconexión llega con un id nuevo y va al final.
- A3: «Modo» es el tipo de frecu (`RoomReach`: local o por internet); el modo de habla es de cada teléfono y no se comparte.
- A4: La IP de cada invitado es la del socket local que ve el anfitrión; por internet no hay IP. La del anfitrión es la IPv4 de su invitación.
  - impacto: alto
- A5: Repartir el secreto de anfitrión a los invitados de una frecu por internet es aceptable: ya conocen el código y lo necesitan para tomar la frecu (A3 de la épica).

## Criterios de aceptación

- AC5: CUANDO la frecu es local en una Wi-Fi compartida, o por internet ENTONCES los participantes saben que admite traspaso, y cada uno conoce el orden de sucesión, el turno vigente y el estado de la frecu (nombre, código, nota, modo y participantes), que el anfitrión les envía al entrar y en cada cambio.

## Diseño

- **Dominio.** `RoomSuccession` (Freezed, JSON, Dart puro) en `domain/entities/room_succession.dart`: `term`, `handover`, `name`, `accessCode`, `note`, `reach`, `internetId?`, `hostSecret?` y `members` en orden de sucesión; cada `RoomMember` lleva `id`, `displayName`, `address?` (IP local) y `joinedAt`. Getter `order` con los ids.
- **Protocolo (aditivo).** Variante nueva `SignalingMessage.roomState({required RoomSuccession state})`, JSON `{"type":"room_state","state":{…}}`. `welcome` no cambia. `hostSecret`, `internetId` y `address` se omiten si son nulos.
- **Pieza propia en `data`.** `data/datasources/room_succession.dart`: `SuccessionLedger` guarda el turno (1 al abrir), el tipo, si el anfitrión es la red, su IP, el id y el secreto por internet, y los miembros con su IP y hora de llegada; arma el `RoomSuccession`. `KnownSuccession` guarda la última que llegó y la entrega como stream (actual primero).
- **Servidor.** `SignalingServerDataSource.succession` (un `SuccessionLedger`, propiedad como `hostOwnsNetwork`, porque pruebas aprobadas sobrescriben `start`). `start` vacía los miembros; tras cada `join` aceptado (después de `welcome` y `peer_joined`) y cada salida, difunde `room_state` a todos. `handover = reach == internet || !hostOwnsNetwork`, como `Room.handover`.
- **Repositorio.** `createRoom` genera el id y el secreto por internet antes de abrir el servidor y configura `succession`. Al recibir `room_state`, lo guarda en `KnownSuccession`; se borra al abrir otra sesión, al cerrarse la frecu, al rendirse y al salir. Expone `succession` y `watchSuccession()` en `RoomRepositoryImpl`.
- **Uniones exhaustivas.** Los `switch` sobre `SignalingMessage` en `lib` (servidor, malla, voz, repositorio) suman `SignalingRoomStateMessage` a su caso de ignorar. Las pruebas aprobadas usan `maybeWhen` con `orElse` y no cambian.

## Archivos

- crear lib/features/room/domain/entities/room_succession.dart — `RoomSuccession` y `RoomMember`.
- crear lib/features/room/domain/entities/room_succession.freezed.dart — generado por build_runner.
- crear lib/features/room/domain/entities/room_succession.g.dart — generado por build_runner.
- modificar lib/features/room/data/models/signaling_message.dart — variante `room_state`.
- modificar lib/features/room/data/models/signaling_message.freezed.dart — regenerado por build_runner.
- modificar lib/features/room/data/models/signaling_message.g.dart — regenerado por build_runner.
- crear lib/features/room/data/datasources/room_succession.dart — `SuccessionLedger` y `KnownSuccession`, fuera del repositorio (R3 de la épica).
- modificar lib/features/room/data/datasources/signaling_server_datasource.dart — difunde `room_state` al entrar y salir alguien.
- modificar lib/features/room/data/datasources/peer_connection_datasource.dart — ignora `room_state` en su `switch`.
- modificar lib/features/room/data/repositories/voice_repository_impl.dart — ignora `room_state` en su `switch`.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — configura la sucesión al crear y guarda la que llega.
- crear test/features/room/data/room_succession_test.dart — reparto y conocimiento de la sucesión (AC5).
- modificar docs/protocolo.md — mensaje `room_state`.

## Tareas

- [x] T1: Sucesión, turno y estado de la frecu en `room_state`
  - files: lib/features/room/domain/entities/room_succession.dart, lib/features/room/domain/entities/room_succession.freezed.dart, lib/features/room/domain/entities/room_succession.g.dart, lib/features/room/data/models/signaling_message.dart, lib/features/room/data/models/signaling_message.freezed.dart, lib/features/room/data/models/signaling_message.g.dart, lib/features/room/data/datasources/room_succession.dart, lib/features/room/data/datasources/signaling_server_datasource.dart, lib/features/room/data/datasources/peer_connection_datasource.dart, lib/features/room/data/repositories/voice_repository_impl.dart, lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/room_succession_test.dart, docs/protocolo.md
  - ac: AC5
  - verify: flutter test test/features/room/data/room_succession_test.dart

## Riesgos

- R1: Un mensaje más tras cada `join` podría romper pruebas aprobadas que cuentan mensajes — las que usan el servidor real filtran por tipo (`maybeWhen`, `whereType`); se corre `flutter test` completo.
- R2: `room_repository_impl.dart` ya pasa de 740 líneas — la lógica va en `room_succession.dart` y el repositorio solo delega.

## Cierre

### Resumen

Mensaje nuevo `room_state` (`SignalingMessage.roomState`, aditivo; `welcome` no cambia) con `RoomSuccession` del dominio: turno (`term`, 1 al abrir), `handover`, nombre, código, nota, tipo (`reach`), por internet `internetId` y `hostSecret`, y `members` (`RoomMember`: id, nombre, IP local y hora de llegada) en orden de llegada con el anfitrión primero. `SuccessionLedger` (`data/datasources/room_succession.dart`) vive en `SignalingServerDataSource.succession`; el servidor difunde `room_state` a todos tras cada `join` aceptado y cada salida. `RoomRepositoryImpl` configura la sucesión al crear (genera el id y el secreto por internet antes de abrir el servidor) y guarda la que llega en `KnownSuccession`, expuesta como `succession` y `watchSuccession()`; se olvida al abrir otra sesión, cerrarse, rendirse o salir. 7 pruebas AC5 en `room_succession_test`; `flutter analyze` sin problemas y `flutter test` completo en verde (1185).

### Desviaciones

- Los `switch` sobre `SignalingMessage` del servidor, la malla, la voz y el repositorio cambiaron su lista de mensajes ignorados por `default`: sumar la variante a cada lista subía la complejidad de funciones que ya pasaban del límite (`specty check`).
- `_prepareHostAddress` recibe el id y el secreto por internet y configura la sucesión, para que `createRoom` no pase de 50 líneas.
- `docs/dominio.md` gana el término «Sucesión» (`RoomSuccession`), como pide el cierre.

### Decisiones

- Todo va en `room_state` y no en `welcome` ni en `Participant`: un campo nuevo en `welcome` rompe la firma posicional de `maybeWhen` de pruebas aprobadas, y uno en `Participant` cambiaría su igualdad en pruebas que lo comparan. Las pruebas aprobadas usan `maybeWhen` con `orElse`, así que la variante nueva no las rompe.
- `succession` es una propiedad del servidor y no un parámetro de `start`, porque pruebas aprobadas sobrescriben `start`.
- La sucesión se expone en `RoomRepositoryImpl` y no en el contrato `RoomRepository`, que implementan muchos dobles de pruebas aprobadas.
- «Modo» es el tipo de frecu (`RoomReach`); el modo de habla es de cada teléfono.
- `RoomSuccession` usa `makeCollectionsUnmodifiable: false` (como `SignalingMessage`): con la lista envuelta, Freezed generaba un constructor que no compila; el `SuccessionLedger` ya entrega la lista inmodificable.

### Pendientes

- C4 y C5: usar la sucesión para tomar la frecu (subir `term`, abrir el servidor con el estado heredado) y reconectar a los demás; si hace falta en la presentación, sumar `succession` al contrato `RoomRepository` (implica tocar los dobles de pruebas aprobadas).
- Al reconectar, el lugar viejo propio puede seguir en `members` hasta que el anfitrión note la salida, y el regreso llega al final de la sucesión con un id nuevo.
- `room_repository_impl.dart` (646 líneas de código) y `signaling_server_datasource.dart` (409) siguen grandes: en C4 conviene sacar la reconexión del repositorio a su propia pieza.
