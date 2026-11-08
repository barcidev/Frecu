---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C18
---

# Núcleo PTT, isla de estado y modo de habla en la frecu activa

## Objetivo

La frecu activa cambia el `SegmentedButton`, el botón PTT y la tarjeta de micrófono abierto de Material por los controles del prototipo aprobado (`pttZone`, `pttState`, `isleFor`, `roomView` de `docs/diseno/prototipo/screens.js`, `drawPtt` de `engine.js`, `syncRoom`/`isleSync` de `app.js`): el núcleo PTT con bisel de 72 marcas como VU circular, anillo líquido y ondas; el selector segmentado PTT | Abierto; la isla de estado siempre oscura arriba (en línea n/6, al aire con su tiempo, quién habla, micrófono abierto, reconectando y conectando); el aviso de eco con micrófono abierto y altavoz; y el modo de habla por defecto de Ajustes al entrar. Cubre esa parte de AC7 de la épica y los pendientes P75 y P79, sin perder el PTT por `track.enabled`, el micrófono abierto ni el ruteo de audio actuales.

## Fuera de alcance

- Hojas de invitación, ruta de audio y salir, la pastilla de ruta de la fila de controles y la pantalla de cierre: C19. La ruta sigue en el botón de la cabecera de C4 y el diálogo QR y el aviso de frecu cerrada no cambian.
- Eventos pasajeros de la isla (se unió, salió, audio por…, conexión recuperada) y la cuenta atrás de la reconexión: `RoomStatus.reconnecting` no trae segundos ni intentos.
- Hablar con el botón de volumen o la barra espaciadora y el nivel real de voz por las estadísticas de WebRTC: la red solo dice quién habla.
- Cambios en `lib/core` (`StatusIsland`, `FrSegmented`, `FrBanner`, `FrIcons`), en `room_mesh.dart`, `room_mesh_scene.dart` y `room_header.dart` (P82 queda pendiente), y en los repositorios y casos de uso de voz.
- Borrar `PttButton` (`ptt_button.dart`) y su prueba: dejan de usarse, pero borrarlos aquí pasaría el corte de talla; queda como pendiente.

## Supuestos

- A1: Elegir «Abierto» (a mano o como modo por defecto) solo cambia el modo, como hoy: el micrófono queda callado («Silencio») hasta que se toca el núcleo; el prototipo lo abría al instante, pero abrir el micrófono sin un gesto sorprendería a quien entra.
  - impacto: alto
- A2: El modo por defecto se lee de `preferencesProvider` (ya precargado al arrancar) al entrar a la frecu, después de `initialize()`, y solo se aplica con `setTalkMode` si es distinto del modo actual de `VoiceState`; `room` lee el provider de `features/settings` como ya hace `lobby` con el nombre guardado.
  - impacto: alto
- A3: La red no da el nivel de voz: el VU y el anillo usan `frVoice` (semilla 1 para la persona propia, como su lugar 0 en la malla, y lugar + 1 para quien habla; ×0,7 con micrófono abierto), como A3 de C4. Con movimiento reducido el nivel es 0,6 fijo y no hay barrido, ondas ni escala.
- A4: El color de quien habla sale de su lugar en la malla (`meshNodeColor`): `RoomPage` repite `assignMeshSlots` con la misma secuencia que `RoomMesh`, así el lugar coincide sin tocar la malla. En la isla se usa la paleta de noche (`FrColors.dark`), porque la isla siempre es oscura; en el núcleo, la del tema.
- A5: Sin la pastilla de ruta (C19), la fila de controles lleva solo el selector de modo, centrado y de 204 px como máximo.
- A6: Los íconos del núcleo y del selector son `FrIcons` (`mic`, `micOff`, `openMic`, `walkie`); el aviso de eco usa `Icons.headphones_rounded` porque `FrBanner` solo acepta `IconData` (P52/P55).

## Criterios de aceptación

