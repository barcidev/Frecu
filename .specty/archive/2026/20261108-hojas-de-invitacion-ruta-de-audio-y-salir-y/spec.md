---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C19
---

# Hojas de invitación, ruta de audio y salir, y pantalla de cierre

## Objetivo

La frecu activa cambia el diálogo QR, el botón de ruta de la cabecera, la salida directa y el diálogo «La frecu fue cerrada» por las piezas del prototipo aprobado (`SH.invite`, `SH.route`, `SH.leave`, `V.closed` y `UI.route` de `docs/diseno/prototipo/screens.js` y `components.js`): la hoja de invitación con el QR de módulos redondos, la pastilla de ruta a la izquierda del selector con su hoja de salidas de audio, la hoja que confirma salir o cerrar la frecu para todos y la pantalla «Fin de la transmisión». Cierra AC7 de la épica y los pendientes P74 (íconos propios en la cabecera) y P107 (pastilla de ruta en la fila de controles), sin perder el PTT, el micrófono abierto ni el ruteo de audio actuales.

## Fuera de alcance

- Borrar `PttButton` (`ptt_button.dart`) y su prueba (P104): cabe en el límite de módulos, pero sus dos borrados suman 4 puntos y pasarían el corte a talla XL; sigue pendiente.
- Cambios en `lib/core` y en `lib/app/router`: la variante sólida `danger-solid` de `FrButton`, los ojos de esquina suave del QR (`qr_flutter` 4.1 solo tiene ojos cuadrados o redondos) y una ruta nueva para el cierre sumarían un tercer módulo.
- El nombre del dispositivo Bluetooth (`AudioRoute.bluetooth` no lo trae) y el evento pasajero «Audio por …» de la isla.
- Transiciones del router (P53): la pantalla de cierre entra con un fundido dentro de `RoomPage`.
- Cambios en el dominio, los repositorios, el protocolo y `BuildInviteQr`.

## Supuestos

- A1: La pantalla de cierre es una vista de `RoomPage` (como el prototipo, que la nombra `RoomStatus.closed`), no una ruta nueva: registrar una página en `lib/app/router` pasaría el límite de 2 módulos.
  - impacto: alto
- A2: Como en el prototipo, quien no es anfitrión y confirma «Salir de la frecu» vuelve al inicio sin pantalla de cierre; el anfitrión que confirma «Cerrar frecu» ve la pantalla de cierre con su texto; y quien recibe `RoomStatus.closed` con un motivo que no es `user_left` (la salida propia) la ve con el texto del anfitrión que cerró o, con `host_unreachable`, el de la señal perdida.
  - impacto: alto
- A3: Al llegar el cierre se llama `leaveRoom()` en el acto para soltar la frecu (lo que hacía «Aceptar» del diálogo) y se cierran las hojas abiertas; «Volver al inicio» solo vuelve atrás.
- A4: La duración va de `Room.createdAt` (apertura para el anfitrión, unión para quien se unió) al cierre, en «mm:ss» o «h:mm:ss» desde una hora; «Personas» es el mayor número de personas que hubo a la vez en la malla, con dos cifras («05»); «Nota» es la nota de la frecu o «—».
- A5: La plataforma no da el nombre del Bluetooth: la opción dice «Bluetooth» con «Conectado» si está en `availableAudioRoutes` o «Sin dispositivo» si no. Toda ruta que no está en `availableAudioRoutes` se ve deshabilitada (al 45 %) y no responde.
- A6: Las barras de la pastilla se mueven mientras se recibe audio (otra persona habla) y quedan quietas en `tx4` en reposo o con movimiento reducido.
- A7: El botón de salir y de cerrar usa `FrButton` `danger` (lavado de alerta), porque `FrButton` no tiene la variante sólida y tocar `lib/core` sumaría un módulo; queda pendiente.
- A8: El QR es un `QrImageView` con módulos redondos, ojos cuadrados y corrección H, en tinta `#0B0D0F` sobre el marco claro `#F4F6F1` en los dos temas para que se pueda escanear, con un cuadro de tinta al centro y la firma de Frecu (Lissajous 2:3, fase 0,6) en `signal`, como `drawQR`.
- A9: Elegir una ruta llama `setAudioRoute` con ella y cierra la hoja; `cycleAudioRoute` deja de usarse desde la pantalla (sigue en el provider).

## Criterios de aceptación

