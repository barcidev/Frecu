// AC4: CUANDO un séptimo participante intenta unirse a una frecu con 6 participantes activos ENTONCES el servidor de señalización rechaza la conexión con motivo `roomFull` y la aplicación del participante muestra la notificación de sala llena del prototipo («Esta frecu está llena (6/6).») sin borrar los dígitos.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/nearby_room_tile.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class MockRoomRepository extends Mock implements RoomRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Room full UI flow', () {
    late MockDiscoveryRepository discoveryRepository;
    late MockRoomRepository roomRepository;
    late StreamController<List<NearbyRoom>> nearbyRoomsController;

    const testNearbyRoom = NearbyRoom(
      roomId: 'room-full-123',
      name: 'Frecu Llena',
      hostAddress: '192.168.43.1',
      port: 47800,
    );

    setUp(() {
      discoveryRepository = MockDiscoveryRepository();
      roomRepository = MockRoomRepository();
      nearbyRoomsController = StreamController<List<NearbyRoom>>.broadcast();

      LocaleSettings.setLocale(AppLocale.es);

      when(() => discoveryRepository.watchNearbyRooms())
          .thenAnswer((_) => nearbyRoomsController.stream);
      when(() => discoveryRepository.dispose()).thenAnswer((_) async {});

      when(() => roomRepository.watchStatus()).thenAnswer(
        (_) => Stream.value(const RoomStatus.closed(reason: 'roomFull')),
      );
      when(() => roomRepository.watchParticipants())
          .thenAnswer((_) => Stream.value([]));
      when(
        () => roomRepository.joinRoom(
          hostAddress: any(named: 'hostAddress'),
          port: any(named: 'port'),
          accessCode: any(named: 'accessCode'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => const Result.failure(Failure.roomFull()));
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
          ],
          child: FrecuApp(appRouter: router),
        ),
      );
    }

    testWidgets(
      'AC4: LobbyPage displays roomFull localized notification when room is full',
      (tester) async {
        // El sintonizador del inicio anima sin fin: con movimiento reducido
        // queda quieto y pumpAndSettle termina.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        nearbyRoomsController.add([testNearbyRoom]);
        await tester.pumpAndSettle();

        // La frecu llena sale como tarjeta de frecu cercana del inicio.
        await tester.tap(find.widgetWithText(NearbyRoomTile, 'Frecu Llena'));
        await tester.pumpAndSettle();

        for (final digit in '1234'.split('')) {
          await tester.tap(find.byKey(ValueKey('fr-key-$digit')));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // El aviso de la hoja lleva el mensaje en negrita y la pista.
        expect(
          find.textContaining(
            'Esta frecu está llena (6/6).',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<FrPinField>(find.byType(FrPinField)).value,
          '1234',
        );
      },
    );
  });
}
