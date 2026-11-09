// Invitar por Bluetooth (corte 8 de la épica de hardware V1), desde el
// inicio del invitado: la frecu encontrada solo por Bluetooth sale en
// «Cercanas» con «Por Bluetooth» y la pista; con el código, el anfitrión
// entrega la invitación, el teléfono entra a su red (con la hoja de la
// Wi-Fi si aún no está en ella) y a la frecu.
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/bluetooth_invite/domain/repositories/bluetooth_invite_repository.dart';
import 'package:frecu/features/bluetooth_invite/presentation/providers/bluetooth_invite_provider.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/wifi_join_sheet.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/domain/repositories/wifi_join_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
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

/// Bluetooth del invitado: la prueba pone las frecus y la respuesta.
class _FakeBluetooth implements BluetoothInviteRepository {
  final rooms = StreamController<List<NearbyRoom>>.broadcast();
  Result<RoomInvite> answer = const Result.failure(Failure.invalidAccessCode());
  final List<String> codes = [];

  @override
  Stream<List<NearbyRoom>> watchNearbyRooms() => rooms.stream;

  @override
  Future<Result<RoomInvite>> requestInvite(NearbyRoom room, String code) async {
    codes.add(code);
    return answer;
  }

  @override
  Future<Result<void>> advertise(RoomInvite invite) async =>
      const Result.success(null);

  @override
  Future<void> stopAdvertising() async {}
}

/// Red del invitado: responde o no, y la conexión a la red acierta.
class _FakeWifi implements WifiJoinRepository {
  bool reachable = false;
  final List<String> calls = [];

  /// Si está, la conexión a la red espera a que la prueba la complete.
  Completer<Result<void>>? pending;

  @override
  Future<bool> route(String host) async => false;

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
  }) async {
    calls.add('join ${credentials.ssid}');
    return pending?.future ?? const Result.success(null);
  }

  @override
  Future<void> release() async => calls.add('release');
}

const _roomStub = Key('room_stub');

class _RouterWithoutRoom extends AppRouter {
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

/// La9 (440 Hz), encontrada solo por Bluetooth.
const _caravana = NearbyRoom(
  roomId: 'room-ble',
  name: 'Caravana Sur',
  hostAddress: '',
  port: 0,
  note: RoomNote(semitone: 9),
  bluetoothId: 'b1',
);

const _wifi = WifiCredentials(ssid: 'DIRECT-frecu', passphrase: 'clave');

const _invite = RoomInvite(
  host: '192.168.49.1',
  port: 47800,
  roomId: 'room-ble',
  accessCode: '4827',
  name: 'Caravana Sur',
  wifi: _wifi,
);

Finder _label(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText())?.toLowerCase() ==
          text.toLowerCase(),
);

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(FrSheet), matching: finder);

