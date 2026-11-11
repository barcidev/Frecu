---
kind: epic
---

# Tipo de frecu y traspaso de anfitrión

## Objetivo

Al crear una frecu, el anfitrión elige si es **Local** (todos en la misma Wi-Fi, sin internet) o **Por internet** (desde cualquier lugar con el QR o el enlace). Las dos formas no se mezclan. Cuando la red no depende del teléfono del anfitrión (una Wi-Fi que ya tienen o internet), la frecu sobrevive a su salida: él la pasa a otra persona, y si se cae, pasa sola. Cuando la red la crea el teléfono del anfitrión, la frecu reintenta y, si él no vuelve, se cierra. Prototipo aprobado: `docs/diseno/prototipo/anfitrion.html` (en la carpeta principal del repositorio).

## Fuera de alcance

- Traspaso cuando la red la crea el teléfono del anfitrión (red de Frecu o zona Wi-Fi): no hay forma de mantener la red sin él.
- Pasar una frecu de local a internet, o al revés, una vez abierta.
- Registro de usuarios, límite de 30 minutos gratis y SFU para más de 6 personas.
- Que un invitado elija por su cuenta convertirse en anfitrión sin que el anfitrión lo pase o se caiga.

## Supuestos

- A1: La app sabe si la red de una frecu local la crea el anfitrión: la creó con la red de Frecu (`LocalOnlyHotspot`), o su interfaz es de zona Wi-Fi (`NetworkState.isHotspot`). En cualquier otro caso es una Wi-Fi compartida y hay traspaso.
  - impacto: alto
- A2: Un iPhone puede ser sucesor en una Wi-Fi compartida, porque ya puede correr el servidor de señalización en el puerto 47800.
- A3: El Durable Object del Worker puede mantener la frecu abierta unos 10 s sin anfitrión, y aceptar al sucesor con el mismo secreto de anfitrión que se reparte a los participantes.
  - impacto: alto
- A4: Los campos nuevos del protocolo y de la invitación son aditivos: una app anterior los ignora y sigue funcionando sin traspaso.
- A5: El orden de sucesión es el orden de llegada a la frecu. En la salida voluntaria, el anfitrión puede elegir a otra persona.

## Criterios de aceptación

- AC1: CUANDO el usuario toca «Crear frecu» ENTONCES el primer paso pregunta «¿Cómo se une tu grupo?» con «Local» (marcada por defecto) y «Por internet». Local sigue a «Prepara la red» y luego a «Nueva frecu» (pasos de 3); Por internet va directo a «Nueva frecu» (pasos de 2). Sin internet, o sin punto de encuentro configurado, «Por internet» se ve atenuada y dice qué falta. «Nueva frecu» ya no tiene el interruptor «Permitir internet», y bajo «Abierta a las HH:MM» lleva la etiqueta «Local» o «Por internet».
- AC2: CUANDO la frecu es local ENTONCES no abre el relé de la nube, su invitación (QR, NFC, Bluetooth) no lleva id de internet ni enlace, y un QR por internet no permite entrar a ella.
- AC3: CUANDO la frecu es por internet ENTONCES todos los invitados entran por la nube, aunque estén en la misma Wi-Fi que el anfitrión. Su invitación no lleva IP local, no se anuncia por mDNS ni por Bluetooth, y ya no existe el aviso «La red de Frecu no tiene internet».
- AC4: CUANDO la red de una frecu local la crea el anfitrión ENTONCES la hoja de salir solo ofrece «Cerrar frecu», con el texto «Tu teléfono es la red de la frecu. Si sales, la frecu se cierra para …». Si el anfitrión se cae, los invitados reintentan como hoy y, si no vuelve, la frecu se cierra con «Se perdió la red del anfitrión y no volvió.».
- AC5: CUANDO la frecu es local en una Wi-Fi compartida, o por internet ENTONCES los participantes saben que admite traspaso, y cada uno conoce el orden de sucesión, el turno vigente y el estado de la frecu (nombre, código, nota, modo y participantes), que el anfitrión les envía al entrar y en cada cambio.
- AC6: CUANDO el anfitrión de una frecu con traspaso toca Salir y hay alguien más ENTONCES ve «¿Qué pasa con la frecu?» con «Que siga sin mí» (marcada) y «Cerrarla para todos». Al seguir con la primera, ve «¿Quién lleva la frecu?» con los participantes y la persona que lleva más tiempo sugerida, y el botón «Pasar a «nombre» y salir». Si está solo, ve la hoja de cerrar de hoy.
- AC7: CUANDO el anfitrión pasa la frecu ENTONCES quien la recibe abre el servidor (o el relé por internet), sube el turno y ve «Ahora llevas la frecu. «anterior» te la pasó al salir.» con «Mostrar el QR». Los demás se reconectan a él sin volver a escribir el código y ven ««anterior» salió · «nombre» lleva ahora la frecu». La cabecera dice «Anfitrión · «nombre»», y quien la recibe ve «Llevas la frecu». Por internet, el enlace y el QR siguen sirviendo; en Wi-Fi compartida, el QR es el nuevo.
- AC8: CUANDO el anfitrión de una frecu con traspaso deja de responder (cierre de la app, teléfono apagado, fuera de alcance) ENTONCES la isla dice ««anfitrión» no responde» durante unos 4 s. Si no vuelve, la toma la primera persona del orden de sucesión que siga conectada, y si esa tampoco responde, la siguiente. Los demás ven ««anfitrión» se desconectó · «nombre» lleva ahora la frecu», y quien la recibe ve «Ahora llevas la frecu. «anfitrión» se desconectó.».
- AC9: CUANDO el anfitrión anterior vuelve, o dos teléfonos se creen anfitriones ENTONCES gana el turno mayor y el otro entra como invitado, con el aviso «Volviste como invitado · «nombre» lleva la frecu».
- AC10: CUANDO falta el anfitrión en una frecu con traspaso ENTONCES la voz entre los invitados que siguen conectados no se corta mientras se hace el traspaso.
  - test: manual
