// Red de Frecu (invitado): un QR con la red de la frecu muestra «Red …» en la tarjeta; al tocar Unirme, si el anfitrión ya responde se une sin más; si no, la hoja conecta el teléfono a la red («Conectando a la Wi-Fi «…»…») y al lograrlo se une con la red en la frecu. Si el aviso se cancela o la red no aparece, lo dice con Reintentar y «Conectarme a mano»; a mano muestra la red y la clave y «Ya me conecté» sigue con la unión. Cerrar la hoja no se une, y salir del escáner sin entrar suelta la red. Un QR sin red se une como siempre, sin hoja.
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/pages/scan_qr_page.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/wifi_join_sheet.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/domain/repositories/wifi_join_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockNetworkRepository extends Mock implements NetworkRepository {}

class _MockRoomRepository extends Mock implements RoomRepository {}

/// Red del invitado: responde o no, y cada conexión espera a la prueba.
class _FakeWifi implements WifiJoinRepository {
  bool reachable = false;
  final List<String> calls = [];
  final List<Completer<Result<void>>> joins = [];

  @override
  Future<bool> route(String host) async {
    calls.add('route $host');
    return false;
  }

  @override
  Future<bool> reaches(String host, int port) async {
    calls.add('reaches $host:$port');
    return reachable;
  }

  @override
  Future<Result<void>> join(
    WifiCredentials credentials, {
    required String host,
    required int port,
  }) {
    calls.add('join ${credentials.ssid}');
    final answer = Completer<Result<void>>();
    joins.add(answer);
    return answer.future;
  }

  @override
  Future<void> release() async => calls.add('release');
}

const _scannerStub = Key('scanner_stub');
const _roomStub = Key('room_stub');

const _wifiInvite =
    'frecu://join?h=192.168.62.1&p=47800&r=room-qr&c=4827&n=7&name=Ruta'
    '&ws=AndroidShare_4821&wk=a3f91c7e5b2d';
const _plainInvite = 'frecu://join?h=192.168.43.1&p=47800&r=room-qr&c=4827';
const _wifi = WifiCredentials(
  ssid: 'AndroidShare_4821',
  passphrase: 'a3f91c7e5b2d',
);

/// El escáner lee lo que la prueba pasa a [onScan], y la frecu activa se
/// sustituye.
class _TestRouter extends AppRouter {
  void Function(String barcode)? onScan;

