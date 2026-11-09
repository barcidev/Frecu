// F7 y F17: las frecus cercanas siguen al anuncio mDNS. Un `lost` quita la frecu por el nombre del servicio aunque no traiga anfitrión ni puerto; un `found` con el nombre de una frecu que ya estaba la sustituye con su TXT nuevo (otra frecu con el mismo nombre); la dirección es la IPv4 del anfitrión y su nombre `.local` solo es reserva. La búsqueda se detiene al dejar de escucharla y se reanuda desde cero; si no puede empezar, da un fallo de red y se puede reintentar. Anunciar y retirar el anuncio van en fila.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/lobby/data/datasources/mdns_datasource.dart';
import 'package:frecu/features/lobby/data/repositories/discovery_repository_impl.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nsd/nsd.dart' as nsd;

class _MockRegistration extends Mock implements nsd.Registration {}

class _MockDiscovery extends Mock implements nsd.Discovery {}

Uint8List _bytes(String value) => Uint8List.fromList(utf8.encode(value));

/// Servicio de una frecu tal como llega resuelto en un `found`.
nsd.Service _service({
  String? name = 'Frecu de Ana',
  String? roomId = 'room-1',
  String? txtName = 'Frecu de Ana',
  String? host = 'iPhone-de-Ana.local.',
  List<InternetAddress>? addresses,
  int? port = 47800,
  int? note,
}) => nsd.Service(
  name: name,
  type: '_frecu._tcp',
  host: host,
  port: port,
  addresses: addresses,
  txt: {
    if (roomId != null) 'roomId': _bytes(roomId),
    if (txtName != null) 'name': _bytes(txtName),
    'v': _bytes('1'),
    if (note != null) 'n': _bytes('$note'),
  },
);

