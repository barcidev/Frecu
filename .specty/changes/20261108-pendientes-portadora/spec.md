---
kind: epic
---

# Pendientes de Portadora: voz real, nota coherente, íconos propios, grupo General y mantenimiento

## Objetivo

Cerrar lo que quedó pendiente de la épica Portadora:
- **Voz real:** el anillo del núcleo PTT y las firmas de la malla siguen el nivel real de la voz, medido por WebRTC, en vez de una onda simulada.
- **Nota coherente:** la frecu se abre con la nota que el anfitrión vio en pantalla, y quien se une por IP ve la nota de la frecu.
- **Íconos propios:** campos, avisos, hojas de unión y Ajustes dejan los íconos de Material.
- **Grupo General:** Ajustes gana el grupo «General» del prototipo, con idioma, permisos y guía del punto de acceso.
- **Mantenimiento:** el código queda sin `PttButton`, con los archivos grandes partidos y con `dart format` limpio.

## Fuera de alcance

- Hablar con el botón de volumen (parte de P102/P106). Queda anotado como pendiente nuevo al cerrar.
- Íconos de Material fuera de los señalados (campos, avisos, hojas de unión, aviso de eco y Ajustes).
- Variante sólida de alerta de `FrButton` (P109), QR con ojos redondeados (P110) y nombre del dispositivo Bluetooth (P111).
- Eventos pasajeros de la isla y cuenta atrás de reconexión (P101, P105).
- Abrir los ajustes de Wi-Fi o de zona Wi-Fi del sistema (P83, P86, P93), porque necesita un plugin.
- `PermissionsGuard` y el paso directo a permisos (P78, P80).
- Las firmas decorativas de la bienvenida, del perfil y de la hoja de nombre, que siguen con `frVoice`.

## Supuestos

- A1: El nivel de voz sale de `RTCPeerConnection.getStats()` de flutter_webrtc: el propio, de `audioLevel` en el informe `media-source` del audio local, y el de cada participante remoto, de `audioLevel` en su `inbound-rtp` de audio. Se muestrea unas 10 veces por segundo solo mientras hay frecu activa y se expone como flujo desde `VoiceRepository`.
  - impacto: alto
- A2: Con movimiento reducido, el núcleo y la malla siguen mostrando el nivel real, pero sin animarlo: lo muestran a saltos, sin resorte.
- A3: La nota que ve el anfitrión en la nueva frecu se pasa tal cual a `RoomNotifier.createRoom` (`note`), que deja de calcularla con su propio reloj. Si llega sin nota, la calcula como hoy.
  - impacto: alto
- A4: Al unirse por IP, la nota ya llega en el mensaje `welcome` desde el cambio «Nota musical RoomNote en el mensaje welcome». C3 solo lo comprueba de punta a punta con una prueba de la frecu activa y corrige lo que falte.
- A5: `FrField` y `FrBanner` aceptan `FrIconData` como ya hace `FrButton.drawn`. El cierre de `FrBanner` usa `FrIcons.close` por defecto. Las variantes con `IconData` se quitan cuando ya no tengan usos.
- A6: El idioma es una preferencia nueva, `LocalePreference`: `auto` (idioma del teléfono, por defecto), `es` o `en`. Se guarda con las demás preferencias en shared_preferences y se aplica al instante con `LocaleSettings.setLocale`, que carga el inglés diferido, y al abrir la app en `bootstrap.dart`, en lugar de `useDeviceLocale` cuando no es `auto`.
  - impacto: alto
- A7: La fila «Permisos» cuenta los permisos que pide la bienvenida y muestra cuántos están concedidos («3/3»). Al tocarla pide los que faltan y, si alguno quedó negado para siempre, abre los ajustes de la app con `openAppSettings` de permission_handler, que ya es dependencia.
- A8: La fila «Guía del punto de acceso» abre la guía de C17 sola, reutilizando el widget de `features/lobby` sin cambiarlo, en una pantalla u hoja que vuelve a Ajustes.

## Criterios de aceptación

- AC1: CUANDO el usuario transmite ENTONCES el bisel del núcleo PTT sigue el nivel real de su micrófono. CUANDO recibe a alguien ENTONCES el anillo de recepción y la firma de esa persona en la malla siguen el nivel real del audio recibido de ella. En silencio vuelven a reposo y ya no se usa `frVoice` en el núcleo ni en la malla.
- AC2: CUANDO el anfitrión toca Abrir en la nueva frecu ENTONCES la frecu abierta lleva exactamente la nota que mostraba la pantalla en ese momento, aunque la hora haya cambiado desde que se calculó.
- AC3: CUANDO alguien se une por IP manual, sin mDNS ni QR, ENTONCES la frecu activa muestra en la cabecera la nota del anfitrión.
- AC4: CUANDO se ven los campos (`FrField`), los avisos (`FrBanner`) con su botón de cerrar, las hojas de unión por código e IP, el aviso de eco de la frecu activa y Ajustes (atrás, editar, modos de habla y aviso) ENTONCES sus íconos son `FrIcons` dibujados y no `Icons.*` de Material.
- AC5: CUANDO se abre Ajustes ENTONCES entre «Voz» y «Apariencia» aparece el grupo «General», con sus textos en español y en inglés, y tres filas: «Idioma» muestra el idioma actual y al tocarla se elige Auto, Español o English, con el cambio visible al instante y mantenido al volver a abrir la app; «Permisos» muestra cuántos están concedidos y al tocarla pide los que faltan o abre los ajustes del sistema; «Guía del punto de acceso» abre la guía y se vuelve a Ajustes.
- AC6: CUANDO se revisa el código ENTONCES `PttButton` y su prueba ya no existen, `room_mesh_scene.dart`, `room_sheets.dart` y `new_room_step.dart` quedan bajo el aviso de 300 líneas de código, `room_mesh_test.dart` queda bajo el máximo de 600 y `dart format --set-exit-if-changed .` pasa sin cambios.
  - test: manual

