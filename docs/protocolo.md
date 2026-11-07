# Protocolo de red — Frecu

## Flujo general

1. El anfitrión activa su hotspot (manualmente en el MVP) y crea la frecu.
2. La app del anfitrión levanta un servidor WebSocket en `0.0.0.0:47800` (constante en `core/constants`).
3. Publica el servicio mDNS `_frecu._tcp` con atributos TXT: `roomId`, `name`, `v` (versión de protocolo) y, si la frecu tiene nota, `n`.
4. Muestra un QR con la invitación: `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>&n=<semitono>` (`&n=…` solo si la frecu tiene nota).
5. Cada participante descubre la frecu por mDNS o escanea el QR, se conecta al WebSocket y envía `join` con el código de acceso.
6. La señalización WebRTC (offer, answer, ice) viaja por el WebSocket; el audio viaja directo entre teléfonos.

La IP del anfitrión no es fija (en Android suele ser `192.168.43.1`, pero varía por fabricante y versión). Obtenla siempre de las interfaces de red, nunca la escribas a mano.

## Nota de la frecu (`n`)

Cada frecu puede llevar su nota musical (`RoomNote`) como dato aditivo `n`: el semitono desde Do4 en texto decimal, de `"0"` (Do4) a `"23"` (Si5). Viaja igual en el TXT de mDNS (clave `n`) y en el QR (parámetro `n`, al final de la URI).

- El anfitrión la calcula una sola vez al abrir la frecu, con su hora local y las notas de las frecus cercanas que ya descubrió (`AssignRoomNote`), y la publica en el TXT y en el QR.
- Quien descubre la frecu o escanea el QR toma esa nota tal cual y nunca la recalcula. Quien se conecta o se une por IP manual recibe la nota en el mensaje `welcome` (`note`) del protocolo de señalización WebSocket.
- `n` es opcional: si falta, está vacío, no es un entero o está fuera de 0–23, la frecu o la invitación se leen sin nota y la unión funciona igual.
- Es aditivo, así que la versión del protocolo no cambia (`v=1`): una app anterior ignora `n` y una app nueva lee las invitaciones sin `n` como frecus sin nota.

## Mensajes de señalización

JSON con discriminador `type`, modelados como una unión `freezed` con `@Freezed(unionKey: 'type')`.

| type | Dirección | Contenido |
|---|---|---|
| `join` | cliente → host | displayName, accessCode, protocolVersion |
| `welcome` | host → cliente | peerId asignado, lista de participantes, nota opcional (`note`) |
| `rejected` | host → cliente | reason (`roomFull`, `invalidAccessCode`, `versionMismatch`) |
| `peer_joined` | host → todos | participante |
| `peer_left` | host → todos | peerId |
| `offer` | peer → peer (vía host) | from, to, sdp |
| `answer` | peer → peer (vía host) | from, to, sdp |
| `ice` | peer → peer (vía host) | from, to, candidate, sdpMid, sdpMLineIndex |
| `talk_state` | peer → todos (vía host) | peerId, isSpeaking |
| `ping` / `pong` | ambos | timestamp |
| `room_closed` | host → todos | reason |

El servidor del anfitrión solo enruta mensajes y mantiene la lista de participantes. No procesa audio.

## WebRTC

- Topología **mesh**: cada participante tiene un `RTCPeerConnection` con cada uno de los demás.
- `iceServers: []`. **No agregues STUN ni TURN**: la app debe funcionar sin internet usando solo candidatos locales.
- Solo audio. Restricciones: `echoCancellation`, `noiseSuppression` y `autoGainControl` en `true`.
- Para evitar *glare*, **el participante que llega crea las offers** hacia los que ya estaban.
- PTT se implementa activando y desactivando `track.enabled` del track local de audio. **No** renegocies la conexión para silenciar.
- Límite de 6 participantes. El anfitrión rechaza el séptimo con `rejected(roomFull)`.

## Resiliencia

- Heartbeat `ping` cada 5 s; un participante sin respuesta durante 15 s se considera desconectado.
- Reconexión del cliente con backoff exponencial (1, 2, 4, 8 s, tope 15 s) mientras la frecu siga anunciada.
- Al reconectar, el participante vuelve a enviar `join` y se recrean sus peer connections.
- Si el anfitrión cierra la frecu o se pierde, todos pasan a `RoomStatus.closed`.
