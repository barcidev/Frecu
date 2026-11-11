// AC9: CUANDO, en una frecu local en una Wi-Fi compartida, el anfitrión anterior vuelve con su frecu abierta o dos teléfonos llevan la misma frecu a la vez ENTONCES cada anfitrión pregunta con `host_probe` (código, turno, su id y su puerto) en las IPs de quienes salieron de su sucesión, y quien responde con el código correcto devuelve su propio `host_probe`. Gana el turno mayor y, a igual turno, el `peer_N` menor; el otro avisa a sus invitados `host_handover` con el id, la IP y el puerto del ganador, cierra su servidor sin `room_closed` y entra como invitado al ganador, sin volver a escribir el código. Emite un `HostChange` con razón `outranked` y quien la lleva, y ve el aviso «Volviste como invitado · «nombre» lleva la frecu», la cabecera «Anfitrión · «nombre»» y deja de llevar la frecu (su invitación es la del ganador). Sus invitados vuelven al ganador. Un `host_probe` con el código incorrecto se rechaza como un `join` incorrecto.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_handover.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
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

  group('AC9: el anterior vuelve como invitado', () {
    testWidgets('AC9: ve «Volviste como invitado · Ana lleva la frecu», la '
        'cabecera «Anfitrión · Ana» y deja de llevar la frecu', (tester) async {
      await enterRoom(tester, _room(hosting: true));
      expect(find.text('ERES EL ANFITRIÓN'), findsOneWidget);

      // Volvió a la frecu de Ana con un id nuevo.
      localId = 'peer_4';
      participants.add(const [
        Participant(id: 'peer_2', displayName: 'Ana', isHost: true),
        _leo,
        Participant(id: 'peer_4', displayName: 'Andrés'),
      ]);
      changes.add(
        const HostChange(
          hostId: 'peer_2',
          hostName: 'Ana',
          you: false,
          reason: HostChangeReason.outranked,
          hostAddress: '192.168.1.21',
          port: 47800,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text(
          'Volviste como invitado · Ana lleva la frecu',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('ANFITRIÓN · ANA'), findsOneWidget);
      expect(find.byKey(const Key('handover_received')), findsNothing);
      final room = container.read(roomNotifierProvider)!;
      expect(room.hosting, isFalse);
      expect(room.inherited, isFalse);
      expect(room.hostAddress, '192.168.1.21');
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    test(
      'AC9: el aviso tiene su texto en inglés, sin suponer género',
      () async {
        final en = await AppLocale.en.build();
        expect(
          en.room.handover.backAsGuest(name: 'Ana'),
          "You're back as a guest · Ana carries the frecu",
        );
      },
    );
  });
}
