// AC6: CUANDO el anfitrión de una frecu con traspaso toca Salir y hay alguien más ENTONCES ve «¿Qué pasa con la frecu?» con «Que siga sin mí» (marcada) y «Cerrarla para todos». Al seguir con la primera, ve «¿Quién lleva la frecu?» con los participantes y la persona que lleva más tiempo sugerida, y el botón «Pasar a «nombre» y salir». Si está solo, ve la hoja de cerrar de hoy.
// AC7: CUANDO el anfitrión de una frecu local en una Wi-Fi compartida pasa la frecu ENTONCES quien la recibe abre el servidor, sube el turno y ve «Ahora llevas la frecu. «anterior» te la pasó al salir.» con «Mostrar el QR». Los demás se reconectan a él con su mismo id y lugar, sin volver a escribir el código, y ven ««anterior» salió · «nombre» lleva ahora la frecu». La cabecera dice «Anfitrión · «nombre»», y quien la recibe ve «Llevas la frecu». Su QR es el nuevo (su IP).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_reach_step.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/pages/room_page.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/invite_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/leave_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/room_closed_view.dart';
import 'package:frecu/features/room/presentation/widgets/room_handover.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Repositorio de la frecu que también pasa la frecu.
class _MockRooms extends Mock implements RoomRepository, RoomHandover {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

class _ActiveRoom extends RoomNotifier {
  _ActiveRoom(this._room);

  final Room _room;

  @override
  Room? build() => _room;
}

const _ok = Result<void>.success(null);
const _andres = Participant(id: 'peer_1', displayName: 'Andrés', isHost: true);
const _ana = Participant(id: 'peer_2', displayName: 'Ana');
const _leo = Participant(id: 'peer_3', displayName: 'Leo');

/// Frecu local en la Wi-Fi de todos (su red no la crea el anfitrión).
Room _room({bool hosting = false}) => Room(
  id: 'room-123',
  name: 'Ruta 40',
  hostAddress: '192.168.1.20',
  port: 47800,
  accessCode: '4821',
  createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
  hosting: hosting,
);

/// Sucesión de Andrés, Ana (16:31) y Leo (16:40).
RoomSuccession _succession() => RoomSuccession(
  term: 1,
  handover: true,
  name: 'Ruta 40',
  accessCode: '4821',
  members: [
    RoomMember(
      id: 'peer_1',
      displayName: 'Andrés',
      joinedAt: DateTime(2026, 11, 11, 16, 20),
      address: '192.168.1.20',
    ),
    RoomMember(
      id: 'peer_2',
      displayName: 'Ana',
      joinedAt: DateTime(2026, 11, 11, 16, 31),
      address: '192.168.1.21',
    ),
    RoomMember(
      id: 'peer_3',
      displayName: 'Leo',
      joinedAt: DateTime(2026, 11, 11, 16, 40),
      address: '192.168.1.22',
    ),
  ],
);

void main() {
  setUpAll(() => registerFallbackValue(TalkMode.pushToTalk));

  late _MockRooms rooms;
  late _MockVoiceRepository voice;
  late StreamController<RoomStatus> status;
  late StreamController<List<Participant>> participants;
  late StreamController<HostChange> changes;
  late String localId;
  late ProviderContainer container;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    // El núcleo PTT, la malla y la línea del cierre animan sin fin: con
    // movimiento reducido quedan quietos y pumpAndSettle termina.
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
      ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    rooms = _MockRooms();
    voice = _MockVoiceRepository();
    status = StreamController<RoomStatus>.broadcast();
    participants = StreamController<List<Participant>>.broadcast();
    changes = StreamController<HostChange>.broadcast();
    localId = 'peer_1';

    when(() => rooms.watchStatus()).thenAnswer((_) => status.stream);
    when(() => rooms.watchParticipants())
        .thenAnswer((_) => participants.stream);
    when(() => rooms.localParticipantId).thenAnswer((_) => localId);
    when(() => rooms.leaveRoom()).thenAnswer((_) async => _ok);
    when(() => rooms.succession).thenAnswer((_) => _succession());
    when(() => rooms.watchSuccession())
        .thenAnswer((_) => Stream.value(_succession()));
    when(() => rooms.watchHostChanges()).thenAnswer((_) => changes.stream);
    when(() => rooms.handOver(any())).thenAnswer((_) async => _ok);
    when(() => voice.initializeAudio()).thenAnswer((_) async => _ok);
    when(() => voice.watchIsTalking()).thenAnswer((_) => const Stream.empty());
    when(() => voice.watchSpeakingPeers())
        .thenAnswer((_) => const Stream.empty());
    when(() => voice.watchTalkMode()).thenAnswer((_) => const Stream.empty());
    when(() => voice.watchAudioRoute())
        .thenAnswer((_) => const Stream<AudioRoute>.empty());
    when(() => voice.watchAvailableAudioRoutes())
        .thenAnswer((_) => const Stream.empty());
    when(() => voice.setTalkMode(any())).thenAnswer((_) async => _ok);
    when(() => voice.leaveMesh()).thenAnswer((_) async {});
    when(() => voice.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await status.close();
    await participants.close();
    await changes.close();
  });

