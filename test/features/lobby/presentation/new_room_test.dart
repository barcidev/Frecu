// AC3: CUANDO se ve la nueva frecu ENTONCES el reloj de quintas recibe la hora y los minutos actuales y la nota de la frecu, y a su lado se lee «Tu frecu suena en», la nota (nombre en el idioma de la app, alteración y octava), sus Hz con un decimal y el separador del idioma («659,3 Hz», «659.3 Hz») y «Abierta a las HH:MM»; la nota es la de su hora en el círculo de quintas (octava 4 de 0 a 11 h y 5 de 12 a 23 h) y, CUANDO aparece una frecu cercana con esa nota o cambia la hora, ENTONCES pasa a la siguiente quinta libre o a la nota de la nueva hora.
// AC4: CUANDO se abre la nueva frecu ENTONCES el campo «Nombre de la frecu» trae «Frecu de <nombre guardado>» (o «Mi frecu» sin nombre guardado) con su contador de 24 y el ejemplo «Ej. Ruta del domingo» al vaciarlo, y el código de acceso muestra 4 cifras generadas en celdas de solo lectura con «4 dígitos» y «Compártelo solo con tu grupo: evita que se unan desconocidos de la misma red.»; CUANDO toca «Generar otro» ENTONCES el código cambia por uno nuevo.
// AC5: CUANDO el usuario toca «Abrir frecu» ENTONCES se crea la frecu con el nombre sin espacios sobrantes, el código mostrado, el nombre guardado como anfitrión y las notas de las frecus cercanas, se publica con su nota y se abre la frecu activa; con el nombre vacío el botón no responde; si la creación falla, avisa con el mensaje de la falla y sigue en la nueva frecu.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/new_room_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/fifths_clock.dart';
import 'package:frecu/features/lobby/presentation/widgets/new_room_hero.dart';
import 'package:frecu/features/lobby/presentation/widgets/new_room_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
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
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockNetworkRepository extends Mock implements NetworkRepository {}

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

/// Frecu cercana en Mi5, la nota de las 16 h.
const _mi5 = NearbyRoom(
  roomId: 'room-mi5',
  name: 'Ruta Norte',
  hostAddress: '192.168.43.20',
  port: 47800,
  note: RoomNote(semitone: 16),
);

/// Frecu cercana en Si5, la quinta siguiente a Mi5.
const _si5 = NearbyRoom(
  roomId: 'room-si5',
  name: 'Brigada Sur',
  hostAddress: '192.168.43.21',
  port: 47800,
  note: RoomNote(semitone: 23),
);

/// Anfitrión anterior a la nota: no la publica.
const _sinNota = NearbyRoom(
  roomId: 'room-vieja',
  name: 'Frecu vieja',
  hostAddress: '192.168.43.9',
  port: 47800,
);

/// El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
Future<void> _useEnglish(WidgetTester tester) async {
  await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
}

Finder _iconButton(String label) => find.byWidgetPredicate(
  (widget) => widget is FrIconButton && widget.semanticLabel == label,
);

/// Texto que se muestra en mayúsculas por estilo: se busca sin distinguir
/// mayúsculas.
Finder _label(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText())?.toLowerCase() ==
          text.toLowerCase(),
  description: 'texto «$text» sin distinguir mayúsculas',
);

FifthsClock _clock(WidgetTester tester) =>
    tester.widget<FifthsClock>(find.byType(FifthsClock));

RoomNote _heroNote(WidgetTester tester) => tester
    .widget<RoomNoteText>(
      find.descendant(
        of: find.byType(NewRoomHero),
        matching: find.byType(RoomNoteText),
      ),
    )
    .note;

