// AC1: CUANDO el usuario toca una frecu cercana ENTONCES se abre la hoja de código (`FrSheet`) con «<nota> · <Hz> · <IP>» (solo la IP si la frecu no tiene nota), el nombre de la frecu, «Ingresa el código de acceso. Pídeselo al anfitrión.», el botón Cerrar, el código de 4 celdas vacío, «Se envía al completar los 4 dígitos», el teclado propio y «Entrarás como <nombre guardado>»; cada tecla escribe su dígito en la celda siguiente y Borrar quita el último.
// AC2: CUANDO se escribe el cuarto dígito ENTONCES el código se envía solo a la IP y el puerto de la frecu con el nombre guardado y la nota de la frecu, las celdas pasan a verificando con «Verificando con el anfitrión…» y el teclado no responde; CUANDO el anfitrión lo acepta ENTONCES la hoja se cierra y se abre la frecu activa.
// AC3: CUANDO el anfitrión rechaza el código ENTONCES las celdas pasan a error con «Código incorrecto. Revisa e intenta otra vez.» y la siguiente tecla empieza un código nuevo; CUANDO la frecu está llena ENTONCES se ve un aviso ámbar «La frecu está llena (máximo 6 participantes)» con «Podrás entrar cuando alguien salga.»; CUANDO falla por otro motivo ENTONCES un aviso de alerta con su mensaje; en esos dos casos las celdas quedan vacías para reintentar.
// AC4: CUANDO el usuario toca Conectar por IP ENTONCES se abre la hoja «Conexión manual», «Conectar por IP», «Úsalo si la frecu no aparece en la lista.» con los campos «IP del anfitrión» (con «Puerto 47800» debajo) y «Código de acceso» (4 dígitos), y Conectar solo responde con una IP y 4 dígitos; al tocarlo se une a esa IP en el puerto 47800 con ese código y el nombre guardado, sin nota; CUANDO el anfitrión acepta ENTONCES la hoja se cierra y se abre la frecu activa.
// AC5: CUANDO el anfitrión no responde a la conexión por IP ENTONCES el campo de IP pasa a error con «Sin respuesta en el puerto 47800» y se ve un aviso de alerta «El anfitrión no responde» con «Revisa que estés en su misma red Wi-Fi.»; CUANDO el código es incorrecto ENTONCES el campo del código pasa a error con «Código incorrecto. Revisa e intenta otra vez.»; CUANDO la frecu está llena ENTONCES el aviso ámbar de AC3; CUANDO el usuario edita un campo ENTONCES el error se quita.
// AC8: CUANDO la app está en inglés ENTONCES las hojas y el escáner muestran sus textos de la traducción `en`; CUANDO el sistema pide reducir el movimiento ENTONCES la retícula no respira, el haz queda quieto y el escáner no pide cuadros, sin ocultar el cierre sobre el código.
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
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_keypad.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/design/widgets/fr_sheet.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/ip_join_sheet.dart';
import 'package:frecu/features/lobby/presentation/widgets/pin_join_sheet.dart';
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

const _roomStub = Key('room_stub');

/// Router de la app con la frecu activa sustituida: las pruebas miran a qué
/// frecu se entra, no su pantalla.
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

/// Mi4: 329,6 Hz.
const _ruta = NearbyRoom(
  roomId: 'room-ruta',
  name: 'Ruta del domingo',
  hostAddress: '192.168.43.1',
  port: 47812,
  note: RoomNote(semitone: 4),
);

/// Anfitrión anterior a la nota: no la publica.
const _vieja = NearbyRoom(
  roomId: 'room-vieja',
  name: 'Frecu vieja',
  hostAddress: '192.168.43.9',
  port: 47800,
);

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

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is FrField && widget.label == label,
);

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(FrSheet), matching: finder);

FrPinField _pin(WidgetTester tester) =>
    tester.widget<FrPinField>(find.byType(FrPinField));

FrBanner _banner(WidgetTester tester) =>
    tester.widget<FrBanner>(find.byType(FrBanner));

