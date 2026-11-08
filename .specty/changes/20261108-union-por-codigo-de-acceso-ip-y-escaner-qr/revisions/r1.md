---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C16
---

# Unión por código de acceso, IP y escáner QR

## Objetivo

Rehacer las tres formas de unirse a una frecu con el sistema Portadora, como en el prototipo aprobado (`docs/diseno/prototipo/screens.js`, hojas `SH.pin` y `SH.ip` y pantalla `scan`): la hoja de código de acceso con celdas de matriz de puntos, teclado propio y envío automático al cuarto dígito; la hoja de conexión manual por IP; y el escáner QR en tema oscuro con la retícula que respira, el haz que barre y el cierre sobre el código con la tarjeta «Frecu encontrada». Cubre la parte de unión de AC6 de la épica. Hoy son dos `AlertDialog` de Material con textos directos («Unirse», «Cancelar», «IP del anfitrión») y un escáner con `AppBar` que se une sin confirmar.

## Fuera de alcance

- Transición de expansión de la hoja a la frecu activa y transiciones del router (P53): al unirse se abre la frecu activa como hoy.
- El nombre de la frecu en el QR: tocaría `features/room` (`BuildInviteQr`) y el protocolo.
- Cambios en `lib/core/design`: `FrField` y `FrBanner` solo admiten `IconData` de Material; queda anotado.
- Estado sin cámara del escáner (permiso negado o cámara ocupada): sigue el error por defecto de `mobile_scanner`; queda anotado.
- Nueva frecu, guía del punto de acceso (C17) y la hoja de invitación (C19).
- Cambios en el dominio, en `features/room` y en `ParseInviteFromQr`.

## Supuestos

- A1: El QR no trae el nombre de la frecu (`frecu://join?h&p&r&c&n`), así que la tarjeta del escáner lleva como título la nota y sus Hz («Mi4 · 329,6 Hz») o «Frecu sin nota», y debajo la IP y el puerto.
  - impacto: alto
- A2: Como en el prototipo, leer una invitación no une sola: la retícula se cierra sobre el código y aparece la tarjeta con Unirme; la unión empieza al tocarlo. Antes se unía al escanear, así que las pruebas que escanean pasan a tocar Unirme.
  - impacto: alto
- A3: La hoja de código empieza vacía y se envía sola con el cuarto dígito, sin botón; la de IP empieza con los campos vacíos («192.168.43.1» solo de ejemplo). Los diálogos de hoy traen «192.168.43.1» y «1234» ya escritos y las pruebas que se apoyan en eso pasan a escribirlos.
  - impacto: alto
- A4: Mientras se verifica el código o se conecta, la hoja no se cierra (ni con el velo ni con volver) y el escáner no vuelve atrás, para no quedar unido a una frecu sin abrirla.
- A5: Al cerrar la hoja de código la frecu sigue elegida en el inicio, como dejó C15 (el prototipo la suelta).
- A6: Los avisos de error usan el mensaje de `Failure` que ya existe (`errors.roomFull`, `errors.hostUnreachable`…) como título y suman una pista: «Podrás entrar cuando alguien salga.» si está llena y «Revisa que estés en su misma red Wi-Fi.» si el anfitrión no responde. Llena va en ámbar y lo demás en alerta.
- A7: Las pruebas que abren el escáner pasan a movimiento reducido, porque la retícula y el haz no paran solos y `pumpAndSettle` no terminaría; las que unen escriben el código con el teclado propio.
  - impacto: alto

## Criterios de aceptación