void main() {
  late List<_MockDiscovery> discoveries;
  late int stopped;
  late void Function(nsd.Service, nsd.ServiceStatus) listener;
  Exception? startError;

  setUp(() {
    discoveries = [];
    stopped = 0;
    startError = null;
  });

  MdnsDataSource dataSource({
    Future<nsd.Registration> Function(nsd.Service)? register,
    Future<void> Function(nsd.Registration)? unregister,
  }) => MdnsDataSource(
    registerFn: register ?? (_) async => _MockRegistration(),
    unregisterFn: unregister ?? (_) async {},
    startDiscoveryFn:
        (
          serviceType, {
          bool autoResolve = true,
          nsd.IpLookupType ipLookupType = nsd.IpLookupType.none,
        }) async {
          final error = startError;
          if (error != null) throw error;
          final discovery = _MockDiscovery();
          when(() => discovery.addServiceListener(any())).thenAnswer((call) {
            listener =
                call.positionalArguments.first
                    as void Function(nsd.Service, nsd.ServiceStatus);
          });
          discoveries.add(discovery);
          return discovery;
        },
    stopDiscoveryFn: (_) async => stopped++,
  );

  /// Escucha las frecus de [repository] y devuelve cada lista emitida.
  Future<(List<List<NearbyRoom>>, StreamSubscription<List<NearbyRoom>>)> watch(
    DiscoveryRepositoryImpl repository, {
    List<Object>? errors,
  }) async {
    final emitted = <List<NearbyRoom>>[];
    final subscription = repository.watchNearbyRooms().listen(
      emitted.add,
      onError: (Object error) => errors?.add(error),
    );
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    return (emitted, subscription);
  }

  group('found y lost', () {
    test('un lost sin anfitrión ni puerto quita la frecu por el nombre del '
        'servicio', () async {
      final repository = DiscoveryRepositoryImpl(mdnsDataSource: dataSource());
      final (emitted, subscription) = await watch(repository);

      listener(_service(), nsd.ServiceStatus.found);
      await pumpEventQueue();
      expect(emitted.last.single.roomId, 'room-1');

      listener(
        const nsd.Service(name: 'Frecu de Ana', type: '_frecu._tcp'),
        nsd.ServiceStatus.lost,
      );
      await pumpEventQueue();
      expect(emitted.last, isEmpty);

      await subscription.cancel();
      await repository.dispose();
    });

    test('un found con el nombre de otra frecu ya cerrada la sustituye con '
        'su TXT nuevo', () async {
      final repository = DiscoveryRepositoryImpl(mdnsDataSource: dataSource());
      final (emitted, subscription) = await watch(repository);

      listener(_service(note: 10), nsd.ServiceStatus.found);
      listener(
        _service(name: 'Brigada', roomId: 'room-b', txtName: 'Brigada'),
        nsd.ServiceStatus.found,
      );
      await pumpEventQueue();
      expect(emitted.last.map((room) => room.roomId), ['room-1', 'room-b']);

      // La misma frecu (mismo nombre) se cerró y se abrió otra, con otra
      // nota, sin que llegara su lost.
      listener(_service(roomId: 'room-2', note: 3), nsd.ServiceStatus.found);
      await pumpEventQueue();

      expect(emitted.last.map((room) => room.roomId), ['room-b', 'room-2']);
      final reopened = emitted.last.last;
      expect(reopened.name, 'Frecu de Ana');
      expect(reopened.note, const RoomNote(semitone: 3));

      // Y su lost la quita a ella, no a la otra.
      listener(
        const nsd.Service(name: 'Frecu de Ana', type: '_frecu._tcp'),
        nsd.ServiceStatus.lost,
      );
      await pumpEventQueue();
      expect(emitted.last.map((room) => room.roomId), ['room-b']);

      await subscription.cancel();
      await repository.dispose();
    });

    test(
      'un found de la misma frecu actualiza sus datos en su lugar',
      () async {
        final repository = DiscoveryRepositoryImpl(
          mdnsDataSource: dataSource(),
        );
        final (emitted, subscription) = await watch(repository);

        listener(_service(note: 10), nsd.ServiceStatus.found);
        listener(
          _service(name: 'Brigada', roomId: 'room-b', txtName: 'Brigada'),
          nsd.ServiceStatus.found,
        );
        listener(_service(note: 4), nsd.ServiceStatus.found);
        await pumpEventQueue();

        expect(emitted.last.map((room) => room.roomId), ['room-1', 'room-b']);
        expect(emitted.last.first.note, const RoomNote(semitone: 4));

        await subscription.cancel();
        await repository.dispose();
      },
    );

    test('un lost de un servicio desconocido no cambia la lista', () async {
      final repository = DiscoveryRepositoryImpl(mdnsDataSource: dataSource());
      final (emitted, subscription) = await watch(repository);
      listener(_service(), nsd.ServiceStatus.found);
      await pumpEventQueue();
      final before = emitted.length;

      listener(
        const nsd.Service(name: 'Otra', type: '_frecu._tcp'),
        nsd.ServiceStatus.lost,
      );
      await pumpEventQueue();

      expect(emitted, hasLength(before));
      expect(emitted.last.single.roomId, 'room-1');

      await subscription.cancel();
      await repository.dispose();
    });
  });

  group('dirección del anfitrión', () {
    Future<NearbyRoom> discover(nsd.Service service) async {
      final repository = DiscoveryRepositoryImpl(mdnsDataSource: dataSource());
      final (emitted, subscription) = await watch(repository);
      listener(service, nsd.ServiceStatus.found);
      await pumpEventQueue();
      await subscription.cancel();
      await repository.dispose();
      return emitted.last.single;
    }

    test(
      'usa la IPv4 resuelta antes que el nombre .local del anfitrión',
      () async {
        final room = await discover(
          _service(
            host: 'MacBook-Pro-de-Jorge.local.',
            addresses: [
              InternetAddress('fe80::1c2a'),
              InternetAddress('169.254.10.4'),
              InternetAddress('192.168.43.27'),
            ],
          ),
        );

        expect(room.hostAddress, '192.168.43.27');
      },
    );

    test('sin IPv4 usa el nombre del anfitrión, sin el punto final', () async {
      final ipv6Only = await discover(
        _service(addresses: [InternetAddress('fe80::1c2a')]),
      );
      expect(ipv6Only.hostAddress, 'iPhone-de-Ana.local');

      final noAddresses = await discover(_service());
      expect(noAddresses.hostAddress, 'iPhone-de-Ana.local');
    });

    test(
      'sin nombre en el TXT ni en el servicio el nombre queda vacío',
      () async {
        final room = await discover(
          _service(
            name: null,
            txtName: null,
            addresses: [InternetAddress('192.168.43.27')],
          ),
        );

        expect(room.name, isEmpty);
        expect(room.roomId, 'room-1');
      },
    );
  });

  group('búsqueda', () {
    test('al escucharla busca y da las frecus que conoce; al dejarla se '
        'detiene y se vacía', () async {
      final repository = DiscoveryRepositoryImpl(mdnsDataSource: dataSource());
      final (emitted, subscription) = await watch(repository);

      expect(discoveries, hasLength(1));
      expect(emitted, [isEmpty]);

      listener(_service(), nsd.ServiceStatus.found);
      await pumpEventQueue();
      await subscription.cancel();
      await pumpEventQueue();

      expect(stopped, 1);

      // Reanudar busca de nuevo desde cero.
      final (again, resumed) = await watch(repository);
      expect(discoveries, hasLength(2));
      expect(again, [isEmpty]);

      await resumed.cancel();
      await repository.dispose();
    });

    test('si no puede empezar da un fallo de red y escucharla de nuevo '
        'reintenta', () async {
      startError = Exception('MissingPluginException');
      final repository = DiscoveryRepositoryImpl(mdnsDataSource: dataSource());
      final errors = <Object>[];
      final (emitted, subscription) = await watch(repository, errors: errors);

      expect(emitted, isEmpty);
      expect(errors.single, isA<Failure>());
      expect(errors.single, Failure.network(message: '$startError'));
      await subscription.cancel();

      startError = null;
      final (retried, again) = await watch(repository);
      expect(retried, [isEmpty]);
      expect(discoveries, hasLength(1));

      await again.cancel();
      await repository.dispose();
    });

    test('detener y reanudar seguidos dejan la búsqueda en marcha', () async {
      final mdns = dataSource();

      await mdns.startDiscovery();
      final stopping = mdns.stopDiscovery();
      final starting = mdns.startDiscovery();
      await Future.wait([stopping, starting]);

      expect(discoveries, hasLength(2));
      expect(stopped, 1);

      await mdns.dispose();
      expect(stopped, 2);
    });
  });

  group('anuncio', () {
    test('retirar el anuncio mientras se publica lo retira al terminar de '
        'publicar', () async {
      final registered = Completer<nsd.Registration>();
      final unregistered = <nsd.Registration>[];
      final mdns = dataSource(
        register: (_) => registered.future,
        unregister: (registration) async => unregistered.add(registration),
      );

      final publishing = mdns.publish(
        roomId: 'room-1',
        name: 'Frecu de Ana',
        port: 47800,
      );
      final stopping = mdns.stopPublishing();
      final registration = _MockRegistration();
      registered.complete(registration);
      await Future.wait([publishing, stopping]);

      expect(unregistered, [registration]);

      await mdns.dispose();
      expect(unregistered, [registration]);
    });
  });
}