- AC1: CUANDO el usuario toca Invitar en la cabecera o un lugar libre de la malla ENTONCES se abre la hoja con «Invitar a la frecu», «Escanea para unirte» y «Desde Frecu › Escanear. El QR ya incluye el código.», el QR de la invitación (`BuildInviteQr`, con la nota si la hay) en un marco claro, debajo la nota (o «—»), el código de acceso y la IP del anfitrión con «Puerto <n>», y «También aparece en “Frecus cercanas” para quien esté en tu red.»; CUANDO toca Cerrar ENTONCES la hoja se cierra y sigue en la frecu.
- AC2: CUANDO el usuario está en la frecu activa ENTONCES la cabecera lleva solo Invitar (`FrIcons.qr`) y Salir (`FrIcons.exit`), sin íconos de Material ni botón de ruta, y la fila de controles lleva a la izquierda la pastilla de ruta (ícono `FrIcons` de la ruta, su nombre, barras de actividad y flecha) y a la derecha el selector PTT | Abierto de hasta 204 px; CUANDO la ruta cambia ENTONCES la pastilla muestra la nueva (Altavoz, Auricular o Bluetooth).
- AC3: CUANDO el usuario toca la pastilla de ruta ENTONCES se abre la hoja con «Salida de audio», «¿Dónde escuchas?» y «Al conectar audífonos, el audio cambia solo.» y las opciones Altavoz («Manos libres»), Auricular («Teléfono en la oreja») y Bluetooth («Conectado» o «Sin dispositivo»), con la ruta activa marcada y las no disponibles deshabilitadas; CUANDO elige una opción disponible ENTONCES se llama `setAudioRoute` con esa ruta y la hoja se cierra; CUANDO toca una deshabilitada ENTONCES no pasa nada.
- AC4: CUANDO el usuario que no es anfitrión toca Salir ENTONCES se abre la hoja «¿Salir de la frecu?» con «Podrás volver a unirte con el código de acceso.», «Salir de la frecu» y «Cancelar»; CUANDO cancela ENTONCES sigue en la frecu sin llamar a `leaveRoom`; CUANDO confirma ENTONCES se llama `leaveRoom` y vuelve al inicio.
- AC5: CUANDO el anfitrión toca Salir ENTONCES la hoja dice «Cerrar la frecu para todos» y «Eres el anfitrión. Si sales, la frecu se cierra para las otras <n> personas.» («para la otra persona» con una, «Si sales, la frecu se cierra.» si está solo) con «Cerrar frecu» y «Cancelar»; CUANDO confirma ENTONCES se llama `leaveRoom` y ve la pantalla de cierre: «<nota> · fuera del aire», «Fin de la transmisión», «Cerraste la frecu. Todos los participantes fueron desconectados.», la duración, las personas y la nota, y «Volver al inicio», que lo lleva al inicio.
- AC6: CUANDO la frecu se cierra sin que el usuario salga (`RoomStatus.closed` con un motivo que no es `user_left`) ENTONCES se cierran las hojas abiertas, se llama `leaveRoom` y ve la pantalla de cierre con «El anfitrión cerró la frecu. Puedes unirte a otra cuando quieras.» o, con `host_unreachable`, «Se perdió la señal del anfitrión. Puedes unirte a otra cuando quieras.»; ya no sale el diálogo «La frecu fue cerrada por el anfitrión».
- AC7: CUANDO la app está en inglés ENTONCES las hojas, la pastilla y la pantalla de cierre salen en inglés (p. ej. «Scan to join», «Where do you listen?», «Leave the frecu?», «End of transmission»); CUANDO el sistema pide reducir el movimiento ENTONCES el haz del QR y las barras de la pastilla no se mueven y la línea de la pantalla de cierre queda plana.

## Diseño

Referencia: `SH.invite`, `SH.route`, `SH.leave`, `leaveCopy`, `V.closed` y `roomView` de `screens.js`; `UI.route`, `UI.opt`, `ROUTES` e `ICONS` de `components.js`; `drawQR` y `drawFlat` de `engine.js`; `setRoute` y `openSheet` de `app.js`; `.sheet`, `.route`, `.bars`, `.opt` y `.btn-danger-solid` de `ui.css`; `.ctrls`, `.qr-frame`, `.inv-meta`, `.v-closed` y `.stats` de `screens.css`. Todo con `context.fr`, `FrIcons` y textos de slang; las hojas se abren con `showFrSheet` sobre un `FrSheet` dentro de un `SingleChildScrollView`, como `IpJoinSheet`.

