// AC1: CUANDO el anfitrión crea una frecu ENTONCES se publica el servicio mDNS `_frecu._tcp` con los atributos `roomId`, `name` y versión de protocolo `v`.
// AC2: CUANDO un participante abre el lobby en la misma red local ENTONCES descubre automáticamente las frecus activas anunciadas por mDNS y las muestra en la lista de frecus cercanas.
// AC3: CUANDO un participante selecciona una frecu descubierta e ingresa el código de acceso ENTONCES se conecta a la sala si el código es válido o recibe notificación de rechazo si es incorrecto.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/domain/usecases/discovery_usecases.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

void main() {
  group('Discovery use cases', () {
    late MockDiscoveryRepository repository;

    setUp(() {
      repository = MockDiscoveryRepository();
    });

    const testRoom = NearbyRoom(
      roomId: 'room-123',
      name: 'Frecu Alpha',
      hostAddress: '192.168.43.1',
      port: 47800,
    );

    // AC1
    test('AC1: PublishRoom use case calls repository publishRoom', () async {
      when(
        () => repository.publishRoom(
          roomId: any(named: 'roomId'),
          name: any(named: 'name'),
          port: any(named: 'port'),
        ),
      ).thenAnswer((_) async => const Result.success(null));

      when(() => repository.stopPublishing())
          .thenAnswer((_) async => const Result.success(null));

      final publishUseCase = PublishRoom(repository);
      final stopUseCase = StopPublishingRoom(repository);

      final publishResult = await publishUseCase(
        const PublishRoomParams(
          roomId: 'room-123',
          name: 'Frecu Alpha',
          port: 47800,
        ),
      );

      expect(publishResult.isSuccess, isTrue);
      verify(
        () => repository.publishRoom(
          roomId: 'room-123',
          name: 'Frecu Alpha',
          port: 47800,
        ),
      ).called(1);

      final stopResult = await stopUseCase(const NoParams());
      expect(stopResult.isSuccess, isTrue);
      verify(() => repository.stopPublishing()).called(1);
    });

    // AC2
    test(
      'AC2: DiscoverRooms use case calls repository watchNearbyRooms',
      () async {
        when(() => repository.watchNearbyRooms())
            .thenAnswer((_) => Stream.value([testRoom]));

        final discoverUseCase = DiscoverRooms(repository);
        final stream = discoverUseCase();

        expect(await stream.first, [testRoom]);
        verify(() => repository.watchNearbyRooms()).called(1);
      },
    );
  });
}
