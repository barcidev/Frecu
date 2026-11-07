# Glosario del dominio

- **Frecu** (`Room`): Sala de voz activa.
- **Anfitrión** (`Host`): Teléfono que crea la frecu y corre el servidor de señalización. También es participante.
- **Participante** (`Participant` / `Peer`): Cualquier teléfono dentro de la frecu, incluido el anfitrión.
- **PTT** (`pushToTalk`): Push-to-talk: el micrófono solo transmite mientras se mantiene presionado el botón.
- **Micrófono abierto** (`openMic`): El micrófono transmite de forma continua.
- **Código de acceso** (`accessCode`): PIN de 4 dígitos que protege la frecu de desconocidos en la misma red.
- **Invitación** (`RoomInvite`): Datos de conexión que viajan en mDNS y QR (`host`, `port`, `roomId`, `accessCode`).
- **Estado de sala** (`RoomStatus`): `idle`, `connecting`, `connected`, `reconnecting`, `closed(reason)`.
- **Ruta de audio** (`AudioRoute`): Salida del sonido (`speaker`, `earpiece`, `bluetooth`).
- **Estado de red** (`NetworkState`): Condición de conectividad local del dispositivo (`disconnected` o `connected` con IP, interfaz e indicador de hotspot).
- **Punto de acceso / Hotspot** (`isHotspot`): Modo en el que el dispositivo o la red local opera como router o punto de acceso WiFi portátil sin acceso a internet externo.