- **Hojas de ruta y salir (`presentation/widgets/room_sheets.dart`)**:
  - `RoomSheetHeader` (`.sh-h`, como `JoinSheetHeader` de C16 sin importar `lobby`): línea superior en `labelS` mayúscula `tx3`, título de 22 y mensaje de 14 en `tx2`, y Cerrar (`FrIcons.close`, compacto) que hace `maybePop`.
  - `AudioRouteSheet` (`ConsumerWidget`, `show(context)`): mira `voiceNotifierProvider` (ruta y `availableAudioRoutes`) y lista tres `AudioRouteOption` separadas 8 (clave `audio_route_option_<ruta>`): rejilla 44 | texto | 24 con relleno 12, radio 18, `bg1` y borde `line1`; ícono `FrIcons.speaker`, `earpiece` o `headset` en un cuadro de 44 con radio 14 sobre `bg2`; título de 15 y subtítulo en `labelS` `tx3`; a la derecha un círculo de 24 con borde `line3`. Marcada: anillo `signal` al 55 % con brillo, ícono en `signalFg` y círculo `signal` con `FrIcons.check` en `signalInk`. Deshabilitada: opacidad 0,45 y sin `onPressed`. Se presiona con `FrPressable` a 0,98. Elegir llama `setAudioRoute` y cierra la hoja (A9).
  - `LeaveSheet` (`show(context, host:, others:)` devuelve si se confirmó): columna centrada con un cuadro de 56 y radio 18 sobre `bg2` con `FrIcons.antenna` (anfitrión) o `FrIcons.exit` en `alert` de 28; título de 22 y mensaje de 14,5 en `tx2` (`leaveCopy`); `FrButton.drawn` `danger` con `FrIcons.exit` («Cerrar frecu» o «Salir de la frecu», clave `leave_confirm`) y `secondary` «Cancelar» (clave `leave_cancel`), a lo ancho.
- **Hoja de invitación (`presentation/widgets/invite_sheet.dart`)**: `InviteSheet` (`show(context, room)`) con `RoomSheetHeader`, `InviteQr` y la ficha:
  - `InviteQr(data)`: marco de 236 con radio 34, relleno 18, fondo `#F4F6F1`, anillo `line2` y brillo de `signal` al 50 %; dentro, `QrImageView` (módulos `circle`, ojos `square`, corrección H, sin relleno) en `#0B0D0F`, el cuadro central de 7,2/29 del lado con radio 2/29 y la firma 2:3 (radio 2,4/29) pintada en `signal`, y el haz de 30 px que baja y sube en 3,2 s (`FrLoop`, `signal` al 35 % en degradado); sin haz con movimiento reducido. `data` es la URI de `BuildInviteQr().buildUri` con la nota de la frecu.
  - Ficha (`.inv-meta`): tres celdas de flex 8 | 9 | 13 separadas por 1 px de `line1`, radio 18, cada una `bg1` con relleno 12 × 14 y 6 de separación: «Nota» con `RoomNoteName` de 26 (o «—»), «Código» en `digits` de 26 (clave `invite_code`) y «Anfitrión» con la IP en `data` y «Puerto <n>» en `labelS`. Debajo, el pie en `bodyS` `tx3` centrado con el nombre de la lista del inicio (`t.lobby.nearbyRooms`).
- **Pantalla de cierre (`presentation/widgets/room_closed_view.dart`)**:
  - `RoomClosure { kind (hostClosed, closedByHost, lostHost), duration, people, note }` y `formatClosureDuration` («mm:ss», o «h:mm:ss» desde una hora).
  - `RoomClosedView(closure, onHome)`: `FrScaffold` con dock (`FrButton` primario «Volver al inicio», clave `closure_home`) y cuerpo desplazable: la línea plana (alto 300, 40 arriba) con `ClosureLinePainter` como `drawFlat` (la firma de «frecu» se aplana en 2,4 s de cada ciclo de 6 s y desde los 3 s la recorre un pulso, trazo `tx2` al 70 % de 1,6 y marcas `ink` al 12 % cada 22 px; plana y quieta con movimiento reducido); el texto centrado con 12 de separación (línea `label` mayúscula `tx3` «Mi4 · fuera del aire», título de 30 como `.h-screen` y mensaje de 15,5 en `tx2` de hasta 300 px); y, 30 más abajo, las estadísticas en tres celdas como la ficha: «Duración» y «Personas» en `digits` de 24 (claves `closure_duration` y `closure_people`) y «Nota».
