---
kind: standard
---

# Dividir room_repository_impl y recuperar la exhaustividad de los mensajes

## Objetivo

Pagar deuda técnica sin cambiar el comportamiento: `room_repository_impl.dart` (hoy 1150 líneas) se reparte en archivos por responsabilidad, y los `switch` sobre `SignalingMessage` dejan de usar `default:` para que el compilador avise cuando un mensaje nuevo del protocolo quede sin atender.

## Fuera de alcance

- Cambiar el comportamiento de la frecu, del protocolo o de la voz.
- Cambiar la API pública de `RoomRepositoryImpl` (constructor, métodos y `RoomRepository` / `RoomHandover`).
- Dividir otros archivos grandes (`voice_repository_impl.dart`, `signaling_server_datasource.dart`).
- Cambiar los `switch` con `_ =>` que no recorren `SignalingMessage` (motivos de rechazo, errores, enums de UI).

## Supuestos

- A1: Los «cuatro sitios» de la petición son un mínimo: hoy hay ocho `switch` sobre `SignalingMessage` con `default:` (dos en `room_repository_impl.dart`, dos en `signaling_server_datasource.dart`, uno en `voice_repository_impl.dart`, uno en `peer_connection_datasource.dart`, uno en `host_probe.dart`), y se corrigen todos.
- A2: La división usa archivos `part` de la misma biblioteca con extensiones privadas sobre `RoomRepositoryImpl`, para que los métodos movidos sigan viendo el estado privado sin cambiar firmas ni comportamiento; los campos, el constructor y los métodos `@override` quedan en la clase.
- A3: Las pruebas actuales (`room_repository_test.dart`, `signaling_server_test.dart`, `voice_repository_test.dart`, `peer_connection_datasource_test.dart`, `host_probe_test.dart`) cubren el comportamiento y bastan como red de seguridad; no hacen falta pruebas nuevas.

## Criterios de aceptación

- AC1: CUANDO se abre `lib/features/room/data/repositories/room_repository_impl.dart` ENTONCES tiene menos de 500 líneas, y la reconexión, los mensajes del cliente y el traspaso viven en sus propios archivos `part`.
  - test: manual
- AC2: CUANDO se ejecutan las pruebas de la frecu tras la división ENTONCES pasan todas sin cambiar ninguna.
- AC3: CUANDO se busca `default:` en los `switch` sobre `SignalingMessage` de `lib/features/room/data` ENTONCES no queda ninguno: cada variante sin efecto aparece nombrada en un `case` que no hace nada, y `flutter analyze` no da avisos.
  - test: manual
- AC4: CUANDO se añade una variante nueva a `SignalingMessage` ENTONCES `flutter analyze` marca como no exhaustivos los ocho `switch` hasta que se atienda.
  - test: manual

## Diseño

- `room_repository_impl.dart`: clase, campos, constructor, API pública, sesiones (`createRoom`, `joinRoom`, `joinInternetRoom`, `leaveRoom`, `dispose`), `_setStatus` / `_setParticipants` y las clases privadas `_Joining` / `_JoinTarget`. Declara `part` de los tres archivos siguientes.
- `room_repository_reconnection.dart` (`part of`): `extension on RoomRepositoryImpl` con `_handleClientConnectionChange`, `_reconnect`, `_onReconnectWait`, `_failoverPlan`, `_failoverAttempt`, `_attemptRejoin` y `_giveUp`.
- `room_repository_messages.dart` (`part of`): `_listen`, `_onMessage`, `_onWelcome*`, `_afterWelcome`, `_onRejected`, `_onPeerJoined`, `_onPeerLeft` y `_onRoomClosed`.
- `room_repository_takeover.dart` (`part of`): `_onRival`, `_onRelayOutranked`, `_yieldTo`, `_yieldUri`, `_release`, `_onHostMessage`, `_onHostHandover`, `_takeOver`, `_rejoinAsHost` y `_onHostChanged`; `handOver` sigue en la clase por ser `@override`.
- En cada `switch` sobre `SignalingMessage`, `default:` se sustituye por un `case A() || B() || …:` con las variantes que no tienen efecto (y `case null:` donde el valor es anulable), conservando el comentario que explica por qué se ignoran.

## Archivos

- modificar lib/features/room/data/repositories/room_repository_impl.dart — se queda con el núcleo y declara los `part`; quita los dos `default:`.
- crear lib/features/room/data/repositories/room_repository_reconnection.dart — reconexión y plan de caída.
- crear lib/features/room/data/repositories/room_repository_messages.dart — mensajes del cliente y `welcome`.
- crear lib/features/room/data/repositories/room_repository_takeover.dart — traspaso y cesión de la frecu.
- modificar lib/features/room/data/repositories/voice_repository_impl.dart — `switch` exhaustivo.
- modificar lib/features/room/data/datasources/peer_connection_datasource.dart — `switch` exhaustivo.
- modificar lib/features/room/data/datasources/signaling_server_datasource.dart — dos `switch` exhaustivos.
- modificar lib/features/room/data/datasources/host_probe.dart — `switch` exhaustivo.

