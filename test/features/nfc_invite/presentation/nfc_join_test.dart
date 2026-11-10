// Invitar por NFC y enlaces frecu:// (corte 9 de la épica de hardware V1),
// desde el inicio: con NFC, el dock lleva «Por IP» y «Por NFC»; leer la
// invitación la muestra encontrada y abre su tarjeta como un QR leído; un
// enlace frecu://join que abre la app hace lo mismo, salvo con una frecu
// activa.
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/data/datasources/invite_links_datasource.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/pages/scan_qr_page.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/invite_links_provider.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/nfc_invite/domain/repositories/nfc_invite_repository.dart';
import 'package:frecu/features/nfc_invite/presentation/providers/nfc_invite_provider.dart';
import 'package:frecu/features/nfc_invite/presentation/widgets/nfc_join_sheet.dart';
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

/// NFC de prueba: la lectura espera a que la prueba la conteste.
class _FakeNfc implements NfcInviteRepository {
  _FakeNfc({this.supported = true});

  final bool supported;
  Completer<Result<String>>? reading;
  int cancels = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<Result<String>> readInvite() => (reading = Completer()).future;

  @override
  Future<Result<void>> writeInvite(String uri) async =>
      const Result.success(null);

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<bool> share(String? uri) async => false;
}

const _scannerStub = Key('scanner_stub');

/// El escáner no enciende la cámara; la frecu activa se sustituye.
class _TestRouter extends AppRouter {
  @override
  List<AutoRoute> get routes => [
    for (final route in super.routes)
      if (route.name == ScanQrRoute.name)
        AutoRoute(
          page: PageInfo(
            ScanQrRoute.name,
            builder: (data) => ScanQrPage(
              invite: data
                  .argsAs<ScanQrRouteArgs>(orElse: ScanQrRouteArgs.new)
                  .invite,
              scannerBuilder: (_, _, _) =>
                  const ColoredBox(color: Colors.black, key: _scannerStub),
            ),
          ),
          path: '/scan-qr',
        )
      else if (route.name == RoomRoute.name)
        AutoRoute(
          page: PageInfo(RoomRoute.name, builder: (_) => const SizedBox()),
          path: '/room/:roomId',
        )
      else
        route,
  ];
}

const _invite =
    'frecu://join?h=192.168.49.1&p=47800&r=room-nfc&c=4827&n=9&name=Caravana';

Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is FrButton && widget.label == label,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late _MockRoomRepository rooms;
  late StreamController<Uri> links;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          PreferencesRepositoryImpl.displayNameKey: 'Ana',
        });
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    rooms = _MockRoomRepository();
    links = StreamController<Uri>.broadcast();
    when(() => discovery.watchNearbyRooms())
        .thenAnswer((_) => Stream.value(const <NearbyRoom>[]));
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(() => network.watchNetworkState()).thenAnswer(
      (_) => Stream.value(
        const NetworkState.connected(
          ipAddress: '192.168.49.20',
          interfaceName: 'wlan0',
          isHotspot: false,
        ),
      ),
    );
    when(() => rooms.getLocalIpAddress()).thenAnswer((_) async => null);
  });

  tearDown(() => links.close());

  Future<(AppRouter, ProviderContainer)> pumpLobby(
    WidgetTester tester,
    _FakeNfc nfc,
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
        nfcInviteRepositoryProvider.overrideWithValue(nfc),
        inviteLinksProvider.overrideWithValue(
          InviteLinksDataSource(links: links.stream),
        ),
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
    return (router, container);
  }

  testWidgets('sin NFC el dock sigue con «Conectar por IP»', (tester) async {
    await pumpLobby(tester, _FakeNfc(supported: false));

    expect(_button('Conectar por IP'), findsOneWidget);
    expect(_button('Por NFC'), findsNothing);
  });

  testWidgets('con NFC, «Por NFC» lee la invitación, la muestra encontrada '
      'y abre su tarjeta como un QR leído, sin cámara', (tester) async {
    final nfc = _FakeNfc();
    await pumpLobby(tester, nfc);
    expect(_button('Por IP'), findsOneWidget);

    await tester.tap(_button('Por NFC'));
    await tester.pumpAndSettle();
    expect(find.byType(NfcJoinSheet), findsOneWidget);
    expect(find.text('Acerca tu teléfono'), findsOneWidget);

    nfc.reading!.complete(const Result.success(_invite));
    await tester.pump();
    await tester.pump();
    expect(find.text('Frecu encontrada'), findsOneWidget);
    await tester.pump(NfcJoinSheet.foundDelay);
    await tester.pumpAndSettle();

    expect(find.byType(NfcJoinSheet), findsNothing);
    expect(find.byType(ScanQrPage), findsOneWidget);
    expect(find.text('Caravana'), findsOneWidget);
    expect(_button('Unirme'), findsOneWidget);
  });

  testWidgets('si lo que se acercó no trae una invitación, lo dice y '
      'Reintentar vuelve a leer; cerrar cancela', (tester) async {
    final nfc = _FakeNfc();
    await pumpLobby(tester, nfc);
    await tester.tap(_button('Por NFC'));
    await tester.pumpAndSettle();

    nfc.reading!.complete(
      const Result.failure(Failure.nfc(NfcFailureReason.notInvite)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FrBanner>(find.byKey(const Key('nfc_join_failure'))).title,
      'Eso no trae una invitación de Frecu.',
    );

    final first = nfc.reading;
    await tester.tap(_button('Reintentar'));
    await tester.pumpAndSettle();
    expect(nfc.reading, isNot(same(first)));
    expect(find.byKey(const Key('nfc_join_failure')), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(NfcJoinSheet),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is FrIconButton && widget.semanticLabel == 'Cerrar',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NfcJoinSheet), findsNothing);
    expect(nfc.cancels, 1);
  });

  testWidgets('un enlace frecu://join abre su tarjeta; con una frecu activa '
      'se ignora', (tester) async {
    final (router, container) = await pumpLobby(tester, _FakeNfc());

    links.add(Uri.parse(_invite));
    await tester.pumpAndSettle();
    expect(find.byType(ScanQrPage), findsOneWidget);
    expect(find.text('Caravana'), findsOneWidget);

    router.popUntilRoot();
    await tester.pumpAndSettle();
    when(
      () => rooms.joinRoom(
        hostAddress: any(named: 'hostAddress'),
        port: any(named: 'port'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        Room(
          id: 'room-1',
          name: 'Otra',
          hostAddress: '192.168.49.1',
          port: 47800,
          accessCode: '1111',
          createdAt: DateTime(2026, 11, 10),
        ),
      ),
    );
    await container
        .read(roomNotifierProvider.notifier)
        .joinRoom(
          hostAddress: '192.168.49.1',
          port: 47800,
          accessCode: '1111',
          displayName: 'Ana',
        );
    await tester.pumpAndSettle();

    links.add(Uri.parse(_invite));
    await tester.pumpAndSettle();
    expect(find.byType(ScanQrPage), findsNothing);
  });

  testWidgets('otros enlaces no abren nada', (tester) async {
    await pumpLobby(tester, _FakeNfc());

    links.add(Uri.parse('https://frecu.app/join?h=1'));
    await tester.pumpAndSettle();

    expect(find.byType(ScanQrPage), findsNothing);
  });
}
