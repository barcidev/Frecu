---
kind: standard
epic: 20261108-pendientes-portadora
slice: C6
---

# Ajustes con íconos propios e idioma guardado

## Objetivo

Ajustes deja los íconos de Material por los dibujados de `FrIcons` (P61): atrás, editar, los modos de habla y el aviso de error. Además gana el grupo «General» del prototipo, por ahora con la fila «Idioma»: el usuario elige Auto (idioma del teléfono), Español o English, la app cambia de idioma al instante y lo conserva al volver a abrirla. Es la parte de AC4 de la épica que toca Ajustes y la fila «Idioma» de AC5; «Permisos» y «Guía del punto de acceso» las suma C7.

## Fuera de alcance

- Las filas «Permisos» y «Guía del punto de acceso» del grupo «General»: las suma C7.
- Un constructor de `FrToast` con `FrIconData` en `lib/core` (el límite de módulos lo deja fuera) y los íconos de Material de otras pantallas.
- Idiomas además de español e inglés, y textos de Ajustes que no sean del grupo «General».
- Cambios en `lib/app/app.dart`: ya pasa el idioma de slang a `MaterialApp`.

## Supuestos

- A1: `LocalePreference` es un enum de Dart puro en `features/settings/domain`, como `ThemePreference`, con `auto` (idioma del teléfono), `es` y `en`. `Preferences.localePreference` vale `auto` por defecto, y `PreferencesRepositoryImpl` lo guarda como texto con su `name` en `settings.localePreference`: un valor que no reconoce se lee como `auto`.
  - impacto: alto
- A2: Traducir `LocalePreference` a slang es cosa de presentación: una función `applyLocalePreference` junto a los providers de preferencias llama a `LocaleSettings.useDeviceLocale()` en `auto` y a `LocaleSettings.setLocale` en `es` y `en`, que es async porque el inglés se carga diferido. El dominio sigue sin Flutter.
  - impacto: alto
- A3: `PreferencesNotifier.setLocalePreference` guarda, luego aplica el idioma (esperando el inglés diferido) y solo entonces cambia el estado. Si no se pudo guardar, no cambia ni el idioma ni el estado, y Ajustes avisa con el mismo `FrToast` de error que el tema y el modo de habla.
- A4: Al cambiar el idioma de slang, `TranslationProvider` reconstruye toda la app con el idioma nuevo, también la pantalla abierta; se comprobó en una prueba de widgets. No hace falta reiniciar ni tocar `app.dart`.
- A5: `bootstrap.dart` lee primero las preferencias (`createAppContainer`) y luego aplica el idioma guardado con `applyLocalePreference`, en lugar de llamar siempre a `useDeviceLocale`: Auto, sin nada guardado o si no se pudieron leer, usa el idioma del teléfono. Para probarlo sin `runApp`, ese paso es una función pública, `applySavedLocale(container)`. `lib/bootstrap.dart` cuenta como un tercer módulo (`lib`), así que se pide con `specty scope add` en su tarea y no está en «Archivos».
  - impacto: alto
- A6: La fila «Idioma» sigue al prototipo (`UI.row('Idioma', 'Español', 'ES ›')`): de subtítulo, la elección (`Auto · Español` en Auto, con el idioma en uso; `Español` o `English`); a la derecha, el código del idioma en uso (`ES` o `EN`) en `labelS` y `tx2`, y `FrIcons.chevron` a 18 px en `tx3`. Toda la fila responde al toque.
- A7: `SettingsRow` suma `onPressed`: con él, la fila entera es presionable (`FrPressable`), se anuncia como botón y añade el chevron después de `trailing`. La fila «Idioma» (`LanguageRow`) vive con su hoja en `language_sheet.dart`, y el grupo «General» de `settings_page.dart` es un `SettingsGroup` con esa sola fila: C7 le suma «Permisos» (con su etiqueta `3/3`) y «Guía» como filas nuevas, sin tocar la del idioma.
- A8: La hoja de idioma sigue a `edit_name_sheet.dart` y a `FrSheet` (título «Idioma» y un mensaje), con las tres opciones al estilo `.opt` del prototipo, como `AudioRouteOption`: una caja de 44 px con `FrIcons.globe` en Auto y el código (`ES` o `EN`) en los idiomas, el nombre, en Auto la explicación «Sigue al teléfono», y la marca de elegida. Elegir una cierra la hoja y devuelve la elección; Ajustes la guarda.
- A9: «Español» y «English» se escriben en su propio idioma en las dos traducciones, como es costumbre en los selectores de idioma; «Auto» y las demás claves se traducen.
- A10: `FrToast.icon` solo acepta `IconData` y `lib/core` queda fuera por el límite de módulos, así que Ajustes arma el aviso con `FrToast(leading:)`: un círculo de 30 px con la señal al 14 % y `FrIcons.alert` a 16 px en `signalFg`, las mismas medidas que `FrToast.icon` (`.toast .tic` del prototipo).

