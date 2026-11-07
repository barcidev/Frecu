---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C9
---

# Widgets de control: `FrPinField`, `FrKeypad`, `FrSegmented`, `FrToggle`, `FrPill` y `FrTag`

## Objetivo

Crear los widgets de control de Portadora que usan el inicio, la unión por código, Ajustes y la frecu activa: el código de acceso en matriz de puntos con su teclado propio de teclas grandes, el selector segmentado con pulgar líquido, el interruptor, la píldora de estado y la etiqueta, copiados del prototipo aprobado (`docs/diseno/prototipo/`) y con movimiento reducido.

## Fuera de alcance

- Pantallas que los usan (hoja del código, Ajustes, modo de habla, nueva frecu) y sus textos en slang: cortes C8, C15 a C18. Los widgets reciben sus textos y etiquetas accesibles ya traducidos.
- Verificar el código con el anfitrión y el envío automático al cuarto dígito: lo decide la pantalla que muestra `FrPinField` (C16).
- Íconos propios `FrIcons` (C11): los widgets reciben el ícono como `Widget`; el teclado usa el ícono Material de borrar mientras C11 no llegue.
- Variante grande del PIN (`.pin.big`): el prototipo no la usa en ninguna pantalla.
- Escribir el PIN con el teclado del sistema o un teclado físico.
- Arrastrar el pulgar del segmentado o la perilla del interruptor: responden al toque.
- Filo especular superior (`inset 0 1px 0 var(--spec)`): los widgets de C2 tampoco lo dibujan.
- `docs/arquitectura.md` y los archivos de C1 y C2 no cambian, para no chocar con C10 y C11.

## Supuestos

- A1: `FrPinField` solo dibuja: recibe los dígitos y el estado (`idle`, `busy`, `ok`, `error`) y la pantalla los lleva junto con `FrKeypad`, como `pinKey` del prototipo.
  - impacto: alto
- A2: Los estados que no son movimiento no se ocultan con movimiento reducido: el cursor queda fijo y visible, `busy` se dibuja quieto en su punto más alto (borde de señal y dígitos en `signalFg`) y la píldora `busy` deja quieto su arco.
- A3: El segmentado necesita un ancho acotado (como `TextField`): sus segmentos se reparten el ancho por igual, como `grid-auto-columns: 1fr`.
- A4: El halo de la píldora `ok` usa `signalFg` (trazo) y no `signal`: de noche es el mismo lima y de día queda en tinta, alrededor del punto relleno de señal con su anillo `ledRing`.

## Criterios de aceptación

