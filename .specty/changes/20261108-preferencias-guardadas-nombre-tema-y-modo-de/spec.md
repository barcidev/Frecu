---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C6
allowedDependencies:
  - shared_preferences
  - shared_preferences_platform_interface
---

# Preferencias guardadas: nombre, tema y modo de habla por defecto (`features/settings` con `shared_preferences`)

## Objetivo

Guardar en el teléfono el nombre visible, el tema (Auto, Claro u Oscuro) y el modo de habla por defecto para que se conserven al reabrir la app. Este corte deja el repositorio y los providers listos y probados; el arranque (C7), Ajustes (C8) y la bienvenida (C12) los usarán.

## Fuera de alcance

- Aplicar el tema guardado al arrancar en `app.dart` y `bootstrap.dart`: C7.
- Pantalla de Ajustes con nombre, tema y modo de habla: C8. `settings_page.dart` no cambia.
- Bienvenida, pedir el nombre una sola vez y guard de primera apertura: C12 y C13.
- Usar el nombre guardado al crear o unirse a una frecu (`lobby`) y el modo de habla por defecto al entrar a una frecu (`room`).
- Idioma de la app como preferencia: se mantiene el idioma del sistema.
- Variante `Failure` propia de almacenamiento: tocaría `lib/core/error` (tercer módulo); se usa `Failure.unexpected`.

## Supuestos

- A1: `TalkMode` se reutiliza desde `features/room/domain/entities/talk_mode.dart`: `docs/arquitectura.md` solo prohíbe importar `data` y `presentation` de otra feature, y `lobby/domain` ya importa `room/domain`.
  - impacto: alto
- A2: Se usa la API `SharedPreferencesAsync` (la recomendada, sin caché en memoria); las pruebas la sustituyen por `InMemorySharedPreferencesAsync` de `shared_preferences_platform_interface`, que entra como dependencia de desarrollo.
- A3: Si la lectura falla, el provider entrega los valores por defecto (sin nombre, Auto y PTT) en lugar de un error, para que la app siga funcionando; el fallo queda en el log.
- A4: El nombre se guarda sin espacios al inicio ni al final y debe tener de 1 a 20 caracteres (el campo del prototipo usa `maxlength="20"`); un nombre que no cumple se rechaza sin tocar lo guardado.
- A5: Los valores se guardan como texto con el nombre del enum; un valor desconocido (por ejemplo, de una versión futura) se lee como el valor por defecto.

## Criterios de aceptación

- AC1: CUANDO se leen las preferencias sin nada guardado ENTONCES el nombre visible es nulo, el tema es Auto y el modo de habla por defecto es PTT.
- AC2: CUANDO se guardan el nombre, el tema y el modo de habla por defecto ENTONCES el provider expone los valores nuevos al instante y, al reabrir la app (un repositorio y un provider nuevos sobre el mismo almacenamiento), se leen los mismos valores.
- AC3: CUANDO se guarda un nombre con espacios alrededor ENTONCES se guarda recortado; CUANDO el nombre queda vacío o pasa de 20 caracteres ENTONCES se devuelve un fallo y el nombre guardado no cambia.
- AC4: CUANDO el almacenamiento falla al leer o escribir, o guarda un valor desconocido ENTONCES el repositorio devuelve `Result.failure` sin lanzar excepciones o usa el valor por defecto, y el provider conserva su estado anterior (o los valores por defecto si falla la lectura).

## Diseño

- **Dominio (`features/settings/domain`, Dart puro)**:
  - `ThemePreference` (`entities/theme_preference.dart`): enum `auto`, `light`, `dark`. C7 lo traduce a `ThemeMode` de Flutter fuera del dominio.
  - `Preferences` (`entities/preferences.dart`): Freezed con `displayName` (`String?`, nulo si aún no se pidió), `themePreference` (por defecto `auto`) y `defaultTalkMode` (`TalkMode`, por defecto `pushToTalk`). Constante `displayNameMaxLength = 20` y función pura `normalizeDisplayName(String)` que recorta y devuelve nulo si el nombre no es válido.
  - `PreferencesRepository` (`repositories/preferences_repository.dart`): `load()` → `Result<Preferences>`, `saveDisplayName(String)`, `saveThemePreference(ThemePreference)` y `saveDefaultTalkMode(TalkMode)` → `Result<void>`.