- AC1: CUANDO el usuario toca una frecu cercana ENTONCES se abre la hoja de código (`FrSheet`) con «<nota> · <Hz> · <IP>» (solo la IP si la frecu no tiene nota), el nombre de la frecu, «Ingresa el código de acceso. Pídeselo al anfitrión.», el botón Cerrar, el código de 4 celdas vacío, «Se envía al completar los 4 dígitos», el teclado propio y «Entrarás como <nombre guardado>»; cada tecla escribe su dígito en la celda siguiente y Borrar quita el último.
- AC2: CUANDO se escribe el cuarto dígito ENTONCES el código se envía solo a la IP y el puerto de la frecu con el nombre guardado y la nota de la frecu, las celdas pasan a verificando con «Verificando con el anfitrión…» y el teclado no responde; CUANDO el anfitrión lo acepta ENTONCES la hoja se cierra y se abre la frecu activa.
- AC3: CUANDO el anfitrión rechaza el código ENTONCES las celdas pasan a error con «Código incorrecto. Revisa e intenta otra vez.» y la siguiente tecla empieza un código nuevo; CUANDO la frecu está llena ENTONCES se ve un aviso ámbar «La frecu está llena (máximo 6 participantes)» con «Podrás entrar cuando alguien salga.»; CUANDO falla por otro motivo ENTONCES un aviso de alerta con su mensaje; en esos dos casos las celdas quedan vacías para reintentar.
- AC4: CUANDO el usuario toca Conectar por IP ENTONCES se abre la hoja «Conexión manual», «Conectar por IP», «Úsalo si la frecu no aparece en la lista.» con los campos «IP del anfitrión» (con «Puerto 47800» debajo) y «Código de acceso» (4 dígitos), y Conectar solo responde con una IP y 4 dígitos; al tocarlo se une a esa IP en el puerto 47800 con ese código y el nombre guardado, sin nota; CUANDO el anfitrión acepta ENTONCES la hoja se cierra y se abre la frecu activa.
- AC5: CUANDO el anfitrión no responde a la conexión por IP ENTONCES el campo de IP pasa a error con «Sin respuesta en el puerto 47800» y se ve un aviso de alerta «El anfitrión no responde» con «Revisa que estés en su misma red Wi-Fi.»; CUANDO el código es incorrecto ENTONCES el campo del código pasa a error con «Código incorrecto. Revisa e intenta otra vez.»; CUANDO la frecu está llena ENTONCES el aviso ámbar de AC3; CUANDO el usuario edita un campo ENTONCES el error se quita.
- AC6: CUANDO se abre el escáner ENTONCES se ve en tema oscuro la cámara bajo la retícula, arriba Atrás, «Escanear invitación», «QR de la frecu» y Linterna, que se enciende y se apaga, y abajo «Apunta al QR que muestra el anfitrión en su teléfono.» y Conectar por IP, que abre la hoja de AC4 y, al unirse, la frecu activa; CUANDO lee un QR que no es una invitación ENTONCES dice «Este QR no es una invitación de Frecu.» y sigue buscando.
- AC7: CUANDO el escáner lee una invitación válida ENTONCES la retícula se cierra sobre el código con el check y abajo aparece la tarjeta «Frecu encontrada» con la nota y sus Hz (o «Frecu sin nota») y «<IP> · Puerto <p>» y el botón Unirme, y no atiende otros QR; CUANDO el usuario toca Unirme ENTONCES se une con la IP, el puerto, el código y la nota del QR y el nombre guardado y se abre la frecu activa en lugar del escáner; CUANDO falla ENTONCES se ve el aviso del error sobre la tarjeta y Unirme reintenta.
- AC8: CUANDO la app está en inglés ENTONCES las hojas y el escáner muestran sus textos de la traducción `en`; CUANDO el sistema pide reducir el movimiento ENTONCES la retícula no respira, el haz queda quieto y el escáner no pide cuadros, sin ocultar el cierre sobre el código.

## Diseño

Referencia: `SH.pin`, `SH.ip` y `V.scan` de `screens.js`; `pinKey`, `renderPin`, `lockScan` y `data-join` de `app.js`; `UI.pin`, `UI.keypad`, `UI.field` y `UI.banner` de `components.js`; `.sheet`, `.pin`, `.keys` y `.field` de `ui.css`; y `.pin-msg`, `.reticle`, `.scan-top`, `.scan-bottom` y `.scan-card` de `screens.css`. Todo con `context.fr`, sin colores sueltos ni texto directo.

