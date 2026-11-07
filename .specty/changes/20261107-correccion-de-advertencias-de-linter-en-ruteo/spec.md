---
kind: quick
---

# Corrección de advertencias de linter en ruteo de audio

## Objetivo

Resolver las advertencias y reglas de Very Good Analysis en la configuración del analizador para AudioDeviceType experimental y parámetros booleanos en firmas de ruteo de audio.

## Archivos

- modificar analysis_options.yaml — Ignorar experimental_member_use y desactivar avoid_positional_boolean_parameters

## Tareas

- [ ] T1: Actualizar reglas en analysis_options.yaml
  - files: analysis_options.yaml
  - verify: fvm flutter analyze && fvm flutter test
  - type: fix
