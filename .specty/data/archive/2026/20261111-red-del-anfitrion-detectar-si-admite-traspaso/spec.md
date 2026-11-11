---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C2
---

# Red del anfitrión: detectar si admite traspaso; en la red del anfitrión, hoja de salir y cierre tras reintentos

## Objetivo

La frecu sabe si su red la crea el teléfono del anfitrión (red de Frecu o zona Wi-Fi) y, por eso, si admite traspaso. Los invitados lo conocen al entrar. Con la red del anfitrión, su hoja de salir dice que su teléfono es la red, y si se cae y no vuelve tras los reintentos, el cierre dice «Se perdió la red del anfitrión y no volvió.».

## Fuera de alcance

- La hoja de salir con traspaso («¿Qué pasa con la frecu?», dos opciones): es de C4. Con traspaso, la hoja sigue como hoy.
- Sucesión, turno y estado compartido en el protocolo (C3); `welcome` no cambia.
- Detectar la zona Wi-Fi por el prefijo de la IP (`192.168.43.x`, `172.20.10.x`) cuando la interfaz no tiene nombre de punto de acceso.
- Cambiar los reintentos de los invitados: siguen como hoy.

## Supuestos

- A1: La red de una frecu local la crea el anfitrión si la abrió con la red de Frecu al aire (la interfaz preferida del repositorio), si la IP de su invitación es de una interfaz de zona Wi-Fi (`LanKind.hotspot` de `lan_address.dart`, el mismo criterio de `NetworkState.isHotspot`), o si no hay ninguna red local a la vista (un iPhone con zona Wi-Fi no tiene `bridge100` hasta que alguien se conecta, y la invitación ya lleva la IP de respaldo `192.168.43.1`). Por internet nunca.
  - impacto: alto
- A2: El dato viaja en el participante del anfitrión (`Participant.ownsNetwork`, aditivo como `remote`) y no en `welcome`: un campo nuevo en `welcome` cambia la firma de `maybeWhen` que usan pruebas aprobadas. Una app anterior lo ignora; un anfitrión anterior no lo manda y vale `false` (Wi-Fi compartida, textos de hoy).

## Criterios de aceptación

- AC4: CUANDO la red de una frecu local la crea el anfitrión ENTONCES la hoja de salir solo ofrece «Cerrar frecu», con el texto «Tu teléfono es la red de la frecu. Si sales, la frecu se cierra para …». Si el anfitrión se cae, los invitados reintentan como hoy y, si no vuelve, la frecu se cierra con «Se perdió la red del anfitrión y no volvió.».

## Diseño

- **Dato.** `Participant` gana `ownsNetwork` (`@Default(false)`): solo el del anfitrión, cuando su teléfono es la red. `Room` gana `hostOwnsNetwork` (solo en el teléfono, sin JSON, como `hosting`) y el getter `handover => reach == internet || !hostOwnsNetwork`.
- **Anfitrión.** `RoomRepositoryImpl.createRoom` elige la IP con `selectLanAddress` (un `_lanAddress()` que también usa `getLocalIpAddress`) y fija `SignalingServerDataSource.hostOwnsNetwork` según A1 antes de abrir. El servidor marca `ownsNetwork` en el primer participante. Es una propiedad y no un parámetro de `start`: pruebas aprobadas sobrescriben `start`.
- **Invitado y anfitrión.** `_onWelcome` arma la `Room` con `hostOwnsNetwork` = algún participante anfitrión con `ownsNetwork`; el notifier la conserva con `copyWith`.
- **Hoja de salir.** `LeaveSheet` recibe `hostNetwork`: con anfitrión y `hostNetwork`, el mensaje es `room.sheets.leave.network{Alone,One,Many}`; título y botones, los de hoy («Cerrar la frecu para todos», «Cerrar frecu», «Cancelar»). `RoomPage` lo pasa desde la `Room` activa.
- **Cierre.** `RoomClosureKind.lostHostNetwork` con `room.closure.lostNetwork`. `RoomPage` lo usa con `host_unreachable` si la `Room` activa tiene `hostOwnsNetwork`.
- **Textos** (es/en), sin «router»: «Tu teléfono es la red de la frecu. Si sales, la frecu se cierra.» / «… para la otra persona.» / «… para las otras $count personas.»; «Se perdió la red del anfitrión y no volvió. Puedes unirte a otra cuando quieras.».

## Archivos

