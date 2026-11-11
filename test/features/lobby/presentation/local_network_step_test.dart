// Red de Frecu (anfitrión Android): Crear frecu y Seguir con Local abren «Frecu crea la red» en el paso 2 de 3, con la ilustración, los tres pasos, «Crear la red» y «Prefiero mi zona Wi-Fi». Crear la red muestra «Creando la red…» con Cancelar (que la apaga) y, al aire, «Tu red está al aire» con su nombre y Seguir, que lleva a la nueva frecu; al abrirla, la frecu lleva la red y la red sigue. Si falla, el aviso dice qué pasó con su acción (ajustes de la zona Wi-Fi, de Frecu o de ubicación) y Reintentar; con la zona Wi-Fi encendida se puede seguir con ella; sin Android 8, solo queda la guía. «Prefiero mi zona Wi-Fi» abre la guía de siempre, y Atrás vuelve. Salir de la creación sin abrir la frecu apaga la red. En iPhone, tras el tipo, sigue la guía.
// AC1: CUANDO el usuario toca «Crear frecu» ENTONCES el primer paso pregunta «¿Cómo se une tu grupo?» con «Local» (marcada por defecto) y «Por internet». Local sigue a «Prepara la red» y luego a «Nueva frecu» (pasos de 3); Por internet va directo a «Nueva frecu» (pasos de 2).
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/new_room_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_guide_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_illustration.dart';
import 'package:frecu/features/lobby/presentation/widgets/local_network_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/new_room_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_reach_step.dart';
import 'package:frecu/features/network/domain/entities/local_hotspot.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/domain/repositories/local_hotspot_repository.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/domain/repositories/system_settings_repository.dart';
import 'package:frecu/features/network/presentation/providers/local_hotspot_provider.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
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

class _MockNetworkRepository extends Mock implements NetworkRepository {}

class _MockRoomRepository extends Mock implements RoomRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

/// Red que responde cuando la prueba completa [pending]. Cada intento crea
/// su espera dentro de la prueba, en el reloj falso.
class _FakeHotspots implements LocalHotspotRepository {
  final StreamController<void> stopped = StreamController<void>.broadcast();
  late Completer<Result<LocalHotspot>> pending;
  int starts = 0;
  int stops = 0;

  @override
  Future<Result<LocalHotspot>> start() {
    starts++;
    pending = Completer<Result<LocalHotspot>>();
    return pending.future;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Stream<void> watchStopped() => stopped.stream;
}

/// Ajustes del sistema que anota cuáles se abren.
class _FakeSettings implements SystemSettingsRepository {
  final List<String> opened = [];

  @override
  Future<Result<void>> openWifiSettings() async {
    opened.add('wifi');
    return const Result.success(null);
  }

  @override
  Future<Result<void>> openHotspotSettings() async {
    opened.add('hotspot');
    return const Result.success(null);
  }

  @override
  Future<Result<void>> openAppSettings() async {
    opened.add('app');
    return const Result.success(null);
  }

  @override
  Future<Result<void>> openLocationSettings() async {
    opened.add('location');
    return const Result.success(null);
  }
}

const _roomStub = Key('room_stub');

/// La frecu activa se sustituye por un hueco.
class _TestRouter extends AppRouter {
  @override
  List<AutoRoute> get routes => [
    for (final route in super.routes)
      if (route.name == RoomRoute.name)
        AutoRoute(
          page: PageInfo(
            RoomRoute.name,
            builder: (_) => const SizedBox(key: _roomStub),
          ),
          path: '/room/:roomId',
        )
      else
        route,
  ];
}

const _wifi = WifiCredentials(
  ssid: 'AndroidShare_4821',
  passphrase: 'a3f91c7e5b2d',
);

Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is FrButton && widget.label == label,
);

Finder _iconButton(String label) => find.byWidgetPredicate(
  (widget) => widget is FrIconButton && widget.semanticLabel == label,
);

/// Texto que se muestra en mayúsculas por estilo.
Finder _label(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText())?.toLowerCase() ==
          text.toLowerCase(),
  description: 'texto «$text» sin distinguir mayúsculas',
);

