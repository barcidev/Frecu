---
kind: standard
epic: 20261106-descubrimiento-y-union
slice: C1
allowedDependencies:
  - nsd
---

# Descubrimiento local mDNS y código de acceso

## Objetivo

Permitir a los participantes descubrir automáticamente las frecus activas en la red local mediante mDNS (`_frecu._tcp`) y unirse a ellas seleccionándolas e ingresando su código de acceso PIN de 4 dígitos, sin necesidad de escribir la dirección IP manualmente.

## Fuera de alcance

- Generación y escaneo de códigos QR de invitación (Corte C2).
- Topología mesh para más de 2 participantes (Fase 3).
- Modo Push-to-Talk y ruteo Bluetooth (Fase 4).

## Supuestos

- A1: El punto de acceso WiFi o Hotspot permite el paso de paquetes multicast DNS (mDNS) entre dispositivos conectados.
  - impacto: alto
- A2: Los atributos TXT anunciados en el servicio mDNS incluyen `roomId`, `name` y versión de protocolo `v`.
- A3: El código de acceso de 4 dígitos no viaja en el anuncio mDNS público para resguardar la privacidad de la frecu; se solicita al unirse.

## Criterios de aceptación

- AC1: CUANDO el anfitrión crea una frecu ENTONCES se publica el servicio mDNS `_frecu._tcp` con los atributos `roomId`, `name` y versión de protocolo `v`.
- AC2: CUANDO un participante abre el lobby en la misma red local ENTONCES descubre automáticamente las frecus activas anunciadas por mDNS y las muestra en la lista de frecus cercanas.
- AC3: CUANDO un participante selecciona una frecu descubierta e ingresa el código de acceso ENTONCES se conecta a la sala si el código es válido o recibe notificación de rechazo si es incorrecto.

## Diseño

- **Domain**:
  - Entidad `NearbyRoom`: `roomId`, `name`, `hostAddress`, `port`, `protocolVersion`.
  - Contrato `DiscoveryRepository`: `watchNearbyRooms()`, `publishRoom()`, `stopPublishing()`.
  - Casos de uso: `DiscoverRooms`, `PublishRoom`, `StopPublishingRoom`.
- **Data**:
  - `MdnsDataSource`: Envoltorio testeable del plugin `nsd` para registrar y descubrir servicios `_frecu._tcp`.
  - `DiscoveryRepositoryImpl`: Implementa `DiscoveryRepository` coordinando el datasource mDNS y mapeando servicios descubiertos a `NearbyRoom`.
- **Presentation**:
  - Proveedores de Riverpod: `discoveryRepositoryProvider`, `nearbyRoomsProvider`.
  - `LobbyPage`: Lista reactiva de frecus cercanas descubiertas con estado vacío, diálogo de PIN al seleccionar una sala y manejo de errores de rechazo.
  - Publicación y detención automática del servicio mDNS al crear o abandonar la frecu.

## Archivos

- modificar pubspec.yaml — añadir dependencia nsd
- crear lib/features/lobby/domain/entities/nearby_room.dart — entidad NearbyRoom
- crear lib/features/lobby/domain/repositories/discovery_repository.dart — contrato DiscoveryRepository
- crear lib/features/lobby/domain/usecases/discovery_usecases.dart — casos de uso de descubrimiento y publicación
- crear test/features/lobby/domain/discovery_usecases_test.dart — pruebas unitarias de casos de uso de descubrimiento
- crear lib/features/lobby/data/datasources/mdns_datasource.dart — datasource mDNS con nsd
- crear lib/features/lobby/data/repositories/discovery_repository_impl.dart — implementación de DiscoveryRepository
- crear test/features/lobby/data/discovery_repository_test.dart — pruebas unitarias de datasource y repositorio mDNS
- crear lib/features/lobby/presentation/providers/discovery_provider.dart — notifiers de Riverpod para descubrimiento
- modificar lib/features/lobby/presentation/pages/lobby_page.dart — lista de frecus descubiertas y diálogo de PIN
- modificar lib/features/room/presentation/pages/create_room_page.dart — publicar mDNS al crear sala
- crear test/features/lobby/presentation/discovery_flow_test.dart — pruebas de integración UI de descubrimiento y unión por PIN

