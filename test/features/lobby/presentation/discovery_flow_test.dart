// AC1: CUANDO el anfitrión crea una frecu ENTONCES se publica el servicio mDNS `_frecu._tcp` con los atributos `roomId`, `name` y versión de protocolo `v`.
// AC2: CUANDO un participante abre el lobby en la misma red local ENTONCES descubre automáticamente las frecus activas anunciadas por mDNS y las muestra en la lista de frecus cercanas.
// AC3: CUANDO un participante selecciona una frecu descubierta e ingresa el código de acceso ENTONCES se conecta a la sala si el código es válido o recibe notificación de rechazo si es incorrecto.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockRoomRepository extends Mock implements RoomRepository {}

class MockNetworkRepository extends Mock implements NetworkRepository {}

/// El sintonizador del inicio anima sin fin: con movimiento reducido queda
/// quieto y pumpAndSettle termina.
void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Discovery UI flow', () {
    late MockDiscoveryRepository discoveryRepository;
    late MockRoomRepository roomRepository;
    late MockNetworkRepository networkRepository;
    late StreamController<List<NearbyRoom>> nearbyRoomsController;

    const testNearbyRoom = NearbyRoom(
      roomId: 'room-123',
      name: 'Frecu mDNS',
      hostAddress: '192.168.43.1',
      port: 47800,
    );

    final testRoom = Room(
      id: 'room-123',
      name: 'Frecu mDNS',
      hostAddress: '192.168.43.1',
      port: 47800,
      accessCode: '1234',
      createdAt: DateTime(2026, 11, 6),
    );

    setUp(() {
      discoveryRepository = MockDiscoveryRepository();
      roomRepository = MockRoomRepository();
      networkRepository = MockNetworkRepository();
      nearbyRoomsController = StreamController<List<NearbyRoom>>.broadcast();

      LocaleSettings.setLocale(AppLocale.es);

      when(() => discoveryRepository.watchNearbyRooms())
          .thenAnswer((_) => nearbyRoomsController.stream);
      when(() => discoveryRepository.dispose()).thenAnswer((_) async {});
      // El inicio está en la red local del anfitrión.
      when(() => networkRepository.watchNetworkState()).thenAnswer(
        (_) => Stream.value(
          const NetworkState.connected(
            ipAddress: '192.168.43.27',
            interfaceName: 'wlan0',
            isHotspot: false,
          ),
        ),
      );

      when(() => roomRepository.watchStatus())
          .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
      when(() => roomRepository.watchParticipants())
          .thenAnswer((_) => Stream.value([]));
      when(
        () => roomRepository.joinRoom(
          hostAddress: any(named: 'hostAddress'),
          port: any(named: 'port'),
          accessCode: any(named: 'accessCode'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => Result.success(testRoom));
    });

    tearDown(() async {
      await nearbyRoomsController.close();
    });

    Widget createTestApp(AppRouter router) {
      return TranslationProvider(
        child: ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
            roomRepositoryProvider.overrideWithValue(roomRepository),
            networkRepositoryProvider.overrideWithValue(networkRepository),
          ],
          child: FrecuApp(appRouter: router),
        ),
      );
    }

    // AC2
    testWidgets('AC2: LobbyPage displays discovered nearby rooms from mDNS', (
      tester,
    ) async {
      reduceMotion(tester);
      final router = AppRouter();
      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      expect(find.text(t.lobby.empty.title), findsOneWidget);

      nearbyRoomsController.add([testNearbyRoom]);
      await tester.pumpAndSettle();

      expect(find.text('Frecu mDNS'), findsOneWidget);
      expect(find.text('192.168.43.1'), findsOneWidget);
    });

    // AC3
    testWidgets(
      'AC3: LobbyPage prompts for PIN and connects or handles rejection',
      (tester) async {
        reduceMotion(tester);
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        nearbyRoomsController.add([testNearbyRoom]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Frecu mDNS'));
        await tester.pumpAndSettle();

        expect(find.text('Unirse a Frecu mDNS'), findsOneWidget);
        expect(find.text(t.lobby.accessCode), findsOneWidget);

        final joinButton = find.byKey(const Key('pin_join_button'));
        expect(joinButton, findsOneWidget);

        await tester.tap(joinButton);
        await tester.pumpAndSettle();

        verify(
          () => roomRepository.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '1234',
            displayName: 'Participante',
          ),
        ).called(1);
      },
    );
  });
}
