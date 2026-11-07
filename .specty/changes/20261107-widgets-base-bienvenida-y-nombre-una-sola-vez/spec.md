---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C2
---

# Widgets base, bienvenida y nombre una sola vez

## Objetivo

Crear los widgets base de Portadora que usan la bienvenida, el nombre y los permisos (`FrButton`, `FrIconButton`, `FrField`, `FrSteps`, la firma de señal y el loader de onda), con el resorte `press`, la luz al tacto y el movimiento reducido del prototipo aprobado (`docs/diseno/prototipo/`). Las pantallas que los usan y el nombre guardado llegan en cortes nuevos de la épica, porque este corte solo cabe con el módulo `core`.

## Fuera de alcance

- Guardar el nombre visible y el tema con `shared_preferences` (`PreferencesRepository` en `features/settings`): corte nuevo de la épica; sumado a este, el corte pasa del tamaño máximo.
- Pantallas de bienvenida, nombre y permisos y sus textos en slang (módulos `permissions` e `i18n`): corte nuevo de la épica.
- Mostrar la bienvenida solo en la primera apertura (guard en `lib/app/router`) y usar el nombre guardado al crear o unirse a una frecu (`lobby`): corte nuevo de la épica.
- Cambiar el nombre y elegir el tema en Ajustes, y aplicar el tema guardado en `app.dart`: corte nuevo de la épica (P21).
- Modo de habla por defecto guardado: con los Ajustes completos (C4).
- `FrPinField` + `FrKeypad`, `FrSegmented`, `FrToggle`, `FrPill`, `FrTag`, `FrBanner`, `FrToast`, `FrSheet`, `StatusIsland`, `FrScaffold` (grano y retícula) y las transiciones onda, deslizamiento, hoja y expansión: en los cortes que los usan (C3 y C4).
- Íconos propios `FrIcons`: necesitan una fuente en `assets/fonts/`, así que van con el corte de fuentes empaquetadas; mientras tanto los widgets reciben cualquier `IconData`.
- El brillo que barre el botón primario cada 6,5 s: sería un bucle infinito en cada pantalla con un botón primario.
- Temas de componentes Material: `lib/app/theme/app_theme.dart` no cambia (P26 sigue abierto).
- Perfilado en un teléfono real de gama media (R1 de la épica): necesita un dispositivo; queda como verificación manual de la persona.

## Supuestos

- A1: `MediaQuery.disableAnimations` refleja "Quitar animaciones" de Android y "Reducir movimiento" de iOS, así que basta para el movimiento reducido.
  - impacto: alto
- A2: La firma reproduce `sigParams` y `drawSig` de `engine.js` (FNV-1a de 32 bits y mulberry32 sobre el nombre en minúsculas y sin espacios en los extremos), así que es idéntica en todos los teléfonos y en el prototipo sin enviar nada por la red (A6 de la épica).
- A3: Con movimiento reducido, la firma y la onda se quedan en el cuadro del instante en que se pidió, como `Loop` del prototipo, y siguen visibles.

## Criterios de aceptación

- AC1: CUANDO se dibuja la firma de señal de un nombre ENTONCES su razón a:b, fase, giro y deriva salen del hash del nombre igual que en el prototipo, el mismo nombre da la misma firma con otras mayúsculas o espacios en los extremos, y otro nombre da otra.
- AC2: CUANDO el sistema pide reducir el movimiento ENTONCES la firma de señal y el loader de onda dejan de animarse y quedan dibujados en un cuadro fijo, los botones no cambian de escala al presionarse, el campo no tiembla con un error y los pasos cambian sin resorte, sin ocultar el estado (cargando, foco, error y paso actual).
- AC3: CUANDO se presiona un `FrButton` o un `FrIconButton` ENTONCES se hunde con el resorte `press` (escala 0,965 o 0,92), se ilumina desde el punto del dedo y llama a su acción al soltar; sin acción se ve al 38 % y no responde, y cargando muestra el loader de onda en lugar del texto, conserva su etiqueta accesible y no responde.
- AC4: CUANDO se escribe en un `FrField` ENTONCES muestra la etiqueta en mayúsculas y el contador `n/máx`, y no admite más caracteres que el máximo; con foco enciende el borde de señal y la línea inferior, y con error pinta el borde y la ayuda con el color de alerta.
- AC5: CUANDO se muestran los pasos de un recorrido ENTONCES el paso actual es una píldora de señal de 22 × 6 px, los anteriores van en `tx2` y los siguientes en `tx4`, y la píldora pasa al paso nuevo con el resorte `organic`.

