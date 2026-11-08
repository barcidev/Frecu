---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C17
---

# Nueva frecu con reloj de quintas y guía de punto de acceso

## Objetivo

Rehacer la creación de una frecu con el sistema Portadora, como las pantallas `hotspot` y `create` del prototipo aprobado (`docs/diseno/prototipo/screens.js`): Crear frecu abre primero la guía del punto de acceso (paso 1 de 2, con pasos para Android y para iPhone) y luego la nueva frecu (paso 2 de 2), donde el reloj del círculo de quintas muestra la hora y la nota que tendrá la frecu con sus Hz, el nombre y un código de acceso generado que se puede cambiar. Cubre la parte de crear de AC4 y AC6 de la épica y P65 (pasar las notas cercanas y recalcular la nota mientras se descubren). Hoy la pantalla es un formulario Material con nombre «Frecu» y código «1234» fijos, sin nota ni guía.

## Fuera de alcance

- Fila «Guía del punto de acceso» en Ajustes (P62): es de `features/settings`.
- Abrir los ajustes de zona Wi-Fi del sistema o detectar que el punto de acceso ya está activo para saltar la guía: necesitan un plugin.
- Transiciones del router (onda al abrir la frecu, P53); entre los dos pasos sí se usa el deslizamiento de `FrPageRoute`.
- Cambios en `features/room` (`RoomNotifier.createRoom` ya asigna la nota con `AssignRoomNote` y las notas cercanas), en `lib/app` y en `lib/core/design`.
- Unificar `lobby.noteNames` con `room.noteNames` (P84/P87): aquí se reutiliza `lobby.noteNames` por `RoomNoteLabels`.
- Hojas de unión por código, IP y QR (C16).

## Supuestos

- A1: La guía y la nueva frecu son dos pasos de la misma ruta `CreateRoomRoute`, en un `Navigator` anidado como el recorrido de `PermissionsPage` (C12), para no tocar `lib/app/router` (sería un tercer módulo). Crear frecu siempre abre la guía, aunque ya haya red.
  - impacto: alto
- A2: La hora sale de un reloj inyectable (`newRoomClockProvider`, por defecto `DateTime.now`) que la pantalla relee cada 15 s; la nota mostrada es `AssignRoomNote().assign(createdAt: ahora, nearbyNotes: notas de las frecus cercanas)` y se recalcula al cambiar la hora o la lista. La frecu creada calcula su nota con su `createdAt` en `RoomNotifier` (C14), que coincide con la mostrada salvo si cambia la hora entre mirar y abrir.
  - impacto: alto
- A3: El reloj enciende el sector y la etiqueta de la nota asignada (`fifthsPosition`), que es la de la hora salvo si una frecu cercana ya la usa; la aguja de la hora sigue marcando la hora real.
- A4: El nombre viene escrito como «Frecu de <nombre guardado>» o «Mi frecu» si aún no hay nombre guardado, con máximo 24 caracteres; con el nombre vacío o solo espacios, «Abrir frecu» queda deshabilitado.
- A5: El código de acceso es aleatorio de 1000 a 9999 (`Random.secure`) desde un generador inyectable (`accessCodeGeneratorProvider`); no se escribe a mano: se cambia con «Generar otro». Nombre y código se conservan al volver a la guía.
  - impacto: alto
- A6: La IP local que muestra la pantalla de hoy desaparece: el prototipo no la muestra al crear y la invitación de la frecu activa la lleva (C19).
- A7: El selector de la guía empieza en iPhone si la plataforma del tema es iOS y en Android en lo demás; es solo informativo y no se guarda.
- A8: Las pruebas de otros cortes que crean una frecu (`room_flow_test`, `room_note_flow_test`, `saved_name_test`) solo cambian su recorrido de creación: tocar «Ya está activo» y luego «Abrir frecu» en lugar del botón Material de hoy, y aceptar el código generado.
  - impacto: alto

## Criterios de aceptación

