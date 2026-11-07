---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C8
---

# Ajustes con nombre, tema Auto/Claro/Oscuro y modo de habla por defecto

## Objetivo

Rehacer Ajustes con el sistema Portadora, como la pantalla `settings` del prototipo aprobado (`docs/diseno/prototipo/screens.js`): una tarjeta con el nombre visible y su firma de señal para cambiarlo, el modo de habla por defecto (PTT o Abierto) y el tema (Auto, Claro u Oscuro), que se guardan con `preferencesProvider` y cambian la app al instante. Cubre la parte de Ajustes de AC1 y AC3 de la épica; hoy la pantalla es Material genérica con textos fijos.

## Fuera de alcance

- Grupo «General» del prototipo (idioma, permisos y guía del punto de acceso): no hay preferencia de idioma y la guía llega con C17. Se quita la fila fija «Idioma · Español» de hoy.
- Conectar la transición de deslizamiento al router: P53.
- Íconos propios `FrIcons` (C11): se usan `IconData` de Material por ahora.
- Usar el nombre guardado al crear o unirse a una frecu y el modo de habla por defecto al entrar a una frecu: C13 y C18.
- Bienvenida y pantalla de nombre de la primera apertura: C12.
- Versión de la app en el pie: necesitaría `package_info_plus`.
- Cambios en `lib/core/design` (`FrField`, `FrSegmented`, `FrSheet`…) y en el dominio, los datos y los providers de `features/settings` (C6).

## Supuestos

- A1: El nombre se cambia en una hoja `FrSheet` sobre Ajustes que abre el botón Editar de la tarjeta (el prototipo dibuja el botón pero no su destino), con la firma que sigue al texto como en la pantalla de nombre del prototipo.
  - impacto: alto
- A2: Los selectores muestran siempre lo que expone `preferencesProvider`; como el provider solo cambia después de guardar, si el guardado falla el selector queda en el valor guardado y basta con un aviso.
- A3: Para P48 no se toca `FrField` (`lib/core`, tercer módulo): el campo usa `maxLength: Preferences.displayNameMaxLength` (cuenta grafemas) y la hoja valida con `Preferences.normalizeDisplayName` (cuenta `runes`) para habilitar Guardar y mostrar el error de largo.
  - impacto: alto
- A4: Sin nombre guardado (antes de C12 y C13) la tarjeta muestra «Sin nombre» y la firma por defecto del nombre vacío.
- A5: Mientras se leen las preferencias la pantalla muestra los valores por defecto; en la app ya llegan leídas desde el arranque (C7).
- A6: Las pruebas abren Ajustes dentro de `FrecuApp` sobre el contenedor de `createAppContainer()` y un almacenamiento en memoria, con movimiento reducido para que la firma no anime sin fin y `pumpAndSettle` termine.

## Criterios de aceptación

- AC1: CUANDO se abre Ajustes ENTONCES se ve en Portadora (`FrScaffold`) con el botón Atrás, el título, la tarjeta del nombre, las secciones Voz y Apariencia con el modo de habla y el tema guardados ya elegidos y el pie «100 % local · sin internet», con todos los textos desde slang en español y en inglés; Atrás vuelve a la pantalla anterior.
- AC2: CUANDO el usuario elige Auto, Claro u Oscuro en el selector de tema ENTONCES toda la app pasa a ese tema de Portadora al instante (Auto sigue al sistema) y la elección se conserva al reabrir la app.
- AC3: CUANDO el usuario elige PTT o Abierto en el modo de habla por defecto ENTONCES queda elegido y se conserva al reabrir la app.
- AC4: CUANDO no se puede guardar el tema o el modo de habla ENTONCES aparece un aviso de error (`FrToast`) y el selector sigue en el valor guardado.
- AC5: CUANDO se abre Ajustes ENTONCES la tarjeta muestra el nombre guardado con su firma de señal, o «Sin nombre» si aún no hay, y el botón Editar.
- AC6: CUANDO el usuario toca Editar, escribe un nombre válido y toca Guardar o confirma desde el teclado ENTONCES la hoja se cierra y la tarjeta muestra el nombre sin espacios alrededor con su firma, que se conserva al reabrir la app; mientras escribe, la firma de la hoja sigue al texto.
- AC7: CUANDO el nombre queda vacío o solo con espacios, o pasa de 20 caracteres contados como el dominio (`runes`) ENTONCES Guardar queda deshabilitado, confirmar desde el teclado no guarda y, si pasa del largo, el campo muestra el error del largo; el campo limita el texto a `Preferences.displayNameMaxLength`; CUANDO el guardado falla ENTONCES la hoja sigue abierta con el error y el nombre guardado no cambia.

