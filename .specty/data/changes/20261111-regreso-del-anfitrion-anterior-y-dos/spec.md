---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C10
---

# Regreso del anfitrión anterior y dos anfitriones a la vez: gana el turno mayor y el otro entra como invitado

## Objetivo

En una frecu local sobre una Wi-Fi compartida, cuando el anfitrión anterior vuelve con su frecu aún abierta (estuvo fuera de alcance) o dos teléfonos llevan la misma frecu a la vez (una partición de la red), se encuentran solos: gana el turno mayor (a igual turno, quien va antes en la sucesión) y el otro entra como invitado con sus invitados, con el aviso «Volviste como invitado · «nombre» lleva la frecu». Prototipo aprobado: `docs/diseno/prototipo/anfitrion.js`, `backAsGuest` (en la carpeta principal).

## Fuera de alcance

- Por internet: el Worker y su turno (C6).
- Que la voz no se corte al cambiar de anfitrión (C7).
- La espera en pantalla cuando el anfitrión no responde (C9).
- Un aviso nuevo para los invitados del que pierde: vuelven al ganador como en un traspaso de C4 y ven sus avisos de hoy.
- Retirar el anuncio mDNS del que pierde (hoy nadie lo retira al dejar de ser anfitrión).
- Cambiar el contrato `RoomRepository`, la interfaz `RoomHandover`, los campos de `welcome` o las firmas de `start`, `stop` y `handOver` del servidor.

## Supuestos

- A1: «Vuelve» es que la app del anfitrión anterior siguió con la frecu abierta (fuera de alcance o sin Wi-Fi un rato). Si cerró la app, ya no tiene frecu y entra con el QR como hoy.
  - impacto: alto
- A2: En la red local todos abren su servidor en el mismo puerto (47800), así que basta la IP de cada persona de la sucesión para preguntarle.
  - impacto: alto
- A3: Preguntar cada 3 s a las pocas IPs de quienes salieron (5 como mucho) es barato en una LAN; una IP que rechaza el código (otra frecu) no se vuelve a preguntar, para no bloquearla por códigos incorrectos.
- A4: Los invitados del que pierde que tenían lugar heredado en el ganador vuelven a él con su mismo id; los demás, y el que pierde, entran con un id nuevo.

## Criterios de aceptación

- AC9: CUANDO, en una frecu local en una Wi-Fi compartida, el anfitrión anterior vuelve con su frecu abierta o dos teléfonos llevan la misma frecu a la vez ENTONCES cada anfitrión pregunta con `host_probe` (código, turno, su id y su puerto) en las IPs de quienes salieron de su sucesión, y quien responde con el código correcto devuelve su propio `host_probe`. Gana el turno mayor y, a igual turno, el `peer_N` menor; el otro avisa a sus invitados `host_handover` con el id, la IP y el puerto del ganador, cierra su servidor sin `room_closed` y entra como invitado al ganador, sin volver a escribir el código. Emite un `HostChange` con razón `outranked` y quien la lleva, y ve el aviso «Volviste como invitado · «nombre» lleva la frecu», la cabecera «Anfitrión · «nombre»» y deja de llevar la frecu (su invitación es la del ganador). Sus invitados vuelven al ganador. Un `host_probe` con el código incorrecto se rechaza como un `join` incorrecto.

## Diseño

- **Protocolo (aditivo).** Mensaje nuevo `host_probe { accessCode, term, host, port }`: un anfitrión pregunta con él a otro servidor, que responde con su propio `host_probe` (su turno, su id y su puerto) y cierra el socket. Con el código incorrecto, `rejected(invalidAccessCode)` y cuenta para el bloqueo, como un `join`. `host_handover` gana `address` y `port` opcionales: a dónde ir cuando quien la recibe no está en la sucesión de los invitados. Un solo tipo de mensaje en las dos direcciones, en lugar de `host_probe` y `host_info`.
- **`host_probe.dart`** (pieza nueva en `data/datasources`). `outranks(term, host, otherTerm, otherHost)`: gana el turno mayor y, a igual turno, el número menor de `peer_N`. `HostRival { host, term, address, port }`. `HostProbe`: recuerda las IPs de todas las personas que vio en la sucesión durante la sesión (`remember`), y mientras este teléfono lleva una frecu local con traspaso, cada 3 s pregunta en las IPs de quienes ya no están (sin la suya ni las de quienes siguen), en el puerto de la frecu (configurable en pruebas). Si la respuesta lo supera, avisa al repositorio y se detiene; si lo rechazan, deja esa IP.
- **Servidor.** Antes del `join`, responde `host_probe` con el suyo; si el que pregunta lo supera, lo avisa en `rivals` (con la IP del socket y el puerto del mensaje). `yieldTo(HostRival)` manda `host_handover` con el id, el turno, la IP y el puerto del ganador, y se detiene sin `room_closed`, como `handOver`.
- **Repositorio.** Al recibir su `welcome` como anfitrión, arranca `HostProbe`; lo detiene al soltar la conexión. Cada `room_state` lo recuerda. Ante un rival (de la pregunta propia o de `rivals`), una sola vez: `yieldTo`, deja de ser anfitrión, apunta la reconexión al ganador con su id y sigue como tras un `host_handover` (`_following`). Al llegar el `welcome` del ganador, emite `HostChange(reason: outranked, you: false)` con quien la lleva. Un invitado que recibe `host_handover` usa su `address` y `port` si vienen.
- **Dominio.** `HostChangeReason.outranked`.
- **Pantalla.** `applyHostChange` deja de llevar la frecu con `outranked` (`hosting: false`), y `HandoverNotice` muestra «Volviste como invitado · «nombre» lleva la frecu» con el ícono `check`, como el prototipo. Textos en slang es/en, sin suponer género.

