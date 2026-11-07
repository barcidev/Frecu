---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C11
---

# Íconos propios `FrIcons` dibujados desde los trazos del prototipo

## Objetivo

La app tiene su propio set de íconos de Portadora: los 37 íconos del prototipo (`ICONS` en `docs/diseno/prototipo/components.js`) se dibujan en código desde sus trazos SVG de 24×24, con trazo redondo y el color del tema, sin fuente de íconos ni assets, así que funcionan sin conexión. `FrButton` y `FrIconButton` pueden mostrarlos.

## Fuera de alcance

- Reemplazar los íconos Material de las pantallas actuales: lo hacen los cortes de pantallas (C12 a C19).
- Íconos animados o transformaciones entre íconos.
- Espejo de íconos direccionales para idiomas de derecha a izquierda.
- Fuentes de íconos, archivos SVG en assets y paquetes como `flutter_svg` o `path_parsing`.
- Íconos que no están en el prototipo.

## Supuestos

- A1: `Path.arcToPoint` de Flutter sigue la semántica de los arcos SVG (bandera de barrido 1 = sentido horario en pantalla, radios que se agrandan si no alcanzan el punto final), así que el parser normaliza los arcos y los delega sin convertirlos a curvas.
  - impacto: alto
- A2: El grosor del trazo replica el CSS del prototipo (`svg.ic` y sus clases `s16`, `s28`, `s34`): 1,6 unidades de rejilla por defecto, 1,8 a 16 px o menos, 1,5 desde 28 px y 1,4 desde 34 px.
- A3: Los íconos se guardan como datos `const` en Dart con los trazos copiados tal cual del prototipo (`rect`, `circle` y `path`), y cada uno se traduce a `Path` una sola vez y queda en caché.
- A4: Para no romper las pruebas aprobadas de C2, `FrButton` y `FrIconButton` conservan su constructor con `IconData` y suman un constructor `.drawn` que recibe un ícono de `FrIcons`.

## Criterios de aceptación

- AC1: CUANDO se lee el atributo `d` de un trazo SVG con comandos M, L, H, V, C, S, Q, T, A y Z, absolutos o relativos, con repeticiones implícitas y números compactos (`.5.5`, `-2-2`, `1e-1`, banderas de arco pegadas) ENTONCES devuelve segmentos absolutos equivalentes al SVG; CUANDO el trazo está mal formado ENTONCES lanza `FormatException` con la posición del error.
- AC2: CUANDO se dibuja un ícono de `FrIcons` ENTONCES su trazado sale en código de los trazos del prototipo (37 íconos, de `mic` a `dot`), cabe en la rejilla de 24 y respeta su geometría (por ejemplo, el arco del micrófono baja hasta y = 18 y el círculo de `info` ocupa de 3 a 21), sin fuentes de íconos, assets ni red.
- AC3: CUANDO se pinta un `FrIcon` ENTONCES usa puntas y uniones redondeadas con el grosor del prototipo según su tamaño, rellena solo las formas con relleno (`dot`), y toma el color, la opacidad y el tamaño de `IconTheme` salvo que reciba los suyos; con `semanticLabel` se anuncia con ese texto.
- AC4: CUANDO un `FrButton` o un `FrIconButton` se crea con `.drawn` y un ícono de `FrIcons` ENTONCES lo dibuja a 22 px con el color de primer plano de su variante, y con `IconData` se comportan como antes.

## Diseño

