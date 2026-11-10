---
kind: standard
epic: 20261108-pendientes-portadora
slice: C4
---

# Nivel real de voz en el núcleo PTT y en la malla

## Objetivo

El bisel y el anillo del núcleo PTT y las firmas de la malla dejan la onda simulada (`frVoice`) y siguen el nivel real de la voz que mide WebRTC: el del micrófono propio al transmitir y el del audio recibido de cada participante. Cubre AC1 de la épica.

## Fuera de alcance

- Hablar con el botón de volumen (parte de P102 y P106). Queda anotado como pendiente al cerrar.
- Decidir quién habla por el nivel en micrófono abierto (`docs/audio.md`): las leyendas «Hablando» y «Al aire», `speakingPeers` y la isla siguen con `talk_state`.
- Las firmas decorativas de la bienvenida, del perfil, de la hoja de nombre, de la isla y de los avisos, que siguen con `frVoice`, y las barras de la pastilla de ruta.
- Partir `room_mesh_scene.dart` y `room_mesh_test.dart` (C5).
- Perfilar la lectura en un teléfono real (P33).

## Supuestos

- A1: Comprobado en el código de flutter_webrtc 1.6.3: `RTCPeerConnection.getStats()` devuelve `List<StatsReport>` con `type` (`media-source`, `inbound-rtp`…) y `values`, el mapa con todos los miembros de la estadística estándar (Android los copia de `RTCStats.getMembers()` y iOS de `RTCStatistics.values`); `values['kind']` dice si es audio y los números llegan como `num`. Los binarios de WebRTC-SDK 150.7871.04 de Android (AAR) y de iOS (xcframework) traen `audioLevel`, `totalAudioEnergy` y `totalSamplesDuration` en `media-source` e `inbound-rtp`, así que no hace falta el respaldo de `totalAudioEnergy` diferencial: se usa `audioLevel` en las dos plataformas.
  - impacto: alto
- A2: `audioLevel` es la amplitud de pico lineal, de 0 a 1 (1 es 0 dBov). El repositorio lo emite tal cual y la presentación lo pasa a la escala del VU en decibelios con `voiceMeterLevel(a) = clamp(1 + 20·log10(a) / 48, 0, 1)`: −48 dB o menos es 0, −24 dB es 0,5 y 0 dB es 1. Así la voz normal (−6 a −20 dB) enciende entre la mitad y casi todo el bisel, como la onda simulada.
  - impacto: alto
- A3: «Frecu activa» es la pantalla de la frecu activa escuchando los niveles. El repositorio lee cada 100 ms solo mientras alguien escucha `watchLocalLevel` o `watchPeerLevels`; cuando nadie escucha (al salir de la frecu, al cerrarse o al liberar el repositorio) para el temporizador y los niveles vuelven a 0. Hay un solo temporizador para los dos flujos y una sola llamada a `getStats()` por conexión en cada lectura; si una lectura no terminó, se salta la siguiente.
  - impacto: alto
- A4: El nivel propio es el mayor `audioLevel` de los `media-source` de audio de todas las conexiones (es el mismo micrófono). Sin conexiones (anfitrión solo) es 0, porque `media-source` necesita un emisor negociado. Una conexión cuyo `getStats()` falla se salta en esa lectura y su par queda sin nivel (0).
- A5: Los flujos solo emiten cuando el valor cambia: en silencio no hay reconstrucciones.
- A6: Al aire, el bisel conserva el mínimo de 0,12 y la escala de 0,7 del micrófono abierto del prototipo: sigue `max(0,12, nivel × escala)`. El anillo de recepción y la malla siguen el nivel sin mínimo, y el nivel solo se ve en quien ya está al aire (transmite, recibe o habla según `talk_state`).
- A7: Con movimiento reducido el núcleo y la malla toman el nivel real tal cual en cada reconstrucción (unas 10 por segundo), sin resorte, ondas ni paquetes. Desaparecen los niveles fijos `pttReducedLevel` y `meshReducedLevel`.
- A8: Los niveles llegan a la pantalla con proveedores `@riverpod` que se escuchan en un `Consumer` alrededor del núcleo y de la malla, para no reconstruir toda la frecu 10 veces por segundo. Si el flujo falla (o un doble de prueba no lo define), el nivel es 0.

## Criterios de aceptación