- AC11: CUANDO se hace un traspaso por internet ENTONCES el Worker mantiene la frecu abierta sin anfitrión durante el periodo de gracia, acepta como anfitrión al sucesor que presenta el secreto con un turno mayor, retira al anfitrión anterior si vuelve con un turno menor, y cierra la frecu si nadie la toma en ese tiempo.
- AC12: CUANDO el traspaso se prueba en teléfonos reales (Android y iPhone, en Wi-Fi compartida y por internet) ENTONCES se cumple de punta a punta, de forma voluntaria y por caída.
  - test: manual

## Diseño

- **Tipo de frecu.** `Room` gana `reach: RoomReach { local, internet }` y `handover: bool`. La elección se guarda en el flujo de creación (`create_room_page.dart`): el paso nuevo va antes de «Prepara la red», que solo aparece en local. `createRoom(internet:)` pasa a `reach`. Con `internet`, el anfitrión no publica mDNS ni Bluetooth, y la invitación lleva solo `x` (id de internet), el código y la nota.
- **Red del anfitrión.** `handover = reach == internet || !hostOwnsNetwork`, donde `hostOwnsNetwork` es verdadero si la frecu se creó con la red de Frecu o si la IP de la invitación es de zona Wi-Fi.
- **Protocolo (aditivo).** `welcome` y un mensaje nuevo `room_state` llevan `term` (entero), `handover`, `succession` (ids en orden), el estado de la frecu y, por participante, su IP (en local) y su hora de llegada. Por internet, también el secreto de anfitrión. Un mensaje nuevo `host_handover { to, term }`: el anfitrión lo envía antes de salir. Un mensaje nuevo `host_changed { host, term, reason: left|lost }`: el nuevo anfitrión lo envía al tomar la frecu.
- **Toma en local.** El sucesor abre `SignalingServerDataSource` en 47800 con el estado heredado y `term + 1`, y se une a sí mismo como hoy. Los demás, en lugar de reintentar la IP vieja, se conectan a la IP del sucesor con su mismo id (`rejoin`) y el código heredado. Si no responde, prueban al siguiente de la lista. Al cambiar de anfitrión, el notifier de la frecu reemplaza la invitación y la notificación.
- **Caída.** `RoomRepositoryImpl` ya detecta la caída del socket. Con `handover`, tras 2 intentos fallidos (unos 4 s), el primero vivo de la sucesión toma la frecu si su propia red sigue arriba (`NetworkReturn`). Si su red no está arriba, no la toma y espera a que lo haga el siguiente.
- **Turnos.** Todo `join` y `welcome` lleva `term`. Un servidor que recibe un `join` con un `term` mayor que el suyo deja de ser anfitrión y se une como invitado al que tiene el turno mayor.
- **Worker.** `room.ts` guarda el `term` vigente. Al caer el anfitrión, no cierra a los invitados durante la gracia (10 s): les envía `{t:'host_lost'}`. Acepta un socket de anfitrión con el mismo secreto y un `term` mayor, y en ese caso retira al anterior. Si nadie lo toma, cierra.
- **Voz.** La malla WebRTC entre invitados no se desarma por perder el socket de señalización. Solo se cierran las conexiones con el anfitrión que se fue, y el nuevo anfitrión renegocia las suyas.
- **Textos.** Todo en slang (es/en), sin suponer género: «lleva la frecu», «Llevas la frecu».

## Cortes

- C1: Tipo de frecu al crear (Local o Por internet) y sin mezcla
  - ac: AC1, AC2, AC3
- C2: Red del anfitrión: detectar si admite traspaso; en la red del anfitrión, hoja de salir y cierre tras reintentos
  - ac: AC4
  - depends: C1
