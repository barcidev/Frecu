---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C9
---

# La espera en pantalla cuando el anfitrión no responde: isla ««anfitrión» no responde · N s», pista con el sucesor y solo el anfitrión en reconectando

## Objetivo

Cuando el anfitrión de una frecu con traspaso deja de responder, los invitados ya no ven toda la frecu en «Reconectando»: la isla dice quién no responde y cuánto lleva así, en la malla solo el anfitrión se ve reconectando, el PTT sigue habilitado y la pista dice quién tomará la frecu si no vuelve (prototipo `guestSearching` de `docs/diseno/prototipo/anfitrion.js`). Es la parte de interfaz de AC8 de la épica; los datos de la caída ya están en develop (C5).

## Fuera de alcance

- La lógica de la caída (reintentos, sucesión, toma): ya la hace C5 en `room_reconnection.dart` y `room_repository_impl.dart`, que no se tocan.
- La notificación del sistema durante la espera: sigue diciendo «Reconectando».
- Frecus sin traspaso (red de Frecu o zona Wi-Fi del anfitrión): siguen con la reconexión de hoy.
- El regreso del anfitrión anterior (C10) y la voz entre invitados durante el traspaso (C7).
- Cambiar el contrato de `RoomRepository` o de `RoomHandover`.

## Supuestos

- A1: La presentación sabe que el anfitrión no responde cuando la frecu está en `RoomStatus.reconnecting`, la sucesión conocida (`RoomHandover.succession`) tiene `handover` y quien reconecta no es el anfitrión. No distingue la caída del anfitrión de la de la propia red del invitado: en los dos casos sigue el mismo plan de caída.
  - impacto: alto
- A2: «N s» cuenta hacia arriba los segundos desde que el anfitrión dejó de responder; a 0 s la isla dice solo ««anfitrión» no responde».
- A3: El sucesor que nombra la pista es el mismo que sigue el plan de caída (`FailoverPlan`): la primera persona de la sucesión que no es el anfitrión, que sigue en la frecu y, en una frecu local, tiene IP (o es este teléfono). Si es este teléfono, la pista dice «si no vuelve, tomas la frecu». Si no hay sucesor, se ve la reconexión de hoy.
- A4: En el traspaso voluntario, mientras los demás siguen al nuevo anfitrión, la pantalla puede mostrar la espera un momento antes del aviso «… lleva ahora la frecu»; la presentación no sabe que es voluntario sin cambiar `RoomHandover`.

## Criterios de aceptación

- AC1: CUANDO el anfitrión de una frecu con traspaso deja de responder ENTONCES la isla, en tono de aviso, dice ««anfitrión» no responde · N s» con los segundos que lleva sin responder, por encima de los eventos pasajeros.
- AC2: CUANDO el anfitrión de una frecu con traspaso deja de responder ENTONCES en la malla solo el anfitrión aparece en «Reconectando» y los demás siguen con su enlace de voz.
- AC3: CUANDO el anfitrión de una frecu con traspaso deja de responder ENTONCES el PTT sigue habilitado («Mantén») y la pista dice «Siguen hablando · si no vuelve, «sucesor» toma la frecu», o «Siguen hablando · si no vuelve, tomas la frecu» si el sucesor es este teléfono.
- AC4: CUANDO la frecu no tiene traspaso, no hay sucesor o el anfitrión vuelve ENTONCES se ve lo de hoy: la reconexión con su cuenta atrás o la frecu conectada.
- AC5: CUANDO los textos de la espera se muestran en español o en inglés ENTONCES salen de slang, no suponen género y no dicen «router».

## Diseño

