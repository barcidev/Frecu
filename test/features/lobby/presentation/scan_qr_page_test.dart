// AC6: CUANDO se abre el escáner ENTONCES se ve en tema oscuro la cámara bajo la retícula, arriba Atrás, «Escanear invitación», «QR de la frecu» y Linterna, que se enciende y se apaga, y abajo «Apunta al QR que muestra el anfitrión en su teléfono.» y Conectar por IP, que abre la hoja de AC4 y, al unirse, la frecu activa; CUANDO lee un QR que no es una invitación ENTONCES dice «Este QR no es una invitación de Frecu.» y sigue buscando.
// AC7: CUANDO el escáner lee una invitación válida ENTONCES la retícula se cierra sobre el código con el check y abajo aparece la tarjeta «Frecu encontrada», que desenfoca el fondo, con el nombre de la frecu y «<nota> · <IP>» si la invitación trae el nombre (P98), o con la nota y sus Hz (o «Frecu sin nota») y «<IP> · Puerto <p>» si no, y el botón Unirme, y no atiende otros QR; «Escanear otro QR» vuelve a buscar; CUANDO el usuario toca Unirme ENTONCES se une con la IP, el puerto, el código y la nota del QR y el nombre guardado y se abre la frecu activa en lugar del escáner; CUANDO falla ENTONCES se ve el aviso del error sobre la tarjeta y Unirme reintenta.
// AC9 (P97): CUANDO se niega el permiso de la cámara ENTONCES en lugar de la retícula y la indicación se ve «Frecu no tiene acceso a la cámara.» con su explicación, «Abrir ajustes» (abre los Ajustes de la app) y Conectar por IP, y la linterna no responde; CUANDO no hay cámara ENTONCES «La cámara no está disponible.» con Conectar por IP; CUANDO la cámara vuelve ENTONCES vuelven la retícula y la indicación. La cámara se para cuando la app deja de estar al frente y vuelve al regresar, también al volver de Ajustes, sin pedir el permiso sin fin.
// AC8: CUANDO la app está en inglés ENTONCES las hojas y el escáner muestran sus textos de la traducción `en`; CUANDO el sistema pide reducir el movimiento ENTONCES la retícula no respira, el haz queda quieto y el escáner no pide cuadros, sin ocultar el cierre sobre el código.
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/pages/scan_qr_page.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/ip_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/scan_reticle.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/domain/repositories/system_settings_repository.dart';
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

const _cameraStub = Key('scanner_stub');
const _roomStub = Key('room_stub');

/// Invitación a Sol4 (392,0 Hz).
const _invite = 'frecu://join?h=192.168.43.1&p=47800&r=room-qr&c=4827&n=7';

/// Router de la app sin cámara: el escáner lee lo que le pasa la prueba con
/// [onScan], la cámara falla con [onIssue], y la frecu activa se sustituye.
class _TestRouter extends AppRouter {
  void Function(String barcode)? onScan;
  void Function(ScanCameraIssue? issue)? onIssue;

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
                onIssue = issue;
                return const ColoredBox(color: Colors.black, key: _cameraStub);
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

Room _joined(String id) => Room(
  id: id,
  name: 'Frecu',
  hostAddress: '192.168.43.1',
  port: 47800,
  accessCode: '4827',
  createdAt: DateTime(2026, 11, 8, 16, 24),
);

/// El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
Future<void> _useEnglish(WidgetTester tester) async {
  await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
}

/// Texto que se muestra en mayúsculas por estilo: se busca sin distinguir
/// mayúsculas.
Finder _label(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      (widget.data ?? widget.textSpan?.toPlainText())?.toLowerCase() ==
          text.toLowerCase(),
  description: 'texto «$text» sin distinguir mayúsculas',
);

Finder _iconButton(String label) => find.byWidgetPredicate(
  (widget) => widget is FrIconButton && widget.semanticLabel == label,
);

Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is FrButton && widget.label == label,
);

Finder _inScanner(Finder finder) =>
    find.descendant(of: find.byType(ScanQrPage), matching: finder);

ScanReticle _reticle(WidgetTester tester) =>
    tester.widget<ScanReticle>(find.byType(ScanReticle));

Finder get _reticleLoop => find.descendant(
  of: find.byType(ScanReticle),
  matching: find.byType(FrLoop),
);

