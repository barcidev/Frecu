---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C7
---

# La voz entre invitados sigue durante el traspaso, y pruebas en teléfonos reales

## Objetivo

Hoy, al perder el socket con el anfitrión, la voz de cada invitado deja de transmitir (PTT y micrófono abierto) aunque sus enlaces WebRTC con los demás invitados sigan arriba; y tras un traspaso, quien vuelve con su mismo id no retoma el micrófono abierto (P160). En una frecu con traspaso, la voz entre los invitados que siguen conectados no se corta durante el traspaso (voluntario, por caída y por internet): solo se cierra el enlace con el anfitrión que se fue. Es AC10 de la épica; AC12 (pruebas en teléfonos reales) queda con su guion para la persona.

## Fuera de alcance

- La lógica del traspaso (reintentos, sucesión, toma, turnos, Worker): ya está en develop (C3 a C6, C10) y no se toca `room_repository_impl.dart`.
- Que una reconexión normal vuelva a su mismo lugar en la sucesión en vez de al final con un id nuevo (parte de datos de P158): es del servidor de señalización y del repositorio de la frecu.
- La notificación del sistema durante la espera del anfitrión: sigue sin el PTT mientras la frecu reconecta.
- Reinicio de ICE de un enlace entre invitados que se cae durante el traspaso.
- Frecus sin traspaso (red de Frecu o zona Wi-Fi del anfitrión): siguen como hoy, sin transmitir mientras reconectan.
- Cambiar los contratos de `RoomRepository`, `VoiceRepository` o `SignalingMessage.welcome`.
- Ejecutar las pruebas en teléfonos reales (AC12): las hace la persona.

## Supuestos

- A1: La voz sabe que la frecu admite traspaso y quién la lleva por los `room_state` que ya recibe por la misma señalización (`state.handover` y el primer miembro de `state.members`, que es el anfitrión), sin tocar `RoomRepository`.
  - impacto: alto
- A2: Mientras el socket de señalización está caído, los enlaces WebRTC ya negociados entre invitados siguen pasando audio (local: por la Wi-Fi compartida; por internet: por STUN/TURN), porque no dependen del socket.
  - impacto: alto
- A3: El nuevo anfitrión ya tenía enlaces con los demás como invitado y los conserva: no hace falta renegociarlos. Solo quien vuelve con un id nuevo rehace los suyos ofreciendo a todos, como quien llega.
- A4: Durante el corte los `talk_state` no viajan: quién habla puede quedar desactualizado unos segundos; al volver, cada uno anuncia su estado y se corrige.

## Criterios de aceptación

- AC1: CUANDO se pierde el socket de señalización en una frecu con traspaso ENTONCES la voz sigue transmitiendo: el PTT presionado y el micrófono abierto siguen activos, los enlaces con los demás siguen abiertos (sin cerrar ni volver a ofrecer), y solo el anfitrión deja de verse hablando.
- AC2: CUANDO llega la sucesión con otro anfitrión (traspaso voluntario, por caída o por internet) ENTONCES se cierra solo el enlace de voz con el anfitrión anterior; los demás enlaces siguen sin renegociar.
- AC3: CUANDO se vuelve a la frecu con el mismo id tras perder al anfitrión ENTONCES no se rehace la malla, se anuncia el estado de habla propio y, si el micrófono abierto se había cortado, se retoma solo.
- AC4: CUANDO se vuelve a la frecu con un id nuevo (una reconexión normal, o el anfitrión anterior que vuelve como invitado) ENTONCES la voz cierra los enlaces del id viejo, ofrece a todos los presentes salvo a su id viejo y retoma el micrófono abierto; en PTT, si seguía transmitiendo, lo anuncia.
- AC5: CUANDO la frecu no tiene traspaso ENTONCES sin anfitrión no se transmite, como hoy, y al volver se retoma el micrófono abierto.
- AC6: CUANDO el traspaso se prueba en teléfonos reales (Android y iPhone; Wi-Fi compartida y por internet; voluntario, por caída y regreso del anfitrión anterior) ENTONCES la voz entre los invitados no se corta y el traspaso se cumple de punta a punta.
  - test: manual

## Diseño

- **`VoiceHandover`** (`data/repositories/voice_handover.dart`, pieza nueva para no hacer crecer `voice_repository_impl.dart`): sigue los `room_state` y el `welcome` de la señalización. Sabe si la frecu admite traspaso (`keepsVoice`) y quién la lleva; `onRoomState` devuelve el anfitrión anterior cuando cambia (si no es el propio id), y `reset` lo olvida al salir.
- **`VoiceRepositoryImpl`**: al perder la conexión, con `keepsVoice` no corta el micrófono ni el estado de habla; solo saca al anfitrión de quienes hablan. Sin traspaso, lo de hoy. Al cambiar el anfitrión, pide a la malla cerrar solo su enlace. Un `welcome` con el mismo id ya no es un no-op: retoma el micrófono abierto si se cortó (P160) o anuncia el estado propio. Un `welcome` con id nuevo sigue rehaciendo la malla; al final, en PTT transmitiendo, anuncia (P178).
- **`PeerConnectionDataSource.closePeer(id)`**: público, cierra el enlace con un par (como `peer_left`), sin tocar los demás.
- **Docs**: `docs/audio.md` y `docs/protocolo.md` dicen que en una frecu con traspaso la voz sigue mientras reconecta.
- **Pruebas en teléfonos (AC6)**: el guion queda en la memoria de Specty para la persona.

## Archivos

- crear lib/features/room/data/repositories/voice_handover.dart — si la frecu admite traspaso y quién la lleva, para la voz
- modificar lib/features/room/data/repositories/voice_repository_impl.dart — no corta la voz con traspaso, cierra el enlace del anfitrión que se fue y retoma al volver con el mismo id
- modificar lib/features/room/data/datasources/peer_connection_datasource.dart — `closePeer` público
- crear test/features/room/data/voice_handover_test.dart — pruebas de la voz durante el traspaso
- modificar docs/audio.md — la voz con traspaso sigue mientras reconecta
- modificar docs/protocolo.md — la voz en la reconexión con traspaso

## Tareas

- [x] T1: La voz sigue durante el traspaso: no corta con traspaso, cierra solo el enlace del anfitrión anterior y retoma al volver
  - files: lib/features/room/data/repositories/voice_handover.dart, lib/features/room/data/repositories/voice_repository_impl.dart, lib/features/room/data/datasources/peer_connection_datasource.dart, test/features/room/data/voice_handover_test.dart
  - ac: AC1, AC2, AC3, AC4, AC5
  - verify: flutter test test/features/room/data/voice_handover_test.dart test/features/room/data/voice_mesh_test.dart test/features/room/data/open_mic_voice_test.dart test/features/room/data/voice_repository_test.dart test/features/room/data/peer_connection_datasource_test.dart
- [x] T2: Docs de la voz en el traspaso y guion de pruebas en teléfonos
  - files: docs/audio.md, docs/protocolo.md
  - ac: AC6
  - verify: flutter analyze

## Riesgos

- R1: Con traspaso, si es la red del propio invitado la que se cae, el micrófono queda abierto sin nadie que lo oiga — no hay daño: si la frecu se cierra, la voz sale de la malla como hoy.
- R2: Conflicto con C11, que toca la reconexión — este corte no toca `room_repository_impl.dart`, `room_reconnection.dart` ni `cloud_relay_datasource.dart`.
- R3: Un PTT que se suelta durante el corte deja a esa persona «hablando» para los demás hasta que vuelve y anuncia — se corrige al volver (A4).