  @override
  List<AutoRoute> get routes => [
    for (final route in super.routes)
      if (route.name == ScanQrRoute.name)
        AutoRoute(
          page: PageInfo(
            ScanQrRoute.name,
            builder: (_) => ScanQrPage(
              scannerBuilder: (context, scan, issue) {
                onScan = scan;
                return const ColoredBox(color: Colors.black, key: _scannerStub);
              },
            ),
          ),
          path: '/scan-qr',
        )
      else if (route.name == RoomRoute.name)
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

Room _joined() => Room(
  id: 'room-qr',
  name: 'Ruta',
  hostAddress: '192.168.62.1',
  port: 47800,
  accessCode: '4827',
  createdAt: DateTime(2026, 11, 9, 20, 15),
);

Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is FrButton && widget.label == label,
);

Finder _iconButton(String label) => find.byWidgetPredicate(
  (widget) => widget is FrIconButton && widget.semanticLabel == label,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late _MockRoomRepository rooms;
  late _FakeWifi wifi;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          PreferencesRepositoryImpl.displayNameKey: 'Ana',
        });
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    rooms = _MockRoomRepository();
    wifi = _FakeWifi();

    when(() => discovery.watchNearbyRooms())
        .thenAnswer((_) => Stream.value(const <NearbyRoom>[]));
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(() => network.watchNetworkState()).thenAnswer(
      (_) => Stream.value(
        const NetworkState.connected(
          ipAddress: '192.168.43.27',
          interfaceName: 'wlan0',
          isHotspot: false,
        ),
      ),
    );
    when(
      () => rooms.joinRoom(
        hostAddress: any(named: 'hostAddress'),
        port: any(named: 'port'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => Result.success(_joined()));
  });

  /// Abre el escáner con movimiento reducido y lee [invite].
  Future<(_TestRouter, ProviderContainer)> scan(
    WidgetTester tester,
    String invite,
  ) async {
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
        wifiJoinRepositoryProvider.overrideWithValue(wifi),
      ],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    final router = _TestRouter();
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: FrecuApp(appRouter: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lobby.scanQr));
    await tester.pumpAndSettle();
    router.onScan!(invite);
    await tester.pumpAndSettle();
    return (router, container);
  }

  Future<void> join(WidgetTester tester) async {
    await tester.tap(_button('Unirme'));
    await tester.pumpAndSettle();
  }

  void verifyJoined({int times = 1}) => verify(
    () => rooms.joinRoom(
      hostAddress: '192.168.62.1',
      port: 47800,
      accessCode: '4827',
      displayName: any(named: 'displayName'),
    ),
  ).called(times);

  testWidgets('la tarjeta dice a qué red se va a conectar', (tester) async {
    await scan(tester, _wifiInvite);

    expect(find.text('Red AndroidShare_4821'), findsOneWidget);
    expect(find.byKey(const Key('scan_found_network')), findsOneWidget);
  });

  testWidgets('un QR sin red no muestra red ni pasa por la hoja', (
    tester,
  ) async {
    await scan(tester, _plainInvite);

    expect(find.byKey(const Key('scan_found_network')), findsNothing);
    await join(tester);

    expect(find.byType(WifiJoinSheet), findsNothing);
    expect(wifi.calls, isNot(contains(startsWith('reaches'))));
    expect(find.byKey(_roomStub), findsOneWidget);
  });

  testWidgets('si el anfitrión ya responde se une sin la hoja y la frecu '
      'lleva la red', (tester) async {
    wifi.reachable = true;
    final (_, container) = await scan(tester, _wifiInvite);

    await join(tester);

    expect(find.byType(WifiJoinSheet), findsNothing);
    expect(wifi.calls.first, 'reaches 192.168.62.1:47800');
    verifyJoined();
    expect(container.read(roomNotifierProvider)?.wifi, _wifi);
    expect(find.byKey(_roomStub), findsOneWidget);
  });

  testWidgets('si no responde, la hoja conecta a la red y luego se une', (
    tester,
  ) async {
    await scan(tester, _wifiInvite);

    await join(tester);

    expect(find.byType(WifiJoinSheet), findsOneWidget);
    expect(
      find.text('Conectando a la Wi-Fi «AndroidShare_4821»…'),
      findsOneWidget,
    );
    expect(
      find.text('Tu teléfono te pedirá confirmar la red.'),
      findsOneWidget,
    );
    expect(wifi.calls, contains('join AndroidShare_4821'));
    verifyNever(
      () => rooms.joinRoom(
        hostAddress: any(named: 'hostAddress'),
        port: any(named: 'port'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    );

    wifi.joins.single.complete(const Result.success(null));
    await tester.pumpAndSettle();

    expect(find.byType(WifiJoinSheet), findsNothing);
    verifyJoined();
    expect(find.byKey(_roomStub), findsOneWidget);
  });

  testWidgets('si se cancela el aviso, lo dice y Reintentar vuelve a '
      'conectar', (tester) async {
    await scan(tester, _wifiInvite);
    await join(tester);

    wifi.joins.single.complete(
      const Result.failure(Failure.wifiJoin(WifiJoinFailureReason.declined)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No te conectaste a la red.'), findsOneWidget);
    expect(
      find.textContaining('Se canceló el aviso del sistema.'),
      findsOneWidget,
    );
    expect(_button('Reintentar'), findsOneWidget);
    expect(_button('Conectarme a mano'), findsOneWidget);

    await tester.tap(_button('Reintentar'));
    await tester.pumpAndSettle();

    expect(wifi.joins, hasLength(2));
    expect(
      find.text('Conectando a la Wi-Fi «AndroidShare_4821»…'),
      findsOneWidget,
    );
  });

  testWidgets('si la red no aparece, lo dice con su nombre', (tester) async {
    await scan(tester, _wifiInvite);
    await join(tester);

    wifi.joins.single.complete(
      const Result.failure(Failure.wifiJoin(WifiJoinFailureReason.notFound)),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No encontramos la red «AndroidShare_4821».'),
      findsOneWidget,
    );
  });

  testWidgets('a mano muestra la red y la clave, y «Ya me conecté» se une', (
    tester,
  ) async {
    await scan(tester, _wifiInvite);
    await join(tester);
    wifi.joins.single.complete(
      const Result.failure(Failure.wifiJoin(WifiJoinFailureReason.failed)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_button('Conectarme a mano'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Abre Ajustes › Wi-Fi, elige esta red y escribe la clave. Luego '
        'vuelve a Frecu.',
      ),
      findsOneWidget,
    );
    expect(find.text('AndroidShare_4821'), findsOneWidget);
    expect(find.text('a3f91c7e5b2d'), findsOneWidget);
    expect(_button('Abrir Wi-Fi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wifi_join_done')));
    await tester.pumpAndSettle();

    verifyJoined();
    expect(find.byKey(_roomStub), findsOneWidget);
  });

  testWidgets('un teléfono que no se conecta solo va directo a mano', (
    tester,
  ) async {
    await scan(tester, _wifiInvite);
    await join(tester);

    wifi.joins.single.complete(
      const Result.failure(Failure.wifiJoin(WifiJoinFailureReason.unsupported)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Este teléfono no se conecta solo a la red. Hazlo desde Ajustes › '
        'Wi-Fi con estos datos y vuelve a Frecu.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('wifi_join_done')), findsOneWidget);
  });

  testWidgets('cerrar la hoja no se une; salir del escáner suelta la red', (
    tester,
  ) async {
    await scan(tester, _wifiInvite);
    await join(tester);
    wifi.joins.single.complete(
      const Result.failure(Failure.wifiJoin(WifiJoinFailureReason.declined)),
    );
    await tester.pumpAndSettle();

    await tester.tap(_iconButton('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(WifiJoinSheet), findsNothing);
    expect(_button('Unirme'), findsOneWidget);
    verifyNever(
      () => rooms.joinRoom(
        hostAddress: any(named: 'hostAddress'),
        port: any(named: 'port'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    );

    await tester.tap(_iconButton('Atrás'));
    await tester.pumpAndSettle();

    expect(wifi.calls.last, 'release');
  });
}
