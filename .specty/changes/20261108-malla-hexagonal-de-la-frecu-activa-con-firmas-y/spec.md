---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C4
---

# Malla hexagonal de la frecu activa con firmas y nota en la cabecera

## Objetivo

La frecu activa deja la lista Material de participantes y pasa a la malla hexagonal del prototipo aprobado (`drawMesh` y `meshSlots` de `docs/diseno/prototipo/engine.js`, `roomView` de `screens.js`): seis lugares con la firma de señal de cada persona, quién habla, las aristas con paquetes de voz y el estado de reconexión, bajo una cabecera con la nota de la frecu y sus Hz. Cubre la parte de malla y cabecera de AC7 de la épica sin perder el PTT, el micrófono abierto ni el ruteo de audio actuales.

## Fuera de alcance

- Núcleo PTT con VU circular, isla de estado y modo de habla con su diseño final: C18. `MicControlSection` y `PttButton` se quedan como están, salvo el color de P23/P25.
- Hojas de invitación, ruta de audio y salir, y la pantalla de cierre: C19. El diálogo QR, el aviso de frecu cerrada y el ciclo de ruta actuales se conservan.
- Cambiar a `FrIcons` los botones de invitar (`Icons.qr_code`) y de ruta de audio: los buscan pruebas de `features/lobby` y de voz; lo hace C19 con sus hojas.
- Llevar la nota en el mensaje `welcome` de la señalización (P64, cambio `20261108-nota-musical-roomnote-en-el-mensaje-welcome-de` en paralelo): mientras no llegue, quien se une por IP ve la cabecera sin nota.
- Nivel de voz real de cada participante (la red solo dice quién habla) y diapasón al entrar.
- Transiciones del router (P53) y cambios en `lib/core`, `lib/app` y `features/lobby`.

## Supuestos

- A1: Para poner a la persona abajo (lugar 0, «cerca del pulgar») y marcarla como «Tú», `RoomRepository` expone `String? get localParticipantId`: el `peerId` del último `welcome` (también tras reconectar, porque el anfitrión asigna un id nuevo) y `null` sin frecu. Si es `null`, nadie se marca como «Tú» y los nodos llenan los lugares 1 a 5 y luego el 0.
  - impacto: alto
- A2: Las firmas son `SignalSignature` de `lib/core` superpuestas al pintor de la malla, cada una con su `FrLoop`, porque su pintor es privado y tocar `lib/core` sería un tercer módulo; la malla tiene su propio `FrLoop` solo mientras hay nodos, así que sin participantes queda quieta y `pumpAndSettle` termina (las pruebas de `features/lobby` entran a la frecu con la lista vacía).
  - impacto: alto
- A3: La red no da el nivel de voz de cada persona: mientras alguien habla, su nivel es `frVoice` con la semilla de su lugar, como `levelFn` del prototipo; con movimiento reducido es un nivel fijo de 0,6 para que el halo y el anillo sigan mostrando quién habla.
- A4: Una persona conserva su lugar mientras siga en la frecu y quien llega toma el primer lugar libre (1 a 5); el color sale del lugar: la persona propia usa la señal y los lugares 1 a 5 usan `p1` a `p5`.
- A5: El color de la señal propia como trazo o texto es `signalFg` (tinta de día, verde de noche) y el halo y el brillo de los paquetes usan `signal` (verde), como `glow` del prototipo (A7 de la épica, P23 y P25).
- A6: Se quitan el contador «Participantes (n/6)» y la tarjeta con IP y código: la ocupación se ve en los lugares libres, la isla de C18 mostrará n/6 y la IP y el código siguen en la invitación QR.
- A7: Las etiquetas pequeñas van en mayúsculas como `.t-label-s` del prototipo y el resto de la app (`toUpperCase()` sobre el texto de slang).

## Criterios de aceptación