- AC1: CUANDO se muestra un `FrPinField` con algunos dígitos ENTONCES dibuja 4 celdas de 64 × 78 px con los dígitos en Doto, un punto `tx4` en las vacías y el cursor de señal (borde de señal y barra `signalFg` que parpadea cada 1,05 s) en la siguiente; el dígito recién escrito aparece con el resorte `organic` desde 0,7, y en solo lectura no hay cursor y el borde es `line2` sin relleno.
- AC2: CUANDO el `FrPinField` pasa a `busy`, `ok` o `error` ENTONCES en `busy` las celdas laten escalonadas con el borde de señal, en `ok` se rellenan de `signal` con los dígitos en `signalInk` y una ola escalonada de 70 ms, y en `error` los dígitos y bordes van en alerta y la fila tiembla una vez durante 560 ms.
- AC3: CUANDO se toca una tecla de `FrKeypad` ENTONCES la tecla (56 px de alto, 3 columnas: 1–9, función opcional, 0 y borrar) se hunde a 0,93 con el resorte `press` y pasa a `bg3`, y el teclado llama a `onDigit` con su dígito, a `onDelete` o a la acción de la tecla de función; borrar y la función tienen su etiqueta accesible.
- AC4: CUANDO se elige otro segmento de `FrSegmented` ENTONCES llama a `onChanged` con su valor, el pulgar viaja hasta él con el resorte `organic` y se estira (1,16 × 0,86) al salir, el texto elegido pasa a `tx1` (a `signalInk` sobre el pulgar de señal en la variante de señal) y el resto queda en `tx3`; sin `onChanged` se ve al 38 % y no responde.
- AC5: CUANDO se toca un `FrToggle` ENTONCES llama a `onChanged` con el valor contrario; encendido es un relleno `signal` con la perilla en `signalInk` a la derecha y apagado es `bg3` con la perilla en `tx2` a la izquierda, la perilla viaja con el resorte `organic` y se estira a 34 px mientras se presiona, y expone su estado a la accesibilidad; sin `onChanged` se ve al 38 % y no responde.
- AC6: CUANDO se muestra una `FrPill` o una `FrTag` ENTONCES la píldora de 28 px lleva el texto en mayúsculas y un punto del color de su tono (`ok`, `warn`, `alert`, `off`) con un halo que late cada 2,4 s (1,1 s en `warn`, sin halo en `off`) o, si está ocupada, un arco que gira; la etiqueta de 20 px va en mayúsculas en neutro (`bg3` y `tx2`), señal (relleno `signal` al 12 % × `washK` y texto `signalFg`) o aviso; en el tema claro ningún texto ni trazo de estos widgets usa `signal`.
- AC7: CUANDO el sistema pide reducir el movimiento ENTONCES el cursor del PIN queda fijo y visible, el dígito no salta, la fila no tiembla, la ola de `ok` no se mueve y `busy` queda quieto con su borde de señal; las teclas no se hunden, el pulgar y la perilla cambian de lugar sin resorte ni estiramiento, el halo de la píldora se apaga y su arco se detiene, sin ocultar ningún estado (cursor, ocupado, correcto, error, selección y encendido).

## Diseño

Todos en `lib/core/design/widgets/`, con `context.fr` y sin colores sueltos. Reutilizan `FrPressable`, `FrLoop`, `FrSpringCurve` y `context.reduceMotion` de C2.

