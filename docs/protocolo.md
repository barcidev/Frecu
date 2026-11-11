# Protocolo de red — Frecu

## Flujo general

1. El anfitrión prepara la red y crea la frecu. En Android, Frecu crea la red (ver «Red de la frecu»); si no, o en iPhone, el anfitrión activa su punto de acceso a mano y la app lo guía.
2. La app del anfitrión levanta un servidor WebSocket en `0.0.0.0:47800` (constante en `core/constants`).
3. Publica el servicio mDNS `_frecu._tcp` con atributos TXT: `roomId`, `name`, `v` (versión de protocolo) y, si la frecu tiene nota, `n`. Retira el anuncio cuando la frecu termina (ver «Anuncio y búsqueda mDNS»).
4. Muestra un QR con la invitación: `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>&n=<semitono>&name=<nombre>&ws=<red>&wk=<clave>` (`n` solo si la frecu tiene nota; `name`, el nombre de la frecu, es opcional; `ws` y `wk`, solo con la red de Frecu).
5. Cada participante descubre la frecu por mDNS o escanea el QR (si el QR trae la red y el anfitrión no responde, la app conecta antes el teléfono a esa red), se conecta al WebSocket y envía `join` con el código de acceso.
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

## Red de la frecu (`ws` y `wk`)

En Android (8 o posterior), el anfitrión no activa la zona Wi-Fi a mano: Frecu crea una red local sin internet con `LocalOnlyHotspot` (canal `frecu/hotspot`). Android le pone un nombre y una clave nuevos cada vez y Frecu los suma a la invitación como datos aditivos, tras `name`: `ws` con el nombre de la red y `wk` con su clave, tal cual y codificados en la URI.

- La red se crea al tocar «Crear la red» y se apaga al cerrar la frecu o al salir de la creación sin abrirla. Si Android la apaga por su cuenta (se encendió la zona Wi-Fi, modo avión), el anfitrión ve un aviso y, al crearla de nuevo, la invitación lleva la red nueva y, si cambió, la IPv4 nueva.
- La IPv4 de la invitación es la de la interfaz de esa red, aunque el teléfono siga en otra Wi-Fi (`selectLanAddress(prefer:)`).
- `ws` es opcional: sin él no hay red y el QR se lee como antes. Sin `wk` (o vacío), la red es abierta. `wk` sin `ws` no cuenta. Es aditivo, así que la versión del protocolo no cambia (`v=1`).
- Lo construye `BuildInviteQr` desde `RoomInvite.wifi` y lo lee `ParseInviteFromQr`. La frecu activa guarda la red en `Room.wifi`, también la de quien se unió con ese QR, para invitar a otros.
- Al tocar Unirme con un QR que trae la red, si el anfitrión no responde, la app conecta el teléfono a esa red (canal `frecu/wifi`): en Android con `WifiNetworkSpecifier` (Android 10 o posterior) y en iOS con `NEHotspotConfiguration` (`joinOnce` falso, para seguir en la red con la pantalla apagada). El sistema pide confirmar. Si se cancela, la red no aparece o el teléfono no se conecta solo (Android 7 a 9), la hoja muestra la red y la clave para conectarse a mano. Al salir de la frecu, el teléfono olvida la red que conectó la app.
- En Android, una Wi-Fi sin internet no es la red por defecto si hay datos móviles: antes de unirse (por cualquier vía), la app se ata a la Wi-Fi en la que está el anfitrión (`bindProcessToNetwork`) y se desata al salir.

## Invitación por Bluetooth (BLE)

Quien está cerca pero aún no en la red del anfitrión encuentra la frecu por Bluetooth y entra a su red con el código, sin buscarla ni escribir la clave. BLE solo sirve para encontrar y unirse; la voz y los mensajes siguen por la red (el alcance de BLE, ~30 m, es menor que el del Wi-Fi). Paquete `bluetooth_low_energy` (central y periférico); código en `lib/features/bluetooth_invite/`.

