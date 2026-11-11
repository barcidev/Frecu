---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C4
---

# Traspaso voluntario en Wi-Fi compartida: hojas de salir y de sucesor, toma de la frecu y reconexión de los demás

## Objetivo

En una frecu local sobre una Wi-Fi que no depende del teléfono del anfitrión, el anfitrión puede salir sin cerrarla: elige quién la lleva, esa persona abre el servidor con el estado heredado y los demás se reconectan a ella con su mismo lugar, sin volver a escribir el código. Prototipo aprobado: `docs/diseno/prototipo/anfitrion.js`, grupo «Router o internet · el anfitrión sale» (en la carpeta principal).

## Fuera de alcance

- Traspaso por caída del anfitrión y regreso del anfitrión anterior por turno (C5); el `join` aún no lleva `term`.
- Traspaso por internet (C6): una frecu por internet sigue con la hoja de salir de hoy.
- Que la voz no se corte durante el traspaso y que el micrófono abierto se retome solo (C7).
- Probar con el siguiente de la sucesión si quien la recibe no responde (C5): hoy, tras los reintentos, la frecu se cierra como siempre.
- Anunciar por mDNS o Bluetooth la frecu de quien la recibe (módulo `lobby`): se invita con su QR nuevo.
- Cambiar el contrato `RoomRepository` o los campos de `welcome`.

## Supuestos

- A1: Quien recibe la frecu abre su servidor en el mismo puerto que el anfitrión (47800), y los demás lo encuentran en la IP con la que el anfitrión vio su socket (`RoomMember.address` de la sucesión).
  - impacto: alto
- A2: El servidor de quien la recibe guarda un lugar a cada persona heredada (mismo id, mismo orden, misma hora de llegada) hasta que se le acaba el latido (`peerTimeout`, 15 s); quien no vuelve en ese tiempo sale como hoy. Así la lista no parpadea ni avisa entradas y salidas falsas.
  - impacto: alto
- A3: Los textos no suponen género: la hoja de salir con traspaso dice «Llevas la frecu y hay N personas más.» en lugar del «Eres el anfitrión…» del prototipo.
- A4: Tras pasar la frecu, quien salió vuelve al inicio como un invitado que sale.

## Criterios de aceptación

- AC6: CUANDO el anfitrión de una frecu con traspaso toca Salir y hay alguien más ENTONCES ve «¿Qué pasa con la frecu?» con «Que siga sin mí» (marcada) y «Cerrarla para todos». Al seguir con la primera, ve «¿Quién lleva la frecu?» con los participantes y la persona que lleva más tiempo sugerida, y el botón «Pasar a «nombre» y salir». Si está solo, ve la hoja de cerrar de hoy.
- AC7: CUANDO el anfitrión de una frecu local en una Wi-Fi compartida pasa la frecu ENTONCES quien la recibe abre el servidor, sube el turno y ve «Ahora llevas la frecu. «anterior» te la pasó al salir.» con «Mostrar el QR». Los demás se reconectan a él con su mismo id y lugar, sin volver a escribir el código, y ven ««anterior» salió · «nombre» lleva ahora la frecu». La cabecera dice «Anfitrión · «nombre»», y quien la recibe ve «Llevas la frecu». Su QR es el nuevo (su IP).

## Diseño

- **Protocolo (aditivo).** `host_handover { to, term }`: el servidor del anfitrión lo difunde antes de salir, seguido de `peer_left` del anfitrión, y se cierra sin `room_closed`. `host_changed { host, term, reason: left|lost }`: el servidor de quien la recibe lo envía a cada persona heredada que vuelve. `join` gana `peerId` opcional (se omite si es nulo) para volver al lugar propio. `welcome` no cambia.
- **Servidor.** `SignalingServerDataSource.handOver(to)` difunde y se detiene sin `room_closed` (`start` y `stop` no cambian de firma: pruebas aprobadas los sobrescriben). `inherit(state, hostPeerId:)` se fija antes de `start`, como `succession`: `start` siembra un lugar por cada persona heredada (menos el anfitrión anterior) con su id, nombre y hora de llegada, y el contador de ids sigue tras el mayor. Un `join` con `peerId` de un lugar libre lo ocupa; el de `hostPeerId` es el anfitrión. Ocupar un lugar no difunde `peer_joined` (ya estaba en las listas), salvo que cambie su `isHost`.
- **Sucesión.** `SuccessionLedger` conserva la hora de llegada heredada y pone al anfitrión primero en el `room_state`.
- **Pieza propia (P159).** `data/repositories/room_reconnection.dart`: el bucle de reintentos (`RejoinLoop`, sacado de `RoomRepositoryImpl` sin cambiar su comportamiento) y `HostTakeover`, que recuerda a quién seguir, abre el servidor de quien recibe la frecu (con reintentos si el puerto aún está ocupado) y emite los `HostChange`.
- **Repositorio.** `RoomRepositoryImpl` implementa además una interfaz nueva del dominio, `RoomHandover` (`succession`, `watchSuccession()`, `watchHostChanges()`, `handOver(peerId)`); `RoomRepository` no cambia. Al recibir `host_handover`: si va dirigido a este teléfono, deja de reconectar, abre el servidor con la sucesión heredada y `term + 1`, y se une a sí mismo con su id; si no, apunta la reconexión a la IP de quien la recibe con su mismo id y el código heredado. Al volver a una frecu con el mismo id, ese id ya no se descarta como lugar viejo.
- **Presentación.** `roomHandoverProvider` da el `RoomHandover` si el repositorio lo implementa (los dobles de pruebas no). `RoomNotifier.handOverAndLeave(peerId)` suelta la voz y pasa la frecu; `applyHostChange` cambia la IP de la invitación y, para quien la recibe, `hosting` e `inherited` (campo nuevo de `Room`, fuera de JSON). Hojas nuevas `HandoverChoiceSheet` y `HandoverPickSheet`; `HandoverNotice` muestra el toast con la firma a los demás y el aviso con «Mostrar el QR» a quien la recibe. La cabecera dice «Llevas la frecu» con `inherited`. La isla no avisa la salida del anfitrión que pasa la frecu.
- **Textos.** En slang (es/en), en `room.handover` y `room.header.carrying`.

