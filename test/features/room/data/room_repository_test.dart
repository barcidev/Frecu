// AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
// AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
// AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.
// F2: CUANDO la pantalla de la frecu se abre después del `welcome` ENTONCES recibe al instante los participantes y el estado actuales.
// F4: CUANDO se abre una frecu sin haber cerrado la anterior ENTONCES la anterior se cierra y la nueva usa su propio código.
// F9: CUANDO alguien se une ENTONCES la frecu lleva el nombre real.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:mocktail/mocktail.dart';

class MockForegroundServiceDataSource extends Mock
    implements ForegroundServiceDataSource {}

void main() {
  setUpAll(() => registerFallbackValue(ForegroundStatus.connected));

  group('RoomRepository integration', () {
    late SignalingServerDataSource hostServer;
    late SignalingClientDataSource hostClient;
    late RoomRepositoryImpl hostRepository;

    late SignalingServerDataSource peerServerStub;
    late SignalingClientDataSource peerClient;
    late RoomRepositoryImpl peerRepository;

    setUp(() {
      hostServer = SignalingServerDataSource();
      hostClient = SignalingClientDataSource();
      hostRepository = RoomRepositoryImpl(
        serverDataSource: hostServer,
        clientDataSource: hostClient,
        networkInterfacesProvider: () async => [],
      );

      peerServerStub = SignalingServerDataSource();
      peerClient = SignalingClientDataSource();
      peerRepository = RoomRepositoryImpl(
        serverDataSource: peerServerStub,
        clientDataSource: peerClient,
        networkInterfacesProvider: () async => [],
      );
    });

    tearDown(() async {
      await peerRepository.dispose();
      await hostRepository.dispose();
    });

    // AC1
    test(
      'AC1: createRoom starts signaling server and connects loopback client',
      () async {
        final statusCompleter = Completer<RoomStatus>();
        final sub = hostRepository.watchStatus().listen((status) {
          final isConnected = status.maybeWhen(
            connected: () => true,
            orElse: () => false,
          );
          if (isConnected && !statusCompleter.isCompleted) {
            statusCompleter.complete(status);
          }
        });

        final result = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );

        expect(result.isSuccess, isTrue);
        final room = result.dataOrNull!;
        expect(room.name, 'Moto Rutas');
        expect(room.accessCode, '1234');
        expect(room.port, greaterThan(0));

        final status = await statusCompleter.future.timeout(
          const Duration(seconds: 3),
        );
        expect(
          status.maybeWhen(connected: () => true, orElse: () => false),
          isTrue,
        );

        await sub.cancel();
      },
    );

    // AC2
    test(
      'AC2: joinRoom connects remote peer and synchronizes participant list',
      () async {
        final createResult = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );
        expect(createResult.isSuccess, isTrue);
        final room = createResult.dataOrNull!;

        final peerParticipantsCompleter = Completer<List<Participant>>();
        final peerSub = peerRepository.watchParticipants().listen((
          participants,
        ) {
          if (participants.length == 2 &&
              !peerParticipantsCompleter.isCompleted) {
            peerParticipantsCompleter.complete(participants);
          }
        });

        final joinResult = await peerRepository.joinRoom(
          hostAddress: '127.0.0.1',
          port: room.port,
          accessCode: '1234',
          displayName: 'PeerBob',
        );

        expect(joinResult.isSuccess, isTrue);

        final participants = await peerParticipantsCompleter.future.timeout(
          const Duration(seconds: 3),
        );
        expect(participants.length, 2);
        expect(participants.any((p) => p.displayName == 'HostAlice'), isTrue);
        expect(participants.any((p) => p.displayName == 'PeerBob'), isTrue);

        await peerSub.cancel();
      },
    );

    // AC3
    test(
      'AC3: leaveRoom closes connection and updates participant list',
      () async {
        final createResult = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );
        final room = createResult.dataOrNull!;

        await peerRepository.joinRoom(
          hostAddress: '127.0.0.1',
          port: room.port,
          accessCode: '1234',
          displayName: 'PeerBob',
        );

        final hostParticipantLeftCompleter = Completer<List<Participant>>();
        final hostSub = hostRepository.watchParticipants().listen((list) {
          if (list.length == 1 && !hostParticipantLeftCompleter.isCompleted) {
            hostParticipantLeftCompleter.complete(list);
          }
        });

        final leaveResult = await peerRepository.leaveRoom();
        expect(leaveResult.isSuccess, isTrue);

        final remaining = await hostParticipantLeftCompleter.future.timeout(
          const Duration(seconds: 3),
        );
        expect(remaining.length, 1);
        expect(remaining.first.displayName, 'HostAlice');

        await hostSub.cancel();
      },
    );

    // AC2
    test(
      'AC2: peer repository transitions to reconnecting when connection drops',
      () async {
        final createResult = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );
        final room = createResult.dataOrNull!;

        await peerRepository.joinRoom(
          hostAddress: '127.0.0.1',
          port: room.port,
          accessCode: '1234',
          displayName: 'PeerBob',
        );

        final reconnectingCompleter = Completer<void>();
        final sub = peerRepository.watchStatus().listen((status) {
          status.maybeWhen(
            reconnecting: (_, _) {
              if (!reconnectingCompleter.isCompleted) {
                reconnectingCompleter.complete();
              }
            },
            orElse: () {},
          );
        });

        // Simular caída abrupta desconectando el socket del cliente sin llamar a leaveRoom
        await peerClient.disconnect();

        await reconnectingCompleter.future.timeout(const Duration(seconds: 3));

        await sub.cancel();
      },
    );

    // AC3
    test('AC3: peer automatically reconnects with backoff and restores connected state when host is available', () async {
      final createResult = await hostRepository.createRoom(
        name: 'Moto Rutas',
        accessCode: '1234',
        displayName: 'HostAlice',
      );
      final room = createResult.dataOrNull!;

      await peerRepository.joinRoom(
        hostAddress: '127.0.0.1',
        port: room.port,
        accessCode: '1234',
        displayName: 'PeerBob',
      );

      final statusEvents = <RoomStatus>[];
      final sub = peerRepository.watchStatus().listen(statusEvents.add);

      // Provocar desconexión del cliente
      await peerClient.disconnect();

      // Esperar a que entre en reconnecting y luego vuelva a connected
      final reconnectedCompleter = Completer<void>();
      final subReconnected = peerRepository.watchStatus().listen((status) {
        status.maybeWhen(
          connected: () {
            if (statusEvents.any(
              (s) => s.maybeWhen(
                reconnecting: (_, _) => true,
                orElse: () => false,
              ),
            )) {
              if (!reconnectedCompleter.isCompleted) {
                reconnectedCompleter.complete();
              }
            }
          },
          orElse: () {},
        );
      });

      await reconnectedCompleter.future.timeout(const Duration(seconds: 5));

      await sub.cancel();
      await subReconnected.cancel();
    });

    // AC4
    test(
      'AC4: peer transitions to closed when host leaves or server stops',
      () async {
        final createResult = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );
        final room = createResult.dataOrNull!;

        await peerRepository.joinRoom(
          hostAddress: '127.0.0.1',
          port: room.port,
          accessCode: '1234',
          displayName: 'PeerBob',
        );

        final closedCompleter = Completer<String>();
        final sub = peerRepository.watchStatus().listen((status) {
          status.maybeWhen(
            closed: (reason) {
              if (!closedCompleter.isCompleted) {
                closedCompleter.complete(reason);
              }
            },
            orElse: () {},
          );
        });

        // Host sale de la frecu
        await hostRepository.leaveRoom();

        final reason = await closedCompleter.future.timeout(
          const Duration(seconds: 3),
        );
        expect(reason, isNotEmpty);

        await sub.cancel();
      },
    );

    // AC1: Foreground service integration
    test(
      'AC1: starts foreground service on createRoom and stops on leaveRoom',
      () async {
        final mockForeground = MockForegroundServiceDataSource();
        when(
          () => mockForeground.startService(
            roomName: any(named: 'roomName'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async {});
        when(mockForeground.stopService).thenAnswer((_) async {});

        final repo = RoomRepositoryImpl(
          serverDataSource: hostServer,
          clientDataSource: hostClient,
          foregroundServiceDataSource: mockForeground,
          networkInterfacesProvider: () async => [],
        );

        final createResult = await repo.createRoom(
          name: 'Frecu Foreground',
          accessCode: '9999',
          displayName: 'HostUser',
        );
        expect(createResult.isSuccess, isTrue);
        verify(
          () => mockForeground.startService(
            roomName: 'Frecu Foreground',
            status: ForegroundStatus.connected,
          ),
        ).called(1);

        await repo.leaveRoom();
        verify(mockForeground.stopService).called(1);
      },
    );

    // AC7
    test(
      'AC7: al crear la frecu localParticipantId es el peerId de la bienvenida '
      'y vuelve a null al salir',
      () async {
        expect(hostRepository.localParticipantId, isNull);

        final participantsCompleter = Completer<List<Participant>>();
        final sub = hostRepository.watchParticipants().listen((participants) {
          if (participants.isNotEmpty && !participantsCompleter.isCompleted) {
            participantsCompleter.complete(participants);
          }
        });

        final result = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );
        expect(result.isSuccess, isTrue);

        final participants = await participantsCompleter.future.timeout(
          const Duration(seconds: 3),
        );
        final localId = hostRepository.localParticipantId;
        expect(localId, isNotNull);
        final me = participants.singleWhere((p) => p.id == localId);
        expect(me.displayName, 'HostAlice');
        expect(me.isHost, isTrue);

        await hostRepository.leaveRoom();
        expect(hostRepository.localParticipantId, isNull);

        await sub.cancel();
      },
    );

    // AC7
    test(
      'AC7: al unirse localParticipantId es el id que el anfitrión asignó al '
      'participante propio',
      () async {
        final createResult = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );
        final room = createResult.dataOrNull!;

        final participantsCompleter = Completer<List<Participant>>();
        final sub = peerRepository.watchParticipants().listen((participants) {
          if (participants.length == 2 && !participantsCompleter.isCompleted) {
            participantsCompleter.complete(participants);
          }
        });

        final joinResult = await peerRepository.joinRoom(
          hostAddress: '127.0.0.1',
          port: room.port,
          accessCode: '1234',
          displayName: 'PeerBob',
        );
        expect(joinResult.isSuccess, isTrue);

        final participants = await participantsCompleter.future.timeout(
          const Duration(seconds: 3),
        );
        final localId = peerRepository.localParticipantId;
        expect(localId, isNotNull);
        expect(localId, isNot(hostRepository.localParticipantId));
        final me = participants.singleWhere((p) => p.id == localId);
        expect(me.displayName, 'PeerBob');
        expect(me.isHost, isFalse);

        await sub.cancel();
      },
    );

    // AC7
    test(
      'AC7: al reconectar localParticipantId pasa al nuevo peerId que asigna '
      'el anfitrión',
      () async {
        final createResult = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );
        final room = createResult.dataOrNull!;

        await peerRepository.joinRoom(
          hostAddress: '127.0.0.1',
          port: room.port,
          accessCode: '1234',
          displayName: 'PeerBob',
        );
        final firstId = peerRepository.localParticipantId;
        expect(firstId, isNotNull);

        var sawReconnecting = false;
        final reconnectedCompleter = Completer<void>();
        final sub = peerRepository.watchStatus().listen((status) {
          status.maybeWhen(
            reconnecting: (_, _) => sawReconnecting = true,
            connected: () {
              if (sawReconnecting && !reconnectedCompleter.isCompleted) {
                reconnectedCompleter.complete();
              }
            },
            orElse: () {},
          );
        });

        await peerClient.disconnect();
        await reconnectedCompleter.future.timeout(const Duration(seconds: 5));

        final newId = peerRepository.localParticipantId;
        expect(newId, isNotNull);
        expect(newId, isNot(firstId));

        await sub.cancel();
      },
    );

    // AC7
    test('AC7: cuando el anfitrión cierra la frecu localParticipantId del '
        'participante vuelve a null', () async {
      final createResult = await hostRepository.createRoom(
        name: 'Moto Rutas',
        accessCode: '1234',
        displayName: 'HostAlice',
      );
      final room = createResult.dataOrNull!;

      await peerRepository.joinRoom(
        hostAddress: '127.0.0.1',
        port: room.port,
        accessCode: '1234',
        displayName: 'PeerBob',
      );
      expect(peerRepository.localParticipantId, isNotNull);

      final closedCompleter = Completer<void>();
      final sub = peerRepository.watchStatus().listen((status) {
        status.maybeWhen(
          closed: (_) {
            if (!closedCompleter.isCompleted) closedCompleter.complete();
          },
          orElse: () {},
        );
      });

      await hostRepository.leaveRoom();
      await closedCompleter.future.timeout(const Duration(seconds: 5));

      expect(peerRepository.localParticipantId, isNull);

      await sub.cancel();
    });

    // AC7
    test(
      'AC7: si el anfitrión rechaza la unión localParticipantId queda en null',
      () async {
        final createResult = await hostRepository.createRoom(
          name: 'Moto Rutas',
          accessCode: '1234',
          displayName: 'HostAlice',
        );
        final room = createResult.dataOrNull!;

        final joinResult = await peerRepository.joinRoom(
          hostAddress: '127.0.0.1',
          port: room.port,
          accessCode: '0000',
          displayName: 'PeerBob',
        );

        expect(joinResult.isSuccess, isFalse);
        expect(peerRepository.localParticipantId, isNull);
      },
    );

    test(
      'AC3: client receives RoomNote from welcome message when joining room',
      () async {
        const expectedNote = RoomNote(semitone: 16);
        final createResult = await hostRepository.createRoom(
          name: 'Sala con Nota',
          accessCode: '1234',
          displayName: 'HostAlice',
          note: expectedNote,
        );
        expect(createResult.isSuccess, isTrue);
        final hostRoom = createResult.dataOrNull!;

        final joinResult = await peerRepository.joinRoom(
          hostAddress: '127.0.0.1',
          port: hostRoom.port,
          accessCode: '1234',
          displayName: 'PeerBob',
        );
        expect(joinResult.isSuccess, isTrue);
        final peerRoom = joinResult.dataOrNull!;
        expect(peerRoom.note, expectedNote);
      },
    );

    test(
      'AC4: host passes RoomNote on createRoom and signaling server conveys it',
      () async {
        const hostNote = RoomNote(semitone: 21);
        final createResult = await hostRepository.createRoom(
          name: 'Sala Nota Host',
          accessCode: '5678',
          displayName: 'HostAlice',
          note: hostNote,
        );
        expect(createResult.isSuccess, isTrue);
        final room = createResult.dataOrNull!;
        expect(room.note, hostNote);
      },
    );

    // F2
    test('F2: quien mira después del welcome recibe al instante los '
        'participantes y el estado actuales', () async {
      final created = await hostRepository.createRoom(
        name: 'Moto Rutas',
        accessCode: '1234',
        displayName: 'HostAlice',
      );
      final room = created.dataOrNull!;

      // La pantalla se abre después: antes, estos streams no repetían nada.
      final hostPeople = await hostRepository.watchParticipants().first.timeout(
        const Duration(seconds: 1),
      );
      expect(hostPeople.single.displayName, 'HostAlice');
      expect(hostPeople.single.id, hostRepository.localParticipantId);
      expect(hostPeople.single.isHost, isTrue);
      expect(
        await hostRepository.watchStatus().first.timeout(
          const Duration(seconds: 1),
        ),
        const RoomStatus.connected(),
      );

      await peerRepository.joinRoom(
        hostAddress: '127.0.0.1',
        port: room.port,
        accessCode: '1234',
        displayName: 'PeerBob',
      );
      final peerPeople = await peerRepository.watchParticipants().first.timeout(
        const Duration(seconds: 1),
      );
      expect(peerPeople.map((p) => p.displayName), ['HostAlice', 'PeerBob']);
      expect(
        await peerRepository.watchStatus().first.timeout(
          const Duration(seconds: 1),
        ),
        const RoomStatus.connected(),
      );
    });

    // F9
    test('F9: quien se une ve el nombre real de la frecu', () async {
      final created = await hostRepository.createRoom(
        name: 'Moto Rutas',
        accessCode: '1234',
        displayName: 'HostAlice',
      );

      final joined = await peerRepository.joinRoom(
        hostAddress: '127.0.0.1',
        port: created.dataOrNull!.port,
        accessCode: '1234',
        displayName: 'PeerBob',
      );

      expect(joined.dataOrNull?.name, 'Moto Rutas');
    });

    // F4
    test('F4: abrir otra frecu sin cerrar la anterior la cierra y la nueva '
        'usa su propio código', () async {
      final first = await hostRepository.createRoom(
        name: 'Vieja',
        accessCode: '1111',
        displayName: 'HostAlice',
      );
      expect(first.isSuccess, isTrue);

      final second = await hostRepository.createRoom(
        name: 'Nueva',
        accessCode: '2222',
        displayName: 'HostAlice',
      );
      expect(second.isSuccess, isTrue);
      final port = second.dataOrNull!.port;

      final stale = await peerRepository.joinRoom(
        hostAddress: '127.0.0.1',
        port: port,
        accessCode: '1111',
        displayName: 'PeerBob',
      );
      expect(stale.failureOrNull, const Failure.invalidAccessCode());

      final fresh = await peerRepository.joinRoom(
        hostAddress: '127.0.0.1',
        port: port,
        accessCode: '2222',
        displayName: 'PeerBob',
      );
      expect(fresh.dataOrNull?.name, 'Nueva');
      final people = await peerRepository.watchParticipants().first;
      expect(people.map((p) => p.displayName), ['HostAlice', 'PeerBob']);
    });
  });
}