- AC1: CUANDO el usuario toca Crear frecu en el inicio ENTONCES se abre la guía en Portadora (`FrScaffold`) con Atrás, «Paso 1 de 2» y «Prepara la red», la ilustración del teléfono emisor, «Activa tu punto de acceso», «Tu teléfono será la antena del grupo.», el selector Android | iPhone y los tres pasos de la plataforma elegida numerados 01 a 03 con su inicio en negrita, y abajo «Ya está activo» y «Ya estamos en la misma Wi-Fi»; el selector empieza en iPhone en iOS y en Android en lo demás, y elegir la otra plataforma cambia los pasos; todos los textos salen de slang en español y en inglés.
- AC2: CUANDO el usuario toca «Ya está activo» o «Ya estamos en la misma Wi-Fi» ENTONCES pasa a la nueva frecu con «Paso 2 de 2» y «Nueva frecu»; Atrás en la nueva frecu vuelve a la guía y, al volver a entrar, conserva el nombre y el código; Atrás en la guía vuelve al inicio.
- AC3: CUANDO se ve la nueva frecu ENTONCES el reloj de quintas recibe la hora y los minutos actuales y la nota de la frecu, y a su lado se lee «Tu frecu suena en», la nota (nombre en el idioma de la app, alteración y octava), sus Hz con un decimal y el separador del idioma («659,3 Hz», «659.3 Hz») y «Abierta a las HH:MM»; la nota es la de su hora en el círculo de quintas (octava 4 de 0 a 11 h y 5 de 12 a 23 h) y, CUANDO aparece una frecu cercana con esa nota o cambia la hora, ENTONCES pasa a la siguiente quinta libre o a la nota de la nueva hora.
- AC4: CUANDO se abre la nueva frecu ENTONCES el campo «Nombre de la frecu» trae «Frecu de <nombre guardado>» (o «Mi frecu» sin nombre guardado) con su contador de 24 y el ejemplo «Ej. Ruta del domingo» al vaciarlo, y el código de acceso muestra 4 cifras generadas en celdas de solo lectura con «4 dígitos» y «Compártelo solo con tu grupo: evita que se unan desconocidos de la misma red.»; CUANDO toca «Generar otro» ENTONCES el código cambia por uno nuevo.
- AC5: CUANDO el usuario toca «Abrir frecu» ENTONCES se crea la frecu con el nombre sin espacios sobrantes, el código mostrado, el nombre guardado como anfitrión y las notas de las frecus cercanas, se publica con su nota y se abre la frecu activa; con el nombre vacío el botón no responde; si la creación falla, avisa con el mensaje de la falla y sigue en la nueva frecu.
- AC6: CUANDO el sistema pide reducir el movimiento ENTONCES la ilustración del punto de acceso queda quieta y no pide cuadros; sin movimiento reducido sus anillos se mueven en cada cuadro.
- AC7: CUANDO se dibuja el reloj de quintas ENTONCES sus 12 notas van cada 30° desde las 12 en el orden del círculo de quintas (Do, Sol, Re, La, Mi, Si, Fa♯, Re♭, La♭, Mi♭, Si♭, Fa; C, G, D… en inglés), la aguja de la hora apunta a (hora mod 12 + minutos/60) · 30° y la de los minutos a minutos · 6°, en sentido horario desde las 12, y se enciende la posición de la nota recibida.

## Diseño

Referencia: `V.hotspot` y `V.create` de `screens.js`; `drawFifths`, `drawHotspot` y `noteAt` de `engine.js`; `UI.field`, `UI.pin`, `UI.seg` y `UI.note` de `components.js`; `.appbar`, `.ttl`, `.hs-ill`, `.stepsl`, `.ch-hero.fifths`, `.chv`, `.pinrow`, `.note.big`, `.h-screen`, `.p-screen` y `.dock` de `screens.css` y `.field-l` y `.field-h` de `ui.css`. Todo con `context.fr`, sin colores sueltos ni texto directo. Como en C15, en los dibujos el trazo y el texto de señal van en `signalFg` y los rellenos y el brillo en `signal`, con los lavados por `washK`.

