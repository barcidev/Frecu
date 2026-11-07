---
kind: standard
epic: 20261107-sistema-diseno-portadora
slice: C12
---

# Bienvenida, nombre con firma en vivo y permisos

## Objetivo

Convertir la ruta de permisos en el recorrido de la primera vez del prototipo aprobado (`docs/diseno/prototipo/screens.js`, pantallas `welcome`, `name` y `perms`): la bienvenida con la malla de 6 lugares, el nombre con la firma de señal que sigue al texto en vivo y se guarda con `preferencesProvider`, y los tres permisos con su porqué, que esta vez sí se piden. Cubre la parte de pantallas de AC3 y AC8 de la épica; hoy `PermissionsPage` es Material genérica y su botón no hace nada.

## Fuera de alcance

- Decidir cuándo se abre el recorrido (solo en la primera apertura, o directo a los permisos si ya hay nombre) y usar el nombre al crear o unirse a una frecu: C13 (`lib/app/router` y `lobby`).
- Arranque del prototipo (splash nativo e intro de la portadora que se pliega en la firma): no está en ningún corte de la épica; se anota como pendiente.
- Transiciones del router de la app (P53): el recorrido usa `FrPageRoute` solo dentro de su ruta, y llega al inicio sin la onda.
- Grupo «General» de Ajustes con el acceso a los permisos (P62) y pedir la cámara (se pide al escanear un QR).
- Cambios en `lib/core/design`, `lib/app`, el dominio y los datos de `features/permissions` y `features/settings`.

## Supuestos

- A1: Los tres pasos viven dentro de `PermissionsRoute`, en un `Navigator` anidado con `FrPageRoute` (onda al avanzar, salida al volver), así que no hace falta registrar rutas en `lib/app/router`; el recorrido siempre empieza en la bienvenida y C13 decidirá cuándo abrirlo.
  - impacto: alto
- A2: Tras pedir los permisos, Continuar aparece aunque alguno se haya negado: la app no bloquea a quien niega uno, y la fila negada ofrece «Ajustes» para concederlo después.
  - impacto: alto
- A3: «Red local y dispositivos cercanos» pide `AppPermission.bluetoothConnect` (`BLUETOOTH_CONNECT` de Android 12+; antes el sistema lo da por concedido). En iOS no hay permiso de ejecución para la red local ni para audífonos Bluetooth (`permission_handler` lo da por negado para siempre), así que allí no se pide y la fila se muestra concedida.
  - impacto: alto
- A4: Un permiso `granted`, `limited` o `provisional` cuenta como concedido. Al leer los estados, `denied` es pendiente (Android no distingue «nunca pedido») y `permanentlyDenied` o `restricted` es negado; tras pedirlo, todo lo que no es concedido es negado.
- A5: El nombre sigue la regla de C6 como en Ajustes (C8, P48): el campo usa `maxLength: Preferences.displayNameMaxLength` y Continuar se habilita solo si `Preferences.normalizeDisplayName` acepta el texto (cuenta `runes`).
- A6: Las pruebas abren la app con `createAppContainer()` y un almacenamiento en memoria, con movimiento reducido para que la malla y la firma no animen sin fin, y sobrescriben `permissionRepositoryProvider` con un repositorio falso.
- A7: `test/app_test.dart` («redirects to PermissionsPage…») esperaba el título y el botón de la página genérica; pasa a esperar la bienvenida, con movimiento reducido.

## Criterios de aceptación