- **Anfitrión (periférico):** anuncia el servicio `51b1b2c2-069a-488c-94c8-c469ede80001`, solo el UUID (sin nombre: no cambia el del teléfono). Lo hace mientras la frecu está activa, si este teléfono la creó y conoce su red: la que creó Frecu (`LocalOnlyHotspot`) o su zona Wi-Fi guardada en la guía («Guardarla para invitar por Bluetooth», solo Android, solo en el teléfono y solo si al abrir la frecu tiene la zona Wi-Fi encendida). Sin red que entregar no anuncia.
- **Característica `…0002` (lectura):** la frecu en JSON, sin nada secreto: `{"v":1,"r":roomId,"name":…,"n":semitono}`. Otra `v` no se lista.
- **Característica `…0003` (escritura y lectura):** el invitado escribe el código de acceso (UTF-8). Si es el de la frecu, el anfitrión acepta la escritura y desde entonces deja leer a ese invitado la invitación completa: la misma URI del QR (`frecu://join?…` con `ws` y `wk`). Con un código equivocado responde `insufficientAuthorization`; leer sin código, `readNotPermitted`. Tras 5 códigos equivocados en 30 s rechaza todos durante 30 s (`BluetoothUnlockGate`). Las lecturas largas siguen el `offset`; Android pide un MTU de 512.
- **Invitado (central):** en el inicio busca solo ese servicio, se conecta a cada anfitrión nuevo una vez para leer `…0002` (de a una conexión) y lo lista en «Cercanas» con «Por Bluetooth» (`NearbyRoom.bluetoothId`, sin IP). Si la misma frecu aparece también por mDNS, va una sola vez, la de la red. Una frecu que no se ve en 15 s sale de la lista. Con una frecu activa la búsqueda queda en pausa.
- **Unión:** la hoja del código escribe el código por BLE; si el anfitrión lo rechaza, código incorrecto; si no se puede hablar con él, «El anfitrión no responde por Bluetooth». Con la invitación, si el anfitrión ya responde se entra directo; si no, la hoja de la Wi-Fi conecta el teléfono a la red (como con el QR) y se entra con esa invitación.
- **Comprobado** en el Samsung como anfitrión con un Mac como invitado (CoreBluetooth): encuentra la frecu, lee sus datos, la invitación sin código y con un código equivocado se rechazan, con el código correcto llega la URI completa, y al cerrar la frecu el anuncio se detiene. Falta probar el invitado en teléfonos reales (un iPhone y otro Android).
- **Permisos:** Android 12+ pide «Dispositivos cercanos» (`BLUETOOTH_SCAN` con `neverForLocation`, `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`). El inicio no muestra el aviso: busca solo si el permiso ya se dio en la bienvenida. El anfitrión lo pide al anunciar. En iOS lo pide CoreBluetooth la primera vez que se busca.

## Invitación por NFC y enlaces `frecu://`

La invitación por NFC y por enlace es la misma URI del QR (`frecu://join?…`, con la red y su clave si las hay); se abre como un QR leído: la tarjeta «Frecu encontrada» del escáner, sin encender la cámara (`ScanQrPage(invite:)`), y Unirme sigue igual. Código en `lib/features/nfc_invite/`.

