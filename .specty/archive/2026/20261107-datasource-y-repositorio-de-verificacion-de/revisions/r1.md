---
kind: standard
---

# Datasource y repositorio de verificación de permisos

## Objetivo

Implementar la arquitectura de verificación y solicitud de permisos para la aplicación en el módulo `features/permissions`, introduciendo entidades de dominio en Dart puro, un datasource desacoplable sobre `permission_handler`, la implementación del repositorio con manejo funcional de resultados (`Result`) y sus providers de Riverpod.

## Fuera de alcance

- Rediseño visual de la pantalla `PermissionsPage`.
- Modificación de la lógica de navegación o de `PermissionsGuard`.
- Integración de nuevos permisos no contemplados en los requerimientos del proyecto.

## Supuestos

- A1: El plugin `permission_handler` provee los métodos de plataforma necesarios para consultar y solicitar los permisos `microphone`, `camera`, `notification` y `bluetoothConnect`, además de abrir los ajustes del sistema con `openAppSettings()`.
- A2: La capa de dominio permanece en Dart puro sin dependencias directas de Flutter ni plugins nativos, permitiendo portabilidad y facilidad de pruebas unitarias.

## Criterios de aceptación

- AC1: CUANDO se consulta el estado de un permiso o se solicita mediante `PermissionRepository` ENTONCES se mapea el tipo `AppPermission` a `permission_handler` y se retorna un `Result.success(AppPermissionStatus)` con el estado mapeado correspondiente.
- AC2: CUANDO ocurre una excepción en el datasource al verificar o solicitar permisos ENTONCES `PermissionRepository` captura la excepción y retorna un `Result.failure(Failure.unexpected(...))`.
- AC3: CUANDO se invoca `requestAll` con una lista de permisos ENTONCES el repositorio solicita cada permiso y retorna un mapa completo de `AppPermission` a `AppPermissionStatus` envuelto en `Result.success`.
- AC4: CUANDO se invoca `openAppSettings` ENTONCES delega a la función de configuración del sistema del datasource y retorna un booleano indicando el éxito.
- AC5: CUANDO se leen los proveedores `permissionDataSourceProvider` y `permissionRepositoryProvider` ENTONCES se obtienen instancias válidas de `PermissionDataSource` y `PermissionRepository`.
- AC6: CUANDO se ejecutan las pruebas unitarias en `test/features/permissions/` ENTONCES todas pasan satisfactoriamente sin fallos con `fvm flutter test test/features/permissions/`.

## Archivos

- crear lib/features/permissions/domain/entities/app_permission.dart — definición de enums de dominio AppPermission y AppPermissionStatus
- crear lib/features/permissions/domain/repositories/permission_repository.dart — contrato abstracto en Dart puro para verificación y solicitud de permisos
- crear lib/features/permissions/data/datasources/permission_datasource.dart — wrapper desacoplable sobre permission_handler
- crear lib/features/permissions/data/repositories/permission_repository_impl.dart — implementación del repositorio mapeando tipos nativos a dominio con Result
- crear lib/features/permissions/presentation/providers/permission_provider.dart — definición de providers Riverpod para datasource y repository
- crear lib/features/permissions/presentation/providers/permission_provider.g.dart — código generado por riverpod_generator
- crear test/features/permissions/domain/app_permission_test.dart — pruebas unitarias de enums y entidades de dominio de permisos
- crear test/features/permissions/data/permission_datasource_test.dart — pruebas unitarias del datasource de permisos
- crear test/features/permissions/data/permission_repository_impl_test.dart — pruebas unitarias del repositorio de permisos
- crear test/features/permissions/presentation/permission_provider_test.dart — pruebas unitarias de los providers de permisos

## Tareas

- [ ] T1: Entidades de dominio y contrato abstracto del repositorio con pruebas
  - files: lib/features/permissions/domain/entities/app_permission.dart, lib/features/permissions/domain/repositories/permission_repository.dart, test/features/permissions/domain/app_permission_test.dart
  - ac: AC1, AC4
  - verify: fvm flutter test test/features/permissions/domain/
- [ ] T2: Datasource e implementación del repositorio con pruebas unitarias
  - files: lib/features/permissions/data/datasources/permission_datasource.dart, lib/features/permissions/data/repositories/permission_repository_impl.dart, test/features/permissions/data/permission_datasource_test.dart, test/features/permissions/data/permission_repository_impl_test.dart
  - ac: AC1, AC2, AC3, AC4, AC6
  - verify: fvm flutter test test/features/permissions/data/
- [ ] T3: Providers de Riverpod y pruebas de integración de dependencias
  - files: lib/features/permissions/presentation/providers/permission_provider.dart, lib/features/permissions/presentation/providers/permission_provider.g.dart, test/features/permissions/presentation/permission_provider_test.dart
  - ac: AC5, AC6
  - verify: dart run build_runner build -d && fvm flutter test test/features/permissions/presentation/ && fvm flutter analyze