- **Partes comunes** (en `widgets/pin_join_sheet.dart`, que también usa la hoja de IP): `JoinSheetHeader` (`.sh-h`): a la izquierda la línea superior en `labelS`, `tx3` y mayúsculas, a 8 px el título en `titleL` y a 6 px el mensaje en `body` y `tx2`; a la derecha `FrIconButton.drawn(FrIcons.close, compact)` con `join.close`, deshabilitado mientras se une. `JoinFailureBanner(failure)`: `FrBanner` sin cierre con `failure.toLocalizedMessage()` de título; `roomFull` en `warn` (`Icons.group_outlined`) con `join.roomFullHint`, `hostUnreachable` en `alert` (`Icons.error_outline_rounded`) con `join.unreachableHint`, y el resto en `alert` sin mensaje.
- **`PinJoinSheet`** (`widgets/pin_join_sheet.dart`, `ConsumerStatefulWidget`): `static Future<Room?> show(context, NearbyRoom)` con `showFrSheet<Room>`; la hoja va en un `SingleChildScrollView` por si no cabe. `FrSheet` con `JoinSheetHeader` (`note.label · note.hzText · IP`, nombre, `join.pin.message`), `FrPinField` centrado (`lobby.accessCode` de etiqueta), la línea de estado o el aviso, `FrKeypad` (`join.pin.delete`, `FrIcon(FrIcons.backspace)`) y «Entrarás como» con el nombre en `tx1` (`labelS`, `tx3`). Estado: dígitos, `FrPinState` y la falla de aviso. Una tecla con error o aviso empieza un código nuevo; con 4 dígitos pasa a `busy` y llama a `roomNotifierProvider.notifier.joinRoom(hostAddress, port, accessCode, displayName: ref.joinDisplayName, note)`. Éxito: `ok` y `Navigator.pop(room)`. `invalidAccessCode`: `error` con `join.wrongCode` en `alert`. Otra falla: celdas vacías y `JoinFailureBanner`. La línea de estado (13 px, centrada) dice `join.pin.autoSend` en `tx3`, `join.pin.checking` en `tx3`, `join.wrongCode` en `alert` o `join.pin.correct` en `signalFg`. `PopScope(canPop: no busy)`.
- **`IpJoinSheet`** (`widgets/ip_join_sheet.dart`): `static Future<Room?> show(context)`. `JoinSheetHeader` (`join.ip.kicker`, `lobby.joinRoom`, `join.ip.message`); `FrField` de IP (`join.ip.host`, `mono`, `Icons.hub_outlined`, ejemplo `192.168.43.1`, ayuda `join.port(47800)`, error `join.ip.noAnswer(47800)` si no responde, `autofocus`, teclado `url`, acción siguiente); `FrField` del código (`lobby.accessCode`, `mono`, `Icons.lock_outline_rounded`, `maxLength` 4, teclado numérico, error `join.wrongCode`); el aviso para las demás fallas (y para `hostUnreachable`); y `FrButton.drawn(join.ip.connect, FrIcons.arrow, expand)` con `loading` mientras conecta y `onPressed` solo con IP no vacía y 4 dígitos. Une a `NetworkConstants.signalingPort` sin nota; éxito: `pop(room)`; editar un campo quita la falla. `PopScope(canPop: no conectando)`.
- **`LobbyPage`**: tocar una frecu la elige y abre `PinJoinSheet`; Conectar por IP abre `IpJoinSheet`; con una frecu de vuelta hace `push(RoomRoute(roomId))`. Se quitan `_PinJoinDialog` y `_JoinRoomDialog`.
- **`ScanQrPage`** (`pages/scan_qr_page.dart`, `@RoutePage()`, conserva `scannerBuilder`): `Theme(AppTheme.dark)` sobre negro y `PopScope(canPop: no uniendo)`. `Stack`: la cámara (`MobileScanner` con un `MobileScannerController` propio, solo si no hay `scannerBuilder`), `ScanReticle(locked)`, arriba `ScanTopBar` y abajo `ScanBottom`. Estado: la invitación leída, si el último QR no era invitación, si está uniendo, la falla y la linterna. Lee con `ParseInviteFromQr`; si no es invitación marca el aviso; si lo es, la guarda, deja de atender QR y hace `HapticFeedback.lightImpact()`. Unirme llama a `joinRoom` con los datos y la nota del QR; éxito: `context.router.replace(RoomRoute)` (sin router, como hoy, no navega); falla: la guarda. Conectar por IP abre `IpJoinSheet` y, con una frecu, hace `replace(RoomRoute)`. La linterna cambia su estado y llama a `toggleTorch()` del controlador si lo hay.
- **`ScanReticle`** (`widgets/scan_reticle.dart`): `CustomPainter` a pantalla completa con el centro al 39 % del alto: velo `rgba(2,3,4,.62)` alrededor de un hueco redondeado de 250 px y radio 36, cuatro esquinas en L de 46 px y 3 px en `tx1` que respiran (escala 1,04 a mitad de 2,8 s) y el haz de 2 px (degradado de `signalFg` con brillo de `signal`) que va del 10 % al 88 % y vuelve en 2,4 s; el tiempo sale de un `FrLoop`. Cerrada (`locked`), el hueco pasa a 196 px y radio 26 con el resorte `organic` (700 ms), las esquinas a `signalFg` con brillo, sin haz ni respiración, y aparece al centro el check (64 px, `signal`, `FrIcons.check` en `signalInk`, brillo) con el resorte. Con movimiento reducido o cerrada no hay `FrLoop`; con movimiento reducido el haz queda al medio y el cierre es un fundido corto.
- **`ScanTopBar`, `ScanBottom` y `ScanFoundCard`** (en `pages/scan_qr_page.dart`): barra de 60 px (relleno 16) con `FrIconButton.drawn(FrIcons.back)` (`join.scan.back`), título `join.scan.title` (Archivo 640 a 16 px) y `join.scan.subtitle` en `labelS`, `tx3` y mayúsculas, y `FrIconButton.drawn(FrIcons.flash, selected)` (`join.scan.torch`). Abajo (20 px a los lados, 34 sobre el borde seguro, separación 14): sin invitación, `join.scan.hint` (15 px, `tx2`, ancho 300) o `join.scan.invalid` en `alert`, y `FrButton.drawn(lobby.joinRoom, secondary, small, FrIcons.nodes)`; con invitación, el aviso si falló y la tarjeta (relleno 16, radio 24, `bg2` al 92 %, borde `line2`, sube con el resorte `flow`): `join.scan.found` en `labelS`, `signalFg` y mayúsculas, el título (Archivo 660 a 18 px), `IP · join.port(p)` en `labelS` y `tx3`, y `FrButton(join.scan.join, small, loading)`.
- **Textos** (`lib/i18n`, `es` y `en`, todos en `lobby.join`): `close`, `port` (`$port`), `wrongCode`, `roomFullHint`, `unreachableHint`, `pin.message`, `pin.autoSend`, `pin.checking`, `pin.correct`, `pin.delete`, `pin.joiningAs`, `ip.kicker`, `ip.message`, `ip.host`, `ip.noAnswer` (`$port`), `ip.connect`, `scan.title`, `scan.subtitle`, `scan.back`, `scan.torch`, `scan.hint`, `scan.invalid`, `scan.found`, `scan.noNote` y `scan.join`. Se regenera con `dart run slang`.
- **Pruebas**: `join_sheets_test` (grupos `PinJoinSheet` e `IpJoinSheet`) y `scan_qr_page_test` montan `FrecuApp` en 390 × 844 con movimiento reducido (salvo la prueba que mira los cuadros), un router de prueba que cambia la frecu activa por un sustituto y el escáner por `ScanQrPage` con `scannerBuilder`, y dobles de descubrimiento, red y sala; el nombre se guarda con `InMemorySharedPreferencesAsync`; el inglés se carga con `tester.runAsync`. Las pruebas existentes que usan los diálogos o el escáner escriben el código con el teclado, llenan los campos de IP y tocan Unirme.

