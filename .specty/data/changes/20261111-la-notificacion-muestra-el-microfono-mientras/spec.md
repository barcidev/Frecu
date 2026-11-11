---
kind: standard
---

# La notificación muestra el micrófono mientras se espera al anfitrión

## Objetivo

Mientras el anfitrión de una frecu con traspaso no responde, la voz entre invitados sigue, pero la notificación del sistema (Android) oculta el botón de micrófono y dice «Reconectando», porque arma su estado sin la espera del anfitrión (`HostSilence`). Con este cambio la tarjeta sigue a la pantalla: muestra el micrófono y la salida de audio, y dice lo mismo que la isla («Andrés no responde · 3 s»). Resuelve P186 y P170.

## Fuera de alcance

- La pista bajo el núcleo PTT (quién toma la frecu): la tarjeta no la muestra.
- Cambios en la pantalla de la frecu, en `HostSilence` o en el traspaso.
- La notificación de iOS (no hay tarjeta de reproductor).

## Supuestos

- A1: La tarjeta debe decir lo mismo que la isla de la pantalla durante la espera, igual que en los demás estados.
- A2: `shownRoom` (room_state.dart) hace lo mismo que `participantsWithVoice` + `negotiatingStatus`, más la espera; la tarjeta puede usarlo sin cambiar los demás estados.
  - impacto: alto

## Criterios de aceptación

- AC1: CUANDO el anfitrión de una frecu con traspaso no responde (estado de habla con `silence`) ENTONCES la tarjeta muestra los botones de micrófono, salida de audio y salir, como con la frecu conectada.
- AC2: CUANDO el anfitrión no responde desde hace N segundos ENTONCES el subtítulo de la tarjeta dice «<anfitrión> no responde · N s» en ámbar, y «<anfitrión> no responde» sin segundos.
- AC3: CUANDO la frecu reconecta sin espera del anfitrión (sin traspaso) ENTONCES la tarjeta sigue diciendo «Reconectando» y solo muestra salir.
- AC4: CUANDO la frecu activa entra en la espera del anfitrión ENTONCES `RoomNotification` arma la tarjeta con `hostSilenceProvider` y `hostSilenceClockProvider` y la actualiza cada segundo.
  - test: manual

## Diseño

- `roomNotificationScene` recibe `silentFor` (segundos de `hostSilenceClockProvider`). Con `talk.silence`, el subtítulo es `silence.islandLabel(silentFor)` con `c.warn` (va después del SOS y antes de reconectando).
- `RoomNotification._refresh` lee `hostSilenceProvider` y arma participantes y estado con `shownRoom`, como la pantalla; pasa `silence` a `RoomTalk.from`. Sigue también `hostSilenceProvider` y `hostSilenceClockProvider`.

## Archivos

- modificar lib/features/room/presentation/pages/room_notification.dart — usar la espera del anfitrión en el estado y el subtítulo de la tarjeta
- modificar test/features/room/presentation/room_notification_test.dart — pruebas de la tarjeta durante la espera

## Tareas

- [ ] T1: La tarjeta aplica la espera del anfitrión
  - files: lib/features/room/presentation/pages/room_notification.dart, test/features/room/presentation/room_notification_test.dart
  - ac: AC1, AC2, AC3, AC4
  - verify: flutter test test/features/room/presentation/room_notification_test.dart
