---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C1
---

# Tokens, tema claro y oscuro y tipografías

## Objetivo

Sustituir el tema Material genérico (semilla teal) por los tokens de Portadora del prototipo aprobado (`docs/diseno/prototipo/base.css`): colores de noche y día con un solo verde de señal (#C4E05C), escala tipográfica de Archivo, Martian Mono y Doto, espacio, radios y movimiento, leídos con `context.fr`. La app pasa a verse con Portadora en claro y en oscuro, siguiendo el tema del sistema.

## Fuera de alcance

- Empaquetar los archivos de fuente en `assets/fonts/` y declararlos en `pubspec.yaml`: corte nuevo de la épica (supera el límite de módulos de este).
- Elegir Auto, Claro u Oscuro en Ajustes y guardar la elección (`shared_preferences`, `app.dart`, `bootstrap.dart`, slang): cortes nuevos de la épica.
- Íconos propios `FrIcons`, widgets `Fr*`, `FrScaffold` con grano y retícula, sombras y niveles de luz (`FrElevation`) y transiciones propias (C2).
- Rediseño de pantallas existentes: solo heredan el nuevo tema.
- Movimiento reducido (AC8 de la épica, en C2).

## Supuestos

- A1: Mientras las fuentes no estén empaquetadas, Flutter dibuja las familias `Archivo`, `Martian Mono` y `Doto` con la fuente del sistema, sin errores; el corte de fuentes solo añade los assets.
- A2: Flutter solo mueve los ejes de una fuente variable con `fontVariations`; cada estilo de `FrType` declara `fontWeight` (el peso nombrado más cercano) y `FontVariation` de `wght`, `wdth` y, en Doto, `ROND`. Las mayúsculas de las etiquetas (`text-transform` en CSS) las aplica el widget, porque `TextStyle` no las tiene.
- A3: Espacio, radios y movimiento son iguales en ambos temas; aun así son `ThemeExtension` para leerlos todos igual con `context.fr`.
- A4: Hasta que exista la preferencia guardada, la app sigue el tema del sistema (`ThemeMode.system`, el valor por defecto que ya usa `app.dart`).

## Criterios de aceptación

- AC1: CUANDO el sistema está en modo oscuro o claro ENTONCES la app usa el tema Portadora correspondiente: fondo `bg0`, texto `tx1`, `ColorScheme` y componentes Material construidos desde los tokens, y señal #C4E05C en ambos.
- AC2: CUANDO un widget lee `context.fr` ENTONCES obtiene los colores, la tipografía, el espacio, los radios y el movimiento del tema activo.
- AC3: CUANDO se comparan los pares de texto y fondo de ambos temas ENTONCES `tx1`, `tx2`, `tx3` y `signalFg` sobre `bg0`, `bg1` y `bg2` tienen contraste ≥ 4,5:1, `signalInk` sobre `signal` también, los canales de participantes ≥ 3:1, y de día `signalFg` es tinta (#0C0F0D) mientras el verde queda para rellenos, halos y marcatexto.
- AC4: CUANDO un texto usa los estilos del tema ENTONCES lleva la familia (Archivo, Martian Mono o Doto), el tamaño, el interlineado, el espaciado y los ejes variables (`wght`, `wdth`, `ROND`) de la escala del prototipo.

## Diseño

- **Colores (`FrColors`)**: `ThemeExtension` inmutable con `copyWith` y `lerp`. `FrColors.dark` y `FrColors.light` copian los bloques `:root, [data-theme="dark"]` y `[data-theme="light"]` de `base.css`: `bg0`–`bg4`, `line1`–`line3`, `spec`, `tx1`–`tx4`, `signal`, `signalInk`, `signalFg`, `signalHi`, `signalMark` (nulo de noche; verde de día, para el marcatexto), `ledRing` (nulo de noche; tinta de día), `ink`, `washK`, `warn`, `alert`, `warnTx`, `alertTx`, `scrim`, `sheetA`, `sheetB`, `coreHi`, `coreLo`, `touch`, `shadow` y los canales `p1`–`p5`.
- **Tipografía (`FrType`, `FrFonts`)**: `FrFonts` nombra las familias `Archivo`, `Martian Mono` y `Doto`. `FrType` trae `display`, `titleL`, `title`, `bodyL`, `body`, `bodyS`, `label`, `labelS`, `data`, `digits` y `button` con los tamaños, interlineados, anchos y espaciados de la escala del prototipo (em convertidos a px).
- **Espacio, forma y movimiento**: `FrSpace` (s1 4 … s18 72), `FrRadii` (xs 6, s 10, m 16, btn 18, l 24, xl 32, sheet 40), `FrMotion` con duraciones (instant 90, quick 160, smooth 280, flow 460, breath 4200 ms), curvas (`out`, `inOut`, `in`, `sheet`) y resortes `press` (600/0,62), `flow` (220/0,9) y `organic` (160/0,5) como `SpringDescription.withDampingRatio`.
- **Acceso**: `lib/core/design/fr_theme.dart` define `FrTheme` (agrupa las cinco extensiones) y la extensión `context.fr`.
- **Tema (`lib/app/theme/app_theme.dart`)**: `AppTheme.light` y `AppTheme.dark` salen de un único constructor que recibe `FrColors` y registra las cinco extensiones. `ColorScheme` desde los tokens (`primary` = `signal`, `onPrimary` = `signalInk`, superficies `bg0`–`bg3`, `outline` = `line2`, `error` = `alert`); `TextTheme` desde `FrType`; botones, campos, segmentado, listas, hojas, diálogos, avisos, interruptores y divisores sobrescritos con `RoundedSuperellipseBorder` y `FrRadii`. Todo lo que usa la señal como letra (botón de texto, foco, cursor, selección) usa `signalFg`, para que de día no aparezca verde sobre blanco.

## Archivos

- crear lib/core/design/tokens/fr_colors.dart — colores de noche y día.
- crear lib/core/design/tokens/fr_type.dart — familias y escala tipográfica con ejes variables.
- crear lib/core/design/tokens/fr_space.dart — espaciado base 4.
- crear lib/core/design/tokens/fr_radii.dart — radios.
- crear lib/core/design/tokens/fr_motion.dart — duraciones, curvas y resortes.
- crear lib/core/design/fr_theme.dart — `FrTheme` y `context.fr`.
- modificar lib/app/theme/app_theme.dart — temas claro y oscuro desde los tokens.
- modificar docs/arquitectura.md — carpeta `core/design/` en la estructura.
- crear test/core/design/fr_colors_test.dart — contraste de los pares de ambos temas.
- crear test/core/design/fr_tokens_test.dart — escala tipográfica, espacio, radios, movimiento y `lerp`.
- crear test/app/theme/app_theme_test.dart — temas, `context.fr` y la app siguiendo el tema del sistema.

## Tareas

- [x] T1: Colores de noche y día con contraste verificado
  - files: lib/core/design/tokens/fr_colors.dart, test/core/design/fr_colors_test.dart
  - ac: AC3
  - verify: flutter test test/core/design/fr_colors_test.dart
- [x] T2: Escala tipográfica, espacio, radios y movimiento
  - files: lib/core/design/tokens/fr_type.dart, lib/core/design/tokens/fr_space.dart, lib/core/design/tokens/fr_radii.dart, lib/core/design/tokens/fr_motion.dart, test/core/design/fr_tokens_test.dart
  - ac: AC4
  - verify: flutter test test/core/design/fr_tokens_test.dart
- [x] T3: AppTheme claro y oscuro desde los tokens y acceso con `context.fr`
  - files: lib/core/design/fr_theme.dart, lib/app/theme/app_theme.dart, docs/arquitectura.md, test/app/theme/app_theme_test.dart
  - ac: AC1, AC2, AC4
  - verify: flutter test

## Riesgos

- R1: Componentes Material que pintan texto con `primary` dejarían verde ilegible de día — mitigación: sobrescribir esos temas con `signalFg` y comprobarlo en `app_theme_test.dart`.
- R2: Las pruebas de widgets existentes podrían depender del aspecto Material anterior — mitigación: la verificación de T3 corre toda la suite.

## Cierre

### Resumen

- `lib/core/design/tokens/`: `FrColors` (noche y día de `base.css`, un solo verde #C4E05C, `signalFg` en tinta de día, canales `p1`–`p5`), `FrType` (Archivo, Martian Mono y Doto con ejes `wght`, `wdth` y `ROND`), `FrSpace`, `FrRadii` y `FrMotion` (duraciones, curvas y resortes `press`, `flow` y `organic`), todos `ThemeExtension`.
- `lib/core/design/fr_theme.dart`: `FrTheme` y `context.fr`.
- `AppTheme.light` y `AppTheme.dark` salen de los mismos tokens: `ColorScheme`, `TextTheme` y componentes Material (botones, segmentado, campos, tarjetas, listas, hojas, diálogos, avisos, chips, interruptores y progreso) con `RoundedSuperellipseBorder`. La app sigue el tema del sistema.
- Verificado: `flutter analyze` sin avisos y `flutter test` completo en verde (85 tests), con contraste ≥ 4,5:1 de los pares de texto en ambos temas.

### Desviaciones

- El corte se estrechó: la primera versión superaba el límite de Specty (8 módulos, máximo 2). Las fuentes en `assets/fonts/`, la preferencia de tema con `shared_preferences`, su aplicación en `app.dart`/`bootstrap.dart` y el selector en Ajustes quedan para cortes nuevos de la épica (mensaje dejado a la épica; memoria P21).
- `FrType` usa el peso exacto (`FontWeight(720)`, etc.) y no el nombrado más cercano (A2): en Flutter 3.47 `FontWeight` admite cualquier valor y mueve el eje `wght`. Además declara `FontVariation.weight`.
- `copyWith` y `lerp` de las extensiones recorren los tokens en orden (`_values`), con tablas `// dart format off`, para cumplir los límites de líneas (50) y complejidad (10) por función.
- `FrColors.lerp` devuelve el juego destino exacto en t = 1, porque `Color.lerp(x, null, 1)` deja un color transparente en `signalMark` y `ledRing`; lo cubre el test nuevo `test/core/design/fr_colors_order_test.dart` (ampliación de alcance en T2).
- Desbloqueo S1: se quitó una importación innecesaria de `test/core/design/fr_tokens_test.dart` que marcaba `flutter analyze`; no cambió ninguna aserción.

### Decisiones

- `primary` = `signal` (relleno) y todo lo que usa la señal como letra (botón de texto, cursor, selección, progreso, acción de aviso) usa `signalFg`. El borde de foco de los campos es `ledRing` de día (tinta) y `signal` de noche.
- Botones con alto mínimo de 56 dp; el segmentado seleccionado usa `bg3`/`tx1`, como el pulgar `.seg-thumb` del prototipo.
- `FrMotion.standard` es `static final` porque `SpringDescription.withDampingRatio` no es constante.
- `FrTheme.of` usa los tokens de Portadora según el brillo si un tema no registra las extensiones.

### Pendientes

- Cortes nuevos de la épica para fuentes empaquetadas, preferencia de tema guardada, tema guardado al arrancar y selector en Ajustes (P21).
- De día, las pantallas actuales que pintan iconos o bordes con `colorScheme.primary` (`mic_control_section.dart`, `participants_list.dart`) muestran el verde sobre blanco con poco contraste hasta que C4 las rediseñe con `signalFg`.
- `lib/app/theme/app_theme.dart` llega a 301 líneas: cuando C2 sume temas de componentes, mover `_Buttons`, `_Surfaces` y `_Controls` a `lib/app/theme/component_themes.dart`.
