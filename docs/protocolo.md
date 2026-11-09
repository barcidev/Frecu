# Protocolo de red — Frecu

## Flujo general

1. El anfitrión activa su hotspot (manualmente en el MVP) y crea la frecu.
2. La app del anfitrión levanta un servidor WebSocket en `0.0.0.0:47800` (constante en `core/constants`).
3. Publica el servicio mDNS `_frecu._tcp` con atributos TXT: `roomId`, `name`, `v` (versión de protocolo) y, si la frecu tiene nota, `n`. Retira el anuncio cuando la frecu termina (ver «Anuncio y búsqueda mDNS»).
4. Muestra un QR con la invitación: `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>&n=<semitono>&name=<nombre>` (`n` solo si la frecu tiene nota; `name`, el nombre de la frecu, es opcional).
5. Cada participante descubre la frecu por mDNS o escanea el QR, se conecta al WebSocket y envía `join` con el código de acceso.
6. La señalización WebRTC (offer, answer, ice) viaja por el WebSocket; el audio viaja directo entre teléfonos.

La IP del anfitrión no es fija (en Android suele ser `192.168.43.1`, pero varía por fabricante y versión). Obtenla siempre de las interfaces de red, nunca la escribas a mano. Solo cuentan las interfaces Wi-Fi o de punto de acceso (`wlan0`, `en0`, `ap0`, `swlan0`, `softap0`, `bridge100`…), nunca las de datos móviles, VPN o túneles (`pdp_ip*`, `rmnet*`, `ccmni*`, `utun*`, `ipsec*`, `tun*`, `ppp*`, `awdl*`, `llw*`); entre varias, se prefiere un rango privado. La regla vive en `selectLanAddress` (`lib/core/network/lan_address.dart`): sin ninguna interfaz así, el teléfono no está en ninguna red local.

## Anuncio y búsqueda mDNS

- El anfitrión anuncia la frecu al abrirla y retira el anuncio cuando la frecu termina, por cualquier motivo; si la creación falla, tampoco queda anuncio. Anunciar y retirar van en fila: un retiro pedido mientras se anuncia espera al anuncio y lo retira.
- Quien busca identifica cada servicio por su nombre mDNS. Un `lost` quita la frecu de ese nombre aunque el evento no traiga anfitrión ni puerto. Un `found` con el nombre de una frecu ya listada la sustituye con su TXT nuevo: es otra frecu con el mismo nombre (se cerró y se abrió otra).
- La dirección de una frecu cercana es la IPv4 resuelta del servicio (`addresses`; la búsqueda pide IPv4). El nombre del anfitrión (`MacBook-Pro-de-Ana.local`, sin el punto final) solo se usa si no llega ninguna IPv4. Esa dirección es la que muestran la lista y la hoja de código y la que se usa para unirse.
- Si ni el TXT ni el servicio traen nombre, la frecu se muestra como «Frecu sin nombre» en el idioma de la app.
- Mientras hay una frecu activa, la búsqueda se detiene; al terminar, se busca desde cero, así que las frecus que siguen anunciadas vuelven con su TXT al día.
- Si la búsqueda no puede empezar, el inicio lo dice («La búsqueda falló · reintentando») y la reintenta cada 5 s.

## Nota de la frecu (`n`)

Cada frecu puede llevar su nota musical (`RoomNote`) como dato aditivo `n`: el semitono desde Do4 en texto decimal, de `"0"` (Do4) a `"23"` (Si5). Viaja igual en el TXT de mDNS (clave `n`) y en el QR (parámetro `n`, tras el código y antes del nombre opcional `name`).

- La nueva frecu la calcula con su hora local y las notas de las frecus cercanas que ya descubrió (`AssignRoomNote`), la muestra y, al tocar Abrir, la frecu se abre con esa misma nota sin recalcularla. El anfitrión la publica en el TXT y en el QR y su servidor la manda en `welcome`.
- Quien descubre la frecu o escanea el QR toma esa nota tal cual y nunca la recalcula. Quien se conecta o se une por IP manual recibe la nota en el mensaje `welcome` (`note`) del protocolo de señalización WebSocket; si llegan las dos, manda la de `welcome`.
- `n` es opcional: si falta, está vacío, no es un entero o está fuera de 0–23, la frecu o la invitación se leen sin nota y la unión funciona igual.
- Es aditivo, así que la versión del protocolo no cambia (`v=1`): una app anterior ignora `n` y una app nueva lee las invitaciones sin `n` como frecus sin nota.

## Nombre de la frecu en el QR (`name`)

La invitación puede llevar el nombre de la frecu como dato aditivo `name`, tras `n`: el texto tal cual, codificado en la URI (`&name=Ruta+del+domingo`). Quien escanea lo ve en la tarjeta «Frecu encontrada», con la nota y la IP debajo.

- `name` es opcional: si falta o está vacío (o solo tiene espacios), la invitación se lee sin nombre y la tarjeta muestra la nota y sus Hz, como antes.
- Es aditivo, así que la versión del protocolo no cambia (`v=1`): una app anterior ignora `name` y una app nueva lee las invitaciones sin `name`.
- Lo construye `BuildInviteQr` desde `RoomInvite.name` y lo lee `ParseInviteFromQr`; el orden de los parámetros no importa al leer.

## Mensajes de señalización

JSON con discriminador `type`, modelados como una unión `freezed` con `@Freezed(unionKey: 'type')`.

