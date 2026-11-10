# Declaraciones para las tiendas — Frecu V1

Lista de lo que piden Google Play y App Store por las funciones de la V1, con lo que Frecu hace de verdad. Antes de enviar, compárala con los formularios vigentes de cada tienda: cambian sus definiciones.

## Lo que sale de cada teléfono

Frecu no tiene servidores ni cuentas: nada va a internet ni al desarrollador. Lo único que sale del teléfono va directo a otros teléfonos de la misma frecu, por la red local, Bluetooth o NFC, y solo por una acción del usuario:

- **Voz:** en directo, cifrada (WebRTC, DTLS-SRTP), sin grabarse.
- **Nombre visible**, mensajes rápidos y SOS: por la señalización local.
- **Ubicación precisa:** solo con «Compartir mi ubicación», a los teléfonos de la frecu, sin guardarse.
- **Invitación** (red, clave y código de la frecu): por el QR, por Bluetooth tras escribir el código, por NFC al acercar los teléfonos, o grabada en una etiqueta.

La política de privacidad está en `docs/privacidad.md`: hay que publicarla en una URL antes de enviar.

## Google Play

- **Seguridad de los datos:** Frecu no recoge datos (no los envía a su desarrollador ni a terceros). Si el formulario cuenta como «compartir» lo que va de un usuario a otro, declarar **Ubicación precisa** (opcional, la activa el usuario, no se guarda) y **Nombre** (visible para los demás de la frecu).
- **Servicio en primer plano** (formulario de permisos, con un video corto por tipo):
  - `microphone`: mantener la voz de la frecu con la pantalla apagada.
  - `location`: solo mientras el usuario comparte su ubicación con la frecu.
  - No se usa `connectedDevice`: anunciar por Bluetooth no lo exige.
- **Ubicación:** solo en primer plano (`ACCESS_FINE_LOCATION`, sin `ACCESS_BACKGROUND_LOCATION`), con el servicio en primer plano de tipo `location` mientras se comparte. No hace falta la declaración de ubicación en segundo plano.
- **Permisos que no piden formulario:** Bluetooth (`BLUETOOTH_SCAN` con `neverForLocation`, `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`), `NEARBY_WIFI_DEVICES` (`neverForLocation`), NFC, cámara, notificaciones.
- **Hardware opcional:** Bluetooth LE, NFC y HCE van con `required="false"`: la app se instala en teléfonos sin ellos.
- **Firma:** la clave de subida y `android/key.properties` las crea el titular de la cuenta (ver `android/key.properties.example`). Sin ellas, el `appbundle` se firma con la clave de depuración y Play lo rechaza.
- **Público:** no dirigida a menores; clasificación de contenido sin violencia ni contenido de usuarios fuera de la voz en vivo.

## App Store

- **Etiquetas de privacidad:** igual que en Play. Si Apple cuenta lo que va entre usuarios, declarar **Ubicación precisa** y **Nombre**, «no vinculados a la identidad» y «sin rastreo».
- **Textos de permisos** (`Info.plist` e `InfoPlist.strings` en español e inglés): micrófono, red local, cámara, ubicación mientras se usa, Bluetooth y NFC.
- **Modos en segundo plano:** `audio` (la voz de la frecu con la pantalla apagada) y `location` (solo mientras se comparte la ubicación). Revisión pide justificar `location`: explicar «Compartir mi ubicación» con un video.
- **Capacidades del App ID** (las activa la firma automática al compilar para un teléfono):
  - Hotspot Configuration: unirse a la red de la frecu.
  - NFC Tag Reading: leer y grabar invitaciones.
- **Norma 2.5.9:** el botón de volumen para hablar solo existe en Android; en iPhone no se ofrece.
- **Cifrado (exportación):** la voz usa el cifrado estándar de WebRTC, exento. Responder en App Store Connect, o añadir `ITSAppUsesNonExemptEncryption` = `NO` en `Info.plist` si se confirma la exención.
- **Solo iPhone** (`TARGETED_DEVICE_FAMILY = 1`).

## Pendiente antes de enviar

- Publicar la política de privacidad en una URL y ponerla en las dos fichas.
- Grabar los videos del servicio en primer plano (micrófono y ubicación) y de la ubicación en segundo plano en iOS.
- Probar con otro teléfono: invitado por Bluetooth, leer un Android que hace de etiqueta (desde Android y desde iPhone) y grabar una etiqueta física.
- Crear la clave de subida de Android y activar las capacidades en el App ID.
