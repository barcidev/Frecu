// U1: CUANDO la frecu está abierta por internet ENTONCES bajo la malla se lee «Por internet» y quien entró desde lejos lleva «Por internet» bajo su nombre.
// U2: CUANDO el anfitrión invita a una frecu por internet ENTONCES la hoja dice «Escanea o comparte», la conexión es «Internet» y «Compartir enlace» comparte el enlace https con el código en el fragmento.
// U3: CUANDO este teléfono está en la red de la frecu sin internet y alguien que entró por internet no conecta ENTONCES su nombre dice «Sin audio» y un aviso explica que no se oirán.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/share_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

class _TestRoomNotifier extends RoomNotifier {
  _TestRoomNotifier(this._room);

  final Room _room;

  @override
  Room? build() => _room;
}

const _id = '0123456789abcdef0123456789abcdef';
const _cloud = CloudConfig('https://frecu.example.workers.dev');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRoomRepository rooms;
  late _MockVoiceRepository voice;
  late List<String> shared;

  final room = Room(
    id: 'room-1',
    name: 'Ruta',
    hostAddress: '',
    port: 47800,
    accessCode: '7788',
    createdAt: DateTime(2026, 11, 10),
    internetId: _id,
    hosting: true,
  );

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    rooms = _MockRoomRepository();
    voice = _MockVoiceRepository();
    shared = [];
    when(() => rooms.watchStatus())
        .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
    when(() => rooms.localParticipantId).thenReturn('peer_1');
    when(() => voice.initializeAudio())
        .thenAnswer((_) async => const Result.success(null));
    when(() => voice.watchIsTalking()).thenAnswer((_) => Stream.value(false));
    when(() => voice.watchSpeakingPeers()).thenAnswer((_) => Stream.value({}));
    when(() => voice.watchTalkMode())
        .thenAnswer((_) => Stream.value(TalkMode.pushToTalk));
    when(() => voice.setTalkMode(any()))
        .thenAnswer((_) async => const Result.success(null));
  });

  setUpAll(() => registerFallbackValue(TalkMode.pushToTalk));

  Future<void> pumpRoom(
    WidgetTester tester, {
    required Room active,
    required List<Participant> participants,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    when(() => rooms.watchParticipants())
        .thenAnswer((_) => Stream.value(participants));
    final router = AppRouter();
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            roomRepositoryProvider.overrideWithValue(rooms),
            voiceRepositoryProvider.overrideWithValue(voice),
            roomNotifierProvider.overrideWith(() => _TestRoomNotifier(active)),
            cloudConfigProvider.overrideWithValue(_cloud),
            shareTextProvider.overrideWithValue((text) async {
              shared.add(text);
            }),
          ],
          child: FrecuApp(appRouter: router),
        ),
      ),
    );
    unawaited(router.push(RoomRoute(roomId: active.id)));
    await tester.pumpAndSettle();
  }

  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('U1: an internet room is tagged and remote people say so', (
    tester,
  ) async {
    await pumpRoom(
      tester,
      active: room,
      participants: const [
        Participant(id: 'peer_1', displayName: 'Ana', isHost: true),
        Participant(id: 'peer_2', displayName: 'Beto', remote: true),
      ],
    );

    expect(find.byKey(const Key('internet_room_tag')), findsOneWidget);
    // La etiqueta bajo la malla y la leyenda de Beto.
    expect(find.text(t.room.mesh.internet.toUpperCase()), findsNWidgets(2));
    await leave(tester);
  });

  testWidgets('U2: the invite sheet shares the https link', (tester) async {
    await pumpRoom(
      tester,
      active: room,
      participants: const [
        Participant(id: 'peer_1', displayName: 'Ana', isHost: true),
        Participant(id: 'peer_2', displayName: 'Beto', remote: true),
      ],
    );

    await tester.tap(find.byKey(const Key('invite_button')));
    await tester.pumpAndSettle();

    final copy = t.room.sheets.invite.internet;
    expect(find.text(copy.title), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('invite_connection'))).data,
      copy.internet,
    );
    expect(find.byKey(const Key('invite_nfc')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('invite_share_button')));
    await tester.tap(find.byKey(const Key('invite_share_button')));
    await tester.pump();

    expect(shared, hasLength(1));
    expect(
      shared.single,
      contains('https://frecu.example.workers.dev/j/$_id#c=7788'),
    );
    await leave(tester);
  });

  testWidgets('U3: on the Frecu network without internet, unreachable '
      'remote people say «Sin audio» and a notice explains it', (tester) async {
    await pumpRoom(
      tester,
      active: room.copyWith(
        hosting: false,
        wifi: const WifiCredentials(ssid: 'DIRECT-frecu'),
      ),
      participants: const [
        Participant(id: 'peer_0', displayName: 'Ana', isHost: true),
        Participant(id: 'peer_1', displayName: 'Carla'),
        Participant(
          id: 'peer_2',
          displayName: 'Beto',
          remote: true,
          connectionState: PeerConnectionState.disconnected,
        ),
      ],
    );

    expect(find.byKey(const Key('internet_cut_notice')), findsOneWidget);
    expect(
      find.textContaining(
        t.room.internet.cutMessage(names: 'Beto'),
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.text(t.room.mesh.noAudio.toUpperCase()), findsOneWidget);
    await leave(tester);
  });
}