## Archivos

- crear lib/features/lobby/presentation/widgets/pin_join_sheet.dart — hoja de código de acceso con teclado propio y envío automático, y el encabezado y el aviso de error de las hojas de unión.
- crear lib/features/lobby/presentation/widgets/ip_join_sheet.dart — hoja de conexión manual por IP.
- crear lib/features/lobby/presentation/widgets/scan_reticle.dart — retícula del escáner con velo, esquinas, haz y cierre.
- modificar lib/features/lobby/presentation/pages/lobby_page.dart — abrir las hojas de código e IP en lugar de los diálogos.
- modificar lib/features/lobby/presentation/pages/scan_qr_page.dart — escáner en Portadora: barra con linterna, indicación, tarjeta «Frecu encontrada» y Unirme.
- modificar lib/i18n/strings.i18n.json — textos de unión en español.
- modificar lib/i18n/strings_en.i18n.json — textos de unión en inglés.
- modificar lib/i18n/strings.g.dart — traducciones generadas por slang.
- modificar lib/i18n/strings_es.g.dart — traducciones generadas por slang en español.
- modificar lib/i18n/strings_en.g.dart — traducciones generadas por slang en inglés.
- crear test/features/lobby/presentation/join_sheets_test.dart — hojas de código y de IP: contenido, teclado, validación, unión, errores e inglés.
- modificar test/features/lobby/presentation/scan_qr_page_test.dart — escáner: contenido, linterna, QR inválido, cierre, Unirme, errores, IP, inglés y movimiento reducido.
- modificar test/features/lobby/presentation/lobby_page_test.dart — Conectar por IP abre la hoja y la frecu se une escribiendo el código.
- modificar test/features/lobby/presentation/discovery_flow_test.dart — unirse escribiendo el código en la hoja.
- modificar test/features/lobby/presentation/room_full_flow_test.dart — unirse escribiendo el código en la hoja.
- modificar test/features/lobby/presentation/room_note_flow_test.dart — código con el teclado, campos de IP, movimiento reducido y Unirme en el escáner.
- modificar test/features/lobby/presentation/saved_name_test.dart — hojas en lugar de diálogos, campos de IP y Unirme en el escáner.
- modificar test/features/room/presentation/room_flow_test.dart — campos de IP y Conectar de la hoja.