- AC1: CUANDO el usuario está en una frecu activa en modo PTT ENTONCES ve bajo el selector el núcleo PTT (zona de 248 × 248 con un botón circular de 156, bisel de 72 marcas y anillo líquido) con el ícono del micrófono, «Mantén» y debajo «Mantén para hablar»; CUANDO pone el dedo en el núcleo ENTONCES se llama `startTalking` una sola vez aunque apoye más dedos, el botón se achica a 0,94 y se rellena de señal, el ícono cambia por el tiempo al aire («00:00», «00:01»…) con «Al aire» y «Suelta para escuchar», y el bisel enciende sus marcas como VU con ondas; CUANDO levanta o se cancela el último dedo ENTONCES se llama `stopTalking` y vuelve al reposo.
- AC2: CUANDO otra persona habla y el usuario está en PTT sin transmitir ENTONCES el bisel y el anillo se encienden en el color de su lugar, la pista dice «<nombre> está hablando · puedes responder» y el núcleo sigue respondiendo a la presión; CUANDO el anfitrión está solo en su frecu ENTONCES la pista dice «Muestra el QR para que tu grupo se una».
- AC3: CUANDO el usuario elige «Abierto» en el selector PTT | Abierto ENTONCES se llama `setTalkMode(openMic)` y el núcleo pasa a conmutador: con el micrófono callado dice «Silencio» con el ícono tachado y «Toca para activar tu micrófono», y transmitiendo dice «Abierto» sobre el relleno de señal con «Toca para silenciarte»; cada toque llama `startTalking` o `stopTalking`; CUANDO vuelve a «PTT» ENTONCES se llama `setTalkMode(pushToTalk)`. Con tema claro las letras sobre el relleno de señal van en `signalInk`.
- AC4: CUANDO el modo es micrófono abierto y la salida es el altavoz ENTONCES sobre la malla aparece el aviso ámbar «Micrófono abierto con altavoz. Usa audífonos para evitar eco.», que se puede cerrar; CUANDO vuelve a PTT o cambia la ruta ENTONCES el aviso se va y vuelve a salir la próxima vez que se den las dos condiciones.
- AC5: CUANDO el usuario entra a una frecu ENTONCES el modo de habla pasa al modo por defecto guardado en Ajustes si es distinto del actual, sin abrir el micrófono.
- AC6: CUANDO el usuario está en la frecu activa ENTONCES arriba ve la isla de estado (cápsula oscura de 36 px también en tema claro) que dice, en este orden de prioridad: «Reconectando…» en ámbar si la frecu reconecta; «Conectando…» si conecta; «Al aire · mm:ss» con relleno de señal y el tiempo que avanza cada segundo mientras transmite en PTT; «<nombre> · hablando» con su firma y su color cuando otra persona habla; «Micrófono abierto · n/6» o «Silenciado · n/6» en micrófono abierto; «Al aire · esperando a tu grupo» si es el anfitrión y está solo; y si no «En línea · n/6», con n las personas en la malla (P75).
- AC7: CUANDO la frecu está conectando o reconectando ENTONCES el núcleo se ve al 35 %, dice «En espera» con «Conectando con el anfitrión…» o «Recuperando la conexión…», no responde al dedo ni al toque y el selector de modo no responde; si el usuario estaba transmitiendo con el dedo en el núcleo ENTONCES se llama `stopTalking`.
- AC8: CUANDO la app está en inglés ENTONCES el núcleo, el selector, la isla y el aviso muestran sus textos en inglés (p. ej. «Hold», «Hold to talk», «Online · 1/6»); CUANDO el sistema pide reducir el movimiento ENTONCES el núcleo queda quieto (sin barrido, ondas ni escala) y sigue mostrando su estado por textos, relleno y marcas.

## Diseño

Referencia: `drawPtt` y `voice` de `engine.js`; `pttZone`, `PTT_COPY`, `pttState`, `isleFor` y `roomView` de `screens.js`; `syncRoom`, `isleSync`, `startTx`, `endTx`, `setMode`, `toggleMute` y `showEcho` de `app.js`; `.ptt`, `.ptt-core`, `.ptt-hint`, `.ctrls`, `.echo` de `screens.css` e `.isle` de `ui.css`. Todo con `context.fr` y textos de slang.

