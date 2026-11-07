---
kind: epic
---

# Sistema de diseño Portadora y pantallas de la app

## Objetivo

Reemplazar la interfaz Material genérica por el sistema de diseño "Portadora" aprobado en el prototipo (`docs/diseno/prototipo/index.html`): tokens propios en tema claro y oscuro, widgets con animaciones orgánicas y todas las pantallas rediseñadas. Además, cada frecu tendrá una nota musical calculada con su hora de apertura que sirve de canal reconocible en voz alta ("estamos en Mi").

## Fuera de alcance

- Diapasón al entrar (que el teléfono suene la nota de la frecu al unirse): queda como idea opcional del prototipo.
- Lógica de heartbeats, reconexión y servicio en primer plano: la lleva la épica "Segundo plano y resiliencia"; aquí solo se dibujan los estados que ya existen en `RoomStatus`.
- Paquetes de animación externos (Lottie, Rive) y fuentes descargadas en ejecución (`google_fonts`).
- Idiomas nuevos: se mantienen `es` como base y `en` como secundario.
- Rediseño de la notificación del servicio en primer plano.

## Supuestos

- A1: `CustomPainter` con un `Ticker` por pantalla dibuja la malla, el núcleo PTT, el sintonizador y las firmas a 60 fps en un Android de gama media.
  - impacto: alto
- A2: La nota viaja como dato aditivo: clave `n` en el TXT de mDNS y parámetro `n` en el QR, con el semitono desde Do4 (0–23). Los teléfonos que no la traen siguen funcionando, así que la versión del protocolo (`v=1`) no cambia.
  - impacto: alto
