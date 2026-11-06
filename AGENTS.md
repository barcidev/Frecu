# Frecu

<!-- specty:begin id=project -->
## Proyecto (detectado por Specty)
- Stack: sin detectar
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

## Mapa

<!-- Directorios no obvios, lo que no se toca y enlaces a PRODUCT.md y docs/ (arquitectura, protocolos). No pongas especificaciones de producto, arquitectura ni fases aquí: guárdalas en archivos dedicados. -->

## Convenciones

<!-- Solo lo que no se deduce del código ni verifica `specty check` (formato, lint, tipos, tests, tamaño, capas…). Mantén este archivo conciso (< 80 líneas). -->