- AC1: CUANDO la pantalla de la frecu activa escucha los niveles ENTONCES `VoiceRepository` lee `getStats()` de cada conexión cada 100 ms y emite por `watchLocalLevel` el `audioLevel` del `media-source` de audio y por `watchPeerLevels` el `audioLevel` del `inbound-rtp` de audio de cada participante por su id, de 0 a 1, solo cuando cambian; CUANDO nadie los escucha ENTONCES deja de leer y los niveles vuelven a 0.
- AC2: CUANDO el usuario transmite (PTT o micrófono abierto) ENTONCES el bisel y el anillo del núcleo PTT siguen, con su resorte, el nivel real de su micrófono en la escala del VU; CUANDO recibe a alguien ENTONCES el anillo de recepción sigue el nivel real del audio de esa persona; CUANDO no suenan ENTONCES vuelven a reposo (al aire, al mínimo de al aire). El núcleo ya no usa `frVoice`.
- AC3: CUANDO alguien habla en la malla ENTONCES su firma, su halo, su anillo, sus aristas y sus paquetes siguen el nivel real de su voz (la propia con el micrófono y las demás con su audio recibido) y en silencio vuelven a reposo. La malla ya no usa `frVoice`.
- AC4: CUANDO el sistema pide reducir el movimiento ENTONCES el núcleo y la malla muestran el nivel real a saltos, sin resorte, ondas ni paquetes.

## Diseño

- **Lectura (`PeerConnectionDataSource`)**: `typedef VoiceLevels = ({double local, Map<String, double> peers})` y `Future<VoiceLevels> readVoiceLevels()`. Pide `getStats()` a todas las conexiones a la vez (`Future.wait`); de cada `StatsReport` con `values['kind']` (o `mediaType`) `audio` y `audioLevel` numérico (limitado a 0–1) toma `media-source` como nivel propio (el mayor) e `inbound-rtp` como nivel del par de esa conexión. Si `getStats()` lanza, esa conexión se salta.
- **Muestreo (`VoiceLevelSampler`, en `data/repositories`)**: recibe la función de lectura. `const voiceLevelInterval = Duration(milliseconds: 100)`. Dos `StreamController.broadcast` (propio y pares) cuyo `onListen`/`onCancel` arrancan o paran un único `Timer.periodic`; en cada tic lee (saltando si hay una lectura en curso) y emite cada flujo solo si cambió (`mapEquals` para los pares). `watchLocal()` y `watchPeers()` empiezan con el valor actual. Al parar, los niveles vuelven a 0 y a `{}`. `dispose()` para el temporizador y cierra los flujos.
- **Repositorio**: `VoiceRepository` suma `Stream<double> watchLocalLevel()` y `Stream<Map<String, double>> watchPeerLevels()` (dominio puro). `VoiceRepositoryImpl` crea su `VoiceLevelSampler` con `_peerConnection.readVoiceLevels`, delega en él y lo libera en `dispose`.
- **Proveedores (`voice_provider.dart`)**: `double voiceMeterLevel(double audioLevel)` (A2); `@riverpod Stream<double> localVoiceLevel` y `@riverpod Stream<Map<String, double>> peerVoiceLevels`, que mapean los flujos del repositorio con `voiceMeterLevel` y se liberan solos al dejar de escucharse.
- **Núcleo**: `PttLook` cambia `rxSeed` por `level` y `rxLevel` (0–1). `PttMotion.advance` apunta a `max(0,12, level × levelScale)` al aire y a `rxLevel` al recibir, con el mismo resorte (`_ease`); con movimiento reducido los toma tal cual. `PttCore` cambia `speakerSeed` por `speakerLevel` y suma `level`. `MicControlSection` envuelve el núcleo en un `Consumer` que lee `onAirClockProvider`, `localVoiceLevelProvider` y, para quien habla, `peerVoiceLevelsProvider`.
- **Malla (`room_mesh_scene.dart`, sin crecer)**: `MeshNode.level` (0–1, en `==` y `hashCode`); `buildMeshNodes(levels:)` lo toma por id. `MeshMotion` apunta a `node.level` si está al aire (sin `frVoice` ni `meshReducedLevel`), con el resorte de hoy y directo con movimiento reducido o enlace caído. `RoomMesh` suma `levels` (por id, la persona propia incluida) y lo pasa a `buildMeshNodes`. `RoomPage` envuelve la malla en un `Consumer` que junta los niveles de los pares con el propio bajo el id local.
- **Pruebas**: `voice_levels_test` (datos) con dobles de `RTCPeerConnection` y de `PeerConnectionDataSource`, y el tiempo falso de `testWidgets` (`tester.pump(Duration)`) para el temporizador; `voice_level_provider_test` con un `ProviderContainer` y un doble del repositorio; `voice_level_core_test` y `voice_level_mesh_test` con `pump(Duration)` y movimiento reducido. `ptt_core_test` y `room_mesh_test` solo cambian los niveles fijos de movimiento reducido por niveles dados, sin crecer `room_mesh_test`.

## Archivos

