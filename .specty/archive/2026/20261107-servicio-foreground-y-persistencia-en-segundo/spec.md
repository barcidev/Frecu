---
kind: standard
epic: 20261107-segundo-plano-y-resiliencia
slice: C2
allowedDependencies:
  - flutter_foreground_task
---

# Servicio foreground y persistencia en segundo plano

## Objetivo

Garantizar que una frecu activa permanezca conectada y transmitiendo/recibiendo voz en segundo plano y con la pantalla apagada mediante un servicio en primer plano (foreground service) con notificación permanente, configurando `flutter_foreground_task` para mostrar el estado y nombre de la sala e iniciando y deteniendo el servicio según el ciclo de vida de la frecu.

## Fuera de alcance

- Migración de anfitrión (si el anfitrión se desconecta o sale de la frecu, la frecu se cierra para todos los participantes).
- Onboarding inicial de permisos y guía de configuración de hotspot (Fase 6).
- Transmisión o persistencia en servidores en la nube.

## Supuestos

- A1: En Android, un Foreground Service de tipo `microphone` con notificación permanente y wake lock evita que el sistema operativo mate el proceso o suspenda la CPU y los sockets WebRTC cuando la aplicación pasa a segundo plano o se apaga la pantalla.
  - impacto: alto
- A2: La notificación permanente muestra como título "Frecu activa" y como contenido el nombre de la sala y su estado actual (conectado o reconectando).
- A3: En entornos de prueba (unit tests), el datasource maneja la plataforma de forma segura simulando la operación sin invocar canales nativos no soportados.

## Criterios de aceptación

- AC1: CUANDO la aplicación pasa a segundo plano o se apaga la pantalla durante una frecu activa ENTONCES el servicio en primer plano mantiene activos los sockets de señalización y las pistas de audio WebRTC sin interrupciones perceptibles.

## Diseño

- **Data / Datasource**:
  - `ForegroundServiceDataSource`: Wrapper sobre `flutter_foreground_task` que gestiona la inicialización de canales de notificación Android (`channelId: frecu_foreground_service`, `channelName: Frecu en segundo plano`, `priority: low`, `importance: low`), configuración de wake lock y tipo de servicio `microphone`. Expone métodos `init()`, `startService({required String roomName, required String status})`, `updateNotification({required String roomName, required String status})` y `stopService()`.
- **Data / Repository & Providers**:
  - `RoomRepositoryImpl`: Se le inyecta `ForegroundServiceDataSource`. Al recibir bienvenida y confirmar conexión (`_onWelcome`), inicia el servicio con la notificación ("Frecu activa", nombre de la sala, "Conectado"). Ante transiciones a reconexión actualiza la notificación ("Reconectando..."). Al invocar `leaveRoom()` o al cerrarse la sala (`_onRoomClosed`, o fallo en reconexión), detiene el servicio en primer plano.
  - `room_provider.dart`: Provee `foregroundServiceDataSourceProvider` e inyecta la instancia en `roomRepositoryProvider`.
- **Plataformas**:
  - `AndroidManifest.xml`: Declaración de permisos `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`, `POST_NOTIFICATIONS`, `WAKE_LOCK` y registro del servicio `ForegroundService` con `foregroundServiceType="microphone"`.

## Archivos

- modificar pubspec.yaml — agregar flutter_foreground_task a dependencies
- modificar android/app/src/main/AndroidManifest.xml — permisos de servicio foreground, micrófono y registro del ForegroundService
- crear lib/features/room/data/datasources/foreground_service_datasource.dart — wrapper de flutter_foreground_task con ciclo de vida e inicio/parada
- crear test/features/room/data/foreground_service_datasource_test.dart — pruebas unitarias del datasource de foreground service
- modificar lib/features/room/data/repositories/room_repository_impl.dart — integración de inicio, actualización y parada del servicio foreground
- modificar lib/features/room/presentation/providers/room_provider.dart — provisión e inyección de ForegroundServiceDataSource
- modificar test/features/room/data/room_repository_test.dart — pruebas de integración de ciclo de vida del foreground service en RoomRepositoryImpl

## Tareas

- [x] T1: Dependencia flutter_foreground_task, configuración de Android y ForegroundServiceDataSource wrapper
  - files: pubspec.yaml, android/app/src/main/AndroidManifest.xml, lib/features/room/data/datasources/foreground_service_datasource.dart, test/features/room/data/foreground_service_datasource_test.dart
  - ac: AC1
  - verify: cd '/Users/innovacloud/Jorge Palacio/Proyectos/Frecu/.worktrees/20261107-servicio-foreground-y-persistencia-en-segundo' && fvm flutter test test/features/room/data/foreground_service_datasource_test.dart
- [x] T2: Conexión del ciclo de vida del foreground service en RoomRepositoryImpl y proveedores
  - files: lib/features/room/data/repositories/room_repository_impl.dart, lib/features/room/presentation/providers/room_provider.dart, test/features/room/data/room_repository_test.dart
  - ac: AC1
  - verify: cd '/Users/innovacloud/Jorge Palacio/Proyectos/Frecu/.worktrees/20261107-servicio-foreground-y-persistencia-en-segundo' && fvm flutter test test/features/room/data/room_repository_test.dart

## Riesgos

- R1: Agresividad de los fabricantes de Android en la gestión de batería que matan procesos en segundo plano — mitigación: Foreground Service con notificación permanente, wake lock controlado y tipo de servicio `microphone`.

## Cierre

### Resumen

Se integró satisfactoriamente el plugin `flutter_foreground_task` y se implementó `ForegroundServiceDataSource` para persistir la sala en segundo plano con notificación persistente ("Frecu activa", nombre de sala y estado). Se conectó el ciclo de vida del servicio en `RoomRepositoryImpl` y en los proveedores de Riverpod (`foregroundServiceDataSourceProvider`), iniciando el servicio al conectar la sala, actualizándolo a "Reconectando..." ante desconexiones transitorias y deteniéndolo limpiamente al abandonar o cerrarse la sala.

### Desviaciones

- Se corrigieron imports no utilizados en tests preexistentes (`invite_qr_dialog_test.dart` y `voice_flow_test.dart`) mediante peticiones de scope (`S3`, `S4`, `S5`) que quedaron solventadas e integradas limpiamente en T2.

### Decisiones

- Se configuró el Foreground Service con tipo `microphone`, notificación de baja intrusión y wake lock para asegurar la retención de sockets TCP/WebSocket y pistas WebRTC cuando la app pasa a segundo plano o se apaga la pantalla.

### Pendientes

- Ninguno en este corte vertical.
