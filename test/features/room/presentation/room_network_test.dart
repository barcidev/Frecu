// Red de Frecu en la frecu activa: al crearla con la red de Frecu, o al unirse con un QR que la trae, la frecu lleva la red; antes de unirse, la app se ata a la red del anfitrión; al salir suelta la red y apaga la que creó. La hoja de invitar suma la red y su clave bajo la ficha y lo dice en su mensaje. Si Android apaga la red, el anfitrión ve «La red de la frecu se apagó» y, al crearla de nuevo, la invitación lleva la red y la IPv4 nuevas; si no se puede, lo dice.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/domain/entities/local_hotspot.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/domain/repositories/local_hotspot_repository.dart';
import 'package:frecu/features/network/domain/repositories/wifi_join_repository.dart';
import 'package:frecu/features/network/presentation/providers/local_hotspot_provider.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/widgets/invite_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/room_network_notice.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

class _FakeWifi implements WifiJoinRepository {
  final List<String> calls = [];

  @override
  Future<bool> route(String host) async {
    calls.add('route $host');
    return true;
  }

  @override
  Future<bool> reaches(String host, int port) async => true;

  @override
  Future<Result<void>> join(
    WifiCredentials credentials, {
    required String host,
    required int port,
  }) async => const Result.success(null);

  @override
  Future<void> release() async => calls.add('release');
}

class _FakeHotspots implements LocalHotspotRepository {
  final StreamController<void> stopped = StreamController<void>.broadcast();
  final List<Result<LocalHotspot>> answers = [];
  int stops = 0;

  @override
  Future<Result<LocalHotspot>> start() async => answers.removeAt(0);

  @override
  Future<void> stop() async => stops++;

  @override
  Stream<void> watchStopped() => stopped.stream;
}

const _wifi = WifiCredentials(
  ssid: 'AndroidShare_4821',
  passphrase: 'a3f91c7e5b2d',
);
const _newWifi = WifiCredentials(
  ssid: 'AndroidShare_9034',
  passphrase: '77c0de11aa42',
);