## Diseño

- **Movimiento (`lib/core/design/motion/`)**:
  - `reduced_motion.dart`: extensión `context.reduceMotion` (`MediaQuery.maybeDisableAnimationsOf`) y `FrLoop`, que da a los pintores el tiempo en segundos como `ValueListenable<double>` con un único `Ticker`. Se detiene con movimiento reducido (congela el cuadro) y con `TickerMode` apagado (fuera de pantalla).
  - `fr_spring_curve.dart`: `FrSpringCurve`, una `Curve` que sigue una `SpringSimulation` de 0 a 1 con un `SpringDescription` de `FrMotion`, para animaciones implícitas con resorte (pasos y, después, pulgares e isla).
  - `fr_noise.dart` (Dart puro): `frHash` (FNV-1a 32 bits), `FrRandom` (mulberry32), `frNoise2` (Perlin 2D con la permutación sembrada con 1337) y `frVoice` (envolvente de voz simulada), copiados de `engine.js`.
- **Widgets (`lib/core/design/widgets/`)**, todos con `context.fr` y sin colores sueltos:
  - `SignalSignature`: `SignatureParams.fromName` (a:b de `RATIOS`, fase, giro y deriva) y un `CustomPainter` con 220 puntos, ondulación según el nivel, brillo al hablar y la estela de fósforo. Modos `idle`, `speak`, `muted`, `off` y `link`; nivel fijo o `levelOf(t)` (p. ej. `frVoice(t) * 0.55` en la pantalla del nombre). `RepaintBoundary` y repintado por `Listenable`, sin reconstruir widgets.
  - `WaveLoader`: dos senos con envolvente (`drawWave`), 64 × 22 px por defecto; reemplaza a los spinners.
  - `FrPressable`: gestos de presión con escala por `SpringSimulation` (`springPress`) en un `AnimationController.unbounded`, punto de contacto para la luz y `Semantics(button: true)`. Con movimiento reducido no escala.
  - `FrButton`: variantes `primary` (relleno `signal`, texto `signalInk`, sombra de señal), `secondary` (`bg2`, borde `line2`), `ghost` y `danger` (`alert` al 12 %, texto `alertTx`); tamaños de 58 y 44 px (`ghost` 48), radio `btn`, `RoundedSuperellipseBorder`, ícono a la izquierda o a la derecha, `loading` con `WaveLoader` y deshabilitado al 38 %. La luz al tacto es un degradado radial de 160 px en `touch` (blanco al 50 % en `primary`) que entra en 60 ms y sale en 420 ms.
  - `FrIconButton`: 48 px (40 en `compact`) sobre `bg1` con borde `line1`; al presionar escala 0,92 y pasa a `bg3`; `selected` con texto `signalFg`, borde y halo de señal; variantes `ghost` y `danger`; etiqueta accesible obligatoria.
  - `FrField`: etiqueta en mayúsculas (`label`, `tx3`), contador `n/máx` (`labelS`), caja de 58 px en `bg2` con radio `m`, texto `bodyL`, cursor `signalFg`, foco con borde de señal al 55 %, anillo `ledRing` de día y línea inferior que se abre desde el centro (600 ms, `easeOut`); error con borde y ayuda en alerta y temblor de 520 ms. Límite con `LengthLimitingTextInputFormatter`.
  - `FrSteps`: puntos de 6 px; el actual crece a 22 px en `signal` con `FrSpringCurve(springOrganic)` en 520 ms.
