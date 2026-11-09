// Ubicación (corte 4 de la épica de hardware V1): compartir es voluntario;
// al activarlo se pide el permiso y, sin él, no se comparte. Con posiciones
// propias y ajenas da la distancia y el rumbo, y avisa quién se quedó atrás.
// En la malla, la distancia va bajo el nombre y «Atrás» en ámbar.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/location/domain/entities/geo_point.dart';
import 'package:frecu/features/location/domain/repositories/location_repository.dart';
import 'package:frecu/features/location/presentation/location_labels.dart';
import 'package:frecu/features/location/presentation/providers/location_provider.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:frecu/features/permissions/domain/repositories/permission_repository.dart';
import 'package:frecu/features/permissions/presentation/providers/permission_provider.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh_scene.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockRooms extends Mock implements RoomRepository {}

class _FakeLocation implements LocationRepository {
  final StreamController<Map<String, GeoPoint>> peers =
      StreamController<Map<String, GeoPoint>>.broadcast();
  final StreamController<GeoPoint> own = StreamController<GeoPoint>.broadcast();
  bool sharing = false;

  @override
  bool get isSharing => sharing;

  @override
  Stream<Map<String, GeoPoint>> watchPeers() => peers.stream;

  @override
  Stream<GeoPoint> watchOwn() => own.stream;

  @override
  Future<Result<void>> startSharing() async {
    sharing = true;
    return const Result.success(null);
  }

  @override
  Future<void> stopSharing() async => sharing = false;
}

class _FakePermissions implements PermissionRepository {
  _FakePermissions(this.answer);

  final AppPermissionStatus answer;
  final List<AppPermission> requested = [];

  @override
  Future<Result<AppPermissionStatus>> checkStatus(AppPermission p) async =>
      Result.success(answer);

  @override
  Future<Result<AppPermissionStatus>> request(AppPermission p) async {
    requested.add(p);
    return Result.success(answer);
  }

  @override
  Future<Result<Map<AppPermission, AppPermissionStatus>>> requestAll(
    List<AppPermission> permissions,
  ) async => Result.success({for (final p in permissions) p: answer});

  @override
  Future<bool> openAppSettings() async => true;
}

/// Punto a tantos metros al norte de un origen en el ecuador (aprox.).
GeoPoint _north(double meters) => GeoPoint(lat: meters / 111195, lon: 0);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  late _FakeLocation location;

  ProviderContainer containerWith(AppPermissionStatus answer) {
    location = _FakeLocation();
    final rooms = _MockRooms();
    when(() => rooms.localParticipantId).thenReturn('me');
    final container = ProviderContainer(
      overrides: [
        locationRepositoryProvider.overrideWithValue(location),
        permissionRepositoryProvider.overrideWithValue(
          _FakePermissions(answer),
        ),
        roomRepositoryProvider.overrideWithValue(rooms),
      ],
    )..listen(locationSharingProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }

  test('sin permiso no comparte', () async {
    final container = containerWith(AppPermissionStatus.denied);

    final outcome = await container
        .read(locationSharingProvider.notifier)
        .setSharing(on: true);

    expect(outcome, ShareLocationOutcome.denied);
    expect(location.sharing, isFalse);
    expect(container.read(locationSharingProvider).sharing, isFalse);
  });

  test('negado para siempre pide ir a los ajustes', () async {
    final container = containerWith(AppPermissionStatus.permanentlyDenied);

    expect(
      await container
          .read(locationSharingProvider.notifier)
          .setSharing(on: true),
      ShareLocationOutcome.deniedForever,
    );
  });

  test('con permiso comparte y da distancia y rumbo a cada uno', () async {
    final container = containerWith(AppPermissionStatus.granted);
    final notifier = container.read(locationSharingProvider.notifier);

    expect(await notifier.setSharing(on: true), ShareLocationOutcome.sharing);
    location.own.add(_north(0));
    location.peers.add({'ana': _north(120)});
    await Future<void>.delayed(Duration.zero);

    final state = container.read(locationSharingProvider);
    expect(state.sharing, isTrue);
    final towards = state.towards('ana')!;
    expect(towards.meters, closeTo(120, 1));
    expect(towardsLabel(towards), '120 m N');

    await notifier.setSharing(on: false);
    expect(container.read(locationSharingProvider).own, isNull);
    expect(location.sharing, isFalse);
  });

  group('etiquetas', () {
    test('metros de 10 en 10 y kilómetros con un decimal', () {
      expect(distanceLabel(3), '10 m');
      expect(distanceLabel(124), '120 m');
      expect(distanceLabel(1240), '1,2 km');
    });

    test('en inglés, punto decimal y rumbos en inglés', () async {
      await LocaleSettings.setLocale(AppLocale.en);
      expect(distanceLabel(1240), '1.2 km');
      expect(compassLabel(225), 'SW');
      expect(compassLongLabel(270), 'west');
    });
  });

  group('malla', () {
    const ana = Participant(id: 'ana', displayName: 'Ana');
    const host = Participant(id: 'h', displayName: 'Andrés', isHost: true);

    test('la distancia va bajo el nombre; con el anfitrión, tras su papel', () {
      final nodes = buildMeshNodes(
        participants: const [ana, host],
        slots: const {'ana': 1, 'h': 2},
        localId: 'me',
        distances: const {'ana': '120 m N', 'h': '45 m NE'},
      );
      expect(nodes[1]!.distance, '120 m N');
      expect(meshCaption(nodes[1]!), MeshCaption.distance);
      expect(meshCaption(nodes[2]!), MeshCaption.hostDistance);
    });

    test('quien se quedó atrás dice «Atrás» y sus aristas van punteadas', () {
      final nodes = buildMeshNodes(
        participants: const [ana, host],
        slots: const {'ana': 1, 'h': 2},
        localId: 'me',
        distances: const {'ana': '850 m S'},
        behind: const {'ana'},
      );
      expect(meshCaption(nodes[1]!), MeshCaption.behind);
      expect(meshEdges(nodes).single.weak, isTrue);
    });
  });
}
