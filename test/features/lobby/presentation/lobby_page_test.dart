// AC1: CUANDO se abre el inicio ENTONCES se ve en Portadora (`FrScaffold`) con la marca «frecu», la píldora de red, el botón Ajustes, «Frecus cercanas», «Elige tu frecu» con el número de frecus cercanas en dos cifras («00»), el sintonizador y abajo Crear frecu, Escanear y Conectar por IP, con todos los textos de slang en español y en inglés; Ajustes abre Ajustes, Crear frecu abre la pantalla de nueva frecu de hoy, Escanear abre el escáner de hoy y Conectar por IP abre el diálogo de unión por IP de hoy.
// AC2: CUANDO llega el estado de la red local ENTONCES la píldora dice «Red · <IP local>» si hay red o «Sin red local» en alerta si no la hay; mientras no llega dice «Buscando red».
// AC3: CUANDO hay frecus cercanas ENTONCES la lista muestra una tarjeta por frecu con su nota (nombre en el idioma de la app, alteración y octava), sus Hz con un decimal («329,6 Hz» en español, «329.6 Hz» en inglés), su nombre y su IP; el número las cuenta, y el sintonizador recibe la nota de cada una para dibujar su pico sobre su tecla y dice «N señales»; una frecu sin nota sale con «—», sin Hz y sin pico.
// AC4: CUANDO el usuario toca una frecu cercana ENTONCES queda elegida (su tarjeta encendida y la aguja del sintonizador va a su nota) y se abre el diálogo de código de hoy, que se une a esa frecu con su IP y su puerto.
// AC5: CUANDO no hay frecus cercanas y la red está conectada o aún no se sabe ENTONCES se ve la búsqueda vacía: la onda, «Sin señales por ahora», «Conéctate a la Wi-Fi del anfitrión o pídele que te muestre su QR.» y «La búsqueda sigue activa»; el sintonizador dice «Escaneando · _frecu._tcp» y «0 señales».
// AC6: CUANDO no hay frecus cercanas y no hay red local ENTONCES en lugar de la búsqueda vacía se ve un aviso de alerta «No estás en ninguna red Wi-Fi.» con «Únete al punto de acceso del anfitrión para encontrar frecus.» y el sintonizador queda atenuado con «Búsqueda en pausa»; CUANDO vuelve la red ENTONCES vuelve la búsqueda vacía; CUANDO hay frecus sin red ENTONCES se ve la lista.
// AC7: CUANDO se dibuja el sintonizador ENTONCES sus 14 teclas blancas y 10 negras van de Do4 a Si5 y cada nota cae en el centro de su tecla (`keyX` del prototipo), la lectura nombra la nota más cercana a la aguja, la aguja sigue un resorte (rigidez 90, amortiguación 16) hacia la nota elegida o barre las dos octavas sin salirse; sin movimiento reducido anima en cada cuadro y con movimiento reducido queda quieto y no pide cuadros.
import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_pill.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/pages/create_room_page.dart';
import 'package:frecu/features/lobby/presentation/pages/lobby_page.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/ip_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/lobby_tuner.dart';
import 'package:frecu/features/lobby/presentation/widgets/nearby_room_tile.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/settings/presentation/pages/settings_page.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockNetworkRepository extends Mock implements NetworkRepository {}

class _MockRoomRepository extends Mock implements RoomRepository {}

const _scannerStub = Key('scanner_stub');

/// Router de la app con el escáner sustituido: en las pruebas no hay cámara.
class _AppRouterWithoutCamera extends AppRouter {
  @override
  List<AutoRoute> get routes => [
    for (final route in super.routes)
      if (route.name == ScanQrRoute.name)
        AutoRoute(
          page: PageInfo(
            ScanQrRoute.name,
            builder: (_) => const SizedBox(key: _scannerStub),
          ),
          path: '/scan-qr',
        )
      else
        route,
  ];
}

/// Mi4: 329,6 Hz.
const _ruta = NearbyRoom(
  roomId: 'room-ruta',
  name: 'Ruta del domingo',
  hostAddress: '192.168.43.1',
  port: 47812,
  note: RoomNote(semitone: 4),
);

/// Fa♯5: 740,0 Hz.
const _brigada = NearbyRoom(
  roomId: 'room-brigada',
  name: 'Brigada Norte',
  hostAddress: '192.168.43.87',
  port: 47800,
  note: RoomNote(semitone: 18),
);

