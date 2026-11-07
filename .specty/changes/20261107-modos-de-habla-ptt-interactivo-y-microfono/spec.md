---
kind: standard
epic: 20261107-modos-de-habla-y-ruteo-de-audio
slice: C2
---

# Modos de habla PTT interactivo y micrófono abierto

## Objetivo

Permitir a los participantes comunicarse mediante pulsación interactiva push-to-talk (PTT) manteniendo presionado el botón visual en pantalla o mediante micrófono abierto continuo, ofreciendo conmutación fluida entre ambos modos dentro de la sala activa.

## Fuera de alcance

- Ruteo de salida de audio a altavoz, auricular y Bluetooth (implementado en el corte C1).
- Mapeo de teclas de hardware de volumen físicas en Android/iOS (requiere canales nativos específicos).
- Persistencia global de preferencias en SettingsPage (se abordará en un cambio de configuración general).

## Supuestos

- A1: El modo de habla inicial por defecto es PTT (`TalkMode.pushToTalk`), garantizando privacidad y evitando transmisiones involuntarias al entrar a una frecu.
- A2: La interacción táctil PTT responde a eventos de puntero (`onPointerDown` para iniciar transmisión y `onPointerUp`/`onPointerCancel` para detenerla) evitando pérdidas de estado si el puntero se cancela o se arrastra fuera del widget.
- A3: Al conmutar de micrófono abierto a PTT mientras se estaba transmitiendo, el sistema silencia de inmediato el micrófono local.

## Criterios de aceptación

- AC1: CUANDO el usuario se encuentra en modo PTT y mantiene presionado el botón de hablar (`onPointerDown`) ENTONCES se activa la transmisión de voz (`startTalking()`) y el botón refleja visualmente el estado de habla hasta que el usuario lo suelta o cancela la pulsación (`onPointerUp`/`onPointerCancel`), silenciando el micrófono (`stopTalking()`).
- AC2: CUANDO el usuario selecciona el modo de micrófono abierto (`openMic`) en la sala ENTONCES el modo se actualiza a `openMic` y el botón de micrófono permite alternar la transmisión continua (conmutar silencio/habla con un solo toque).
- AC3: CUANDO el usuario cambia de modo de habla de micrófono abierto transmitiendo a PTT ENTONCES la transmisión continua se detiene de inmediato silenciando el micrófono.

## Diseño

Se aplica Clean Architecture por feature, respetando Dart puro en `domain`, inmutabilidad con Riverpod y modularización de widgets para mantener `RoomPage` por debajo del límite de 300 líneas:

- **Domain (Dart puro)**:
  - Entidad `TalkMode` (`pushToTalk`, `openMic`) existente y casos de uso `StartTalking`, `StopTalking`, `ChangeTalkMode` en `VoiceRepository`.
- **Presentation**:
  - `PttButton`: widget interactivo con `Listener` que intercepta `onPointerDown`, `onPointerUp` y `onPointerCancel`, mostrando animación y feedback visual diferenciado según el estado de transmisión.
  - `MicControlSection`: sección modular que aloja el selector de modo interactivo (PTT vs Mic Abierto) y el botón de acción correspondiente (`PttButton` en PTT o botón conmutable en `openMic`).
  - Extracción de widgets en `lib/features/room/presentation/widgets/`: `RoomInfoCard`, `ParticipantsList` (con avatares e indicadores de habla reactivos) e `InviteQrDialog`, garantizando que `room_page.dart` tenga menos de 300 líneas y complejidad ciclomática <= 10.

## Archivos

- crear lib/features/room/presentation/widgets/room_info_card.dart — Componente desacoplado para visualizar información y estado de la sala.
- crear lib/features/room/presentation/widgets/participants_list.dart — Componente desacoplado para la lista y avatares de participantes con indicador de habla.
- crear lib/features/room/presentation/widgets/invite_qr_dialog.dart — Componente desacoplado para mostrar el código QR e invitación a la sala.
- crear lib/features/room/presentation/widgets/ptt_button.dart — Botón visual interactivo PTT con detección de eventos onPointerDown, onPointerUp y onPointerCancel.
- crear lib/features/room/presentation/widgets/mic_control_section.dart — Sección de control de micrófono con selector de modo (PTT vs Micrófono Abierto) y control de habla.
- modificar lib/features/room/presentation/pages/room_page.dart — Reducción a menos de 300 líneas integrando los componentes modulares y el modo interactivo.
- modificar lib/i18n/strings.i18n.json — Nuevas etiquetas y textos localizados en español para el selector de modo y botones PTT.
- modificar lib/i18n/strings_en.i18n.json — Nuevas etiquetas y textos localizados en inglés para el selector de modo y botones PTT.
- modificar lib/i18n/strings.g.dart — Clases tipadas generadas por slang para traducciones en español.
- modificar lib/i18n/strings_en.g.dart — Clases tipadas generadas por slang para traducciones en inglés.
- modificar lib/i18n/strings_es.g.dart — Clases tipadas generadas por slang para traducciones en español (variante es).
- crear test/features/room/presentation/widgets/ptt_button_test.dart — Tests de eventos de puntero y ciclo de vida de pulsación en PttButton.
- modificar test/features/room/presentation/voice_flow_test.dart — Tests de integración para conmutación interactiva de modo y PTT en RoomPage.
- modificar test/features/room/presentation/room_flow_test.dart — Tests de integración tras la modularización de widgets en RoomPage.

## Tareas

- [x] T1: Componentes modulares de RoomPage para información, participantes y QR
  - files: lib/features/room/presentation/widgets/room_info_card.dart, lib/features/room/presentation/widgets/participants_list.dart, lib/features/room/presentation/widgets/invite_qr_dialog.dart, lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/room_flow_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter test test/features/room/presentation/room_flow_test.dart
- [x] T2: Componente interactivo PttButton con eventos de puntero
  - files: lib/features/room/presentation/widgets/ptt_button.dart, test/features/room/presentation/widgets/ptt_button_test.dart
  - ac: AC1
  - verify: fvm flutter test test/features/room/presentation/widgets/ptt_button_test.dart
- [x] T3: Control de modos de habla y sección de micrófono en RoomPage
  - files: lib/features/room/presentation/widgets/mic_control_section.dart, lib/features/room/presentation/pages/room_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, test/features/room/presentation/voice_flow_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter test test/features/room/presentation/voice_flow_test.dart
- [ ] T4: Regeneración de clases de localización con slang
  - files: lib/i18n/strings.g.dart, lib/i18n/strings_en.g.dart, lib/i18n/strings_es.g.dart, test/features/room/presentation/voice_flow_test.dart
  - ac: AC2
  - verify: fvm flutter test test/features/room/presentation/voice_flow_test.dart

## Riesgos

- R1: La cancelación de gestos táctiles (por ejemplo, notificaciones del sistema o scroll) podría dejar el micrófono abierto involuntariamente — mitigación: vincular tanto `onPointerUp` como `onPointerCancel` al método `stopTalking()`.