- **`FrPinField`** (`fr_pin_field.dart`): `value` (dígitos), `length` (4), `state` (`FrPinState.idle`, `busy`, `ok`, `error`), `readOnly` y `semanticLabel`. Celdas de 64 × 78 px, radio 18, `bg2`, borde `line1`, dígitos con `type.digits` a 46 px en `tx1`. Cursor: borde de señal al 60 %, anillo `ledRing` de día y halo de señal al 6 % de 4 px; barra de 2 × 30 px en `signalFg` que parpadea con `FrLoop` (visible la primera mitad de cada 1,05 s). Al crecer `value` en un dígito, la celda nueva escala de 0,7 a 1 y su opacidad de 0,2 a 1 con `FrSpringCurve(springOrganic)` en 460 ms. `busy`: con `FrLoop`, cada celda (desfase de 110 ms) sube y baja en 1,1 s con `easeInOut` hasta el borde de señal al 60 % y los dígitos en `signalFg`. `ok`: relleno `signal`, dígitos `signalInk` y brillo de señal; la ola (700 ms, `easeOut`, desfase de 70 ms) sube 6 px y escala a 1,04 al 40 % mientras el fondo pasa de `bg2` a `signal`. `error`: dígitos en `alert`, borde de alerta al 65 % y temblor de 560 ms con los pasos de `@keyframes shake`. Solo lectura: fondo transparente y borde `line2`, sin cursor.
- **`FrKeypad`** (`fr_keypad.dart`): `onDigit(int)`, `onDelete`, `deleteLabel`, `deleteIcon` (por defecto `Icons.backspace_outlined`) y la tecla de función opcional (`leading`, `leadingLabel`, `onLeading`). Rejilla de 3 columnas con 8 px de separación; teclas de 56 px, radio `m`, `bg1` y borde `line1`, dígitos en Archivo 560 a 24 px con ancho 115 en `tx1`; las teclas de función son transparentes y en `tx2`. Cada tecla es un `FrPressable` a 0,93 que pasa a `bg3` en 90 ms.
- **`FrSegmented<T>`** (`fr_segmented.dart`): `segments` (`FrSegment<T>` con valor, etiqueta e ícono `Widget` opcional), `value`, `onChanged` y `signal`. Caja de 48 px con 4 px de relleno, radio `m`, `bg1` y borde `line1`; etiquetas con `type.label` en mayúsculas. El pulgar (radio 12, `bg3`, borde `line2` y sombra; o `signal` con brillo en la variante de señal) se mueve en unidades de segmento con un `AnimationController.unbounded` y `SpringSimulation(springOrganic)`, conservando la velocidad si se interrumpe; el estiramiento usa un segundo controlador de 520 ms (`easeOut`, 1,16 × 0,86 al 35 %). Cada segmento expone `button`, `selected` e `inMutuallyExclusiveGroup`.
- **`FrToggle`** (`fr_toggle.dart`): `value`, `onChanged` y `semanticLabel`. Pista de 54 × 32 px, radio 16; apagada en `bg3` con borde `line2` y perilla `tx2`, encendida en `signal` con brillo de señal y perilla `signalInk`. La posición de la perilla va de 0 a 1 con `SpringSimulation(springOrganic)`; al presionar, el ancho pasa de 26 a 34 px en 260 ms (`easeOut`) creciendo hacia el centro. `Semantics(toggled: …)`.
- **`FrPill`** (`fr_pill.dart`): `label`, `tone` (`FrPillTone.ok`, `warn`, `alert`, `off`) y `busy`. 28 px de alto, relleno 0 12 0 10, radio 14, `bg1`, borde `line1` y texto `labelS` en mayúsculas. Punto de 7 px: `ok` en `signal` con `ledRing` y brillo, texto `tx1` y halo `signalFg`; `warn` y `alert` en su color, también el texto; `off` en `tx4` con texto `tx3` y sin halo. El halo es un anillo de 1 px que crece de 0,6 a 2,1 y se desvanece (`easeOut`) con `FrLoop`; `busy` cambia el punto por un anillo de 1,5 px con un arco que gira cada 0,9 s.
- **`FrTag`** (`fr_tag.dart`): `label` y `tone` (`FrTagTone.neutral`, `signal`, `warn`). 20 px de alto, relleno 0 7, radio `xs`, texto `labelS` en mayúsculas.
- **Movimiento reducido**: sin resortes ni escalas; los cambios de color siguen con un fundido corto (`quick`). `FrLoop` ya se detiene solo; los estados que dependen del bucle se dibujan quietos según A2.

## Archivos

- crear lib/core/design/widgets/fr_pin_field.dart — celdas del código de acceso con cursor, aparición, ocupado, correcto y error.
- crear lib/core/design/widgets/fr_keypad.dart — teclado numérico propio de teclas grandes.
- crear lib/core/design/widgets/fr_segmented.dart — selector segmentado con pulgar líquido.
- crear lib/core/design/widgets/fr_toggle.dart — interruptor con perilla de resorte.
- crear lib/core/design/widgets/fr_pill.dart — píldora de estado con halo.
- crear lib/core/design/widgets/fr_tag.dart — etiqueta en mayúsculas.
- crear test/core/design/widgets/fr_pin_field_test.dart — celdas, cursor, estados, teclado y movimiento reducido.
- crear test/core/design/widgets/fr_segmented_test.dart — selección, pulgar, interruptor y movimiento reducido.
- crear test/core/design/widgets/fr_pill_test.dart — tonos, halo, etiqueta, colores de día y movimiento reducido.

## Tareas

- [x] T1: Código de acceso y teclado
  - files: lib/core/design/widgets/fr_pin_field.dart, lib/core/design/widgets/fr_keypad.dart, test/core/design/widgets/fr_pin_field_test.dart
  - ac: AC1, AC2, AC3, AC7
  - verify: flutter test test/core/design/widgets/fr_pin_field_test.dart
- [x] T2: Selector segmentado e interruptor
  - files: lib/core/design/widgets/fr_segmented.dart, lib/core/design/widgets/fr_toggle.dart, test/core/design/widgets/fr_segmented_test.dart
  - ac: AC4, AC5, AC7
  - verify: flutter test test/core/design/widgets/fr_segmented_test.dart