- AC1: CUANDO el usuario está en una frecu activa ENTONCES ve la malla de 6 lugares sobre un lienzo de 390 × 304 (centro en (195, 138), radio 104, a 90°, 150°, 210°, 270°, 330° y 30°) con un nodo por participante: su firma de señal (`SignalSignature` de su nombre), su nombre debajo y su papel («Tú», «Tú · anfitrión» o «Anfitrión»); la persona propia está en el lugar 0 con el color de la señal, cada participante conserva su lugar y su color mientras siga y quien llega toma el primer lugar libre; hay una arista entre cada par de nodos y cada lugar vacío muestra un círculo punteado con «+» y «Libre», que al tocarlo abre la invitación QR.
- AC2: CUANDO alguien habla (un participante remoto en `speakingPeers` o con `isSpeaking`, o la persona propia al transmitir) ENTONCES su nodo crece con halo y anillo de su color, su firma ondula con su nivel de voz, su etiqueta dice «Hablando» (o «Al aire» si es la propia) en su color, sus aristas se degradan desde su nodo y salen paquetes de voz hacia cada nodo conectado; CUANDO deja de hablar ENTONCES el nodo vuelve al reposo y los paquetes se acaban.
- AC3: CUANDO la frecu está reconectando ENTONCES todas las aristas son punteadas en ámbar, los anillos son punteados en ámbar, las firmas pasan a «enlazando», las etiquetas dicen «Reconectando» en ámbar y no hay halos ni paquetes aunque alguien hable; CUANDO la frecu está conectando o un participante está conectando ENTONCES su etiqueta dice «Conectando», su firma está enlazando y sus aristas son punteadas; un participante silenciado dice «Silenciado» con la firma aplanada.
- AC4: CUANDO alguien se une ENTONCES su nodo aparece con el resorte del prototipo (escala `1 − e^(−6a)·cos(11a)` entre 0 y 1,25 durante 1,6 s) y sus aristas se funden en 0,7 s; CUANDO el sistema pide reducir el movimiento ENTONCES los nodos aparecen a escala 1 sin resorte, la malla no anima ni lanza paquetes y quien habla se sigue viendo por su halo, su anillo y su etiqueta.
- AC5: CUANDO la frecu activa tiene nota ENTONCES la cabecera muestra un chip con su frecuencia redondeada («330 HZ») y la nota en Doto con la alteración en superíndice y la octava en subíndice (Mi⁴, Fa♯⁴), el nombre de la frecu y «Eres el anfitrión» o «Anfitrión · <nombre>»; en inglés la nota sale con su nombre en inglés (E4, F♯4); CUANDO la frecu no tiene nota (por ejemplo, unión por IP) ENTONCES la cabecera se muestra sin chip, con el nombre y el anfitrión.
- AC6: CUANDO el usuario está en la frecu activa ENTONCES la pantalla es un `FrScaffold` con la cabecera (ruta de audio, invitar y salir), la malla y debajo los controles actuales: el PTT, el micrófono abierto, el cambio de modo, el ciclo de ruta de audio, la invitación QR, salir y el aviso de frecu cerrada funcionan como antes; con tema claro, la etiqueta y la firma propias y el texto «Hablando» del micrófono abierto van en `signalFg`, nunca en verde sobre blanco.
- AC7: CUANDO el repositorio de sala recibe la bienvenida (`welcome`) al crear, unirse o reconectar ENTONCES `localParticipantId` es el `peerId` que asignó el anfitrión; CUANDO el usuario sale, la frecu se cierra o lo rechazan ENTONCES vuelve a `null`.

## Diseño

Referencia: `drawMesh`, `meshSlots`, `drawSig` y `easeInOut` de `engine.js`; `meshFor`, `meshLabels` y `roomView` de `screens.js`; `.room-h`, `.chip`, `.note` y `.mesh .nl` de `screens.css`. Todo con `context.fr` y textos de slang.