List<String> _steps(WidgetTester tester) => [
  for (final row in tester.widgetList<HotspotGuideStepRow>(
    find.byType(HotspotGuideStepRow),
  ))
    '${row.step.lead}${row.step.rest}',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late _MockRoomRepository rooms;
  late _FakeHotspots hotspots;
  late _FakeSettings settings;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    rooms = _MockRoomRepository();
    hotspots = _FakeHotspots();
    settings = _FakeSettings();

    when(() => discovery.watchNearbyRooms())
        .thenAnswer((_) => Stream.value(const <NearbyRoom>[]));
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(
      () => discovery.publishRoom(
        roomId: any(named: 'roomId'),
        name: any(named: 'name'),
        port: any(named: 'port'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => network.watchNetworkState()).thenAnswer(
      (_) => Stream.value(
        const NetworkState.connected(
          ipAddress: '192.168.62.1',
          interfaceName: 'swlan0',
          isHotspot: true,
        ),
      ),
    );
    when(() => rooms.getLocalIpAddress())
        .thenAnswer((_) async => '192.168.62.1');
    when(() => rooms.localParticipantId).thenReturn(null);
    when(
      () => rooms.createRoom(
        name: any(named: 'name'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        Room(
          id: 'room-1',
          name: 'Mi frecu',
          hostAddress: '192.168.62.1',
          port: 47800,
          accessCode: '4827',
          createdAt: DateTime(2026, 11, 9, 20, 15),
        ),
      ),
    );
  });

  tearDown(() => hotspots.stopped.close());

  /// Abre la app en Android (o, sin [android], en iPhone) con movimiento
  /// reducido, toca Crear frecu y sigue con Local, marcada.
  Future<ProviderContainer> pumpCreate(
    WidgetTester tester, {
    bool android = true,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(discovery),
        networkRepositoryProvider.overrideWithValue(network),
        roomRepositoryProvider.overrideWithValue(rooms),
        voiceRepositoryProvider.overrideWithValue(_MockVoiceRepository()),
        systemSettingsRepositoryProvider.overrideWithValue(settings),
        localHotspotRepositoryProvider.overrideWithValue(hotspots),
        localHotspotAvailableProvider.overrideWithValue(android),
        newRoomClockProvider.overrideWithValue(
          () => DateTime(2026, 11, 9, 20, 15),
        ),
        accessCodeGeneratorProvider.overrideWithValue(() => '4827'),
        cloudConfigProvider.overrideWithValue(
          const CloudConfig('https://frecu.example.workers.dev'),
        ),
        internetCheckProvider.overrideWithValue(() async => true),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: FrecuApp(appRouter: _TestRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lobby.createRoom));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> answer(WidgetTester tester, Result<LocalHotspot> result) async {
    hotspots.pending.complete(result);
    await tester.pumpAndSettle();
  }

  testWidgets('Crear frecu abre «Frecu crea la red» con sus pasos y el dock', (
    tester,
  ) async {
    await pumpCreate(tester);

    expect(find.byType(LocalNetworkStep), findsOneWidget);
    expect(_label('Paso 2 de 3'), findsOneWidget);
    expect(find.text('Prepara la red'), findsOneWidget);
    expect(find.byType(HotspotIllustration), findsOneWidget);
    expect(find.text('Frecu crea la red'), findsOneWidget);
    expect(
      find.text(
        'Tu teléfono será la antena del grupo. Sin internet y sin gastar tus '
        'datos.',
      ),
      findsOneWidget,
    );
    const create =
        'Toca «Crear la red». La primera vez, Android te pide el permiso de '
        'dispositivos cercanos.';
    const show =
        'Abre tu frecu y muestra el QR. Ya lleva la red y su clave: tu grupo '
        'entra con un solo escaneo.';
    const close =
        'Al cerrar la frecu, la red se apaga. La próxima tendrá otro nombre y '
        'otra clave.';
    expect(_steps(tester), [create, show, close]);
    expect(_button('Crear la red'), findsOneWidget);
    expect(_button('Prefiero mi zona Wi-Fi'), findsOneWidget);
    expect(hotspots.starts, 0);
  });

  testWidgets('crear la red: «Creando la red…» y, al aire, su nombre y '
      'Seguir a la nueva frecu', (tester) async {
    await pumpCreate(tester);

    await tap(tester, _button('Crear la red'));

    expect(hotspots.starts, 1);
    expect(find.text('Creando la red…'), findsOneWidget);
    expect(tester.widget<FrButton>(_button('Creando la red…')).loading, isTrue);
    expect(_button('Cancelar'), findsOneWidget);

    await answer(
      tester,
      const Result.success(LocalHotspot(credentials: _wifi)),
    );

    expect(find.text('Tu red está al aire'), findsOneWidget);
    expect(find.text('AndroidShare_4821'), findsOneWidget);
    expect(_label('Al aire'), findsOneWidget);
    expect(find.text('La clave viaja en el QR'), findsOneWidget);
    expect(_button('Prefiero mi zona Wi-Fi'), findsNothing);

    await tap(tester, _button('Seguir'));

    expect(find.byType(NewRoomStep), findsOneWidget);
    expect(find.text('Nueva frecu'), findsOneWidget);
  });

  testWidgets('al abrir la frecu, la frecu lleva la red y la red sigue', (
    tester,
  ) async {
    final container = await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));
    await answer(
      tester,
      const Result.success(LocalHotspot(credentials: _wifi)),
    );
    await tap(tester, _button('Seguir'));

    await tap(tester, _button('Abrir frecu'));

    expect(find.byKey(_roomStub), findsOneWidget);
    expect(container.read(roomNotifierProvider)?.wifi, _wifi);
    expect(hotspots.stops, 0);
  });

  testWidgets('Cancelar mientras se crea la apaga y vuelve a los pasos', (
    tester,
  ) async {
    await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));

    await tap(tester, _button('Cancelar'));

    expect(hotspots.stops, 1);
    expect(_button('Crear la red'), findsOneWidget);
    expect(find.byType(HotspotGuideStepRow), findsNWidgets(3));
  });

  testWidgets('salir de la creación sin abrir la frecu apaga la red', (
    tester,
  ) async {
    await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));
    await answer(
      tester,
      const Result.success(LocalHotspot(credentials: _wifi)),
    );

    await tap(tester, _iconButton('Atrás'));
    expect(find.text('¿Cómo se une tu grupo?'), findsOneWidget);
    await tap(tester, _iconButton('Atrás'));

    expect(find.byType(LocalNetworkStep), findsNothing);
    expect(hotspots.stops, 1);
  });

  testWidgets('AC1: volver al tipo y seguir Por internet apaga la red y va '
      'directo a «Nueva frecu»', (tester) async {
    await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));
    await answer(
      tester,
      const Result.success(LocalHotspot(credentials: _wifi)),
    );

    await tap(tester, _iconButton('Atrás'));
    await tap(tester, find.text('Por internet'));
    await tap(tester, find.text('Seguir'));

    expect(hotspots.stops, 1);
    expect(find.byType(LocalNetworkStep), findsNothing);
    expect(find.byType(NewRoomStep), findsOneWidget);
    expect(_label('Paso 2 de 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('con la zona Wi-Fi encendida lo dice, abre sus ajustes y deja '
      'seguir con ella', (tester) async {
    await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));

    await answer(
      tester,
      const Result.failure(Failure.hotspot(HotspotFailureReason.hotspotOn)),
    );

    expect(
      find.textContaining('Tu zona Wi-Fi está encendida.'),
      findsOneWidget,
    );
    expect(_button('Reintentar'), findsOneWidget);
    await tap(tester, find.text('Abrir ajustes de la zona Wi-Fi'));
    expect(settings.opened, ['hotspot']);

    await tap(tester, _button('Reintentar'));
    expect(hotspots.starts, 2);
  });

  testWidgets('«Seguir con mi zona Wi-Fi» lleva a la nueva frecu', (
    tester,
  ) async {
    await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));
    await answer(
      tester,
      const Result.failure(Failure.hotspot(HotspotFailureReason.hotspotOn)),
    );

    await tap(tester, _button('Seguir con mi zona Wi-Fi'));

    expect(find.byType(NewRoomStep), findsOneWidget);
  });

  testWidgets('sin permiso lo dice y abre los ajustes de Frecu', (
    tester,
  ) async {
    await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));

    await answer(
      tester,
      const Result.failure(Failure.hotspot(HotspotFailureReason.nearbyDenied)),
    );

    expect(
      find.textContaining('Falta el permiso de dispositivos cercanos.'),
      findsOneWidget,
    );
    await tap(tester, find.text('Abrir ajustes de Frecu'));
    expect(settings.opened, ['app']);
    expect(_button('Prefiero mi zona Wi-Fi'), findsOneWidget);
  });

  testWidgets('con la ubicación apagada abre sus ajustes', (tester) async {
    await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));

    await answer(
      tester,
      const Result.failure(Failure.hotspot(HotspotFailureReason.locationOff)),
    );

    expect(find.textContaining('La ubicación está apagada.'), findsOneWidget);
    await tap(tester, find.text('Abrir ajustes de ubicación'));
    expect(settings.opened, ['location']);
  });

  testWidgets('en Android 7 solo queda la guía', (tester) async {
    await pumpCreate(tester);
    await tap(tester, _button('Crear la red'));

    await answer(
      tester,
      const Result.failure(Failure.hotspot(HotspotFailureReason.unsupported)),
    );

    expect(
      find.textContaining('Este teléfono no puede crear la red.'),
      findsOneWidget,
    );
    expect(_button('Reintentar'), findsNothing);
    await tap(tester, _button('Prefiero mi zona Wi-Fi'));
    expect(find.byType(HotspotGuideStep), findsOneWidget);
  });

  testWidgets('«Prefiero mi zona Wi-Fi» abre la guía y Atrás vuelve', (
    tester,
  ) async {
    await pumpCreate(tester);

    await tap(tester, _button('Prefiero mi zona Wi-Fi'));

    expect(find.byType(HotspotGuideStep), findsOneWidget);
    expect(find.text('Activa tu punto de acceso'), findsOneWidget);

    await tap(tester, _iconButton('Atrás'));

    expect(find.byType(LocalNetworkStep), findsOneWidget);
    expect(find.text('Frecu crea la red'), findsOneWidget);
  });

  testWidgets('en la guía, la zona Wi-Fi se guarda para invitar por '
      'Bluetooth y la frecu abierta con ella encendida la lleva', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    when(() => network.getNetworkState()).thenAnswer(
      (_) async => const Result.success(
        NetworkState.connected(
          ipAddress: '192.168.62.1',
          interfaceName: 'swlan0',
          isHotspot: true,
        ),
      ),
    );
    final container = await pumpCreate(tester);
    await tap(tester, _button('Prefiero mi zona Wi-Fi'));

    final save = _button('Guardarla para invitar por Bluetooth');
    await tester.ensureVisible(save);
    await tap(tester, save);
    expect(find.text('Tu zona Wi-Fi'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('hotspot_ssid')),
        matching: find.byType(EditableText),
      ),
      ' Moto de Andrés ',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('hotspot_key')),
        matching: find.byType(EditableText),
      ),
      'clave-1234',
    );
    await tester.pump();
    await tap(tester, find.byKey(const Key('hotspot_save')));

    const saved = WifiCredentials(
      ssid: 'Moto de Andrés',
      passphrase: 'clave-1234',
    );
    expect(container.read(preferencesProvider).value?.hotspot, saved);
    expect(_button('Zona Wi-Fi guardada · editar'), findsOneWidget);

    await tap(tester, _button('Ya está activo'));
    await tap(tester, _button('Abrir frecu'));

    expect(container.read(roomNotifierProvider)?.wifi, saved);
  });

  testWidgets('sin la zona Wi-Fi encendida, la clave guardada no viaja', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          PreferencesRepositoryImpl.hotspotKey:
              '{"ssid":"Moto de Andrés","passphrase":"clave-1234"}',
        });
    when(() => network.getNetworkState()).thenAnswer(
      (_) async => const Result.success(
        NetworkState.connected(
          ipAddress: '192.168.1.20',
          interfaceName: 'wlan0',
          isHotspot: false,
        ),
      ),
    );
    final container = await pumpCreate(tester);
    await container.read(preferencesProvider.future);
    await tap(tester, _button('Prefiero mi zona Wi-Fi'));
    await tap(tester, _button('Ya está activo'));
    await tap(tester, _button('Abrir frecu'));

    expect(container.read(roomNotifierProvider)?.wifi, isNull);
  });

  testWidgets('en iPhone la guía no ofrece guardar la zona Wi-Fi', (
    tester,
  ) async {
    await pumpCreate(tester, android: false);

    expect(_button('Guardarla para invitar por Bluetooth'), findsNothing);
  });

  testWidgets('AC1: en iPhone, tras «¿Cómo se une tu grupo?», sigue la guía', (
    tester,
  ) async {
    await pumpCreate(tester, android: false);

    expect(find.byType(HotspotGuideStep), findsOneWidget);
    expect(find.byType(LocalNetworkStep), findsNothing);
  });
}