## Archivos

- modificar lib/features/room/data/models/signaling_message.dart — `host_handover`, `host_changed` y `peerId` del `join`.
- modificar lib/features/room/data/models/signaling_message.freezed.dart — regenerado por build_runner.
- modificar lib/features/room/data/models/signaling_message.g.dart — regenerado por build_runner.
- modificar lib/features/room/data/datasources/signaling_server_datasource.dart — `handOver`, `inherit` y lugares heredados.
- modificar lib/features/room/data/datasources/room_succession.dart — hora de llegada heredada y anfitrión primero.
- crear lib/features/room/data/repositories/room_reconnection.dart — `RejoinLoop` y `HostTakeover`, fuera del repositorio.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — toma, seguimiento a quien recibe y `RoomHandover`.
- crear lib/features/room/domain/repositories/room_handover.dart — interfaz `RoomHandover` y entidad `HostChange`.
- modificar lib/features/room/domain/entities/room.dart — `inherited`.
- modificar lib/features/room/domain/entities/room.freezed.dart — regenerado por build_runner.
- modificar lib/features/room/presentation/providers/room_provider.dart — `roomHandoverProvider`, sucesión, cambios de anfitrión, `handOverAndLeave` y `applyHostChange`.
- modificar lib/features/room/presentation/providers/room_provider.g.dart — regenerado por build_runner.
- crear lib/features/room/presentation/widgets/room_handover.dart — hojas de salir con traspaso y de sucesor, y `HandoverNotice`.
- modificar lib/features/room/presentation/widgets/room_header.dart — «Llevas la frecu».
- modificar lib/features/room/presentation/pages/room_page.dart — salir con traspaso, aviso y sin aviso de salida del anfitrión.
- modificar lib/i18n/strings.i18n.json — textos en español.
- modificar lib/i18n/strings_en.i18n.json — textos en inglés.
- modificar lib/i18n/strings.g.dart — regenerado por slang.
- modificar lib/i18n/strings_es.g.dart — regenerado por slang.
- modificar lib/i18n/strings_en.g.dart — regenerado por slang.
- crear test/features/room/data/room_handover_test.dart — toma y reconexión con servidores reales en 127.0.0.1 (AC7).
- crear test/features/room/presentation/room_handover_ui_test.dart — hojas, aviso, toast y cabecera (AC6, AC7).
- modificar docs/protocolo.md — `host_handover`, `host_changed` y `peerId` del `join`.

## Tareas

- [x] T1: Toma de la frecu y reconexión de los demás con su mismo lugar
  - files: lib/features/room/data/models/signaling_message.dart, lib/features/room/data/models/signaling_message.freezed.dart, lib/features/room/data/models/signaling_message.g.dart, lib/features/room/data/datasources/signaling_server_datasource.dart, lib/features/room/data/datasources/room_succession.dart, lib/features/room/data/repositories/room_reconnection.dart, lib/features/room/data/repositories/room_repository_impl.dart, lib/features/room/domain/repositories/room_handover.dart, test/features/room/data/room_handover_test.dart, docs/protocolo.md
  - ac: AC7
  - verify: flutter test test/features/room/data/room_handover_test.dart test/features/room/data/room_reconnect_test.dart test/features/room/data/room_succession_test.dart
- [x] T2: Hojas de salir y de sucesor, aviso de quien la recibe, toast y cabecera
  - files: lib/features/room/domain/entities/room.dart, lib/features/room/domain/entities/room.freezed.dart, lib/features/room/presentation/providers/room_provider.dart, lib/features/room/presentation/providers/room_provider.g.dart, lib/features/room/presentation/widgets/room_handover.dart, lib/features/room/presentation/widgets/room_header.dart, lib/features/room/presentation/pages/room_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/room/presentation/room_handover_ui_test.dart
  - ac: AC6, AC7
  - verify: flutter test test/features/room/presentation/room_handover_ui_test.dart