- **Cabecera (`room_header.dart`)**: sin `audioRoute` ni `onCycleAudioRoute`; Invitar pasa a `FrIconButton.drawn` con `FrIcons.qr` (clave `invite_button`) junto a Salir (P74). `_NoteName` pasa a `RoomNoteName` pública con su tamaño, para la ficha y el cierre.
- **Controles (`mic_control_section.dart`)**: recibe `onRoute`; la fila de 52 con relleno horizontal 20 reparte la pastilla a la izquierda y el selector (flex, hasta 204) a la derecha con 10 de separación (P107). `AudioRoutePill` (en el mismo archivo, clave `audio_route_button`): alto 48, relleno 10 | 12, radio 16, `bg1` con borde `line1` y filo `spec`; `FrIcon` de la ruta de 18, el nombre (`t.room.speaker`, `earpiece` o `bluetooth`) de 13,5 y peso 600, tres barras de 3 × 14 en `signalFg` que suben y bajan (900, 700 y 1100 ms) mientras `talk.speaker` no es nulo y quedan al 30 % en `tx4` si no, y `FrIcons.down` de 16 en `tx3`; se presiona a 0,96 y abre la hoja de ruta.
- **Página (`room_page.dart`)**: abre `InviteSheet` (cabecera y lugares libres), `AudioRouteSheet` (pastilla) y `LeaveSheet` (Salir, con `host` si la persona propia es anfitriona y `others` = personas en la malla − 1). Guarda el mayor número de personas en la malla. Confirmar sin ser anfitrión: `leaveRoom` y `maybePop`. Confirmar como anfitrión, o recibir `RoomStatus.closed` con otro motivo que `user_left`: cierra las hojas abiertas (`popUntil` de las `PopupRoute`), guarda el `RoomClosure` (duración desde `room.createdAt`), llama `leaveRoom` y cambia a `RoomClosedView` con un `AnimatedSwitcher` de fundido; «Volver al inicio» hace `maybePop`. Sin el diálogo de cierre, `InviteQrDialog` ni `cycleAudioRoute`.
- **Textos (`lib/i18n`)**: `room.sheets` (`close`, `invite` con `kicker`, `title`, `message`, `note`, `code`, `host`, `port` con `$port` y `footer` con `$list`; `route` con `kicker`, `title`, `message`, `speakerSub`, `earpieceSub`, `bluetoothOn`, `bluetoothOff` y `label` con `$route`; `leave` con `peerTitle`, `peerMessage`, `peerConfirm`, `hostTitle`, `hostAlone`, `hostOne`, `hostMany` con `$count`, `hostConfirm` y `cancel`) y `room.closure` (`offAir`, `noteOffAir` con `$note`, `title`, `host`, `peer`, `lost`, `duration`, `people`, `note`, `home`), en `es` y `en`; salen `room.roomClosed` y `room.accept`. Se regenera con `dart run slang`.
- **Pruebas**: `room_sheets_test.dart` (grupos «Invitar», «Ruta de audio» y «Salir») y `room_closure_test.dart` prueban la página dentro de `FrecuApp` con repositorios simulados y movimiento reducido; inglés con `tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en))`. `invite_qr_dialog_test.dart`, `room_note_flow_test.dart`, `voice_flow_test.dart` y `room_flow_test.dart` cambian solo las búsquedas del diálogo QR, el ícono de Material, el botón de ruta, la salida y el diálogo de cierre.

## Archivos