- A3: La hora usada para la nota es la hora local del teléfono anfitrión al abrir la frecu; el anfitrión calcula la nota una vez y la publica, y los demás nunca la recalculan.
- A4: `shared_preferences` es aceptable como dependencia nueva para guardar el nombre, el modo de habla por defecto y el tema.
- A5: Archivo, Martian Mono y Doto tienen licencia OFL y pueden empaquetarse como assets de la app.
- A6: La firma de Lissajous de cada persona sale de un hash estable de su nombre, idéntica en todos los teléfonos sin enviar nada nuevo por la red.
- A7: En tema claro el verde de señal (#C4E05C, el mismo de noche) no se usa como letra: `signalFg` es tinta y el verde queda para rellenos, halos y marcatexto, tal como en el prototipo.

## Criterios de aceptación

- AC1: CUANDO el usuario elige Auto, Claro u Oscuro en Ajustes ENTONCES toda la app cambia de tema al instante con los tokens de Portadora, Auto sigue al sistema y la elección se conserva al reabrir la app.
- AC2: CUANDO la app se usa sin conexión a internet ENTONCES las tipografías Archivo, Martian Mono y Doto y los íconos propios se cargan desde assets locales.
- AC3: CUANDO la app se abre por primera vez ENTONCES muestra la bienvenida, pide el nombre una sola vez y luego los permisos; en las aperturas siguientes va directo al inicio, usa ese nombre al crear o unirse a una frecu y permite cambiarlo en Ajustes.
- AC4: CUANDO se abre una frecu ENTONCES su nota se calcula con la hora de apertura sobre el círculo de quintas (12→Do, 1→Sol, 2→Re, 3→La, 4→Mi, 5→Si, 6→Fa♯, 7→Re♭, 8→La♭, 9→Mi♭, 10→Si♭, 11→Fa), en octava 4 de 0 a 11 h y en octava 5 de 12 a 23 h, con su frecuencia en Hz (La4 = 440 Hz, temperamento igual); si una frecu cercana ya usa esa nota y octava, avanza a la siguiente quinta libre.
- AC5: CUANDO un teléfono descubre una frecu por mDNS o escanea su QR ENTONCES muestra la misma nota y frecuencia que el anfitrión; si la invitación no trae nota, la frecu aparece sin nota y la unión funciona igual.
- AC6: CUANDO el usuario está en el inicio ENTONCES ve el sintonizador de dos octavas con un pico por frecu cercana sobre la tecla de su nota, la lista de frecus con nota y Hz, los estados de búsqueda vacía y sin red, y puede unirse por código de acceso, QR o IP, o crear una frecu con el reloj de quintas.
- AC7: CUANDO el usuario está en una frecu activa ENTONCES ve la malla hexagonal de 6 lugares con la firma de cada persona y quién habla, el núcleo PTT con VU circular, la isla de estado (al aire, recibiendo, reconectando) y las hojas de invitación, ruta de audio y salir, sin perder el PTT, el micrófono abierto ni el ruteo de audio actuales.
- AC8: CUANDO el sistema pide reducir el movimiento ENTONCES las animaciones orgánicas se detienen o se cambian por fundidos sin ocultar ningún estado.

## Diseño

Referencia visual y de comportamiento: `docs/diseno/prototipo/index.html` (secciones 02 a 11, en especial "Paso a Flutter"). Cada corte replica allí sus pantallas y componentes.

- **Tokens (`lib/core/design/`)**: `ThemeExtension` `FrColors`, `FrType`, `FrSpace`, `FrRadii` y `FrMotion` con acceso por `context.fr`. `AppTheme.light` y `AppTheme.dark` se construyen desde los mismos tokens. Los resortes `press` (600/0.62), `flow` (220/0.9) y `organic` (160/0.5) se implementan con `SpringSimulation`.
- **Preferencias (`features/settings`)**: `PreferencesRepository` en `domain` (Dart puro) con nombre, modo de habla por defecto y modo de tema. Implementación con `shared_preferences` en `data` y providers `@riverpod` (`Notifier`/`AsyncNotifier`).
- **Widgets base (`lib/core/design/widgets/`)**: `FrButton`, `FrIconButton`, `FrField`, `FrPinField` + `FrKeypad`, `FrSegmented`, `FrToggle`, `FrPill`, `FrTag`, `FrBanner`, `FrToast`, `FrSheet`, `StatusIsland`, `WaveLoader`, `SignalSignature`, íconos `FrIcons` y las transiciones onda, deslizamiento, hoja y expansión (`CustomRoute` de auto_route).
- **Nota (`features/room/domain`)**: entidad `RoomNote` (nombre, octava, clase de altura, semitono, Hz) y caso de uso puro `AssignRoomNote(createdAt, notasCercanas)` con pruebas de las 24 posiciones y de los choques. `Room`, `NearbyRoom` y `RoomInvite` suman una nota opcional. `MdnsDataSource` publica y lee `n`, y `BuildInviteQr`/`ParseInviteFromQr` agregan y leen `n`. Se actualiza `docs/protocolo.md`.
- **Pantallas**: bienvenida, nombre y permisos (C2); inicio con sintonizador, hojas de código e IP, escáner, guía de punto de acceso y nueva frecu (C3); frecu activa, cierre y Ajustes completos (C4). Todo el texto sale de slang (`t.<clave>`), con pantallas `@RoutePage()`.

## Cortes

- C1: Tokens, tema claro y oscuro y tipografías
  - ac: AC1, AC2
- C2: Widgets base, bienvenida y nombre una sola vez
  - ac: AC3, AC8
  - depends: C1
- C3: Inicio y unión con la nota de cada frecu
  - ac: AC4, AC5, AC6
  - depends: C2
- C4: Frecu activa
  - ac: AC7
  - depends: C3

## Riesgos

- R1: Rendimiento de los pintores animados en teléfonos de gama media — mitigación: un `Ticker` por pantalla, `RepaintBoundary`, pausa fuera de pantalla y perfilado en un dispositivo real en C2.
- R2: Choque con la épica abierta "Segundo plano y resiliencia", cuyo cambio "Heartbeats, reconexión con backoff y cierre de frecu" toca `RoomPage` y `room_provider` — mitigación: C4 empieza cuando ese cambio se cierre y dibuja sus estados `reconnecting` y `closed` en la isla de estado.
- R3: Peso de las fuentes variables — mitigación: incluir solo los ejes y rangos usados y revisar el tamaño del APK en C1.
- R4: Contraste del verde en tema claro — mitigación: `signalFg` en tinta de día y una prueba que verifique el contraste mínimo de los pares texto/fondo de ambos temas.