## Tareas

- [x] T1: Dividir `room_repository_impl.dart` en archivos `part`
  - files: lib/features/room/data/repositories/room_repository_impl.dart, lib/features/room/data/repositories/room_repository_reconnection.dart, lib/features/room/data/repositories/room_repository_messages.dart, lib/features/room/data/repositories/room_repository_takeover.dart
  - ac: AC1, AC2
  - verify: flutter test test/features/room/data
- [x] T2: Quitar `default:` de los `switch` de los repositorios
  - files: lib/features/room/data/repositories/room_repository_impl.dart, lib/features/room/data/repositories/room_repository_messages.dart, lib/features/room/data/repositories/room_repository_takeover.dart, lib/features/room/data/repositories/voice_repository_impl.dart
  - ac: AC2, AC3, AC4
  - verify: flutter test test/features/room/data
- [x] T3: Quitar `default:` de los `switch` de los datasources
  - files: lib/features/room/data/datasources/peer_connection_datasource.dart, lib/features/room/data/datasources/signaling_server_datasource.dart, lib/features/room/data/datasources/host_probe.dart
  - ac: AC2, AC3, AC4
  - verify: flutter test test/features/room/data

## Riesgos

- R1: Una frecu abierta en un simulador iOS ocupa el puerto 47800 del Mac y tumba `room_repository_test.dart` — cerrar el simulador antes de verificar.
- R2: Listar todas las variantes alarga los `switch` — se agrupan en un solo `case` con `||` y se conserva el comentario del motivo.
- R3: `20261111-sucesor-rechazado-por-internet-entra-como` (y quizá otros cambios abiertos de la frecu) también tocan `room_repository_impl.dart`; al mover métodos a archivos `part`, el que se fusione después tendrá conflictos — al resolverlos, sus cambios van al archivo `part` que ahora tiene el método.

## Cierre

### Resumen

- `room_repository_impl.dart` baja de 1150 a 472 líneas: la reconexión (con `_JoinTarget`) va a `room_repository_reconnection.dart`; las sesiones, el `join` y los mensajes del cliente (con `_Joining`) a `room_repository_messages.dart`; el traspaso (con `_afterWelcome`) a `room_repository_takeover.dart`. Son archivos `part` con extensiones privadas sobre `RoomRepositoryImpl`.
- Ningún `switch` sobre `SignalingMessage` de `lib/features/room/data` usa ya `default:`: cada mensaje sin efecto va nombrado, y quitar uno da `non_exhaustive_switch_expression` en `flutter analyze` (comprobado a mano en la malla).
- Verificado: `flutter analyze` sin avisos y `flutter test` completo en verde (1260 pruebas), sin tocar ninguna.

### Desviaciones

- Los `switch` pasan a `switch` expression (`Mensaje() => null` para los que no hacen nada) en lugar de `case A() || B():`: `specty check` cuenta cada `case` y cada `||` en la complejidad, y por eso se habían cambiado a `default:`. Los cuerpos de varias líneas pasan a funciones pequeñas (`_onRoomState`, `_greetNewcomer`, `_forgetPeer`, `_forward`, `_echo`, `_beforeJoin`, `_acceptJoin`, `_probeBeforeJoin`, `_ifForMe`, `_refuse`).
- Quedan siete `switch`, no ocho: `_onHostMessage` desaparece; `_onMessage` llama directo a `_onHostHandover` y `_onHostChanged`, que ahora no hacen nada si este teléfono es el anfitrión.
- Nombrar cada mensaje pasaba `peer_connection_datasource.dart` y `signaling_server_datasource.dart` del máximo de 500 líneas: con la ampliación S1, la señalización de la malla va a `peer_connection_signaling.dart` y el enrutado del servidor a `signaling_server_routing.dart`, también como `part`.
- `_routeFrom` reenvía con `copyWith(from: …)` / `copyWith(peerId: …)` en lugar de construir el mensaje de nuevo; el resultado es el mismo mensaje con el remitente forzado.
- `dispose` también cancela `_clientSubscription` (lint `cancel_subscriptions` al mover su cancelación a los `part`); `leaveRoom` ya la soltaba antes.

### Decisiones

- `part` con extensiones privadas, y no clases colaboradoras: los métodos movidos siguen viendo el estado privado sin cambiar firmas ni comportamiento (A2).
- Se corrigen todos los `switch` sobre `SignalingMessage`, no solo cuatro (A1).

### Pendientes

- Los cambios abiertos que tocan `room_repository_impl.dart` (p. ej. `20261111-sucesor-rechazado-por-internet-entra-como`) tendrán conflictos al fusionarse después de este: sus cambios van al archivo `part` que ahora tiene el método (R3).
- `voice_repository_impl.dart` sigue con 559 líneas de código (aviso a partir de 300); dividirlo queda fuera de alcance.
