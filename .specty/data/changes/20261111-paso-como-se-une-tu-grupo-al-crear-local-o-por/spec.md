---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C8
---

# Paso «¿Cómo se une tu grupo?» al crear (Local o Por internet), pasos de 3 o 2, etiqueta bajo la hora y sin el interruptor «Permitir internet»

## Objetivo

Al crear una frecu, el anfitrión elige primero cómo se une su grupo: **Local** (marcada) o **Por internet**. Local sigue a «Prepara la red» y a «Nueva frecu» (pasos de 3); Por internet va directo a «Nueva frecu» (pasos de 2). «Nueva frecu» pierde el interruptor «Permitir internet» y muestra el tipo elegido bajo «Abierta a las HH:MM». Prototipo aprobado: `kindStep` y `createOf` de `docs/diseno/prototipo/anfitrion.js` (grupo «Crear · el tipo va primero»).

## Fuera de alcance

- Borrar `room.internet.*` y `room.sheets.invite.internet.andWifi` con la rama «y Wi-Fi» de la hoja de invitar: siguen en uso (`internet_room_ui_test` y `invite_sheet.dart`) y son del módulo `room`; con ellos el corte pasaría de 2 módulos. Quedan como pendiente.
- Traspaso de anfitrión, sucesión y turnos (cortes C2 a C7).
- Cambiar cómo se abre la frecu según su tipo (C1 ya lo hace: `createRoom(reach:)`).
- Cambiar la guía de la zona Wi-Fi que se abre sola desde Ajustes (sigue sin paso).

## Supuestos

- A1: «Sin internet» es que el teléfono no resuelve, en 3 s, el nombre del servidor del punto de encuentro. El paso lo comprueba al abrirse y, mientras falte, cada 5 s; si vuelve, «Por internet» se habilita sola.
- A2: Sin punto de encuentro configurado (compilación sin `FRECU_CLOUD_URL`), «Por internet» se ve atenuada con «Esta versión de Frecu no crea frecus por internet.»; el prototipo solo define el texto de sin internet.
- A3: Si Android ya creó la red de Frecu, se vuelve a «¿Cómo se une tu grupo?» y se sigue con Por internet, la red se apaga: una frecu por internet no la usa.
- A4: El paso del tipo es el primero también en iPhone; en Android, «Prefiero mi zona Wi-Fi» abre la guía como «Paso 2 de 3».

## Criterios de aceptación

- AC1: CUANDO el usuario toca «Crear frecu» ENTONCES el primer paso pregunta «¿Cómo se une tu grupo?» con «Local» (marcada por defecto) y «Por internet». Local sigue a «Prepara la red» y luego a «Nueva frecu» (pasos de 3); Por internet va directo a «Nueva frecu» (pasos de 2). Sin internet, o sin punto de encuentro configurado, «Por internet» se ve atenuada y dice qué falta. «Nueva frecu» ya no tiene el interruptor «Permitir internet», y bajo «Abierta a las HH:MM» lleva la etiqueta «Local» o «Por internet».

## Diseño

- **Paso del tipo.** `RoomReachStep` (nuevo, en `widgets/`) replica la estructura de los pasos (`FrScaffold`, `CreateRoomAppBar`, `CreateRoomScroll`, dock con `FrButton.drawn` «Seguir» y flecha) y sus opciones replican `AudioRouteOption` (`.opt`: ícono en caja de 44, título, detalle en `labelS`, marca redonda; atenuada al 45 % y sin respuesta si no está disponible). Ícono `hotspot` para Local y `globe` para Por internet. El paso muestra «Paso 1 de 3» o «Paso 1 de 2» según la opción marcada.
- **Internet.** Provider `internetCheck` (`@riverpod`, en el mismo archivo del paso): una función que dice si se resuelve el servidor del punto de encuentro (`cloudConfigProvider`); sin punto de encuentro, falso sin consultar. Las pruebas la reemplazan. Si «Por internet» deja de estar disponible estando marcada, vuelve a Local.
- **Orden.** `CreateRoomPage` empieza en `RoomReachStep`. Seguir con Local empuja la red de hoy (`LocalNetworkStep` en Android, la guía en iPhone); con Por internet empuja `NewRoomStep(reach: internet)` y apaga la red de Frecu si estaba creada. Atrás en la red vuelve al paso del tipo; Atrás en el paso del tipo sale al inicio.
- **Pasos.** `CreateRoomAppBar` recibe `steps` (total) y `CreateRoomAppBar.stepsFor(reach)` da 3 o 2. La red de Frecu y la guía son «Paso 2 de 3»; «Nueva frecu» es «Paso 3 de 3» o «Paso 2 de 2».
- **Nueva frecu.** `NewRoomStep` recibe `reach` y deja `_internet`, `_internetRow` y `FrToggle`. `NewRoomHero` recibe `reach` y siempre muestra la etiqueta bajo «Abierta a las HH:MM»: `hotspot` + «Local» o `globe` + «Por internet».
- **Textos.** Nuevos en `lobby.newRoom.reach` (es/en); se borran `lobby.newRoom.internet.*`, que quedan sin uso. Nunca «router».