| type | Dirección | Contenido |
|---|---|---|
| `join` | cliente → host | displayName, accessCode, protocolVersion |
| `welcome` | host → cliente | peerId asignado, lista de participantes, nota opcional (`note`), nombre de la frecu opcional (`roomName`) |
| `rejected` | host → cliente | reason (`roomFull`, `invalidAccessCode`, `versionMismatch`) |
| `peer_joined` | host → todos | participante |
| `peer_left` | host → todos | peerId |
| `offer` | peer → peer (vía host) | from, to, sdp |
| `answer` | peer → peer (vía host) | from, to, sdp |
| `ice` | peer → peer (vía host) | from, to, candidate, sdpMid, sdpMLineIndex |
| `talk_state` | peer → todos (vía host) | peerId, isSpeaking, `muted` opcional |
| `ping` / `pong` | ambos | timestamp |
| `room_closed` | host → todos | reason |

El servidor del anfitrión solo enruta mensajes y mantiene la lista de participantes. No procesa audio.

### Nombre de la frecu (`roomName`)

El `welcome` lleva el nombre de la frecu en `roomName`, para que quien se une (también por IP) lo vea en la cabecera y en la notificación. Es aditivo, así que `v=1` no cambia: una app anterior lo ignora y, si falta (anfitrión anterior), la frecu queda sin nombre y la pantalla usa el título genérico.

### Silencio en micrófono abierto (`muted`)

Quien está en micrófono abierto y se silencia envía `talk_state` con `isSpeaking: false` y `muted: true`; al abrir el micrófono o pasar a PTT lo envía sin `muted`. Quien recibe marca a esa persona como «Silenciado» mientras el último `talk_state` traiga `muted: true`. Es aditivo (`v=1`): sin `muted` se lee como no silenciado. Cada uno reenvía su estado cuando entra alguien (`peer_joined`), para que quien llega lo sepa.

### Control de acceso del anfitrión

- Mientras un socket no hizo un `join` aceptado, el servidor ignora todo lo demás que mande; un segundo `join` del mismo socket también se ignora.
- El remitente lo pone el servidor: `from` de `offer`, `answer` e `ice`, y `peerId` de `talk_state`, son siempre el id asignado a ese socket, diga lo que diga el mensaje. Solo se enruta a participantes que ya se unieron.
- Un `join` con otra `protocolVersion` se rechaza con `rejected(versionMismatch)`.
- Tras 5 códigos incorrectos desde la misma IP en un minuto, esa IP queda bloqueada hasta que pase el minuto: sus `join` se rechazan con `invalidAccessCode` aunque traigan el código correcto. Cada código incorrecto cierra el socket.
- El tope sigue en 6 participantes (`rejected(roomFull)`).
- Abrir una frecu con el servidor de otra aún en marcha lo reinicia: quienes estaban reciben `room_closed` y la nueva usa solo su código.

## WebRTC

- Topología **mesh**: cada participante tiene un `RTCPeerConnection` con cada uno de los demás.
- `iceServers: []`. **No agregues STUN ni TURN**: la app debe funcionar sin internet usando solo candidatos locales.
- Solo audio. Restricciones: `echoCancellation`, `noiseSuppression` y `autoGainControl` en `true`.
- Para evitar *glare*, **el participante que llega crea las offers** hacia los que ya estaban (los que trae su `welcome`).
- La voz escucha la señalización desde que se crea y entra a la malla con el id del `welcome` en cuanto se crea o se une a la frecu, sin esperar a la pantalla. Una offer que llega antes de conocer el id local se atiende al conocerlo; los mensajes de cada par se procesan en orden y los candidatos ICE que llegan antes que la descripción remota se aplican después de ella.
- Un solo `getUserMedia` por frecu. Sin micrófono (permiso negado) la malla se arma igual para escuchar, con un transceptor de solo recepción.
- Salir, cerrar o perder la frecu cierra todos los enlaces y para el micrófono; nunca se reutiliza un enlace de otra frecu.
- El estado ICE de cada enlace (`onIceConnectionState`) llega a la malla como el estado del participante: conectando, conectado, reconectando o desconectado.
- PTT se implementa activando y desactivando `track.enabled` del track local de audio. **No** renegocies la conexión para silenciar.
- Límite de 6 participantes. El anfitrión rechaza el séptimo con `rejected(roomFull)`.

## Resiliencia

- Heartbeat `ping` cada 5 s; un participante sin respuesta durante 15 s se considera desconectado.
- Abrir el WebSocket espera como mucho 5 s. Sin respuesta, socket rechazado o handshake roto es `hostUnreachable`; la conexión solo se da por abierta cuando el WebSocket abrió.
- Reconexión del cliente con backoff exponencial (1, 2, 4, 8 s, tope 15 s), hasta 5 intentos. Hay un solo bucle de reconexión por frecu y solo tras una unión con `welcome`: una unión fallida no reconecta. `RoomStatus.reconnecting` lleva el intento y el tiempo al próximo, para la cuenta atrás.
- Al reconectar, el participante vuelve a enviar `join`, recibe otro id y se recrean sus peer connections (vuelve a ofrecer, como quien llega). Mientras reconecta no transmite; el micrófono abierto se retoma al volver.
- Si se agotan los intentos, la frecu pasa a `RoomStatus.closed('host_unreachable')` una sola vez. Si el anfitrión cierra la frecu, todos pasan a `RoomStatus.closed`.
