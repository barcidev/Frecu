// AC1: CUANDO el anfitrión crea una frecu ENTONCES se publica el servicio mDNS `_frecu._tcp` con los atributos `roomId`, `name` y versión de protocolo `v`.
// AC2: CUANDO un participante abre el lobby en la misma red local ENTONCES descubre automáticamente las frecus activas anunciadas por mDNS y las muestra en la lista de frecus cercanas.
// AC3: CUANDO un participante selecciona una frecu descubierta e ingresa el código de acceso ENTONCES se conecta a la sala si el código es válido o recibe notificación de rechazo si es incorrecto.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/lobby/data/datasources/mdns_datasource.dart';
import 'package:frecu/features/lobby/data/repositories/discovery_repository_impl.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nsd/nsd.dart' as nsd;

class MockRegistration extends Mock implements nsd.Registration {}

class MockDiscovery extends Mock implements nsd.Discovery {}

void main() {
  group('DiscoveryRepository', () {
    late MockRegistration mockRegistration;
    late MockDiscovery mockDiscovery;
    late void Function(nsd.Service, nsd.ServiceStatus) serviceListener;
    nsd.Service? registeredService;
    var unregistered = false;

    setUp(() {
      mockRegistration = MockRegistration();
      mockDiscovery = MockDiscovery();
      unregistered = false;
      registeredService = null;

      when(() => mockDiscovery.addServiceListener(any()))
          .thenAnswer((invocation) {
            serviceListener =
                invocation.positionalArguments[0]
                    as void Function(nsd.Service, nsd.ServiceStatus);
          });
    });

    MdnsDataSource createDataSource() {
      return MdnsDataSource(
        registerFn: (service) async {
          registeredService = service;
          return mockRegistration;
        },
        unregisterFn: (registration) async {
          unregistered = true;
        },
        startDiscoveryFn:
            (
              serviceType, {
              bool autoResolve = true,
              nsd.IpLookupType ipLookupType = nsd.IpLookupType.v4,
            }) async {
              return mockDiscovery;
            },
        stopDiscoveryFn: (discovery) async {},
      );
    }

    // AC1
    test(
      'AC1: publishRoom registers mDNS service with roomId, name and version v',
      () async {
        final ds = createDataSource();
        final repository = DiscoveryRepositoryImpl(mdnsDataSource: ds);

        final result = await repository.publishRoom(
          roomId: 'room-123',
          name: 'Frecu Alpha',
          port: 47800,
        );

        expect(result.isSuccess, isTrue);
        expect(registeredService, isNotNull);
        expect(registeredService!.name, 'Frecu Alpha');
        expect(registeredService!.type, '_frecu._tcp');
        expect(registeredService!.port, 47800);

        final txt = registeredService!.txt!;
        expect(utf8.decode(txt['roomId']!), 'room-123');
        expect(utf8.decode(txt['name']!), 'Frecu Alpha');
        expect(utf8.decode(txt['v']!), '1');

        final stopResult = await repository.stopPublishing();
        expect(stopResult.isSuccess, isTrue);
        expect(unregistered, isTrue);

        await repository.dispose();
      },
    );

    // AC2
    test(
      'AC2: watchNearbyRooms discovers and emits nearby rooms from mDNS',
      () async {
        final ds = createDataSource();
        final repository = DiscoveryRepositoryImpl(mdnsDataSource: ds);

        final stream = repository.watchNearbyRooms();

        unawaited(
          expectLater(
            stream,
            emitsInOrder([
              predicate<List<NearbyRoom>>((list) {
                if (list.length != 1) return false;
                final room = list.first;
                return room.roomId == 'room-123' &&
                    room.name == 'Frecu Alpha' &&
                    room.hostAddress == '192.168.43.1' &&
                    room.port == 47800;
              }),
              isEmpty,
            ]),
          ),
        );

        await pumpEventQueue();

        final txt = <String, Uint8List?>{
          'roomId': Uint8List.fromList(utf8.encode('room-123')),
          'name': Uint8List.fromList(utf8.encode('Frecu Alpha')),
          'v': Uint8List.fromList(utf8.encode('1')),
        };

        final testService = nsd.Service(
          name: 'Frecu Alpha',
          type: '_frecu._tcp',
          host: '192.168.43.1',
          port: 47800,
          txt: txt,
        );

        serviceListener(testService, nsd.ServiceStatus.found);
        await pumpEventQueue();

        serviceListener(testService, nsd.ServiceStatus.lost);
        await pumpEventQueue();

        await repository.dispose();
      },
    );
  });
}