Room _room({String host = '192.168.62.1'}) => Room(
  id: 'room-1',
  name: 'Ruta',
  hostAddress: host,
  port: 47800,
  accessCode: '4827',
  createdAt: DateTime(2026, 11, 9, 20, 15),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRoomRepository rooms;
  late _FakeWifi wifi;
  late _FakeHotspots hotspots;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    rooms = _MockRoomRepository();
    wifi = _FakeWifi();
    hotspots = _FakeHotspots();
    when(
      () => rooms.createRoom(
        name: any(named: 'name'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Result.success(_room()));
    when(
      () => rooms.joinRoom(
        hostAddress: any(named: 'hostAddress'),
        port: any(named: 'port'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => Result.success(_room()));
    when(() => rooms.leaveRoom())
        .thenAnswer((_) async => const Result<void>.success(null));
    when(() => rooms.getLocalIpAddress()).thenAnswer((_) async => '10.4.4.1');
    when(() => rooms.localParticipantId).thenReturn(null);
  });

  tearDown(() => hotspots.stopped.close());

  ProviderContainer container({bool android = true}) {
    final created = ProviderContainer.test(
      overrides: [
        roomRepositoryProvider.overrideWithValue(rooms),
        wifiJoinRepositoryProvider.overrideWithValue(wifi),
        localHotspotRepositoryProvider.overrideWithValue(hotspots),
        localHotspotAvailableProvider.overrideWithValue(android),
      ],
    );
    return created;
  }

  group('RoomNotifier con la red de la frecu', () {
    test('al crearla con la red de Frecu, la frecu la lleva', () async {
      final c = container();

      await c
          .read(roomNotifierProvider.notifier)
          .createRoom(name: 'Ruta', accessCode: '4827', wifi: _wifi);

      expect(c.read(roomNotifierProvider)?.wifi, _wifi);
    });

    test('al unirse se ata a la red del anfitrión y la frecu lleva la red del '
        'QR', () async {
      final c = container();

      await c
          .read(roomNotifierProvider.notifier)
          .joinRoom(
            hostAddress: '192.168.62.1',
            port: 47800,
            accessCode: '4827',
            displayName: 'Ana',
            wifi: _wifi,
          );

      expect(wifi.calls, ['route 192.168.62.1']);
      expect(c.read(roomNotifierProvider)?.wifi, _wifi);
    });

    test('al salir suelta la red y apaga la que creó', () async {
      final c = container();
      hotspots.answers.add(
        const Result.success(LocalHotspot(credentials: _wifi)),
      );
      await c.read(localHotspotProvider.notifier).start();
      await c
          .read(roomNotifierProvider.notifier)
          .createRoom(name: 'Ruta', accessCode: '4827', wifi: _wifi);

      await c.read(roomNotifierProvider.notifier).leaveRoom();
      await Future<void>.delayed(Duration.zero);

      expect(c.read(roomNotifierProvider), isNull);
      expect(wifi.calls, contains('release'));
      expect(hotspots.stops, 1);
      expect(c.read(localHotspotProvider), const LocalHotspotState.off());
    });

    test(
      'useNetwork cambia la red y, si llega, la IPv4 del anfitrión',
      () async {
        final c = container();
        // Sin frecu no hay red que cambiar.
        final notifier = c.read(roomNotifierProvider.notifier)
          ..useNetwork(_newWifi);
        expect(c.read(roomNotifierProvider), isNull);

        await notifier.createRoom(
          name: 'Ruta',
          accessCode: '4827',
          wifi: _wifi,
        );
        notifier.useNetwork(_newWifi, hostAddress: '10.4.4.1');

        expect(c.read(roomNotifierProvider)?.wifi, _newWifi);
        expect(c.read(roomNotifierProvider)?.hostAddress, '10.4.4.1');

        notifier.useNetwork(_wifi);
        expect(c.read(roomNotifierProvider)?.hostAddress, '10.4.4.1');
      },
    );
  });

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer c,
    Widget child,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // El haz del QR se mueve sin fin: con movimiento reducido queda quieto.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Hoja de invitar', () {
    testWidgets('con la red suma su nombre y su clave bajo la ficha', (
      tester,
    ) async {
      final c = container();
      addTearDown(c.dispose);

      await pump(tester, c, InviteSheet(room: _room().copyWith(wifi: _wifi)));

      expect(
        find.text(
          'Desde Frecu › Escanear. El QR ya lleva la red, su clave y el '
          'código.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('invite_network')), findsOneWidget);
      expect(find.text('AndroidShare_4821'), findsOneWidget);
      expect(find.textContaining('a3f91c7e5b2d'), findsOneWidget);
      expect(find.text('A MANO'), findsOneWidget);
    });

    testWidgets('una red abierta lo dice; sin red no hay fila', (tester) async {
      final c = container();
      addTearDown(c.dispose);

      await pump(
        tester,
        c,
        InviteSheet(
          room: _room().copyWith(wifi: const WifiCredentials(ssid: 'Frecu')),
        ),
      );
      expect(find.text('Red abierta, sin clave'), findsOneWidget);

      await pump(tester, c, InviteSheet(room: _room()));
      expect(find.byKey(const Key('invite_network')), findsNothing);
      expect(
        find.text('Desde Frecu › Escanear. El QR ya incluye el código.'),
        findsOneWidget,
      );
    });
  });

  group('Aviso de la red apagada', () {
    Future<ProviderContainer> hostOnAir({bool android = true}) async {
      final c = container(android: android);
      hotspots.answers.add(
        const Result.success(
          LocalHotspot(credentials: _wifi, interfaceName: 'swlan0'),
        ),
      );
      await c.read(localHotspotProvider.notifier).start();
      await c
          .read(roomNotifierProvider.notifier)
          .createRoom(name: 'Ruta', accessCode: '4827', wifi: _wifi);
      return c;
    }

    testWidgets('con la red al aire no se ve nada', (tester) async {
      final c = await tester.runAsync(hostOnAir);
      addTearDown(c!.dispose);

      await pump(tester, c, const RoomNetworkNotice());

      expect(find.byType(RoomNetworkNotice), findsOneWidget);
      expect(find.textContaining('La red de la frecu'), findsNothing);
    });

    testWidgets('si Android la apaga, avisa y al crearla de nuevo la '
        'invitación lleva la red y la IPv4 nuevas', (tester) async {
      final c = await tester.runAsync(hostOnAir);
      addTearDown(c!.dispose);
      await pump(tester, c, const RoomNetworkNotice());

      hotspots.stopped.add(null);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('room_network_lost')), findsOneWidget);
      expect(
        find.textContaining('La red de la frecu se apagó.'),
        findsOneWidget,
      );

      hotspots.answers.add(
        const Result.success(
          LocalHotspot(credentials: _newWifi, interfaceName: 'swlan0'),
        ),
      );
      await tester.tap(find.text('Crear la red de nuevo'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('room_network_lost')), findsNothing);
      expect(c.read(roomNotifierProvider)?.wifi, _newWifi);
      expect(c.read(roomNotifierProvider)?.hostAddress, '10.4.4.1');
    });

    testWidgets('si no se puede crear de nuevo, lo dice', (tester) async {
      final c = await tester.runAsync(hostOnAir);
      addTearDown(c!.dispose);
      await pump(tester, c, const RoomNetworkNotice());
      hotspots.stopped.add(null);
      await tester.pumpAndSettle();

      hotspots.answers.add(
        const Result.failure(Failure.hotspot(HotspotFailureReason.hotspotOn)),
      );
      await tester.tap(find.text('Crear la red de nuevo'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('room_network_failed')), findsOneWidget);
      expect(c.read(roomNotifierProvider)?.wifi, _wifi);
    });

    testWidgets('en un teléfono que no crea la red no hay aviso', (
      tester,
    ) async {
      final c = await tester.runAsync(() => hostOnAir(android: false));
      addTearDown(c!.dispose);
      await pump(tester, c, const RoomNetworkNotice());

      hotspots.stopped.add(null);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('room_network_lost')), findsNothing);
    });
  });
}
