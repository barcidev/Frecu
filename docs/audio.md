# Audio — Frecu

- Configura `audio_session` en categoría `playAndRecord`, modo `voiceChat`, con Bluetooth permitido y salida por altavoz por defecto. Al activar la sesión de cada frecu se vuelve a aplicar la ruta elegida.
- Al conectar audífonos Bluetooth o cableados, la salida cambia a ellos automáticamente, también si ya estaban conectados al entrar (Bluetooth antes que cable). Al desconectar los que se usaban, vuelve al altavoz. La isla avisa «Audio por …».
- La hoja de salida y la pastilla muestran el nombre del dispositivo Bluetooth (el `name` del dispositivo de `audio_session`, p. ej. «Sena 50S · Bluetooth · conectado»).
- Un solo `getUserMedia` por frecu. Salir, cerrar o perder la frecu para la pista, suelta la sesión de audio y deja de transmitir.
- Sin permiso de micrófono se escucha igual y la frecu lo avisa con un acceso a los ajustes del sistema.
- Elegir «Abierto» en el selector abre el micrófono al instante. El modo por defecto de Ajustes se aplica al entrar sin abrirlo: Abierto empieza en silencio. Silenciarse en Abierto envía `talk_state` con `muted: true` y los demás ven «Silenciado».
- Mientras la frecu reconecta no se transmite, ni en PTT ni en Abierto; al volver, el micrófono abierto se retoma solo y PTT espera a que se vuelva a presionar.
- En modo micrófono abierto con altavoz, muestra un aviso sugiriendo audífonos para evitar eco.
- El indicador de "hablando" se basa en `talk_state` en PTT. En micrófono abierto, usa el nivel de audio de las estadísticas de WebRTC.
