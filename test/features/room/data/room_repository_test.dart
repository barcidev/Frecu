// AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
// AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
// AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';

void main() {
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
  });
}