- **`CreateRoomPage`** (`create_room_page.dart`, `ConsumerStatefulWidget`, `@RoutePage()`): guarda los controladores del nombre y el código y un `Navigator` anidado con `NavigatorPopHandler` (como `PermissionsPage`). El primer paso es `HotspotGuideStep`; sus dos botones hacen `push` de `NewRoomStep` con `FrPageRoute(transition: FrTransition.slide)`. Atrás en la guía hace `context.router.maybePop()`; en la nueva frecu, `pop` del `Navigator` anidado. Mantiene vivo `nearbyRoomsProvider`. Al iniciar, el nombre es `newRoom.defaultName(name)` con el nombre guardado o `newRoom.untitled`, y el código, `ref.read(accessCodeGeneratorProvider)()`. Abrir: `roomNotifierProvider.notifier.createRoom(name: nombre.trim(), accessCode: código, displayName: ref.savedDisplayName, nearbyNotes: notas cercanas)`; si sale bien, `publishRoom` con la nota y `replace(RoomRoute(roomId))`; si falla, `showFrToast` con `toLocalizedMessage()` y quita la carga.
- **`create_room_layout.dart`**: `CreateRoomAppBar` (60 px, relleno 0 16: `FrIconButton.drawn(FrIcons.back, ghost)` con `newRoom.back`, en el centro `newRoom.step(current, total)` en `labelS` y `tx3` en mayúsculas sobre el título en Archivo 640 a 16 px ancho 110, y un hueco de 48), `CreateRoomScroll` (desplazable con espacio abajo para el dock) y los estilos `.h-screen` y `.p-screen`.
- **`HotspotGuideStep`** (`widgets/hotspot_guide_step.dart`): cabecera `Paso 1 de 2` · `guide.title`; `HotspotIllustration` de 190 px; `guide.heading` (`.h-screen` a 26/30) y `guide.message` (`.p-screen`, margen 8) con relleno 0 20; `FrSegmented<HotspotPlatform>` (`android`, `iphone`) con relleno 16 20 0; la lista de pasos (relleno 6 20 0): rejilla 34 / resto con separación 12, relleno 13 0, línea inferior `line1`; el número «01» en Martian Mono 11 px en `signalFg` con interletrado 0,06 em y, de día, el marcatexto `signalMark` debajo; el texto a 14,5/1,45 en `tx2` con el inicio (`lead`) en 600 y `tx1`. Dock: `FrButton.drawn` «Ya está activo» con `FrIcons.arrow` a la derecha y «Ya estamos en la misma Wi-Fi» ghost, ambos a todo el ancho.
- **`HotspotIllustration`** (`widgets/hotspot_illustration.dart`): `FrLoop` en un `RepaintBoundary` con un `CustomPainter` que porta `drawHotspot`: 4 anillos elípticos orgánicos (fase `(0,35 t + k/4) mod 1`, radio 34 + 110 · fase, ruido `frNoise2` de 6 px por fase, alto al 62 %) en `signalFg` con alfa (1 − fase) · 0,5; el teléfono de 38 × 68 (radio 9) en `bg2` con borde de tinta al 30 %, el punto de señal con brillo y dos arcos de emisión; y tres satélites (círculos de 15 px en `bg0` con borde de tinta al 14 %) en los ángulos −2,4, −0,8 y 0,8 rad sobre una elipse de 128 × 66, cada uno con un `SignalSignature` de 30 px de las semillas fijas del prototipo en `p1`, `p2` y `p3`. Función pura `hotspotRingPhase(seconds, ring)`. Con movimiento reducido no pide cuadros.
- **`NewRoomStep`** (`widgets/new_room_step.dart`, `ConsumerStatefulWidget`): cabecera `Paso 2 de 2` · `newRoom.title`; relee el reloj cada 15 s (`Timer.periodic`, cancelado en `dispose`); calcula la nota con `AssignRoomNote().assign`. Héroe (margen 4 20 0, alto 196, radio 28, `bg1` con el degradado radial de señal al 12 % · `washK` desde abajo, borde `line1` y filo `spec`): `FifthsClock` de 184 × 184 en (2, 6) y a la derecha (20, 24), alineado al final con separación 8: `newRoom.soundsIn` en `labelS` `tx3`, `RoomNoteText` a 64 px con brillo de señal y octava a 15 px, `hzText` en `labelS` `tx2` y `newRoom.openedAt(time)` en `labelS` `tx3`. Debajo (relleno 0 20, margen 22, separación 22): `FrField` `newRoom.name` (máximo 24, ejemplo `newRoom.nameHint`) y el código: `newRoom.code` en `label` y `newRoom.codeDigits` en `labelS` en una fila, `FrPinField(readOnly: true)` (en un `FittedBox`) y `FrIconButton.drawn(FrIcons.regen)` con `newRoom.regenerate` que gira una vuelta (700 ms, sin giro con movimiento reducido), y `newRoom.codeHelp` en 12,5/1,45 `tx3`. Dock: `FrButton.drawn` `newRoom.open` con `FrIcons.antenna`, `loading` mientras crea y deshabilitado sin nombre.
- **`FifthsClock`** (`widgets/fifths_clock.dart`): `hour`, `minute` y `note` (`RoomNote`); `Semantics` con `newRoom.clockLabel(time, note)`; `CustomPainter` sin bucle (no anima) que porta `drawFifths` sin pie: R = 0,36 · lado; sector encendido en `position = note.fifthsPosition` con degradado radial de señal de 0 a 0,14 · `washK`; la estrella {12/5} en tinta al 7 % a 0,8 R; 60 marcas (mayores cada 5, de 0,88 R en tinta al 32 % y 1,4 px; menores de 0,94 R al 12 %); las 12 notas a 1,22 R en Martian Mono de max(9, round(0,17 R)) px, la encendida en 700 y `signalFg` con brillo de señal y las demás en 500 y tinta al 42 %, con los nombres de `lobby.noteNames` en el orden de `RoomNote.circleOfFifths`; la aguja de minutos en tinta al 50 % (1,3 px, 0,82 R), la de la hora en `signalFg` (2,6 px, 0,6 R, punta redonda, brillo de señal) y el eje de 3,5 px en `signalFg`. Funciones puras: `fifthsAngle(position)` (−π/2 + posición · 2π/12), `fifthsHourAngle(hour, minute)`, `fifthsMinuteAngle(minute)` y `fifthsLabels(noteNames)`.
- **`RoomNoteText`** (`room_note_label.dart`): suma `octaveSize` (por defecto el de `labelS`) y `glow` (sombra de texto de señal de 24 px al 30 %) para la nota grande; lo demás no cambia.
- **Proveedores** (`providers/new_room_provider.dart`, `@riverpod`): `newRoomClock` (`DateTime Function()`, `DateTime.now`) y `accessCodeGenerator` (`String Function()`, cuatro cifras de 1000 a 9999 con `Random.secure`).
- **Textos** (`lib/i18n`, `es` y `en`, dentro de `lobby.newRoom`): `back`, `step` (`$current`, `$total`), `guide.title`, `guide.heading`, `guide.message`, `guide.android`, `guide.iphone`, `guide.androidSteps` y `guide.iphoneSteps` (listas de `lead` y `rest` con la interfaz `HotspotStep`), `guide.ready`, `guide.sameWifi`, `title`, `soundsIn`, `openedAt` (`$time`), `name`, `nameHint`, `defaultName` (`$name`), `untitled`, `code`, `codeDigits`, `regenerate`, `codeHelp`, `open` y `clockLabel` (`$time`, `$note`); se quita `lobby.roomName`, que solo usaba la pantalla de hoy. Se regenera con `dart run slang`.
- **Pruebas**: `fifths_clock_test.dart` (funciones puras y nombres en `es` y `en`); `hotspot_guide_test.dart` y `new_room_test.dart` montan `FrecuApp` en 390 × 844 con movimiento reducido, sustituyen el descubrimiento, la red, la sala, el reloj y el generador por dobles y cargan el inglés con `tester.runAsync`.