## Tareas

- [ ] T1: Hoja de código de acceso desde la lista de frecus
  - files: lib/features/lobby/presentation/widgets/pin_join_sheet.dart, lib/features/lobby/presentation/pages/lobby_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/join_sheets_test.dart
  - ac: AC1, AC2, AC3, AC8
  - verify: flutter test test/features/lobby/presentation/join_sheets_test.dart --name PinJoinSheet
- [ ] T2: Hoja de conexión manual por IP
  - files: lib/features/lobby/presentation/widgets/ip_join_sheet.dart, lib/features/lobby/presentation/widgets/pin_join_sheet.dart, lib/features/lobby/presentation/pages/lobby_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/join_sheets_test.dart
  - ac: AC4, AC5, AC8
  - verify: flutter test test/features/lobby/presentation/join_sheets_test.dart
- [ ] T3: Escáner QR con retícula, tarjeta y Unirme, y pruebas existentes con la unión nueva
  - files: lib/features/lobby/presentation/pages/scan_qr_page.dart, lib/features/lobby/presentation/widgets/scan_reticle.dart, lib/features/lobby/presentation/widgets/ip_join_sheet.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/scan_qr_page_test.dart, test/features/lobby/presentation/lobby_page_test.dart, test/features/lobby/presentation/discovery_flow_test.dart, test/features/lobby/presentation/room_full_flow_test.dart, test/features/lobby/presentation/room_note_flow_test.dart, test/features/lobby/presentation/saved_name_test.dart, test/features/room/presentation/room_flow_test.dart
  - ac: AC6, AC7, AC8
  - verify: flutter test && flutter analyze

## Riesgos

- R1: C17 corre en paralelo y también toca `features/lobby` y los textos — mitigación: los textos van en `lobby.join`, los archivos nuevos no se cruzan con los suyos y, si chocan los generados, se regeneran con `dart run slang`.
- R2: La hoja de código con el teclado mide unos 600 px y no cabe en pantallas bajas — mitigación: va dentro de un `SingleChildScrollView` que se encoge a su contenido.
- R3: La retícula repinta a 60 fps sobre la cámara — mitigación: un solo `FrLoop` en un `RepaintBoundary`, que se quita al cerrarse sobre el código y con movimiento reducido.
