// AC3: CUANDO se construye el QR de una invitación con nota ENTONCES la URI es `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>&n=<semitono>`, y sin nota es la misma URI de antes sin `n`; CUANDO se escanea una URI con `n` entre 0 y 23 ENTONCES la invitación trae esa nota, y si `n` falta o es inválido la invitación es válida, sin nota y con los demás datos iguales.
// AC4: CUANDO el anfitrión abre una frecu ENTONCES su nota se calcula una vez con la hora local de apertura y las notas de las frecus cercanas descubiertas (si una ya usa la nota de su hora, toma la siguiente quinta libre), queda en la frecu activa y se publica con esa misma nota en el TXT de mDNS y en el QR de invitación.
// AC5: CUANDO un participante se une a una frecu descubierta por mDNS o escaneada por QR ENTONCES su frecu activa lleva la nota que trajo la invitación, sin recalcularla con su propia hora; si la invitación no trae nota, o se une por IP, la frecu activa queda sin nota y la unión funciona igual.
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
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const RoomNote(semitone: 0));
  });

  group('Nota de la frecu al crear, invitar y unirse', () {
    late _MockDiscoveryRepository discoveryRepository;
    late _MockRoomRepository roomRepository;
    late _MockVoiceRepository voiceRepository;
    late StreamController<List<NearbyRoom>> nearbyRoomsController;

    // Abierta a las 04:30 hora local: le toca Mi4 (semitono 4).
    final testRoom = Room(
      id: 'room-123',
      name: 'Frecu',
      hostAddress: '192.168.43.1',
      port: 47800,
      accessCode: '1234',
      createdAt: DateTime(2026, 11, 8, 4, 30),
    );

    setUp(() {
      discoveryRepository = _MockDiscoveryRepository();
      roomRepository = _MockRoomRepository();
      voiceRepository = _MockVoiceRepository();
      nearbyRoomsController = StreamController<List<NearbyRoom>>.broadcast();

      LocaleSettings.setLocale(AppLocale.es);

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
          .thenAnswer((_) => Stream.value(TalkMode.openMic));
    });

    tearDown(() async {
      await nearbyRoomsController.close();
    });

    Widget withProviders(Widget child) {
      return TranslationProvider(
        child: ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
            roomRepositoryProvider.overrideWithValue(roomRepository),
            voiceRepositoryProvider.overrideWithValue(voiceRepository),
          ],
          child: child,
        ),
      );
    }

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(withProviders(FrecuApp(appRouter: AppRouter())));
      await tester.pumpAndSettle();
    }

    Future<void Function(String)> pumpScanner(WidgetTester tester) async {
      void Function(String)? triggerScan;
      await tester.pumpWidget(
        withProviders(
          MaterialApp(
            home: ScanQrPage(
              scannerBuilder: (context, onScan) {
                triggerScan = onScan;
                return const SizedBox(key: Key('scanner_stub'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return triggerScan!;
    }

    Room? activeRoom(WidgetTester tester, Type widgetType) {
      final container = ProviderScope.containerOf(
        tester.element(find.byType(widgetType)),
      );
      return container.read(roomNotifierProvider);
    }

    Future<void> joinNearbyRoom(WidgetTester tester, NearbyRoom room) async {
      nearbyRoomsController.add([room]);
      await tester.pumpAndSettle();

      await tester.tap(find.text(room.name));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pin_join_button')));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'AC4: al crear la frecu calcula su nota con las frecus cercanas y la '
      'publica en el TXT de mDNS y en el QR',
      (tester) async {
        await pumpApp(tester);

        // Una frecu cercana ya usa Mi4, la nota de las 04:30: le toca Si4.
        nearbyRoomsController.add([
          const NearbyRoom(
            roomId: 'room-vecina',
            name: 'Frecu vecina',
            hostAddress: '192.168.43.20',
            port: 47800,
            note: RoomNote(semitone: 4),
          ),
        ]);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, t.lobby.createRoom));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, t.lobby.createRoom));
        await tester.pumpAndSettle();

        expect(
          activeRoom(tester, FrecuApp)?.note,
          const RoomNote(semitone: 11),
        );
        verify(
          () => discoveryRepository.publishRoom(
            roomId: 'room-123',
            name: 'Frecu',
            port: 47800,
            note: const RoomNote(semitone: 11),
          ),
        ).called(1);

        await tester.tap(find.byIcon(Icons.qr_code));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'frecu://join?h=192.168.43.1&p=47800&r=room-123&c=1234&n=11',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC5: al unirse a una frecu descubierta por mDNS la frecu activa lleva '
      'su nota sin recalcularla',
      (tester) async {
        await pumpApp(tester);

        await joinNearbyRoom(
          tester,
          const NearbyRoom(
            roomId: 'room-123',
            name: 'Frecu mDNS',
            hostAddress: '192.168.43.1',
            port: 47800,
            note: RoomNote(semitone: 21),
          ),
        );

        verify(
          () => roomRepository.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '1234',
            displayName: any(named: 'displayName'),
          ),
        ).called(1);
        expect(
          activeRoom(tester, FrecuApp)?.note,
          const RoomNote(semitone: 21),
        );
      },
    );

    testWidgets(
      'AC5: al unirse a una frecu descubierta sin nota la frecu activa queda '
      'sin nota y la unión funciona igual',
      (tester) async {
        await pumpApp(tester);

        await joinNearbyRoom(
          tester,
          const NearbyRoom(
            roomId: 'room-123',
            name: 'Frecu mDNS',
            hostAddress: '192.168.43.1',
            port: 47800,
          ),
        );

        expect(activeRoom(tester, FrecuApp), isNotNull);
        expect(activeRoom(tester, FrecuApp)?.note, isNull);
      },
    );

    testWidgets('AC5: al unirse por IP la frecu activa queda sin nota', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text(t.lobby.joinRoom));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conectar'));
      await tester.pumpAndSettle();

      verify(
        () => roomRepository.joinRoom(
          hostAddress: '192.168.43.1',
          port: 47800,
          accessCode: '1234',
          displayName: any(named: 'displayName'),
        ),
      ).called(1);
      expect(activeRoom(tester, FrecuApp), isNotNull);
      expect(activeRoom(tester, FrecuApp)?.note, isNull);
    });

    testWidgets('AC5: al escanear un QR con n la frecu activa lleva esa nota', (
      tester,
    ) async {
      final triggerScan = await pumpScanner(tester);

      triggerScan('frecu://join?h=192.168.43.1&p=47800&r=room-123&c=1234&n=7');
      await tester.pumpAndSettle();

      verify(
        () => roomRepository.joinRoom(
          hostAddress: '192.168.43.1',
          port: 47800,
          accessCode: '1234',
          displayName: any(named: 'displayName'),
        ),
      ).called(1);
      expect(activeRoom(tester, ScanQrPage)?.note, const RoomNote(semitone: 7));
    });

    testWidgets(
      'AC5: al escanear un QR sin n la frecu activa queda sin nota y la unión '
      'funciona igual',
      (tester) async {
        final triggerScan = await pumpScanner(tester);

        triggerScan('frecu://join?h=192.168.43.1&p=47800&r=room-123&c=1234');
        await tester.pumpAndSettle();

        verify(
          () => roomRepository.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '1234',
            displayName: any(named: 'displayName'),
          ),
        ).called(1);
        expect(activeRoom(tester, ScanQrPage), isNotNull);
        expect(activeRoom(tester, ScanQrPage)?.note, isNull);
      },
    );
  });
}