- C3: Sucesión, turno y estado compartido en el protocolo (`welcome`, `room_state`)
  - ac: AC5
  - depends: C2
- C4: Traspaso voluntario en Wi-Fi compartida: hojas de salir y de sucesor, toma de la frecu y reconexión de los demás
  - ac: AC6, AC7
  - depends: C3
- C5: Traspaso por caída en Wi-Fi compartida, solo datos: reintentos al anfitrión, sucesión en orden con el mismo id, toma por quien siga en la red y turno en el `join`
  - ac: AC8
  - depends: C4
- C6: Traspaso por internet: Worker con gracia, turno y sucesor; voluntario y por caída
  - ac: AC11, AC7, AC8
  - depends: C5, C10
- C7: La voz entre invitados sigue durante el traspaso, y pruebas en teléfonos reales
  - ac: AC10, AC12
  - depends: C6, C9
- C8: Paso «¿Cómo se une tu grupo?» al crear (Local o Por internet), pasos de 3 o 2, etiqueta bajo la hora y sin el interruptor «Permitir internet»
  - ac: AC1
  - depends: C1
- C9: La espera en pantalla cuando el anfitrión no responde: isla ««anfitrión» no responde · N s», pista con el sucesor y solo el anfitrión en reconectando
  - ac: AC8
  - depends: C5
- C10: Regreso del anfitrión anterior y dos anfitriones a la vez: gana el turno mayor y el otro entra como invitado
  - ac: AC9
  - depends: C5
- C11: Por internet, el anfitrión anterior que vuelve con un turno menor entra como invitado en lugar de reintentar su relé
  - ac: AC9
  - depends: C6

## Riesgos

- R1: Dos teléfonos toman la frecu a la vez por una partición de la red — se resuelve con el turno mayor y, a igual turno, gana el que va antes en la sucesión.
- R2: El sucesor no tiene permiso de red local en iOS, o el puerto 47800 está ocupado — se salta al siguiente de la sucesión.
- R3: Es la épica más grande de la app y toca `room_repository_impl.dart` (626 líneas) — se extrae la lógica de traspaso a una pieza propia en `data` en C3, en lugar de hacer crecer el repositorio.
- R4: Las pruebas con varios teléfonos son difíciles en CI — se prueba con datasources falsos en Dart y con `vitest` en el Worker. Lo real queda en AC12 (manual).

## Cierre

### Resumen

Al crear una frecu se elige Local o Por internet, sin mezcla. Con la red creada por el anfitrión, al salir solo se puede cerrar, y si se cae la frecu se cierra tras los reintentos. En una Wi-Fi compartida o por internet, el anfitrión pasa la frecu al salir. Si se cae, la toma sola el siguiente de la sucesión, tras una espera visible de unos 4 s. El anterior que vuelve entra como invitado. La voz entre invitados no se corta durante el traspaso. Once cortes fusionados en develop, con 1249 pruebas en verde y las pruebas del Worker con vitest.

### Desviaciones

- C1 salió XL: el paso «¿Cómo se une tu grupo?» pasó a un corte nuevo, C8 (revisión 2).
- C5 salió XL: se dividió en C5 (datos de la caída), C9 (la espera en pantalla) y C10 (regreso y dos anfitriones) (revisión 3).
- C6 dejó sin cubrir el regreso por internet: se añadió C11 (revisión 4).
- `welcome` no cambió: dos pruebas aprobadas dependen de su firma. Por eso el estado va en un mensaje nuevo, `room_state`, y el dato de la red, en el participante.
- C3 cambió varios `switch` sobre `SignalingMessage` a `default`, para no pasar el límite de complejidad.
- La hoja de salir dice «Llevas la frecu y hay N personas más.», sin suponer género.
- AC10 y AC12 (teléfonos reales) se aceptaron sin probar, por decisión del usuario. El guion quedó en P185.

### Decisiones

- «Local / Por internet» en lugar de «privada / pública». La palabra «router» no aparece en la app.
- El anfitrión elige el sucesor al salir. En una caída, decide el orden de llegada.
- `RoomRepository` no cambió. El traspaso se expone con una interfaz aparte, `RoomHandover`, para no romper los dobles de las pruebas aprobadas.
- El Worker no se desplegó: lo decide el usuario (P179).

### Pendientes

- P179: desplegar el Worker (`cd cloud && npx wrangler deploy`).
- P185: probar en teléfonos reales con el guion.
- P187: el sucesor que recibe un 409 al abrir su relé da la frecu por perdida.
- P158: una reconexión normal vuelve al final de la sucesión.
- P177 y P161: anuncios mDNS del que cede y del que recibe la frecu.
- P186: la notificación oculta el micrófono durante la espera del anfitrión.
- P162: dividir `room_repository_impl.dart` (961 líneas) y `room_page.dart`, y devolver los `switch` exhaustivos sobre `SignalingMessage`.