## Archivos

- modificar lib/features/lobby/presentation/pages/create_room_page.dart — guía y nueva frecu en dos pasos de un `Navigator` anidado, nombre y código guardados y apertura de la frecu.
- crear lib/features/lobby/presentation/widgets/create_room_layout.dart — cabecera con Atrás, paso y título, desplazable con espacio para el dock y estilos de título y texto.
- crear lib/features/lobby/presentation/widgets/hotspot_guide_step.dart — guía del punto de acceso con selector Android | iPhone, pasos y dock.
- crear lib/features/lobby/presentation/widgets/hotspot_illustration.dart — teléfono emisor con anillos orgánicos y satélites.
- crear lib/features/lobby/presentation/widgets/new_room_step.dart — nueva frecu con reloj, nota, Hz, hora, nombre, código y Abrir frecu.
- crear lib/features/lobby/presentation/widgets/fifths_clock.dart — reloj del círculo de quintas y sus funciones puras.
- modificar lib/features/lobby/presentation/widgets/room_note_label.dart — tamaño de la octava y brillo para la nota grande.
- crear lib/features/lobby/presentation/providers/new_room_provider.dart — reloj y generador de código inyectables.
- crear lib/features/lobby/presentation/providers/new_room_provider.g.dart — proveedores generados por riverpod_generator.
- modificar lib/i18n/strings.i18n.json — textos de la guía y la nueva frecu en español; se quita `lobby.roomName`.
- modificar lib/i18n/strings_en.i18n.json — los mismos textos en inglés.
- modificar lib/i18n/strings.g.dart — traducciones generadas por slang.
- modificar lib/i18n/strings_es.g.dart — traducciones generadas por slang en español.
- modificar lib/i18n/strings_en.g.dart — traducciones generadas por slang en inglés.
- crear test/features/lobby/presentation/fifths_clock_test.dart — orden de las notas, ángulos de las agujas y posición encendida.
- crear test/features/lobby/presentation/hotspot_guide_test.dart — guía, plataformas, inglés, pasos entre pantallas y movimiento reducido.
- crear test/features/lobby/presentation/new_room_test.dart — nota y reloj con la hora y las frecus cercanas, nombre, código, Abrir frecu y fallas.
- modificar test/features/room/presentation/room_flow_test.dart — crear pasa por la guía y Abrir frecu con el código generado.
- modificar test/features/lobby/presentation/room_note_flow_test.dart — crear pasa por la guía y Abrir frecu.
- modificar test/features/lobby/presentation/saved_name_test.dart — crear pasa por la guía y Abrir frecu.

