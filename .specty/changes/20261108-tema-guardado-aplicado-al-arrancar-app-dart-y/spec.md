---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C7
---

# Tema guardado aplicado al arrancar (`app.dart` y `bootstrap.dart`)

## Objetivo

Que la app abra con el tema guardado (Auto, Claro u Oscuro) desde el primer cuadro, sin mostrar antes el tema del sistema, y que cambie de tema al instante cuando cambie la preferencia. Auto sigue al tema del sistema. Es la parte de arranque de AC1 de la épica; el selector en Ajustes llega en C8.

## Fuera de alcance

- Selector de tema en Ajustes: C8. `settings_page.dart` no cambia.
- Usar el nombre y el modo de habla guardados al crear, unirse o entrar a una frecu: cortes posteriores de la épica.
- Pantalla de carga propia o cambios en la pantalla de inicio nativa (splash).
- Temas de alto contraste.
- Cambios en `features/settings` (dominio, repositorio y providers de C6).

## Supuestos

- A1: `bootstrap.dart` espera la lectura de las preferencias antes de `runApp`; mientras tanto sigue visible la pantalla de inicio nativa, y leer `shared_preferences` del disco local tarda milisegundos.
  - impacto: alto
- A2: La traducción `ThemePreference` → `ThemeMode` vive en `app.dart`, fuera del dominio: `auto` → `ThemeMode.system`, `light` → `ThemeMode.light` y `dark` → `ThemeMode.dark`.
- A3: `FrecuApp` observa solo `themePreference` (con `select`), así que guardar el nombre o el modo de habla no reconstruye `MaterialApp`; mientras no haya preferencias leídas usa Auto.
- A4: Los cambios de tema con la app abierta conservan la transición animada de `MaterialApp` (`AnimatedTheme`); "sin parpadeo" se refiere al primer cuadro al abrir.
- A5: Las pruebas que montan la app usan por defecto un almacenamiento en memoria (`InMemorySharedPreferencesAsync`) configurado en `test/flutter_test_config.dart`, para no depender del plugin nativo.

## Criterios de aceptación

- AC1: CUANDO la app arranca con el tema Claro u Oscuro guardado ENTONCES el primer cuadro ya se pinta con ese tema de Portadora, aunque el sistema esté en el otro, sin pasar por el tema del sistema.
- AC2: CUANDO el tema guardado es Auto, no hay nada guardado o no se pudieron leer las preferencias ENTONCES la app arranca igual y sigue el tema claro u oscuro del sistema, también si el sistema cambia con la app abierta.
- AC3: CUANDO el tema guardado cambia con la app abierta ENTONCES toda la app pasa a ese tema al instante, sin reiniciar.

## Diseño

- **`lib/bootstrap.dart`**: función pública `createAppContainer()` que crea el `ProviderContainer` de la app y espera `preferencesProvider.future`; si la lectura lanza, lo registra con `AppLogger` y devuelve el contenedor igualmente (la app sigue en Auto). `bootstrap` la llama antes de `runApp` y monta la app con `TranslationProvider(child: UncontrolledProviderScope(container: …, child: app))` en lugar de `ProviderScope`.
- **`lib/app/app.dart`**: `FrecuApp` pasa a `ConsumerStatefulWidget` (mantiene el `AppRouter` inyectable). En `build` observa `preferencesProvider.select((p) => p.value?.themePreference ?? ThemePreference.auto)` y pasa `themeMode` a `MaterialApp.router` con un `switch` exhaustivo sobre `ThemePreference`. `theme` y `darkTheme` siguen siendo `AppTheme.light` y `AppTheme.dark`.
- **Pruebas**: `test/bootstrap_test.dart` comprueba que el contenedor de arranque ya trae el tema leído y que arranca aunque no haya almacenamiento; `test/app/saved_theme_test.dart` monta `FrecuApp` sobre ese contenedor y mide `MaterialApp.themeMode` y el `ColorScheme` del árbol en el primer cuadro y, tras cambiar el tema o el sistema, después de `pumpAndSettle`.

## Archivos

- modificar lib/bootstrap.dart — `createAppContainer()` lee las preferencias antes de `runApp` y la app se monta sobre ese contenedor con `UncontrolledProviderScope`.
- modificar lib/app/app.dart — `FrecuApp` observa el tema guardado y pasa `themeMode` a `MaterialApp.router` (Auto → sistema).
- modificar test/flutter_test_config.dart — almacenamiento de preferencias en memoria por defecto para las pruebas que montan la app.
- crear test/bootstrap_test.dart — precarga del tema guardado y arranque sin almacenamiento disponible.
- crear test/app/saved_theme_test.dart — primer cuadro con el tema guardado, Auto y fallos siguen al sistema, y cambio al instante.

## Tareas

- [x] T1: Precarga de preferencias en `bootstrap.dart`
  - files: lib/bootstrap.dart, test/bootstrap_test.dart
  - ac: AC1, AC2
  - verify: flutter test test/bootstrap_test.dart
- [ ] T2: Tema guardado aplicado en `app.dart`
  - files: lib/app/app.dart, test/flutter_test_config.dart, test/app/saved_theme_test.dart
  - ac: AC1, AC2, AC3
  - verify: flutter analyze && flutter test

## Riesgos

- R1: Si leer las preferencias se colgara, la app no pasaría de la pantalla de inicio nativa — mitigación: el plugin lee del disco local y sus fallos ya se convierten en valores por defecto; si apareciera, se añade un tiempo máximo en `createAppContainer`.
- R2: Las pruebas de widgets existentes que montan `FrecuApp` leerían `preferencesProvider` sin plugin de plataforma — mitigación: almacenamiento en memoria global en `test/flutter_test_config.dart` y `flutter test` completo en T2.