- **Enlaces:** `frecu://join?…` abre Frecu desde otra app o la cámara del sistema (Android: `intent-filter` `VIEW` con `scheme="frecu" host="join"`; iOS: `CFBundleURLTypes`). Los lee `app_links` (por eso `flutter_deeplinking_enabled`/`FlutterDeepLinkingEnabled` van apagados) y el inicio abre su tarjeta, también el enlace que abrió la app; con una frecu activa se ignora. Otros enlaces no hacen nada.
- **Leer (Por NFC):** con NFC, el dock del inicio lleva «Por IP» y «Por NFC» (sin NFC, «Conectar por IP» como antes). La hoja «Unirse por NFC» espera una etiqueta o el teléfono del anfitrión (`nfc_manager`, ISO 14443 y 15693), toma el primer registro URI `frecu:` del mensaje NDEF, lo muestra encontrado 700 ms y abre su tarjeta. Si no trae una invitación lo dice con Reintentar; cerrar (o cancelar el aviso de iPhone) corta la lectura.
- **En Android, sin abrir la hoja:** el `intent-filter` `NDEF_DISCOVERED` con el mismo esquema hace que acercar una etiqueta o el teléfono del anfitrión abra Frecu con el enlace.
- **El teléfono como etiqueta (Android, HCE):** mientras se está en una frecu (anfitrión o invitado, como el QR), `FrecuNfcHostService` emula una etiqueta NDEF tipo 4 de solo lectura (aplicación `D2760000850101`, archivos `E103` y `E104`) con un registro URI de la invitación; al salir deja de responder. Funciona con la pantalla encendida. El iPhone no puede hacer de etiqueta: en él solo se graban etiquetas.
- **Grabar etiqueta:** la hoja de invitar lleva «También por NFC» con «Grabar etiqueta»: espera una etiqueta NDEF y graba un registro URI con la invitación (sin prefijo abreviado). Si es de solo lectura o no cabe, lo dice con Reintentar. La etiqueta sirve mientras la frecu siga abierta (el código y la red cambian con cada frecu).
- **Comprobado en el Samsung:** un enlace `frecu://join` abre la tarjeta sin cámara («Escanear otro QR» la enciende); «Por NFC» y «Grabar etiqueta» activan y sueltan el modo lectura; Android registra `FrecuNfcHostService` como servicio por defecto de `D2760000850101`. Falta probar con otro teléfono y con una etiqueta: leer un Android que hace de etiqueta, en Android y en iPhone, y grabar una etiqueta.
- **Fallos:** `Failure.nfc(NfcFailureReason)`: `notInvite`, `readOnly`, `tooSmall`, `cancelled`, `failed`.

## Mensajes de señalización

JSON con discriminador `type`, modelados como una unión `freezed` con `@Freezed(unionKey: 'type')`.

| type | Dirección | Contenido |
|---|---|---|
| `join` | cliente → host | displayName, accessCode, protocolVersion, `peerId` (opcional: volver a su lugar tras un traspaso), `term` (opcional: el turno de la sucesión que conoce) |
| `welcome` | host → cliente | peerId asignado, lista de participantes, nota opcional (`note`), nombre de la frecu opcional (`roomName`) |
| `rejected` | host → cliente | reason (`roomFull`, `invalidAccessCode`, `versionMismatch`, `stale_term`) |
| `peer_joined` | host → todos | participante |
| `peer_left` | host → todos | peerId |
| `offer` | peer → peer (vía host) | from, to, sdp |
| `answer` | peer → peer (vía host) | from, to, sdp |
| `ice` | peer → peer (vía host) | from, to, candidate, sdpMid, sdpMLineIndex |
| `talk_state` | peer → todos (vía host) | peerId, isSpeaking, `muted` opcional |
| `quick_message` | peer → todos menos quien lo envía (vía host) | peerId, kind |
| `position` | peer → todos menos quien lo envía (vía host) | peerId, lat y lon opcionales, accuracy opcional |
| `ping` / `pong` | ambos | timestamp |
| `room_state` | host → todos | `state`: sucesión, turno y estado de la frecu |
| `host_handover` | host → todos | `to`, `term`, `address` y `port` opcionales: el anfitrión pasa (o cede) la frecu y sale |
| `host_probe` | host → otro host, y su respuesta | `accessCode`, `term`, `host`, `port`: ¿llevas esta frecu y con qué turno? |
| `host_changed` | nuevo host → quien vuelve | `host`, `term`, `reason` (`left` o `lost`) |
| `room_closed` | host → todos | reason |

El servidor del anfitrión solo enruta mensajes y mantiene la lista de participantes. No procesa audio.

### Nombre de la frecu (`roomName`)

El `welcome` lleva el nombre de la frecu en `roomName`, para que quien se une (también por IP) lo vea en la cabecera y en la notificación. Es aditivo, así que `v=1` no cambia: una app anterior lo ignora y, si falta (anfitrión anterior), la frecu queda sin nombre y la pantalla usa el título genérico.

### Sucesión y estado de la frecu (`room_state`)

