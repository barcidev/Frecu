---
kind: standard
---

# Permisos de plataforma Android e iOS

## Objetivo

Configurar los permisos de plataforma en Android (`AndroidManifest.xml`) e iOS (`Info.plist`) requeridos para la captura y reproducción de voz grupal en red local, descubrimiento mDNS, escaneo QR y audio en segundo plano, verificando su presencia mediante pruebas automatizadas.

## Fuera de alcance

- Implementación o cambios en el módulo Dart de permisos (`lib/features/permissions`).
- Lógica de interfaz de usuario para solicitar permisos en tiempo de ejecución (runtime permissions).
- Modificaciones a archivos de código en `lib/`.

## Supuestos

- A1: La declaración de permisos a nivel de manifiesto nativo en Android e iOS es necesaria y suficiente para habilitar el uso de micrófono, cámara, red local mDNS, Bluetooth y tareas foreground sin bloqueos por parte del sistema operativo.
- A2: Los tests automatizados leen directamente el contenido de los archivos `android/app/src/main/AndroidManifest.xml` e `ios/Runner/Info.plist` mediante I/O de archivos en Dart para verificar las claves y valores requeridos de forma determinista y sin requerir dispositivos físicos.

## Criterios de aceptación

- AC1: CUANDO se inspecciona `android/app/src/main/AndroidManifest.xml` ENTONCES contiene todos los permisos necesarios (`android.permission.RECORD_AUDIO`, `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`, `BLUETOOTH_CONNECT`, `CAMERA`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE`, `POST_NOTIFICATIONS`, `WAKE_LOCK`) y la declaración del servicio `ForegroundService` de tipo `microphone`.
- AC2: CUANDO se inspecciona `ios/Runner/Info.plist` ENTONCES contiene las descripciones de uso `NSMicrophoneUsageDescription`, `NSLocalNetworkUsageDescription` y `NSCameraUsageDescription`, el servicio de Bonjour `_frecu._tcp` en `NSBonjourServices`, y el modo en segundo plano `audio` en `UIBackgroundModes`.
- AC3: CUANDO se ejecutan las pruebas de `test/platform/platform_manifest_test.dart` con `fvm flutter test test/platform/platform_manifest_test.dart` ENTONCES todas las aserciones sobre `AndroidManifest.xml` e `Info.plist` pasan satisfactoriamente.

## Archivos

- modificar android/app/src/main/AndroidManifest.xml — configuración de permisos requeridos por plataforma Android
- modificar ios/Runner/Info.plist — configuración de descripciones de uso, Bonjour y background audio para iOS
- crear test/platform/platform_manifest_test.dart — prueba unitaria para validar los permisos y configuraciones en ambos manifiestos

## Tareas

- [x] T1: Configurar permisos de plataforma Android e iOS con sus pruebas automatizadas
  - files: android/app/src/main/AndroidManifest.xml, ios/Runner/Info.plist, test/platform/platform_manifest_test.dart
  - ac: AC1, AC2, AC3
  - verify: cd '/Users/innovacloud/Jorge Palacio/Proyectos/Frecu/.worktrees/20261107-permisos-de-plataforma-android-e-ios' && fvm flutter test test/platform/platform_manifest_test.dart
