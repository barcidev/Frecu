---
kind: standard
epic: 20261108-pendientes-portadora
slice: C1
---

# Íconos propios en `FrField` y `FrBanner`, y formato de las pruebas de core

## Objetivo

Los campos (`FrField`) y los avisos (`FrBanner`) pueden mostrar los íconos dibujados de `FrIcons`, como ya hace `FrButton.drawn`, y el botón de cerrar de los avisos deja el ícono de Material por `FrIcons.close` (P52 y P55). Así C2, C5 y C6 pueden cambiar sus campos y avisos a íconos propios (AC4 de la épica). Además, `lib/core` y `test/core` quedan con `dart format` limpio (parte de AC6 de la épica y de P99).

## Fuera de alcance

- Cambiar los íconos de los campos y avisos de las features (hojas de unión, aviso de eco, inicio sin red y Ajustes): lo hacen C2, C5 y C6.
- Quitar los constructores con `IconData` de `FrField` y `FrBanner`: se quitan cuando ya no tengan usos (A5 de la épica).
- Formatear archivos fuera de `lib/core` y `test/core` (C5 y C8).
- Cambiar el aspecto, las medidas o las animaciones de `FrField` y `FrBanner`.

## Supuestos

- A1: Para no romper las pruebas aprobadas de `FrField` y `FrBanner` ni sus usos actuales, los dos conservan su constructor con `IconData` y suman un constructor `.drawn` que recibe un `FrIconData`, que guardan en `drawnIcon`, como `FrButton.drawn` y `FrIconButton.drawn`.
  - impacto: alto
- A2: Los tamaños y colores salen del prototipo (`UI.field` y `UI.banner` en `components.js`, `ui.css`): el ícono del campo va a 18 px en `tx3`, el del aviso a 18 px con el color de su tono y el cierre a 16 px en `tx3`. `FrIcon.strokeFor` ya da el grosor de cada tamaño.
- A3: `dismissIcon` de `FrBanner` no tiene usos en `lib` ni en `test`, así que pasa de `IconData` a `FrIconData` con `FrIcons.close` por defecto en los dos constructores, y el cierre se pinta con `FrIcon`.
- A4: `test/core/design/fr_colors_order_test.dart` es una prueba aprobada de un corte anterior: solo se le aplica `dart format`, sin tocar ninguna aserción (R3 de la épica). Es el único archivo de `lib/core` y `test/core` que `dart format` cambia hoy.

## Criterios de aceptación

- AC1: CUANDO un `FrField` se crea con `FrField.drawn` y un ícono de `FrIcons` ENTONCES lo dibuja con `FrIcon` antes del texto, a 18 px, en `tx3` y a 10 px del texto, sin ningún `Icon` de Material; y con `IconData` o sin ícono se comporta como antes.
- AC2: CUANDO un `FrBanner` se crea con `FrBanner.drawn` y un ícono de `FrIcons` ENTONCES lo dibuja con `FrIcon` a 18 px con el color de ícono de su tono (`warn`, `alert` o `tx2` en info); y con `IconData` se comporta como antes.
- AC3: CUANDO un `FrBanner` tiene cierre (`onDismiss`), creado con cualquiera de sus dos constructores, ENTONCES el botón de cerrar dibuja `FrIcons.close` con `FrIcon` a 16 px en `tx3`, sin `Icons.close_rounded`, conserva su etiqueta accesible y al tocarlo el aviso se va y llama a `onDismiss`; sin `onDismiss` no hay cierre.
- AC4: CUANDO se revisa el código ENTONCES `dart format --output=none --set-exit-if-changed lib/core test/core` pasa sin cambios.
  - test: manual

## Diseño

- **`FrField`**: el constructor actual inicializa `drawnIcon = null`; `FrField.drawn({… FrIconData? icon …})` guarda `drawnIcon = icon` e `icon = null`. `_input` pinta `FrIcon(drawn, size: 18, color: tx3)` si hay `drawnIcon` y, si no, el `Icon` de hoy, en el mismo lugar.
- **`FrBanner`**: `icon` pasa a `IconData?` con `required IconData this.icon` en el constructor actual, como `FrIconButton`; `FrBanner.drawn({required FrIconData icon, …})` guarda `drawnIcon = icon` e `icon = null`, con el mismo `assert` de la etiqueta del cierre. Un `_glyph` pinta `FrIcon` o `Icon` a 18 px con `look.icon`. `dismissIcon` es `FrIconData` con `FrIcons.close` por defecto y `_close` lo pinta con `FrIcon` a 16 px.
- **Formato**: `dart format test/core/design/fr_colors_order_test.dart`, que solo pone un token por línea en la lista de `tokens`.

## Archivos

- modificar lib/core/design/widgets/fr_field.dart — constructor `FrField.drawn` con ícono propio.
- modificar lib/core/design/widgets/fr_banner.dart — constructor `FrBanner.drawn` y cierre con `FrIcons.close`.
- crear test/core/design/widgets/fr_field_drawn_test.dart — ícono propio del campo: tamaño, color, posición y sin Material.
- crear test/core/design/widgets/fr_banner_drawn_test.dart — ícono propio del aviso por tono y cierre con `FrIcons.close` en los dos constructores.
- modificar test/core/design/fr_colors_order_test.dart — `dart format`, sin cambiar aserciones.

## Tareas

- [x] T1: `FrField.drawn` con ícono propio
  - files: lib/core/design/widgets/fr_field.dart, test/core/design/widgets/fr_field_drawn_test.dart
  - ac: AC1
  - verify: flutter test test/core/design/widgets/fr_field_drawn_test.dart test/core/design/widgets/fr_field_test.dart
- [x] T2: `FrBanner.drawn` y cierre con `FrIcons.close`
  - files: lib/core/design/widgets/fr_banner.dart, test/core/design/widgets/fr_banner_drawn_test.dart
  - ac: AC2, AC3
  - verify: flutter test test/core/design/widgets/fr_banner_drawn_test.dart test/core/design/widgets/fr_notices_test.dart
- [ ] T3: `dart format` limpio en `lib/core` y `test/core`
  - files: test/core/design/fr_colors_order_test.dart
  - ac: AC4
  - verify: dart format --output=none --set-exit-if-changed lib/core test/core && flutter analyze && flutter test test/core

## Riesgos

- R1: C2, C5 y C6 dependen de estos constructores y trabajan después en paralelo — mitigación: solo se suman constructores y el cierre cambia de ícono, sin cambiar medidas, colores ni la firma del constructor actual (salvo `dismissIcon`, que no tiene usos).
