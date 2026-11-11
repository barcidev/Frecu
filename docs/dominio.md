# Glosario del dominio

- **Frecu** (`Room`): Sala de voz activa.
- **Anfitrión** (`Host`): Teléfono que crea la frecu y corre el servidor de señalización. También es participante.
- **Participante** (`Participant` / `Peer`): Cualquier teléfono dentro de la frecu, incluido el anfitrión.
- **PTT** (`pushToTalk`): Push-to-talk: el micrófono solo transmite mientras se mantiene presionado el botón.
- **Micrófono abierto** (`openMic`): El micrófono transmite de forma continua.
- **Código de acceso** (`accessCode`): PIN de 4 dígitos que protege la frecu de desconocidos en la misma red.
- **Invitación** (`RoomInvite`): Datos de conexión que viajan en mDNS y QR (`host`, `port`, `roomId`, `accessCode` y, si la frecu la tiene, la nota `n`).
- **Nota** (`RoomNote`): Nota musical de cada frecu, su canal reconocible en voz alta ("estamos en Mi"). La asigna `AssignRoomNote` con la hora local de apertura sobre el círculo de quintas (12→Do, 1→Sol, 2→Re … 11→Fa), en octava 4 de 0 a 11 h y en octava 5 de 12 a 23 h; si una frecu cercana ya usa esa nota y octava, avanza a la siguiente quinta libre. Se guarda como semitono desde Do4 (0–23) y es opcional en `Room`, `NearbyRoom` y `RoomInvite`. La calcula solo el anfitrión en la nueva frecu, que se abre con la nota que mostraba, y viaja como `n` en el TXT de mDNS y en el QR y como `note` en `welcome`; quien se une, también por IP, la toma sin recalcularla.
- **Tipo de frecu** (`RoomReach`): Cómo se une el grupo, elegido al crearla y sin mezcla: `local` (todos en la misma Wi-Fi; se entra por la IP del anfitrión con QR, mDNS, Bluetooth o NFC, sin relé de la nube) o `internet` (se entra solo por el punto de encuentro con el QR o el enlace `x`; la invitación no lleva IP ni red y no se anuncia en la red local). `Room.reach` se deduce de `internetId`.
- **Sucesión** (`RoomSuccession`): Lo que cada participante sabe para heredar la frecu, que el anfitrión manda en `room_state` al entrar o salir alguien: turno vigente (`term`, 1 al abrir), si admite traspaso (`handover`), nombre, código, nota, tipo y, por internet, `internetId` y el secreto de anfitrión. Sus `members` (`RoomMember`: id, nombre, IP local y hora de llegada) van en orden de sucesión, que es el de llegada con el anfitrión primero.
- **Traspaso** (`RoomHandover`, `HostChange`): Paso de la frecu a otra persona sin cerrarla. El anfitrión la pasa al salir (`host_handover`); quien la recibe abre su servidor con la sucesión heredada y el turno siguiente, y los demás vuelven a su mismo lugar (mismo id) en su IP. Cada teléfono recibe un `HostChange` con quién la lleva ahora, quién la llevaba y por qué (`left` o `lost`).
- **Estado de sala** (`RoomStatus`): `idle`, `connecting`, `connected`, `reconnecting`, `closed(reason)`.
- **Ruta de audio** (`AudioRoute`): Salida del sonido (`speaker`, `earpiece`, `bluetooth`).
- **Estado de red** (`NetworkState`): Condición de conectividad local del dispositivo (`disconnected` o `connected` con IP, interfaz e indicador de hotspot).
- **Punto de acceso / Hotspot** (`isHotspot`): Modo en el que el dispositivo o la red local opera como router o punto de acceso WiFi portátil sin acceso a internet externo.
- **Preferencias** (`Preferences`): Lo que el teléfono guarda del usuario: nombre visible (`displayName`, nulo si aún no se pidió; de 1 a 20 caracteres), tema (`themePreference`), modo de habla por defecto (`defaultTalkMode`) e idioma (`localePreference`).
- **Tema** (`ThemePreference`): `auto` (sigue al sistema), `light` (claro) o `dark` (oscuro).
- **Idioma** (`LocalePreference`): `auto` (sigue al idioma del teléfono, por defecto), `es` (español) o `en` (inglés).