## Archivos

- modificar lib/features/room/data/models/signaling_message.dart — `host_probe` y `address`/`port` de `host_handover`.
- modificar lib/features/room/data/models/signaling_message.freezed.dart — regenerado por build_runner.
- modificar lib/features/room/data/models/signaling_message.g.dart — regenerado por build_runner.
- crear lib/features/room/data/datasources/host_probe.dart — `outranks`, `HostRival` y `HostProbe`.
- modificar lib/features/room/data/datasources/signaling_server_datasource.dart — responder `host_probe`, `rivals` y `yieldTo`.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — preguntar mientras lleva la frecu, ceder al rival y seguir `host_handover` con IP y puerto.
- modificar lib/features/room/domain/repositories/room_handover.dart — `HostChangeReason.outranked`.
- modificar lib/features/room/presentation/providers/room_provider.dart — `applyHostChange` deja de llevar la frecu con `outranked`.
- modificar lib/features/room/presentation/widgets/room_handover.dart — aviso «Volviste como invitado».
- modificar lib/i18n/strings.i18n.json — texto en español.
- modificar lib/i18n/strings_en.i18n.json — texto en inglés.
- modificar lib/i18n/strings.g.dart — regenerado por slang.
- modificar lib/i18n/strings_es.g.dart — regenerado por slang.
- modificar lib/i18n/strings_en.g.dart — regenerado por slang.
- crear test/features/room/data/host_probe_test.dart — `outranks`, respuesta del servidor, rechazo por código y `yieldTo` (AC9).
- crear test/features/room/data/host_rivalry_test.dart — el anterior vuelve y entra como invitado; sus invitados van al ganador, con servidores reales en 127.0.0.1 (AC9).
- crear test/features/room/presentation/host_outranked_ui_test.dart — aviso, cabecera y deja de llevar la frecu (AC9).
- modificar docs/protocolo.md — `host_probe` y `address`/`port` de `host_handover`.

## Tareas

- [x] T1: `host_probe` en el protocolo, `HostProbe` y `outranks`, y el servidor responde y cede
  - files: lib/features/room/data/models/signaling_message.dart, lib/features/room/data/models/signaling_message.freezed.dart, lib/features/room/data/models/signaling_message.g.dart, lib/features/room/data/datasources/host_probe.dart, lib/features/room/data/datasources/signaling_server_datasource.dart, test/features/room/data/host_probe_test.dart, docs/protocolo.md
  - ac: AC9
  - verify: flutter test test/features/room/data/host_probe_test.dart test/features/room/data/signaling_server_test.dart test/features/room/data/signaling_term_test.dart test/features/room/data/signaling_access_test.dart
- [ ] T2: El repositorio pregunta mientras lleva la frecu, cede al turno mayor y entra como invitado
  - files: lib/features/room/data/repositories/room_repository_impl.dart, lib/features/room/domain/repositories/room_handover.dart, test/features/room/data/host_rivalry_test.dart
  - ac: AC9
  - verify: flutter test test/features/room/data/host_rivalry_test.dart test/features/room/data/host_failover_test.dart test/features/room/data/room_handover_test.dart test/features/room/data/room_reconnect_test.dart
- [ ] T3: Aviso «Volviste como invitado» y deja de llevar la frecu
  - files: lib/features/room/presentation/providers/room_provider.dart, lib/features/room/presentation/widgets/room_handover.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/room/presentation/host_outranked_ui_test.dart
  - ac: AC9
  - verify: flutter test test/features/room/presentation/host_outranked_ui_test.dart test/features/room/presentation/room_handover_ui_test.dart

## Riesgos

- R1: Los dos anfitriones se detectan a la vez (cada uno pregunta al otro) — `outranks` es un orden total, así que los dos eligen al mismo ganador, y el que pierde cede una sola vez.
- R2: `room_repository_impl.dart` ya es grande (P162) — la pregunta, el orden y el rival viven en `host_probe.dart`; el repositorio solo arranca, detiene y cede.
- R3: En pruebas todos están en 127.0.0.1 con puertos distintos — `HostProbe` recibe el puerto al que preguntar, y `host_handover` lleva el puerto del ganador.
- R4: Preguntar a una IP que ahora lleva otra frecu cuenta como código incorrecto allí — se deja de preguntarle tras el primer rechazo.