/// Escribe [digits] con el teclado propio de la hoja.
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
    nearby = StreamController<List<NearbyRoom>>.broadcast();

    when(() => discovery.watchNearbyRooms()).thenAnswer((_) => nearby.stream);
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
    when(() => rooms.getLocalIpAddress())
        .thenAnswer((_) async => '192.168.43.27');
    answerJoin(() async => const Result.failure(Failure.invalidAccessCode()));
  });

  tearDown(() async {
    await nearby.close();
  });

  /// Abre la app en el inicio, en un teléfono de 390 × 844, con movimiento
  /// reducido y el nombre «Ana» ya leído.
  Future<(AppRouter, ProviderContainer)> pumpLobby(WidgetTester tester) async {
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
    final router = _RouterWithoutRoom();
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

  Future<void> openPin(WidgetTester tester, NearbyRoom room) async {
    nearby.add([room]);
    await tester.pumpAndSettle();
    await tester.tap(find.text(room.name));
    await tester.pumpAndSettle();
  }

  group('PinJoinSheet', () {
    testWidgets(
      'AC1: tocar una frecu abre la hoja con su nota, sus Hz, su IP y su '
      'nombre, el código vacío, el teclado y el nombre guardado',
      (tester) async {
        await pumpLobby(tester);
        await openPin(tester, _ruta);

        expect(find.byType(PinJoinSheet), findsOneWidget);
        expect(_inSheet(_label('Mi4 · 329,6 Hz · 192.168.43.1')), findsOne);
        expect(_inSheet(find.text('Ruta del domingo')), findsOneWidget);
        expect(
          _inSheet(
            find.text('Ingresa el código de acceso. Pídeselo al anfitrión.'),
          ),
          findsOneWidget,
        );
        expect(_inSheet(_iconButton('Cerrar')), findsOneWidget);
        expect(_pin(tester).value, isEmpty);
        expect(_pin(tester).state, FrPinState.idle);
        expect(
          _inSheet(find.text('Se envía al completar los 4 dígitos')),
          findsOneWidget,
        );
        expect(_inSheet(find.byType(FrKeypad)), findsOneWidget);
        expect(
          find.textContaining(
            RegExp('entrarás como ana', caseSensitive: false),
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC1: sin nota la hoja dice solo la IP; las teclas escriben, Borrar '
      'quita el último dígito y Cerrar cierra la hoja',
      (tester) async {
        await pumpLobby(tester);
        await openPin(tester, _vieja);

        expect(_inSheet(_label('192.168.43.9')), findsOneWidget);

        await _type(tester, '48');
        expect(_pin(tester).value, '48');

        await tester.tap(find.byKey(const ValueKey('fr-key-del')));
        await tester.pumpAndSettle();
        expect(_pin(tester).value, '4');
        verifyNever(
          () => rooms.joinRoom(
            hostAddress: any(named: 'hostAddress'),
            port: any(named: 'port'),
            accessCode: any(named: 'accessCode'),
            displayName: any(named: 'displayName'),
          ),
        );

        await tester.tap(_iconButton('Cerrar'));
        await tester.pumpAndSettle();
        expect(find.byType(PinJoinSheet), findsNothing);
      },
    );

    testWidgets(
      'AC2: el cuarto dígito envía el código solo, verifica sin aceptar '
      'teclas y, si el anfitrión acepta, abre la frecu activa con su nota',
      (tester) async {
        final answer = Completer<Result<Room>>();
        answerJoin(() => answer.future);
        final (router, container) = await pumpLobby(tester);
        await openPin(tester, _ruta);

        await _type(tester, '482');
        verifyNever(
          () => rooms.joinRoom(
            hostAddress: any(named: 'hostAddress'),
            port: any(named: 'port'),
            accessCode: any(named: 'accessCode'),
            displayName: any(named: 'displayName'),
          ),
        );

        await _type(tester, '7');
        verify(
          () => rooms.joinRoom(
            hostAddress: '192.168.43.1',
            port: 47812,
            accessCode: '4827',
            displayName: 'Ana',
          ),
        ).called(1);
        expect(_pin(tester).state, FrPinState.busy);
        expect(
          _inSheet(find.text('Verificando con el anfitrión…')),
          findsOneWidget,
        );

        await _type(tester, '5');
        expect(_pin(tester).value, '4827');

        answer.complete(Result.success(_joined('room-ruta')));
        await tester.pumpAndSettle();

        expect(find.byType(PinJoinSheet), findsNothing);
        expect(router.currentPath, '/room/room-ruta');
        expect(find.byKey(_roomStub), findsOneWidget);
        expect(
          container.read(roomNotifierProvider)?.note,
          const RoomNote(semitone: 4),
        );
      },
    );

    testWidgets(
      'AC3: con el código rechazado las celdas pasan a error con su mensaje '
      'y la siguiente tecla empieza un código nuevo',
      (tester) async {
        await pumpLobby(tester);
        await openPin(tester, _ruta);

        await _type(tester, '1111');

        expect(_pin(tester).state, FrPinState.error);
        expect(_pin(tester).value, '1111');
        expect(
          _inSheet(find.text('Código incorrecto. Revisa e intenta otra vez.')),
          findsOneWidget,
        );
        expect(find.byType(PinJoinSheet), findsOneWidget);

        await _type(tester, '2');

        expect(_pin(tester).state, FrPinState.idle);
        expect(_pin(tester).value, '2');
        expect(
          _inSheet(find.text('Se envía al completar los 4 dígitos')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC3: con la frecu llena se ve el aviso ámbar y las celdas quedan '
      'vacías para reintentar',
      (tester) async {
        answerJoin(() async => const Result.failure(Failure.roomFull()));
        await pumpLobby(tester);
        await openPin(tester, _ruta);

        await _type(tester, '4827');

        expect(_banner(tester).tone, FrBannerTone.warn);
        expect(
          _banner(tester).title,
          'La frecu está llena (máximo 6 participantes)',
        );
        expect(_banner(tester).message, 'Podrás entrar cuando alguien salga.');
        expect(_pin(tester).value, isEmpty);
        expect(_pin(tester).state, FrPinState.idle);

        await _type(tester, '4');

        expect(_pin(tester).value, '4');
        expect(find.byType(FrBanner), findsNothing);
      },
    );

    testWidgets(
      'AC3: si el anfitrión no responde se ve un aviso de alerta con su '
      'mensaje y las celdas quedan vacías',
      (tester) async {
        answerJoin(() async => const Result.failure(Failure.hostUnreachable()));
        await pumpLobby(tester);
        await openPin(tester, _ruta);

        await _type(tester, '4827');

        expect(_banner(tester).tone, FrBannerTone.alert);
        expect(_banner(tester).title, 'El anfitrión no responde');
        expect(_pin(tester).value, isEmpty);
        expect(find.byType(PinJoinSheet), findsOneWidget);
      },
    );

    testWidgets('AC8: en inglés la hoja de código sale de la traducción en', (
      tester,
    ) async {
      await _useEnglish(tester);
      await pumpLobby(tester);
      await openPin(tester, _ruta);

      expect(_inSheet(_label('E4 · 329.6 Hz · 192.168.43.1')), findsOneWidget);
      expect(
        _inSheet(find.text('Enter the access code. Ask the host for it.')),
        findsOneWidget,
      );
      expect(
        _inSheet(find.text('Sent once all 4 digits are in')),
        findsOneWidget,
      );
      expect(_inSheet(_iconButton('Close')), findsOneWidget);
      expect(
        find.textContaining(
          RegExp("you'll join as ana", caseSensitive: false),
          findRichText: true,
        ),
        findsOneWidget,
      );

      await _type(tester, '1111');
      expect(
        _inSheet(find.text('Wrong code. Check it and try again.')),
        findsOneWidget,
      );
    });
  });

  group('IpJoinSheet', () {
    Future<void> openIp(WidgetTester tester) async {
      await tester.tap(find.text(t.lobby.joinRoom));
      await tester.pumpAndSettle();
    }

    Future<void> fill(WidgetTester tester, {String? ip, String? code}) async {
      if (ip != null) {
        await tester.enterText(
          find.descendant(
            of: _field(t.lobby.join.ip.host),
            matching: find.byType(TextField),
          ),
          ip,
        );
      }
      if (code != null) {
        await tester.enterText(
          find.descendant(
            of: _field(t.lobby.accessCode),
            matching: find.byType(TextField),
          ),
          code,
        );
      }
      await tester.pumpAndSettle();
    }

    FrField field(WidgetTester tester, String label) =>
        tester.widget<FrField>(_field(label));

    testWidgets(
      'AC4: Conectar por IP abre la hoja de conexión manual con la IP, el '
      'puerto y el código',
      (tester) async {
        await pumpLobby(tester);
        await openIp(tester);

        expect(find.byType(IpJoinSheet), findsOneWidget);
        expect(_inSheet(_label('Conexión manual')), findsOneWidget);
        expect(_inSheet(find.text('Conectar por IP')), findsOneWidget);
        expect(
          _inSheet(find.text('Úsalo si la frecu no aparece en la lista.')),
          findsOneWidget,
        );
        expect(_inSheet(_field('IP del anfitrión')), findsOneWidget);
        expect(_inSheet(_field('Código de acceso')), findsOneWidget);
        expect(field(tester, 'IP del anfitrión').help, 'Puerto 47800');
        expect(field(tester, 'Código de acceso').maxLength, 4);
        expect(_inSheet(_button('Conectar')), findsOneWidget);
        expect(_inSheet(_iconButton('Cerrar')), findsOneWidget);
      },
    );

    testWidgets(
      'AC4: Conectar solo responde con IP y 4 dígitos, se une en el puerto '
      '47800 sin nota y abre la frecu activa',
      (tester) async {
        answerJoin(() async => Result.success(_joined('room-ip')));
        final (router, container) = await pumpLobby(tester);
        await openIp(tester);
        FrButton connect() => tester.widget<FrButton>(_button('Conectar'));

        expect(connect().onPressed, isNull);
        await fill(tester, ip: '192.168.43.50');
        expect(connect().onPressed, isNull);
        await fill(tester, code: '48');
        expect(connect().onPressed, isNull);
        await fill(tester, code: '4827');
        expect(connect().onPressed, isNotNull);

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
        expect(find.byType(IpJoinSheet), findsNothing);
        expect(router.currentPath, '/room/room-ip');
        expect(container.read(roomNotifierProvider)?.id, 'room-ip');
        expect(container.read(roomNotifierProvider)?.note, isNull);
      },
    );

    testWidgets(
      'AC5: si el anfitrión no responde la IP pasa a error con el aviso de '
      'alerta, y al editarla el error se quita',
      (tester) async {
        answerJoin(() async => const Result.failure(Failure.hostUnreachable()));
        await pumpLobby(tester);
        await openIp(tester);
        await fill(tester, ip: '192.168.43.50', code: '4827');

        await tester.tap(_button('Conectar'));
        await tester.pumpAndSettle();

        expect(find.byType(IpJoinSheet), findsOneWidget);
        expect(
          field(tester, 'IP del anfitrión').error,
          'Sin respuesta en el puerto 47800',
        );
        expect(_banner(tester).tone, FrBannerTone.alert);
        expect(_banner(tester).title, 'El anfitrión no responde');
        expect(
          _banner(tester).message,
          'Revisa que estés en su misma red Wi-Fi.',
        );

        await fill(tester, ip: '192.168.43.51');

        expect(field(tester, 'IP del anfitrión').error, isNull);
        expect(find.byType(FrBanner), findsNothing);
      },
    );

    testWidgets(
      'AC5: con el código incorrecto el campo del código pasa a error, y con '
      'la frecu llena se ve el aviso ámbar',
      (tester) async {
        await pumpLobby(tester);
        await openIp(tester);
        await fill(tester, ip: '192.168.43.50', code: '1111');

        await tester.tap(_button('Conectar'));
        await tester.pumpAndSettle();

        expect(
          field(tester, 'Código de acceso').error,
          'Código incorrecto. Revisa e intenta otra vez.',
        );
        expect(field(tester, 'IP del anfitrión').error, isNull);
        expect(find.byType(FrBanner), findsNothing);

        answerJoin(() async => const Result.failure(Failure.roomFull()));
        await fill(tester, code: '4827');
        expect(field(tester, 'Código de acceso').error, isNull);

        await tester.tap(_button('Conectar'));
        await tester.pumpAndSettle();

        expect(_banner(tester).tone, FrBannerTone.warn);
        expect(
          _banner(tester).title,
          'La frecu está llena (máximo 6 participantes)',
        );
        expect(_banner(tester).message, 'Podrás entrar cuando alguien salga.');
      },
    );

    testWidgets('AC8: en inglés la hoja de IP sale de la traducción en', (
      tester,
    ) async {
      await _useEnglish(tester);
      await pumpLobby(tester);
      await openIp(tester);

      expect(_inSheet(_label('Manual connection')), findsOneWidget);
      expect(_inSheet(find.text('Connect by IP')), findsOneWidget);
      expect(
        _inSheet(find.text("Use it if the room isn't on the list.")),
        findsOneWidget,
      );
      expect(_inSheet(_field('Host IP')), findsOneWidget);
      expect(_inSheet(_field('Access code')), findsOneWidget);
      expect(field(tester, 'Host IP').help, 'Port 47800');
      expect(_inSheet(_button('Connect')), findsOneWidget);
    });
  });
}
