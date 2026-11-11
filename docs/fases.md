# Plan de implementación y definición de terminado — Frecu

## Plan de implementación por fases

Trabaja **una fase a la vez**. Al terminar cada una, reporta qué se hizo, qué quedó pendiente y cómo probarlo.

### Fase 0 — Base del proyecto
Estructura de carpetas, dependencias, lints, `build_runner`, slang (es/en), router, tema, `Result`, `Failure`, logger, `bootstrap.dart`.
Criterio: la app compila, navega entre pantallas vacías y `flutter analyze` queda limpio.

### Fase 1 — Prueba de concepto de audio (2 teléfonos)
Servidor WebSocket en el anfitrión, cliente con IP ingresada a mano, una conexión WebRTC de audio con micrófono abierto.
Criterio: dos teléfonos en el mismo hotspot se escuchan con latencia baja perceptible.

### Fase 2 — Descubrimiento y unión
mDNS (publicar y descubrir), QR de invitación, código de acceso, rechazo con motivo.
Criterio: un participante encuentra la frecu sin escribir la IP, o la une por QR.

### Fase 3 — Frecu multiparticipante
Mesh de hasta 6, lista de participantes, `peer_joined` / `peer_left`, límite de sala.
Criterio: 4 o más teléfonos hablan y se escuchan entre todos.

### Fase 4 — Modos de habla y audio
PTT, micrófono abierto, indicador de quién habla, ruteo altavoz / Bluetooth.
Criterio: PTT silencia y activa sin cortes; el audio cambia correctamente al conectar audífonos.

### Fase 5 — Segundo plano y resiliencia
Servicio en primer plano en Android, background audio en iOS, heartbeats, reconexión con backoff, cierre de frecu.
Criterio: la frecu sobrevive 10 minutos con pantalla apagada y se recupera tras una desconexión breve.

### Fase 6 — Experiencia de usuario
Onboarding de permisos, guía para activar el hotspot, ajustes, textos completos en es/en, estados vacíos y de error.
Criterio: un usuario nuevo puede crear o unirse a una frecu sin ayuda.

### Fase 7 — Sensores y hardware del teléfono
Señal débil por persona, vibración, mensajes rápidos y SOS, ubicación compartida voluntaria, PTT con el botón de volumen (Android), auricular al acercar, filtro de viento, unión por Bluetooth, invitación por NFC y enlaces `frecu://`. Detalle en `docs/audio.md`, `docs/protocolo.md` y `docs/plataforma.md`.
Criterio: cada función se apaga o no se ofrece donde la plataforma no la permite, y se comprobó en teléfonos reales: en el Samsung, volumen, proximidad, filtro de viento, anfitrión Bluetooth, enlaces y NFC de lectura; con otro teléfono, faltan el invitado Bluetooth, leer un Android que hace de etiqueta y grabar una etiqueta.

---

## Pruebas requeridas

- **Unitarias** para todos los casos de uso, con repositorios simulados vía `mocktail`.
- **Serialización** de cada mensaje del protocolo (ida y vuelta JSON).
- **Lógica del servidor de señalización** probada con un transporte falso en memoria, sin sockets reales.
- **Notifiers** de presentación probados con `ProviderContainer` y overrides.

Matriz de pruebas manuales:
- 2 Android (uno anfitrión).
- Android anfitrión + iPhone participante.
- 4 a 6 dispositivos simultáneos.
- Pantalla apagada y app en segundo plano durante 10 minutos.
- Conexión y desconexión de audífonos Bluetooth.
- Participante que sale del rango y vuelve.
- Red de la frecu (Android anfitrión): crearla, invitar con un solo QR a un Android y a un iPhone (aviso del sistema y unión), con el invitado con datos móviles encendidos; salir de la frecu (el invitado vuelve a su Wi-Fi y la red se apaga); encender la zona Wi-Fi con la frecu abierta (aviso y crear la red de nuevo); Android 12 o anterior (permiso de ubicación).

---

## Definición de terminado

Una tarea se considera terminada solo si:
- Respeta las reglas de dependencia de arquitectura (`domain` puro).
- No tiene textos visibles sin pasar por slang.
- Tiene pruebas para la lógica nueva de `domain` y `data`.
- `dart run build_runner build -d`, `flutter analyze` y `flutter test` pasan sin errores.
- No agrega dependencias de internet fuera del modo internet (`CloudConfig`, `CloudRelayDataSource`, `TurnCredentialsDataSource`).

## Qué no hacer

- No uses multicast ni broadcast UDP para transportar audio; muchos hotspots lo bloquean.
- No asumas que hay internet en el flujo local; solo el modo internet lo usa.
- No agregues video ni tracks innecesarios.
- No metas plugins de plataforma en `domain`.
- No implementes funcionalidades fuera de alcance del MVP sin aprobación explícita.
