---
kind: standard
epic: 20261106-descubrimiento-y-union
slice: C2
allowedDependencies:
  - qr_flutter
  - mobile_scanner
---

# Invitación y escaneo por código QR

## Objetivo

Permitir al anfitrión generar y mostrar un código QR de invitación con los parámetros de conexión de la sala, y a los participantes escanear dicho código con la cámara para unirse automáticamente a la frecu sin tener que ingresar la dirección IP ni el código de acceso manualmente.

## Fuera de alcance

- Topología mesh para más de 2 participantes (Fase 3).
- Modo Push-to-Talk y ruteo Bluetooth (Fase 4).
- Unión por enlaces web externos o NFC.

## Supuestos

- A1: El dispositivo participante cuenta con cámara funcional para capturar códigos QR.
  - impacto: alto
- A2: La URI codificada en el código QR sigue el esquema estándar `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
- A3: Ambos dispositivos se encuentran en la misma red local o el participante está conectado al punto de acceso del anfitrión.

## Criterios de aceptación

- AC4: CUANDO el anfitrión consulta la información de invitación de la frecu ENTONCES se genera y muestra un código QR con el formato URI `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
- AC5: CUANDO un participante escanea el código QR de invitación ENTONCES la aplicación parsea los parámetros de conexión y se une automáticamente a la sala sin ingresar la IP ni el código manualmente.

## Diseño

- **Domain**:
  - Entidad `RoomInvite`: `host`, `port`, `roomId`, `accessCode`.
  - Caso de uso `BuildInviteQr`: genera la URI `frecu://join?h=$host&p=$port&r=$roomId&c=$accessCode` a partir de `RoomInvite`.
  - Caso de uso `ParseInviteFromQr`: valida y parsea un string devolviendo `Result<RoomInvite>`. Valida esquema `frecu`, host/path `join` y parámetros query requeridos (`h`, `p`, `r`, `c`).
- **Data**:
  - Renderizado de QR con la librería `qr_flutter` mediante `QrImageView`.
  - Escaneo con la librería `mobile_scanner` mediante `MobileScanner`, desacoplado para permitir pruebas unitarias y de widgets.
- **Presentation**:
  - `RoomPage`: Botón de acción en la barra superior o tarjeta de información que abre el diálogo `_InviteQrDialog` para ver el código QR y datos de conexión.
  - `ScanQrPage`: Vista de escaneo con cámara que al detectar un código QR válido parsea los datos y ejecuta `roomNotifierProvider.joinRoom(...)`, redirigiendo automáticamente a `RoomPage`.

## Archivos

- modificar pubspec.yaml — añadir dependencias qr_flutter y mobile_scanner
- crear lib/features/room/domain/entities/room_invite.dart — entidad RoomInvite
- crear lib/features/room/domain/usecases/build_invite_qr.dart — caso de uso BuildInviteQr
- crear lib/features/lobby/domain/usecases/parse_invite_from_qr.dart — caso de uso ParseInviteFromQr
- crear test/features/room/domain/invite_qr_usecases_test.dart — pruebas unitarias de casos de uso de QR
- modificar lib/features/room/presentation/pages/room_page.dart — botón y diálogo de QR de invitación
- crear test/features/room/presentation/invite_qr_dialog_test.dart — pruebas de widget para diálogo QR
- modificar lib/features/lobby/presentation/pages/scan_qr_page.dart — vista de escaneo de QR y unión automática
- crear test/features/lobby/presentation/scan_qr_page_test.dart — pruebas de widget para escaneo y navegación

## Tareas

- [x] T1: Dependencias, entidad RoomInvite y casos de uso BuildInviteQr y ParseInviteFromQr con pruebas unitarias.
  - files: pubspec.yaml, lib/features/room/domain/entities/room_invite.dart, lib/features/room/domain/usecases/build_invite_qr.dart, lib/features/lobby/domain/usecases/parse_invite_from_qr.dart, test/features/room/domain/invite_qr_usecases_test.dart
  - ac: AC4, AC5
  - verify: fvm flutter test test/features/room/domain/invite_qr_usecases_test.dart
  - type: feat
- [x] T2: Diálogo y visualización de código QR en RoomPage con pruebas de widget.
  - files: lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/invite_qr_dialog_test.dart
  - ac: AC4
  - verify: fvm flutter test test/features/room/presentation/invite_qr_dialog_test.dart
  - type: feat
- [x] T3: Escáner de QR en ScanQrPage con unión automática a la sala y verificación completa.
  - files: lib/features/lobby/presentation/pages/scan_qr_page.dart, test/features/lobby/presentation/scan_qr_page_test.dart
  - ac: AC5
  - verify: fvm flutter analyze && fvm flutter test
  - type: feat

## Riesgos

- R1: Entornos de prueba de widgets no disponen de hardware de cámara — mitigación: desacoplar el widget del escáner permitiendo inyectar un widget mock o callback de detección para verificar el flujo de unión sin cámara física.

## Cierre

### Resumen

Se implementó el corte vertical C2 ("Invitación y escaneo por código QR") del epic `20261106-descubrimiento-y-union`.

- Se configuraron las dependencias `qr_flutter` y `mobile_scanner`.
- Se crearon la entidad `RoomInvite` y los casos de uso `BuildInviteQr` y `ParseInviteFromQr` con tests unitarios exhaustivos bajo TDD.
- En `RoomPage`, se añadió el botón de código QR en la AppBar y el diálogo `_InviteQrDialog` con `QrImageView` para mostrar la URI en formato `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
- En `ScanQrPage`, se integró `MobileScanner` con inyección desacoplada (`scannerBuilder`) para pruebas de widget, extrayendo los parámetros y conectando automáticamente con `roomNotifierProvider.joinRoom(...)` y navegando a `RoomRoute`.
- Se verificó el cumplimiento de todos los criterios de aceptación (AC4 y AC5) con 41 pruebas automatizadas pasando y 0 advertencias de análisis estático.

### Desviaciones

- Se añadió `lib/features/lobby/presentation/pages/lobby_page.dart` al alcance mediante ampliación (S6) debido a que `ScanQrRoute` dejó de ser un constructor constante al recibir `scannerBuilder` opcional para pruebas desacopladas.
- Se configuró `.specty/config.yaml` (`scope.generated`) para excluir archivos generados (`.freezed.dart`, `.g.dart`, `.gr.dart`) de los linters de complejidad y estilo estricto de Specty.

### Decisiones

- Se mantuvo la arquitectura limpia desacoplando la capa de dominio sin dependencias de Flutter ni plugins.
- Para habilitar pruebas de widget herméticas y deterministas sin hardware de cámara, se introdujo `ScannerWidgetBuilder` en `ScanQrPage`.
- Se mantuvo el alcance dentro del límite de 2 módulos de Specty (`room` y `lobby`) utilizando las traducciones existentes de slang sin crear módulos adicionales.

### Pendientes

- Ninguno para este corte vertical C2.