- **Repositorio (AC7)**: `RoomRepository` suma `String? get localParticipantId`. `RoomRepositoryImpl` guarda el `peerId` en `_onWelcome` y lo borra en `leaveRoom`, `_onRoomClosed` y `_onRejected`.
- **Escena (`presentation/widgets/room_mesh_scene.dart`)**: el modelo, sin widgets, y el pintor de la malla.
  - `meshCanvas = Size(390, 304)`, `meshRadius = 104` y `List<Offset> meshSlots(Size)`: centro `(w/2, h/2 − 14)` y ángulos 90, 150, 210, 270, 330 y 30.
  - `assignMeshSlots(previous, participants, localId)`: la propia al 0, los que siguen conservan su lugar, los nuevos toman el primer libre en el orden 1, 2, 3, 4, 5, 0; como máximo 6.
  - `MeshLink { ok, link, rec, off }` y `MeshNode` (`id`, `name`, `slot`, `isMe`, `isHost`, `speaking`, `muted`, `link`). `buildMeshNodes(...)` da la lista de 6 lugares (nulos los libres): `RoomStatus.reconnecting` → `rec` para todos, `connecting` → `link`, si no, `connectionState` del participante (`connecting` → `link`, `reconnecting` → `rec`, `disconnected` → `off`). La propia habla con `VoiceState.isTalking`; las demás con `isSpeaking` o `speakingPeers`.
  - `MeshCaption` y `meshCaption(node)`: `link` → conectando; `rec` → reconectando; silenciado; hablando (al aire si es la propia); si no, tú · anfitrión, tú, anfitrión o nada.
  - `meshAppearScale(age)` = `clamp(1 − e^(−6a)·cos(11a), 0, 1,25)` si `a < 1,6`, si no 1; `meshEdgeAlpha(age)` = `clamp(a·1,4)`.
  - `MeshMotion.advance(t, nodes, reduced:)`: nivel objetivo `frVoice(t, slot + 1)` si habla con enlace `ok` (0,6 fijo con movimiento reducido), 0 si no; suavizado por tiempo (sube a 0,4 y baja a 0,1 por cuadro de 60 Hz) y directo con movimiento reducido o enlace distinto de `ok`. Cada nodo con nivel ≥ 0,18 lanza cada `0,16 − 0,08·nivel` s un paquete a cada otro nodo `ok`; un paquete dura 0,75 s con `easeInOut` y alfa `0,9·sin(πk)`. Sin paquetes con movimiento reducido ni hacia nodos que se fueron.
  - `RoomMeshPainter`: aristas (punteadas 3/5 en `warn` al 22 % si alguno no está `ok`; con habla, degradado de su color al 20 % + 50 %·nivel hacia el 5 %, grosor 1 + nivel; si no, `ink` al 8 %), paquetes (radio 1,8 con brillo), lugares libres (círculo de 22 punteado 2/4 en `ink` al 16 % y «+» de ±5 en `ink` al 28 %), halos (degradado radial de R·0,6 a R·2,2 si el nivel > 0,04, sin halos en `rec`), relleno `bg1` de radio `(27 + 3·nivel)·escala` y anillo (punteado 4/4 en `warn` al 70 % con `rec`; color al 50 % + 50 %·nivel si habla; la propia al 45 %; si no, `ink` al 13 %). Repinta con el tiempo del `FrLoop`.
- **Malla (`room_mesh.dart`, `RoomMesh`)**: `StatefulWidget` con `participants`, `localParticipantId`, `speakingPeers`, `localTalking`, `status` y `onInvite`. Guarda los lugares, la hora de llegada de cada nodo y un `MeshMotion`. `Stack` de 390 × 304 (en un `FittedBox` que solo achica): el pintor, una `SignalSignature` de 40 px por nodo (radio 0,425, color del nodo, modo `link` con `rec` o `link`, `muted` si está silenciado, `off` si está desconectado, y si no `idle` con `levelOf` leyendo el nivel de `MeshMotion`) escalada por `meshAppearScale`, la marca de antena del anfitrión arriba a la derecha (círculo de 8 en `bg0` con borde `tx2`), las etiquetas de 112 px centradas a +33 (nombre en Archivo 600 a 12,5 px; papel en `labelS` y `tx3`, en el color del nodo si habla y en `warn` si reconecta; con clave `speaking_indicator_<id>` si habla) y en los libres «Libre» en `tx4` a +30 con un área de 64 px que llama a `onInvite`.
- **Cabecera (`room_header.dart`, `RoomHeader`)**: alto 72, relleno 8 20 0. A la izquierda el chip de nota (64 × 50, radio 14, `bg0`, borde `line2`, filo `spec`; Hz en `labelS` y `tx3` arriba a la izquierda; nota en Doto 800 a 22 px en `tx1`, alteración en Martian Mono al 50 % arriba y octava en `labelS` a 8 px en `tx3` abajo; con `Semantics` «Nota Mi4, 330 Hz») y el nombre (Archivo 660 a 16,5 px, una línea con elipsis) sobre «Eres el anfitrión» o «Anfitrión · <nombre>» en `labelS` y `tx3`. A la derecha, separados 8: `FrIconButton` de ruta (`audio_route_button`, íconos de hoy), de invitar (`Icons.qr_code`) y `FrIconButton.drawn(FrIcons.exit)` en `danger` (`leave_button`).
- **Página (`room_page.dart`)**: `FrScaffold` con columna: `RoomHeader`, `Expanded` con `RoomMesh` centrada y `MicControlSection` con relleno 16. `participants_list.dart` y `room_info_card.dart` desaparecen: la malla y la cabecera los reemplazan. `MicControlSection` pinta «Hablando» del micrófono abierto en `signalFg` (P23/P25).
- **Textos (`lib/i18n`, dentro de `room`)**: `noteNames` (12 nombres por clase de altura: Do … Si y C … B), `mesh.you`, `mesh.youHost`, `mesh.onAir`, `mesh.connecting`, `mesh.reconnecting`, `mesh.free`, `mesh.invite`, `header.youAreHost`, `header.hostedBy` (`$name`), `header.hz` (`$value`), `header.note` (`$note`, `$hz`) y `header.invite`. Se reutilizan `room.speaking`, `room.muted`, `room.host`, `room.leave` y los nombres de ruta. Se regenera con `dart run slang`.
- **Pruebas**: `room_mesh_test.dart` prueba el modelo y el widget `RoomMesh` dentro de un `MaterialApp` con el tema de Portadora; `room_flow_test.dart` prueba la cabecera y la página dentro de `FrecuApp`. Las que muestran nodos usan movimiento reducido (`FakeAccessibilityFeatures(disableAnimations: true)`) para que `pumpAndSettle` termine; las del resorte y los paquetes usan `pump` con duración.