- AC1: CUANDO se abre la ruta de permisos ENTONCES el recorrido empieza en la bienvenida, en Portadora (`FrScaffold`): los pasos con el primero encendido y «01 / 03», la malla de 6 lugares, el aviso «Sin internet · sin cobertura», el título «Todo tu grupo en la misma frecu.», el texto y el botón Empezar; todos los textos del recorrido salen de slang en español y en inglés.
- AC2: CUANDO se dibuja la malla de la bienvenida ENTONCES sus 6 lugares, cada uno con la firma de su nombre, giran despacio sobre una elipse unidos por enlaces como en `drawOrbit` del prototipo, y cada 2,6 s habla el siguiente: su firma ondula con la voz simulada y salen paquetes hacia los demás.
- AC3: CUANDO el usuario toca Empezar ENTONCES pasa al paso del nombre (segundo paso encendido, «02 / 03») con el título «¿Cómo te llamamos?», el texto, la firma de señal en su escenario con la leyenda, el campo «Nombre visible» con su ayuda (y el nombre guardado si ya había uno) y Continuar; Atrás o el gesto de volver del sistema regresan al paso anterior sin perder lo escrito.
- AC4: CUANDO el usuario escribe su nombre ENTONCES la firma del escenario sigue al texto en vivo y habla con la voz simulada (`frVoice(t) * 0.55`).
- AC5: CUANDO el usuario toca Continuar o confirma desde el teclado con un nombre válido ENTONCES el nombre se guarda sin espacios alrededor con `preferencesProvider`, se conserva al reabrir la app y el recorrido pasa a los permisos.
- AC6: CUANDO el nombre queda vacío o solo con espacios, o pasa de 20 caracteres contados como el dominio (`runes`) ENTONCES Continuar queda deshabilitado, confirmar desde el teclado no avanza y, si pasa del largo, el campo muestra el error del largo; el campo limita el texto a `Preferences.displayNameMaxLength`; CUANDO el guardado falla ENTONCES el recorrido sigue en el nombre con el error en el campo.
- AC7: CUANDO se llega a los permisos ENTONCES se ven el tercer paso encendido y «03 / 03», el título «Tres permisos y listo.», el texto, las filas de micrófono, red local y dispositivos cercanos, y notificaciones, cada una con su porqué y su estado actual, la nota de que la cámara se pide solo al escanear un QR y el botón Conceder permisos, o Continuar si ya están todos concedidos.
- AC8: CUANDO el usuario toca Conceder permisos ENTONCES se piden uno por uno los que faltan; cada fila muestra su resultado (concedido con la marca de señal; negado con el borde de alerta y un botón Ajustes que abre los ajustes de la app) y el botón pasa a Continuar aunque alguno se haya negado; CUANDO el usuario vuelve a la app ENTONCES se leen de nuevo los estados.
- AC9: CUANDO el usuario toca Continuar en los permisos ENTONCES el recorrido termina en el inicio (`LobbyRoute`) como única pantalla.
- AC10: CUANDO el sistema pide reducir el movimiento ENTONCES la malla de la bienvenida y la firma del nombre quedan en un cuadro fijo y visibles, los pasos cambian con un fundido y la marca de concedido aparece sin resorte, sin ocultar ningún estado.

## Diseño

Referencia: pantallas `welcome`, `name` y `perms` de `docs/diseno/prototipo/screens.js`, con `.topline`, `.h-screen`, `.p-screen`, `.kicker`, `.hero-c`, `.sig-stage` y `.dock` de `screens.css`, `.perm` y `.steps` de `ui.css` y `drawOrbit` de `engine.js`. Todo con `context.fr` e íconos `FrIcons`, sin colores sueltos ni texto directo.

