---
kind: standard
epic: 20261107-modos-de-habla-y-ruteo-de-audio
slice: C1
---

# Ruteo de audio a altavoz, auricular y Bluetooth

## Objetivo

Permitir a los participantes en una frecu conmutar la salida de audio en tiempo real entre el altavoz del teléfono, el auricular integrado y dispositivos Bluetooth conectados, actualizando dinámicamente la interfaz ante cambios de periféricos.

## Fuera de alcance

- Modos de habla PTT interactivo y selector de modo (corresponde al corte C2).
- Gestión avanzada de perfiles de audio Bluetooth de baja latencia o BLE Audio custom.

## Supuestos

- A1: El paquete `audio_session` y la API WebRTC permiten redirigir la salida de audio hacia el altavoz, auricular o Bluetooth sin reiniciar la pista de audio o la conexión peer.
  - impacto: alto
- A2: Si un dispositivo Bluetooth se conecta o desconecta durante una frecu activa, la sesión de audio actualiza automáticamente la lista de rutas disponibles y realiza un fallback seguro a altavoz si la ruta activa era Bluetooth.

## Criterios de aceptación

- AC1: CUANDO el usuario conmuta la salida de audio entre altavoz, auricular y Bluetooth ENTONCES la sesión de audio redirige la salida al dispositivo seleccionado y actualiza el icono de ruta de audio en tiempo real.
- AC2: CUANDO se conecta o desconecta un accesorio de audio (auriculares cableados o Bluetooth) ENTONCES el sistema detecta el cambio de periférico y actualiza la ruta de audio activa.

## Diseño

Se aplica Clean Architecture por feature:

- **Domain (Dart puro)**:
  - Entidad `AudioRoute` (`speaker`, `earpiece`, `bluetooth`) sin dependencias de Flutter ni `audio_session`.
  - Contrato `VoiceRepository` enriquecido con `setAudioRoute(AudioRoute)`, `setSpeakerOn(bool)`, `watchAudioRoute()` y `watchAvailableAudioRoutes()`.
  - Casos de uso `SetAudioRoute` y `SetSpeakerOn`.
- **Data**:
  - `AudioSessionDataSource`: escucha `devicesStream` de `AudioSession` y provee métodos para conmutar altavoz y auricular/bluetooth mediante `Helper.setSpeakerphoneOn`.
  - `VoiceRepositoryImpl`: coordina la ruta activa, mapea dispositivos a `AudioRoute` y reacciona a desconexiones de periféricos activos haciendo fallback a altavoz.
- **Presentation**:
  - `voice_provider`: almacena `audioRoute` y `availableAudioRoutes` en `VoiceState`, y expone métodos de conmutación y ciclado de ruta (`cycleAudioRoute()`).
  - `RoomPage`: botón de acción `audio_route_button` con icono dinámico según la ruta activa (`Icons.volume_up`, `Icons.phone_in_talk`, `Icons.bluetooth_audio`).

## Archivos

- crear lib/features/room/domain/entities/audio_route.dart — Definición de la entidad AudioRoute (speaker, earpiece, bluetooth) en Dart puro.
- modificar lib/features/room/domain/repositories/voice_repository.dart — Añadir setAudioRoute, setSpeakerOn, watchAudioRoute y watchAvailableAudioRoutes al contrato.
- crear lib/features/room/domain/usecases/set_audio_route.dart — Caso de uso para cambiar la ruta de audio.
- crear lib/features/room/domain/usecases/set_speaker_on.dart — Caso de uso para conmutar altavoz.
- modificar lib/features/room/domain/usecases/voice_usecases.dart — Exportar casos de uso de ruteo de audio.
- modificar lib/features/room/data/datasources/audio_session_datasource.dart — Gestión de AudioDevice, stream de dispositivos y control de salida a altavoz / bluetooth.
- modificar lib/features/room/data/repositories/voice_repository_impl.dart — Implementación de ruteo de audio y actualización reactiva ante desconexión de dispositivos.
- modificar lib/features/room/presentation/providers/voice_provider.dart — Integrar audioRoute y availableAudioRoutes en VoiceState y notifier.
- modificar lib/features/room/presentation/pages/room_page.dart — Botón de control de ruta de audio con icono dinámico.
- modificar lib/i18n/strings.i18n.json — Textos localizados para earpiece en español.
- modificar lib/i18n/strings_en.i18n.json — Textos localizados para earpiece en inglés.
- modificar test/features/room/domain/entities_test.dart — Tests unitarios para AudioRoute.
- crear test/features/room/domain/audio_route_usecases_test.dart — Tests unitarios para casos de uso de ruteo de audio.
- modificar test/features/room/data/voice_repository_test.dart — Tests de integración para conmutación de ruta y detección de desconexión.
- modificar test/features/room/presentation/voice_flow_test.dart — Tests de interfaz para conmutación de ruta y actualización de icono en RoomPage.

## Tareas

- [x] T1: Entidad AudioRoute y contrato VoiceRepository en domain
  - files: lib/features/room/domain/entities/audio_route.dart, lib/features/room/domain/repositories/voice_repository.dart, test/features/room/domain/entities_test.dart
  - ac: AC1
  - verify: fvm flutter test test/features/room/domain/entities_test.dart
- [x] T2: Casos de uso de ruteo de audio (SetAudioRoute, SetSpeakerOn)
  - files: lib/features/room/domain/usecases/set_audio_route.dart, lib/features/room/domain/usecases/set_speaker_on.dart, lib/features/room/domain/usecases/voice_usecases.dart, test/features/room/domain/audio_route_usecases_test.dart
  - ac: AC1
  - verify: fvm flutter test test/features/room/domain/audio_route_usecases_test.dart
- [ ] T3: Integración de AudioDevice y ruteo en AudioSessionDataSource y VoiceRepositoryImpl
  - files: lib/features/room/data/datasources/audio_session_datasource.dart, lib/features/room/data/repositories/voice_repository_impl.dart, test/features/room/data/voice_repository_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter test test/features/room/data/voice_repository_test.dart
- [ ] T4: Proveedores de estado en voice_provider y control visual con icono dinámico en RoomPage
  - files: lib/features/room/presentation/providers/voice_provider.dart, lib/features/room/presentation/pages/room_page.dart, lib/i18n/strings.i18n.json, lib/i18n/strings_en.i18n.json, test/features/room/presentation/voice_flow_test.dart
  - ac: AC1, AC2
  - verify: fvm flutter test test/features/room/presentation/voice_flow_test.dart

## Riesgos

- R1: El comportamiento de conmutación Bluetooth puede variar según la plataforma nativa y permisos — mitigación: delegar en `Helper.setSpeakerphoneOn` de WebRTC y `audio_session`, con fallback automático a altavoz ante errores o desconexión.
