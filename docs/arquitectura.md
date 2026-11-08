# Arquitectura — Frecu

Clean Architecture organizada **por feature**, con principios SOLID.

## Reglas de dependencia

```
presentation  →  domain  ←  data
```

- `domain` es Dart puro. **Prohibido** importar `flutter`, `flutter_webrtc`, `shelf`, `nsd` o cualquier plugin de plataforma.
- `data` implementa los contratos de `domain` y es la única capa que toca plugins, sockets y APIs nativas.
- `presentation` solo consume casos de uso y entidades a través de providers. Ningún widget llama a un datasource ni a un repositorio directamente.
- Las features no se importan entre sí por su capa `data` ni `presentation`. Si dos features comparten algo, súbelo a `core/`.

## Estructura de carpetas

```
lib/
├── main.dart
├── bootstrap.dart                  # ProviderScope, logger, orientación, errores globales
├── app/
│   ├── app.dart                    # MaterialApp.router + TranslationProvider
│   ├── router/
│   │   ├── app_router.dart         # @AutoRouterConfig
│   │   └── guards/                 # PermissionsGuard
│   └── theme/                      # AppTheme.light / AppTheme.dark desde los tokens de Portadora
├── core/
│   ├── design/                     # sistema de diseño Portadora
│   │   ├── tokens/                 # FrColors, FrType, FrSpace, FrRadii, FrMotion (fr_theme.dart: context.fr)
│   │   ├── motion/                 # context.reduceMotion, FrLoop, FrSpringCurve, ruido y hash del prototipo
│   │   └── widgets/                # FrButton, FrIconButton, FrField, FrSteps, SignalSignature, WaveLoader
│   ├── error/                      # Failure (sealed, freezed)
│   ├── result/                     # Result<T> (sealed, freezed)
│   ├── usecase/                    # contrato base UseCase<T, Params>
│   ├── logging/
│   ├── constants/                  # puertos, tipo de servicio mDNS, límites, timeouts
│   └── utils/
├── i18n/
│   ├── strings.i18n.json           # español (base)
│   └── strings_en.i18n.json
└── features/
    ├── permissions/                # onboarding y solicitud de permisos
    ├── lobby/                      # crear frecu, descubrir, escanear QR, unirse
    ├── room/                       # frecu activa: señalización, WebRTC, PTT, participantes
    └── settings/                   # nombre visible, modo de habla por defecto, idioma
```

Cada feature sigue esta forma:

```
features/<feature>/
├── domain/
│   ├── entities/
│   ├── repositories/               # contratos abstractos
│   └── usecases/
├── data/
│   ├── datasources/
│   ├── models/                     # DTOs con toEntity()/fromEntity()
│   └── repositories/               # implementaciones
└── presentation/
    ├── providers/                  # @riverpod: DI + notifiers de estado
    ├── pages/                      # @RoutePage()
    └── widgets/
```

## Entidades y contratos principales (orientativos)

Dominio de `room`:
- `Room`: id, nombre, hostAddress, port, accessCode, maxParticipants, createdAt.
- `Participant`: id, displayName, isHost, isSpeaking, isMuted, connectionState.
- `TalkMode`: unión `pushToTalk` | `openMic`.
- `RoomStatus`: unión `idle` | `connecting` | `connected` | `reconnecting` | `closed(reason)`.
- `RoomInvite`: host, port, roomId, accessCode (lo que viaja en QR y mDNS).

Contratos:
- `RoomRepository`: `createRoom`, `joinRoom`, `leaveRoom`, `watchParticipants`, `watchStatus`.
- `VoiceRepository`: `startTalking`, `stopTalking`, `setTalkMode`, `setSpeakerOn`, `watchAudioRoute`.
- `DiscoveryRepository` (feature `lobby`): `watchNearbyRooms`, `publishRoom`, `stopPublishing`.

Casos de uso esperados: `CreateRoom`, `JoinRoom`, `LeaveRoom`, `StartTalking`, `StopTalking`, `ChangeTalkMode`, `DiscoverRooms`, `ParseInviteFromQr`, `BuildInviteQr`.

Datasources esperados en `features/room/data`:
- `SignalingServerDataSource`: servidor WebSocket en el anfitrión.
- `SignalingClientDataSource`: conexión WebSocket de cada participante, incluido el anfitrión hacia sí mismo vía loopback para unificar la lógica.
- `PeerConnectionDataSource`: gestiona un `RTCPeerConnection` por cada otro participante.
- `AudioSessionDataSource`: configuración de `audio_session` y ruteo.

## Manejo de errores

- Los repositorios devuelven `Result<T>` (`success` | `failure`). Nunca lanzan excepciones hacia `domain` o `presentation`.
- `Failure` es una unión sellada: `network`, `permissionDenied`, `roomFull`, `invalidAccessCode`, `hostUnreachable`, `audio`, `unexpected`.
- Los datasources capturan excepciones y las traducen a `Failure` en el repositorio.
