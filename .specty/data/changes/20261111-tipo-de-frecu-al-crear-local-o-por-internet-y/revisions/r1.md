---
kind: standard
epic: 20261111-tipo-de-frecu-y-traspaso
slice: C1
---

# Tipo de frecu al crear (Local o Por internet) y sin mezcla

## Objetivo

Una frecu es **Local** (todos en la misma Wi-Fi, sin internet) o **Por internet** (desde cualquier lugar con el QR o el enlace), y las dos formas ya no se mezclan: una frecu local no abre el relé de la nube, y una por internet no invita por IP, no se anuncia en la red local y no necesita el aviso de frecu mezclada. Este corte deja el tipo en el dominio, el repositorio y la apertura de la frecu; el paso «¿Cómo se une tu grupo?» de la creación (AC1 de la épica) va en un corte aparte, porque con él el cambio pasa de 15 archivos y 2 módulos.

## Fuera de alcance

- El paso «¿Cómo se une tu grupo?», el orden de pasos de la creación, la etiqueta Local o Por internet de «Nueva frecu» y quitar el interruptor (AC1 de la épica): van en un corte nuevo de la épica, que también borra los textos que este corte deja sin uso.
- Traspaso de anfitrión, sucesión y turnos (cortes C2 a C7).
- Pasar una frecu de local a internet, o al revés, una vez abierta.
- Cambios en el Worker de la nube.
- Quitar la marca «Sin audio» de la malla para quien entró por internet: solo se quita el aviso «La red de Frecu no tiene internet».
- Cambiar el escáner: una invitación nueva por internet ya no trae IP, así que entra por la nube.

## Supuestos

- A1: El tipo de una frecu se deduce de su id de internet: con `internetId` es por internet y sin él es local. Así el invitado también conoce el tipo sin campos nuevos en el protocolo.
  - impacto: alto
- A2: Una invitación sin IP y con `x` se une por la nube en el escáner, como hoy (`_joinsByInternet`), y la de Bluetooth no se anuncia sin red de la frecu (`wifi`).
  - impacto: alto
- A3: Hasta que llegue el paso del tipo, el interruptor «Permitir internet» de «Nueva frecu» elige el tipo: encendido abre una frecu solo por internet.
- A4: Los textos y la rama de la hoja de invitar que quedan sin uso (`room.internet.*`, `room.sheets.invite.internet.andWifi`) se borran en el corte del paso del tipo; dejarlos un tiempo no rompe nada.

## Criterios de aceptación

- AC2: CUANDO la frecu es local ENTONCES no abre el relé de la nube, su invitación (QR, NFC, Bluetooth) no lleva id de internet ni enlace, y un QR por internet no permite entrar a ella.
- AC3: CUANDO la frecu es por internet ENTONCES todos los invitados entran por la nube, aunque estén en la misma Wi-Fi que el anfitrión. Su invitación no lleva IP local, no se anuncia por mDNS ni por Bluetooth, y ya no existe el aviso «La red de Frecu no tiene internet».

## Diseño

- **Dominio.** Nuevo `RoomReach { local, internet }` en `room_reach.dart`. `Room` gana el getter `reach` (por `internetId`, A1). `RoomRepository.createRoom`, `CreateRoomParams` y `RoomNotifier.createRoom` cambian `bool internet` por `RoomReach reach` (por defecto `local`).
- **Repositorio.** `createRoom(reach: internet)` deja la IP del anfitrión vacía, así la invitación (QR, NFC, hoja) no lleva `h` ni `p`, y abre el relé; `local` no lo abre ni crea `internetId`, así ninguna invitación lleva `x` ni enlace y la nube no conoce la frecu.
- **Nueva frecu.** `NewRoomStep` pasa `reach` (A3); por internet no pasa red a la frecu (sin `wifi`, Bluetooth no la anuncia y la invitación no lleva `ws`) ni la publica por mDNS.
- **Sin mezcla.** `RoomPage` deja el aviso `internet_cut_notice`.

## Archivos

- crear lib/features/room/domain/entities/room_reach.dart — tipo de frecu: local o por internet.
- modificar lib/features/room/domain/entities/room.dart — getter `reach`.
- modificar lib/features/room/domain/entities/room.freezed.dart — regenerado por build_runner.
- modificar lib/features/room/domain/repositories/room_repository.dart — `createRoom(reach:)`.
- modificar lib/features/room/domain/usecases/create_room.dart — `CreateRoomParams.reach`.
- modificar lib/features/room/data/repositories/room_repository_impl.dart — por internet sin IP local; local sin relé.
- modificar lib/features/room/presentation/providers/room_provider.dart — `createRoom(reach:)`.
- modificar lib/features/room/presentation/pages/room_page.dart — sin el aviso de frecu mezclada.
- modificar lib/features/lobby/presentation/widgets/new_room_step.dart — pasa el tipo; por internet sin red ni mDNS.
- modificar test/features/room/data/internet_room_test.dart — `reach`; local sin relé ni `x`; por internet sin IP.
- modificar test/features/room/presentation/internet_room_ui_test.dart — sin aviso de mezcla.
- modificar test/features/lobby/presentation/new_room_test.dart — `reach`; por internet sin red ni mDNS.

## Tareas

- [ ] T1: Tipo de frecu en el dominio y el repositorio
  - files: lib/features/room/domain/entities/room_reach.dart, lib/features/room/domain/entities/room.dart, lib/features/room/domain/entities/room.freezed.dart, lib/features/room/domain/repositories/room_repository.dart, lib/features/room/domain/usecases/create_room.dart, lib/features/room/data/repositories/room_repository_impl.dart, test/features/room/data/internet_room_test.dart
  - ac: AC2, AC3
  - verify: flutter test test/features/room/data/internet_room_test.dart
- [ ] T2: Nueva frecu por internet sin red ni mDNS
  - files: lib/features/room/presentation/providers/room_provider.dart, lib/features/lobby/presentation/widgets/new_room_step.dart, test/features/lobby/presentation/new_room_test.dart
  - ac: AC3
  - verify: flutter test test/features/lobby/presentation/new_room_test.dart
- [ ] T3: Sin aviso de frecu mezclada
  - files: lib/features/room/presentation/pages/room_page.dart, test/features/room/presentation/internet_room_ui_test.dart
  - ac: AC3
  - verify: flutter test test/features/room/presentation/internet_room_ui_test.dart

## Riesgos

- R1: Una invitación por internet de un anfitrión con versión anterior lleva IP y `x`: el escáner aún prueba la IP primero; es solo durante la transición.
- R2: El interruptor «Permitir internet» queda con su texto viejo («También pueden unirse desde lejos») hasta el corte del paso del tipo — es un estado intermedio en develop, sin publicar.
