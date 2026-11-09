// Ubicación (corte 4 de la épica de hardware V1): CUANDO alguien comparte
// su posición ENTONCES llega por `position` con su id; sin coordenadas o al
// salir deja de verse. CUANDO se comparte la propia ENTONCES se envía como
// mucho cada 5 s salvo que se mueva 20 m, el servicio en primer plano pasa a
// tipo ubicación y, al dejar de compartir, se avisa a la frecu.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/location/data/datasources/position_datasource.dart';
import 'package:frecu/features/location/data/repositories/location_repository_impl.dart';
import 'package:frecu/features/location/domain/entities/geo_point.dart';
import 'package:frecu/features/room/data/datasources/foreground_service_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignaling extends Mock implements SignalingClientDataSource {}

class _FakeForeground extends Fake implements ForegroundServiceDataSource {
  final List<bool> locationTypes = [];

  @override
  Future<void> setLocationActive({required bool active}) async =>
      locationTypes.add(active);
}

void main() {
  setUpAll(
    () => registerFallbackValue(const SignalingMessage.ping(timestamp: 0)),
  );

  late _MockSignaling signaling;
  late StreamController<SignalingMessage> incoming;
  late StreamController<GeoPoint> gps;
  late _FakeForeground foreground;
  late DateTime now;
  late List<SignalingMessage> sent;
  late LocationRepositoryImpl repository;

  setUp(() {
    signaling = _MockSignaling();
    incoming = StreamController<SignalingMessage>.broadcast();
    gps = StreamController<GeoPoint>.broadcast();
    foreground = _FakeForeground();
    now = DateTime(2026, 11, 9, 10);
    sent = [];
    when(() => signaling.messages).thenAnswer((_) => incoming.stream);
    when(() => signaling.isConnected).thenReturn(true);
    when(() => signaling.send(any())).thenAnswer((invocation) {
      sent.add(invocation.positionalArguments.single as SignalingMessage);
    });
    repository = LocationRepositoryImpl(
      PositionDataSource(positions: () => gps.stream),
      signaling,
      foreground,
      clock: () => now,
    );
  });

  tearDown(() async {
    await repository.dispose();
    await incoming.close();
    await gps.close();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test(
    'las posiciones de los demás llegan, se quitan y se olvidan al salir',
    () async {
      final seen = <Map<String, GeoPoint>>[];
      final sub = repository.watchPeers().listen(seen.add);

      incoming
        ..add(const SignalingMessage.position(peerId: 'ana', lat: 4, lon: -74))
        ..add(const SignalingMessage.position(peerId: 'leo', lat: 5, lon: -74));
      await flush();
      expect(seen.last.keys, {'ana', 'leo'});

      incoming.add(const SignalingMessage.position(peerId: 'ana'));
      await flush();
      expect(seen.last.keys, {'leo'});

      incoming.add(const SignalingMessage.peerLeft(peerId: 'leo'));
      await flush();
      expect(seen.last, isEmpty);
      await sub.cancel();
    },
  );

  test('comparte la propia con freno: cada 5 s o al moverse 20 m', () async {
    await repository.startSharing();
    expect(foreground.locationTypes, [true]);

    gps.add(const GeoPoint(lat: 4, lon: -74));
    await flush();
    // Quieto y enseguida: no se envía otra.
    now = now.add(const Duration(seconds: 1));
    gps.add(const GeoPoint(lat: 4.00001, lon: -74));
    await flush();
    // Se movió unos 33 m: se envía.
    now = now.add(const Duration(seconds: 1));
    gps.add(const GeoPoint(lat: 4.0003, lon: -74));
    await flush();
    // Quieto pero pasaron 5 s: se envía.
    now = now.add(const Duration(seconds: 5));
    gps.add(const GeoPoint(lat: 4.0003, lon: -74));
    await flush();

    final positions = sent.whereType<SignalingPositionMessage>().toList();
    expect(positions, hasLength(3));
    expect(positions.first.lat, 4);
  });

  test(
    'dejar de compartir avisa a la frecu y quita el tipo ubicación',
    () async {
      await repository.startSharing();
      await repository.stopSharing();

      final last = sent.whereType<SignalingPositionMessage>().last;
      expect(last.lat, isNull);
      expect(last.lon, isNull);
      expect(repository.isSharing, isFalse);
      expect(foreground.locationTypes, [true, false]);
    },
  );
}
