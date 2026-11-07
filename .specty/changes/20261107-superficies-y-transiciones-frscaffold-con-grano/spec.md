---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C10
---

# Superficies y transiciones: `FrScaffold` con grano y retícula, `FrSheet`, `FrBanner`, `FrToast`, `StatusIsland` y transiciones onda, deslizamiento, hoja y expansión

## Objetivo

Crear en `lib/core/design/` las superficies de Portadora que usarán las pantallas (`FrScaffold` con retícula y grano, la hoja `FrSheet`, los avisos `FrBanner` y `FrToast` y la isla de estado `StatusIsland`) y las transiciones onda, deslizamiento, hoja y expansión del prototipo aprobado (`docs/diseno/prototipo/`), con su versión de fundido cuando el sistema pide reducir el movimiento (AC8 de la épica).

## Fuera de alcance

- Conectar las transiciones al router (`lib/app/router/`) y usar estas superficies en las pantallas: en los cortes de pantallas (C4, C12, C15 a C19).
- Decidir qué muestra la isla según `RoomStatus` y el estado de habla: C18; aquí la isla recibe su estado y su texto.
- Arrastrar la hoja para cerrarla y el gesto de volver predictivo de Android.
- Íconos `FrIcons` (C11): mientras tanto los widgets reciben cualquier `IconData`; el cierre del aviso usa `Icons.close_rounded` por defecto y se puede cambiar.
- Hápticos.
- `docs/arquitectura.md` y otros archivos compartidos: los archivos nuevos van en `core/design/motion/` y `core/design/widgets/`, que ya están documentadas.

## Supuestos

- A1: `ModalRoute.delegatedTransition` (Flutter 3.47) deja que la ruta que entra decida cómo se aparta la de abajo, también si la de abajo es una página de auto_route, así que la pantalla de abajo se aleja bajo la hoja y se corre o se encoge con deslizamiento y onda sin tocar el router.
  - impacto: alto
- A2: El grano se pinta bajo el contenido con la tinta `ink` al 5 % en mezcla normal, no encima de todo con `mix-blend-mode: overlay`: sobre el grafito, el `overlay` al 4,5 % casi no se ve y, sobre contenido animado (firmas, malla), obligaría a una mezcla de pantalla completa en cada cuadro (R1 de la épica).
  - impacto: alto
- A3: El origen de la onda es el último toque registrado por `FrScaffold` (las páginas ocupan toda la pantalla); sin toque, sale de abajo al centro (195, 640 de 390 × 844, como el prototipo).
- A4: Los widgets no llevan texto propio: títulos, mensajes y etiquetas accesibles llegan de quien los usa (slang); la etiqueta del velo de la hoja usa `MaterialLocalizations.modalBarrierDismissLabel` si no se da otra.

## Criterios de aceptación

- AC1: CUANDO una pantalla usa `FrScaffold` ENTONCES se pinta sobre `bg0` con la retícula de puntos cada 22 px en tinta al 6 % que se desvanece hacia el 55 % del alto y con un grano generado por código (mosaico de 128 px de ruido sembrado, igual en cada arranque y creado una sola vez), en tema claro y oscuro y sin assets.
- AC2: CUANDO se abre una hoja con `showFrSheet` ENTONCES el velo `scrim` aparece desenfocando el fondo, la `FrSheet` (radio 40, asa, título, mensaje y contenido) sube desde abajo con el resorte `flow` y la pantalla de abajo se aleja (escala 0,93) y se oscurece; al tocar el velo o volver, la hoja baja, el velo se va y la pantalla de abajo vuelve a su lugar.
- AC3: CUANDO se navega con las transiciones de Portadora ENTONCES onda revela la pantalla nueva en un círculo que crece desde el último toque con un aro de señal en 760 ms mientras la anterior se encoge y se oscurece; deslizamiento la trae desde la derecha en 560 ms mientras la anterior se corre al −28 % y se oscurece; expansión hace crecer la superficie de la hoja desde su rectángulo hasta ocupar la pantalla y luego funde la pantalla nueva; y volver desliza la pantalla hacia la derecha.
- AC4: CUANDO se muestra un `FrBanner` ENTONCES lleva el tono de aviso, alerta o info (lavado y borde del color, ícono, título en negrita, mensaje y acción subrayada) y, al tocar cerrar, se funde subiendo 6 px y luego llama a `onDismiss`; y CUANDO se muestra un `FrToast` con `showFrToast` ENTONCES es una píldora de 46 px con la firma o el ícono que entra subiendo, se va sola al terminar su duración y uno nuevo reemplaza al anterior.
- AC5: CUANDO la isla de estado muestra en línea, al aire, recibiendo, reconectando, conectando o un evento ENTONCES es una cápsula de 36 px siempre oscura (también en tema claro): al aire con relleno de señal y punto que parpadea, recibiendo con la firma y el nombre en el color de la persona, reconectando en ámbar con punto que parpadea y conectando con la onda; cambia de ancho con el resorte `organic`, el contenido nuevo entra fundido y subiendo, y su texto se anuncia a la accesibilidad.
- AC6: CUANDO el sistema pide reducir el movimiento ENTONCES onda, deslizamiento, expansión y hoja pasan a un fundido de 280 ms sin desplazamientos ni escalas, la pantalla de abajo no se aleja, la isla cambia sin resorte y su punto no parpadea, el aviso y el toast solo se funden, y ningún estado ni texto se oculta.