- **`PermissionsPage`** (`permissions_page.dart`, `@RoutePage()`, `StatefulWidget`): un `NavigatorPopHandler` con un `Navigator` anidado cuya ruta inicial es la bienvenida. Avanzar hace `push` de un `FrPageRoute(transition: FrTransition.wave)` con el paso siguiente; Atrás y el gesto de volver hacen `maybePop` del anidado, y en la bienvenida el gesto sale de la ruta. Al terminar los permisos, `context.router.replaceAll([const LobbyRoute()])`.
- **`onboarding_layout.dart`**: `OnboardingTopLine` (alto 44, relleno 10 22 0, o 10 a la izquierda con Atrás: `FrIconButton.drawn(FrIcons.back)` ghost compacto; `FrSteps(count: 3, current: paso)` y el contador `t.permissions.stepOf` en `labelS` y `tx3`) y `OnboardingHeading` (relleno 0 20; título `.h-screen`: Archivo 720 a 30 px, alto 1,06, ancho 122, interletrado −0,6; texto `.p-screen`: 15,5 px, alto 1,55, `tx2`; separación 10).
- **`WelcomeMesh`** (`welcome_mesh.dart`): un `FrLoop` que mueve un `CustomPaint` (4 anillos elípticos en `ink` del 5 % al 2,6 %, enlaces entre todos en `ink` al 7 % o en el color de quien habla al 28 %, paquetes de 2 px con halo desde quien habla y el disco `bg0` de 30 px de radio de cada lugar, con borde `ink` al 12 % o el color de quien habla al 60 %) y un `Flow` que coloca encima la `SignalSignature` de 40 px (radio 0,5) de cada nombre. Lugar `i` en el instante `t`: ángulo −π/2 + i·2π/6 + 0,06·t, radio 118 + 10·sin(0,5·t + i) (escalado si el ancho es menor de 390 px), centro (ancho/2, alto/2 + 6) y eje vertical × 0,86. Habla `floor(t / 2,6) % 6`, con `levelOf` = `frVoice(t, i)` para quien habla y 0 para los demás. Nombres del prototipo (Jorge, Ana, Leo, Sofi, Andrés, Marta) y colores `signal`, `p1`…`p5`. Con movimiento reducido `FrLoop` congela el cuadro.
- **`WelcomeStep`** (`welcome_step.dart`): `FrScaffold` con `OnboardingTopLine` sin Atrás, la malla en 380 px, el bloque `.copy` (relleno 0 24, separación 14: aviso con la raya de 16 × 1 px en `signalFg` y el texto en `label` mayúsculas `tx3`, título y texto) y el dock con `FrButton.drawn` «Empezar» y `FrIcons.arrow` a todo el ancho.
- **`NameStep`** (`name_step.dart`, `ConsumerStatefulWidget`): contenido desplazable sobre el dock; `OnboardingTopLine` con Atrás, `OnboardingHeading`, el escenario de la firma (alto 270 y margen inferior 18: círculo de 236 px con borde `line1` y degradado radial de `signal` al 6 %, anillo de marcas cada 6° entre 112 y 118 px en `line3` al 70 %, `SignalSignature` de 210 px, radio 0,4, modo `speak`, `levelOf: (t) => frVoice(t) * 0.55` y el nombre del campo por `ValueListenableBuilder`, y la leyenda en `labelS` mayúsculas `tx3` abajo) y `FrField` («Nombre visible», ayuda, `maxLength: Preferences.displayNameMaxLength`, `TextInputAction.done`). El controlador se llena una vez con el nombre guardado. Continuar (`FrButton.drawn` con `FrIcons.arrow`) se habilita con `normalizeDisplayName`; guarda con `setDisplayName` mostrando `loading` y, si sale bien, avanza; el error del largo y el del guardado van en el campo, como en `EditNameSheet`.
- **`OnboardingPermissions`** (`onboarding_permissions_provider.dart`, `@riverpod` `AsyncNotifier`): estado Freezed `OnboardingPermissionsState` con el estado de cada permiso (`PermissionState.pending`, `granted`, `denied`), `requesting` y `requested`; `allGranted` y `canContinue` (`requested || allGranted`). Lista `onboardingPermissions`: micrófono, `bluetoothConnect` y notificaciones. `build` lee los estados con `checkStatus` (A4); `requestMissing()` pide en orden los no concedidos y actualiza cada fila al llegar su resultado; `refresh()` relee los estados sin bajar uno ya negado a pendiente; `openSettings()` abre los ajustes de la app. En iOS no pide `bluetoothConnect` y lo da por concedido (A3).
- **`PermissionRow`** (`permission_row.dart`): `.perm` (relleno 14, radio 20, `bg1`, borde `line1` y filo `spec`; ícono en caja de 46 px con radio 15 en `bg2`; título Archivo 620 a 15 px ancho 106 y porqué a 12,5 px en `tx2`; separación 14). Pendiente: círculo de 30 px con borde `line2`. Concedido: caja en `signalFg` con borde de señal al 45 % y lavado al 7 %·`washK`, y el círculo en `signal` con `FrIcons.check` en `signalInk` y halo, que entra con el resorte `organic` (fundido con movimiento reducido). Negado: borde `alert` al 40 %, ícono en `alert` y una píldora «Ajustes» (`FrPressable`, `labelS` en `alert`) que llama a `onOpenSettings`. `Semantics` con el título y el estado.
- **`PermissionsStep`** (`permissions_step.dart`, `ConsumerStatefulWidget`): `OnboardingTopLine` con Atrás, `OnboardingHeading`, las tres filas (`FrIcons.mic`, `wifi` y `bell`, separación 10, margen superior 24), la nota de la cámara (`FrIcons.camera` de 16 px y `bodyS` en `tx3`, margen 16) y el dock: Conceder permisos (`FrIcons.check`, `loading` mientras pide) o Continuar (`FrIcons.arrow`). Un `AppLifecycleListener` llama a `refresh()` al volver a la app.
- **Textos** (`lib/i18n`, `es` y `en`), todo bajo `permissions`: `back`, `stepOf` (`$current / $total`), `welcome.kicker`, `welcome.title`, `welcome.message`, `welcome.start`, `name.title`, `name.message`, `name.signature`, `name.label`, `name.hint`, `name.help`, `name.tooLong` (`$max`), `name.saveError`, `name.next`, `title`, `description`, `microphone`, `microphoneDesc`, `nearbyDevices`, `nearbyDevicesDesc`, `notifications`, `notificationsDesc`, `camera`, `grant`, `openSettings`, `finish`, `status.pending`, `status.granted` y `status.denied`. Se quita `permissions.granted`. Se regenera con `dart run slang`.

## Archivos