## Diseño

- **Nivel de voz (C4):**
  - `VoiceRepository` suma `Stream<double> watchLocalLevel()` y `Stream<Map<String, double>> watchPeerLevels()`, con niveles de 0 a 1 por id de participante.
  - La implementación los lee de `PeerConnectionDatasource` con `getStats()` en un temporizador que solo corre con frecu activa.
  - En presentación, el núcleo PTT (`ptt_core_painter.dart`) y la malla (`room_mesh_scene.dart`) reciben el nivel por parámetro, en lugar de `frVoice`, y lo suavizan con su resorte.
- **Nota (C3):** `RoomNotifier.createRoom` recibe `RoomNote? note`, y la nueva frecu le pasa la nota que pinta. `NewRoomHero`, `_HeroBox` y `_NoteReading` pasan a `new_room_hero.dart` (P94).
- **Íconos (C1, C2, C5, C6):** `FrField` y `FrBanner` se adaptan siguiendo el patrón de `FrButton.drawn`. Los equivalentes son:
  - `nodes`, `lock`, `users` y `alert` en las hojas de unión;
  - `headset` en el aviso de eco;
  - `back`, `edit`, `walkie`, `openMic` y `alert` en Ajustes;
  - `close` para cerrar avisos.
- **Idioma (C6):**
  - `LocalePreference` (Freezed o enum, como `ThemePreference`) en `features/settings/domain`, y `Preferences.localePreference`.
  - `PreferencesRepository` lo guarda, y `bootstrap.dart` lo aplica al arrancar.
  - La hoja de idioma sigue el modelo de `edit_name_sheet.dart` y `FrSheet`.
- **Permisos y guía (C7):**
  - La fila «Permisos» lee el estado del repositorio de permisos existente.
  - «Guía del punto de acceso» reutiliza `HotspotGuideStep` de `features/lobby`.
- **Mantenimiento (C5, C8):**
  - Mover `RoomMeshPainter` a `room_mesh_painter.dart` (P82).
  - Mover `AudioRouteSheet` y `LeaveSheet` a sus archivos (P112).
  - Partir `room_mesh_test.dart` en `room_mesh_scene_test.dart` y `room_mesh_test.dart` (P76).
  - Borrar `PttButton` (P100/P104).
  - Pasar `dart format` a los 6 archivos de P99.
- **Dominio:** se añade a `docs/dominio.md` «Idioma (`LocalePreference`)».

## Cortes

- C1: Íconos propios en `FrField` y `FrBanner`, y formato de las pruebas de core
  - ac: AC4, AC6
- C2: Íconos propios en las hojas de unión por código e IP
  - ac: AC4
  - depends: C1
- C3: Nota coherente al crear la frecu y al unirse por IP, y nueva frecu partida
  - ac: AC2, AC3, AC6
- C4: Nivel real de voz en el núcleo PTT y en la malla
  - ac: AC1
- C5: Frecu activa: aviso de eco con ícono propio, sin `PttButton`, malla y hojas partidas, y formato de sus pruebas
  - ac: AC4, AC6
  - depends: C1, C4
- C6: Ajustes con íconos propios e idioma guardado
  - ac: AC4, AC5
  - depends: C1
- C7: Permisos y guía del punto de acceso en el grupo General de Ajustes
  - ac: AC5
  - depends: C6
- C8: Formato de red y permisos
  - ac: AC6

## Riesgos

- R1: Leer `getStats()` 10 veces por segundo con 6 participantes puede pesar en un teléfono de gama media — mitigación: un solo temporizador por frecu, solo con frecu activa, y perfilar en un dispositivo real (P33).
- R2: Hay cortes en paralelo sobre los mismos módulos — mitigación: en `features/room`, C5 depende de C4 porque los dos tocan `room_mesh_scene.dart`; en `features/settings`, C7 depende de C6; en `features/lobby`, C2 y C3 tocan archivos distintos.
- R3: Partir o formatear pruebas aprobadas de cortes anteriores — mitigación: se reescriben en la fase de pruebas de su corte, sin cambiar ninguna aserción.