Tras cada `join` aceptado (después de `welcome` y `peer_joined`) y cada salida, el anfitrión envía a todos `room_state` con `state`: el turno vigente (`term`, 1 al abrir la frecu), si admite traspaso (`handover`: por internet o en una Wi-Fi que no crea su teléfono), el nombre (`name`), el código (`accessCode`), la nota (`note`), el tipo (`reach`: `local` o `internet`) y quienes están (`members`) en orden de sucesión, que es el de llegada con el anfitrión primero. Cada miembro lleva `id`, `displayName`, su hora de llegada (`joinedAt`) y, si entró por la red local, su IPv4 (`address`; la del anfitrión es la de su invitación). Por internet también lleva `internetId` y el secreto de anfitrión (`hostSecret`). Cada teléfono guarda el último (`RoomRepositoryImpl.succession`) y lo olvida al salir o al cerrarse la frecu. Es aditivo (`v=1`): `welcome` no cambia y una app anterior descarta el tipo desconocido, así que sigue sin traspaso.

### Traspaso voluntario (`host_handover`, `host_changed`)

En una frecu local con traspaso (una Wi-Fi que no crea el teléfono del anfitrión), el anfitrión que sale con «Que siga sin mí» envía a todos `host_handover` con `to` (quien la recibe) y `term` (el turno siguiente), luego `peer_left` de sí mismo, y cierra su servidor sin `room_closed`. Quien la recibe abre su servidor en el mismo puerto con el estado de `room_state` y ese turno, y guarda un lugar a cada persona heredada (mismo id, orden y hora de llegada) hasta que se le acaba el latido. Se une a sí mismo con `join.peerId` = su id y queda como anfitrión. Los demás, en lugar de reintentar la IP vieja, se conectan a la `address` de quien la recibe (de `room_state`) con el código heredado y `join.peerId` = su id: ocupan su lugar sin `peer_joined` (ya estaban en las listas) y reciben `host_changed` con `host`, `term` y `reason: left`. Es aditivo: una app anterior descarta los tipos nuevos y su `join` sin `peerId` entra con un id nuevo.

Si el anfitrión de una frecu local con traspaso deja de responder (sin `host_handover`), cada invitado sigue el mismo plan con la sucesión de `room_state`: reintenta al anfitrión dos veces (esperas de 1 s y 2 s) y, si no vuelve, recorre la sucesión en orden sin él. A cada persona le da dos intentos en su `address` con `join.peerId` = su id y `join.term` = el turno conocido (esperas de 1 s). Cuando le toca a sí mismo, si su red sigue arriba toma la frecu sin esperar, como en el traspaso voluntario, con `term + 1`, y su servidor responde `host_changed` con `reason: lost`; si su red no está arriba, pasa a la siguiente persona. Si nadie responde, la frecu se cierra con `host_unreachable`.

### Dos anfitriones a la vez (`host_probe`)

Si el anfitrión anterior vuelve con su frecu aún abierta (estuvo fuera de alcance) o una partición deja dos anfitriones de la misma frecu, se encuentran solos. Cada teléfono recuerda la `address` de todas las personas que vio en `room_state` durante la sesión, y mientras lleva una frecu local con traspaso, cada 3 s abre un socket en el puerto de la frecu de las IPs de quienes ya no están (sin la suya ni las de quienes siguen en la frecu) y envía `host_probe` con el código, su turno (`term`), su id (`host`) y el puerto de su servidor (`port`). Un servidor que lleva esa frecu responde con su propio `host_probe` y cierra el socket. Gana el turno mayor y, a igual turno, el `peer_N` menor. Quien pierde (lo sepa por la respuesta o por la pregunta que recibió) envía a sus invitados `host_handover` con `to`, `term`, `address` y `port` del ganador, cierra su servidor sin `room_closed` y entra como invitado al ganador con su id en `join.peerId`; sus invitados van a esa `address` y `port` aunque el ganador no esté en su sucesión, y quien tenía un lugar heredado allí vuelve a él. Un `host_probe` con el código incorrecto se rechaza con `rejected(invalidAccessCode)` y cuenta para el bloqueo, como un `join`; esa IP (que lleva otra frecu) no se vuelve a preguntar. Es aditivo: una app anterior descarta `host_probe`.

### Silencio en micrófono abierto (`muted`)

Quien está en micrófono abierto y se silencia envía `talk_state` con `isSpeaking: false` y `muted: true`; al abrir el micrófono o pasar a PTT lo envía sin `muted`. Quien recibe marca a esa persona como «Silenciado» mientras el último `talk_state` traiga `muted: true`. Es aditivo (`v=1`): sin `muted` se lee como no silenciado. Cada uno reenvía su estado cuando entra alguien (`peer_joined`), para que quien llega lo sepa.

