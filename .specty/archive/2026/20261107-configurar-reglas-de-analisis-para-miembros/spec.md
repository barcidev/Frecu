---
kind: standard
---

# Configurar reglas de análisis para miembros experimentales y booleanos

## Objetivo

Actualizar la configuración del analizador estático en `analysis_options.yaml` para ignorar diagnósticos de miembros experimentales en paquetes de terceros y desactivar la regla de parámetros booleanos posicionales en APIs internas, asegurando que `fvm flutter analyze` pase sin advertencias.

## Fuera de alcance

- Modificación de lógica de producción o interfaces de usuario.

## Supuestos

- A1: Ignorar `experimental_member_use` y desactivar `avoid_positional_boolean_parameters` permite compilar limpiamente con el SDK y plugins nativos de audio actuales.

## Criterios de aceptación

- AC1: CUANDO se ejecuta `fvm flutter analyze` ENTONCES no se emiten advertencias ni errores en el código del proyecto.

## Archivos

- modificar analysis_options.yaml — Configurar ignorado de experimental_member_use y regla avoid_positional_boolean_parameters

## Tareas

- [x] T1: Actualizar analysis_options.yaml
  - files: analysis_options.yaml
  - ac: AC1
  - verify: fvm flutter analyze
  - type: build

## Cierre

### Resumen

Se actualizó la configuración de `analysis_options.yaml` para evitar falsos positivos y advertencias no bloqueantes:
- Se añadió `experimental_member_use: ignore` bajo `analyzer.errors` para silenciar advertencias relativas al uso de `AudioDeviceType` del paquete nativo `audio_session`.
- Se desactivó la regla `avoid_positional_boolean_parameters: false` bajo `linter.rules` para mantener compatibilidad con las firmas de control de altavoz en `AudioSessionDataSource` y `VoiceRepository`.
- `fvm flutter analyze` ejecuta con cero advertencias.

### Desviaciones

- Ninguna.

### Decisiones

- Mantener la firma `setSpeakerOn(bool enabled)` y la delegación nativa sin alterar contratos existentes de repositorios, ajustando la configuración del analizador para alinearse con los plugins de plataforma.

### Pendientes

- Ninguno.
