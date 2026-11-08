---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C15
---

# Inicio con sintonizador de dos octavas y lista de frecus cercanas

## Objetivo

Rehacer el inicio (`LobbyPage`) con el sistema Portadora, como la pantalla `lobby` del prototipo aprobado (`docs/diseno/prototipo/screens.js`): cabecera con la marca, el estado de la red local y Ajustes; el sintonizador de dos octavas (Do4–Si5) con un pico por frecu cercana sobre la tecla de su nota, aguja con resorte y lectura de nota; la lista de frecus cercanas con su nota y sus Hz; los estados de búsqueda vacía y sin red; y abajo Crear frecu, Escanear y Conectar por IP. Cubre la parte del inicio de AC6 de la épica, traduce los nombres de las notas (P59) y quita `lobby.yourName` (P81). Hoy el inicio es Material genérico, sin notas ni estado de red.

## Fuera de alcance

- Hojas de código de acceso e IP y escáner con su diseño final (C16): tocar una frecu abre el diálogo de código de hoy, Conectar por IP el diálogo de IP de hoy y Escanear la pantalla de escaneo de hoy.
- Guía del punto de acceso y nueva frecu con el reloj de quintas (C17): Crear frecu abre la pantalla de nueva frecu de hoy.
- Acción «Abrir ajustes de Wi-Fi» del aviso sin red: necesita un plugin nuevo; queda anotada.
- Entrada escalonada de las tarjetas (`rise`) y transiciones del router (P53).
- Cambios en `lib/core/design` (`FrBanner` solo admite `IconData`), en `features/network`, en `features/room` y en el dominio.
- Unificar los nombres de las notas con `room.noteNames` de C4, que aún no está en develop: aquí van en `lobby.noteNames`; queda anotado.

## Supuestos

- A1: El estado de la red sale de `networkRepositoryProvider` (C5): el inicio se suscribe a `watchNetworkState()` al montarse. Mientras no llega el primer estado, la píldora dice «Buscando red» (aviso, ocupada) y el cuerpo muestra la búsqueda vacía.
  - impacto: alto
- A2: La lista manda sobre la red: si mDNS encuentra frecus se muestran aunque la detección de interfaces (heurística) diga que no hay red; el aviso sin red solo aparece sin frecus. Un error del descubrimiento se ve como búsqueda vacía.
  - impacto: alto
- A3: Tocar una frecu la elige (tarjeta encendida y aguja a su tecla) y abre el diálogo de código; la elección sigue hasta tocar otra o hasta que esa frecu desaparece de la lista.
- A4: Una frecu sin nota (anfitrión anterior a C14) sale en la lista con «—» en lugar de nota, sin Hz ni chispa, y sin pico en el sintonizador; sí cuenta en el número de frecus y en las señales.
- A5: Los Hz se muestran con un decimal y el separador del idioma («329,6 Hz», «329.6 Hz»); el nombre de la nota sale de `lobby.noteNames` por clase de altura (Do … Si, C … B).
- A6: «Frecus cercanas» se muestra tal cual y no en mayúsculas: la prueba aprobada de C4 (`room_flow_test`, salir vuelve al inicio) lo busca con ese texto.
- A7: Las pruebas que montan la app sobre el inicio pasan a movimiento reducido, porque la aguja, el ruido, el halo de la píldora, las firmas y la onda no paran solas y `pumpAndSettle` no terminaría. En `room_flow_test` y `voice_flow_test`, que también cambia C4, el cambio va en `setUp` y en los buscadores del inicio de sus pruebas AC1 y AC2, lejos de lo que toca C4.
  - impacto: alto

## Criterios de aceptación