- [x] T3: Píldora de estado y etiqueta
  - files: lib/core/design/widgets/fr_pill.dart, lib/core/design/widgets/fr_tag.dart, test/core/design/widgets/fr_pill_test.dart
  - ac: AC6, AC7
  - verify: flutter analyze && flutter test

## Riesgos

- R1: El cursor, `busy` y el halo son bucles infinitos que impiden que `pumpAndSettle` termine en las pruebas de las pantallas — mitigación: usan `FrLoop`, que se detiene con movimiento reducido y con `TickerMode`; esas pruebas avanzan con `pump` y una duración o activan "reducir movimiento".
- R2: Doto aún no está empaquetada (C5 corre en paralelo) — mitigación: las pruebas miden cajas, colores y estilos, no el dibujo de los glifos.

## Cierre

### Resumen

- `lib/core/design/widgets/`: `FrPinField` (celdas Doto de 64 × 78, cursor que parpadea, dígito nuevo con resorte `organic`, `busy` con latido escalonado, `ok` con ola, `error` con temblor y solo lectura), `FrKeypad` (teclas de 56 px sobre `FrPressable` a 0,93, tecla de función opcional y borrar con etiqueta accesible), `FrSegmented<T>` (pulgar con `SpringSimulation` `organic` que se estira y variante de señal), `FrToggle` (perilla de resorte que se estira al presionar, `Semantics(toggled)`), `FrPill` (punto con halo que late o arco que gira) y `FrTag` (neutro, señal y aviso).
- Movimiento reducido en los seis: sin resortes, escalas, ola ni temblor; el cursor queda fijo, `busy` quieto en su punto más alto, el halo se apaga y el arco se detiene.
- Verificado: `flutter analyze` sin avisos y `flutter test` completo en verde, con 30 pruebas nuevas en `fr_pin_field_test.dart`, `fr_segmented_test.dart` y `fr_pill_test.dart`.

### Desviaciones

- La píldora ocupada dibuja el anillo fijo al 30 % y el arco al 100 % del tono: en el prototipo ambos van en `warn` pleno y el arco no se distingue. Tampoco lleva halo (el prototipo lo mantiene en `warn busy`).
- Los dígitos del PIN cambian de color sin transición; el relleno y el borde de las celdas sí se funden en 280 ms (160 ms con movimiento reducido), salvo en `busy` y durante la ola, que se dibujan cuadro a cuadro.
- La pista de `FrToggle` usa `StadiumBorder` en lugar de `RoundedSuperellipseBorder` para ser una píldora exacta.
- `FrTag` no recibe ícono: el prototipo no lo usa.

### Decisiones

- `FrPinField` solo dibuja: la pantalla lleva los dígitos y el estado y decide el envío al cuarto dígito. El dígito salta solo cuando `value` crece en uno al final; la ola de `ok` y el temblor de `error` solo al cambiar de estado, no al montarse ya en ese estado.
- `FrLoop` se monta solo donde hace falta (cursor visible, `busy`, halo y arco), para que `pumpAndSettle` termine en los demás estados.
- Los resortes del pulgar y de la perilla usan `snapToEnd: true` y conservan la velocidad si se interrumpen.
- Tocar el segmento ya elegido no llama a `onChanged`. Las teclas de función del teclado siguen transparentes al presionarse, como en el prototipo.
- El segmentado y el interruptor pintan su borde con `DecoratedBox` (no `Container`) para que no reste espacio al pulgar ni mueva la perilla.
- `fr_pin_field.dart` queda en 328 líneas: es un solo widget con sus estados; no se divide.

### Pendientes

- Cambiar el ícono Material de borrar de `FrKeypad` (`deleteIcon`) por el de `FrIcons` cuando llegue C11.
- Usar estos widgets en las pantallas con sus textos de slang: Ajustes (C8), inicio (C15), unión por código (C16), nueva frecu (C17) y modo de habla en la frecu activa (C18).
