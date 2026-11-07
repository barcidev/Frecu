---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C13
---

# Primera apertura y nombre guardado al crear o unirse a una frecu

## Objetivo

Que el recorrido de la primera vez (bienvenida, nombre y permisos, C12) se abra solo cuando hace falta: en la primera apertura, sin nombre guardado, o cuando queda algún permiso por pedir; en las demás aperturas la app va directo al inicio. Y que crear una frecu o unirse a ella use el nombre guardado, sin volver a pedirlo. Cierra AC3 de la épica: hoy la app abre siempre el inicio (el guard de permisos deja pasar siempre), `lobby_page.dart` pide el nombre en sus diálogos y `scan_qr_page.dart` usa «Participante» fijo.

## Fuera de alcance

- Rediseño visual del inicio (C15) y de las hojas de código, IP y escáner (C16): aquí solo se quita el campo del nombre y se usa el guardado.
- Saltar la bienvenida y el nombre cuando ya hay nombre y faltan permisos: necesita un paso inicial en `PermissionsPage` (`features/permissions`, un tercer módulo); queda anotado.
- Modo de habla por defecto al entrar a una frecu (P49): se aplica al entrar, en `features/room`, y queda para C18.
- Quitar de slang `lobby.yourName`, que deja de usarse (`lib/i18n`, un tercer módulo).
- Arranque del prototipo (splash nativo e intro de la portadora).

## Supuestos

- A1: Con el nombre guardado y algún permiso por pedir, el recorrido se abre desde la bienvenida y su paso del nombre trae el nombre guardado ya escrito (C12 lo llena), así que basta con tocar Continuar; ir directo a los permisos exige cambiar `PermissionsPage` y queda pendiente.
  - impacto: alto
- A2: «Faltan permisos» quiere decir que algún permiso del recorrido (`onboardingPermissions`) está `PermissionState.pending` en `onboardingPermissionsProvider`: sin pedir aún, o negado una vez con el sistema dispuesto a pedirlo otra vez. Uno negado para siempre no reabre el recorrido, porque solo se concede desde los ajustes del teléfono (la fila ya ofrece «Ajustes»).
  - impacto: alto
- A3: La decisión se toma una vez por apertura, al resolver la ruta inicial con el `deepLinkBuilder` de auto_route en `lib/app/app.dart`, y no en `PermissionsGuard`: el guard sigue en cada navegación al inicio (también al terminar el recorrido), mientras que la ruta inicial se resuelve una sola vez, así que terminar el recorrido con un permiso negado no lo vuelve a abrir. Así el corte cabe en `lib/app` y `lobby` sin tocar `lib/app/router`. Si la comprobación falla, se registra y la app va al inicio.
  - impacto: alto
- A4: `preferencesProvider` ya está cargado al llegar al inicio (se precarga al arrancar, C7), así que el lobby lee el nombre sin esperar. Si aún no hay nombre (solo si falla el almacenamiento), unirse usa «Participante», como hasta ahora, y crear deja el de siempre del repositorio («Anfitrión»).
- A5: Un router inyectado en `FrecuApp` (las pruebas) abre la ruta que pida su prueba, sin la comprobación de la primera apertura, así que las pruebas existentes que montan la app con `AppRouter()` no cambian. `PermissionsGuard` queda como está (deja pasar salvo con `hasPermissions: false`, que solo usa `test/app_test.dart`); quitarlo queda anotado para un corte que toque `lib/app/router`.

## Criterios de aceptación

- AC1: CUANDO la app se abre sin nombre guardado ENTONCES muestra la bienvenida del recorrido de la primera vez en lugar del inicio.
- AC2: CUANDO la app se abre con el nombre guardado y algún permiso del recorrido por pedir ENTONCES muestra la bienvenida del recorrido, y su paso del nombre trae el nombre guardado ya escrito.
- AC3: CUANDO la app se abre con el nombre guardado y los permisos del recorrido concedidos o negados para siempre ENTONCES va directo al inicio, sin la bienvenida.
- AC4: CUANDO el recorrido termina, aunque se haya negado algún permiso ENTONCES el inicio queda como única pantalla y el recorrido no se vuelve a abrir mientras la app siga abierta, tampoco al volver al inicio.
- AC5: CUANDO el usuario se une a una frecu cercana con su código, por IP o escaneando un QR ENTONCES no se le pide el nombre y la unión usa el nombre guardado en ese momento (el último que cambió en Ajustes).
- AC6: CUANDO el usuario crea una frecu ENTONCES no se le pide el nombre y la frecu se abre con el nombre guardado como anfitrión.

