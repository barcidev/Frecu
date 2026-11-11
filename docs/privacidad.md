# Política de privacidad de Frecu

> **Borrador para revisar antes de publicarlo.** Completa los datos entre corchetes, revisa que siga siendo cierto con la versión que publiques y súbelo a una URL pública (por ejemplo, GitHub Pages). Esa URL va en Google Play Console y en App Store Connect. No es asesoría legal.
>
> **Por comprobar:** en Android, el escáner QR usa Google ML Kit, que según su documentación puede enviar a Google métricas de uso y diagnóstico cuando hay internet. Revisa la «divulgación de datos de Google Play» de ML Kit; si aplica, menciónalo aquí, en «Lo que no hacemos» y en el formulario de seguridad de los datos de Play.

**Última actualización:** [fecha de publicación]
**Responsable:** [nombre o empresa] · [correo de contacto]

## Resumen

Frecu funciona sin internet y sin cuentas. No recogemos, guardamos ni vendemos datos personales. Solo si abres o te unes a una frecu **por internet**, la señalización y, a veces, la voz cifrada pasan por Cloudflare, el proveedor de nuestro punto de encuentro (ver «Frecus por internet»).

## Qué usa la app y para qué

| Permiso | Para qué | ¿Sale del teléfono? |
|---|---|---|
| Micrófono | Enviar tu voz a las personas de tu frecu mientras hablas (PTT) o con el micrófono abierto. | Solo en directo, por la red Wi-Fi local, a los teléfonos de tu frecu. No se graba. |
| Red local (Wi-Fi, mDNS) | Encontrar frecus cercanas y conectar los teléfonos entre sí. | Solo dentro de la red local. |
| Cámara | Escanear el código QR de invitación a una frecu. | No. Las imágenes no se guardan ni se envían. |
| Notificaciones | Mostrar que la frecu sigue activa con la pantalla apagada y manejarla desde ahí: micrófono, salida de audio, salir y responder a un SOS. | No. |
| Bluetooth | Usar audífonos o intercomunicadores Bluetooth y encontrar frecus cercanas aunque aún no estés en su Wi-Fi. | Quien crea la frecu anuncia por Bluetooth su nombre y su nota; el nombre de la red y su clave solo se entregan a quien escribe el código de la frecu. Nada más sale por Bluetooth. |
| NFC | Leer la invitación del teléfono del anfitrión o de una etiqueta, grabarla en una etiqueta y, en Android, dejar que otro teléfono la lea del tuyo mientras estás en una frecu. | Solo la invitación de la frecu (la misma del QR), y solo al acercar los teléfonos o la etiqueta. |
| Ubicación (solo si activas «Compartir mi ubicación») | Que tu grupo vea a qué distancia y hacia dónde estás, y avisar si alguien se queda atrás. | Solo a los teléfonos de tu frecu, por la red local o, en una frecu por internet, por el punto de encuentro, mientras la compartes. No se guarda. |

## Frecus por internet

Cuando abres o te unes a una frecu por internet:

- **El punto de encuentro** (un Worker de Cloudflare) reenvía entre los teléfonos de la frecu tu nombre visible, el código de acceso, los mensajes rápidos, el estado de habla y, si la compartes, tu ubicación. No los guarda: viven solo mientras la frecu está abierta.
- **La voz** va cifrada de extremo a extremo (WebRTC, DTLS-SRTP). Si los teléfonos no pueden conectarse directo, pasa por un relé TURN de Cloudflare, que no puede oírla.
- **Cloudflare ve tu dirección IP**, como cualquier servicio de internet. El punto de encuentro solo guarda un resumen de ella mientras la frecu está abierta, para frenar a quien prueba códigos.
- Usa tus datos móviles o tu Wi-Fi con internet.

## Datos que se guardan en tu teléfono

- **Tu nombre visible**, el que escribes en la bienvenida. Se guarda solo en tu teléfono y lo ven las personas de cada frecu a la que te unes.
- **Tus preferencias:** modo de habla, idioma, tema, vibración, botón de volumen, auricular al acercar y filtro de viento.
- **El nombre y la clave de tu zona Wi-Fi**, solo si los guardas para invitar por Bluetooth. Se entregan únicamente a quien escribe el código de tu frecu.

