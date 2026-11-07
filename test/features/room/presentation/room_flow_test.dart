// AC1: CUANDO el anfitrión crea una frecu ENTONCES la sala se inicializa en el estado conectado, el servidor de señalización se activa y se muestra la IP local del anfitrión.
// AC2: CUANDO un participante ingresa la IP del anfitrión y el código de acceso ENTONCES se une a la sala mediante WebSocket y ambos teléfonos ven la lista actualizada de participantes.
// AC3: CUANDO un participante o el anfitrión abandona la sala ENTONCES la conexión se cierra limpiamente y se actualiza el estado de la sala en los participantes restantes.
// AC1 (C4): CUANDO el usuario está en una frecu activa ENTONCES ve la malla de 6 lugares con un nodo por participante, su firma, su nombre y su papel; la persona propia está en el lugar 0, quien llega toma el primer lugar libre y cada lugar vacío muestra «Libre», que al tocarlo abre la invitación QR.
// AC3 (C4): CUANDO la frecu está reconectando ENTONCES las etiquetas de la malla dicen «Reconectando».
// AC5 (C4): CUANDO la frecu activa tiene nota ENTONCES la cabecera muestra un chip con su frecuencia redondeada y la nota con su alteración y su octava, el nombre de la frecu y «Eres el anfitrión» o «Anfitrión · <nombre>»; en inglés la nota sale con su nombre en inglés; sin nota la cabecera se muestra sin chip.
// AC6 (C4): CUANDO el usuario está en la frecu activa ENTONCES la pantalla es un `FrScaffold` con la cabecera (ruta de audio, invitar y salir), la malla y los controles actuales, y salir funciona como antes.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/pages/room_page.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/widgets/room_mesh.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomRepository extends Mock implements RoomRepository {}

class _TestRoomNotifier extends RoomNotifier {
  _TestRoomNotifier(this._initialRoom);

  final Room _initialRoom;

  @override
  Room? build() => _initialRoom;
}

const andres = Participant(id: 'peer-1', displayName: 'Andrés', isHost: true);
const jorge = Participant(id: 'peer-2', displayName: 'Jorge');