- modificar lib/features/room/domain/repositories/voice_repository.dart — contrato `watchLocalLevel` y `watchPeerLevels`.
- modificar lib/features/room/data/datasources/peer_connection_datasource.dart — `VoiceLevels` y `readVoiceLevels` con `getStats()`.
- crear lib/features/room/data/repositories/voice_level_sampler.dart — temporizador único de 100 ms mientras alguien escucha y flujos de nivel.
- modificar lib/features/room/data/repositories/voice_repository_impl.dart — niveles desde el muestreo y su liberación.
- modificar lib/features/room/presentation/providers/voice_provider.dart — `voiceMeterLevel`, `localVoiceLevel` y `peerVoiceLevels`.
- modificar lib/features/room/presentation/providers/voice_provider.g.dart — proveedores generados.
- modificar lib/features/room/presentation/widgets/ptt_core_painter.dart — nivel real en `PttLook` y `PttMotion` en lugar de `frVoice`.
- modificar lib/features/room/presentation/widgets/ptt_core.dart — `level` y `speakerLevel` en lugar de `speakerSeed`.
- modificar lib/features/room/presentation/widgets/mic_control_section.dart — el núcleo lee los niveles en un `Consumer`.
- modificar lib/features/room/presentation/widgets/room_mesh_scene.dart — `MeshNode.level` y `MeshMotion` sin `frVoice`.
- modificar lib/features/room/presentation/widgets/room_mesh.dart — parámetro `levels`.
- modificar lib/features/room/presentation/pages/room_page.dart — la malla lee los niveles en un `Consumer`.
- crear test/features/room/data/voice_levels_test.dart — lectura de `getStats()` y muestreo de los niveles.
- crear test/features/room/presentation/voice_level_provider_test.dart — escala del VU y proveedores de nivel.
- crear test/features/room/presentation/voice_level_core_test.dart — núcleo PTT con nivel real.
- crear test/features/room/presentation/voice_level_mesh_test.dart — malla con nivel real y niveles en la frecu activa.
- modificar test/features/room/presentation/ptt_core_test.dart — movimiento reducido con un nivel dado en lugar de `pttReducedLevel`.
- modificar test/features/room/presentation/room_mesh_test.dart — niveles dados en la escena y en la malla en lugar de la onda simulada y del 0,6 fijo.

## Tareas

- [ ] T1: Niveles de voz leídos de `getStats()` en el repositorio de voz
  - files: lib/features/room/domain/repositories/voice_repository.dart, lib/features/room/data/datasources/peer_connection_datasource.dart, lib/features/room/data/repositories/voice_level_sampler.dart, lib/features/room/data/repositories/voice_repository_impl.dart, test/features/room/data/voice_levels_test.dart
  - ac: AC1
  - verify: flutter test test/features/room/data/voice_levels_test.dart
- [ ] T2: Proveedores de nivel en la escala del VU
  - files: lib/features/room/presentation/providers/voice_provider.dart, lib/features/room/presentation/providers/voice_provider.g.dart, test/features/room/presentation/voice_level_provider_test.dart
  - ac: AC1, AC2
  - verify: flutter test test/features/room/presentation/voice_level_provider_test.dart
- [ ] T3: Núcleo PTT con el nivel real
  - files: lib/features/room/presentation/widgets/ptt_core_painter.dart, lib/features/room/presentation/widgets/ptt_core.dart, lib/features/room/presentation/widgets/mic_control_section.dart, test/features/room/presentation/voice_level_core_test.dart, test/features/room/presentation/ptt_core_test.dart
  - ac: AC2, AC4
  - verify: flutter test test/features/room/presentation/voice_level_core_test.dart test/features/room/presentation/ptt_core_test.dart
- [ ] T4: Malla con el nivel real en la frecu activa
  - files: lib/features/room/presentation/widgets/room_mesh_scene.dart, lib/features/room/presentation/widgets/room_mesh.dart, lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/voice_level_mesh_test.dart, test/features/room/presentation/room_mesh_test.dart
  - ac: AC2, AC3, AC4
  - verify: flutter test && flutter analyze

## Riesgos

- R1: Leer `getStats()` 10 veces por segundo con 5 conexiones puede pesar en un teléfono de gama media — mitigación: un solo temporizador, una llamada por conexión y lectura, lecturas que no se encadenan, emisiones solo con cambios y lectura solo con la frecu activa; perfilar en un dispositivo real queda en P33.
- R2: C5 parte `room_mesh_scene.dart` después de este corte — mitigación: el archivo no crece (hoy 438 líneas de código) y `room_mesh_test.dart` solo cambia sus niveles.
- R3: Otras pruebas montan la frecu activa con dobles de `VoiceRepository` sin los flujos nuevos — mitigación: con el flujo en error el nivel es 0 (A8), así que no hay que tocarlas.
