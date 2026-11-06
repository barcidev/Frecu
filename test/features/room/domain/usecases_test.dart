// AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
// AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
// AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/usecases/create_room.dart';
import 'package:frecu/features/room/domain/usecases/join_room.dart';
import 'package:frecu/features/room/domain/usecases/leave_room.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomRepository extends Mock implements RoomRepository {}

void main() {
  group('Room use cases', () {
    late MockRoomRepository repository;
    late CreateRoom createRoom;
    late JoinRoom joinRoom;
    late LeaveRoom leaveRoom;

    final testRoom = Room(
      id: 'test-room-1',
      name: 'Ruta 66',
      hostAddress: '192.168.43.1',
      port: 47800,
      accessCode: '1234',
      createdAt: DateTime(2026, 11, 6, 12),
    );

    setUp(() {
      repository = MockRoomRepository();
      createRoom = CreateRoom(repository);
      joinRoom = JoinRoom(repository);
      leaveRoom = LeaveRoom(repository);
    });

    // AC1
    test(
      'AC1: CreateRoom use case creates a room and returns success Result',
      () async {
        when(
          () => repository.createRoom(
            name: 'Ruta 66',
            accessCode: '1234',
            displayName: 'HostAlice',
          ),
        ).thenAnswer((_) async => Result.success(testRoom));

        const params = CreateRoomParams(
          name: 'Ruta 66',
          accessCode: '1234',
          displayName: 'HostAlice',
        );

        final result = await createRoom(params);

        expect(result, Result.success(testRoom));
        expect(result.dataOrNull?.hostAddress, '192.168.43.1');
        verify(
          () => repository.createRoom(
            name: 'Ruta 66',
            accessCode: '1234',
            displayName: 'HostAlice',
          ),
        ).called(1);
      },
    );

    // AC2
    test(
      'AC2: JoinRoom use case joins room with host address and access code',
      () async {
        when(
          () => repository.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '1234',
            displayName: 'PeerBob',
          ),
        ).thenAnswer((_) async => Result.success(testRoom));

        const params = JoinRoomParams(
          hostAddress: '192.168.43.1',
          accessCode: '1234',
          displayName: 'PeerBob',
        );

        final result = await joinRoom(params);

        expect(result, Result.success(testRoom));
        verify(
          () => repository.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '1234',
            displayName: 'PeerBob',
          ),
        ).called(1);
      },
    );

    // AC3
    test('AC3: LeaveRoom use case leaves the current room cleanly', () async {
      when(() => repository.leaveRoom())
          .thenAnswer((_) async => const Result<void>.success(null));

      final result = await leaveRoom(const NoParams());

      expect(result, const Result<void>.success(null));
      expect(result.isSuccess, isTrue);
      verify(() => repository.leaveRoom()).called(1);
    });
  });
}
