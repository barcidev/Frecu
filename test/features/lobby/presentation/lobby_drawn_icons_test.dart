// AC1: CUANDO se abre la hoja de conexión por IP ENTONCES el campo «IP del anfitrión» dibuja `FrIcons.nodes` y el de «Código de acceso» dibuja `FrIcons.lock`, con `FrIcon` y sin ningún `Icon` de Material en la hoja.
// AC2: CUANDO una unión por código o por IP falla porque la frecu está llena ENTONCES el aviso ámbar dibuja `FrIcons.users`; CUANDO falla por otro motivo que no es el código (por ejemplo, el anfitrión no responde) ENTONCES el aviso de alerta dibuja `FrIcons.alert`; en los dos casos con `FrIcon` y sin ningún `Icon` de Material en la hoja.
// AC3: CUANDO el inicio no tiene red local ni frecus cercanas ENTONCES el aviso de alerta «No estás en ninguna red Wi-Fi.» dibuja `FrIcons.wifi` con `FrIcon`, sin ningún `Icon` de Material en el aviso.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
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

/// Mi4: 329,6 Hz.
const _ruta = NearbyRoom(
  roomId: 'room-ruta',
  name: 'Ruta del domingo',
  hostAddress: '192.168.43.1',
  port: 47812,
  note: RoomNote(semitone: 4),
);

/// Ícono propio [icon] dibujado con `FrIcon`.
Finder _drawn(FrIconData icon) => find.byWidgetPredicate(
  (widget) => widget is FrIcon && widget.icon == icon,
  description: 'FrIcon «${icon.name}»',
);

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is FrField && widget.label == label,
);

Finder _inField(String label, Finder finder) =>
    find.descendant(of: _field(label), matching: finder);

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(FrSheet), matching: finder);

Finder _inBanner(Finder finder) =>
    find.descendant(of: find.byType(FrBanner), matching: finder);

FrBanner _banner(WidgetTester tester) =>
    tester.widget<FrBanner>(find.byType(FrBanner));

/// Escribe [digits] con el teclado propio de la hoja de código.
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

  void answerJoin(Failure failure) => when(
    () => rooms.joinRoom(
      hostAddress: any(named: 'hostAddress'),
      port: any(named: 'port'),
      accessCode: any(named: 'accessCode'),
      displayName: any(named: 'displayName'),
    ),
  ).thenAnswer((_) async => Result<Room>.failure(failure));

  void answerNetwork(NetworkState state) =>
      when(() => network.watchNetworkState())
          .thenAnswer((_) => Stream.value(state));

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

    when(() => discovery.watchNearbyRooms()).thenAnswer((_) => nearby.stream);
    when(() => discovery.dispose()).thenAnswer((_) async {});
    answerNetwork(
      const NetworkState.connected(
        ipAddress: '192.168.43.27',
        interfaceName: 'wlan0',
        isHotspot: false,
      ),
    );
    when(() => rooms.getLocalIpAddress())
        .thenAnswer((_) async => '192.168.43.27');
    answerJoin(const Failure.invalidAccessCode());
  });

  tearDown(() async {
    await nearby.close();
  });

  /// Abre la app en el inicio, en un teléfono de 390 × 844, con movimiento
  /// reducido y el nombre «Ana» ya leído.
  Future<void> pumpLobby(WidgetTester tester) async {
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
      ],
    );
    addTearDown(container.dispose);
    await container.read(preferencesProvider.future);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: FrecuApp(appRouter: AppRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('IpJoinSheet', () {
    /// Abre la hoja por IP y pide unirse con una IP y un código completos.
    Future<void> openIp(WidgetTester tester, {bool connect = false}) async {
      await tester.tap(find.text(t.lobby.joinRoom));
      await tester.pumpAndSettle();
      if (!connect) return;
      await tester.enterText(
        _inField('IP del anfitrión', find.byType(TextField)),
        '192.168.43.50',
      );
      await tester.enterText(
        _inField('Código de acceso', find.byType(TextField)),
        '4827',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is FrButton && widget.label == 'Conectar',
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'AC1: la IP dibuja FrIcons.nodes y el código FrIcons.lock, sin íconos '
      'de Material en la hoja',
      (tester) async {
        await pumpLobby(tester);
        await openIp(tester);

        expect(_inField('IP del anfitrión', _drawn(FrIcons.nodes)), findsOne);
        expect(_inField('Código de acceso', _drawn(FrIcons.lock)), findsOne);
        expect(_inSheet(find.byType(Icon)), findsNothing);
      },
    );

    testWidgets('AC2: si el anfitrión no responde el aviso de alerta dibuja '
        'FrIcons.alert', (tester) async {
      answerJoin(const Failure.hostUnreachable());
      await pumpLobby(tester);
      await openIp(tester, connect: true);

      expect(_banner(tester).tone, FrBannerTone.alert);
      expect(_inBanner(_drawn(FrIcons.alert)), findsOneWidget);
      expect(_inSheet(find.byType(Icon)), findsNothing);
    });

    testWidgets('AC2: con la frecu llena el aviso ámbar dibuja FrIcons.users', (
      tester,
    ) async {
      answerJoin(const Failure.roomFull());
      await pumpLobby(tester);
      await openIp(tester, connect: true);

      expect(_banner(tester).tone, FrBannerTone.warn);
      expect(_inBanner(_drawn(FrIcons.users)), findsOneWidget);
      expect(_inSheet(find.byType(Icon)), findsNothing);
    });
  });

  group('PinJoinSheet', () {
    /// Abre la hoja de código de [_ruta] y escribe los 4 dígitos.
    Future<void> sendPin(WidgetTester tester) async {
      nearby.add([_ruta]);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_ruta.name));
      await tester.pumpAndSettle();
      await _type(tester, '4827');
    }

    testWidgets('AC2: con la frecu llena el aviso ámbar dibuja FrIcons.users', (
      tester,
    ) async {
      answerJoin(const Failure.roomFull());
      await pumpLobby(tester);
      await sendPin(tester);

      expect(_banner(tester).tone, FrBannerTone.warn);
      expect(_inBanner(_drawn(FrIcons.users)), findsOneWidget);
      expect(_inSheet(find.byType(Icon)), findsNothing);
    });

    testWidgets(
      'AC2: si falla por otro motivo el aviso de alerta dibuja FrIcons.alert',
      (tester) async {
        answerJoin(const Failure.hostUnreachable());
        await pumpLobby(tester);
        await sendPin(tester);

        expect(_banner(tester).tone, FrBannerTone.alert);
        expect(_inBanner(_drawn(FrIcons.alert)), findsOneWidget);
        expect(_inSheet(find.byType(Icon)), findsNothing);
      },
    );
  });

  group('Inicio sin red', () {
    testWidgets(
      'AC3: el aviso «No estás en ninguna red Wi-Fi.» dibuja FrIcons.wifi, '
      'sin íconos de Material',
      (tester) async {
        answerNetwork(const NetworkState.disconnected());
        await pumpLobby(tester);
        nearby.add([]);
        await tester.pumpAndSettle();

        expect(_banner(tester).tone, FrBannerTone.alert);
        expect(_banner(tester).title, 'No estás en ninguna red Wi-Fi.');
        expect(_inBanner(_drawn(FrIcons.wifi)), findsOneWidget);
        expect(_inBanner(find.byType(Icon)), findsNothing);
      },
    );
  });
}
