---
kind: epic
---

# Permisos de plataforma y verificación de permisos

## Objetivo

Configurar los permisos de plataforma en Android (`AndroidManifest.xml`) e iOS (`Info.plist`) requeridos para la operación completa de la aplicación (micrófono, red local, escáner QR con cámara, bluetooth y servicios de fondo), e implementar la capa de verificación y solicitud reactiva de permisos en `features/permissions` bajo Clean Architecture.

## Fuera de alcance

- Rediseño visual o flujos completos de UI de onboarding (cubiertos en la épica de diseño Portadora).
- Lógica de streaming WebRTC o publicación mDNS (ya implementadas en sus respectivos features).

## Supuestos

- A1: El plugin `permission_handler: ^13.0.2` ya instalado en el proyecto gestiona la solicitud y verificación en runtime para micrófono, cámara, notificaciones y conexión bluetooth en Android e iOS.
  - impacto: alto

## Criterios de aceptación

- AC1: CUANDO se compila e inspecciona `android/app/src/main/AndroidManifest.xml` ENTONCES contiene los permisos `RECORD_AUDIO`, `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `BLUETOOTH_CONNECT`, `CAMERA`, conservando los permisos de foreground service y notificaciones.
- AC2: CUANDO se inspecciona `ios/Runner/Info.plist` ENTONCES contiene las descripciones de uso `NSMicrophoneUsageDescription`, `NSLocalNetworkUsageDescription`, `NSCameraUsageDescription`, el servicio Bonjour `_frecu._tcp` en `NSBonjourServices`, y el modo en segundo plano `audio` en `UIBackgroundModes`.
- AC3: CUANDO se invoca `PermissionDataSource` para consultar o solicitar un permiso (`microphone`, `camera`, `notification`, `bluetoothConnect`) ENTONCES delega a `permission_handler` y retorna el estado correspondiente.
- AC4: CUANDO `PermissionRepository` verifica o solicita permisos desde el dominio ENTONCES mapea los estados a entidades de Dart puro (`AppPermission` y `AppPermissionStatus`) retornando el resultado tipado en `Result`.
- AC5: CUANDO se consumen los providers de Riverpod `@riverpod` ENTONCES exponen de forma reactiva y testeable el repositorio de permisos y las operaciones de verificación y solicitud.

## Diseño

La épica se estructura en dos cortes verticales:

1. **C1 (Permisos en manifiestos de plataforma Android e iOS)**:
   - Declaración de permisos completos en `android/app/src/main/AndroidManifest.xml`.
   - Declaración de descripciones de privacidad, Bonjour y audio en segundo plano en `ios/Runner/Info.plist`.
   - Pruebas automatizadas de plataforma para validar la presencia de todos los permisos y directivas requeridas en los manifiestos.
2. **C2 (Datasource, repositorio y providers de permisos en features/permissions)**:
   - Dominio: Entidades `AppPermission`, `AppPermissionStatus` y contrato `PermissionRepository`.
   - Datos: Implementación `PermissionDataSource` (wrapper de `permission_handler`) y `PermissionRepositoryImpl`.
   - Presentación: Providers de Riverpod con `@riverpod` generador y tests unitarios exhaustivos con `mocktail`.

## Cortes

- C1: Permisos en manifiestos de plataforma Android e iOS
  - ac: AC1, AC2
- C2: Datasource, repositorio y providers de permisos en features/permissions
  - ac: AC3, AC4, AC5
  - depends: C1

## Riesgos

- R1: Divergencias entre nombres de permisos en Android/iOS y los enums de `permission_handler` — mitigación: Mapeador explícito con validación exhaustiva en tests unitarios.