En micrófono abierto, `isSpeaking` no es tener el micrófono abierto, sino que se oiga la voz: se envía `true` cuando el nivel propio supera el umbral y `false` cuando pasa la retención sin superarlo (ver `docs/audio.md`). Abrir el micrófono envía `isSpeaking: false` sin `muted`.

### Mensajes rápidos y SOS (`quick_message`)

Mensajes predefinidos para toda la frecu: `kind` es `behind` («Me quedé atrás»), `stop` («Parada en la próxima»), `fuel` («Necesito combustible»), `ok` («Todo bien»), `onMyWay` («Voy en camino», la respuesta a un SOS) o `sos`. No hay texto libre.

- El anfitrión lo reenvía a todos menos a quien lo envía, con `peerId` forzado al id de su socket, igual que `talk_state`.
- Quien lo recibe ignora un `kind` que no conoce, así que sumar tipos no cambia la versión (`v=1`). Una app anterior descarta el mensaje entero.
- Un SOS tapa la frecu con una alarma hasta que se atiende y vuelve a vibrar cada 5 s. «Voy en camino» lo atiende y envía `onMyWay` a todos.

### Ubicación compartida (`position`)

Solo la envía quien activó «Compartir mi ubicación» (apagado por defecto): `lat` y `lon` en grados, como mucho cada 5 s salvo que se haya movido 20 m. Sin `lat` ni `lon` avisa que dejó de compartirla.

- El anfitrión la reenvía como `quick_message`: a todos menos a quien la envía y con `peerId` forzado.
- Quien la recibe muestra la distancia y el rumbo (N, NE…) bajo el nombre, si también comparte la suya. Al salir alguien (`peer_left`) o al cambiar de frecu se olvidan sus posiciones.
- «Se quedó atrás»: con 3 o más personas compartiendo, quien tiene a la más cercana a más de 200 m durante 20 s. Es un primer umbral, que se ajustará en ruta.
- Es aditivo (`v=1`).

### Control de acceso del anfitrión

- Mientras un socket no hizo un `join` aceptado, el servidor ignora todo lo demás que mande; un segundo `join` del mismo socket también se ignora.
- El remitente lo pone el servidor: `from` de `offer`, `answer` e `ice`, y `peerId` de `talk_state`, son siempre el id asignado a ese socket, diga lo que diga el mensaje. Solo se enruta a participantes que ya se unieron.
- Un `join` con otra `protocolVersion` se rechaza con `rejected(versionMismatch)`.
- Un `join` con un `term` mayor que el turno del servidor se rechaza con `rejected(stale_term)`: otra persona ya tomó la frecu. Sin `term` (app anterior) entra como hoy.
- Tras 5 códigos incorrectos desde la misma IP en un minuto, esa IP queda bloqueada hasta que pase el minuto: sus `join` se rechazan con `invalidAccessCode` aunque traigan el código correcto. Cada código incorrecto cierra el socket.
- El tope sigue en 6 participantes (`rejected(roomFull)`).
- Abrir una frecu con el servidor de otra aún en marcha lo reinicia: quienes estaban reciben `room_closed` y la nueva usa solo su código.

## WebRTC