- modificar lib/features/permissions/presentation/pages/permissions_page.dart — recorrido de bienvenida, nombre y permisos en un `Navigator` anidado.
- crear lib/features/permissions/presentation/widgets/onboarding_layout.dart — línea superior con pasos y contador, y título con texto del recorrido.
- crear lib/features/permissions/presentation/widgets/welcome_mesh.dart — malla animada de 6 lugares con firmas de la bienvenida.
- crear lib/features/permissions/presentation/widgets/welcome_step.dart — paso de bienvenida.
- crear lib/features/permissions/presentation/widgets/name_step.dart — paso del nombre con la firma en vivo y el guardado.
- crear lib/features/permissions/presentation/providers/onboarding_permissions_provider.dart — estado, lectura y solicitud de los permisos del recorrido.
- crear lib/features/permissions/presentation/providers/onboarding_permissions_provider.g.dart — provider generado por riverpod_generator.
- crear lib/features/permissions/presentation/providers/onboarding_permissions_provider.freezed.dart — estado generado por Freezed.
- crear lib/features/permissions/presentation/widgets/permission_row.dart — fila de un permiso con su porqué y su estado.
- crear lib/features/permissions/presentation/widgets/permissions_step.dart — paso de permisos.
- modificar lib/i18n/strings.i18n.json — textos del recorrido en español.
- modificar lib/i18n/strings_en.i18n.json — textos del recorrido en inglés.
- modificar lib/i18n/strings.g.dart — traducciones generadas por slang.
- modificar lib/i18n/strings_es.g.dart — traducciones generadas por slang en español.
- modificar lib/i18n/strings_en.g.dart — traducciones generadas por slang en inglés.
- crear test/features/permissions/presentation/welcome_test.dart — malla (posiciones, quién habla y cuadro fijo), bienvenida, textos en inglés y movimiento reducido.
- crear test/features/permissions/presentation/name_step_test.dart — paso del nombre: firma en vivo, guardado, validación y volver.
- crear test/features/permissions/presentation/permissions_step_test.dart — lectura, solicitud y relectura de los permisos, paso de permisos, Ajustes y salida al inicio.
- modificar test/app_test.dart — la redirección a permisos ahora muestra la bienvenida.

## Tareas

- [x] T1: Recorrido y bienvenida con la malla animada
  - files: lib/features/permissions/presentation/widgets/welcome_mesh.dart, lib/features/permissions/presentation/widgets/onboarding_layout.dart, lib/features/permissions/presentation/widgets/welcome_step.dart, lib/features/permissions/presentation/pages/permissions_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/permissions/presentation/welcome_test.dart, test/app_test.dart
  - ac: AC1, AC2, AC10
  - verify: flutter test test/features/permissions/presentation/welcome_test.dart test/app_test.dart
- [x] T2: Nombre con la firma en vivo
  - files: lib/features/permissions/presentation/widgets/name_step.dart, lib/features/permissions/presentation/pages/permissions_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/permissions/presentation/name_step_test.dart
  - ac: AC3, AC4, AC5, AC6, AC10
  - verify: flutter test test/features/permissions/presentation/name_step_test.dart
- [x] T3: Permisos pedidos con su estado y salida al inicio
  - files: lib/features/permissions/presentation/providers/onboarding_permissions_provider.dart, lib/features/permissions/presentation/providers/onboarding_permissions_provider.g.dart, lib/features/permissions/presentation/providers/onboarding_permissions_provider.freezed.dart, lib/features/permissions/presentation/widgets/permission_row.dart, lib/features/permissions/presentation/widgets/permissions_step.dart, lib/features/permissions/presentation/pages/permissions_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, lib/i18n/strings.g.dart, lib/i18n/strings_es.g.dart, lib/i18n/strings_en.g.dart, test/features/permissions/presentation/permissions_step_test.dart
  - ac: AC7, AC8, AC9, AC10
  - verify: flutter analyze && flutter test

## Riesgos

- R1: La bienvenida anima 7 bucles a la vez (la malla y 6 firmas) — mitigación: `RepaintBoundary` en cada firma, repintado por `Listenable` sin reconstruir y pausa de los pasos que quedan debajo (`TickerMode` del `Navigator` anidado); el perfilado en un teléfono real sigue en P33.
- R2: El gesto de volver del sistema podría cerrar la ruta entera en vez de volver un paso — mitigación: `NavigatorPopHandler` sobre el `Navigator` anidado y una prueba con `handlePopRoute`.
- R3: Con el teclado abierto el paso del nombre no cabe en 844 px — mitigación: contenido desplazable con relleno inferior del alto del dock.
