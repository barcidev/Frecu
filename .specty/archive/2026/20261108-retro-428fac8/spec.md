---
kind: retro
---

# Cambios manuales en ios

## Objetivo

El proyecto iOS queda integrado con CocoaPods. El workspace `Runner.xcworkspace` incluye `Pods/Pods.xcodeproj`, y `Runner.xcodeproj` enlaza `Pods_Runner.framework` y `Pods_RunnerTests.framework`, con sus `xcconfig` de Pods para debug, release y profile y las fases `[CP] Check Pods Manifest.lock`, `[CP] Embed Pods Frameworks` y `[CP] Copy Pods Resources`. `Podfile.lock` fija las versiones de los pods de los plugins: audio_session, flutter_foreground_task, flutter_webrtc 1.6.3 con WebRTC-SDK 150.7871.04, mobile_scanner 7.0.0, nsd_ios, permission_handler_apple 9.4.8 y shared_preferences_foundation. Usa CocoaPods 1.16.2. Ningún cambio toca código Dart ni el comportamiento de la app.

## Motivo

Es lo que genera CocoaPods (`pod install`, que también ejecuta `flutter run` o `flutter build ios`) la primera vez que se compila la app para iOS con los plugins nativos. `ios/Podfile` existe desde 3ea957b, pero hasta ahora no había `Podfile.lock` ni integración de Pods en el proyecto Xcode. Se guarda en el repositorio para que cualquier compilación de iOS use las mismas versiones de los pods y para que la carpeta principal (develop) quede limpia: con estos archivos sin commit, `specty close` no puede avanzar develop.

## Archivos

- crear ios/Podfile.lock
- modificar ios/Runner.xcodeproj/project.pbxproj
- modificar ios/Runner.xcworkspace/contents.xcworkspacedata

## Riesgos

- R1: `Podfile.lock` congela las versiones de los pods; al subir un plugin en `pubspec.yaml` puede quedar desfasado y `[CP] Check Pods Manifest.lock` fallará al compilar. Mitigación: ejecutar `pod install` (o `flutter run`) en `ios/` y guardar el `Podfile.lock` resultante junto con el cambio de dependencias.
- R2: `project.pbxproj` es propenso a conflictos de merge. Mitigación: ningún corte abierto de la épica Portadora toca `ios/`; los cambios futuros en Xcode se hacen en un solo cambio a la vez.
- R3: compilar para iOS exige CocoaPods instalado (1.16.2 o compatible). Mitigación: es requisito estándar de Flutter en iOS; Android y las pruebas (`flutter test`) no se ven afectados.