- Topología **mesh**: cada participante tiene un `RTCPeerConnection` con cada uno de los demás.
- `iceServers: []` en la red local: **no agregues STUN ni TURN** ahí; debe funcionar sin internet con solo candidatos locales. Solo una frecu por internet usa STUN y TURN (ver «Modo internet»).
- Solo audio. Restricciones: `echoCancellation`, `noiseSuppression` y `autoGainControl` en `true`.
- Para evitar *glare*, **el participante que llega crea las offers** hacia los que ya estaban (los que trae su `welcome`).
- La voz escucha la señalización desde que se crea y entra a la malla con el id del `welcome` en cuanto se crea o se une a la frecu, sin esperar a la pantalla. Una offer que llega antes de conocer el id local se atiende al conocerlo; los mensajes de cada par se procesan en orden y los candidatos ICE que llegan antes que la descripción remota se aplican después de ella.
- Un solo `getUserMedia` por frecu. Sin micrófono (permiso negado) la malla se arma igual para escuchar, con un transceptor de solo recepción.
- Salir, cerrar o perder la frecu cierra todos los enlaces y para el micrófono; nunca se reutiliza un enlace de otra frecu.
- El estado ICE de cada enlace (`onIceConnectionState`) llega a la malla como el estado del participante: conectando, conectado, reconectando o desconectado.
- Un enlace que no conecta en 15 s (sin ruta de voz, p. ej. ICE sin pares) queda como desconectado: la frecu no se queda «Conectando» con el PTT bloqueado. Si conecta después, vuelve a conectado.
- **Punto de acceso en Android:** WebRTC solo junta candidatos en las redes que conoce ConnectivityManager con internet, y la interfaz de la zona Wi-Fi propia (`swlan0`, `ap0`, `wlan1`…) no lo es. `HotspotNetworkDetector` (Kotlin, instalado en `MainActivity` antes de la primera conexión) suma esa interfaz al detector de WebRTC con el identificador de su red de Android, o con 0 si no tiene (WebRTC no ata sus sockets). Sin él, el teléfono que comparte su zona Wi-Fi no tiene ruta de voz con nadie, aunque la señalización (y «hablando») sí llegue. Se compila contra la misma versión de WebRTC que trae flutter_webrtc (`compileOnly`). En iOS, con el iPhone como punto de acceso (`bridge100`), falta verificarlo.
- PTT se implementa activando y desactivando `track.enabled` del track local de audio. **No** renegocies la conexión para silenciar.
- Límite de 6 participantes. El anfitrión rechaza el séptimo con `rejected(roomFull)`.

## Resiliencia

- Heartbeat `ping` cada 5 s; un participante sin respuesta durante 15 s se considera desconectado.
- Abrir el WebSocket espera como mucho 5 s. Sin respuesta, socket rechazado o handshake roto es `hostUnreachable`; la conexión solo se da por abierta cuando el WebSocket abrió.
- Reconexión del cliente con backoff exponencial (1, 2, 4, 8 s, tope 15 s), hasta 5 intentos. Hay un solo bucle de reconexión por frecu y solo tras una unión con `welcome`: una unión fallida no reconecta. `RoomStatus.reconnecting` lleva el intento y el tiempo al próximo, para la cuenta atrás.
- Al reconectar, el participante vuelve a enviar `join`, recibe otro id y se recrean sus peer connections (vuelve a ofrecer, como quien llega). Mientras reconecta no transmite; el micrófono abierto se retoma al volver. En una frecu con traspaso la voz sigue mientras reconecta: la malla entre invitados no se desarma, solo se cierra el enlace con el anfitrión que se fue (al llegar `room_state` o `welcome` con otro anfitrión), y quien vuelve a su mismo lugar (`join.peerId`) conserva sus enlaces y vuelve a enviar su `talk_state`.
- Si se agotan los intentos, la frecu pasa a `RoomStatus.closed('host_unreachable')` una sola vez. Si el anfitrión cierra la frecu, todos pasan a `RoomStatus.closed`.

## Modo internet

Una frecu puede abrirse también por internet, sin servidor propio: un Worker de Cloudflare con un Durable Object por frecu (código en `cloud/`). Solo existe si la app se compila con `--dart-define=FRECU_CLOUD_URL=https://…` (`CloudConfig`); sin ella, todo sigue local.

