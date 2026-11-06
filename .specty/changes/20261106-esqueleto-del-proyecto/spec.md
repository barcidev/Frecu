---
kind: standard
allowedDependencies:
  - flutter_riverpod
  - riverpod_annotation
  - riverpod_generator
  - freezed
  - freezed_annotation
  - json_serializable
  - json_annotation
  - auto_route
  - auto_route_generator
  - slang
  - slang_flutter
  - slang_build_runner
  - build_runner
  - logger
  - very_good_analysis
  - mocktail
---

# Esqueleto del proyecto

## Objetivo

Crear el andamiaje del proyecto Flutter Frecu (Fase 0) con Clean Architecture por feature, dependencias base, linter con very_good_analysis, generadores con build_runner, soporte i18n con slang (es/en), AutoRoute con rutas iniciales vacías, tema, Result, Failure, logger y bootstrap.dart.

## Fuera de alcance

- Implementación de WebRTC y sockets de señalización (Fase 1).
- Implementación de descubrimiento mDNS y escaneo QR (Fase 2).
- Audio en tiempo real y PTT (Fase 4).
- Foreground service y lógica en segundo plano (Fase 5).

## Supuestos

- A1: El entorno utiliza Flutter 3.47.9 y Dart 3.13.7 gestionados mediante FVM (fvm).
- A2: La aplicación utiliza el paquete de organización com.frecu.app y nombre de proyecto frecu.
- A3: El idioma base de la aplicación es español (es) con soporte secundario para inglés (en) a través de Slang.

## Criterios de aceptación

- AC1: CUANDO se ejecuta `fvm flutter analyze` ENTONCES no se reportan errores ni advertencias de análisis estático.
- AC2: CUANDO se ejecuta `fvm flutter test` ENTONCES todas las pruebas unitarias pasan exitosamente.
- AC3: CUANDO se inicializa la aplicación ENTONCES se ejecuta bootstrap.dart, monta TranslationProvider, ProviderScope y configura AppRouter navegando a la pantalla inicial.

## Diseño

- Arquitectura limpia organizada por feature: core, app, i18n, features/permissions, features/lobby, features/room, features/settings.
- Result y Failure como uniones selladas e inmutables para el manejo funcional de resultados y errores sin lanzar excepciones a la capa de dominio.
- Navegación declarativa mediante auto_route con PermissionsGuard y rutas base (PermissionsRoute, LobbyRoute, CreateRoomRoute, ScanQrRoute, RoomRoute, SettingsRoute).

## Archivos

- crear pubspec.yaml — manifiesto de dependencias de Flutter
- crear analysis_options.yaml — linter con very_good_analysis
- crear slang.yaml — configuración de traducciones
- crear build.yaml — configuración de generadores build_runner
- crear lib/** — código fuente de la aplicación
- crear test/** — pruebas unitarias iniciales

## Tareas

- [x] T1: Inicializar el proyecto Flutter, configurar pubspec.yaml con dependencias base, analysis_options.yaml y slang.yaml.
  - files: pubspec.yaml, analysis_options.yaml, slang.yaml, build.yaml
  - ac: AC1
  - verify: fvm flutter pub get
  - type: build
- [x] T2: Implementar contratos del núcleo (Result, Failure, logger, usecase, constants), traducciones i18n (es/en) y sus pruebas unitarias.
  - files: lib/core/**, lib/i18n/**, test/core/**
  - ac: AC1, AC2
  - verify: fvm dart run build_runner build -d && fvm dart run slang && fvm flutter test test/core
  - type: feat
- [x] T3: Implementar capa de aplicación (AppRouter, guards, tema, app.dart, bootstrap, main), páginas base de features y prueba de widget/arranque.
  - files: lib/app/**, lib/features/**, lib/bootstrap.dart, lib/main.dart, test/app_test.dart
  - ac: AC1, AC2, AC3
  - verify: fvm flutter analyze && fvm flutter test
  - type: feat

## Riesgos

- R1: Incompatibilidad entre versiones recientes de plugins generadores en Dart 3 — mitigación: verificar versiones compatibles y estables en pub.dev.