- modificar lib/features/room/domain/entities/participant.dart — `ownsNetwork` del anfitrión.
- modificar lib/features/room/domain/entities/participant.freezed.dart — regenerado por build_runner.
- modificar lib/features/room/domain/entities/participant.g.dart — regenerado por build_runner.
- modificar lib/features/room/domain/entities/room.dart — `hostOwnsNetwork` y getter `handover`.
- modificar lib/features/room/domain/entities/room.freezed.dart — regenerado por build_runner.
- modificar lib/features/room/data/datasources/signaling_server_datasource.dart — `hostOwnsNetwork` y marca del primer participante.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — detecta la red del anfitrión al crear y la pasa a la `Room` en `welcome`.
- modificar lib/features/room/presentation/widgets/leave_sheet.dart — mensaje de la red del anfitrión.
- modificar lib/features/room/presentation/widgets/room_closed_view.dart — `RoomClosureKind.lostHostNetwork`.
- modificar lib/features/room/presentation/pages/room_page.dart — pasa la red del anfitrión a la hoja y al cierre.
- modificar lib/i18n/strings.i18n.json — textos en español.
- modificar lib/i18n/strings_en.i18n.json — textos en inglés.
- modificar lib/i18n/strings.g.dart — regenerado por slang.
- modificar lib/i18n/strings_es.g.dart — regenerado por slang.
- modificar lib/i18n/strings_en.g.dart — regenerado por slang.
- crear test/features/room/data/host_network_test.dart — detección de la red del anfitrión y su llegada a los invitados.
- crear test/features/room/presentation/host_network_ui_test.dart — hoja de salir y cierre con la red del anfitrión.

## Tareas

- [x] T1: La frecu sabe si la red la crea el anfitrión
  - files: lib/features/room/domain/entities/participant.dart, lib/features/room/domain/entities/participant.freezed.dart, lib/features/room/domain/entities/participant.g.dart, lib/features/room/domain/entities/room.dart, lib/features/room/domain/entities/room.freezed.dart, lib/features/room/data/datasources/signaling_server_datasource.dart, lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/host_network_test.dart
  - ac: AC4
  - verify: flutter test test/features/room/data/host_network_test.dart
- [x] T2: Hoja de salir y cierre con la red del anfitrión
  - files: lib/features/room/presentation/widgets/leave_sheet.dart, lib/features/room/presentation/widgets/room_closed_view.dart, lib/features/room/presentation/pages/room_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/room/presentation/host_network_ui_test.dart
  - ac: AC4
  - verify: flutter test test/features/room/presentation/host_network_ui_test.dart

## Riesgos

- R1: Un Android que arma la zona Wi-Fi en una interfaz `wlanN` (sin la red de Frecu) se toma como Wi-Fi compartida y mostraría los textos de hoy — se acepta en este corte; el prefijo de IP queda fuera de alcance.
- R2: En paralelo, C8 toca `lib/i18n/*.json` — conflictos menores al integrar, en claves distintas.

## Cierre

### Resumen

`Participant.ownsNetwork` (aditivo) marca al anfitrión cuyo teléfono es la red de la frecu, y `Room` gana `hostOwnsNetwork` y el getter `handover` (`reach == internet || !hostOwnsNetwork`). Al crear una frecu local, `RoomRepositoryImpl` decide con `selectLanAddress` si la red es del anfitrión (red de Frecu al aire, interfaz de zona Wi-Fi o ninguna red local a la vista) y lo fija en `SignalingServerDataSource.hostOwnsNetwork`; el servidor lo pone en el participante anfitrión, que llega a todos en `welcome`, y `_onWelcome` lo pasa a la `Room`. Con la red del anfitrión, la hoja de salir del anfitrión dice «Tu teléfono es la red de la frecu. Si sales, la frecu se cierra para …» (solo «Cerrar frecu»), y el cierre por `host_unreachable` tras los reintentos de hoy dice «Se perdió la red del anfitrión y no volvió.» (`RoomClosureKind.lostHostNetwork`). Textos en es/en. Pruebas AC4 en `host_network_test` y `host_network_ui_test`; `flutter analyze` sin problemas y `flutter test` completo en verde (1173).

### Desviaciones

- `createRoom` se partió en `_prepareHostAddress` y `_createFailure` para no pasar de 50 líneas ni de complejidad 10.

### Decisiones

- El dato viaja en el participante anfitrión y no en `welcome`: un campo nuevo en `welcome` cambia la firma posicional de `maybeWhen` que usan pruebas aprobadas (`signaling_message_test`, `signaling_server_test`).
- `hostOwnsNetwork` es una propiedad del servidor y no un parámetro de `start`, porque pruebas aprobadas sobrescriben `start` (`room_session_test`, `ip_join_note_test`).
- `Room.hostOwnsNetwork` vale `false` por defecto (textos de hoy) y no viaja en el JSON de `Room`, como `hosting`.

### Pendientes

- C3 tendrá el mismo problema si agrega campos a `welcome`: o los pone en un mensaje nuevo (`room_state`) o en los participantes, o pide al usuario desbloquear `signaling_message_test` y `signaling_server_test`.
- Una zona Wi-Fi de Android en una interfaz `wlanN` (sin la red de Frecu) se toma como Wi-Fi compartida (R1).
- Probar en teléfonos reales la hoja y el cierre con la red de Frecu y con zona Wi-Fi (Android e iPhone).