Puedes borrarlos desinstalando la app o borrando sus datos desde los ajustes del teléfono.

## Lo que no hacemos

- No hay cuentas ni inicio de sesión.
- No grabamos audio.
- No usamos analítica, publicidad ni rastreo.
- No guardamos nada en la nube: en la red local la voz va cifrada (WebRTC, DTLS-SRTP) directo entre los teléfonos, y por internet solo pasa por Cloudflare mientras la frecu está abierta.

## Menores

Frecu no está dirigida a menores de [13] años y no recoge datos de nadie.

## Cambios

Si esta política cambia, publicaremos la nueva versión en esta misma página con su fecha.

## Contacto

[correo de contacto]

---

# Frecu privacy policy

> **Draft — review before publishing.** Fill in the bracketed fields and publish it at a public URL.

**Last updated:** [publication date]
**Controller:** [name or company] · [contact email]

## Summary

Frecu works without internet and without accounts. We do not collect, store or sell personal data. Only if you open or join a frecu **over the internet** do signaling and, sometimes, the encrypted voice pass through Cloudflare, the provider of our meeting point (see “Frecus over the internet”).

## What the app uses and why

| Permission | Why | Does it leave the phone? |
|---|---|---|
| Microphone | To send your voice to the people in your frecu while you talk (push-to-talk) or with the open mic. | Only live, over the local Wi-Fi network, to the phones in your frecu. Nothing is recorded. |
| Local network (Wi-Fi, mDNS) | To find nearby frecus and connect the phones to each other. | Only within the local network. |
| Camera | To scan a frecu's invitation QR code. | No. Images are neither stored nor sent. |
| Notifications | To show that the frecu is still active with the screen off and to let you leave it. | No. |
| Bluetooth | To use Bluetooth headphones or intercoms, and to find nearby frecus before you are on their Wi-Fi. | Whoever creates the frecu advertises its name and note over Bluetooth; the network name and password are only handed to someone who enters the frecu's code. Nothing else goes out over Bluetooth. |
| NFC | To read the invitation from the host's phone or a tag, write it to a tag and, on Android, let another phone read it from yours while you are in a frecu. | Only the frecu's invitation (the same as the QR), and only when phones or the tag are brought together. |
| Location (only if you turn on “Share my location”) | So your group sees how far away you are and in which direction, and to warn if someone falls behind. | Only to the phones in your frecu, over the local network or, in an internet frecu, through the meeting point, while you share it. Not stored. |

## Frecus over the internet

When you open or join a frecu over the internet:

- **The meeting point** (a Cloudflare Worker) relays between the frecu's phones your display name, the access code, quick messages, talk state and, if you share it, your location. It does not store them: they live only while the frecu is open.
- **Voice** is end-to-end encrypted (WebRTC, DTLS-SRTP). If the phones cannot connect directly, it goes through a Cloudflare TURN relay, which cannot hear it.
- **Cloudflare sees your IP address**, like any internet service. The meeting point keeps only a digest of it while the frecu is open, to slow down anyone guessing codes.
- It uses your mobile data or your Wi-Fi with internet.

## Data stored on your phone

- **Your display name**, the one you enter on the welcome screen. It is stored only on your phone and is shown to the people in each frecu you join.
- **Your preferences:** talk mode, language, theme, vibration, volume button, earpiece on raise and wind filter.
- **Your hotspot's name and password**, only if you save them to invite via Bluetooth. They are only handed to someone who enters your frecu's code.

You can delete them by uninstalling the app or clearing its data in your phone's settings.

## What we don't do

- No accounts or sign-in.
- No audio recording.
- No analytics, advertising or tracking.
- Nothing stored in the cloud: on a local network, voice travels encrypted (WebRTC, DTLS-SRTP) directly between the phones, and over the internet it only passes through Cloudflare while the frecu is open.

## Children

Frecu is not directed at children under [13] and collects no data from anyone.

## Changes

If this policy changes, we will publish the new version on this page with its date.

## Contact

[contact email]