- **Estado de habla e isla (`presentation/widgets/room_talk.dart`)**: el modelo, sin estado propio, y la isla:
  - `TalkLink { ready, connecting, reconnecting }`, `PttPhase { idle, alone, receiving, onAir, open, muted, connecting, reconnecting }` e `IslandPhase { online, waiting, receiving, onAir, openMic, muted, connecting, reconnecting }`.
  - `RoomTalk.from({status, mode, talking, nodes})` con los nodos de `buildMeshNodes`: `link` (`RoomStatus.reconnecting` → `reconnecting`, `connecting` → `connecting`, si no `ready`), `count` (nodos no nulos), `speaker` (el primer nodo que no es propio y está `onAir`), `alone` (un solo nodo, propio y anfitrión). `enabled` = `link == ready`.
  - `pttPhase({pressed})`: reconectando → conectando → micrófono abierto (`open` si transmite, si no `muted`) → `onAir` si transmite o `pressed` → `receiving` con `speaker` → `alone` → `idle`. `islandPhase`: reconectando → conectando → `onAir` (PTT y transmite) → `receiving` → micrófono abierto (`openMic` o `muted`) → `waiting` si `alone` → `online`.
  - `formatOnAir(Duration)` → «mm:ss».
- **Reloj al aire (`voice_provider.dart`)**: `@riverpod class OnAirClock` con `Duration?`: mira `voiceNotifierProvider.select(isTalking && talkMode == pushToTalk)`; al aire vale `Duration.zero` y un `Timer.periodic` de 1 s lo sube; si no, `null`. El temporizador se cancela en `ref.onDispose`.
- **Núcleo (`presentation/widgets/ptt_core.dart`, `PttCore`)**: `StatefulWidget` con `phase`, `onStart`, `onStop`, `onToggle`, `onAirFor`, `speakerName`, `speakerColor` y `speakerSeed`. Zona de 248 de ancho: el lienzo de 248 × 248 y debajo, separada 2, la pista en `labelS` mayúscula `tx3` (clave `ptt_core_hint`).
  - Fases de presión (`idle`, `alone`, `receiving`, `onAir`): un `Listener` (clave `ptt_button`) sobre el botón; el primer dedo llama `onStart` con `HapticFeedback.lightImpact`, el último en salir (arriba o cancelado) llama `onStop`. Mientras hay dedos se ve como `onAir`. Fases de conmutador (`open`, `muted`): un toque (clave `mic_toggle_button`) llama `onToggle`. Fases de espera: `IgnorePointer` y `Opacity` 0,35. Si la fase deja de ser de presión con dedos apoyados, se llama `onStop` y se olvidan los dedos.
  - Botón de 156: degradado radial `coreHi` → `coreLo` (centro a 30 %, hasta el 70 %), borde `line2`, filo `spec` arriba y sombra `shadow`; al aire o abierto, degradado `signalHi` → `signal` (hasta el 62 %) con halo de `signal` al 75 %. Contenido centrado con 8 de separación: ícono `FrIcons` de 34 (`mic`; `openMic` abierto; `micOff` en silencio, en `tx3`) o, al aire en PTT, el tiempo en `digits` de 26; y la etiqueta en `label` mayúscula (clave `ptt_core_label`) en `tx2`, o `signalInk` sobre la señal. Se achica a 0,94 en 160 ms al apoyar y vuelve con el resorte `organic` en 520 ms; sin escala con movimiento reducido. `Semantics` de botón «Hablar» con la etiqueta como valor.
  - Textos por fase (etiqueta / pista): reposo y anfitrión solo «Mantén» / «Mantén para hablar» o «Muestra el QR…»; recibiendo «Mantén» / «<nombre> está hablando · puedes responder»; al aire «Al aire» / «Suelta para escuchar»; abierto «Abierto» / «Toca para silenciarte»; silencio «Silencio» / «Toca para activar tu micrófono»; espera «En espera» / «Conectando con el anfitrión…» o «Recuperando la conexión…».