- crear lib/features/room/presentation/widgets/room_sheets.dart — encabezado de las hojas de la frecu, hoja de ruta de audio con sus opciones y hoja para salir o cerrar la frecu.
- crear lib/features/room/presentation/widgets/invite_sheet.dart — hoja de invitación con el QR de módulos redondos, el haz y la ficha de nota, código y anfitrión.
- crear lib/features/room/presentation/widgets/room_closed_view.dart — pantalla «Fin de la transmisión» con la línea plana, el texto de cada cierre y las estadísticas.
- modificar lib/features/room/presentation/widgets/room_header.dart — Invitar con `FrIcons.qr`, sin botón de ruta, y `RoomNoteName` pública.
- modificar lib/features/room/presentation/widgets/mic_control_section.dart — pastilla de ruta a la izquierda del selector.
- modificar lib/features/room/presentation/pages/room_page.dart — abrir las tres hojas, salir y cerrar, y la pantalla de cierre en lugar del diálogo.
- borrar lib/features/room/presentation/widgets/invite_qr_dialog.dart — la invitación pasa a la hoja.
- modificar lib/i18n/strings.i18n.json — textos de las hojas y del cierre en español.
- modificar lib/i18n/strings_en.i18n.json — los mismos textos en inglés.
- modificar lib/i18n/strings.g.dart — traducciones generadas por slang.
- modificar lib/i18n/strings_es.g.dart — traducciones generadas por slang en español.
- modificar lib/i18n/strings_en.g.dart — traducciones generadas por slang en inglés.
- crear test/features/room/presentation/room_sheets_test.dart — hojas de invitación, ruta y salir, cabecera, pastilla e inglés.
- crear test/features/room/presentation/room_closure_test.dart — cierre por el anfitrión, cierre recibido, señal perdida, estadísticas, volver al inicio e inglés.
- modificar test/features/room/presentation/invite_qr_dialog_test.dart — Invitar abre la hoja con el QR.
- modificar test/features/lobby/presentation/room_note_flow_test.dart — Invitar con su clave y la URI del QR de la hoja.
- modificar test/features/room/presentation/voice_flow_test.dart — pastilla y hoja de ruta en lugar del botón de la cabecera.
- modificar test/features/room/presentation/room_flow_test.dart — Invitar desde un lugar libre, salir con la hoja y la pantalla de cierre.

## Tareas

- [x] T1: Hoja de invitación e Invitar con ícono propio
  - files: lib/features/room/presentation/widgets/room_sheets.dart, lib/features/room/presentation/widgets/invite_sheet.dart, lib/features/room/presentation/widgets/room_header.dart, lib/features/room/presentation/pages/room_page.dart, lib/features/room/presentation/widgets/invite_qr_dialog.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/room/presentation/room_sheets_test.dart, test/features/room/presentation/invite_qr_dialog_test.dart, test/features/lobby/presentation/room_note_flow_test.dart
  - ac: AC1, AC2, AC7
  - verify: flutter test test/features/room/presentation/room_sheets_test.dart --name Invitar && flutter test test/features/room/presentation/invite_qr_dialog_test.dart test/features/lobby/presentation/room_note_flow_test.dart
- [x] T2: Pastilla y hoja de ruta de audio
  - files: lib/features/room/presentation/widgets/room_sheets.dart, lib/features/room/presentation/widgets/mic_control_section.dart, lib/features/room/presentation/widgets/room_header.dart, lib/features/room/presentation/pages/room_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/room/presentation/room_sheets_test.dart, test/features/room/presentation/voice_flow_test.dart
  - ac: AC2, AC3, AC7
  - verify: flutter test test/features/room/presentation/room_sheets_test.dart --name "Ruta de audio" && flutter test test/features/room/presentation/voice_flow_test.dart test/features/room/presentation/talk_flow_test.dart
- [x] T3: Hoja de salir y pantalla de cierre
  - files: lib/features/room/presentation/widgets/room_sheets.dart, lib/features/room/presentation/widgets/room_closed_view.dart, lib/features/room/presentation/pages/room_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/room/presentation/room_sheets_test.dart, test/features/room/presentation/room_closure_test.dart, test/features/room/presentation/room_flow_test.dart
  - ac: AC4, AC5, AC6, AC7
  - verify: flutter analyze && flutter test

## Riesgos

- R1: El QR con un cuadro al centro puede no leerse con IDs largos — mitigación: corrección H (hasta 30 %), el cuadro tapa menos del 7 % del área y la URI es la misma que ya lee `ParseInviteFromQr`.
- R2: `room_page.dart` crece con las hojas y el cierre — mitigación: las hojas y la vista de cierre viven en sus archivos y la página solo las abre; cada función por debajo de 50 líneas.
- R3: Las pruebas de otros cortes buscan el diálogo, el botón de ruta y los íconos de Material — mitigación: solo cambian esas búsquedas, con claves estables (`invite_button`, `audio_route_button`, `leave_button`).

## Cierre

### Resumen