## Diseño

- **`needsOnboardingProvider`** (`lib/app/needs_onboarding_provider.dart`, `@riverpod` que se libera solo): `true` si `preferencesProvider` no tiene nombre o si algún permiso de `onboardingPermissions` está `PermissionState.pending` en `onboardingPermissionsProvider`; solo lee los permisos si hay nombre.
- **`FrecuApp`** (`lib/app/app.dart`): sin router inyectado pasa a `_appRouter.config` un `deepLinkBuilder`. Para el enlace inicial (`PlatformDeepLink.initial`) lee una vez `needsOnboardingProvider.future` con `ref.listenManual` (y cierra la suscripción, para no dejar vivos los permisos leídos) y devuelve `DeepLink.single(const PermissionsRoute())` si hace falta el recorrido, o el mismo enlace (el inicio) si no; si la lectura falla, lo registra con `AppLogger.e` y devuelve el enlace. Los demás enlaces pasan igual. El recorrido termina, como en C12, con `replaceAll([LobbyRoute()])`.
- **Nombre en el lobby** (`lib/features/lobby/presentation/extensions/display_name_extension.dart`): extensión `SavedDisplayName` sobre `WidgetRef` con `savedDisplayName` (el nombre de `preferencesProvider`, o nulo) y `joinDisplayName` (el guardado o «Participante»). `_PinJoinDialog` y `_JoinRoomDialog` de `lobby_page.dart` pierden el campo y el controlador del nombre y se unen con `joinDisplayName`; `ScanQrPage` también; `CreateRoomPage` pasa `displayName: savedDisplayName` a `createRoom`. Se lee al tocar el botón, así que un cambio en Ajustes vale para la siguiente unión.

## Archivos

- crear lib/app/needs_onboarding_provider.dart — si hace falta el recorrido: sin nombre guardado o con algún permiso por pedir.
- crear lib/app/needs_onboarding_provider.g.dart — provider generado por riverpod_generator.
- modificar lib/app/app.dart — la ruta inicial es el recorrido o el inicio según la comprobación de la primera apertura.
- crear lib/features/lobby/presentation/extensions/display_name_extension.dart — nombre guardado para crear una frecu o unirse a ella.
- modificar lib/features/lobby/presentation/pages/lobby_page.dart — los diálogos de unión dejan de pedir el nombre y usan el guardado.
- modificar lib/features/lobby/presentation/pages/scan_qr_page.dart — la unión por QR usa el nombre guardado en vez de «Participante».
- modificar lib/features/lobby/presentation/pages/create_room_page.dart — crear una frecu pasa el nombre guardado como anfitrión.
- crear test/app/first_open_test.dart — cuándo se abre el recorrido al abrir la app y que no se reabre al terminar.
- crear test/features/lobby/presentation/saved_name_test.dart — unirse por código, IP y QR y crear con el nombre guardado, sin pedirlo.

## Tareas

- [x] T1: Recorrido solo en la primera apertura o con permisos por pedir
  - files: lib/app/needs_onboarding_provider.dart, lib/app/needs_onboarding_provider.g.dart, lib/app/app.dart, test/app/first_open_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: flutter test test/app/first_open_test.dart test/app_test.dart
- [x] T2: Nombre guardado al crear o unirse a una frecu
  - files: lib/features/lobby/presentation/extensions/display_name_extension.dart, lib/features/lobby/presentation/pages/lobby_page.dart, lib/features/lobby/presentation/pages/scan_qr_page.dart, lib/features/lobby/presentation/pages/create_room_page.dart, test/features/lobby/presentation/saved_name_test.dart
  - ac: AC5, AC6
  - verify: flutter analyze && flutter test

## Riesgos

- R1: Si la decisión se tomara en cada navegación al inicio, terminar el recorrido con un permiso negado devolvería al recorrido sin fin — mitigación: se toma solo con el enlace inicial y la prueba de AC4 termina el recorrido negando un permiso.
- R2: Al abrir, la primera pantalla espera la lectura de los permisos (un canal de plataforma) antes de dibujarse — mitigación: las preferencias ya están precargadas y solo se leen los permisos si hay nombre; es una lectura local de milisegundos.