## Archivos

- modificar lib/features/room/domain/repositories/room_repository.dart — `localParticipantId` en el contrato.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — guardar y borrar el id local con la bienvenida, la salida y el cierre.
- crear lib/features/room/presentation/widgets/room_mesh_scene.dart — lugares, asignación estable, nodos, leyendas, resorte, movimiento y pintor de la malla.
- renombrar lib/features/room/presentation/widgets/participants_list.dart -> lib/features/room/presentation/widgets/room_mesh.dart — la malla con firmas, marca de anfitrión y etiquetas reemplaza a la lista de participantes.
- renombrar lib/features/room/presentation/widgets/room_info_card.dart -> lib/features/room/presentation/widgets/room_header.dart — la cabecera con chip de nota y Hz, nombre, anfitrión y botones reemplaza a la tarjeta de IP y código.
- modificar lib/features/room/presentation/pages/room_page.dart — `FrScaffold` con cabecera, malla y controles actuales.
- modificar lib/features/room/presentation/widgets/mic_control_section.dart — «Hablando» en `signalFg` (P23/P25).
- modificar lib/i18n/strings.i18n.json — textos de la malla, la cabecera y los nombres de las notas en español (los `.g.dart` se regeneran con `dart run slang`).
- modificar lib/i18n/strings_en.i18n.json — los mismos textos en inglés.
- modificar test/features/room/data/room_repository_test.dart — id local con la bienvenida, la reconexión, la salida y el cierre.
- crear test/features/room/presentation/room_mesh_test.dart — geometría, lugares, nodos, leyendas, resorte y movimiento; malla con firmas, etiquetas, lugares libres, reconexión y movimiento reducido.
- modificar test/features/room/presentation/room_flow_test.dart — cabecera con nota en español e inglés y sin nota, anfitrión, salir, lugares y reconexión en la frecu activa.
- modificar test/features/room/presentation/voice_flow_test.dart — controles de voz y ruta con la malla y movimiento reducido.

## Tareas

- [x] T1: Id del participante local en el repositorio de sala
  - files: lib/features/room/domain/repositories/room_repository.dart, lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/room_repository_test.dart
  - ac: AC7
  - verify: flutter test test/features/room/data/room_repository_test.dart
- [x] T2: Malla hexagonal con firmas, etiquetas, movimiento y pintor
  - files: lib/features/room/presentation/widgets/room_mesh_scene.dart, lib/features/room/presentation/widgets/room_mesh.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, test/features/room/presentation/room_mesh_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: flutter test test/features/room/presentation/room_mesh_test.dart
- [ ] T3: Frecu activa con cabecera de nota, malla y controles actuales
  - files: lib/features/room/presentation/widgets/room_header.dart, lib/features/room/presentation/pages/room_page.dart, lib/features/room/presentation/widgets/mic_control_section.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, test/features/room/presentation/room_flow_test.dart, test/features/room/presentation/voice_flow_test.dart
  - ac: AC1, AC5, AC6
  - verify: flutter analyze && flutter test test/features/room test/features/lobby

## Riesgos

- R1: Hasta siete tickers a la vez (la malla y seis firmas) en un Android de gama media (A1 de la épica) — mitigación: `RepaintBoundary` en la malla y en cada firma, la malla quieta sin nodos y el perfilado pendiente de P33.
- R2: C18 y C19 también rehacen `RoomPage` — mitigación: la cabecera, la malla y los controles quedan en widgets separados y los controles actuales no cambian de clave ni de comportamiento.
- R3: C12 añade textos a slang en paralelo — mitigación: las claves nuevas van dentro del objeto `room` y, si hay conflicto en los generados, se regeneran con `dart run slang`.