String _name(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

String _code(WidgetTester tester) =>
    tester.widget<FrPinField>(find.byType(FrPinField)).value;

FrButton _openButton(WidgetTester tester) => tester.widget<FrButton>(
  find.ancestor(
    of: find.text(t.lobby.newRoom.open),
    matching: find.byType(FrButton),
  ),
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
  late List<String> codes;

  // Abierta a las 16:24 hora local, como marca el reloj de la pantalla.
  final openedRoom = Room(
    id: 'room-123',
    name: 'Ruta del domingo',
    hostAddress: '192.168.43.1',
    port: 47800,
    accessCode: '4827',
    createdAt: DateTime(2026, 11, 8, 16, 24),
  );

  void stubCreate(Future<Result<Room>> Function() answer) {
    when(
      () => rooms.createRoom(
        name: any(named: 'name'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) => answer());
  }

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    rooms = _MockRoomRepository();
    voice = _MockVoiceRepository();
    nearby = StreamController<List<NearbyRoom>>.broadcast();
    networkStates = StreamController<NetworkState>.broadcast();
    now = DateTime(2026, 11, 8, 16, 24);
    codes = ['4827', '1593', '7302'];

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
    stubCreate(() async => Result.success(openedRoom));
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

  /// Abre la app en el inicio (390 × 844, movimiento reducido), con el
  /// nombre [savedName] guardado, y va a la nueva frecu por la guía.
  Future<void> pumpNewRoom(
    WidgetTester tester, {
    String? savedName = 'Ana',
    List<NearbyRoom> nearbyRooms = const [],
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferencesAsyncPlatform.instance = savedName == null
        ? InMemorySharedPreferencesAsync.empty()
        : InMemorySharedPreferencesAsync.withData({
            PreferencesRepositoryImpl.displayNameKey: savedName,
          });
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(discovery),
        networkRepositoryProvider.overrideWithValue(network),
        roomRepositoryProvider.overrideWithValue(rooms),
        voiceRepositoryProvider.overrideWithValue(voice),
        newRoomClockProvider.overrideWithValue(() => now),
        accessCodeGeneratorProvider.overrideWithValue(() => codes.removeAt(0)),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(preferencesProvider.future));
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: FrecuApp(appRouter: AppRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (nearbyRooms.isNotEmpty) {
      nearby.add(nearbyRooms);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(t.lobby.createRoom));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lobby.newRoom.guide.ready));
    await tester.pumpAndSettle();
  }

  group('Nota de la nueva frecu', () {
    testWidgets('AC3: a las 16:24 el reloj marca la hora y la frecu suena en '
        'Mi5 a 659,3 Hz', (tester) async {
      await pumpNewRoom(tester);

      final clock = _clock(tester);
      expect(clock.hour, 16);
      expect(clock.minute, 24);
      expect(clock.note, const RoomNote(semitone: 16));
      expect(_heroNote(tester), const RoomNote(semitone: 16));
      expect(_label('Tu frecu suena en'), findsOneWidget);
      expect(find.text('Mi'), findsOneWidget);
      expect(_label('659,3 Hz'), findsOneWidget);
      expect(_label('Abierta a las 16:24'), findsOneWidget);
    });

    testWidgets('AC3: por la mañana la nota va en la octava 4', (tester) async {
      now = DateTime(2026, 11, 8, 9, 5);
      await pumpNewRoom(tester);

      // 9 h → Mi♭ en el círculo de quintas.
      expect(_clock(tester).note, const RoomNote(semitone: 3));
      expect(_heroNote(tester), const RoomNote(semitone: 3));
      expect(find.text('♭'), findsOneWidget);
      expect(_label('311,1 Hz'), findsOneWidget);
      expect(_label('Abierta a las 09:05'), findsOneWidget);
    });

    testWidgets('AC3: si una frecu cercana ya usa la nota, pasa a la '
        'siguiente quinta libre', (tester) async {
      await pumpNewRoom(tester, nearbyRooms: [_mi5, _sinNota]);

      expect(_heroNote(tester), const RoomNote(semitone: 23));
      expect(_clock(tester).note, const RoomNote(semitone: 23));
      expect(_clock(tester).hour, 16);
      expect(_label('987,8 Hz'), findsOneWidget);

      nearby.add([_mi5, _si5, _sinNota]);
      await tester.pumpAndSettle();

      expect(_heroNote(tester), const RoomNote(semitone: 18));
      expect(_label('740,0 Hz'), findsOneWidget);
    });

    testWidgets('AC3: cuando cambia la hora la nota pasa a la de la nueva '
        'hora', (tester) async {
      now = DateTime(2026, 11, 8, 16, 59);
      await pumpNewRoom(tester);
      expect(_heroNote(tester), const RoomNote(semitone: 16));

      now = DateTime(2026, 11, 8, 17);
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      expect(_clock(tester).hour, 17);
      expect(_clock(tester).minute, 0);
      expect(_heroNote(tester), const RoomNote(semitone: 23));
      expect(_label('Abierta a las 17:00'), findsOneWidget);
    });

    testWidgets('AC3: en inglés la nota y los Hz salen de la traducción en', (
      tester,
    ) async {
      await _useEnglish(tester);
      await pumpNewRoom(tester);

      expect(_label('Step 2 of 2'), findsOneWidget);
      expect(find.text('New room'), findsOneWidget);
      expect(_label('Your room sounds in'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
      expect(_label('659.3 Hz'), findsOneWidget);
      expect(_label('Opened at 16:24'), findsOneWidget);
    });
  });

  group('Nombre y código de la nueva frecu', () {
    testWidgets('AC4: el nombre trae «Frecu de» y el nombre guardado, con '
        'su contador de 24 y el ejemplo al vaciarlo', (tester) async {
      await pumpNewRoom(tester);

      expect(_label('Nombre de la frecu'), findsOneWidget);
      expect(_name(tester), 'Frecu de Ana');
      expect(find.text('12/24'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.text('Ej. Ruta del domingo'), findsOneWidget);
      expect(find.text('0/24'), findsOneWidget);
    });

    testWidgets('AC4: sin nombre guardado el nombre es «Mi frecu»', (
      tester,
    ) async {
      await pumpNewRoom(tester, savedName: null);

      expect(_name(tester), 'Mi frecu');
    });

    testWidgets('AC4: con un nombre guardado largo el nombre no pasa de 24 '
        'caracteres', (tester) async {
      await pumpNewRoom(tester, savedName: 'María Fernanda Ruiz');

      expect(_name(tester), 'Frecu de María Fernanda');
      expect(_name(tester).length, lessThanOrEqualTo(24));
    });

    testWidgets('AC4: el código son 4 cifras generadas en celdas de solo '
        'lectura con su ayuda', (tester) async {
      await pumpNewRoom(tester);

      final pin = tester.widget<FrPinField>(find.byType(FrPinField));
      expect(pin.value, '4827');
      expect(pin.length, 4);
      expect(pin.readOnly, isTrue);
      expect(_label('Código de acceso'), findsOneWidget);
      expect(_label('4 dígitos'), findsOneWidget);
      expect(
        find.text(
          'Compártelo solo con tu grupo: evita que se unan desconocidos de '
          'la misma red.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC4: «Generar otro» cambia el código por uno nuevo', (
      tester,
    ) async {
      await pumpNewRoom(tester);

      await tester.tap(_iconButton('Generar otro'));
      await tester.pumpAndSettle();
      expect(_code(tester), '1593');

      await tester.tap(_iconButton('Generar otro'));
      await tester.pumpAndSettle();
      expect(_code(tester), '7302');
    });
  });

  group('Abrir la nueva frecu', () {
    testWidgets(
      'AC5: Abrir frecu la crea con el nombre, el código, el anfitrión y las '
      'notas cercanas, la publica con su nota y la abre',
      (tester) async {
        await pumpNewRoom(tester, nearbyRooms: [_mi5, _sinNota]);

        await tester.enterText(find.byType(TextField), '  Ruta del domingo  ');
        await tester.tap(_iconButton('Generar otro'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abrir frecu'));
        await tester.pumpAndSettle();

        verify(
          () => rooms.createRoom(
            name: 'Ruta del domingo',
            accessCode: '1593',
            displayName: 'Ana',
            note: any(named: 'note'),
          ),
        ).called(1);
        // Mi5 ya la usa una frecu cercana: la frecu abierta suena en Si5.
        verify(
          () => discovery.publishRoom(
            roomId: 'room-123',
            name: 'Ruta del domingo',
            port: 47800,
            note: const RoomNote(semitone: 23),
          ),
        ).called(1);
        expect(find.byType(RoomPage), findsOneWidget);
        expect(find.byType(NewRoomStep), findsNothing);
      },
    );

    testWidgets('AC5: con el nombre vacío Abrir frecu no responde', (
      tester,
    ) async {
      await pumpNewRoom(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      expect(_openButton(tester).onPressed, isNull);
      await tester.tap(find.text('Abrir frecu'));
      await tester.pumpAndSettle();

      verifyNever(
        () => rooms.createRoom(
          name: any(named: 'name'),
          accessCode: any(named: 'accessCode'),
          displayName: any(named: 'displayName'),
          note: any(named: 'note'),
        ),
      );
      expect(find.byType(NewRoomStep), findsOneWidget);
    });

    testWidgets('AC5: si la creación falla avisa con el mensaje y sigue en '
        'la nueva frecu', (tester) async {
      stubCreate(() async => const Result.failure(Failure.network()));
      await pumpNewRoom(tester);

      await tester.tap(find.text('Abrir frecu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(t.errors.network), findsOneWidget);
      expect(find.byType(NewRoomStep), findsOneWidget);
      expect(find.byType(RoomPage), findsNothing);
      expect(_openButton(tester).loading, isFalse);
      verifyNever(
        () => discovery.publishRoom(
          roomId: any(named: 'roomId'),
          name: any(named: 'name'),
          port: any(named: 'port'),
          note: any(named: 'note'),
        ),
      );

      // El aviso se va solo.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text(t.errors.network), findsNothing);
    });
  });
}
