// AC1: CUANDO el anfitrión publica su frecu con nota ENTONCES el TXT de mDNS lleva `n` con su semitono (por ejemplo `"16"` para Mi5) además de `roomId`, `name` y `v` = `"1"`; sin nota, el TXT tiene solo `roomId`, `name` y `v`, como antes.
// AC2: CUANDO un teléfono descubre por mDNS una frecu cuyo TXT trae `n` entre 0 y 23 ENTONCES la frecu cercana tiene esa nota, con el mismo nombre, octava y Hz que la del anfitrión; si `n` falta, está vacío, no es un entero o está fuera de 0–23, la frecu cercana aparece sin nota y con su `roomId`, nombre, dirección, puerto y versión intactos.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/lobby/data/datasources/mdns_datasource.dart';
import 'package:frecu/features/lobby/data/repositories/discovery_repository_impl.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/usecases/discovery_usecases.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nsd/nsd.dart' as nsd;

class _MockRegistration extends Mock implements nsd.Registration {}

class _MockDiscovery extends Mock implements nsd.Discovery {}

Uint8List _bytes(String value) => Uint8List.fromList(utf8.encode(value));

void main() {
  late _MockDiscovery discovery;
  late void Function(nsd.Service, nsd.ServiceStatus) serviceListener;
  nsd.Service? registeredService;

  setUp(() {
    discovery = _MockDiscovery();
    registeredService = null;

    when(() => discovery.addServiceListener(any())).thenAnswer((invocation) {
      serviceListener =
          invocation.positionalArguments[0]
              as void Function(nsd.Service, nsd.ServiceStatus);
    });
  });

  MdnsDataSource createDataSource() {
    return MdnsDataSource(
      registerFn: (service) async {
        registeredService = service;
        return _MockRegistration();
      },
      unregisterFn: (registration) async {},
      startDiscoveryFn:
          (
            serviceType, {
            bool autoResolve = true,
            nsd.IpLookupType ipLookupType = nsd.IpLookupType.v4,
          }) async {
            return discovery;
          },
      stopDiscoveryFn: (discovery) async {},
    );
  }

  Map<String, String?> registeredTxt() {
    return registeredService!.txt!.map(
      (key, value) => MapEntry(key, value == null ? null : utf8.decode(value)),
    );
  }

  /// Descubre un servicio con el [txt] dado y devuelve la frecu cercana.
  Future<NearbyRoom> discover(Map<String, Uint8List?> txt) async {
    final repository = DiscoveryRepositoryImpl(
      mdnsDataSource: createDataSource(),
    );
    final emitted = <List<NearbyRoom>>[];
    final subscription = repository.watchNearbyRooms().listen(emitted.add);
    await pumpEventQueue();

    serviceListener(
      nsd.Service(
        name: 'Frecu Alpha',
        type: '_frecu._tcp',
        host: '192.168.43.1',
        port: 47800,
        txt: txt,
      ),
      nsd.ServiceStatus.found,
    );
    await pumpEventQueue();

    await subscription.cancel();
    await repository.dispose();
    return emitted.last.single;
  }

  Map<String, Uint8List?> baseTxt() => {
    'roomId': _bytes('room-123'),
    'name': _bytes('Frecu Alpha'),
    'v': _bytes('1'),
  };

  group('Nota en el TXT de mDNS', () {
    test('AC1: publishRoom con nota publica n con su semitono junto a roomId, '
        'name y v', () async {
      final repository = DiscoveryRepositoryImpl(
        mdnsDataSource: createDataSource(),
      );

      final result = await repository.publishRoom(
        roomId: 'room-123',
        name: 'Frecu Alpha',
        port: 47800,
        note: const RoomNote(semitone: 16),
      );

      expect(result.isSuccess, isTrue);
      expect(registeredTxt(), {
        'roomId': 'room-123',
        'name': 'Frecu Alpha',
        'v': '1',
        'n': '16',
      });

      await repository.dispose();
    });

    test('AC1: publica n también en los extremos 0 (Do4) y 23 (Si5)', () async {
      final dataSource = createDataSource();

      await dataSource.publish(
        roomId: 'room-123',
        name: 'Frecu Alpha',
        port: 47800,
        note: const RoomNote(semitone: 0),
      );
      expect(registeredTxt()['n'], '0');

      await dataSource.publish(
        roomId: 'room-123',
        name: 'Frecu Alpha',
        port: 47800,
        note: const RoomNote(semitone: 23),
      );
      expect(registeredTxt()['n'], '23');

      await dataSource.dispose();
    });

    test('AC1: PublishRoom pasa la nota de sus parámetros al TXT', () async {
      final repository = DiscoveryRepositoryImpl(
        mdnsDataSource: createDataSource(),
      );

      final result = await PublishRoom(repository)(
        const PublishRoomParams(
          roomId: 'room-123',
          name: 'Frecu Alpha',
          port: 47800,
          note: RoomNote(semitone: 9),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(registeredTxt()['n'], '9');

      await repository.dispose();
    });

    test('AC1: sin nota el TXT tiene solo roomId, name y v, sin n', () async {
      final repository = DiscoveryRepositoryImpl(
        mdnsDataSource: createDataSource(),
      );

      final result = await repository.publishRoom(
        roomId: 'room-123',
        name: 'Frecu Alpha',
        port: 47800,
      );

      expect(result.isSuccess, isTrue);
      expect(registeredTxt(), {
        'roomId': 'room-123',
        'name': 'Frecu Alpha',
        'v': '1',
      });

      await repository.dispose();
    });

    test(
      'AC2: la frecu descubierta tiene la misma nota, octava y Hz que publicó '
      'el anfitrión',
      () async {
        const hostNote = RoomNote(semitone: 16);
        final host = DiscoveryRepositoryImpl(
          mdnsDataSource: createDataSource(),
        );
        await host.publishRoom(
          roomId: 'room-123',
          name: 'Frecu Alpha',
          port: 47800,
          note: hostNote,
        );
        final publishedTxt = registeredService!.txt!;
        await host.dispose();

        final room = await discover(publishedTxt);

        expect(room.note, hostNote);
        expect(room.note?.name, 'Mi');
        expect(room.note?.octave, 5);
        expect(room.note?.hz, closeTo(659.26, 0.01));
        expect(room.roomId, 'room-123');
        expect(room.name, 'Frecu Alpha');
      },
    );

    test('AC2: lee n en los extremos 0 (Do4) y 23 (Si5)', () async {
      final low = await discover({...baseTxt(), 'n': _bytes('0')});
      expect(low.note, const RoomNote(semitone: 0));

      final high = await discover({...baseTxt(), 'n': _bytes('23')});
      expect(high.note, const RoomNote(semitone: 23));
    });

    test('AC2: si n falta, está vacío, no es un entero o está fuera de 0–23 la '
        'frecu aparece sin nota y con lo demás intacto', () async {
      final cases = <String, Map<String, Uint8List?>>{
        'ausente': baseTxt(),
        'clave sin valor': {...baseTxt(), 'n': null},
        'vacío': {...baseTxt(), 'n': _bytes('')},
        'texto': {...baseTxt(), 'n': _bytes('Mi')},
        'decimal': {...baseTxt(), 'n': _bytes('4.5')},
        'negativo': {...baseTxt(), 'n': _bytes('-1')},
        'fuera de rango': {...baseTxt(), 'n': _bytes('24')},
        'bytes no UTF-8': {
          ...baseTxt(),
          'n': Uint8List.fromList([0xff, 0xfe]),
        },
      };

      for (final entry in cases.entries) {
        final room = await discover(entry.value);

        expect(room.note, isNull, reason: 'n ${entry.key}');
        expect(room.roomId, 'room-123', reason: 'n ${entry.key}');
        expect(room.name, 'Frecu Alpha', reason: 'n ${entry.key}');
        expect(room.hostAddress, '192.168.43.1', reason: 'n ${entry.key}');
        expect(room.port, 47800, reason: 'n ${entry.key}');
        expect(room.protocolVersion, 1, reason: 'n ${entry.key}');
      }
    });
  });
}
