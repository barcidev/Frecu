---
kind: standard
---

# Deteccion de interfaz de red y estado de hotspot

## Objetivo

Implementar la feature `features/network` para la detección autónoma de interfaces de red locales activas (WiFi cliente o Hotspot/Punto de acceso móvil) sin requerir acceso a internet ni servidores externos, proporcionando estados inmutables con Freezed 3, un contrato de repositorio en Dart puro, un datasource parametrizable sobre `NetworkInterface.list()` y providers de Riverpod.

## Fuera de alcance

- Conexión a servidores externos o resolución DNS en internet.
- Modificación de interfaces de red a nivel de sistema operativo (creación de puntos de acceso o conexión programática a SSIDs).
- Integración visual o cambios en páginas existentes de la UI.

## Supuestos

- A1: La detección de interfaces de red locales en Dart (`dart:io` `NetworkInterface.list`) provee acceso a las direcciones IP IPv4 asignadas a nivel de dispositivo móvil y de escritorio sin requerir paquetes de red externos.
- A2: Los puntos de acceso WiFi (Hotspot) comúnmente asignan direcciones en subredes estándar como `192.168.43.0/24` (Android), `172.20.10.0/28` (iOS) o `192.168.49.0/24` (Wi-Fi Direct), o utilizan nombres de interfaz característicos (`ap`, `softap`, `wlan`, etc.).
- A3: La capa de dominio permanece en Dart puro sin dependencias de Flutter ni `dart:io`.

## Criterios de aceptación

- AC1: CUANDO no existan interfaces de red activas o solo haya direcciones loopback ENTONCES `getNetworkState` retorna `Result.success(NetworkState.disconnected())`.
- AC2: CUANDO se detecta una interfaz IPv4 activa no loopback ENTONCES `getNetworkState` retorna `Result.success(NetworkState.connected(...))` con la dirección IP, el nombre de la interfaz y el indicador de hotspot.
- AC3: CUANDO la dirección IP o la interfaz pertenece a un rango o identificador de hotspot conocido (`192.168.43.x`, `172.20.10.x`, `192.168.49.x` o interfaz con prefijo ap/softap) ENTONCES `isHotspot` es verdadero (`true`).
- AC4: CUANDO ocurre una excepción al consultar las interfaces de red ENTONCES `getNetworkState` retorna `Result.failure(Failure.network(...))` con el mensaje de error.
- AC5: CUANDO se escucha `watchNetworkState()` ENTONCES emite periódicamente el estado actual de la red filtrando emisiones duplicadas consecutivas.
- AC6: CUANDO se leen los proveedores `networkInterfaceDataSourceProvider`, `networkRepositoryProvider` y `networkStateStreamProvider` ENTONCES retornan instancias no nulas de tipo `NetworkInterfaceDataSource`, `NetworkRepository` y `Stream<NetworkState>`.
- AC7: CUANDO se ejecutan las pruebas unitarias en `test/features/network/` ENTONCES todas pasan exitosamente con `fvm flutter test test/features/network/`.

## Archivos

- crear lib/features/network/domain/entities/network_state.dart — entidad sealed class Freezed con estados disconnected y connected
- crear lib/features/network/domain/entities/network_state.freezed.dart — código generado por freezed para NetworkState
- crear lib/features/network/domain/repositories/network_repository.dart — contrato abstracto del repositorio en Dart puro
- crear lib/features/network/data/datasources/network_interface_datasource.dart — wrapper parametrizable sobre NetworkInterface.list para IPv4
- crear lib/features/network/data/repositories/network_repository_impl.dart — implementación de NetworkRepository con manejo funcional Result y stream
- crear lib/features/network/presentation/providers/network_provider.dart — definición de providers Riverpod con anotaciones
- crear lib/features/network/presentation/providers/network_provider.g.dart — código generado por riverpod_generator
- crear test/features/network/domain/network_state_test.dart — pruebas unitarias para NetworkState
- crear test/features/network/data/network_interface_datasource_test.dart — pruebas unitarias para NetworkInterfaceDataSource
- crear test/features/network/data/network_repository_impl_test.dart — pruebas unitarias para NetworkRepositoryImpl
- crear test/features/network/presentation/network_provider_test.dart — pruebas unitarias para network_provider

## Tareas

- [ ] T1: Entidad de dominio NetworkState y contrato NetworkRepository con pruebas
  - files: lib/features/network/domain/entities/network_state.dart, lib/features/network/domain/entities/network_state.freezed.dart, lib/features/network/domain/repositories/network_repository.dart, test/features/network/domain/network_state_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter test test/features/network/domain/
- [ ] T2: Datasource de interfaces de red e implementación del repositorio con pruebas
  - files: lib/features/network/data/datasources/network_interface_datasource.dart, lib/features/network/data/repositories/network_repository_impl.dart, test/features/network/data/network_interface_datasource_test.dart, test/features/network/data/network_repository_impl_test.dart
  - ac: AC1, AC2, AC3, AC4, AC5
  - verify: fvm flutter test test/features/network/data/
- [ ] T3: Providers de Riverpod y pruebas de integración
  - files: lib/features/network/presentation/providers/network_provider.dart, lib/features/network/presentation/providers/network_provider.g.dart, test/features/network/presentation/network_provider_test.dart
  - ac: AC6, AC7
  - verify: fvm flutter test test/features/network/ && fvm flutter analyze