- **`HostSilence`** (`presentation/widgets/host_silence.dart`): valor inmutable con el id y el nombre del anfitrión que no responde y el sucesor (o «tú»). `HostSilence.find(status, succession, participants, localId)` decide si hay espera (A1, A3). Da el texto de la isla, la pista del PTT y la vista de la frecu durante la espera: el estado se muestra conectado y el anfitrión, con su enlace en `reconnecting`, de modo que `buildMeshNodes` pone solo su nodo en «Reconectando».
- **Providers** (`host_silence_provider.dart`, como `reconnect_countdown_provider.dart`): `hostSilenceProvider` arma la espera con el estado, los participantes y la sucesión del repositorio; `hostSilenceClockProvider` cuenta los segundos hacia arriba mientras dura la espera del mismo anfitrión.
- **`RoomTalk`** gana `silence` y la fase de isla `hostSilent`, que manda sobre todo; `RoomStatusIsland` recibe los segundos y usa `StatusIsland.reconnecting` (ámbar con punto). La fase del PTT sigue la de siempre (con la frecu conectada, «Mantén»).
- **PTT**: `PttCore` recibe una pista de reposo opcional que reemplaza la de `idle`; `MicControlSection` le pasa la de la espera.
- **`room_page.dart`**: aplica la espera a participantes y estado; no crece (se compacta lo que añade).
- **Textos** (slang es/en): `room.talk.island.hostSilent`, `room.talk.island.hostSilentFor`, `room.talk.hint.hostSilent`, `room.talk.hint.hostSilentYou`.

## Archivos

- crear lib/features/room/presentation/widgets/host_silence.dart — la espera: quién no responde, el sucesor, textos y la vista de la frecu
- crear lib/features/room/presentation/providers/host_silence_provider.dart — espera y reloj de segundos
- crear lib/features/room/presentation/providers/host_silence_provider.g.dart — código generado por riverpod
- modificar lib/features/room/presentation/widgets/room_talk.dart — `RoomTalk.silence`, fase `hostSilent` y la isla con sus segundos
- modificar lib/features/room/presentation/widgets/ptt_core_face.dart — pista de reposo opcional en `PttCopy.of`
- modificar lib/features/room/presentation/widgets/ptt_core.dart — parámetro de pista de reposo
- modificar lib/features/room/presentation/widgets/mic_control_section.dart — pasa la pista de la espera al núcleo
- modificar lib/features/room/presentation/pages/room_page.dart — aplica la espera a la isla, la malla y el PTT
- modificar lib/i18n/strings.i18n.json — textos en español
- modificar lib/i18n/strings_en.i18n.json — textos en inglés
- modificar lib/i18n/strings_es.g.dart — código generado por slang
- modificar lib/i18n/strings_en.g.dart — código generado por slang
- modificar lib/i18n/strings.g.dart — código generado por slang (conteo de claves)
- crear test/features/room/presentation/host_silence_test.dart — pruebas de la espera

## Tareas

- [ ] T1: La espera del anfitrión (`HostSilence`, providers y textos)
  - files: lib/features/room/presentation/widgets/host_silence.dart, lib/features/room/presentation/providers/host_silence_provider.dart, lib/features/room/presentation/providers/host_silence_provider.g.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, lib/i18n/strings.g.dart, test/features/room/presentation/host_silence_test.dart
  - ac: AC3, AC4, AC5
  - verify: flutter test test/features/room/presentation/host_silence_test.dart
- [ ] T2: La espera en la pantalla de la frecu: isla, malla y pista del PTT
  - files: lib/features/room/presentation/widgets/room_talk.dart, lib/features/room/presentation/widgets/ptt_core_face.dart, lib/features/room/presentation/widgets/ptt_core.dart, lib/features/room/presentation/widgets/mic_control_section.dart, lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/host_silence_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: flutter test test/features/room/presentation

## Riesgos

- R1: Conflictos con C10 en `lib/i18n/*.json` y sus generados — las claves nuevas van bajo `room.talk`, lejos de `room.handover`; se regeneran con `dart run slang` al fusionar.
- R2: Una pista larga no cabe bajo el núcleo — se comprueba en la prueba de widget con el texto en mayúsculas.
