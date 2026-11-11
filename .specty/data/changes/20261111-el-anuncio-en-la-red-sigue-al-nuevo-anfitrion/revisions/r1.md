---
kind: standard
---

# El anuncio en la red sigue al nuevo anfitrión tras el traspaso

## Objetivo

En una Wi-Fi compartida, el anuncio mDNS de la frecu lo hace siempre quien la lleva: al recibirla, el teléfono empieza a anunciarla con su puerto, y al cederla (o al volver como invitado porque otro la lleva con un turno que gana) deja de anunciarla. Así «Frecus cercanas» muestra la frecu con la dirección de su anfitrión actual.

## Fuera de alcance

- Frecus por internet: siguen sin anunciarse en la red local.
- Frecus en la red del anfitrión (red de Frecu o zona Wi-Fi): no tienen traspaso.
- Cambiar el contenido del anuncio (TXT) o el datasource mDNS.
- Pruebas en teléfonos reales (quedan como pendiente manual).

## Supuestos

- A1: El cambio de anfitrión ya llega al estado de la frecu: `RoomNotifier.applyHostChange` pone `hosting` y `port` del nuevo anfitrión (lo llama `HandoverNotice`).
  - impacto: alto
- A2: El inicio (`LobbyPage`) sigue montado debajo de la frecu y escucha `roomNotifierProvider`; ya retira el anuncio cuando la frecu termina.
- A3: Volver a publicar reemplaza el anuncio anterior (`MdnsDataSource.publish` desregistra antes de registrar).
- A4: Al crear la frecu la publica la pantalla de nueva frecu; el inicio solo reacciona a cambios de `hosting` entre dos estados de la misma frecu, para no publicar dos veces.

## Criterios de aceptación

- AC1: CUANDO un invitado de una frecu local pasa a llevarla (su `hosting` cambia de falso a verdadero) ENTONCES su teléfono publica el anuncio mDNS con el id, el nombre, la nota y el puerto de su servidor.
- AC2: CUANDO el teléfono que llevaba una frecu local deja de llevarla sin salir de ella (`hosting` cambia de verdadero a falso, p. ej. al entrar como invitado por un turno que gana) ENTONCES retira su anuncio mDNS.
- AC3: CUANDO el teléfono pasa a llevar una frecu por internet ENTONCES no publica nada en la red local.
- AC4: CUANDO el anfitrión cede la frecu y sale ENTONCES su anuncio se retira, como al salir (sin cambios en ese camino).

## Diseño

`LobbyPage._onRoomChanged` ya escucha la frecu activa. Se amplía: si `previous` y `next` son la misma frecu (mismo `id`) y cambia `hosting`, entonces con `next.hosting` y `next.reach == RoomReach.local` publica con `discoveryRepositoryProvider.publishRoom(roomId, name, port, note)`; si `hosting` pasa a falso, llama a `stopPublishingRoomProvider`. El camino de salida (frecu a nula) no cambia.

## Archivos

- modificar lib/features/lobby/presentation/pages/lobby_page.dart — el inicio publica o retira el anuncio cuando este teléfono empieza o deja de llevar la frecu.
- modificar test/features/lobby/presentation/lobby_page_test.dart — pruebas de AC1, AC2 y AC3.

## Tareas

- [ ] T1: El anuncio sigue a quien lleva la frecu
  - files: lib/features/lobby/presentation/pages/lobby_page.dart, test/features/lobby/presentation/lobby_page_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: flutter test test/features/lobby/presentation/lobby_page_test.dart

## Riesgos

- R1: El nuevo anfitrión aún no sabe su nota si la frecu no la trae — se publica sin `n`, como cualquier frecu sin nota.
