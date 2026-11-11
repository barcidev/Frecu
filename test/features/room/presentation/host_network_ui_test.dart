// AC4: CUANDO la red de una frecu local la crea el anfitrión ENTONCES la hoja de salir solo ofrece «Cerrar frecu», con el texto «Tu teléfono es la red de la frecu. Si sales, la frecu se cierra para …». Si el anfitrión se cae, los invitados reintentan como hoy y, si no vuelve, la frecu se cierra con «Se perdió la red del anfitrión y no volvió.».
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/leave_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/room_closed_view.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

class _ActiveRoom extends RoomNotifier {
  _ActiveRoom(this._room);

  final Room _room;

  @override
  Room? build() => _room;
}

const _ok = Result<void>.success(null);
const _andres = Participant(
  id: 'peer-1',
  displayName: 'Andrés',
  isHost: true,
  ownsNetwork: true,
);
const _ana = Participant(id: 'peer-2', displayName: 'Ana');

/// Frecu local abierta hace un rato; [hostOwnsNetwork] si su red la crea
/// el teléfono del anfitrión.
Room _room({required bool hostOwnsNetwork}) => Room(
  id: 'room-123',
  name: 'Ruta 40',
  hostAddress: '192.168.43.1',
  port: 47800,
  accessCode: '4821',
  createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
  hostOwnsNetwork: hostOwnsNetwork,
);

const _lostNetwork =
    'Se perdió la red del anfitrión y no volvió. Puedes unirte a otra '
    'cuando quieras.';