## Tareas

- [x] T1: Configurar dependencia nsd, entidad NearbyRoom, contrato DiscoveryRepository y casos de uso con pruebas.
  - files: pubspec.yaml, lib/features/lobby/domain/entities/nearby_room.dart, lib/features/lobby/domain/repositories/discovery_repository.dart, lib/features/lobby/domain/usecases/discovery_usecases.dart, test/features/lobby/domain/discovery_usecases_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter test test/features/lobby/domain/discovery_usecases_test.dart
  - type: build
- [x] T2: Implementar MdnsDataSource y DiscoveryRepositoryImpl con pruebas.
  - files: lib/features/lobby/data/datasources/mdns_datasource.dart, lib/features/lobby/data/repositories/discovery_repository_impl.dart, test/features/lobby/data/discovery_repository_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter test test/features/lobby/data/discovery_repository_test.dart
  - type: feat
- [x] T3: Proveedores de Riverpod, integración en LobbyPage y manejo de PIN con pruebas UI.
  - files: lib/features/lobby/presentation/providers/discovery_provider.dart, lib/features/lobby/presentation/pages/lobby_page.dart, lib/features/room/presentation/pages/create_room_page.dart, test/features/lobby/presentation/discovery_flow_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter analyze && fvm flutter test
  - type: feat

## Riesgos

- R1: El emulador o entorno de pruebas puede no tener soporte mDNS nativo — mitigación: abstraer el plugin nsd con fábricas y dobles de prueba para verificar registro y descubrimiento sin red física.

## Cierre

### Resumen

Se implementó el descubrimiento local automático de frecus mediante mDNS y la unión por PIN de 4 dígitos:
- Se incorporó la dependencia nsd para registro y descubrimiento de servicios _frecu._tcp con atributos TXT (roomId, name, v).
- Se definió la entidad NearbyRoom, el contrato DiscoveryRepository y los casos de uso PublishRoom, StopPublishingRoom y DiscoverRooms.
- Se implementó MdnsDataSource con funciones inyectables para pruebas y manejo de eventos found/lost, junto con DiscoveryRepositoryImpl.
- Se integró Riverpod (discoveryRepositoryProvider, nearbyRoomsProvider) y se adaptó LobbyPage con la lista reactiva de salas cercanas y el diálogo de ingreso de PIN (_PinJoinDialog).
- Se integró la publicación mDNS en CreateRoomPage al crear una sala como anfitrión.
- Se verificaron los criterios AC1, AC2 y AC3 con 35 pruebas unitarias y de integración UI pasando con 0 advertencias de análisis estático.

### Desviaciones

- Se añadió a la tarea T3 el archivo lib/features/lobby/presentation/pages/create_room_page.dart (aprobado bajo S4) ya que la página de creación de sala residía en la feature de lobby en la arquitectura del proyecto.
- Se ajustó el estado de carga inicial en _NearbyRoomsList para evitar temporizadores infinitos de CircularProgressIndicator durante la ejecución de pruebas con pumpAndSettle().

### Decisiones

- Los atributos TXT de mDNS no incluyen el código de acceso (PIN) para preservar la privacidad de la sala frente a escaneos pasivos en la red; el PIN se solicita interactivamente al usuario en el lobby.
- Se encapsuló nsd en MdnsDataSource mediante delegados funcionales inyectables, permitiendo pruebas unitarias deterministas y completas sin requerir dependencias de red física o simuladores externos.

### Pendientes

- Implementación del corte C2: Generación de código QR para invitación y escaneo con cámara como mecanismo alternativo de respaldo.
