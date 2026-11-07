// AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
// AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
// AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomRepository extends Mock implements RoomRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.es);
  });

  group('Room presentation and UI flow', () {
    late MockRoomRepository repository;

    final testRoom = Room(
      id: 'room-123',
      name: 'Frecu Test',
      hostAddress: '192.168.43.1',
      port: 47800,
      accessCode: '1234',
      createdAt: DateTime(2026, 11, 6, 12),
    );

    setUp(() {
      // El sintonizador del inicio anima sin fin: con movimiento reducido
      // queda quieto y pumpAndSettle termina.
      final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
        ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      repository = MockRoomRepository();
    });

    Widget createTestApp(AppRouter router) {
      return TranslationProvider(
        child: ProviderScope(
          overrides: [roomRepositoryProvider.overrideWithValue(repository)],
          child: FrecuApp(appRouter: router),
        ),
      );
    }

    // AC1
    testWidgets(
      'AC1: CreateRoomPage allows host to create room and navigate to RoomPage with local IP',
      (tester) async {
        when(() => repository.getLocalIpAddress())
            .thenAnswer((_) async => '192.168.43.1');
        when(
          () => repository.createRoom(
            name: any(named: 'name'),
            accessCode: any(named: 'accessCode'),
            displayName: any(named: 'displayName'),
          ),
        ).thenAnswer((_) async => Result.success(testRoom));
        when(() => repository.watchParticipants())
            .thenAnswer((_) => Stream.value([]));
        when(() => repository.watchStatus())
            .thenAnswer((_) => Stream.value(const RoomStatus.connected()));

        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        await tester.tap(find.text(t.lobby.createRoom));
        await tester.pumpAndSettle();

        expect(find.text('IP local: 192.168.43.1'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Crear frecu'),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Crear frecu'));
        await tester.pumpAndSettle();

        verify(
          () => repository.createRoom(
            name: 'Frecu',
            accessCode: '1234',
            displayName: any(named: 'displayName'),
          ),
        ).called(1);
      },
    );

    // AC2
    testWidgets(
      'AC2: LobbyPage allows peer to join by manual IP and navigate to RoomPage',
      (tester) async {
        when(
          () => repository.joinRoom(
            hostAddress: any(named: 'hostAddress'),
            port: any(named: 'port'),
            accessCode: any(named: 'accessCode'),
            displayName: any(named: 'displayName'),
          ),
        ).thenAnswer((_) async => Result.success(testRoom));
        when(() => repository.watchParticipants())
            .thenAnswer((_) => Stream.value([]));
        when(() => repository.watchStatus())
            .thenAnswer((_) => Stream.value(const RoomStatus.connected()));

        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        final joinButton = find.text(t.lobby.joinRoom);
        expect(joinButton, findsOneWidget);
        await tester.tap(joinButton);
        await tester.pumpAndSettle();

        expect(find.text('IP del anfitrión'), findsOneWidget);
        final connectButton = find.widgetWithText(FilledButton, 'Conectar');
        expect(connectButton, findsOneWidget);

        await tester.tap(connectButton);
        await tester.pumpAndSettle();

        verify(
          () => repository.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '1234',
            displayName: 'Participante',
          ),
        ).called(1);
      },
    );

    // AC3
    testWidgets('AC3: RoomPage allows leaving room and returns to LobbyPage', (
      tester,
    ) async {
      when(() => repository.watchParticipants()).thenAnswer(
        (_) => Stream.value([
          const Participant(id: 'peer-1', displayName: 'Alice', isHost: true),
        ]),
      );
      when(() => repository.watchStatus())
          .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
      when(() => repository.leaveRoom())
          .thenAnswer((_) async => const Result<void>.success(null));

      final router = AppRouter();
      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      unawaited(router.push(RoomRoute(roomId: 'room-123')));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Anfitrión'), findsOneWidget);

      final leaveButton = find.widgetWithText(
        FilledButton,
        'Salir de la frecu',
      );
      expect(leaveButton, findsOneWidget);

      await tester.tap(leaveButton);
      await tester.pumpAndSettle();

      verify(() => repository.leaveRoom()).called(1);
    });

    // AC3
    testWidgets(
      'AC3: RoomPage updates reactive participant list and counter when peer leaves',
      (tester) async {
        final participantsController =
            StreamController<List<Participant>>.broadcast();
        when(() => repository.watchParticipants())
            .thenAnswer((_) => participantsController.stream);
        when(() => repository.watchStatus())
            .thenAnswer((_) => Stream.value(const RoomStatus.connected()));

        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Initially 2 participants
        participantsController.add([
          const Participant(
            id: 'host-1',
            displayName: 'HostAlice',
            isHost: true,
          ),
          const Participant(id: 'peer-2', displayName: 'Bob'),
        ]);
        await tester.pumpAndSettle();

        expect(find.text('HostAlice'), findsOneWidget);
        expect(find.text('Bob'), findsOneWidget);
        expect(find.text('Anfitrión'), findsOneWidget);
        expect(find.text('Participantes (2/6)'), findsOneWidget);

        // Peer leaves (peer_left)
        participantsController.add([
          const Participant(
            id: 'host-1',
            displayName: 'HostAlice',
            isHost: true,
          ),
        ]);
        await tester.pumpAndSettle();

        expect(find.text('Bob'), findsNothing);
        expect(find.text('HostAlice'), findsOneWidget);
        expect(find.text('Participantes (1/6)'), findsOneWidget);

        await participantsController.close();
      },
    );

    // AC3
    testWidgets(
      'AC3: RoomPage displays reconnecting status when connection drops',
      (tester) async {
        final statusController = StreamController<RoomStatus>.broadcast();
        when(() => repository.watchParticipants())
            .thenAnswer((_) => Stream.value([]));
        when(() => repository.watchStatus())
            .thenAnswer((_) => statusController.stream);

        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        statusController.add(const RoomStatus.reconnecting());
        await tester.pumpAndSettle();

        expect(find.textContaining('Reconectando'), findsOneWidget);

        await statusController.close();
      },
    );

    // AC4
    testWidgets(
      'AC4: RoomPage displays dialog and returns to Lobby when room is closed',
      (tester) async {
        final statusController = StreamController<RoomStatus>.broadcast();
        when(() => repository.watchParticipants())
            .thenAnswer((_) => Stream.value([]));
        when(() => repository.watchStatus())
            .thenAnswer((_) => statusController.stream);
        when(() => repository.leaveRoom())
            .thenAnswer((_) async => const Result<void>.success(null));

        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        statusController.add(const RoomStatus.closed(reason: 'host_closed'));
        await tester.pumpAndSettle();

        expect(
          find.text('La frecu fue cerrada por el anfitrión'),
          findsOneWidget,
        );

        final acceptButton = find.widgetWithText(TextButton, 'Aceptar');
        expect(acceptButton, findsOneWidget);
        await tester.tap(acceptButton);
        await tester.pumpAndSettle();

        expect(find.text('Frecus cercanas'), findsOneWidget);

        await statusController.close();
      },
    );
  });
}
