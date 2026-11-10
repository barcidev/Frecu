---
kind: standard
---

# Nombrado de parámetros booleanos en ruteo de audio

## Objetivo

Refactorizar los métodos de ruteo de audio que reciben booleanos posicionales para usar parámetros nombrados (`{required bool enabled}`) e ignorar miembros experimentales de paquetes externos en `analysis_options.yaml`, garantizando cero advertencias en `very_good_analysis`.

## Fuera de alcance

- Cambios de funcionalidad en ruteo o WebRTC.

## Supuestos

- A1: El uso de parámetros nombrados `{required bool enabled}` cumple con la regla `avoid_positional_boolean_parameters` de Very Good Analysis sin alterar el comportamiento en tiempo de ejecución.

## Criterios de aceptación

- AC1: CUANDO se ejecuta `fvm flutter analyze` ENTONCES no se reportan advertencias de `avoid_positional_boolean_parameters` ni de `experimental_member_use`.

## Archivos

- modificar analysis_options.yaml — Ignorar experimental_member_use
- modificar lib/features/room/data/datasources/audio_session_datasource.dart — Usar parámetros nombrados booleanos
- modificar lib/features/room/domain/repositories/voice_repository.dart — Usar parámetros nombrados en setSpeakerOn
- modificar lib/features/room/data/repositories/voice_repository_impl.dart — Implementar setSpeakerOn con parámetro nombrado
- modificar lib/features/room/domain/usecases/set_speaker_on.dart — Actualizar llamada con parámetro nombrado
- modificar lib/features/room/presentation/providers/voice_provider.dart — Actualizar método setSpeakerOn con parámetro nombrado
- modificar test/features/room/data/voice_repository_test.dart — Actualizar llamadas en pruebas
- modificar test/features/room/presentation/voice_flow_test.dart — Actualizar llamadas en pruebas

## Tareas

- [ ] T1: Actualizar firmas en datasources, domain y analyzer
  - files: analysis_options.yaml, lib/features/room/data/datasources/audio_session_datasource.dart, lib/features/room/domain/repositories/voice_repository.dart, lib/features/room/domain/usecases/set_speaker_on.dart
  - ac: AC1
  - verify: fvm flutter analyze
  - type: refactor
- [ ] T2: Actualizar implementación en repository, provider y tests
  - files: lib/features/room/data/repositories/voice_repository_impl.dart, lib/features/room/presentation/providers/voice_provider.dart, test/features/room/data/voice_repository_test.dart, test/features/room/presentation/voice_flow_test.dart
  - ac: AC1
  - verify: fvm flutter analyze && fvm flutter test
  - type: refactor