## Criterios de aceptación

- AC1: CUANDO se abre Ajustes ENTONCES el botón Atrás dibuja `FrIcons.back`, el botón Editar de la tarjeta del nombre `FrIcons.edit` y los segmentos PTT y Abierto del modo de habla `FrIcons.walkie` y `FrIcons.openMic`, todos con `FrIcon`; CUANDO no se puede guardar una preferencia ENTONCES el aviso de error dibuja `FrIcons.alert`; y Ajustes no muestra ningún `Icon` de Material.
- AC2: CUANDO se abre Ajustes ENTONCES entre «Voz» y «Apariencia» aparece el grupo «General» con la fila «Idioma», que muestra la elección guardada (Auto con el idioma en uso, Español o English), el código del idioma en uso (ES o EN) y un chevron, con sus textos en español y en inglés.
- AC3: CUANDO el usuario toca «Idioma» ENTONCES se abre una hoja con Auto, Español y English, con la elección actual marcada; CUANDO elige una ENTONCES la hoja se cierra y Ajustes y el resto de la app pasan a ese idioma al instante, sin reiniciar (Auto: el idioma del teléfono).
- AC4: CUANDO se elige un idioma ENTONCES queda guardado y la app vuelve a abrir en ese idioma aunque el teléfono esté en otro; CUANDO la elección es Auto, no hay nada guardado, lo guardado no se reconoce o no se pudieron leer las preferencias ENTONCES abre en el idioma del teléfono.
- AC5: CUANDO no se puede guardar el idioma ENTONCES aparece el aviso de error y el idioma de la app y la fila «Idioma» siguen como estaban.

## Diseño

- **Dominio**: `lib/features/settings/domain/entities/locale_preference.dart` con `enum LocalePreference { auto, es, en }`. `Preferences` suma `@Default(LocalePreference.auto) LocalePreference localePreference` (Freezed regenerado) y `PreferencesRepository` suma `Future<Result<void>> saveLocalePreference(LocalePreference)`. `docs/dominio.md` suma «Idioma (`LocalePreference`)».
- **Datos**: `PreferencesRepositoryImpl.localePreferenceKey = 'settings.localePreference'`; `load` lo lee con `LocalePreference.values.asNameMap()` y `saveLocalePreference` usa `_save` con su `name`.
- **Providers** (`preferences_provider.dart`):
  - `Future<AppLocale> applyLocalePreference(LocalePreference)`, con un `switch` exhaustivo.
  - `PreferencesNotifier.setLocalePreference`: guardar, `applyLocalePreference` y luego el estado.
- **Ajustes**:
  - `settings_group.dart`: `SettingsRow.onPressed` con `FrPressable(pressedScale: 0.98)` y `FrIcons.chevron` después de `trailing`.
  - `language_sheet.dart`:
    - `LanguageRow({value, onChanged})`: la fila «Idioma», que abre `LanguageSheet.show` y, si vuelve una elección distinta, llama a `onChanged`.
    - `LanguageSheet`: un `FrSheet` con título y mensaje; `show` devuelve `Future<LocalePreference?>`.
    - `LanguageOption`: una opción `.opt` con `Key('language_option_<name>')`.
  - `settings_page.dart`:
    - Entre Voz y Apariencia, `SettingsSectionLabel(t.settings.general)` y un `SettingsGroup` con `LanguageRow`, que guarda con `_saveOrWarn`.
    - Íconos: `FrIconButton.drawn(FrIcons.back)` y los segmentos con `FrIcon(FrIcons.walkie)` y `FrIcon(FrIcons.openMic)`.
    - El aviso de `_saveOrWarn` es `FrToast(leading: _AlertBadge())`.
  - `profile_card.dart`: `FrButton.drawn(icon: FrIcons.edit)`.
- **Arranque**: en `lib/bootstrap.dart`, `applySavedLocale(ProviderContainer)` lee `preferencesProvider` del contenedor ya cargado (Auto si no hay valor) y llama a `applyLocalePreference`. `bootstrap` deja `useDeviceLocale` y llama a `createAppContainer()` y luego a `applySavedLocale` antes de `runApp`.
- **Textos** (`settings`, en es y en): `general`, y `language.title`, `language.message`, `language.auto`, `language.autoHelp`, `language.autoValue` (con `$language`), `language.es` y `language.en`.
- **Pruebas**: el inglés se carga con `tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en))` y se restaura con `addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es))`; los cambios desde la hoja también se esperan con `runAsync`. Ajustes se abre con movimiento reducido, porque la firma del perfil anima sin fin.

## Archivos