## Archivos

- crear lib/features/lobby/presentation/widgets/room_reach_step.dart — paso «¿Cómo se une tu grupo?», sus opciones y el provider `internetCheck`.
- crear lib/features/lobby/presentation/widgets/room_reach_step.g.dart — generado por build_runner.
- modificar lib/features/lobby/presentation/pages/create_room_page.dart — empieza en el paso del tipo y sigue según la opción.
- modificar lib/features/lobby/presentation/widgets/create_room_layout.dart — total de pasos variable (3 o 2).
- modificar lib/features/lobby/presentation/widgets/local_network_step.dart — «Paso 2 de 3».
- modificar lib/features/lobby/presentation/widgets/hotspot_guide_step.dart — «Paso 2 de 3» en la creación.
- modificar lib/features/lobby/presentation/widgets/new_room_step.dart — recibe el tipo, sin interruptor, paso 3 de 3 o 2 de 2.
- modificar lib/features/lobby/presentation/widgets/new_room_hero.dart — etiqueta Local o Por internet bajo la hora.
- modificar lib/i18n/strings.i18n.json — textos del paso del tipo; sin `newRoom.internet`.
- modificar lib/i18n/strings_en.i18n.json — lo mismo en inglés.
- modificar lib/i18n/strings.g.dart — generado por slang.
- modificar lib/i18n/strings_es.g.dart — generado por slang.
- modificar lib/i18n/strings_en.g.dart — generado por slang.
- modificar test/features/lobby/presentation/new_room_test.dart — paso del tipo, pasos, etiqueta y sin interruptor.
- modificar test/features/lobby/presentation/hotspot_guide_test.dart — la guía tras el paso del tipo, «Paso 2 de 3» y «Paso 3 de 3».
- modificar test/features/lobby/presentation/local_network_step_test.dart — la red tras el paso del tipo, «Paso 2 de 3».
- modificar test/features/lobby/presentation/room_note_flow_test.dart — pasa por el paso del tipo.
- modificar test/features/lobby/presentation/new_room_note_test.dart — pasa por el paso del tipo.
- modificar test/features/lobby/presentation/saved_name_test.dart — pasa por el paso del tipo.
- modificar test/features/room/presentation/room_flow_test.dart — pasa por el paso del tipo.

## Tareas

- [x] T1: «Nueva frecu» con el tipo: sin interruptor, etiqueta bajo la hora y pasos de 3 o 2
  - files: lib/features/lobby/presentation/widgets/new_room_step.dart, lib/features/lobby/presentation/widgets/new_room_hero.dart, lib/features/lobby/presentation/widgets/create_room_layout.dart, lib/features/lobby/presentation/pages/create_room_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart
  - ac: AC1
  - verify: flutter test test/features/lobby/presentation/new_room_test.dart
- [x] T2: Paso «¿Cómo se une tu grupo?» antes de la red
  - files: lib/features/lobby/presentation/widgets/room_reach_step.dart, lib/features/lobby/presentation/widgets/room_reach_step.g.dart, lib/features/lobby/presentation/pages/create_room_page.dart, lib/features/lobby/presentation/widgets/local_network_step.dart, lib/features/lobby/presentation/widgets/hotspot_guide_step.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/new_room_test.dart, test/features/lobby/presentation/hotspot_guide_test.dart, test/features/lobby/presentation/local_network_step_test.dart
  - ac: AC1
  - verify: flutter test test/features/lobby/presentation/new_room_test.dart test/features/lobby/presentation/hotspot_guide_test.dart test/features/lobby/presentation/local_network_step_test.dart
- [x] T3: El resto de los flujos de creación pasan por el paso del tipo
  - files: test/features/lobby/presentation/room_note_flow_test.dart, test/features/lobby/presentation/new_room_note_test.dart, test/features/lobby/presentation/saved_name_test.dart, test/features/room/presentation/room_flow_test.dart
  - ac: AC1
  - verify: flutter test test/features/lobby/presentation/room_note_flow_test.dart test/features/lobby/presentation/new_room_note_test.dart test/features/lobby/presentation/saved_name_test.dart test/features/room/presentation/room_flow_test.dart

## Riesgos

- R1: La consulta DNS puede responder desde la caché sin internet — en ese caso «Por internet» se ve habilitada y, al abrir, la creación falla con el aviso de red de hoy.
- R2: Las pruebas que entran a la creación desde el inicio cambian todas a la vez — se cubren en T2 y T3 y se corre `flutter test` completo al final.