- AC1: CUANDO se abre el inicio ENTONCES se ve en Portadora (`FrScaffold`) con la marca «frecu», la píldora de red, el botón Ajustes, «Frecus cercanas», «Elige tu frecu» con el número de frecus cercanas en dos cifras («00»), el sintonizador y abajo Crear frecu, Escanear y Conectar por IP, con todos los textos de slang en español y en inglés; Ajustes abre Ajustes, Crear frecu abre la pantalla de nueva frecu de hoy, Escanear abre el escáner de hoy y Conectar por IP abre el diálogo de unión por IP de hoy.
- AC2: CUANDO llega el estado de la red local ENTONCES la píldora dice «Red · <IP local>» si hay red o «Sin red local» en alerta si no la hay; mientras no llega dice «Buscando red».
- AC3: CUANDO hay frecus cercanas ENTONCES la lista muestra una tarjeta por frecu con su nota (nombre en el idioma de la app, alteración y octava), sus Hz con un decimal («329,6 Hz» en español, «329.6 Hz» en inglés), su nombre y su IP; el número las cuenta, y el sintonizador recibe la nota de cada una para dibujar su pico sobre su tecla y dice «N señales»; una frecu sin nota sale con «—», sin Hz y sin pico.
- AC4: CUANDO el usuario toca una frecu cercana ENTONCES queda elegida (su tarjeta encendida y la aguja del sintonizador va a su nota) y se abre el diálogo de código de hoy, que se une a esa frecu con su IP y su puerto.
- AC5: CUANDO no hay frecus cercanas y la red está conectada o aún no se sabe ENTONCES se ve la búsqueda vacía: la onda, «Sin señales por ahora», «Conéctate a la Wi-Fi del anfitrión o pídele que te muestre su QR.» y «La búsqueda sigue activa»; el sintonizador dice «Escaneando · _frecu._tcp» y «0 señales».
- AC6: CUANDO no hay frecus cercanas y no hay red local ENTONCES en lugar de la búsqueda vacía se ve un aviso de alerta «No estás en ninguna red Wi-Fi.» con «Únete al punto de acceso del anfitrión para encontrar frecus.» y el sintonizador queda atenuado con «Búsqueda en pausa»; CUANDO vuelve la red ENTONCES vuelve la búsqueda vacía; CUANDO hay frecus sin red ENTONCES se ve la lista.
- AC7: CUANDO se dibuja el sintonizador ENTONCES sus 14 teclas blancas y 10 negras van de Do4 a Si5 y cada nota cae en el centro de su tecla (`keyX` del prototipo), la lectura nombra la nota más cercana a la aguja, la aguja sigue un resorte (rigidez 90, amortiguación 16) hacia la nota elegida o barre las dos octavas sin salirse; sin movimiento reducido anima en cada cuadro y con movimiento reducido queda quieto y no pide cuadros.

## Diseño

Referencia: `V.lobby` de `screens.js`; `drawTuner`, `keyX`, `WHITE`, `drawSpark` y `noteAt` de `engine.js`; `UI.rtile`, `UI.note`, `UI.pill` y `UI.banner` de `components.js`; `.rtile` de `ui.css` y `.lobby-head`, `.tuner`, `.list`, `.empty`, `.dock`, `.wordmark`, `.kicker` y `.note` de `screens.css`. Todo con `context.fr`, sin colores sueltos ni texto directo. Como en el prototipo, en los dibujos el trazo y el texto de señal van en `signalFg` y los rellenos y el brillo en `signal`, con los lavados por `washK`.

- **`LobbyPage`** (`lobby_page.dart`, `ConsumerStatefulWidget`, `@RoutePage()`): en `initState` guarda `ref.read(networkRepositoryProvider).watchNetworkState()` y lo lee con un `StreamBuilder` (nulo = aún no se sabe); observa `nearbyRoomsProvider` (`value ?? []`) y guarda el `roomId` elegido. `FrScaffold` con el dock y una columna:
  - Cabecera de 60 px (relleno izq. 20, der. 16, `spaceBetween`): marca (`SignalSignature` de 26 px con la semilla `t.lobby.title` y «frecu» en Archivo 780 a 21 px, ancho 125, interletrado −0,03 em), `FrPill` en un `Flexible` con `FittedBox` (`network.checking` en `warn` y `busy`, `network.connected(ip)` en `ok`, `network.offline` en `alert`) y `FrIconButton.drawn(FrIcons.sliders)` con `t.lobby.settings` que hace `push(SettingsRoute())`.
  - Encabezado (relleno 6 20 16): a la izquierda la línea de 16 × 1 en `signalFg`, «Frecus cercanas» en `label` y `tx3`, y debajo «Elige tu frecu» en `display` a 28 px; a la derecha el número en dos cifras en `digits` a 44 px en `tx1`.
  - `LobbyTuner` con las notas de las frecus (`.nonNulls`), su número, la nota de la elegida y `paused` si no hay frecus y la red es `NetworkDisconnected`.
  - Cuerpo: con frecus, `ListView` (relleno 16 20 200, separación 10) de `NearbyRoomTile`; sin frecus y sin red, `FrBanner` de alerta (`Icons.wifi_off_rounded`, `offline.title`, `offline.message`, sin cierre) con relleno 16 20; si no, la búsqueda vacía (relleno 26 26 0, centrada): `WaveLoader` de 80 × 26, `empty.title` en Archivo 640 a 18 px, `empty.message` a 14 px en `tx2` con ancho máximo 290 y `empty.searching` en `labelS` y `tx3`, en mayúsculas.
  - Dock: fila 1,25 : 1 con `FrButton.drawn` «Crear frecu» (`FrIcons.plus`, `push(CreateRoomRoute())`) y «Escanear» secundario (`FrIcons.scan`, `push(ScanQrRoute())`), y debajo «Conectar por IP» ghost a todo el ancho (`FrIcons.nodes`) que abre el diálogo de IP.
  - Tocar una tarjeta guarda su `roomId` y abre `_PinJoinDialog`. `_PinJoinDialog` y `_JoinRoomDialog` siguen como hoy (C16 los rehace).
