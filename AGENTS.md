# Frecu

<!-- specty:begin id=project -->

## Proyecto (detectado por Specty)

- Stack: Flutter (Dart), Clean Architecture por feature

<!-- specty:end id=project -->

<!-- specty:begin id=flow -->

## Flujo de trabajo (Specty)

Este repositorio usa Specty. Antes de crear, modificar o borrar código, ejecuta `specty next` y sigue su salida hasta la línea `SIGUIENTE:`. Habla con el usuario en español.

- Si el usuario pide un cambio y no hay uno activo, `specty next` te indica cómo crear la spec (en proyectos nuevos, andamiaje con framework y globs en alcance como única excepción; en épicas, cortes verticales en paralelo).
- Cada cambio vive en su propia carpeta (una worktree): tras `specty new`, trabaja en la carpeta que indica, no en la principal. Entra con `specty enter <id>` (en Claude Code con `EnterWorktree`) y no pidas abrir otra sesión ni cambiar de rama.
- Completa cada tarea con `specty task done <id>`; no ejecutes `git commit` tú mismo.
- Si necesitas un archivo fuera del alcance de la tarea, pídelo con `specty scope add`.
- Aprobar, decidir el alcance, aceptar y cerrar lo decide solo el usuario en su terminal o UI (no alteres .git ni eludas permisos); pídeselo y ejecuta `specty wait` para esperar su decisión. Solo si `SIGUIENTE:` te lo pide (modo delegado), los ejecutas tú.
- Si el comando `specty` no existe, usa `npx -y @baquia-dev/specty <comando>`. Nunca uses `npx specty`: es otro paquete.

## Reglas (Specty)

- `specty task done` ya ejecuta `specty check --changed --spec` y la verificación de la tarea, y no la completa con fallos: no los repitas justo antes; corrige lo que devuelva y no reportes con fallos pendientes.
- Antes de crear un módulo, caso de uso, componente o pantalla, busca uno equivalente en el repo y replica su estructura.
- Localiza el código con búsquedas dirigidas por símbolo o texto y lee solo los fragmentos necesarios, no archivos completos; pide juntas, en la misma respuesta, las lecturas y búsquedas que no dependen entre sí.
- Edita con cambios puntuales; no reescribas archivos completos para cambios pequeños.
- Responde al usuario de forma directa y concisa en cada mensaje: primero el resultado o la pregunta; no repitas la salida de Specty, no narres cada paso ni enumeres opciones que no vas a seguir. En el reporte final, breve, di qué cambió, qué se verificó y qué queda pendiente de tu trabajo; de los demás pendientes, nombra solo los que tu trabajo resolvió, y márcalos con `specty memory resolve <id>`. Anota cada pendiente con `specty memory add "<texto>"` para que no se quede solo en el chat.

<!-- specty:end id=flow -->

## Mapa del repositorio

- [PRODUCT.md](PRODUCT.md): Visión, glosario, alcance MVP, fuera de alcance y stack tecnológico.
- [docs/dominio.md](docs/dominio.md): Términos del dominio (`Room`, `Participant`, `TalkMode`, `RoomInvite`).
- [docs/arquitectura.md](docs/arquitectura.md): Clean Architecture por feature, estructura de carpetas, reglas de dependencia (`domain` puro), contratos y manejo de errores con `Result<T>` y `Failure`.
- [docs/protocolo.md](docs/protocolo.md): Protocolo de red local, WebSocket (`0.0.0.0:47800`), mDNS, QR, WebRTC mesh sin STUN/TURN, y mensajes JSON con discriminador.
- [docs/audio.md](docs/audio.md): `audio_session`, PTT por `track.enabled`, micrófono abierto y ruteo altavoz / Bluetooth.
- [docs/plataforma.md](docs/plataforma.md): Permisos Android / iOS y Foreground Service persistente.
- [docs/fases.md](docs/fases.md): Plan de fases (0 a 6), estrategia de pruebas y Definition of Done.
- [docs/tiendas.md](docs/tiendas.md): Declaraciones para Google Play y App Store (datos, servicios en primer plano, permisos, capacidades) y lo pendiente antes de enviar.

## Convenciones

- **Riverpod**: Providers con `@riverpod` y `Notifier` / `AsyncNotifier`. Prohibido `StateNotifier` o `ChangeNotifier`.
- **Freezed**: Clases `sealed` o `abstract` (Freezed 3). Uniones exhaustivas con `switch`.
- **auto_route**: Pantallas con `@RoutePage()`.
- **slang**: Idioma base `es` (español), secundario `en`. Prohibido texto directo en widgets; siempre `t.<clave>`.
- **Arquitectura**: `domain` es Dart puro sin plugins ni `flutter`.
- **Comandos**:
  - `dart run build_runner build -d`
  - `dart run slang`
  - `flutter analyze`
  - `flutter test`