## Diseño

Referencia: pantalla `settings` de `docs/diseno/prototipo/screens.js` con `.group`, `.row`, `.set-label` y `.profile` de `ui.css` y `screens.css`. Todo con `context.fr`, sin colores sueltos ni texto directo.

- **`SettingsPage`** (`settings_page.dart`, `ConsumerWidget`, `@RoutePage()`): `FrScaffold` con una cabecera fija de 60 px (relleno 0 16: `FrIconButton` ghost con `Icons.arrow_back_rounded` y etiqueta `t.settings.back` que hace `context.router.maybePop()`, título centrado en Archivo 640 a 16 px y un hueco de 48 px) y debajo una lista desplazable: tarjeta del nombre, secciones «Voz» y «Apariencia» y el pie centrado en `labelS` y `tx3` a 24 px del último grupo. Observa `preferencesProvider` (`value ?? const Preferences()`).
  - Voz: grupo con una fila de una columna («Modo de habla por defecto» y «Se aplica al entrar a cada frecu.») y debajo, con relleno 0 14 14, un `FrSegmented<TalkMode>` con PTT (`Icons.touch_app_outlined`) y Abierto (`Icons.mic_none_rounded`) que llama a `setDefaultTalkMode`.
  - Apariencia: una fila «Tema» / «Auto sigue al teléfono» con un `FrSegmented<ThemePreference>` de 196 px a la derecha (Auto, Claro, Oscuro) que llama a `setThemePreference`.
  - Si un guardado devuelve fallo: `showFrToast` con `FrToast.icon(Icons.error_outline_rounded, t.settings.saveError)`.
- **`settings_group.dart`**: `SettingsSectionLabel` (texto en mayúsculas en `labelS` y `tx3`, relleno 22 26 10), `SettingsGroup` (márgenes de 20, radio 22, `bg1`, borde `line1`, filo `spec` arriba, recorta su contenido y separa las filas con una línea `line1`) y `SettingsRow` (título en Archivo 560 a 15 px en `tx1`, subtítulo en `bodyS` a 12,5 px en `tx3`, `trailing` opcional; relleno 15 16, alto mínimo 58, separación 12).
- **`ProfileCard`** (`profile_card.dart`): `name` (`String?`) y `onEdit`. Margen 4 20 0, relleno 18, radio 26, `bg1` y borde `line1`; columna de 96 px y separación 16. A la izquierda un círculo de 96 px con borde `line1` y un degradado radial de señal al 8 %, con `SignalSignature(name: name ?? '', size: 96, mode: speak, levelOf: (s) => frVoice(s) * 0.55, radius: 0.38)`. A la derecha, «NOMBRE VISIBLE» en `labelS` y `tx3`, el nombre en Archivo 700 a 26 px con ancho 120 e interletrado −0,02 em (o «Sin nombre» en `tx3`) y un `FrButton` secundario pequeño «Editar» con `Icons.edit_outlined`.
- **`EditNameSheet`** (`edit_name_sheet.dart`, `ConsumerStatefulWidget`, abierta con `showFrSheet`): `FrSheet` con título «Tu nombre» y el mensaje «Así te verán y escucharán en cada frecu.»; una `SignalSignature` de 120 px centrada que sigue al texto (`ValueListenableBuilder` del controlador); `FrField` con la etiqueta «Nombre visible», el nombre actual, `maxLength: Preferences.displayNameMaxLength`, `autofocus`, `TextInputAction.done` y `onSubmitted` que guarda; y un `FrButton` «Guardar» a todo el ancho. Guardar se habilita solo si `Preferences.normalizeDisplayName(texto) != null`; si el texto recortado no está vacío pero no es válido, el campo muestra `t.settings.editName.tooLong(max: 20)`. Al guardar muestra `loading`, llama a `setDisplayName` y, si sale bien, cierra la hoja; si falla, la deja abierta con `t.settings.editName.saveError` en el campo.
- **Textos** (`lib/i18n`, `es` y `en`): bajo `settings` — `title`, `back`, `displayName`, `noName`, `edit`, `voice`, `defaultTalkMode`, `defaultTalkModeHelp`, `talkMode.pushToTalk`, `talkMode.openMic`, `appearance`, `theme`, `themeHelp`, `themeMode.auto`, `themeMode.light`, `themeMode.dark`, `saveError`, `footer` y `editName.title`, `editName.message`, `editName.hint`, `editName.save`, `editName.tooLong` (con `{max}`), `editName.saveError`. Se quita `settings.language`. Se regenera con `dart run slang`.
- **Pruebas**: `settings_page_test.dart` (AC1 a AC4) y `settings_name_test.dart` (AC5 a AC7) montan `FrecuApp` como `test/app/saved_theme_test.dart`, hacen `push(const SettingsRoute())` y `pumpAndSettle`; los fallos de guardado usan un `InMemorySharedPreferencesAsync` que lanza al escribir, y «al reabrir» se comprueba con un contenedor nuevo de `createAppContainer()` sobre el mismo almacenamiento.

