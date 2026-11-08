// AC1: CUANDO el usuario toca Invitar en la cabecera o un lugar libre de la malla ENTONCES se abre la hoja de invitación con el QR, la nota, el código, la IP y el puerto; CUANDO toca Cerrar ENTONCES se cierra y sigue en la frecu.
// AC2: CUANDO está en la frecu activa ENTONCES la cabecera lleva solo Invitar y Salir con íconos propios y la pastilla de ruta va a la izquierda del selector y muestra la ruta activa.
// AC3: CUANDO toca la pastilla ENTONCES se abre la hoja de salidas con la ruta activa marcada y las no disponibles deshabilitadas; elegir una disponible llama `setAudioRoute` y cierra la hoja.
// AC4: CUANDO quien no es anfitrión toca Salir ENTONCES la hoja pide confirmar; cancelar lo deja en la frecu y confirmar llama `leaveRoom` y vuelve al inicio.
// AC5: CUANDO el anfitrión toca Salir ENTONCES la hoja dice que la frecu se cierra para las otras personas, para la otra persona o, si está solo, que se cierra.
// AC7: CUANDO la app está en inglés ENTONCES las hojas y la pastilla salen en inglés; CUANDO se reduce el movimiento ENTONCES el haz del QR y las barras no se mueven.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/pages/room_page.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/invite_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/features/room/presentation/widgets/room_sheets.dart';
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
const _alice = Participant(id: 'peer-1', displayName: 'Alice', isHost: true);
const _bob = Participant(id: 'peer-2', displayName: 'Bob');
const _leo = Participant(id: 'peer-3', displayName: 'Leo');
const _sofi = Participant(id: 'peer-4', displayName: 'Sofi');

final _ruta40 = Room(
  id: 'room-123',
  name: 'Ruta 40',
  hostAddress: '192.168.43.1',
  port: 47800,
  accessCode: '4821',
  createdAt: DateTime(2026, 11, 8, 4, 30),
  note: const RoomNote(semitone: 4),
);

/// Texto exacto sin distinguir mayúsculas (el estilo pasa algunos a
/// mayúsculas).
Finder _caseless(String text) => find.textContaining(
  RegExp('^${RegExp.escape(text)}\$', caseSensitive: false),
);