- **Pintor (`presentation/widgets/ptt_core_painter.dart`)**: `PttMotion` (nivel propio suavizado a 0,35 al subir y 0,12 al bajar por cuadro de 60 Hz con objetivo `max(0,12, nivel)`; nivel recibido suavizado a 0,25; ondas cada 0,42 s al aire o 0,7 s recibiendo, de 1,4 s) y `PttCorePainter` como `drawPtt`: ondas de radio 82 + 42k con ruido, 72 marcas de 113 a 118 (mayores cada 6, hasta 122) encendidas `round(72·(0,08 + 0,92·nivel))` al aire o `round(72·nivel·0,9)` recibiendo en el color activo al 95 % con brillo, barrido de 4 s en reposo y `ink` al 8 % en espera; anillo líquido de radio 94 con ruido de amplitud 3 + 9·nivel al aire, 2 + 7·nivel recibiendo y 1,3 en reposo, en el color activo al 85 % con brillo o `ink` al 16 %. El color activo es `signal` al aire y el del lugar de quien habla al recibir. Un `FrLoop` lo repinta; con movimiento reducido pinta un cuadro fijo.
- **Controles (`mic_control_section.dart`, `MicControlSection`)**: recibe `voiceState` y `talk`. Fila de 52 con relleno horizontal 20 y el `FrSegmented<TalkMode>` centrado de hasta 204 px: «PTT» con `FrIcons.walkie` (clave `mode_ptt`) y «Abierto» con `FrIcons.openMic` (clave `mode_open_mic`); sin `onChanged` si `talk.enabled` es falso. Debajo, con 8 de separación, `PttCore` con la fase de `talk`, el tiempo de `onAirClockProvider` y quien habla. `EchoNotice` (en el mismo archivo): `FrBanner` ámbar flotante con cierre, que entra y sale fundido; recuerda que se cerró hasta que deja de ser visible.
- **Isla (en `room_talk.dart`, `RoomStatusIsland`)**: alto 44 con relleno superior 4 y la `StatusIsland` centrada: `reconnecting`, `connecting`, `onAir` (con `formatOnAir`), `receiving` (nombre y `meshNodeColor(FrColors.dark, speaker)`) u `online` con el texto de cada fase y `count`/6.
- **Página (`room_page.dart`)**: guarda los lugares (`assignMeshSlots`) y arma `RoomTalk` en cada `build`. Columna: `RoomStatusIsland` (en un `Consumer` del reloj), `RoomHeader`, `Expanded` con la malla centrada y `EchoNotice` arriba (izquierda y derecha 14), y `MicControlSection` con relleno inferior 16. Al entrar: `initialize()` y luego el modo por defecto (A2). `PttButton` deja de usarse.
- **Textos (`lib/i18n`, dentro de `room.talk`)**: `modePtt`, `modeOpen`, `core` (`hold`, `onAir`, `open`, `silence`, `standby`, `talk`), `hint` (`idle`, `alone`, `receiving` con `$name`, `onAir`, `open`, `muted`, `connecting`, `reconnecting`), `island` (`online`, `openMic` y `muted` con `$count` y `$max`, `onAir` con `$time`, `receiving` con `$name`, `waiting`, `connecting`, `reconnecting`) y `echo` (`title`, `message`, `dismiss`), en `es` y `en`. Se regenera con `dart run slang`.
- **Pruebas**: `room_talk_test.dart` prueba el modelo y la isla; `ptt_core_test.dart`, el núcleo en un `MaterialApp` con `AppTheme`; `talk_flow_test.dart`, la página dentro de `FrecuApp` con repositorios simulados. Todas con movimiento reducido (o `pump` con duración) para que `pumpAndSettle` termine; inglés con `tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en))`. `voice_flow_test.dart` cambia solo las búsquedas del núcleo nuevo, e `invite_qr_dialog_test.dart` suma movimiento reducido y la respuesta de `setTalkMode`, porque el núcleo anima en reposo y la página aplica el modo por defecto.