- `invite_sheet.dart`: `InviteSheet` con `RoomSheetHeader`, `InviteQr` (marco claro `#F4F6F1` en los dos temas, `QrImageView` de módulos redondos en tinta con corrección H, la firma 2:3 de Frecu sobre un cuadro de tinta al centro y el haz de 3,2 s, quieto con movimiento reducido) y la ficha `RoomFacts` de nota (o «—»), código y anfitrión con su puerto, y el pie con «Frecus cercanas». Se abre desde Invitar de la cabecera y desde los lugares libres; `InviteQrDialog` se borró.
- `room_sheets.dart`: `RoomSheetHeader`, `AudioRouteSheet` con `AudioRouteOption` (ruta activa marcada, las que no están en `availableAudioRoutes` al 45 % y sin respuesta; elegir llama `setAudioRoute` y cierra) y `LeaveSheet` (texto de quien no es anfitrión, o del anfitrión con las otras n personas, la otra persona o solo).
- `mic_control_section.dart`: `AudioRoutePill` a la izquierda del selector de hasta 204 px (P107/P103), con ícono `FrIcons`, nombre, barras que se mueven mientras llega audio y flecha; abre la hoja de ruta.
- `room_header.dart`: Invitar con `FrIcons.qr` y Salir, sin íconos de Material ni botón de ruta (P74); `RoomNoteName` pública con su tamaño.
- `room_closed_view.dart`: `RoomClosure`, `formatClosureDuration` y `RoomClosedView` con la línea que se aplana (`ClosureLinePainter`, plana con movimiento reducido), la nota fuera del aire, «Fin de la transmisión», el mensaje de cada cierre, duración, personas y nota, y «Volver al inicio».
- `room_page.dart`: abre las tres hojas; salir sin ser anfitrión llama `leaveRoom` y vuelve al inicio; cerrar como anfitrión o recibir `RoomStatus.closed` (salvo `user_left`) cierra las hojas, guarda el resumen, llama `leaveRoom` y cambia con un fundido a la pantalla de cierre. Sin el diálogo de cierre.
- Textos `room.sheets.*` y `room.closure.*` en es y en; salen `room.roomClosed` y `room.accept`.
- Verificado: `flutter analyze` sin avisos y `flutter test` completo en verde (582 pruebas).

### Desviaciones

- La ficha de la invitación y las estadísticas del cierre comparten `RoomFacts` y `RoomFact` (en `invite_sheet.dart`), para que ninguna función pase de 50 líneas.
- `room.sheets.invite.qr` se suma a las claves del diseño: es la etiqueta accesible del QR.
- La hoja de salir y la de ruta quedaron completas en T1, porque `room_sheets_test.dart` las nombra y debe compilar desde la primera tarea; T2 y T3 solo las conectan a la página.
- `voice_flow_test.dart` y `room_flow_test.dart` además buscan `AudioRouteSheet` y `RoomClosedView`, para que la verificación las nombre al fallar sin el código en la fase de tests.

### Decisiones

- La pantalla de cierre es una vista de `RoomPage` con `AnimatedSwitcher`, no una ruta (A1).
- La duración va de `Room.createdAt` al cierre y «Personas» es el mayor número de personas que hubo a la vez en la malla (A4).
- Las barras de la pastilla se mueven solo mientras otra persona habla; quietas en `tx4` en reposo o con movimiento reducido (A6).
- El botón de cerrar o salir usa `FrButton` `danger` (lavado de alerta) en lugar de la variante sólida del prototipo (A7).
- `Key('sheet_close')`, `invite_button`, `audio_route_button`, `audio_route_option_<ruta>`, `leave_confirm`, `leave_cancel`, `closure_home`, `closure_duration` y `closure_people` quedan como claves estables para las pruebas.

### Pendientes

- `FrButton` no tiene la variante sólida `danger-solid` del prototipo: la hoja de salir usa `danger` (lavado de alerta); sumarla en `lib/core/design/widgets/fr_button.dart` y usarla en `LeaveSheet`.
- El QR de la invitación usa ojos cuadrados porque `qr_flutter` 4.1 no tiene ojos de esquina suave como `drawQR`; dibujarlos con un pintor propio sobre `QrCode` si se quiere igual al prototipo.
- La hoja de ruta dice «Bluetooth» sin el nombre del dispositivo, porque `AudioRoute.bluetooth` no lo trae; sumarlo en la plataforma y en `VoiceState` para mostrar p. ej. «Sena 50S».
- `room_sheets.dart` tiene 350 líneas de código (aviso desde 300): si crece, pasar `AudioRouteSheet` y `LeaveSheet` a sus propios archivos.