void main() {
  setUpAll(() {
    registerFallbackValue(TalkMode.pushToTalk);
    registerFallbackValue(AudioRoute.speaker);
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  late _MockRoomRepository room;
  late _MockVoiceRepository voice;
  late StreamController<List<Participant>> participants;
  late StreamController<AudioRoute> route;
  late StreamController<Set<AudioRoute>> available;
  late StreamController<Set<String>> speaking;
  late String localId;

  setUp(() {
    // El núcleo PTT, la malla y el inicio animan sin fin: con movimiento
    // reducido quedan quietos y pumpAndSettle termina.
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
      ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    room = _MockRoomRepository();
    voice = _MockVoiceRepository();
    participants = StreamController<List<Participant>>.broadcast();
    route = StreamController<AudioRoute>.broadcast();
    available = StreamController<Set<AudioRoute>>.broadcast();
    speaking = StreamController<Set<String>>.broadcast();
    localId = 'peer-2';

    when(() => room.watchStatus())
        .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
    when(() => room.watchParticipants()).thenAnswer((_) => participants.stream);
    when(() => room.localParticipantId).thenAnswer((_) => localId);
    when(() => room.leaveRoom()).thenAnswer((_) async => _ok);
    when(() => voice.initializeAudio()).thenAnswer((_) async => _ok);
    when(() => voice.watchIsTalking()).thenAnswer((_) => const Stream.empty());
    when(() => voice.watchSpeakingPeers()).thenAnswer((_) => speaking.stream);
    when(() => voice.watchTalkMode()).thenAnswer((_) => const Stream.empty());
    when(() => voice.watchAudioRoute()).thenAnswer((_) => route.stream);
    when(() => voice.watchAvailableAudioRoutes())
        .thenAnswer((_) => available.stream);
    when(() => voice.setTalkMode(any())).thenAnswer((_) async => _ok);
    when(() => voice.setAudioRoute(any())).thenAnswer((_) async => _ok);
    when(() => voice.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    for (final controller in [participants, route, available, speaking]) {
      await controller.close();
    }
  });

  /// Entra a [active] con [people] conectados.
  Future<void> enterRoom(
    WidgetTester tester, {
    List<Participant> people = const [_alice, _bob],
    Room? active,
  }) async {
    final router = AppRouter();
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            roomRepositoryProvider.overrideWithValue(room),
            voiceRepositoryProvider.overrideWithValue(voice),
            roomNotifierProvider.overrideWith(
              () => _ActiveRoom(active ?? _ruta40),
            ),
          ],
          child: FrecuApp(appRouter: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push(RoomRoute(roomId: 'room-123')));
    await tester.pumpAndSettle();
    participants.add(people);
    await tester.pumpAndSettle();
  }

  Future<void> inEnglish(WidgetTester tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  Finder pill() => find.byKey(const Key('audio_route_button'));

  FrIconData pillIcon(WidgetTester tester) => tester
      .widget<FrIcon>(
        find.descendant(of: pill(), matching: find.byType(FrIcon)).first,
      )
      .icon;

  AudioRouteOption option(WidgetTester tester, AudioRoute value) =>
      tester.widget<AudioRouteOption>(
        find.byKey(Key('audio_route_option_${value.name}')),
      );

  group('Invitar', () {
    testWidgets('AC1: Invitar de la cabecera abre la hoja con el QR, la '
        'nota, el código y el anfitrión', (tester) async {
      await enterRoom(tester);
      await tapKey(tester, 'invite_button');

      expect(find.byType(InviteSheet), findsOneWidget);
      expect(_caseless('Invitar a la frecu'), findsOneWidget);
      expect(find.text('Escanea para unirte'), findsOneWidget);
      expect(
        find.text('Desde Frecu › Escanear. El QR ya incluye el código.'),
        findsOneWidget,
      );
      expect(
        tester.widget<InviteQr>(find.byType(InviteQr)).data,
        'frecu://join?h=192.168.43.1&p=47800&r=room-123&c=4821&n=4',
      );
      expect(
        find.descendant(
          of: find.byType(InviteSheet),
          matching: find.byType(RoomNoteName),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('invite_code'))).data,
        '4821',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('invite_host'))).data,
        '192.168.43.1',
      );
      expect(_caseless('Puerto 47800'), findsOneWidget);
      expect(
        find.text(
          'También aparece en “Frecus cercanas” para quien esté en tu red.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC1: un lugar libre abre la misma hoja y Cerrar la cierra '
        'sin salir de la frecu', (tester) async {
      await enterRoom(tester);
      await tapKey(tester, 'mesh_free_slot_2');
      expect(find.byType(InviteSheet), findsOneWidget);

      await tapKey(tester, 'sheet_close');

      expect(find.byType(InviteSheet), findsNothing);
      expect(find.byType(RoomPage), findsOneWidget);
      verifyNever(() => room.leaveRoom());
    });

    testWidgets('AC1: sin nota la ficha dice «—» y el QR va sin nota', (
      tester,
    ) async {
      await enterRoom(tester, active: _ruta40.copyWith(note: null));
      await tapKey(tester, 'invite_button');

      expect(
        tester.widget<InviteQr>(find.byType(InviteQr)).data,
        'frecu://join?h=192.168.43.1&p=47800&r=room-123&c=4821',
      );
      expect(
        find.descendant(of: find.byType(InviteSheet), matching: find.text('—')),
        findsOneWidget,
      );
    });

    testWidgets('AC2: la cabecera lleva solo Invitar y Salir con íconos '
        'propios, sin íconos de Material ni ruta', (tester) async {
      await enterRoom(tester);

      final header = find.byType(RoomHeader);
      expect(
        find.descendant(of: header, matching: find.byType(Icon)),
        findsNothing,
      );
      final buttons = tester
          .widgetList<FrIconButton>(
            find.descendant(of: header, matching: find.byType(FrIconButton)),
          )
          .map((button) => button.drawnIcon)
          .toList();
      expect(buttons, [FrIcons.qr, FrIcons.exit]);
      expect(find.descendant(of: header, matching: pill()), findsNothing);
    });

    testWidgets('AC7: en inglés la hoja de invitación sale en inglés y, con '
        'movimiento reducido, el QR no tiene haz', (tester) async {
      await inEnglish(tester);
      await enterRoom(tester);
      await tapKey(tester, 'invite_button');

      expect(_caseless('Invite to the frecu'), findsOneWidget);
      expect(find.text('Scan to join'), findsOneWidget);
      expect(_caseless('Port 47800'), findsOneWidget);
      expect(
        find.text(
          'It also shows up in “Nearby rooms” for anyone on your network.',
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(InviteQr),
          matching: find.byType(FrLoop),
        ),
        findsNothing,
      );
    });
  });

  group('Ruta de audio', () {
    testWidgets('AC2: la pastilla va a la izquierda del selector y muestra '
        'la ruta activa', (tester) async {
      await enterRoom(tester);

      final pillBox = tester.getRect(pill());
      final selector = tester.getRect(find.byType(FrSegmented<TalkMode>));
      expect(pillBox.right, lessThanOrEqualTo(selector.left));
      expect((pillBox.center.dy - selector.center.dy).abs(), lessThan(2));
      expect(selector.width, lessThanOrEqualTo(204.5));
      expect(
        find.descendant(of: pill(), matching: find.text('Altavoz')),
        findsOneWidget,
      );
      expect(pillIcon(tester), FrIcons.speaker);

      route.add(AudioRoute.earpiece);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: pill(), matching: find.text('Auricular')),
        findsOneWidget,
      );
      expect(pillIcon(tester), FrIcons.earpiece);

      route.add(AudioRoute.bluetooth);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: pill(), matching: find.text('Bluetooth')),
        findsOneWidget,
      );
      expect(pillIcon(tester), FrIcons.headset);
    });

    testWidgets('AC3: la pastilla abre la hoja de salidas con la ruta activa '
        'marcada y Bluetooth sin dispositivo deshabilitado', (tester) async {
      await enterRoom(tester);
      await tester.tap(pill());
      await tester.pumpAndSettle();

      expect(find.byType(AudioRouteSheet), findsOneWidget);
      expect(_caseless('Salida de audio'), findsOneWidget);
      expect(find.text('¿Dónde escuchas?'), findsOneWidget);
      expect(
        find.text('Al conectar audífonos, el audio cambia solo.'),
        findsOneWidget,
      );
      expect(_caseless('Manos libres'), findsOneWidget);
      expect(_caseless('Teléfono en la oreja'), findsOneWidget);
      expect(_caseless('Sin dispositivo'), findsOneWidget);
      expect(option(tester, AudioRoute.speaker).selected, isTrue);
      expect(option(tester, AudioRoute.earpiece).selected, isFalse);
      expect(option(tester, AudioRoute.earpiece).enabled, isTrue);
      expect(option(tester, AudioRoute.bluetooth).enabled, isFalse);

      await tester.tap(
        find.byKey(const Key('audio_route_option_bluetooth')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      verifyNever(() => voice.setAudioRoute(any()));
      expect(find.byType(AudioRouteSheet), findsOneWidget);
    });

    testWidgets('AC3: elegir una ruta disponible la cambia y cierra la hoja', (
      tester,
    ) async {
      await enterRoom(tester);
      await tester.tap(pill());
      await tester.pumpAndSettle();

      await tapKey(tester, 'audio_route_option_earpiece');

      verify(() => voice.setAudioRoute(AudioRoute.earpiece)).called(1);
      expect(find.byType(AudioRouteSheet), findsNothing);
    });

    testWidgets('AC3: con Bluetooth conectado dice «Conectado», se elige y '
        'la marca sigue a la ruta activa', (tester) async {
      await enterRoom(tester);
      available.add({
        AudioRoute.speaker,
        AudioRoute.earpiece,
        AudioRoute.bluetooth,
      });
      await tester.pumpAndSettle();
      await tester.tap(pill());
      await tester.pumpAndSettle();

      expect(_caseless('Conectado'), findsOneWidget);
      route.add(AudioRoute.bluetooth);
      await tester.pumpAndSettle();
      expect(option(tester, AudioRoute.bluetooth).selected, isTrue);
      expect(option(tester, AudioRoute.speaker).selected, isFalse);

      await tapKey(tester, 'audio_route_option_bluetooth');
      verify(() => voice.setAudioRoute(AudioRoute.bluetooth)).called(1);
    });

    testWidgets('AC7: en inglés la pastilla y la hoja salen en inglés y, con '
        'movimiento reducido, las barras no se mueven', (tester) async {
      await inEnglish(tester);
      await enterRoom(tester);
      speaking.add({'peer-1'});
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: pill(), matching: find.text('Speaker')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: pill(), matching: find.byType(FrLoop)),
        findsNothing,
      );
      await tester.tap(pill());
      await tester.pumpAndSettle();
      expect(_caseless('Audio output'), findsOneWidget);
      expect(find.text('Where do you listen?'), findsOneWidget);
      expect(_caseless('Hands-free'), findsOneWidget);
      expect(_caseless('No device'), findsOneWidget);
    });
  });

  group('Salir', () {
    testWidgets('AC4: quien no es anfitrión ve «¿Salir de la frecu?» y '
        'Cancelar lo deja en la frecu', (tester) async {
      await enterRoom(tester);
      await tapKey(tester, 'leave_button');

      expect(find.byType(LeaveSheet), findsOneWidget);
      expect(find.text('¿Salir de la frecu?'), findsOneWidget);
      expect(
        find.text('Podrás volver a unirte con el código de acceso.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('leave_confirm')),
          matching: _caseless('Salir de la frecu'),
        ),
        findsOneWidget,
      );
      expect(_caseless('Cancelar'), findsOneWidget);

      await tapKey(tester, 'leave_cancel');

      expect(find.byType(LeaveSheet), findsNothing);
      expect(find.byType(RoomPage), findsOneWidget);
      verifyNever(() => room.leaveRoom());
    });

    testWidgets('AC4: al confirmar se llama leaveRoom y vuelve al inicio', (
      tester,
    ) async {
      await enterRoom(tester);
      await tapKey(tester, 'leave_button');
      await tapKey(tester, 'leave_confirm');

      verify(() => room.leaveRoom()).called(1);
      expect(find.byType(RoomPage), findsNothing);
      expect(find.text('Fin de la transmisión'), findsNothing);
    });

    testWidgets('AC5: el anfitrión ve «Cerrar la frecu para todos» con las '
        'otras personas', (tester) async {
      localId = 'peer-1';
      await enterRoom(tester, people: const [_alice, _bob, _leo, _sofi]);
      await tapKey(tester, 'leave_button');

      expect(find.text('Cerrar la frecu para todos'), findsOneWidget);
      expect(
        find.text(
          'Eres el anfitrión. Si sales, la frecu se cierra para las otras 3 '
          'personas.',
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('leave_confirm')),
          matching: _caseless('Cerrar frecu'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC5: con una persona más dice «para la otra persona» y '
        'solo, que la frecu se cierra', (tester) async {
      localId = 'peer-1';
      await enterRoom(tester);
      await tapKey(tester, 'leave_button');
      expect(
        find.text(
          'Eres el anfitrión. Si sales, la frecu se cierra para la otra '
          'persona.',
        ),
        findsOneWidget,
      );

      await tapKey(tester, 'leave_cancel');
      participants.add(const [_alice]);
      await tester.pumpAndSettle();
      await tapKey(tester, 'leave_button');
      expect(
        find.text('Eres el anfitrión. Si sales, la frecu se cierra.'),
        findsOneWidget,
      );
    });

    testWidgets('AC7: en inglés la hoja de salir sale en inglés', (
      tester,
    ) async {
      await inEnglish(tester);
      await enterRoom(tester);
      await tapKey(tester, 'leave_button');

      expect(find.text('Leave the frecu?'), findsOneWidget);
      expect(
        find.text('You can join again with the access code.'),
        findsOneWidget,
      );
      expect(_caseless('Cancel'), findsOneWidget);
    });
  });
}