- **Parser (`lib/core/design/icons/svg_path_parser.dart`)**: `parseSvgPathData(String d)` recorre el texto con un lector propio de números y banderas y devuelve `List<SvgPathSegment>` (clases `sealed`: `SvgMoveTo`, `SvgLineTo`, `SvgCubicTo`, `SvgQuadTo`, `SvgArcTo`, `SvgClose`) en coordenadas absolutas: H y V pasan a líneas, S y T reflejan el punto de control anterior, los pares tras M son líneas, un arco con radio 0 es una línea y uno sin desplazamiento se omite. `buildSvgPath(segments)` los vuelca en un `Path` (`arcToPoint` para los arcos).
- **Datos (`lib/core/design/icons/fr_icon_data.dart`)**: `FrIconData(name, shapes)` `const`, con formas `FrIconPath(d)`, `FrIconRect(x, y, w, h, rx)` y `FrIconCircle(cx, cy, r, filled)`. `geometry` devuelve los trazados de línea y de relleno en la rejilla de 24, calculados una vez y guardados en un `Expando`.
- **Catálogo (`lib/core/design/icons/fr_icons.dart`)**: `abstract final class FrIcons` con un `static const` por ícono, mismos nombres que el prototipo (`mic`, `micOff`, `walkie`, …, `dot`) y la lista `values`.
- **Widget (`lib/core/design/icons/fr_icon.dart`)**: `FrIcon(icon, {size, color, strokeWidth, semanticLabel})`, como `Icon`: tamaño de `IconTheme` (24 si no hay), color de `IconTheme` por su opacidad, `CustomPaint` con `FrIconPainter` que escala la rejilla a `size` y traza con `StrokeCap.round` y `StrokeJoin.round`. `FrIcon.strokeFor(size)` da el grosor del prototipo.
- **Botones**: `FrButton.drawn` y `FrIconButton.drawn` guardan el ícono propio en `drawnIcon` (y `drawnTrailingIcon`) y lo pintan con `FrIcon` en el mismo lugar, tamaño y color que hoy el `Icon`.

## Archivos

- crear lib/core/design/icons/svg_path_parser.dart — parser propio del atributo `d` de SVG y paso a `Path`.
- crear lib/core/design/icons/fr_icon_data.dart — formas de un ícono y su geometría en caché.
- crear lib/core/design/icons/fr_icons.dart — catálogo de los 37 íconos del prototipo.
- crear lib/core/design/icons/fr_icon.dart — widget `FrIcon` y su pintor.
- modificar lib/core/design/widgets/fr_button.dart — constructor `FrButton.drawn` con íconos propios.
- modificar lib/core/design/widgets/fr_icon_button.dart — constructor `FrIconButton.drawn` con ícono propio.
- crear test/core/design/icons/svg_path_parser_test.dart — comandos, números compactos, reflejos, arcos y errores.
- crear test/core/design/icons/fr_icons_test.dart — catálogo completo, rejilla y geometría de referencia.
- crear test/core/design/icons/fr_icon_test.dart — trazo, grosor, relleno, `IconTheme`, semántica y botones con `.drawn`.

## Tareas

- [x] T1: Parser propio de trazos SVG
  - files: lib/core/design/icons/svg_path_parser.dart, test/core/design/icons/svg_path_parser_test.dart
  - ac: AC1
  - verify: flutter test test/core/design/icons/svg_path_parser_test.dart
- [x] T2: Catálogo `FrIcons` y widget `FrIcon`
  - files: lib/core/design/icons/fr_icon_data.dart, lib/core/design/icons/fr_icons.dart, lib/core/design/icons/fr_icon.dart, test/core/design/icons/fr_icons_test.dart, test/core/design/icons/fr_icon_test.dart
  - ac: AC2, AC3
  - verify: flutter test test/core/design/icons
- [ ] T3: `FrButton.drawn` y `FrIconButton.drawn`
  - files: lib/core/design/widgets/fr_button.dart, lib/core/design/widgets/fr_icon_button.dart, test/core/design/icons/fr_icon_test.dart
  - ac: AC4
  - verify: flutter analyze && flutter test test/core/design

## Riesgos

- R1: Diferencias sutiles entre el arco de Skia y el del navegador — mitigación: pruebas de geometría con límites calculados a mano para arcos pequeños, grandes y con bandera de barrido distinta.
- R2: C9 y C10 trabajan en paralelo en `lib/core/design/` — mitigación: solo archivos nuevos en `icons/`, y en los botones únicamente constructores añadidos sin cambiar el comportamiento existente.