  /// Entra a [active] con [people] conectados.
  Future<void> enterRoom(
    WidgetTester tester,
    Room active, {
    List<Participant> people = const [_andres, _ana, _leo],
  }) async {
    final router = AppRouter();
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            roomRepositoryProvider.overrideWithValue(rooms),
            voiceRepositoryProvider.overrideWithValue(voice),
            roomNotifierProvider.overrideWith(() => _ActiveRoom(active)),
          ],
          child: FrecuApp(appRouter: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(FrecuApp)),
    );
    unawaited(router.push(RoomRoute(roomId: 'room-123')));
    await tester.pumpAndSettle();
    status.add(const RoomStatus.connected());
    participants.add(people);
    await tester.pumpAndSettle();
  }

  Future<void> tapLeave(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('leave_button')));
    await tester.pumpAndSettle();
  }

  group('AC6: salir con traspaso', () {
    testWidgets('AC6: el anfitrión ve «¿Qué pasa con la frecu?» con «Que '
        'siga sin mí» marcada y «Cerrarla para todos»', (tester) async {
      await enterRoom(tester, _room(hosting: true));

      await tapLeave(tester);

      expect(find.byType(HandoverChoiceSheet), findsOneWidget);
      expect(find.byType(LeaveSheet), findsNothing);
      expect(find.text('¿Qué pasa con la frecu?'), findsOneWidget);
      expect(
        find.text('Llevas la frecu y hay 2 personas más.'),
        findsOneWidget,
      );
      final keep = tester.widget<RoomReachOption>(
        find.byKey(const Key('handover_keep')),
      );
      final close = tester.widget<RoomReachOption>(
        find.byKey(const Key('handover_close')),
      );
      expect(keep.title, 'Que siga sin mí');
      expect(keep.selected, isTrue);
      expect(close.title, 'Cerrarla para todos');
      expect(close.selected, isFalse);
      expect(find.text('Seguir'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('AC6: al seguir, ve «¿Quién lleva la frecu?» con quien lleva '
        'más tiempo sugerida, y pasa la frecu y sale', (tester) async {
      await enterRoom(tester, _room(hosting: true));
      await tapLeave(tester);

      await tester.tap(find.byKey(const Key('handover_next')));
      await tester.pumpAndSettle();

      expect(find.byType(HandoverPickSheet), findsOneWidget);
      expect(find.text('¿Quién lleva la frecu?'), findsOneWidget);
      expect(
        find.text('Esa persona muestra el QR y decide cuándo cerrarla.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('handover_peer_peer_2')), findsOneWidget);
      expect(find.byKey(const Key('handover_peer_peer_3')), findsOneWidget);
      expect(find.byKey(const Key('handover_peer_peer_1')), findsNothing);
      expect(find.text('LLEVA MÁS TIEMPO · SUGERIDA'), findsOneWidget);
      expect(find.text('DESDE LAS 16:40'), findsOneWidget);
      expect(find.text('Pasar a Ana y salir'), findsOneWidget);

      await tester.tap(find.byKey(const Key('handover_pass')));
      await tester.pumpAndSettle();

      verify(() => rooms.handOver('peer_2')).called(1);
      verifyNever(() => rooms.leaveRoom());
      expect(find.byType(RoomPage), findsNothing);
      expect(find.byType(RoomClosedView), findsNothing);
    });

    testWidgets('AC6: puede elegir a otra persona', (tester) async {
      await enterRoom(tester, _room(hosting: true));
      await tapLeave(tester);
      await tester.tap(find.byKey(const Key('handover_next')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('handover_peer_peer_3')));
      await tester.pumpAndSettle();

      expect(find.text('Pasar a Leo y salir'), findsOneWidget);
      await tester.tap(find.byKey(const Key('handover_pass')));
      await tester.pumpAndSettle();
      verify(() => rooms.handOver('peer_3')).called(1);
    });

    testWidgets('AC6: «Cerrarla para todos» cierra la frecu como hoy', (
      tester,
    ) async {
      await enterRoom(tester, _room(hosting: true));
      await tapLeave(tester);

      await tester.tap(find.byKey(const Key('handover_close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('handover_next')));
      await tester.pumpAndSettle();

      verifyNever(() => rooms.handOver(any()));
      verify(() => rooms.leaveRoom()).called(1);
      expect(find.byType(RoomClosedView), findsOneWidget);
    });

    testWidgets('AC6: el anfitrión solo ve la hoja de cerrar de hoy', (
      tester,
    ) async {
      await enterRoom(tester, _room(hosting: true), people: const [_andres]);

      await tapLeave(tester);

      expect(find.byType(LeaveSheet), findsOneWidget);
      expect(find.byType(HandoverChoiceSheet), findsNothing);
    });

    testWidgets('AC6: un invitado sale como hoy', (tester) async {
      localId = 'peer_3';
      await enterRoom(tester, _room());

      await tapLeave(tester);

      expect(find.byType(LeaveSheet), findsOneWidget);
      expect(find.byType(HandoverChoiceSheet), findsNothing);
    });
  });

  group('AC7: después del traspaso', () {
    testWidgets('AC7: los demás ven «Andrés salió · Ana lleva ahora la '
        'frecu», la cabecera con Ana y la invitación con su IP', (
      tester,
    ) async {
      localId = 'peer_3';
      await enterRoom(tester, _room());

      participants.add(const [
        Participant(id: 'peer_2', displayName: 'Ana', isHost: true),
        _leo,
      ]);
      changes.add(
        const HostChange(
          hostId: 'peer_2',
          hostName: 'Ana',
          you: false,
          reason: HostChangeReason.left,
          hostAddress: '192.168.1.21',
          port: 47800,
          previousHost: 'Andrés',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(
          'Andrés salió · Ana lleva ahora la frecu',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('ANFITRIÓN · ANA'), findsOneWidget);
      expect(container.read(roomNotifierProvider)!.hostAddress, '192.168.1.21');
      expect(container.read(roomNotifierProvider)!.hosting, isFalse);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('AC7: quien la recibe ve «Ahora llevas la frecu. Andrés te '
        'la pasó al salir.» con «Mostrar el QR» y «Llevas la frecu»', (
      tester,
    ) async {
      localId = 'peer_2';
      await enterRoom(tester, _room());

      participants.add(const [
        Participant(id: 'peer_2', displayName: 'Ana', isHost: true),
        _leo,
      ]);
      changes.add(
        const HostChange(
          hostId: 'peer_2',
          hostName: 'Ana',
          you: true,
          reason: HostChangeReason.left,
          hostAddress: '192.168.1.21',
          port: 47800,
          previousHost: 'Andrés',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ahora llevas la frecu. Andrés te la pasó al salir.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('LLEVAS LA FRECU'), findsOneWidget);
      expect(find.text('ERES EL ANFITRIÓN'), findsNothing);
      final room = container.read(roomNotifierProvider)!;
      expect(room.hosting, isTrue);
      expect(room.inherited, isTrue);
      expect(room.hostAddress, '192.168.1.21');

      await tester.tap(find.text('Mostrar el QR'));
      await tester.pumpAndSettle();
      expect(find.byType(InviteSheet), findsOneWidget);
    });
  });
}
