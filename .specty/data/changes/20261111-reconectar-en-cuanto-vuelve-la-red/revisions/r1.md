---
kind: standard
---

# Reconectar en cuanto vuelve la red

## Objetivo

Hoy, al caerse la conexión, el invitado y el relé del anfitrión en modo internet esperan siempre la espera completa (1→2→4→8→15 s) antes de reintentar. Con este cambio, si durante esa espera el teléfono recupera una red (aparece una dirección IP nueva), el reintento se adelanta y la frecu vuelve antes de que termine la cuenta.

## Fuera de alcance

- Añadir plugins nativos (p. ej. connectivity_plus) o escuchar eventos del sistema operativo.
- Cambiar el número de intentos, el backoff o los tiempos de espera del `welcome`.
- Adelantar el reintento cuando la red se pierde (solo cuando aparece).
- Reconexión de la voz WebRTC (va por su propio camino una vez vuelve la señalización).
- Cambiar textos o pantallas.

## Supuestos

- A1: Cuando vuelve la red (Wi-Fi, punto de acceso o datos móviles) aparece en `NetworkInterface.list` al menos una dirección IPv4/IPv6 no loopback que no estaba en la consulta anterior.
  - impacto: alto
- A2: Consultar `NetworkInterface.list` cada 500 ms solo durante la espera de reconexión tiene un coste despreciable.
- A3: Si la IP de la Wi-Fi reaparece igual tras desaparecer, cuenta como aparición porque se compara con la consulta anterior, no solo con la del inicio.
- A4: La cuenta de «Reconectando · N s» puede pasar a 0 («intentando») en cuanto se adelanta el intento sin cambiar la UI.

## Criterios de aceptación

- AC1: CUANDO durante la espera aparece una dirección de red que no estaba en la consulta anterior ENTONCES la espera termina antes de su plazo e indica que vino por la red.
- AC2: CUANDO durante la espera solo desaparecen direcciones o nada cambia ENTONCES la espera dura su plazo completo; y si quien espera se cancela, termina sin seguir consultando.
- AC3: CUANDO un invitado reconecta y aparece una red nueva durante la espera ENTONCES reintenta antes de que termine la espera, el estado pasa a `reconnecting(retryIn: 0, attempt)` antes del intento y vuelve a quedar en línea.
- AC4: CUANDO el relé del anfitrión en modo internet se cae y aparece una red nueva durante la espera ENTONCES vuelve a conectar con la nube antes de que termine la espera.

## Diseño

- Nueva pieza `NetworkReturnWatcher` en `lib/core/network/network_return.dart`: recibe la fuente de interfaces (por defecto `NetworkInterface.list`) y el intervalo de sondeo (por defecto `NetworkConstants.networkReturnPollInterval`, 500 ms). `addresses()` da las direcciones no loopback; `wait(delay, {baseline, cancelled})` devuelve `Future<bool>`: `true` si despertó porque apareció una dirección respecto a la consulta anterior (la primera se compara con `baseline` o con una toma inicial), `false` si se cumplió el plazo o `cancelled()` dio verdadero. Un sondeo a la vez; los errores de la fuente se ignoran.
- `RoomRepositoryImpl._reconnect`: toma `baseline` al empezar y antes de cada intento; sustituye `Future.delayed` por `wait(delay, baseline:, cancelled: () => !_stillReconnecting(session))`. Si despertó por la red publica `reconnecting(retryIn: Duration.zero, attempt)` para que la cuenta muestre 0 mientras intenta. Nuevo parámetro `networkReturnPollInterval` para pruebas; el relé por defecto recibe el mismo vigía.
- `CloudRelayDataSource._scheduleReconnect`: el `Timer` pasa a `wait(delay, cancelled: () => generation != _generation)` y luego conecta; parámetro opcional `networkWatcher`. `stop()` cancela por la generación.

## Archivos

- crear lib/core/network/network_return.dart — vigía que adelanta la espera cuando aparece una red.
- modificar lib/core/constants/network_constants.dart — intervalo de sondeo de la red durante la reconexión.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — la espera de reconexión del invitado usa el vigía y publica `retryIn: 0` al adelantar.
- modificar lib/features/room/data/datasources/cloud_relay_datasource.dart — la espera de reconexión del relé usa el vigía.
- crear test/core/network/network_return_test.dart — pruebas del vigía (aparición, desaparición, plazo y cancelación).
- modificar test/features/room/data/room_reconnect_test.dart — el invitado reintenta antes al aparecer una red.
- modificar test/features/room/data/internet_room_test.dart — el relé del anfitrión vuelve antes al aparecer una red.

## Tareas

- [ ] T1: Vigía de vuelta de la red
  - files: lib/core/network/network_return.dart, lib/core/constants/network_constants.dart, test/core/network/network_return_test.dart
  - ac: AC1, AC2
  - verify: flutter test test/core/network/network_return_test.dart
- [ ] T2: El invitado reintenta en cuanto vuelve la red
  - files: lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/room_reconnect_test.dart
  - ac: AC3
  - verify: flutter test test/features/room/data/room_reconnect_test.dart
- [ ] T3: El relé del anfitrión vuelve en cuanto vuelve la red
  - files: lib/features/room/data/datasources/cloud_relay_datasource.dart, lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/internet_room_test.dart
  - ac: AC4
  - verify: flutter test test/features/room/data/internet_room_test.dart

## Riesgos

- R1: Un cambio de dirección sin red útil (p. ej. Wi-Fi sin el anfitrión) gasta un intento antes — la toma de referencia se renueva antes de cada intento, así que solo adelanta una vez por aparición.
- R2: Pruebas que dejan el sondeo vivo — `cancelled` corta el sondeo al salir o al parar el relé.