## Tareas

- [x] T1: Reloj del círculo de quintas
  - files: lib/features/lobby/presentation/widgets/fifths_clock.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/fifths_clock_test.dart
  - ac: AC7
  - verify: flutter test test/features/lobby/presentation/fifths_clock_test.dart
- [x] T2: Guía del punto de acceso y nueva frecu en dos pasos
  - files: lib/features/lobby/presentation/pages/create_room_page.dart, lib/features/lobby/presentation/widgets/create_room_layout.dart, lib/features/lobby/presentation/widgets/hotspot_guide_step.dart, lib/features/lobby/presentation/widgets/hotspot_illustration.dart, lib/features/lobby/presentation/widgets/new_room_step.dart, lib/features/lobby/presentation/widgets/room_note_label.dart, lib/features/lobby/presentation/providers/new_room_provider.dart, lib/features/lobby/presentation/providers/new_room_provider.g.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/hotspot_guide_test.dart, test/features/lobby/presentation/new_room_test.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6
  - verify: flutter test test/features/lobby/presentation/hotspot_guide_test.dart test/features/lobby/presentation/new_room_test.dart
- [ ] T3: Pruebas existentes con la creación nueva y textos sin uso fuera
  - files: lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/room/presentation/room_flow_test.dart, test/features/lobby/presentation/room_note_flow_test.dart, test/features/lobby/presentation/saved_name_test.dart
  - ac: AC2, AC5
  - verify: flutter test && flutter analyze

## Riesgos

- R1: C16 corre en paralelo y también toca `features/lobby`, `lib/i18n`, `room_flow_test` y `saved_name_test` — mitigación: los textos van en `lobby.newRoom`, en las pruebas solo cambian las líneas del recorrido de crear y, si al cerrar chocan, los `strings*.g.dart` se regeneran con `dart run slang`.
- R2: En un teléfono de 360 px el código (286 px) y «Generar otro» no caben — mitigación: el código va en un `FittedBox` que lo encoge.
- R3: La nota mostrada y la de la frecu creada se calculan con relojes distintos (A2) — mitigación: ambas usan `AssignRoomNote` con las mismas notas cercanas; solo difieren si cambia la hora entre mirar y abrir, y la frecu publica la suya.