## Archivos

- modificar lib/features/settings/presentation/pages/settings_page.dart — Ajustes en Portadora con cabecera, secciones Voz y Apariencia, pie y avisos de error.
- crear lib/features/settings/presentation/widgets/settings_group.dart — etiqueta de sección, grupo y fila de Ajustes.
- crear lib/features/settings/presentation/widgets/profile_card.dart — tarjeta del nombre visible con su firma y el botón Editar.
- crear lib/features/settings/presentation/widgets/edit_name_sheet.dart — hoja para cambiar el nombre con firma en vivo y validación del dominio.
- modificar lib/i18n/strings.i18n.json — textos de Ajustes en español.
- modificar lib/i18n/strings_en.i18n.json — textos de Ajustes en inglés.
- modificar lib/i18n/strings.g.dart — traducciones generadas por slang.
- modificar lib/i18n/strings_es.g.dart — traducciones generadas por slang en español.
- modificar lib/i18n/strings_en.g.dart — traducciones generadas por slang en inglés.
- crear test/features/settings/presentation/settings_page_test.dart — pantalla, tema, modo de habla, fallos de guardado y textos en inglés.
- crear test/features/settings/presentation/settings_name_test.dart — tarjeta del nombre, hoja para cambiarlo y validación.

## Tareas

- [x] T1: Ajustes con tema y modo de habla por defecto
  - files: lib/features/settings/presentation/pages/settings_page.dart, lib/features/settings/presentation/widgets/settings_group.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/settings/presentation/settings_page_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: flutter test test/features/settings/presentation/settings_page_test.dart
- [x] T2: Nombre con su firma y hoja para cambiarlo
  - files: lib/features/settings/presentation/pages/settings_page.dart, lib/features/settings/presentation/widgets/profile_card.dart, lib/features/settings/presentation/widgets/edit_name_sheet.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/settings/presentation/settings_name_test.dart
  - ac: AC5, AC6, AC7
  - verify: flutter analyze && flutter test

## Riesgos

- R1: En un teléfono angosto el selector de tema de 196 px deja poco ancho al título de su fila — mitigación: el título y el subtítulo hacen salto de línea; se revisa a 360 px de ancho.
- R2: Un nombre de 20 grafemas con emojis compuestos pasa el límite del campo y no el del dominio — mitigación: Guardar se deshabilita y el campo muestra el error del largo (A3).