## Archivos

- crear lib/features/room/presentation/widgets/room_talk.dart — fases del núcleo y de la isla, quién habla, cuántos son, formato del tiempo al aire e isla de estado con n/6.
- crear lib/features/room/presentation/widgets/ptt_core.dart — núcleo PTT con presión, conmutador, espera, textos e íconos.
- crear lib/features/room/presentation/widgets/ptt_core_painter.dart — bisel VU, anillo líquido, ondas y su movimiento.
- modificar lib/features/room/presentation/widgets/mic_control_section.dart — selector de modo de Portadora, núcleo y aviso de eco.
- modificar lib/features/room/presentation/providers/voice_provider.dart — reloj del tiempo al aire.
- modificar lib/features/room/presentation/pages/room_page.dart — isla, aviso de eco, estado de habla y modo por defecto al entrar.
- modificar lib/i18n/strings.i18n.json — textos del núcleo, el selector, la isla y el aviso en español (los `.g.dart` se regeneran con `dart run slang`).
- modificar lib/i18n/strings_en.i18n.json — los mismos textos en inglés.
- crear test/features/room/presentation/room_talk_test.dart — fases, prioridad, quién habla, n, tiempo al aire e isla.
- crear test/features/room/presentation/ptt_core_test.dart — presión, varios dedos, conmutador, espera, textos, colores y movimiento reducido del núcleo.
- crear test/features/room/presentation/talk_flow_test.dart — isla, selector, aviso de eco, modo por defecto, espera e inglés en la frecu activa.
- modificar test/features/room/presentation/voice_flow_test.dart — búsquedas del núcleo nuevo en lugar del botón y la tarjeta de Material.
- modificar test/features/room/presentation/invite_qr_dialog_test.dart — movimiento reducido y respuesta de `setTalkMode`.

## Tareas

- [ ] T1: Estado de habla e isla de estado
  - files: lib/features/room/presentation/widgets/room_talk.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, test/features/room/presentation/room_talk_test.dart
  - ac: AC2, AC6, AC7
  - verify: flutter test test/features/room/presentation/room_talk_test.dart
- [ ] T2: Núcleo PTT con bisel VU, anillo y textos
  - files: lib/features/room/presentation/widgets/ptt_core.dart, lib/features/room/presentation/widgets/ptt_core_painter.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, test/features/room/presentation/ptt_core_test.dart
  - ac: AC1, AC2, AC3, AC7, AC8
  - verify: flutter test test/features/room/presentation/ptt_core_test.dart
- [ ] T3: Isla, selector, aviso de eco y modo por defecto en la frecu activa
  - files: lib/features/room/presentation/widgets/mic_control_section.dart, lib/features/room/presentation/providers/voice_provider.dart, lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/talk_flow_test.dart, test/features/room/presentation/voice_flow_test.dart, test/features/room/presentation/invite_qr_dialog_test.dart
  - ac: AC1, AC3, AC4, AC5, AC6, AC7, AC8
  - verify: flutter analyze && flutter test test/features/room test/features/lobby

## Riesgos

- R1: Un ticker más (el núcleo) junto a la malla y sus firmas en un Android de gama media (A1 de la épica) — mitigación: `RepaintBoundary` en el pintor, un solo `FrLoop` y el perfilado pendiente de P33.
- R2: C19 rehace la cabecera y la fila de controles — mitigación: el núcleo, la isla y el aviso quedan en widgets separados y la fila deja el sitio de la pastilla de ruta.
- R3: C16 y C17 tocan `lib/i18n` en paralelo — mitigación: las claves nuevas van dentro de `room.talk` y, si hay conflicto en los generados, se regeneran con `dart run slang`.
