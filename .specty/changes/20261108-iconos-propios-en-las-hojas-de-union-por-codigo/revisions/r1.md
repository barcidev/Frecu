---
kind: standard
epic: 20261108-pendientes-portadora
slice: C2
---

# Íconos propios en las hojas de unión por código e IP

## Objetivo

Las hojas de unión por código (`PinJoinSheet`) y por IP (`IpJoinSheet`) dejan los íconos de Material de sus campos y de su aviso de falla por los íconos dibujados de `FrIcons` del prototipo (`nodes`, `lock`, `users` y `alert`), con los constructores `FrField.drawn` y `FrBanner.drawn` que dejó C1 (P96). El aviso sin red del inicio también pasa a `FrIcons.wifi`, como en el prototipo (`screens.js:159`, P123). Cubre la parte de las hojas de unión de AC4 de la épica.

## Fuera de alcance

- El aviso de error de la nueva frecu (`new_room_step.dart`, `Icons.error_outline_rounded`) y `new_room_hero.dart`: los trabaja C3 en paralelo.
- Los íconos del aviso de eco y de Ajustes (C5 y C6).
- Quitar los constructores con `IconData` de `FrField` y `FrBanner` (A5 de la épica): siguen teniendo usos fuera de `features/lobby`.
- Cambiar textos, tonos, medidas o el comportamiento de las hojas y del aviso sin red.
- La acción «Abrir ajustes de Wi-Fi» del aviso sin red (P83, P86).

## Supuestos

- A1: Los íconos salen del prototipo (`screens.js`): `nodes` en «IP del anfitrión» y `lock` en «Código de acceso» (línea 250-251), `users` en el aviso ámbar de frecu llena (línea 238), `alert` en el aviso de alerta (línea 252) y `wifi` en el aviso sin red (línea 159). `FrIcons` no tiene un wifi tachado y el prototipo usa `wifi`.
- A2: `PinJoinSheet` e `IpJoinSheet` muestran sus fallas con el mismo `JoinFailureBanner` de `pin_join_sheet.dart`, así que cambiarlo ahí cubre las dos hojas.
- A3: Las pruebas aprobadas de las hojas y del inicio (`join_sheets_test.dart`, `lobby_page_test.dart`) no buscan íconos de Material (solo tono, título y mensaje del aviso, que no cambian), así que no se tocan.

## Criterios de aceptación

- AC1: CUANDO se abre la hoja de conexión por IP ENTONCES el campo «IP del anfitrión» dibuja `FrIcons.nodes` y el de «Código de acceso» dibuja `FrIcons.lock`, con `FrIcon` y sin ningún `Icon` de Material en la hoja.
- AC2: CUANDO una unión por código o por IP falla porque la frecu está llena ENTONCES el aviso ámbar dibuja `FrIcons.users`; CUANDO falla por otro motivo que no es el código (por ejemplo, el anfitrión no responde) ENTONCES el aviso de alerta dibuja `FrIcons.alert`; en los dos casos con `FrIcon` y sin ningún `Icon` de Material en la hoja.
- AC3: CUANDO el inicio no tiene red local ni frecus cercanas ENTONCES el aviso de alerta «No estás en ninguna red Wi-Fi.» dibuja `FrIcons.wifi` con `FrIcon`, sin ningún `Icon` de Material en el aviso.

## Diseño

- `IpJoinSheet._ipField` y `_codeField` pasan a `FrField.drawn` con `icon: FrIcons.nodes` y `icon: FrIcons.lock`.
- `JoinFailureBanner` pasa a `FrBanner.drawn` con `icon: full ? FrIcons.users : FrIcons.alert`.
- `LobbyOfflineNotice` pasa a `FrBanner.drawn` con `icon: FrIcons.wifi`.
- Se quitan los imports que queden sin uso.
- La prueba abre la app en el inicio como `join_sheets_test.dart` (mismos falsos de descubrimiento, red y frecus, movimiento reducido) y busca cada ícono como el widget `FrIcon` con su `icon`, sin depender de píxeles.

## Archivos

- modificar lib/features/lobby/presentation/widgets/ip_join_sheet.dart — campos de IP y código con `FrField.drawn` y `FrIcons.nodes` y `lock`.
- modificar lib/features/lobby/presentation/widgets/pin_join_sheet.dart — `JoinFailureBanner` con `FrBanner.drawn` y `FrIcons.users` y `alert`.
- modificar lib/features/lobby/presentation/widgets/lobby_sections.dart — aviso sin red con `FrBanner.drawn` y `FrIcons.wifi`.
- crear test/features/lobby/presentation/lobby_drawn_icons_test.dart — íconos propios de las hojas de unión y del aviso sin red.

## Tareas

- [ ] T1: Íconos propios en las hojas de unión y en el aviso sin red
  - files: lib/features/lobby/presentation/widgets/ip_join_sheet.dart, lib/features/lobby/presentation/widgets/pin_join_sheet.dart, lib/features/lobby/presentation/widgets/lobby_sections.dart, test/features/lobby/presentation/lobby_drawn_icons_test.dart
  - ac: AC1, AC2, AC3
  - verify: flutter test test/features/lobby/presentation/lobby_drawn_icons_test.dart test/features/lobby/presentation/join_sheets_test.dart test/features/lobby/presentation/lobby_page_test.dart

## Riesgos

- R1: C3 trabaja en paralelo en `features/lobby` — mitigación: este corte no toca `new_room_step.dart` ni `new_room_hero.dart`, y la prueba nueva no depende de la nueva frecu ni de la nota al crear.