## Diseño

- **Transiciones (`lib/core/design/motion/fr_transitions.dart`)**:
  - `FrTransition` (`wave`, `slide`, `expand`, `fade`) y `FrTransitions`, con un `RouteTransitionsBuilder` por tipo (sirven directo en `CustomRoute(transitionsBuilder: …)` de auto_route) y sus duraciones: onda 760 ms (`easeOut`), deslizamiento 560 ms (`FrSpringCurve(springFlow)`), expansión 1100 ms (la superficie crece en los primeros 620 ms con `springFlow` y la pantalla entra en los últimos 520 ms desde escala 0,97), fundido 620 ms y volver 520 ms. Cada constructor aplica también su efecto de salida a la pantalla que queda abajo (`secondaryAnimation`).
  - Onda: `ClipPath` circular desde el origen hasta la esquina más lejana + 20 px, la pantalla nueva de escala 1,08 a 1 y un aro de señal (trazo de 1,5 px al 85 % y halo al 30 %) que se apaga; la anterior baja a escala 0,9 y se oscurece al 35 % de brillo. El brillo 1,5 de la pantalla nueva del prototipo se omite (filtro de color de pantalla completa).
  - `FrPageRoute<T>` (`PageRoute`): recibe el tipo, el `builder`, `settings` (puede ser la `Page` de auto_route vía `customRouteBuilder`), el origen de la onda y el rectángulo de la expansión; expone `delegatedTransition` para que la pantalla de abajo use el efecto de salida de la ruta que entra. Con movimiento reducido (`MediaQuery` del navegador al instalarse) dura 280 ms y todos los tipos son fundido.
  - `FrTouchOrigin`: guarda la posición global del último toque (lo registra `FrScaffold` con un `Listener` translúcido).
  - Al volver (animación en reversa), onda, expansión y deslizamiento sacan la pantalla hacia la derecha con `springFlow`, como el "atrás" del prototipo.
  - El oscurecimiento es un velo negro pintado encima (`foregroundPainter`), no un filtro, y la estructura de widgets no cambia durante la transición para no perder el estado de la pantalla.
- **Superficies (`lib/core/design/widgets/`)**, todas con `context.fr` y sin colores sueltos:
  - `fr_scaffold.dart`: `FrScaffold` sobre `Scaffold` de Material (`bg0`, `resizeToAvoidBottomInset`), con un fondo en `RepaintBoundary` que pinta la retícula (puntos de 1,15 px cada 22 px en `ink` al 6 %, desvanecidos hasta el 55 % del alto) y el grano, y un `dock` opcional abajo con el degradado de `bg0` del prototipo. `FrGrain`: alfas de 128 × 128 px con `FrRandom` (semilla fija) pintadas una vez en una imagen blanca (`Picture.toImageSync`) y cacheadas; se dibuja en mosaico con `ImageShader` teñido de `ink` al 5 %.
  - `fr_sheet.dart`: `FrSheet` (margen 8 px, radio `sheet` 40, relleno 10/20/22, degradado `sheetA`→`sheetB` al 30 %, borde `line2`, filo `spec`, sombra `shadow`, asa de 38 × 5 en `bg4`, título `titleL`, mensaje `body` en `tx2`, `trailing` opcional, separación de 18 px y espacio para el teclado). `FrSheetRoute<T>` (`PageRoute` no opaca, velo descartable): velo `scrim` con desenfoque de 6 px que entra en 320 ms y sale en 280 ms; la hoja sube desde 105 % con `SpringSimulation(springFlow)` y baja en 400 ms con `Cubic(.4, 0, 1, 1)`; `delegatedTransition` aleja la pantalla de abajo (escala 0,93, 10 px abajo, brillo 0,55 y radio 46). `showFrSheet` la empuja en el navegador más cercano.
  - `fr_banner.dart`: `FrBanner` con `FrBannerTone.warn`/`alert`/`info` (lavado 8 % y borde 30–32 % del tono; info en `bg1` con `line1`), ícono de 18 px, `title` en negrita y `message` (`bodyS`), acción subrayada en `tx1` con línea `line3`, cierre en `tx3` con etiqueta accesible obligatoria y variante `floating` (sobre `bg1` con sombra, para el aviso de eco). Al cerrar se funde subiendo 6 px en 240 ms y luego llama a `onDismiss`.
  - `fr_toast.dart`: `FrToast` (46 px, radio 23, relleno 0/16/0/8, `bg3`, borde `line2`, filo `spec`, sombra; texto `body`), con `FrToast.signature` (firma de 30 px hablando con nivel de voz simulado) o `FrToast.icon` (círculo de 30 px con señal al 14 % y el ícono en `signalFg`). `showFrToast` lo pone en el `Overlay` abajo al centro: entra en 600 ms subiendo 18 px desde escala 0,98 con `springFlow`, se queda 2,6 s por defecto y sale fundido en 240 ms; uno nuevo reemplaza al anterior.
  - `status_island.dart`: `StatusIsland` con `StatusIslandTone.neutral`/`onAir`/`warn` y constructores `online`, `onAir`, `receiving`, `reconnecting`, `connecting` y `event`. Usa siempre `FrColors.dark`: fondo `shadow` (negro), borde `line2` y sombra; al aire en `signal` con texto `signalInk` y halo; reconectando con borde y halo `warn`. El punto de 7 px parpadea con `FrLoop` (0,8 s al aire, 1 s reconectando). El ancho cambia con `AnimatedSize` y `FrSpringCurve(springOrganic)` en 640 ms y el contenido nuevo entra en 420 ms (fundido y 6 px). `Semantics(liveRegion: true)` con el texto.

