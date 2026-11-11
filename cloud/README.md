# Frecu en internet (Cloudflare)

Punto de encuentro para el modo internet de Frecu. Es un Worker de Cloudflare
con un Durable Object por sala que hace de **relé en estrella** entre el
anfitrión y sus invitados. El anfitrión sigue siendo la autoridad de la frecu
(valida el código, asigna ids, enruta); aquí no se guarda nada más que el
SHA-256 del secreto del anfitrión. No hay servidor propio que mantener.

## Contrato

| Ruta | Qué hace |
| --- | --- |
| `GET /rooms/<id>/host?secret=<s>` (WebSocket) | El primero que llega reclama la sala. Secreto distinto → `403`. El mismo secreto reemplaza la conexión anterior (y cierra a sus invitados). |
| `GET /rooms/<id>/guest` (WebSocket) | Sin anfitrión conectado → `404`. Máximo 16 invitados a la vez (`503`). |
| `POST /rooms/<id>/turn` | Credenciales TURN de Cloudflare Realtime (24 h) como `{"iceServers":[…]}`, más `stun:stun.cloudflare.com:3478`. Sin anfitrión → `404`. |
| `GET /j/<id>` | Página para abrir una invitación: lee `#c=…&n=…&name=…` y ofrece «Abrir en Frecu» hacia `frecu://join?x=<id>&c=…`. |

`<id>` son 32 caracteres hexadecimales en minúscula (128 bits); otro formato →
`400`.

Sobres entre el Durable Object y el anfitrión (JSON de texto):

- Al anfitrión: `{"t":"open","c":"…","k":"…"}` (nuevo invitado; `k` son los
  primeros 16 hex del SHA-256 de su IP), `{"t":"msg","c":"…","d":"…"}` (texto
  del invitado tal cual) y `{"t":"close","c":"…"}` (el invitado se fue).
- Del anfitrión: `{"t":"msg","c":"…","d":"…"}` (se entrega `d` tal cual a ese
  invitado) y `{"t":"close","c":"…"}` (se cierra a ese invitado).

Los invitados nunca se hablan entre sí. Si el anfitrión se desconecta, se
cierra a todos los invitados (código `1001`). Mensajes de más de 64 KB o
binarios cierran al invitado (`1009` / `1003`). Una sala sin anfitrión durante
24 h olvida su secreto.

El código de la frecu viaja en el fragmento de `/j/<id>#c=…`: el navegador no
lo manda al servidor, así que no llega a los registros del Worker.

## Desarrollo

```bash
npm install
npm test          # pruebas en el runtime de Workers (Miniflare)
npm run typecheck
npm run dev       # Worker local en http://localhost:8787
```

Si cambias `wrangler.toml`, regenera los tipos con `npx wrangler types`.

## Despliegue

1. **Crear una cuenta de Cloudflare** (gratis) en <https://dash.cloudflare.com/sign-up>.
   Esto lo hace la persona dueña del proyecto.
2. Iniciar sesión desde esta carpeta:

   ```bash
   npx wrangler login
   ```

3. **Crear la clave TURN** en el panel: *Realtime → TURN Server → Create*.
   Copia el **Turn Token ID** y el **API Token** que muestra (el token solo se
   ve una vez).
4. Guardarlos como secretos del Worker:

   ```bash
   npx wrangler secret put TURN_KEY_ID
   ```

   ```bash
   npx wrangler secret put TURN_KEY
   ```

   (`TURN_KEY_ID` = Turn Token ID, `TURN_KEY` = API Token.)
5. Publicar:

   ```bash
   npx wrangler deploy
   ```

   Wrangler imprime la URL, del estilo `https://frecu-cloud.<tu-subdominio>.workers.dev`.
   El Durable Object usa SQLite, que está incluido en el plan gratis.

## Pasar la URL a la app

La app toma la URL al compilar; sin ella el modo internet queda apagado y solo
funciona la red local:

```bash
flutter run --dart-define=FRECU_CLOUD_URL=https://frecu-cloud.<tu-subdominio>.workers.dev
```

Lo mismo para `flutter build apk` / `flutter build ipa`.