- **`LobbyTuner`** (`widgets/lobby_tuner.dart`, `StatefulWidget`): `notes` (`List<RoomNote>`), `signalCount`, `selected` (`RoomNote?`) y `paused`. Caja de 158 px con margen 0 20, radio 26, degradado `bg1`→`bg0`, borde `line1` y filo `spec`; al 35 % si `paused`. Arriba (14 px, 16 a los lados) `tuner.scanning` o `tuner.paused` y `tuner.signals(n)` (en `signalFg` si hay señales), en `labelS` y mayúsculas. Debajo un `FrLoop` con un `CustomPainter` que porta `drawTuner`: teclas blancas y negras encendidas por las notas (más la elegida), etiquetas «DO4», «DO5» y «SI5» con los nombres traducidos, piso de ruido (`frNoise2`), un pico gaussiano por nota que nace con el resorte del prototipo y lleva su nota encima, y la aguja con su estela y la lectura de la nota más cercana cuando no hay elección. El estado guarda cuándo apareció cada nota y la aguja. Funciones puras y públicas para probarlas: `tunerKeyX(semitone, left:, keyWidth:)` (`keyX`), `tunerNearestSemitone(x, left:, keyWidth:)`, `tunerSweep(seconds)` (`0,5 + 0,44 · sen(0,42 t) + 0,02 · ruido(3 t)`) y `TunerNeedle` (`position`, `velocity`, `advance(target, seconds)` en pasos de 1/60 s con Euler semiimplícito, rigidez 90 y amortiguación 16, y `jumpTo(target)`). Con movimiento reducido la aguja salta a su destino y los picos nacen ya crecidos.
- **`NearbyRoomTile`** (`widgets/nearby_room_tile.dart`): `room`, `selected` y `onPressed`. `FrPressable` (0,975) con la rejilla 70 / resto / 40, separación 14, relleno 10 12 10 10, radio 22, `bg1`, borde `line1` y filo `spec`; elegida, aro de señal, borde de señal al 50 % y brillo. Caja de canal de 60 px (radio 15, `bg0`, borde `line1`) con la chispa de `drawSpark` en un `FrLoop`, los Hz arriba en `labelS`, `tx3` y mayúsculas, y la nota abajo con `RoomNoteText`, o `noNote` sin Hz ni chispa. Al centro el nombre (Archivo 620 a 16,5 px, una línea con elipsis) y la IP en `labelS` y `tx3` tras `FrIcons.lock` de 16. A la derecha la caja de 40 × 40 (radio 13, `bg2`, borde `line1`) con `FrIcons.arrow`; elegida, en `signal` con el ícono en `signalInk`.
- **Nota** (`widgets/room_note_label.dart`): extensión `RoomNoteLabels` sobre `RoomNote` con `localizedName` (`t.lobby.noteNames[pitchClass]`), `label` (nombre y octava, «Fa♯4») y `hzText` (`t.lobby.hz` con un decimal y `t.lobby.decimalSeparator`); y `RoomNoteText` (`.note` del prototipo): el nombre sin alteración en `digits`, la alteración en Martian Mono a la mitad arriba y la octava en `labelS` y `tx3` abajo, como textos separados.
- **Textos** (`lib/i18n`, `es` y `en`, todos dentro de `lobby`): `title` pasa a «frecu»; nuevos `settings`, `heading`, `network.checking`, `network.connected` (`$ip`), `network.offline`, `tuner.scanning`, `tuner.paused`, `tuner.signals` (plural con `$n`), `empty.title`, `empty.message`, `empty.searching`, `offline.title`, `offline.message`, `noteNames` (12), `noNote`, `hz` (`$value`) y `decimalSeparator`; `scanQr` pasa a «Escanear» / «Scan» y `joinRoom` a «Conectar por IP» / «Connect by IP» (también título del diálogo de IP); se quitan `noRoomsNearby` y `yourName`. Se regenera con `dart run slang`.
- **Pruebas**: `lobby_page_test.dart` monta `FrecuApp` en 390 × 844 con movimiento reducido y sustituye el descubrimiento, la red y la sala por dobles; el inglés se carga con `tester.runAsync`. Las pruebas existentes que abren el inicio pasan a movimiento reducido y a los textos nuevos.