## Archivos

- crear lib/core/design/motion/fr_transitions.dart — transiciones onda, deslizamiento, expansión y fundido, `FrPageRoute` y origen del toque.
- crear lib/core/design/widgets/fr_scaffold.dart — `FrScaffold` con retícula, grano y dock.
- crear lib/core/design/widgets/fr_sheet.dart — `FrSheet`, `FrSheetRoute` y `showFrSheet`.
- crear lib/core/design/widgets/fr_banner.dart — aviso contextual.
- crear lib/core/design/widgets/fr_toast.dart — toast y `showFrToast`.
- crear lib/core/design/widgets/status_island.dart — isla de estado.
- crear test/core/design/motion/fr_transitions_test.dart — onda, deslizamiento, expansión, volver y fundido con movimiento reducido.
- crear test/core/design/widgets/fr_scaffold_test.dart — fondo, retícula, grano cacheado y determinista y dock.
- crear test/core/design/widgets/fr_sheet_test.dart — hoja, velo, fondo que se aleja, cierre y movimiento reducido.
- crear test/core/design/widgets/fr_notices_test.dart — aviso, toast e isla de estado.

## Tareas

- [x] T1: Transiciones onda, deslizamiento, expansión y fundido
  - files: lib/core/design/motion/fr_transitions.dart, test/core/design/motion/fr_transitions_test.dart
  - ac: AC3, AC6
  - verify: flutter test test/core/design/motion/fr_transitions_test.dart
- [x] T2: `FrScaffold` con retícula y grano
  - files: lib/core/design/widgets/fr_scaffold.dart, test/core/design/widgets/fr_scaffold_test.dart
  - ac: AC1
  - verify: flutter test test/core/design/widgets/fr_scaffold_test.dart
- [x] T3: Hoja elástica con velo
  - files: lib/core/design/widgets/fr_sheet.dart, test/core/design/widgets/fr_sheet_test.dart
  - ac: AC2, AC6
  - verify: flutter test test/core/design/widgets/fr_sheet_test.dart
- [x] T4: Aviso, toast e isla de estado
  - files: lib/core/design/widgets/fr_banner.dart, lib/core/design/widgets/fr_toast.dart, lib/core/design/widgets/status_island.dart, test/core/design/widgets/fr_notices_test.dart
  - ac: AC4, AC5, AC6
  - verify: flutter analyze && flutter test

## Riesgos

- R1: El desenfoque del velo y el recorte circular de la onda cuestan en un Android de gama media — mitigación: el recorte se quita (`Clip.none`) al terminar, el oscurecimiento es un velo pintado y el perfilado en un teléfono real queda para la persona (R1 de la épica).
- R2: `Picture.toImageSync` en las pruebas de widgets — mitigación: la tabla de alfas del grano es una función pura probada aparte y la imagen se crea perezosamente una sola vez.
- R3: C9 y C11 crean archivos en `lib/core/design/widgets/` en paralelo — mitigación: este corte solo crea archivos nuevos con nombres propios y no toca archivos existentes.
