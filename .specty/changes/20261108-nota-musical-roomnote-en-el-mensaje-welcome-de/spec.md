---
kind: standard
---

# Nota musical RoomNote en el mensaje welcome de señalizacion

## Objetivo

Permitir que la nota musical (RoomNote) de una sala (frecu) viaje dentro del mensaje welcome del protocolo de señalización WebSocket como campo opcional y aditivo. De esta forma, los participantes que se unan por IP manual (o cualquier cliente conectado) recibirán la nota activa fijada por el anfitrión sin romper la compatibilidad de protocolo (v=1).

## Fuera de alcance

- Modificar componentes de presentación o widgets (cero UI).
- Modificar pantallas de unión manual ni diálogos de conexión.
- Cambiar la versión principal del protocolo (v=1).
- Alterar la lógica existente de asignación de notas (AssignRoomNote).

## Supuestos

- A1: El campo note en el mensaje welcome viaja serializado como su semitono entero decimal (0–23) usando RoomNoteConverter, o null si la sala no tiene nota asignada.
  - impacto: alto
- A2: La ausencia del campo note en el JSON recibido se deserializa como null, manteniendo retrocompatibilidad completa con clientes o servidores que operen sin dicha clave.
- A3: SignalingServerDataSource.start recibe opcionalmente RoomNote? note y la conserva durante la vida de la sala para adjuntarla a todo mensaje welcome enviado a clientes aceptados.
- A4: RoomRepositoryImpl._onWelcome asigna message.note a la entidad Room construida para que los clientes unidos tengan la nota disponible inmediatamente.

## Criterios de aceptación

- AC1: CUANDO se serializa un mensaje SignalingMessage.welcome con RoomNote ENTONCES el JSON resultante contiene el campo "note" con el semitono entero de la nota; CUANDO se deserializa un JSON de welcome sin campo "note" o con valor nulo/inválido ENTONCES el mensaje resultante tiene note: null, preservando retrocompatibilidad aditiva con v=1.
- AC2: CUANDO se inicia SignalingServerDataSource con una RoomNote activa y un cliente se conecta enviando join válido ENTONCES el servidor le responde con un mensaje SignalingMessage.welcome que incluye dicha RoomNote; si el servidor se inicia sin nota, el mensaje welcome se envía con note: null.
- AC3: CUANDO un cliente se une a una sala y recibe el mensaje welcome del anfitrión ENTONCES RoomRepositoryImpl devuelve la entidad Room con la RoomNote informada en dicho mensaje.
- AC4: CUANDO el anfitrión crea una sala mediante RoomRepository.createRoom pasando una RoomNote ENTONCES el servidor de señalización se inicia con dicha nota y los clientes reciben la nota en el welcome.
- AC5: CUANDO se consulta la especificación del protocolo de señalización en docs/protocolo.md ENTONCES describe el campo opcional y aditivo note en el mensaje welcome manteniendo v=1.

## Diseño

- Modelo SignalingMessage.welcome (lib/features/room/data/models/signaling_message.dart):
  - Se añade el parámetro opcional @RoomNoteConverter() RoomNote? note a la variante welcome.
  - Regeneración de código Freezed y JSON serialization con dart run build_runner build -d.
- Servidor de señalización (lib/features/room/data/datasources/signaling_server_datasource.dart):
  - start acepta el parámetro opcional RoomNote? note.
  - Se almacena _note en el servidor y se limpia en stop().
  - En _processJoin, se incluye note: _note en el SignalingMessage.welcome enviado al canal del cliente aceptado.
- Repositorio de sala (lib/features/room/domain/repositories/room_repository.dart y lib/features/room/data/repositories/room_repository_impl.dart):
  - RoomRepository.createRoom y CreateRoomParams reciben opcionalmente RoomNote? note.
  - RoomRepositoryImpl.createRoom pasa note: note a _server.start(...).
  - En _onWelcome, el objeto Room se instancia con note: note proveniente de SignalingMessage.welcome.
- Documentación (docs/protocolo.md):
  - Actualizar la tabla de mensajes y la sección de nota para registrar que welcome incluye el campo aditivo note con el semitono 0–23, permitiendo que la unión por IP manual también reciba la nota.

## Archivos

- modificar lib/features/room/data/models/signaling_message.dart — campo opcional note en welcome con @RoomNoteConverter().
- modificar lib/features/room/data/models/signaling_message.freezed.dart — código generado por build_runner.
- modificar lib/features/room/data/models/signaling_message.g.dart — código generado por build_runner.
- modificar lib/features/room/data/datasources/peer_connection_datasource.dart — adaptar aridad de callback welcome.
- modificar lib/features/room/data/repositories/voice_repository_impl.dart — adaptar aridad de callback welcome.
- modificar lib/features/room/data/datasources/signaling_server_datasource.dart — recibir note opcional al iniciar y enviarla en welcome.
- modificar lib/features/room/domain/repositories/room_repository.dart — parámetro opcional note en createRoom.
- modificar lib/features/room/domain/usecases/create_room.dart — parámetro opcional note en CreateRoomParams.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — pasar nota al servidor en createRoom y asignarla desde welcome.note en _onWelcome.
- modificar docs/protocolo.md — documentar campo aditivo note en mensaje welcome.
- modificar test/features/room/data/signaling_message_test.dart — pruebas de serialización y deserialización de welcome con nota y retrocompatibilidad.
- modificar test/features/room/data/signaling_server_test.dart — pruebas de servidor enviando nota en welcome.
- modificar test/features/room/data/room_repository_test.dart — pruebas de cliente recibiendo nota en welcome al unirse.

## Tareas

- [x] T1: Modelado y serialización de RoomNote en SignalingMessage.welcome
  - files: lib/features/room/data/models/signaling_message.dart, lib/features/room/data/models/signaling_message.freezed.dart, lib/features/room/data/models/signaling_message.g.dart, lib/features/room/data/datasources/peer_connection_datasource.dart, lib/features/room/data/repositories/voice_repository_impl.dart, test/features/room/data/signaling_message_test.dart
  - ac: AC1
  - verify: fvm flutter test test/features/room/data/signaling_message_test.dart
- [x] T2: Envío de RoomNote en el mensaje welcome de SignalingServerDataSource
  - files: lib/features/room/data/datasources/signaling_server_datasource.dart, test/features/room/data/signaling_server_test.dart
  - ac: AC2
  - verify: fvm flutter test test/features/room/data/signaling_server_test.dart
- [x] T3: Propagación de note en createRoom y asignación en _onWelcome de RoomRepositoryImpl
  - files: lib/features/room/domain/repositories/room_repository.dart, lib/features/room/domain/usecases/create_room.dart, lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/room_repository_test.dart
  - ac: AC3, AC4
  - verify: fvm flutter test test/features/room/data/room_repository_test.dart
- [x] T4: Documentación del protocolo y verificación integral del protocolo
  - files: docs/protocolo.md, test/features/room/data/signaling_server_test.dart
  - ac: AC5
  - verify: fvm flutter test test/features/room/data/signaling_server_test.dart

## Riesgos

- R1: Servidores o clientes sin este cambio omiten el campo note — mitigación: @RoomNoteConverter() maneja de forma natural la ausencia o nulidad de la clave devolviendo null, y SignalingWelcomeMessage define note como opcional y nulleable.
- R2: Pruebas unitarias existentes de SignalingMessage.welcome o createRoom fallan por diferencias de firma — mitigación: note es un parámetro opcional con nombre (RoomNote? note), sin romper invocaciones previas.
