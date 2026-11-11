// AC1: CUANDO el anfitrión toca «Abrir frecu» en la nueva frecu ENTONCES la frecu abierta lleva exactamente la nota que mostraba la pantalla en ese momento, aunque la hora haya cambiado desde que se calculó. La publica con esa nota en mDNS y se la da al servidor para `welcome`, y la cabecera de la frecu activa la muestra.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/new_room_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/fifths_clock.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/pages/room_page.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockNetworkRepository extends Mock implements NetworkRepository {}

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

/// Mi4 (330 Hz): la nota de las 04:30.
const _mi4 = RoomNote(semitone: 4);

/// Mi5 (659 Hz): la nota de las 16:24.
const _mi5 = RoomNote(semitone: 16);

/// Frecu que devuelve el repositorio, abierta a [createdAt] y sin nota: la
/// nota de la frecu abierta solo puede venir de la pantalla.
Room _opened(DateTime createdAt) => Room(
  id: 'room-123',
  name: 'Frecu de Ana',
  hostAddress: '192.168.43.1',
  port: 47800,
  accessCode: '4827',
  createdAt: createdAt,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const RoomNote(semitone: 0));
  });

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late _MockRoomRepository rooms;
  late _MockVoiceRepository voice;
  late StreamController<List<NearbyRoom>> nearby;
  late StreamController<NetworkState> networkStates;
  late DateTime now;

  final morning = DateTime(2026, 11, 8, 4, 30);
  final afternoon = DateTime(2026, 11, 8, 16, 24);

  void stubCreate(Room room) {
    when(
      () => rooms.createRoom(
        name: any(named: 'name'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Result.success(room));
  }

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    rooms = _MockRoomRepository();
    voice = _MockVoiceRepository();
    nearby = StreamController<List<NearbyRoom>>.broadcast();
    networkStates = StreamController<NetworkState>.broadcast();

    when(() => discovery.watchNearbyRooms()).thenAnswer((_) => nearby.stream);
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(
      () => discovery.publishRoom(
        roomId: any(named: 'roomId'),
        name: any(named: 'name'),
        port: any(named: 'port'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => network.watchNetworkState())
        .thenAnswer((_) => networkStates.stream);
    when(() => rooms.getLocalIpAddress())
        .thenAnswer((_) async => '192.168.43.1');
    when(() => rooms.watchStatus())
        .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
    when(() => rooms.watchParticipants()).thenAnswer((_) => Stream.value([]));
    when(() => voice.initializeAudio())
        .thenAnswer((_) async => const Result.success(null));
    when(() => voice.watchIsTalking()).thenAnswer((_) => Stream.value(false));
    when(() => voice.watchSpeakingPeers()).thenAnswer((_) => Stream.value({}));
    when(() => voice.watchTalkMode())
        .thenAnswer((_) => Stream.value(TalkMode.pushToTalk));
  });

  tearDown(() async {
    await nearby.close();
    await networkStates.close();
  });

  /// Abre la app con movimiento reducido y va a la nueva frecu por la guía,
  /// con el reloj de la pantalla en [now].
  Future<ProviderContainer> pumpNewRoom(WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(discovery),
        networkRepositoryProvider.overrideWithValue(network),
        roomRepositoryProvider.overrideWithValue(rooms),
        voiceRepositoryProvider.overrideWithValue(voice),
        newRoomClockProvider.overrideWithValue(() => now),
        accessCodeGeneratorProvider.overrideWithValue(() => '4827'),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: FrecuApp(appRouter: AppRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lobby.createRoom));
    await tester.pumpAndSettle();
    // Local, marcada: sigue a la guía.
    await tester.tap(find.text(t.lobby.newRoom.reach.kContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lobby.newRoom.guide.ready));
    await tester.pumpAndSettle();
    return container;
  }

  /// Comprueba que la frecu se creó, se publicó y se abrió con [note], y
  /// que la cabecera de la frecu activa la muestra con su [label].
  void expectOpenedWith(
    WidgetTester tester,
    ProviderContainer container,
    RoomNote note,
    String label,
  ) {
    verify(
      () => rooms.createRoom(
        name: any(named: 'name'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
        note: note,
      ),
    ).called(1);
    verify(
      () => discovery.publishRoom(
        roomId: 'room-123',
        name: 'Frecu de Ana',
        port: 47800,
        note: note,
      ),
    ).called(1);
    expect(container.read(roomNotifierProvider)?.note, note);
    expect(find.byType(RoomPage), findsOneWidget);
    expect(tester.widget<RoomNoteChip>(find.byType(RoomNoteChip)).note, note);
    expect(find.bySemanticsLabel(label), findsOneWidget);
  }

  group('Nota con la que se abre la nueva frecu', () {
    testWidgets('AC1: Abrir frecu abre en la nota que muestra la pantalla '
        'aunque la hora ya haya cambiado', (tester) async {
      now = morning;
      // La frecu creada lleva otra hora: su nota no puede salir de ella.
      stubCreate(_opened(afternoon));
      final container = await pumpNewRoom(tester);
      expect(tester.widget<FifthsClock>(find.byType(FifthsClock)).note, _mi4);

      // Cambia la hora, pero la pantalla aún no la ha releído.
      now = afternoon;
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<FifthsClock>(find.byType(FifthsClock)).note, _mi4);

      await tester.tap(find.text(t.lobby.newRoom.open));
      await tester.pumpAndSettle();

      expectOpenedWith(tester, container, _mi4, 'Nota Mi4, 330 Hz');
      await _unmountRoomPage(tester);
    });

    testWidgets('AC1: tras releer la hora Abrir frecu abre en la nota nueva '
        'que muestra', (tester) async {
      now = morning;
      stubCreate(_opened(morning));
      final container = await pumpNewRoom(tester);

      now = afternoon;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(tester.widget<FifthsClock>(find.byType(FifthsClock)).note, _mi5);

      await tester.tap(find.text(t.lobby.newRoom.open));
      await tester.pumpAndSettle();

      expectOpenedWith(tester, container, _mi5, 'Nota Mi5, 659 Hz');
      await _unmountRoomPage(tester);
    });
  });
}

/// La prueba termina dentro de la frecu: al desmontarse, `RoomPage` sale de
/// ella y Riverpod refresca a quien la mira. Se vacía antes de acabar para no
/// dejar temporizadores pendientes.
Future<void> _unmountRoomPage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
}