Future<void> _type(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.byKey(ValueKey('fr-key-$digit')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late _MockRoomRepository rooms;
  late StreamController<List<NearbyRoom>> nearby;
  late _FakeBluetooth bluetooth;
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
    nearby = StreamController<List<NearbyRoom>>.broadcast();
    bluetooth = _FakeBluetooth();
    wifi = _FakeWifi();
    when(() => discovery.watchNearbyRooms()).thenAnswer((_) => nearby.stream);
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(() => discovery.stopPublishing())
        .thenAnswer((_) async => const Result<void>.success(null));
    when(() => network.watchNetworkState())
        .thenAnswer((_) => Stream.value(const NetworkState.disconnected()));
    when(() => rooms.getLocalIpAddress()).thenAnswer((_) async => null);
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
          id: 'room-ble',
          name: 'Caravana Sur',
          hostAddress: '192.168.49.1',
          port: 47800,
          accessCode: '4827',
          createdAt: DateTime(2026, 11, 10),
        ),
      ),
    );
    when(() => rooms.leaveRoom())
        .thenAnswer((_) async => const Result<void>.success(null));
  });

  tearDown(() async {
    await nearby.close();
    await bluetooth.rooms.close();
  });

  Future<ProviderContainer> pumpLobby(WidgetTester tester) async {
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
        bluetoothInviteRepositoryProvider.overrideWithValue(bluetooth),
        wifiJoinRepositoryProvider.overrideWithValue(wifi),
      ],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: FrecuApp(appRouter: _RouterWithoutRoom()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openCaravana(WidgetTester tester) async {
    bluetooth.rooms.add([_caravana]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caravana Sur'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin red local, la frecu por Bluetooth sale en Cercanas con '
      '«Por Bluetooth» y la pista; si también está en la red, va una vez', (
    tester,
  ) async {
    await pumpLobby(tester);
    bluetooth.rooms.add([_caravana]);
    await tester.pumpAndSettle();

    expect(find.text('Caravana Sur'), findsOneWidget);
    expect(find.text('Por Bluetooth'), findsOneWidget);
    expect(find.byKey(const Key('lobby_bluetooth_hint')), findsOneWidget);

    nearby.add([
      _caravana.copyWith(hostAddress: '192.168.49.1', bluetoothId: null),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Caravana Sur'), findsOneWidget);
    expect(find.text('Por Bluetooth'), findsNothing);
    expect(find.byKey(const Key('lobby_bluetooth_hint')), findsNothing);
  });

  testWidgets('con un código equivocado, las celdas pasan a error y no se '
      'toca la red ni se une', (tester) async {
    await pumpLobby(tester);
    await openCaravana(tester);
    expect(_inSheet(_label('La4 · 440,0 Hz · Por Bluetooth')), findsOneWidget);

    await _type(tester, '1111');

    expect(bluetooth.codes, ['1111']);
    expect(
      tester.widget<FrPinField>(find.byType(FrPinField)).state,
      FrPinState.error,
    );
    expect(wifi.calls, isEmpty);
    verifyNever(
      () => rooms.joinRoom(
        hostAddress: any(named: 'hostAddress'),
        port: any(named: 'port'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    );
  });

  testWidgets('si el anfitrión no responde por Bluetooth, lo dice con su '
      'pista', (tester) async {
    bluetooth.answer = const Result.failure(Failure.hostUnreachable());
    await pumpLobby(tester);
    await openCaravana(tester);

    await _type(tester, '4827');

    final banner = tester.widget<FrBanner>(find.byType(FrBanner));
    expect(banner.title, 'El anfitrión no responde por Bluetooth.');
    expect(banner.message, 'Acércate a su teléfono e intenta otra vez.');
  });

  testWidgets('con el código correcto y fuera de su red, se conecta a la red '
      'con la hoja de la Wi-Fi y entra con la invitación', (tester) async {
    bluetooth.answer = const Result.success(_invite);
    wifi.pending = Completer();
    final container = await pumpLobby(tester);
    await openCaravana(tester);

    await _type(tester, '4827');
    expect(find.byType(WifiJoinSheet), findsOneWidget);
    expect(find.text('Conectando a la Wi-Fi «DIRECT-frecu»…'), findsOneWidget);
    wifi.pending!.complete(const Result.success(null));
    await tester.pumpAndSettle();

    expect(wifi.calls, ['reaches 192.168.49.1:47800', 'join DIRECT-frecu']);
    verify(
      () => rooms.joinRoom(
        hostAddress: '192.168.49.1',
        port: 47800,
        accessCode: '4827',
        displayName: 'Ana',
      ),
    ).called(1);
    expect(find.byType(PinJoinSheet), findsNothing);
    expect(find.byKey(_roomStub), findsOneWidget);
    expect(container.read(roomNotifierProvider)?.wifi, _wifi);
    expect(wifi.calls, isNot(contains('release')));
  });

  testWidgets('si ya está en su red, entra sin la hoja de la Wi-Fi', (
    tester,
  ) async {
    bluetooth.answer = const Result.success(_invite);
    wifi.reachable = true;
    await pumpLobby(tester);
    await openCaravana(tester);

    await _type(tester, '4827');

    expect(wifi.calls, ['reaches 192.168.49.1:47800']);
    expect(find.byKey(_roomStub), findsOneWidget);
  });
}
