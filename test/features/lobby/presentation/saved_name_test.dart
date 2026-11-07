// AC5: CUANDO el usuario se une a una frecu cercana con su código, por IP o escaneando un QR ENTONCES no se le pide el nombre y la unión usa el nombre guardado en ese momento (el último que cambió en Ajustes).
// AC6: CUANDO el usuario crea una frecu ENTONCES no se le pide el nombre y la frecu se abre con el nombre guardado como anfitrión.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/pages/scan_qr_page.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

/// Etiqueta del campo del nombre que el inicio ya no pide.
const _nameLabel = 'Tu nombre visible';

const _nearbyRoom = NearbyRoom(
  roomId: 'room-123',
  name: 'Ruta Sur',
  hostAddress: '192.168.43.1',
  port: 47800,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const RoomNote(semitone: 0));
  });

  group('Nombre guardado al crear o unirse a una frecu', () {
    late _MockDiscoveryRepository discoveryRepository;
    late _MockRoomRepository roomRepository;
    late _MockVoiceRepository voiceRepository;
    late StreamController<List<NearbyRoom>> nearbyRoomsController;

    final testRoom = Room(
      id: 'room-123',
      name: 'Ruta Sur',
      hostAddress: '192.168.43.1',
      port: 47800,
      accessCode: '1234',
      createdAt: DateTime(2026, 11, 8, 9),
    );

    setUp(() {
      discoveryRepository = _MockDiscoveryRepository();
      roomRepository = _MockRoomRepository();
      voiceRepository = _MockVoiceRepository();
      nearbyRoomsController = StreamController<List<NearbyRoom>>.broadcast();

      LocaleSettings.setLocale(AppLocale.es);
      // El nombre se guardó en el recorrido de la primera vez.
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            PreferencesRepositoryImpl.displayNameKey: 'Ana',
          });

      when(() => discoveryRepository.watchNearbyRooms())
          .thenAnswer((_) => nearbyRoomsController.stream);
      when(() => discoveryRepository.dispose()).thenAnswer((_) async {});
      when(
        () => discoveryRepository.publishRoom(
          roomId: any(named: 'roomId'),
          name: any(named: 'name'),
          port: any(named: 'port'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => const Result.success(null));

      when(() => roomRepository.getLocalIpAddress())
          .thenAnswer((_) async => '192.168.43.1');
      when(() => roomRepository.watchStatus())
          .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
      when(() => roomRepository.watchParticipants())
          .thenAnswer((_) => Stream.value([]));
      when(
        () => roomRepository.createRoom(
          name: any(named: 'name'),
          accessCode: any(named: 'accessCode'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => Result.success(testRoom));
      when(
        () => roomRepository.joinRoom(
          hostAddress: any(named: 'hostAddress'),
          port: any(named: 'port'),
          accessCode: any(named: 'accessCode'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => Result.success(testRoom));

      when(() => voiceRepository.initializeAudio())
          .thenAnswer((_) async => const Result.success(null));
      when(() => voiceRepository.watchIsTalking())
          .thenAnswer((_) => Stream.value(false));
      when(() => voiceRepository.watchSpeakingPeers())
          .thenAnswer((_) => Stream.value({}));
      when(() => voiceRepository.watchTalkMode())
          .thenAnswer((_) => Stream.value(TalkMode.pushToTalk));
    });

    tearDown(() async {
      await nearbyRoomsController.close();
    });

    /// Contenedor de la app con las preferencias ya leídas, como al arrancar.
    Future<ProviderContainer> appContainer() async {
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
          roomRepositoryProvider.overrideWithValue(roomRepository),
          voiceRepositoryProvider.overrideWithValue(voiceRepository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(preferencesProvider.future);
      return container;
    }

    Future<ProviderContainer> pumpWith(WidgetTester tester, Widget app) async {
      // El sintonizador del inicio anima sin fin: con movimiento reducido
      // queda quieto y pumpAndSettle termina.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final container = await appContainer();
      await tester.pumpWidget(
        TranslationProvider(
          child: UncontrolledProviderScope(container: container, child: app),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    Future<ProviderContainer> pumpApp(WidgetTester tester) =>
        pumpWith(tester, FrecuApp(appRouter: AppRouter()));

    Finder inDialog(Finder finder) =>
        find.descendant(of: find.byType(AlertDialog), matching: finder);

    /// El diálogo abierto no tiene campo para el nombre.
    void expectNoNameField() {
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(_nameLabel), findsNothing);
      expect(
        inDialog(find.widgetWithText(TextField, 'Participante')),
        findsNothing,
      );
    }

    Future<void> joinByIp(WidgetTester tester) async {
      await tester.tap(find.text(t.lobby.joinRoom));
      await tester.pumpAndSettle();
      expectNoNameField();
      await tester.tap(inDialog(find.byType(FilledButton)));
      await tester.pumpAndSettle();
    }

    void verifyJoinedAs(String displayName) {
      verify(
        () => roomRepository.joinRoom(
          hostAddress: any(named: 'hostAddress'),
          port: any(named: 'port'),
          accessCode: any(named: 'accessCode'),
          displayName: displayName,
        ),
      ).called(1);
    }

    testWidgets(
      'AC5: unirse a una frecu cercana con su código usa el nombre guardado '
      'sin pedirlo',
      (tester) async {
        await pumpApp(tester);
        nearbyRoomsController.add([_nearbyRoom]);
        await tester.pumpAndSettle();

        await tester.tap(find.text(_nearbyRoom.name));
        await tester.pumpAndSettle();

        expectNoNameField();
        expect(inDialog(find.text(t.lobby.accessCode)), findsOneWidget);
        expect(inDialog(find.byType(TextField)), findsOneWidget);

        await tester.tap(find.byKey(const Key('pin_join_button')));
        await tester.pumpAndSettle();

        verifyJoinedAs('Ana');
      },
    );

    testWidgets('AC5: unirse por IP usa el nombre guardado sin pedirlo', (
      tester,
    ) async {
      await pumpApp(tester);

      await joinByIp(tester);

      verifyJoinedAs('Ana');
    });

    testWidgets('AC5: unirse escaneando un QR usa el nombre guardado', (
      tester,
    ) async {
      void Function(String)? triggerScan;
      await pumpWith(
        tester,
        MaterialApp(
          home: ScanQrPage(
            scannerBuilder: (context, onScan) {
              triggerScan = onScan;
              return const SizedBox(key: Key('scanner_stub'));
            },
          ),
        ),
      );

      triggerScan!('frecu://join?h=192.168.1.100&p=47800&r=room-qr&c=4321');
      await tester.pumpAndSettle();

      verify(
        () => roomRepository.joinRoom(
          hostAddress: '192.168.1.100',
          port: 47800,
          accessCode: '4321',
          displayName: 'Ana',
        ),
      ).called(1);
    });

    testWidgets('AC5: la unión usa el último nombre que se cambió en Ajustes', (
      tester,
    ) async {
      final container = await pumpApp(tester);

      await container.read(preferencesProvider.notifier).setDisplayName('Bea');
      await tester.pumpAndSettle();
      await joinByIp(tester);

      verifyJoinedAs('Bea');
    });

    testWidgets(
      'AC6: crear una frecu la abre con el nombre guardado como anfitrión '
      'sin pedirlo',
      (tester) async {
        await pumpApp(tester);

        await tester.tap(find.text(t.lobby.createRoom));
        await tester.pumpAndSettle();

        expect(find.text(_nameLabel), findsNothing);

        await tester.tap(find.widgetWithText(FilledButton, t.lobby.createRoom));
        await tester.pumpAndSettle();

        verify(
          () => roomRepository.createRoom(
            name: any(named: 'name'),
            accessCode: any(named: 'accessCode'),
            displayName: 'Ana',
          ),
        ).called(1);
      },
    );
  });
}
