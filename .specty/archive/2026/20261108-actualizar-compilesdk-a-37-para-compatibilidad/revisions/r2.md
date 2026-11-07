---
kind: quick
---

# Actualizar compileSdk a 37 para compatibilidad de plugins Android

## Objetivo

Actualizar `compileSdk` a la versión 37 en `android/app/build.gradle.kts` para resolver el requerimiento de compilación de `permission_handler_android` y permitir empaquetar la aplicación Android en modo release.

## Archivos

- modificar android/app/build.gradle.kts — configurar compileSdk = 37 para compatibilidad de plugins nativos

## Tareas

- [ ] T1: Configurar compileSdk en 37
  - files: android/app/build.gradle.kts
  - verify: ./android/gradlew assembleRelease -p android -x lint