## Riesgos

- R1: Sacar el bucle de reintentos del repositorio podría cambiar la reconexión de hoy — se mueve sin cambiar tiempos ni orden, y T1 corre `room_reconnect_test` y `room_succession_test`.
- R2: En pruebas, quien recibe la frecu abre su servidor en el mismo puerto que acaba de soltar el anfitrión — `HostTakeover` reintenta abrirlo unas veces antes de rendirse.
- R3: Un `case` más en los `switch` del repositorio puede pasar el límite de complejidad de `specty check` — los mensajes de traspaso se atienden en funciones propias.

## Cierre

### Resumen

Traspaso voluntario en una frecu local sobre una Wi-Fi compartida. Protocolo aditivo: `host_handover { to, term }`, `host_changed { host, term, reason }` y `join.peerId` (se omite si es nulo); `welcome` no cambia. El servidor del anfitrión pasa la frecu (`handOver`: difunde `host_handover` y `peer_left` propio, y se detiene sin `room_closed`); el de quien la recibe, con `inherited` (`InheritedRoom`), guarda un lugar a cada persona heredada (mismo id, orden y hora de llegada) que se ocupa con `join.peerId`, sin `peer_joined`, y responde `host_changed`. `RoomRepositoryImpl` implementa la interfaz nueva del dominio `RoomHandover` (`succession`, `watchSuccession`, `watchHostChanges`, `handOver`), sin tocar `RoomRepository`: quien recibe la frecu abre el servidor con `term + 1` y vuelve a su lugar como anfitrión; los demás reconectan a su IP con su mismo id. En la presentación, hojas «¿Qué pasa con la frecu?» y «¿Quién lleva la frecu?», `HandoverNotice` (toast con la firma a los demás y aviso «Ahora llevas la frecu.» con «Mostrar el QR» a quien la recibe), «Llevas la frecu» en la cabecera y la invitación con la IP nueva. 4 pruebas AC7 con servidores reales y 8 de interfaz (AC6, AC7); `flutter analyze` sin problemas y `flutter test` completo en verde (1197).

### Desviaciones

- `HostChange` vive en `domain/repositories/room_handover.dart` junto a la interfaz, para no sumar un archivo de código más.
- El servidor recibe la frecu heredada como propiedad (`inherited`, una `InheritedRoom` de `room_succession.dart`) y no como método `inherit`, y la lógica de los lugares heredados se movió a `InheritedRoom` para no pasar de 500 líneas en `signaling_server_datasource.dart`.
- `_listen` del repositorio se partió (`_onMessage`, `_onWelcomeMessage` y la clase `_Joining`), y el `join` del servidor (`_admits`), por los límites de líneas y complejidad de `specty check`.
- La isla deja de avisar la salida del anfitrión (solo sale de una frecu que sigue cuando la pasa); el aviso lo da el cambio de anfitrión.
- Los textos de `lost` («se desconectó») ya están en slang y en `HandoverNotice`, aunque la caída es de C5.

### Decisiones

- Lugares heredados en el servidor de quien recibe la frecu, en vez de dejar que cada uno vuelva como nuevo: la lista no parpadea, la isla no avisa entradas y salidas falsas, la malla WebRTC entre invitados no se rehace (mismo id) y el orden de sucesión se conserva. Quien no vuelve sale por latido (`peerTimeout`).
- Mientras el servidor se detiene no acepta conexiones (`_closing`): en pruebas, todos en 127.0.0.1, un invitado podía entrar al servidor que se cerraba como anfitrión.
- Quien recibe la frecu reintenta abrir el puerto 10 veces cada 300 ms, por si el anterior aún lo suelta.
- `roomHandoverProvider` devuelve el repositorio solo si implementa `RoomHandover`: con los dobles de `RoomRepository` de las pruebas aprobadas la salida sigue como hoy.
- La hoja de salir con traspaso dice «Llevas la frecu y hay N personas más.» en vez del «Eres el anfitrión…» del prototipo, para no suponer género.
- Tras pasar la frecu, quien sale vuelve al inicio como un invitado que sale (sin pantalla de cierre).

### Pendientes

- P160: el micrófono abierto no se retoma solo tras el traspaso (C7).
- P161: quien recibe la frecu no la anuncia por mDNS ni Bluetooth; solo con su QR.
- P162: `room_repository_impl.dart` (788 líneas de código) y `room_page.dart` (615) siguen grandes; P159 sigue abierto.
- P163: probar el traspaso voluntario en teléfonos reales.
- C5: probar con el siguiente de la sucesión si quien recibe la frecu no responde, y el `term` en el `join`.