- **El anfitrión sigue siendo la autoridad.** Levanta su servidor local como siempre (también acepta a los cercanos) y además abre un relé (`CloudRelayDataSource`) a `wss://<worker>/rooms/<id>/host?secret=<s>`. `<id>` son 128 bits en hexadecimal (`CloudConfig.newRoomId`) y `<s>` un secreto nuevo por frecu: el primero que llega reclama la sala.
- **Los invitados por internet** se conectan a `wss://<worker>/rooms/<id>/guest` y hablan el mismo protocolo JSON de este documento (`v=1`), con el mismo `SignalingClientDataSource`.
- **Sobres entre el Durable Object y el anfitrión:** `{"t":"open","c":<conexión>,"k":<resumen de la IP>}`, `{"t":"msg","c","d":<mensaje JSON en texto>}` y `{"t":"close","c"}`, en los dos sentidos salvo `open`. Cada invitado llega al servidor como una `SignalingConnection` más; `k` es la clave del bloqueo por códigos incorrectos. Los invitados nunca se hablan entre sí por el Durable Object.
- **Caídas:** el anfitrión se conecta con su turno (`/host?secret=<s>&term=<n>`, 1 al abrir la frecu). Si su relé se cae, el Durable Object no cierra a sus invitados durante una gracia de 10 s y les envía `{"t":"host_lost"}` (un sobre de la nube, fuera del protocolo: una app anterior lo descarta). El cliente suelta su socket al recibirlo y sigue el plan de caída. El anfitrión reconecta con espera creciente (hasta 15 s) con el mismo turno. Si nadie toma la frecu en la gracia, el Durable Object cierra a los invitados (`1001`). Un anfitrión sin `term` (app anterior) se trata como hasta ahora: al caer, se cierran sus invitados.
- **Traspaso por internet:** el enlace y el QR no cambian. Tomar la frecu es abrir el servidor propio en un puerto libre (nadie llega a él directamente) y el relé de anfitrión con el `internetId` y el `hostSecret` de `room_state` y el turno siguiente (`InternetHandover`). El Durable Object acepta un turno igual o mayor que el vigente, retira al anfitrión anterior (`4000`) y cierra a sus invitados (`1012`); a un turno menor responde `409`. En el traspaso voluntario, `host_handover` no necesita `address`: los demás vuelven al mismo socket de invitado con `join.peerId` = su id. En la caída, el plan es el de la red local, con todas las personas de la sucesión (sin IP): dos reintentos al anfitrión y dos pasos por persona, en los que seguirla es volver al mismo socket con su id y, si le toca a este teléfono y tiene red, tomarla con `term + 1` y `reason: lost`. Mientras nadie la toma, el socket de invitado responde `404`. El anfitrión anterior que vuelve con un turno menor recibe `409` y sigue reintentando su relé: todavía no entra como invitado.
- **ICE:** quien está en una frecu por internet pide `POST /rooms/<id>/turn` (`TurnCredentialsDataSource`), que responde `{"iceServers":[…]}` con STUN y TURN de Cloudflare (credenciales que vencen en 24 h). Si no responde en 5 s, queda `stun:stun.cloudflare.com:3478`. Los enlaces nuevos usan esos servidores (`PeerConnectionDataSource.iceServers`).
- **Invitación:** dato aditivo `x=<id>` (`v=1` no cambia). Con `x`, `h` y `p` son opcionales: sin red local, el QR lleva solo `r`, `c`, `x` y los opcionales. Si `r` falta, vale `x`. Un `x` mal formado se ignora. Al escanear, si el anfitrión responde en la red local se entra por ella; si no, por internet. El enlace para compartir es `https://<worker>/j/<id>#c=<código>`: la página abre `frecu://join?x=…&c=…`, y el código va en el fragmento, que no llega al Worker.
- **Red en Android:** al unirse por internet, la app suelta cualquier Wi-Fi a la que se haya atado (`release`), porque una red sin internet no llega a la nube.
- **Frecus mezcladas:** la voz entre un invitado local y uno por internet conecta si el local tiene salida a internet (Wi-Fi con internet o la zona Wi-Fi del iPhone). En la red de Frecu de Android (sin internet) no hay ruta: queda para una fase con reenvío por el anfitrión.
- **Quién entró por internet:** cada participante lleva `remote` (aditivo, `v=1`; sin él vale `false`), que pone el anfitrión según por dónde llegó. La frecu muestra «Por internet» bajo su nombre y, a quien está en la red de la frecu sin internet, «Sin audio» y un aviso para quienes no conectan.
- **Pendiente de esta fase:** registro y tope de 30 min gratis, y reinicio de ICE al cambiar entre Wi-Fi y datos (hoy la voz se rehace al reconectar la señalización). Un enlace abre la pantalla de escaneo con la frecu encontrada (no una hoja en el inicio, como dibuja el prototipo).

