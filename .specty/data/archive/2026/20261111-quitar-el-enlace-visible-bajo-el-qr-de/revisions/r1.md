---
kind: quick
---

# Quitar el enlace visible bajo el QR de invitación

## Objetivo

En la hoja de invitación, debajo del QR y del botón «Compartir enlace» ya no se muestra el texto del enlace (host y ruta con el ícono de enlace). El botón de compartir se queda igual.

Criterio: `InviteShareLink` muestra solo el botón «Compartir enlace» (key `invite_share_button`), sin la fila con el ícono de enlace ni el texto `host/ruta`; compartir sigue enviando el enlace completo.

## Archivos

- modificar lib/features/room/presentation/widgets/invite_sheet.dart — quitar la fila del enlace en `InviteShareLink` y actualizar su comentario

## Tareas

- [ ] T1: Quitar la fila del enlace bajo el botón de compartir
  - files: lib/features/room/presentation/widgets/invite_sheet.dart
  - verify: flutter test test/features/room/presentation/internet_room_ui_test.dart