- **Datos (`features/settings/data/repositories/preferences_repository_impl.dart`)**: `PreferencesRepositoryImpl` recibe un `SharedPreferencesAsync`. Claves `settings.displayName`, `settings.themePreference` y `settings.defaultTalkMode`, con los enums guardados por `name`. Captura las excepciones del plugin, las registra con `AppLogger` y las devuelve como `Failure.unexpected`.
- **Presentación (`features/settings/presentation/providers/preferences_provider.dart`)**: `preferencesRepositoryProvider` (`@Riverpod(keepAlive: true)`) y `PreferencesNotifier` (`AsyncNotifier<Preferences>`, `keepAlive`, provider `preferencesProvider`) con `setDisplayName`, `setThemePreference` y `setDefaultTalkMode`: cada uno espera el estado cargado, guarda y, solo si se guardó, actualiza el estado; devuelve el `Result<void>` para que la pantalla muestre el fallo.

## Archivos

- modificar pubspec.yaml — dependencia `shared_preferences` y, de desarrollo, `shared_preferences_platform_interface` para las pruebas.
- modificar pubspec.lock — versiones resueltas de las dependencias nuevas.
- crear lib/features/settings/domain/entities/theme_preference.dart — enum del tema Auto, Claro y Oscuro.
- crear lib/features/settings/domain/entities/preferences.dart — entidad con nombre, tema y modo de habla por defecto, y validación del nombre.
- crear lib/features/settings/domain/entities/preferences.freezed.dart — código generado por Freezed.
- crear lib/features/settings/domain/repositories/preferences_repository.dart — contrato del repositorio de preferencias.
- crear lib/features/settings/data/repositories/preferences_repository_impl.dart — implementación con `SharedPreferencesAsync`.
- crear lib/features/settings/presentation/providers/preferences_provider.dart — provider del repositorio y `PreferencesNotifier`.
- crear lib/features/settings/presentation/providers/preferences_provider.g.dart — código generado por riverpod_generator.
- crear test/features/settings/domain/preferences_test.dart — valores por defecto y validación del nombre.
- crear test/features/settings/data/preferences_repository_test.dart — valores por defecto, guardar y reabrir, valores desconocidos y fallos del plugin.
- crear test/features/settings/presentation/preferences_provider_test.dart — estado inicial, cambios al instante, reabrir, validación del nombre y fallos.

## Tareas

- [x] T1: Dominio de preferencias
  - files: lib/features/settings/domain/entities/theme_preference.dart, lib/features/settings/domain/entities/preferences.dart, lib/features/settings/domain/entities/preferences.freezed.dart, lib/features/settings/domain/repositories/preferences_repository.dart, test/features/settings/domain/preferences_test.dart
  - ac: AC1, AC3
  - verify: flutter test test/features/settings/domain/preferences_test.dart
- [x] T2: Repositorio con `shared_preferences`
  - files: pubspec.yaml, pubspec.lock, lib/features/settings/data/repositories/preferences_repository_impl.dart, test/features/settings/data/preferences_repository_test.dart
  - ac: AC1, AC2, AC4
  - verify: flutter test test/features/settings/data/preferences_repository_test.dart
- [ ] T3: Providers de preferencias
  - files: lib/features/settings/presentation/providers/preferences_provider.dart, lib/features/settings/presentation/providers/preferences_provider.g.dart, test/features/settings/presentation/preferences_provider_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: flutter analyze && flutter test

## Riesgos

- R1: Las pruebas de widgets existentes que monten algo que lea `preferencesProvider` fallarían sin canal de plataforma — mitigación: en este corte nada de `app.dart` ni de las pantallas lo lee; C7 y C8 sobrescriben el repositorio o usan `InMemorySharedPreferencesAsync` en sus pruebas.