List<String> _stack(AppRouter router) =>
    router.stackData.map((data) => data.name).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late _MockRoomRepository rooms;
  late _FakeSettings settings;

  void answerJoin(Future<Result<Room>> Function() answer) => when(
    () => rooms.joinRoom(
      hostAddress: any(named: 'hostAddress'),
      port: any(named: 'port'),
      accessCode: any(named: 'accessCode'),
      displayName: any(named: 'displayName'),
    ),
  ).thenAnswer((_) => answer());

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          PreferencesRepositoryImpl.displayNameKey: 'Ana',
        });
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    rooms = _MockRoomRepository();
    settings = _FakeSettings();

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
    answerJoin(() async => Result.success(_joined('room-qr')));
  });

  /// Abre la app en un teléfono de 390 × 844 con el nombre «Ana» y toca
  /// Escanear; con [reduce] (por defecto) en movimiento reducido.
  Future<(_TestRouter, ProviderContainer)> pumpScanner(
    WidgetTester tester, {
    bool reduce = true,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    if (reduce) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(discovery),
        networkRepositoryProvider.overrideWithValue(network),
        roomRepositoryProvider.overrideWithValue(rooms),
        systemSettingsRepositoryProvider.overrideWithValue(settings),
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
    await settle(tester, reduce: reduce);
    await tester.tap(find.text(t.lobby.scanQr));
    await settle(tester, reduce: reduce);
    return (router, container);
  }

  Future<void> scan(WidgetTester tester, _TestRouter router, String raw) async {
    router.onScan!(raw);
    await tester.pumpAndSettle();
  }

  group('ScanQrPage', () {
    testWidgets(
      'AC6: el escáner va en tema oscuro con la cámara bajo la retícula '
      'abierta, la barra con Atrás y Linterna, la indicación y Conectar por IP',
      (tester) async {
        await pumpScanner(tester);

        expect(find.byType(ScanQrPage), findsOneWidget);
        expect(
          Theme.of(tester.element(find.byType(ScanReticle))).brightness,
          Brightness.dark,
        );
        expect(_inScanner(find.byKey(_cameraStub)), findsOneWidget);
        expect(_reticle(tester).locked, isFalse);
        expect(_inScanner(_iconButton('Atrás')), findsOneWidget);
        expect(_inScanner(find.text('Escanear invitación')), findsOneWidget);
        expect(_inScanner(_label('QR de la frecu')), findsOneWidget);
        expect(_inScanner(_iconButton('Linterna')), findsOneWidget);
        expect(
          _inScanner(
            find.text('Apunta al QR que muestra el anfitrión en su teléfono.'),
          ),
          findsOneWidget,
        );
        expect(_inScanner(_button('Conectar por IP')), findsOneWidget);
      },
    );

    testWidgets('AC6: Linterna se enciende y se apaga, y Atrás vuelve al '
        'inicio', (tester) async {
      final (router, _) = await pumpScanner(tester);
      bool torch() =>
          tester.widget<FrIconButton>(_iconButton('Linterna')).selected;

      expect(torch(), isFalse);
      await tester.tap(_iconButton('Linterna'));
      await tester.pumpAndSettle();
      expect(torch(), isTrue);
      await tester.tap(_iconButton('Linterna'));
      await tester.pumpAndSettle();
      expect(torch(), isFalse);

      await tester.tap(_iconButton('Atrás'));
      await tester.pumpAndSettle();
      expect(find.byType(ScanQrPage), findsNothing);
      expect(_stack(router), [LobbyRoute.name]);
    });

    testWidgets(
      'AC6: Conectar por IP abre la hoja de IP y, al unirse, la frecu activa '
      'reemplaza al escáner',
      (tester) async {
        answerJoin(() async => Result.success(_joined('room-ip')));
        final (router, _) = await pumpScanner(tester);

        await tester.tap(_button('Conectar por IP'));
        await tester.pumpAndSettle();
        expect(find.byType(IpJoinSheet), findsOneWidget);

        Finder input(String label) => find.descendant(
          of: find.byWidgetPredicate((w) => w is FrField && w.label == label),
          matching: find.byType(TextField),
        );
        await tester.enterText(input('IP del anfitrión'), '192.168.43.50');
        await tester.enterText(input('Código de acceso'), '4827');
        await tester.pumpAndSettle();
        await tester.tap(_button('Conectar'));
        await tester.pumpAndSettle();

        verify(
          () => rooms.joinRoom(
            hostAddress: '192.168.43.50',
            port: 47800,
            accessCode: '4827',
            displayName: 'Ana',
          ),
        ).called(1);
        expect(find.byType(ScanQrPage), findsNothing);
        expect(_stack(router), [LobbyRoute.name, RoomRoute.name]);
        expect(router.currentPath, '/room/room-ip');
      },
    );

    testWidgets(
      'AC6: un QR que no es una invitación lo dice y el escáner sigue '
      'buscando',
      (tester) async {
        final (router, _) = await pumpScanner(tester);

        await scan(tester, router, 'https://example.com/menu');

        expect(
          _inScanner(find.text('Este QR no es una invitación de Frecu.')),
          findsOneWidget,
        );
        expect(_reticle(tester).locked, isFalse);
        expect(_inScanner(_label('Frecu encontrada')), findsNothing);

        await scan(tester, router, _invite);

        expect(_reticle(tester).locked, isTrue);
        expect(
          _inScanner(find.text('Este QR no es una invitación de Frecu.')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC7: una invitación cierra la retícula y muestra la tarjeta con la '
      'nota, sus Hz, la IP y el puerto y Unirme, sin atender otros QR',
      (tester) async {
        final (router, _) = await pumpScanner(tester);

        await scan(tester, router, _invite);

        expect(_reticle(tester).locked, isTrue);
        expect(_inScanner(_label('Frecu encontrada')), findsOneWidget);
        expect(_inScanner(find.text('Sol4 · 392,0 Hz')), findsOneWidget);
        expect(
          _inScanner(_label('192.168.43.1 · Puerto 47800')),
          findsOneWidget,
        );
        expect(_inScanner(_button('Unirme')), findsOneWidget);
        verifyNever(
          () => rooms.joinRoom(
            hostAddress: any(named: 'hostAddress'),
            port: any(named: 'port'),
            accessCode: any(named: 'accessCode'),
            displayName: any(named: 'displayName'),
          ),
        );

        await scan(
          tester,
          router,
          'frecu://join?h=10.0.0.9&p=47801&r=otra&c=1111&n=0',
        );

        expect(_inScanner(find.text('Sol4 · 392,0 Hz')), findsOneWidget);
        expect(
          _inScanner(_label('192.168.43.1 · Puerto 47800')),
          findsOneWidget,
        );
      },
    );

    testWidgets('AC7: una invitación sin nota sale como «Frecu sin nota»', (
      tester,
    ) async {
      final (router, _) = await pumpScanner(tester);

      await scan(
        tester,
        router,
        'frecu://join?h=192.168.43.1&p=47800&r=room-qr&c=4827',
      );

      expect(_inScanner(find.text('Frecu sin nota')), findsOneWidget);
      expect(_inScanner(_label('192.168.43.1 · Puerto 47800')), findsOneWidget);
    });

    testWidgets(
      'AC7: Unirme se une con los datos y la nota del QR y el nombre guardado '
      'y la frecu activa reemplaza al escáner',
      (tester) async {
        final (router, container) = await pumpScanner(tester);
        await scan(tester, router, _invite);

        await tester.tap(_button('Unirme'));
        await tester.pumpAndSettle();

        verify(
          () => rooms.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '4827',
            displayName: 'Ana',
          ),
        ).called(1);
        expect(find.byType(ScanQrPage), findsNothing);
        expect(_stack(router), [LobbyRoute.name, RoomRoute.name]);
        expect(router.currentPath, '/room/room-qr');
        expect(
          container.read(roomNotifierProvider)?.note,
          const RoomNote(semitone: 7),
        );
      },
    );

    testWidgets(
      'AC7: si la unión falla se ve el aviso sobre la tarjeta y Unirme '
      'reintenta',
      (tester) async {
        answerJoin(() async => const Result.failure(Failure.hostUnreachable()));
        final (router, _) = await pumpScanner(tester);
        await scan(tester, router, _invite);

        await tester.tap(_button('Unirme'));
        await tester.pumpAndSettle();

        final banner = tester.widget<FrBanner>(find.byType(FrBanner));
        expect(banner.tone, FrBannerTone.alert);
        expect(banner.title, 'El anfitrión no responde.');
        expect(
          tester.getBottomLeft(find.byType(FrBanner)).dy,
          lessThanOrEqualTo(tester.getTopLeft(_button('Unirme')).dy),
        );
        expect(find.byType(ScanQrPage), findsOneWidget);

        answerJoin(() async => Result.success(_joined('room-qr')));
        await tester.tap(_button('Unirme'));
        await tester.pumpAndSettle();

        verify(
          () => rooms.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '4827',
            displayName: 'Ana',
          ),
        ).called(2);
        expect(router.currentPath, '/room/room-qr');
      },
    );

    testWidgets('AC8: en inglés el escáner sale de la traducción en', (
      tester,
    ) async {
      await _useEnglish(tester);
      final (router, _) = await pumpScanner(tester);

      expect(_inScanner(_iconButton('Back')), findsOneWidget);
      expect(_inScanner(find.text('Scan invite')), findsOneWidget);
      expect(_inScanner(_label('Room QR')), findsOneWidget);
      expect(_inScanner(_iconButton('Flashlight')), findsOneWidget);
      expect(
        _inScanner(find.text('Point at the QR the host shows on their phone.')),
        findsOneWidget,
      );
      expect(_inScanner(_button('Connect by IP')), findsOneWidget);

      await scan(tester, router, 'not a frecu invite');
      expect(
        _inScanner(find.text("This QR isn't a Frecu invite.")),
        findsOneWidget,
      );

      await scan(tester, router, _invite);
      expect(_inScanner(_label('Room found')), findsOneWidget);
      expect(_inScanner(find.text('G4 · 392.0 Hz')), findsOneWidget);
      expect(_inScanner(_label('192.168.43.1 · Port 47800')), findsOneWidget);
      expect(_inScanner(_button('Join')), findsOneWidget);
    });

    testWidgets(
      'AC8: con movimiento reducido la retícula no anima ni pide cuadros y '
      'se cierra igual sobre el QR',
      (tester) async {
        final (router, _) = await pumpScanner(tester);

        expect(_reticleLoop, findsNothing);
        expect(tester.binding.hasScheduledFrame, isFalse);

        await scan(tester, router, _invite);

        expect(_reticle(tester).locked, isTrue);
        expect(_reticleLoop, findsNothing);
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets(
      'AC8: sin movimiento reducido la retícula anima hasta cerrarse sobre '
      'el QR',
      (tester) async {
        final (router, _) = await pumpScanner(tester, reduce: false);

        expect(_reticleLoop, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.binding.hasScheduledFrame, isTrue);

        router.onScan!(_invite);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(_reticle(tester).locked, isTrue);
        expect(_reticleLoop, findsNothing);
      },
    );

    testWidgets(
      'AC7: con el nombre en el QR la tarjeta lo muestra, con la nota y la '
      'IP debajo',
      (tester) async {
        final (router, _) = await pumpScanner(tester);

        await scan(tester, router, '$_invite&name=Ruta%20del%20domingo');

        expect(_inScanner(find.text('Ruta del domingo')), findsOneWidget);
        expect(_inScanner(_label('Sol4 · 192.168.43.1')), findsOneWidget);
        expect(_inScanner(find.text('Sol4 · 392,0 Hz')), findsNothing);
      },
    );

    testWidgets('AC7: la tarjeta desenfoca lo que hay detrás', (tester) async {
      final (router, _) = await pumpScanner(tester);

      await scan(tester, router, _invite);

      final blur = tester.widget<BackdropFilter>(
        find.descendant(
          of: find.byType(ScanFoundCard),
          matching: find.byType(BackdropFilter),
        ),
      );
      expect(blur.filter, ImageFilter.blur(sigmaX: 14, sigmaY: 14));
    });

    testWidgets(
      'AC7: «Escanear otro QR» suelta la invitación y vuelve a buscar',
      (tester) async {
        final (router, _) = await pumpScanner(tester);
        await scan(tester, router, _invite);
        expect(_reticle(tester).locked, isTrue);

        await tester.tap(_button('Escanear otro QR'));
        await tester.pumpAndSettle();

        expect(_reticle(tester).locked, isFalse);
        expect(_inScanner(_label('Frecu encontrada')), findsNothing);
        expect(
          _inScanner(
            find.text('Apunta al QR que muestra el anfitrión en su teléfono.'),
          ),
          findsOneWidget,
        );

        await scan(
          tester,
          router,
          'frecu://join?h=10.0.0.9&p=47801&r=otra&c=1111&n=0',
        );

        expect(_reticle(tester).locked, isTrue);
        expect(_inScanner(_label('10.0.0.9 · Puerto 47801')), findsOneWidget);
      },
    );

    testWidgets(
      'AC9: sin permiso de la cámara se explica en lugar de la retícula, con '
      'Abrir ajustes y Conectar por IP',
      (tester) async {
        final (router, _) = await pumpScanner(tester);

        router.onIssue!(ScanCameraIssue.denied);
        await tester.pumpAndSettle();

        expect(find.byType(ScanReticle), findsNothing);
        expect(
          _inScanner(
            find.text('Apunta al QR que muestra el anfitrión en su teléfono.'),
          ),
          findsNothing,
        );
        expect(
          _inScanner(find.text('Frecu no tiene acceso a la cámara.')),
          findsOneWidget,
        );
        expect(
          _inScanner(
            find.text(
              'Permítela en Ajustes para escanear la invitación, o conéctate '
              'por IP.',
            ),
          ),
          findsOneWidget,
        );
        expect(_inScanner(_iconButton('Atrás')), findsOneWidget);
        // Sin cámara no hay linterna.
        expect(
          tester.widget<FrIconButton>(_iconButton('Linterna')).onPressed,
          isNull,
        );

        await tester.tap(_button('Abrir ajustes'));
        await tester.pumpAndSettle();
        expect(settings.opened, ['app']);

        await tester.tap(_button('Conectar por IP'));
        await tester.pumpAndSettle();
        expect(find.byType(IpJoinSheet), findsOneWidget);
      },
    );

    testWidgets(
      'AC9: sin cámara lo dice y ofrece solo Conectar por IP; al volver la '
      'cámara vuelven la retícula y la indicación',
      (tester) async {
        final (router, _) = await pumpScanner(tester);

        router.onIssue!(ScanCameraIssue.unavailable);
        await tester.pumpAndSettle();

        expect(
          _inScanner(find.text('La cámara no está disponible.')),
          findsOneWidget,
        );
        expect(
          _inScanner(find.text('Puedes unirte con la IP del anfitrión.')),
          findsOneWidget,
        );
        expect(_button('Abrir ajustes'), findsNothing);
        expect(_inScanner(_button('Conectar por IP')), findsOneWidget);

        router.onIssue!(null);
        await tester.pumpAndSettle();

        expect(find.byType(ScanReticle), findsOneWidget);
        expect(find.text('La cámara no está disponible.'), findsNothing);
        expect(
          _inScanner(
            find.text('Apunta al QR que muestra el anfitrión en su teléfono.'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('AC9: en inglés el aviso sin cámara sale de la traducción en', (
      tester,
    ) async {
      await _useEnglish(tester);
      final (router, _) = await pumpScanner(tester);

      router.onIssue!(ScanCameraIssue.denied);
      await tester.pumpAndSettle();

      expect(find.text("Frecu can't use the camera."), findsOneWidget);
      expect(_button('Open settings'), findsOneWidget);
      expect(_button('Connect by IP'), findsOneWidget);
    });
  });

  group('ScanCameraLifecycle', () {
    test('AC9: para la cámara si estaba en marcha y la enciende al volver', () {
      final lifecycle = ScanCameraLifecycle();

      expect(lifecycle.shouldStop(running: true), isTrue);
      expect(lifecycle.shouldStart(running: false, starting: false), isTrue);
      // Una sola vez por pausa.
      expect(lifecycle.shouldStart(running: false, starting: false), isFalse);
    });

    test('AC9: si la cámara no estaba en marcha no la toca', () {
      final lifecycle = ScanCameraLifecycle();

      expect(lifecycle.shouldStop(running: false), isFalse);
      expect(lifecycle.shouldStart(running: false, starting: false), isFalse);
    });

    test('AC9: al volver de Ajustes la intenta encender otra vez', () {
      final lifecycle = ScanCameraLifecycle()..openedSettings();

      expect(lifecycle.shouldStart(running: false, starting: false), isTrue);
      expect(lifecycle.shouldStart(running: false, starting: false), isFalse);
    });

    test('AC9: tras negar el permiso no lo vuelve a pedir solo, ni enciende '
        'una cámara que ya arranca', () {
      final lifecycle = ScanCameraLifecycle();

      // El diálogo del permiso pasa la app a inactiva y luego la reanuda.
      expect(lifecycle.shouldStop(running: false), isFalse);
      expect(lifecycle.shouldStart(running: false, starting: false), isFalse);

      lifecycle.openedSettings();
      expect(lifecycle.shouldStart(running: false, starting: true), isFalse);
    });
  });
}

/// Espera a que la pantalla quede quieta: con movimiento reducido hasta que
/// no pide cuadros y, sin él, un segundo de cuadros (el inicio anima sin fin).
Future<void> settle(WidgetTester tester, {required bool reduce}) async {
  if (reduce) {
    await tester.pumpAndSettle();
    return;
  }
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