## Archivos

- modificar lib/features/lobby/presentation/pages/lobby_page.dart — inicio en Portadora con cabecera, sintonizador, lista, estados vacío y sin red, dock y elección de frecu.
- crear lib/features/lobby/presentation/widgets/lobby_tuner.dart — sintonizador de dos octavas: teclas, ruido, picos, aguja con resorte, lectura y sus funciones puras.
- crear lib/features/lobby/presentation/widgets/nearby_room_tile.dart — tarjeta de frecu cercana con chispa, Hz, nota, nombre e IP.
- crear lib/features/lobby/presentation/widgets/room_note_label.dart — nombre traducido, etiqueta y Hz de una nota, y su texto con alteración y octava.
- modificar lib/i18n/strings.i18n.json — textos del inicio y nombres de las notas en español.
- modificar lib/i18n/strings_en.i18n.json — textos del inicio y nombres de las notas en inglés.
- modificar lib/i18n/strings.g.dart — traducciones generadas por slang.
- modificar lib/i18n/strings_es.g.dart — traducciones generadas por slang en español.
- modificar lib/i18n/strings_en.g.dart — traducciones generadas por slang en inglés.
- crear test/features/lobby/presentation/lobby_page_test.dart — inicio, red, lista, elección, estados y sintonizador.
- modificar test/features/lobby/presentation/discovery_flow_test.dart — movimiento reducido, IP y búsqueda vacía con los textos nuevos.
- modificar test/features/lobby/presentation/saved_name_test.dart — movimiento reducido y Crear frecu del inicio nuevo, sin `lobby.yourName`.
- modificar test/features/lobby/presentation/room_note_flow_test.dart — movimiento reducido y Crear frecu del inicio nuevo.
- modificar test/features/lobby/presentation/room_full_flow_test.dart — movimiento reducido.
- modificar test/features/room/presentation/room_flow_test.dart — movimiento reducido en `setUp` y Crear frecu y Conectar por IP del inicio nuevo.
- modificar test/features/room/presentation/voice_flow_test.dart — movimiento reducido en `setUp`.
- modificar test/app_test.dart — movimiento reducido al abrir el inicio.
- modificar test/app/theme/app_theme_test.dart — movimiento reducido al abrir la app.
- modificar test/app/saved_theme_test.dart — movimiento reducido al abrir la app.

## Tareas

- [x] T1: Sintonizador de dos octavas con los nombres de las notas
  - files: lib/features/lobby/presentation/widgets/lobby_tuner.dart, lib/features/lobby/presentation/widgets/room_note_label.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/lobby_page_test.dart
  - ac: AC7
  - verify: flutter test test/features/lobby/presentation/lobby_page_test.dart --name AC7
- [x] T2: Inicio con cabecera, lista de frecus, estados y dock
  - files: lib/features/lobby/presentation/pages/lobby_page.dart, lib/features/lobby/presentation/widgets/nearby_room_tile.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/lobby_page_test.dart
  - ac: AC1, AC2, AC3, AC4, AC5, AC6
  - verify: flutter test test/features/lobby/presentation/lobby_page_test.dart
- [x] T3: Textos sin uso fuera y pruebas existentes con el inicio nuevo
  - files: lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/lobby/presentation/discovery_flow_test.dart, test/features/lobby/presentation/saved_name_test.dart, test/features/lobby/presentation/room_note_flow_test.dart, test/features/lobby/presentation/room_full_flow_test.dart, test/features/room/presentation/room_flow_test.dart, test/features/room/presentation/voice_flow_test.dart, test/app_test.dart, test/app/theme/app_theme_test.dart, test/app/saved_theme_test.dart
  - ac: AC1, AC4
  - verify: flutter test && flutter analyze

## Riesgos

- R1: El sintonizador repinta a 60 fps con ruido, picos y texto — mitigación: un solo `FrLoop` en un `RepaintBoundary`, los `TextPainter` de etiquetas fijas se preparan una vez por tamaño e idioma, y con movimiento reducido no pinta cuadros.
- R2: C4 también cambia `room_flow_test`, `voice_flow_test` y los `.g.dart` de slang — mitigación: los cambios de estas pruebas van en líneas que C4 no toca (A7), los textos van dentro de `lobby` y, si al cerrar chocan los generados, se regeneran con `dart run slang`.
- R3: En un teléfono de 360 px la píldora con una IP larga empuja la marca y Ajustes — mitigación: la píldora va en un `Flexible` con `FittedBox` que la encoge.