- **Documentación**: `docs/arquitectura.md` suma `core/design/motion/` y `core/design/widgets/`.

## Archivos

- crear lib/core/design/motion/reduced_motion.dart — `context.reduceMotion` y `FrLoop`.
- crear lib/core/design/motion/fr_spring_curve.dart — curva de resorte para animaciones implícitas.
- crear lib/core/design/motion/fr_noise.dart — hash, aleatorio, ruido Perlin y voz simulada del prototipo.
- crear lib/core/design/widgets/signal_signature.dart — firma de señal de Lissajous.
- crear lib/core/design/widgets/wave_loader.dart — loader de onda.
- crear lib/core/design/widgets/fr_pressable.dart — presión con resorte y punto de contacto.
- crear lib/core/design/widgets/fr_button.dart — botón de Portadora.
- crear lib/core/design/widgets/fr_icon_button.dart — botón de ícono de Portadora.
- crear lib/core/design/widgets/fr_field.dart — campo de texto con etiqueta, contador, foco y error.
- crear lib/core/design/widgets/fr_steps.dart — pasos de un recorrido.
- modificar docs/arquitectura.md — carpetas `motion/` y `widgets/` de `core/design`.
- crear test/core/design/motion/fr_motion_tools_test.dart — hash, aleatorio y ruido iguales al prototipo, curva de resorte y `FrLoop` con movimiento reducido.
- crear test/core/design/widgets/signal_signature_test.dart — firma determinista y animación detenida con movimiento reducido.
- crear test/core/design/widgets/fr_button_test.dart — presión, luz, deshabilitado y carga de los botones.
- crear test/core/design/widgets/fr_field_test.dart — etiqueta, contador, límite, foco, error y pasos.

## Tareas

- [x] T1: Movimiento reducido, bucle, curva de resorte y ruido del prototipo
  - files: lib/core/design/motion/reduced_motion.dart, lib/core/design/motion/fr_spring_curve.dart, lib/core/design/motion/fr_noise.dart, test/core/design/motion/fr_motion_tools_test.dart
  - ac: AC1, AC2
  - verify: flutter test test/core/design/motion/fr_motion_tools_test.dart
- [x] T2: Firma de señal y loader de onda
  - files: lib/core/design/widgets/signal_signature.dart, lib/core/design/widgets/wave_loader.dart, test/core/design/widgets/signal_signature_test.dart
  - ac: AC1, AC2
  - verify: flutter test test/core/design/widgets/signal_signature_test.dart
- [x] T3: Botones con resorte y luz al tacto
  - files: lib/core/design/widgets/fr_pressable.dart, lib/core/design/widgets/fr_button.dart, lib/core/design/widgets/fr_icon_button.dart, test/core/design/widgets/fr_button_test.dart
  - ac: AC2, AC3
  - verify: flutter test test/core/design/widgets/fr_button_test.dart
- [ ] T4: Campo de texto, pasos y arquitectura
  - files: lib/core/design/widgets/fr_field.dart, lib/core/design/widgets/fr_steps.dart, test/core/design/widgets/fr_field_test.dart, docs/arquitectura.md
  - ac: AC2, AC4, AC5
  - verify: flutter analyze && flutter test

## Riesgos

- R1: Los bucles infinitos (firma y onda) impiden que `pumpAndSettle` termine en las pruebas de las pantallas que los usen — mitigación: `FrLoop` se detiene con movimiento reducido y con `TickerMode`; esas pruebas activan "reducir movimiento" con `accessibilityFeaturesTestValue` o avanzan con `pump` y una duración.
- R2: Coste de la firma por cuadro (220 puntos y 30 tramos de estela) — mitigación: `RepaintBoundary`, repintado por `Listenable` sin reconstruir widgets y pausa fuera de pantalla; el perfilado en un teléfono real queda para la persona.