void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

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
      repository = MockRoomRepository();
    });

    Widget createTestApp(AppRouter router, {Room? room}) {
      return TranslationProvider(
        child: ProviderScope(
          overrides: [
            roomRepositoryProvider.overrideWithValue(repository),
            if (room != null)
              roomNotifierProvider.overrideWith(() => _TestRoomNotifier(room)),
          ],
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

        await tester.tap(find.widgetWithText(FilledButton, 'Crear frecu'));
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

        final joinButton = find.widgetWithText(
          OutlinedButton,
          'Unirse a frecu',
        );
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

    // AC6
    testWidgets(
      'AC6: el botón salir de la cabecera abandona la frecu y vuelve al inicio',
      (tester) async {
        reduceMotion(tester);
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
        expect(find.text('ANFITRIÓN'), findsOneWidget);

        final leaveButton = find.byKey(const Key('leave_button'));
        expect(leaveButton, findsOneWidget);

        await tester.tap(leaveButton);
        await tester.pumpAndSettle();

        verify(() => repository.leaveRoom()).called(1);
        expect(find.text('Frecus cercanas'), findsOneWidget);
      },
    );

    // AC1
    testWidgets(
      'AC1: la frecu activa es un FrScaffold con la malla, la persona propia, '
      'el anfitrión y lugares libres que abren la invitación',
      (tester) async {
        reduceMotion(tester);
        when(() => repository.watchParticipants())
            .thenAnswer((_) => Stream.value(const [andres, jorge]));
        when(() => repository.watchStatus())
            .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
        when(() => repository.localParticipantId).thenReturn('peer-2');

        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router, room: testRoom));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(RoomPage),
            matching: find.byType(FrScaffold),
          ),
          findsOneWidget,
        );
        expect(find.byType(RoomMesh), findsOneWidget);
        expect(find.text('Jorge'), findsOneWidget);
        expect(find.text('TÚ'), findsOneWidget);
        expect(find.text('Andrés'), findsOneWidget);
        expect(find.text('ANFITRIÓN'), findsOneWidget);
        expect(find.text('Libre'), findsNWidgets(4));

        await tester.tap(find.byKey(const Key('mesh_free_slot_2')));
        await tester.pumpAndSettle();

        expect(find.text('Código QR de invitación'), findsOneWidget);
      },
    );

    // AC1
    testWidgets('AC1: cuando alguien se va su lugar de la malla queda libre', (
      tester,
    ) async {
      reduceMotion(tester);
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

      participantsController.add([
        const Participant(id: 'host-1', displayName: 'HostAlice', isHost: true),
        const Participant(id: 'peer-2', displayName: 'Bob'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('HostAlice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('ANFITRIÓN'), findsOneWidget);
      expect(find.text('Libre'), findsNWidgets(4));

      participantsController.add([
        const Participant(id: 'host-1', displayName: 'HostAlice', isHost: true),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Bob'), findsNothing);
      expect(find.text('HostAlice'), findsOneWidget);
      expect(find.text('Libre'), findsNWidgets(5));

      await participantsController.close();
    });

    // AC3
    testWidgets(
      'AC3: RoomPage muestra «Reconectando» en la malla cuando se cae la '
      'conexión',
      (tester) async {
        reduceMotion(tester);
        final statusController = StreamController<RoomStatus>.broadcast();
        when(() => repository.watchParticipants()).thenAnswer(
          (_) => Stream.value([
            const Participant(id: 'peer-1', displayName: 'Alice', isHost: true),
          ]),
        );
        when(() => repository.watchStatus())
            .thenAnswer((_) => statusController.stream);

        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        statusController.add(const RoomStatus.connected());
        await tester.pumpAndSettle();
        expect(find.text('RECONECTANDO'), findsNothing);

        statusController.add(const RoomStatus.reconnecting());
        await tester.pumpAndSettle();

        expect(find.text('RECONECTANDO'), findsOneWidget);

        await statusController.close();
      },
    );

    // AC5
    testWidgets(
      'AC5: la cabecera muestra la nota Mi4 con 330 Hz, el nombre de la frecu '
      'y que eres el anfitrión',
      (tester) async {
        reduceMotion(tester);
        final semantics = tester.ensureSemantics();
        when(() => repository.watchParticipants()).thenAnswer(
          (_) => Stream.value([
            const Participant(id: 'peer-1', displayName: 'Jorge', isHost: true),
          ]),
        );
        when(() => repository.watchStatus())
            .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
        when(() => repository.localParticipantId).thenReturn('peer-1');

        final router = AppRouter();
        await tester.pumpWidget(
          createTestApp(
            router,
            room: testRoom.copyWith(note: const RoomNote(semitone: 4)),
          ),
        );
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('room_note_chip')), findsOneWidget);
        expect(find.text('330 HZ'), findsOneWidget);
        expect(find.text('Mi'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.bySemanticsLabel('Nota Mi4, 330 Hz'), findsOneWidget);
        expect(find.text('Frecu Test'), findsOneWidget);
        expect(find.text('ERES EL ANFITRIÓN'), findsOneWidget);
        expect(find.text('TÚ · ANFITRIÓN'), findsOneWidget);

        semantics.dispose();
      },
    );

    // AC5
    testWidgets(
      'AC5: en inglés la nota sale con su nombre en inglés, F♯5 con 740 Hz',
      (tester) async {
        reduceMotion(tester);
        await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
        final semantics = tester.ensureSemantics();
        when(() => repository.watchParticipants())
            .thenAnswer((_) => Stream.value(const [andres, jorge]));
        when(() => repository.watchStatus())
            .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
        when(() => repository.localParticipantId).thenReturn('peer-2');

        final router = AppRouter();
        await tester.pumpWidget(
          createTestApp(
            router,
            room: testRoom.copyWith(note: const RoomNote(semitone: 18)),
          ),
        );
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        expect(find.text('740 HZ'), findsOneWidget);
        expect(find.text('F'), findsOneWidget);
        expect(find.text('♯'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.bySemanticsLabel('Note F♯5, 740 Hz'), findsOneWidget);
        expect(find.text('HOST · ANDRÉS'), findsOneWidget);

        semantics.dispose();
      },
    );

    // AC5
    testWidgets(
      'AC5: sin nota (unión por IP) la cabecera se muestra sin chip, con el '
      'nombre de la frecu y el anfitrión',
      (tester) async {
        reduceMotion(tester);
        when(() => repository.watchParticipants())
            .thenAnswer((_) => Stream.value(const [andres, jorge]));
        when(() => repository.watchStatus())
            .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
        when(() => repository.localParticipantId).thenReturn('peer-2');

        final router = AppRouter();
        await tester.pumpWidget(createTestApp(router, room: testRoom));
        await tester.pumpAndSettle();

        unawaited(router.push(RoomRoute(roomId: 'room-123')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('room_note_chip')), findsNothing);
        expect(find.textContaining('HZ'), findsNothing);
        expect(find.text('Frecu Test'), findsOneWidget);
        expect(find.text('ANFITRIÓN · ANDRÉS'), findsOneWidget);
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