- crear lib/features/settings/domain/entities/locale_preference.dart — enum del idioma Auto, Español y English.
- modificar lib/features/settings/domain/entities/preferences.dart — `localePreference`, Auto por defecto.
- modificar lib/features/settings/domain/entities/preferences.freezed.dart — código generado por Freezed.
- modificar lib/features/settings/domain/repositories/preferences_repository.dart — contrato `saveLocalePreference`.
- modificar lib/features/settings/data/repositories/preferences_repository_impl.dart — leer y guardar el idioma en shared_preferences.
- modificar lib/features/settings/presentation/providers/preferences_provider.dart — `applyLocalePreference` y `setLocalePreference`, que guarda y aplica el idioma.
- modificar lib/features/settings/presentation/providers/preferences_provider.g.dart — código generado por riverpod_generator.
- modificar lib/features/settings/presentation/pages/settings_page.dart — íconos propios, aviso con `FrIcons.alert` y grupo General entre Voz y Apariencia.
- modificar lib/features/settings/presentation/widgets/profile_card.dart — Editar con `FrIcons.edit`.
- modificar lib/features/settings/presentation/widgets/settings_group.dart — fila presionable con chevron.
- crear lib/features/settings/presentation/widgets/language_sheet.dart — fila Idioma y hoja para elegir Auto, Español o English.
- modificar lib/i18n/strings.i18n.json — textos del grupo General y del idioma en español.
- modificar lib/i18n/strings_en.i18n.json — textos del grupo General y del idioma en inglés.
- modificar lib/i18n/strings.g.dart — traducciones generadas por slang.
- modificar lib/i18n/strings_es.g.dart — traducciones generadas por slang en español.
- modificar lib/i18n/strings_en.g.dart — traducciones generadas por slang en inglés.
- modificar docs/dominio.md — término Idioma (`LocalePreference`).
- crear test/features/settings/presentation/locale_preference_test.dart — Auto por defecto, guardar y reabrir, valor desconocido, idioma aplicado al guardar y fallos.
- crear test/bootstrap_locale_test.dart — el arranque aplica el idioma guardado o el del teléfono.
- crear test/features/settings/presentation/settings_icons_test.dart — íconos propios de Ajustes y aviso con `FrIcons.alert`, sin Material.
- crear test/features/settings/presentation/settings_language_test.dart — grupo General, fila Idioma, hoja, cambio al instante, reabrir, fallos e inglés.

## Tareas

- [ ] T1: `LocalePreference` guardado y aplicado al instante
  - files: lib/features/settings/domain/entities/locale_preference.dart, lib/features/settings/domain/entities/preferences.dart, lib/features/settings/domain/entities/preferences.freezed.dart, lib/features/settings/domain/repositories/preferences_repository.dart, lib/features/settings/data/repositories/preferences_repository_impl.dart, lib/features/settings/presentation/providers/preferences_provider.dart, lib/features/settings/presentation/providers/preferences_provider.g.dart, docs/dominio.md, test/features/settings/presentation/locale_preference_test.dart
  - ac: AC3, AC4, AC5
  - verify: flutter test test/features/settings
- [ ] T2: Idioma guardado aplicado al arrancar
  - files: test/bootstrap_locale_test.dart
  - ac: AC4
  - verify: flutter test test/bootstrap_locale_test.dart test/bootstrap_test.dart
- [ ] T3: Íconos propios en Ajustes
  - files: lib/features/settings/presentation/pages/settings_page.dart, lib/features/settings/presentation/widgets/profile_card.dart, test/features/settings/presentation/settings_icons_test.dart
  - ac: AC1
  - verify: flutter test test/features/settings/presentation/settings_icons_test.dart test/features/settings/presentation/settings_page_test.dart test/features/settings/presentation/settings_name_test.dart
- [ ] T4: Grupo General con la fila Idioma y su hoja
  - files: lib/features/settings/presentation/pages/settings_page.dart, lib/features/settings/presentation/widgets/settings_group.dart, lib/features/settings/presentation/widgets/language_sheet.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/settings/presentation/settings_language_test.dart
  - ac: AC2, AC3, AC5
  - verify: flutter analyze && flutter test

## Riesgos

- R1: `lib/bootstrap.dart` es un tercer módulo y necesita un permiso de alcance — mitigación: se pide con `specty scope add` al empezar T2; si no se concede, el arranque queda como pendiente y la fila «Idioma» funciona igual con la app abierta.
- R2: El inglés se carga diferido y el reloj falso de las pruebas no lo espera — mitigación: `runAsync` al cargarlo y en los cambios desde la hoja, y restaurar el español con `setLocaleSync`.
- R3: El grupo General alarga Ajustes y las pruebas aprobadas tocan el tema y el modo de habla por su texto — mitigación: con el grupo, Ajustes cabe entera en 390 × 844 y esas pruebas no se tocan.