/// La hoja de salir del anfitrión sola, con [others] personas más.
Future<void> _showSheet(
  WidgetTester tester, {
  required int others,
  bool hostNetwork = true,
}) => tester.pumpWidget(
  TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LeaveSheet(
            host: true,
            others: others,
            hostNetwork: hostNetwork,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() => registerFallbackValue(TalkMode.pushToTalk));
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('AC4: hoja de salir en la red del anfitrión', () {
    testWidgets('AC4: solo ofrece «Cerrar frecu» y dice que su teléfono es '
        'la red', (tester) async {
      await _showSheet(tester, others: 4);

      expect(find.text('Cerrar la frecu para todos'), findsOneWidget);
      expect(
        find.text(
          'Tu teléfono es la red de la frecu. Si sales, la frecu se cierra '
          'para las otras 4 personas.',
        ),
        findsOneWidget,
      );
      expect(find.byType(FrButton), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const Key('leave_confirm')),
          matching: find.text('Cerrar frecu'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('leave_cancel')), findsOneWidget);
      expect(find.text('Que siga sin mí'), findsNothing);
    });

    testWidgets('AC4: con una persona más o sola', (tester) async {
      await _showSheet(tester, others: 1);
      expect(
        find.text(
          'Tu teléfono es la red de la frecu. Si sales, la frecu se cierra '
          'para la otra persona.',
        ),
        findsOneWidget,
      );

      await _showSheet(tester, others: 0);
      expect(
        find.text(
          'Tu teléfono es la red de la frecu. Si sales, la frecu se cierra.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC4: sin la red del anfitrión la hoja sigue como hoy', (
      tester,
    ) async {
      await _showSheet(tester, others: 4, hostNetwork: false);

      expect(
        find.text(
          'Eres el anfitrión. Si sales, la frecu se cierra para las otras 4 '
          'personas.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Tu teléfono es la red'), findsNothing);
    });

    testWidgets('AC4: en inglés', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await _showSheet(tester, others: 2);

      expect(
        find.text(
          "Your phone is the frecu's network. If you leave, the frecu closes "
          'for the other 2 people.',
        ),
        findsOneWidget,
      );
    });
  });

  group('AC4: en la frecu', () {
    late _MockRoomRepository room;
    late _MockVoiceRepository voice;
    late StreamController<RoomStatus> status;
    late StreamController<List<Participant>> participants;
    late String localId;

    setUp(() {
      // El núcleo PTT, la malla y la línea del cierre animan sin fin: con
      // movimiento reducido quedan quietos y pumpAndSettle termina.
      final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
        ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      room = _MockRoomRepository();
      voice = _MockVoiceRepository();
      status = StreamController<RoomStatus>.broadcast();
      participants = StreamController<List<Participant>>.broadcast();
      localId = 'peer-2';

      when(() => room.watchStatus()).thenAnswer((_) => status.stream);
      when(() => room.watchParticipants())
          .thenAnswer((_) => participants.stream);
      when(() => room.localParticipantId).thenAnswer((_) => localId);
      when(() => room.leaveRoom()).thenAnswer((_) async => _ok);
      when(() => voice.initializeAudio()).thenAnswer((_) async => _ok);
      when(() => voice.watchIsTalking())
          .thenAnswer((_) => const Stream.empty());
      when(() => voice.watchSpeakingPeers())
          .thenAnswer((_) => const Stream.empty());
      when(() => voice.watchTalkMode()).thenAnswer((_) => const Stream.empty());
      when(() => voice.watchAudioRoute())
          .thenAnswer((_) => const Stream<AudioRoute>.empty());
      when(() => voice.watchAvailableAudioRoutes())
          .thenAnswer((_) => const Stream.empty());
      when(() => voice.setTalkMode(any())).thenAnswer((_) async => _ok);
      when(() => voice.dispose()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await status.close();
      await participants.close();
    });

    /// Entra a [active] con Andrés (anfitrión) y Ana conectados.
    Future<void> enterRoom(WidgetTester tester, Room active) async {
      final router = AppRouter();
      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(
            overrides: [
              roomRepositoryProvider.overrideWithValue(room),
              voiceRepositoryProvider.overrideWithValue(voice),
              roomNotifierProvider.overrideWith(() => _ActiveRoom(active)),
            ],
            child: FrecuApp(appRouter: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(router.push(RoomRoute(roomId: 'room-123')));
      await tester.pumpAndSettle();
      status.add(const RoomStatus.connected());
      participants.add(const [_andres, _ana]);
      await tester.pumpAndSettle();
    }

    testWidgets('AC4: el anfitrión que es la red ve que la frecu se cierra '
        'para la otra persona y la cierra', (tester) async {
      localId = 'peer-1';
      await enterRoom(tester, _room(hostOwnsNetwork: true));

      await tester.tap(find.byKey(const Key('leave_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LeaveSheet), findsOneWidget);
      expect(
        find.text(
          'Tu teléfono es la red de la frecu. Si sales, la frecu se cierra '
          'para la otra persona.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('leave_confirm')));
      await tester.pumpAndSettle();

      verify(() => room.leaveRoom()).called(1);
      expect(find.byType(RoomClosedView), findsOneWidget);
    });

    testWidgets('AC4: si el anfitrión que es la red se cae, el invitado '
        'reintenta y, si no vuelve, ve que se perdió su red', (tester) async {
      await enterRoom(tester, _room(hostOwnsNetwork: true));

      status.add(const RoomStatus.reconnecting());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RoomClosedView), findsNothing);
      verifyNever(() => room.leaveRoom());

      status.add(const RoomStatus.closed(reason: 'host_unreachable'));
      await tester.pumpAndSettle();

      expect(find.byType(RoomClosedView), findsOneWidget);
      expect(find.text(_lostNetwork), findsOneWidget);
      verify(() => room.leaveRoom()).called(1);
    });

    testWidgets('AC4: en una Wi-Fi compartida el cierre por caída sigue '
        'como hoy', (tester) async {
      await enterRoom(tester, _room(hostOwnsNetwork: false));

      status.add(const RoomStatus.closed(reason: 'host_unreachable'));
      await tester.pumpAndSettle();

      expect(find.text(_lostNetwork), findsNothing);
      expect(
        find.text(
          'Se perdió la señal del anfitrión. Puedes unirte a otra cuando '
          'quieras.',
        ),
        findsOneWidget,
      );
    });
  });
}