## Cierre

### Resumen

- `LobbyPage` en Portadora (`FrScaffold`): cabecera con la marca («frecu» y su firma), la píldora de red (`Buscando red` ocupada, `Red · <IP>`, `Sin red local` en alerta) y Ajustes; «Frecus cercanas», «Elige tu frecu» y el número en dos cifras; el sintonizador; la lista de `NearbyRoomTile`, la búsqueda vacía con la onda o el aviso sin red; y el dock con Crear frecu, Escanear y Conectar por IP. Tocar una frecu la elige y abre el diálogo de código de hoy; la elección se olvida si la frecu sale de la lista.
- `LobbyTuner`: teclado Do4–Si5, piso de ruido, un pico por nota que nace con el resorte del prototipo y la aguja con resorte (rigidez 90, amortiguación 16) hacia la elegida o en barrido, con la lectura de la nota más cercana; con movimiento reducido queda quieto y no pide cuadros. Funciones puras `tunerKeyX`, `tunerNearestSemitone`, `tunerSweep` y `TunerNeedle`.
- `RoomNoteLabels` (`localizedName`, `label`, `hzText`) y `RoomNoteText` con el nombre, la alteración y la octava como textos separados.
- Textos de `lobby` nuevos en `es` y `en` (nombres de las notas incluidos); `scanQr` pasa a «Escanear» y `joinRoom` a «Conectar por IP»; se quitan `noRoomsNearby` y `yourName`.
- Verificado: `flutter analyze` sin avisos y `flutter test` completo en verde (415 pruebas), 21 de ellas en `lobby_page_test.dart`.

### Desviaciones

- S1, S2: el sintonizador se repartió en `lobby_tuner.dart` (widget), `lobby_tuner_painter.dart` (pintor y estado entre cuadros) y `tuner_keyboard.dart` (teclado y aguja, reexportado desde `lobby_tuner.dart`) por el límite de 500 líneas.
- S3: la cabecera, el encabezado, la búsqueda vacía, el aviso sin red y el dock van en `widgets/lobby_sections.dart` por el mismo límite.
- `nearby_room_tile.dart` entró en el alcance de T1 porque `lobby_page_test.dart`, que verifica T1, lo importa.
- `lobby.noRoomsNearby` y `lobby.yourName` siguieron hasta T3 para que el inicio de antes compilara durante T1.
- `room_full_flow_test` además toca la frecu llena por su `NearbyRoomTile` (no solo pasa a movimiento reducido): `specty propose` pide que cada prueba enviada falle sin el código. `discovery_flow_test` sustituye la red por un doble con Wi-Fi para no depender de las interfaces de la máquina.
- Los botones del dock se encogen (`FittedBox`) si no caben, en lugar de desbordarse: con la fuente de pruebas a 390 px y en teléfonos de 360 px «Crear frecu» y «Escanear» no caben (amplía R3).

### Decisiones

- Textos en inglés: «Pick your room», «Checking network», «Network · $ip», «No local network», «Scanning · _frecu._tcp», «Search paused», «$n signal(s)», «No signals yet», «Join the host's Wi-Fi or ask them to show you their QR.», «Still searching», «You're not on any Wi-Fi network.», «Join the host's hotspot to find rooms.»; las notas en inglés son C, D♭, D, E♭, E, F, F♯, G, A♭, A, B♭, B, con las mismas alteraciones que `RoomNote`.
- La línea y la punta de la aguja van en `signalFg` (trazo) y su brillo en `signal`; los lavados (pico, estela) multiplican su alfa por `washK` con tope 1.
- Los picos de las notas que ya estaban al montar el sintonizador nacen crecidos; los que llegan después nacen con el resorte en el primer cuadro que los pinta.
- Las pruebas buscan sin distinguir mayúsculas los textos que el estilo pone en mayúsculas (píldora, etiquetas, Hz).

### Pendientes

- Acción «Abrir ajustes de Wi-Fi» del aviso sin red (necesita un plugin).
- Unificar `lobby.noteNames` con `room.noteNames` de C4 cuando llegue a develop.
- Entrada escalonada de las tarjetas (`rise`) y transiciones del router (P53).
- `dart format --set-exit-if-changed .` falla por 5 archivos ajenos a este cambio (`network_state.dart`, `permission_repository_impl.dart` y 3 pruebas de permisos y colores).
