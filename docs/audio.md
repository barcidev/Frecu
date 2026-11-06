# Audio — Frecu

- Configura `audio_session` en categoría `playAndRecord`, modo `voiceChat`, con Bluetooth permitido y salida por altavoz por defecto.
- Al conectar audífonos Bluetooth o cableados, la salida cambia a ellos automáticamente.
- En modo micrófono abierto con altavoz, muestra un aviso sugiriendo audífonos para evitar eco.
- El indicador de "hablando" se basa en `talk_state` en PTT. En micrófono abierto, usa el nivel de audio de las estadísticas de WebRTC.