/// Anfitrión anterior a la nota: no la publica.
const _vieja = NearbyRoom(
  roomId: 'room-vieja',
  name: 'Frecu vieja',
  hostAddress: '192.168.43.9',
  port: 47800,
);

const _wifi = NetworkState.connected(
  ipAddress: '192.168.43.27',
  interfaceName: 'wlan0',
  isHotspot: false,
);

/// El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
Future<void> _useEnglish(WidgetTester tester) async {
  await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

LobbyTuner _tuner(WidgetTester tester) =>
    tester.widget<LobbyTuner>(find.byType(LobbyTuner));

Finder _tileOf(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(NearbyRoomTile));

NearbyRoomTile _tile(WidgetTester tester, String name) =>
    tester.widget<NearbyRoomTile>(_tileOf(name));

Finder _inTile(String name, Finder finder) =>
    find.descendant(of: _tileOf(name), matching: finder);

Finder _iconButton(String label) => find.byWidgetPredicate(
  (widget) => widget is FrIconButton && widget.semanticLabel == label,
);

/// Texto que se muestra en mayúsculas por estilo (etiquetas, píldora): se
/// busca sin distinguir mayúsculas.
Finder _label(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText())?.toLowerCase() ==
          text.toLowerCase(),
  description: 'texto «$text» sin distinguir mayúsculas',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late _MockRoomRepository rooms;
  late StreamController<List<NearbyRoom>> nearby;
  late StreamController<NetworkState> networkStates;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    rooms = _MockRoomRepository();
    nearby = StreamController<List<NearbyRoom>>.broadcast();
    networkStates = StreamController<NetworkState>.broadcast();

    when(() => discovery.watchNearbyRooms()).thenAnswer((_) => nearby.stream);
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(() => network.watchNetworkState())
        .thenAnswer((_) => networkStates.stream);
    when(() => rooms.getLocalIpAddress())
        .thenAnswer((_) async => '192.168.43.27');
    when(
      () => rooms.joinRoom(
        hostAddress: any(named: 'hostAddress'),
        port: any(named: 'port'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer(
      (_) async => const Result.failure(Failure.invalidAccessCode()),
    );
  });

  tearDown(() async {
    await nearby.close();
    await networkStates.close();
  });

  /// Abre la app en el inicio, en un teléfono de 390 × 844 y con movimiento
  /// reducido (el sintonizador, la píldora y la onda no paran solos).
  Future<void> pumpLobby(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    _reduceMotion(tester);
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(discovery),
            networkRepositoryProvider.overrideWithValue(network),
            roomRepositoryProvider.overrideWithValue(rooms),
          ],
          child: FrecuApp(appRouter: _AppRouterWithoutCamera()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> showRooms(WidgetTester tester, List<NearbyRoom> list) async {
    nearby.add(list);
    await tester.pumpAndSettle();
  }

  Future<void> showNetwork(WidgetTester tester, NetworkState state) async {
    networkStates.add(state);
    await tester.pumpAndSettle();
  }

  group('Inicio', () {
    testWidgets(
      'AC1: el inicio es Portadora con la marca, la red, Ajustes, el título '
      'con el número, el sintonizador y el dock',
      (tester) async {
        await pumpLobby(tester);

        expect(
          find.descendant(
            of: find.byType(LobbyPage),
            matching: find.byType(FrScaffold),
          ),
          findsOneWidget,
        );
        expect(find.text('frecu'), findsOneWidget);
        expect(find.byType(FrPill), findsOneWidget);
        expect(_iconButton('Ajustes'), findsOneWidget);
        expect(find.text('Frecus cercanas'), findsOneWidget);
        expect(find.text('Elige tu frecu'), findsOneWidget);
        expect(find.text('00'), findsOneWidget);
        expect(find.byType(LobbyTuner), findsOneWidget);
        expect(find.text('Crear frecu'), findsOneWidget);
        expect(find.text('Escanear'), findsOneWidget);
        expect(find.text('Conectar por IP'), findsOneWidget);
      },
    );

    testWidgets('AC1: en inglés los textos del inicio salen de la '
        'traducción en', (tester) async {
      await _useEnglish(tester);
      await pumpLobby(tester);

      expect(find.text('frecu'), findsOneWidget);
      expect(_iconButton('Settings'), findsOneWidget);
      expect(find.text('Nearby rooms'), findsOneWidget);
      expect(find.text('Pick your room'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
      expect(_label('Checking network'), findsOneWidget);
      expect(_label('Scanning · _frecu._tcp'), findsOneWidget);
      expect(_label('0 signals'), findsOneWidget);
      expect(find.text('No signals yet'), findsOneWidget);
      expect(find.text('Create room'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Connect by IP'), findsOneWidget);
    });

    testWidgets('AC1: Ajustes abre Ajustes', (tester) async {
      await pumpLobby(tester);

      await tester.tap(_iconButton(t.lobby.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('AC1: Crear frecu abre la pantalla de nueva frecu de hoy', (
      tester,
    ) async {
      await pumpLobby(tester);

      await tester.tap(find.text(t.lobby.createRoom));
      await tester.pumpAndSettle();

      expect(find.byType(CreateRoomPage), findsOneWidget);
    });

    testWidgets('AC1: Escanear abre el escáner', (tester) async {
      await pumpLobby(tester);

      await tester.tap(find.text(t.lobby.scanQr));
      await tester.pumpAndSettle();

      expect(find.byKey(_scannerStub), findsOneWidget);
    });

    testWidgets('AC1: Conectar por IP abre la hoja de unión por IP', (
      tester,
    ) async {
      await pumpLobby(tester);

      await tester.tap(find.text(t.lobby.joinRoom));
      await tester.pumpAndSettle();

      expect(find.byType(IpJoinSheet), findsOneWidget);
    });

    testWidgets(
      'AC2: la píldora dice Buscando red hasta que llega la red, y luego la '
      'IP local o Sin red local en alerta',
      (tester) async {
        await pumpLobby(tester);
        FrPill pill() => tester.widget<FrPill>(find.byType(FrPill));

        expect(pill().label, equalsIgnoringCase('Buscando red'));

        await showNetwork(tester, _wifi);
        expect(pill().label, equalsIgnoringCase('Red · 192.168.43.27'));
        expect(pill().tone, FrPillTone.ok);

        await showNetwork(tester, const NetworkState.disconnected());
        expect(pill().label, equalsIgnoringCase('Sin red local'));
        expect(pill().tone, FrPillTone.alert);
      },
    );

    testWidgets(
      'AC3: cada frecu cercana tiene su tarjeta con nota, Hz, nombre e IP, el '
      'número las cuenta y el sintonizador recibe sus notas',
      (tester) async {
        await pumpLobby(tester);
        await showNetwork(tester, _wifi);
        await showRooms(tester, [_ruta, _brigada, _vieja]);

        expect(find.byType(NearbyRoomTile), findsNWidgets(3));
        expect(find.text('03'), findsOneWidget);

        expect(_inTile(_ruta.name, find.text('Mi')), findsOneWidget);
        expect(_inTile(_ruta.name, find.text('4')), findsOneWidget);
        expect(_inTile(_ruta.name, _label('329,6 Hz')), findsOneWidget);
        expect(_inTile(_ruta.name, find.text('192.168.43.1')), findsOneWidget);

        expect(_inTile(_brigada.name, find.text('Fa')), findsOneWidget);
        expect(_inTile(_brigada.name, find.text('♯')), findsOneWidget);
        expect(_inTile(_brigada.name, find.text('5')), findsOneWidget);
        expect(_inTile(_brigada.name, _label('740,0 Hz')), findsOneWidget);
        expect(
          _inTile(_brigada.name, find.text('192.168.43.87')),
          findsOneWidget,
        );

        expect(_tuner(tester).notes, const [
          RoomNote(semitone: 4),
          RoomNote(semitone: 18),
        ]);
        expect(_tuner(tester).signalCount, 3);
        expect(_label('3 señales'), findsOneWidget);
      },
    );

    testWidgets('AC3: una frecu sin nota sale con «—», sin Hz y sin pico', (
      tester,
    ) async {
      await pumpLobby(tester);
      await showNetwork(tester, _wifi);
      await showRooms(tester, [_vieja]);

      expect(_inTile(_vieja.name, find.text('—')), findsOneWidget);
      expect(
        _inTile(
          _vieja.name,
          find.textContaining(RegExp('hz', caseSensitive: false)),
        ),
        findsNothing,
      );
      expect(_inTile(_vieja.name, find.text('192.168.43.9')), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(_tuner(tester).notes, isEmpty);
      expect(_tuner(tester).signalCount, 1);
      expect(_label('1 señal'), findsOneWidget);
    });

    testWidgets('AC3: en inglés la nota sale con su nombre en inglés y los Hz '
        'con punto', (tester) async {
      await _useEnglish(tester);
      await pumpLobby(tester);
      await showNetwork(tester, _wifi);
      await showRooms(tester, [_ruta, _brigada]);

      expect(_inTile(_ruta.name, find.text('E')), findsOneWidget);
      expect(_inTile(_ruta.name, find.text('4')), findsOneWidget);
      expect(_inTile(_ruta.name, _label('329.6 Hz')), findsOneWidget);
      expect(_inTile(_brigada.name, find.text('F')), findsOneWidget);
      expect(_inTile(_brigada.name, find.text('♯')), findsOneWidget);
      expect(_inTile(_brigada.name, find.text('5')), findsOneWidget);
      expect(_inTile(_brigada.name, _label('740.0 Hz')), findsOneWidget);
      expect(_label('2 signals'), findsOneWidget);
    });

    testWidgets(
      'AC4: tocar una frecu la elige, lleva la aguja a su nota y abre el '
      'diálogo de código, que se une con su IP y su puerto',
      (tester) async {
        await pumpLobby(tester);
        await showNetwork(tester, _wifi);
        await showRooms(tester, [_ruta, _brigada]);

        expect(_tile(tester, _ruta.name).selected, isFalse);
        expect(_tuner(tester).selected, isNull);

        await tester.tap(find.text(_ruta.name));
        await tester.pumpAndSettle();

        expect(_tile(tester, _ruta.name).selected, isTrue);
        expect(_tile(tester, _brigada.name).selected, isFalse);
        expect(_tuner(tester).selected, const RoomNote(semitone: 4));

        expect(find.byType(PinJoinSheet), findsOneWidget);
        for (final digit in '1234'.split('')) {
          await tester.tap(find.byKey(ValueKey('fr-key-$digit')));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        verify(
          () => rooms.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47812,
            accessCode: '1234',
            displayName: any(named: 'displayName'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'AC5: sin frecus y con red se ve la búsqueda vacía con la onda y el '
      'sintonizador escaneando',
      (tester) async {
        await pumpLobby(tester);
        await showNetwork(tester, _wifi);
        await showRooms(tester, []);

        expect(
          find.descendant(
            of: find.byType(LobbyPage),
            matching: find.byType(WaveLoader),
          ),
          findsOneWidget,
        );
        expect(find.text('Sin señales por ahora'), findsOneWidget);
        expect(
          find.text(
            'Conéctate a la Wi-Fi del anfitrión o pídele que te muestre su QR.',
          ),
          findsOneWidget,
        );
        expect(_label('La búsqueda sigue activa'), findsOneWidget);
        expect(_label('Escaneando · _frecu._tcp'), findsOneWidget);
        expect(_label('0 señales'), findsOneWidget);
        expect(find.byType(NearbyRoomTile), findsNothing);
        expect(find.byType(FrBanner), findsNothing);
        expect(_tuner(tester).paused, isFalse);
      },
    );

    testWidgets('AC5: sin frecus y sin saber aún la red también se ve la '
        'búsqueda vacía', (tester) async {
      await pumpLobby(tester);

      expect(find.text('Sin señales por ahora'), findsOneWidget);
      expect(find.byType(FrBanner), findsNothing);
      expect(_tuner(tester).paused, isFalse);
    });

    testWidgets(
      'AC6: sin frecus y sin red se ve el aviso de alerta y el sintonizador '
      'en pausa; al volver la red vuelve la búsqueda vacía',
      (tester) async {
        await pumpLobby(tester);
        await showRooms(tester, []);
        await showNetwork(tester, const NetworkState.disconnected());

        final banner = tester.widget<FrBanner>(find.byType(FrBanner));
        expect(banner.tone, FrBannerTone.alert);
        expect(banner.title, 'No estás en ninguna red Wi-Fi.');
        expect(
          banner.message,
          'Únete al punto de acceso del anfitrión para encontrar frecus.',
        );
        expect(find.text('Sin señales por ahora'), findsNothing);
        expect(find.byType(WaveLoader), findsNothing);
        expect(_tuner(tester).paused, isTrue);
        expect(_label('Búsqueda en pausa'), findsOneWidget);

        await showNetwork(tester, _wifi);

        expect(find.byType(FrBanner), findsNothing);
        expect(find.text('Sin señales por ahora'), findsOneWidget);
        expect(_tuner(tester).paused, isFalse);
        expect(_label('Escaneando · _frecu._tcp'), findsOneWidget);
      },
    );

    testWidgets('AC6: con frecus y sin red se ve la lista', (tester) async {
      await pumpLobby(tester);
      await showNetwork(tester, const NetworkState.disconnected());
      await showRooms(tester, [_ruta]);

      expect(find.byType(NearbyRoomTile), findsOneWidget);
      expect(find.byType(FrBanner), findsNothing);
      expect(_tuner(tester).paused, isFalse);
    });
  });

  group('Sintonizador', () {
    const left = 16.0;
    const keyWidth = 10.0;

    double keyX(int semitone) =>
        tunerKeyX(semitone, left: left, keyWidth: keyWidth);

    test('AC7: las 14 teclas blancas y las 10 negras van de Do4 a Si5 y cada '
        'nota cae en el centro de su tecla', () {
      // `keyX` del prototipo: una blanca en el centro de su tecla y una negra
      // en la juntura de las dos blancas que la rodean.
      const whites = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23];
      const blacks = [1, 3, 6, 8, 10, 13, 15, 18, 20, 22];
      expect({...whites, ...blacks}, hasLength(24));

      for (final (key, semitone) in whites.indexed) {
        expect(
          keyX(semitone),
          closeTo(left + (key + 0.5) * keyWidth, 1e-6),
          reason: 'blanca $semitone',
        );
      }
      for (final semitone in blacks) {
        final below = whites.indexOf(semitone - 1);
        expect(
          keyX(semitone),
          closeTo(left + (below + 1) * keyWidth, 1e-6),
          reason: 'negra $semitone',
        );
      }
      expect(keyX(0), closeTo(left + keyWidth / 2, 1e-6));
      expect(keyX(23), closeTo(left + 13.5 * keyWidth, 1e-6));
    });

    test('AC7: la lectura nombra la nota más cercana a la aguja', () {
      int nearest(double x) =>
          tunerNearestSemitone(x, left: left, keyWidth: keyWidth);

      for (var semitone = 0; semitone < 24; semitone++) {
        expect(nearest(keyX(semitone)), semitone);
      }
      expect(nearest(0), 0);
      expect(nearest(500), 23);
      // Entre Mi4 (2,5 teclas) y Fa4 (3,5 teclas).
      expect(nearest(left + 2.9 * keyWidth), 4);
      expect(nearest(left + 3.1 * keyWidth), 5);
    });

    test('AC7: la aguja sigue un resorte de rigidez 90 y amortiguación 16', () {
      final needle = TunerNeedle()..jumpTo(0.5);
      expect(needle.position, 0.5);
      expect(needle.velocity, 0);

      // Un paso de Euler semiimplícito de 1/60 s hacia 0,9:
      // a = −90 · (0,5 − 0,9) − 16 · 0 = 36; v = 36 / 60; x = 0,5 + v / 60.
      needle.advance(0.9, 1 / 60);
      expect(needle.velocity, closeTo(0.6, 1e-6));
      expect(needle.position, closeTo(0.51, 1e-6));

      for (var frame = 0; frame < 120; frame++) {
        needle.advance(0.9, 1 / 60);
      }
      expect(needle.position, closeTo(0.9, 0.001));
      expect(needle.velocity, closeTo(0, 0.01));

      needle.jumpTo(0.2);
      expect(needle.position, 0.2);
      expect(needle.velocity, 0);
    });

    test('AC7: sin elección la aguja barre las dos octavas sin salirse', () {
      var low = 1.0;
      var high = 0.0;
      for (var seconds = 0.0; seconds <= 60; seconds += 0.05) {
        final x = tunerSweep(seconds);
        expect(x, inInclusiveRange(0, 1), reason: 't = $seconds');
        low = math.min(low, x);
        high = math.max(high, x);
      }
      expect(low, lessThan(0.1));
      expect(high, greaterThan(0.9));
    });

    Future<void> pumpTuner(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: LobbyTuner(
            notes: [RoomNote(semitone: 4), RoomNote(semitone: 18)],
            signalCount: 2,
            selected: RoomNote(semitone: 4),
          ),
        ),
      ),
    );

    testWidgets('AC7: sin movimiento reducido el sintonizador anima en cada '
        'cuadro', (tester) async {
      await pumpTuner(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AC7: con movimiento reducido el sintonizador queda quieto y '
        'no pide cuadros', (tester) async {
      _reduceMotion(tester);
      await pumpTuner(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(find.byType(LobbyTuner), findsOneWidget);
    });
  });
}
