// AC1: CUANDO el usuario toca Crear frecu en el inicio y sigue con Local ENTONCES se abre la guía en Portadora (`FrScaffold`) con Atrás, «Paso 2 de 3» y «Prepara la red», la ilustración del teléfono emisor, «Activa tu punto de acceso», «Tu teléfono será la antena del grupo.», el selector Android | iPhone y los tres pasos de la plataforma elegida numerados 01 a 03 con su inicio en negrita, y abajo «Ya está activo» y «Ya estamos en la misma Wi-Fi»; el selector empieza en Android en todos los teléfonos (se prioriza como anfitrión), elegir la otra plataforma cambia los pasos y los nuevos entran con un fundido; bajo los pasos de la plataforma del teléfono, «Abrir ajustes de zona Wi-Fi» (en iPhone, «Abrir Ajustes») abre los ajustes de su punto de acceso; todos los textos salen de slang en español y en inglés.
// AC2: CUANDO el usuario toca «Ya está activo» o «Ya estamos en la misma Wi-Fi» ENTONCES pasa a la nueva frecu con «Paso 3 de 3» y «Nueva frecu»; Atrás en la nueva frecu vuelve a la guía y, al volver a entrar, conserva el nombre y el código; Atrás en la guía vuelve a «¿Cómo se une tu grupo?».
// AC6: CUANDO el sistema pide reducir el movimiento ENTONCES la ilustración del punto de acceso queda quieta y no pide cuadros; sin movimiento reducido sus anillos se mueven en cada cuadro.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/pages/create_room_page.dart';
import 'package:frecu/features/lobby/presentation/pages/lobby_page.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/new_room_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_guide_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_illustration.dart';
import 'package:frecu/features/lobby/presentation/widgets/new_room_step.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/domain/repositories/system_settings_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockNetworkRepository extends Mock implements NetworkRepository {}

class _MockRoomRepository extends Mock implements RoomRepository {}

const _iphoneOpen =
    'Abre Ajustes › Punto de acceso personal y activa «Permitir a otros '
    'conectarse».';

const _iphoneKeepOpen =
    'Mantén Frecu abierta mientras se unen. En iPhone recomendamos que el '
    'anfitrión use Android.';

const _androidComeBackEn =
    "Come back to Frecu and open your room. It doesn't use your mobile data.";

const _iphoneOpenEn =
    'Open Settings › Personal Hotspot and turn on “Allow Others to Join”.';

const _iphoneKeepOpenEn =
    'Keep Frecu open while they join. On iPhone we recommend that the host '
    'uses Android.';

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

/// Texto de los pasos de la guía, en orden.
List<String> _steps(WidgetTester tester) => [
  for (final row in tester.widgetList<HotspotGuideStepRow>(
    find.byType(HotspotGuideStepRow),
  ))
    '${row.step.lead}${row.step.rest}',
];

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

Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is FrButton && widget.label == label,
);

/// Opacidad de los pasos (el fundido al cambiar de pestaña).
double _stepsOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byType(HotspotGuideStepRow).first,
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

HotspotPlatform _platform(WidgetTester tester) => tester
    .widget<FrSegmented<HotspotPlatform>>(
      find.byType(FrSegmented<HotspotPlatform>),
    )
    .value;

HotspotPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(HotspotIllustration),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((paint) => paint.painter)
    .whereType<HotspotPainter>()
    .single;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late _MockRoomRepository rooms;
  late StreamController<List<NearbyRoom>> nearby;
  late StreamController<NetworkState> networkStates;
  late List<String> codes;
  late _FakeSettings settings;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    rooms = _MockRoomRepository();
    nearby = StreamController<List<NearbyRoom>>.broadcast();
    networkStates = StreamController<NetworkState>.broadcast();
    codes = ['4827', '1593', '7302'];
    settings = _FakeSettings();

    when(() => discovery.watchNearbyRooms()).thenAnswer((_) => nearby.stream);
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(() => network.watchNetworkState())
        .thenAnswer((_) => networkStates.stream);
    when(() => rooms.getLocalIpAddress())
        .thenAnswer((_) async => '192.168.43.1');
  });

  tearDown(() async {
    await nearby.close();
    await networkStates.close();
  });

  /// Abre la app en el inicio, en un teléfono de 390 × 844 y con movimiento
  /// reducido, toca Crear frecu y sigue con Local, marcada.
  Future<void> pumpGuide(WidgetTester tester) async {
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
            systemSettingsRepositoryProvider.overrideWithValue(settings),
            newRoomClockProvider.overrideWithValue(
              () => DateTime(2026, 11, 8, 16, 24),
            ),
            accessCodeGeneratorProvider.overrideWithValue(
              () => codes.removeAt(0),
            ),
          ],
          child: FrecuApp(appRouter: AppRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lobby.createRoom));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lobby.newRoom.reach.kContinue));
    await tester.pumpAndSettle();
  }

  group('Guía del punto de acceso', () {
    testWidgets(
      'AC1: Crear frecu abre la guía en Portadora con la ilustración, el '
      'selector, los pasos y el dock',
      (tester) async {
        await pumpGuide(tester);

        expect(
          find.descendant(
            of: find.byType(HotspotGuideStep),
            matching: find.byType(FrScaffold),
          ),
          findsOneWidget,
        );
        expect(_iconButton('Atrás'), findsOneWidget);
        expect(_label('Paso 2 de 3'), findsOneWidget);
        expect(find.text('Prepara la red'), findsOneWidget);
        expect(find.byType(HotspotIllustration), findsOneWidget);
        expect(find.text('Activa tu punto de acceso'), findsOneWidget);
        expect(
          find.text('Tu teléfono será la antena del grupo.'),
          findsOneWidget,
        );
        expect(_label('Android'), findsOneWidget);
        expect(_label('iPhone'), findsOneWidget);
        expect(_platform(tester), HotspotPlatform.android);
        expect(find.text('01'), findsOneWidget);
        expect(find.text('02'), findsOneWidget);
        expect(find.text('03'), findsOneWidget);
        expect(_steps(tester), [
          'Abre Ajustes › Zona Wi-Fi (el nombre cambia según la marca).',
          'Actívala y comparte el nombre y la contraseña con tu grupo.',
          'Vuelve a Frecu y abre tu frecu. No usa tus datos móviles.',
        ]);
        expect(find.text('Ya está activo'), findsOneWidget);
        expect(find.text('Ya estamos en la misma Wi-Fi'), findsOneWidget);
      },
    );

    testWidgets('AC1: el inicio de cada paso va en negrita', (tester) async {
      await pumpGuide(tester);

      final text = tester.widget<Text>(
        find.text(
          'Abre Ajustes › Zona Wi-Fi (el nombre cambia según la marca).',
        ),
      );
      final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.first.text, 'Abre Ajustes › Zona Wi-Fi');
      expect(spans.first.style?.fontWeight, FontWeight.w600);
      expect(spans.last.text, ' (el nombre cambia según la marca).');
      expect(spans.last.style?.fontWeight, isNot(FontWeight.w600));
    });

    testWidgets('AC1: elegir iPhone cambia los pasos y Android los '
        'devuelve', (tester) async {
      await pumpGuide(tester);

      await tester.tap(_label('iPhone'));
      await tester.pumpAndSettle();

      expect(_platform(tester), HotspotPlatform.iphone);
      expect(_steps(tester), [
        _iphoneOpen,
        'Comparte la contraseña con tu grupo y que se unan a tu red.',
        _iphoneKeepOpen,
      ]);

      await tester.tap(_label('Android'));
      await tester.pumpAndSettle();

      expect(_platform(tester), HotspotPlatform.android);
      expect(
        _steps(tester).first,
        'Abre Ajustes › Zona Wi-Fi (el nombre cambia según la marca).',
      );
    });

    testWidgets('AC1: en iOS la guía también empieza en Android, que se '
        'prioriza como anfitrión', (tester) async {
      await pumpGuide(tester);

      expect(_platform(tester), HotspotPlatform.android);
      expect(
        _steps(tester).first,
        'Abre Ajustes › Zona Wi-Fi (el nombre cambia según la marca).',
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('AC1: al cambiar de pestaña los pasos nuevos entran con un '
        'fundido', (tester) async {
      await pumpGuide(tester);
      expect(_stepsOpacity(tester), 1);

      await tester.tap(_label('iPhone'));
      await tester.pump();

      expect(_steps(tester).first, _iphoneOpen);
      expect(_stepsOpacity(tester), lessThan(1));

      await tester.pumpAndSettle();
      expect(_stepsOpacity(tester), 1);
    });

    testWidgets('P92: en Android, bajo sus pasos, «Abrir ajustes de zona '
        'Wi-Fi» abre los ajustes del punto de acceso', (tester) async {
      await pumpGuide(tester);

      final open = _button('Abrir ajustes de zona Wi-Fi');
      expect(open, findsOneWidget);
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(settings.opened, ['hotspot']);

      // Los pasos del iPhone son para otro teléfono: sin botón.
      await tester.tap(_label('iPhone'));
      await tester.pumpAndSettle();
      expect(open, findsNothing);
      expect(_button('Abrir Ajustes'), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('P93: en iPhone el botón sale bajo sus pasos y dice «Abrir '
        'Ajustes»', (tester) async {
      await pumpGuide(tester);
      expect(_button('Abrir ajustes de zona Wi-Fi'), findsNothing);

      await tester.tap(_label('iPhone'));
      await tester.pumpAndSettle();

      final open = _button('Abrir Ajustes');
      expect(open, findsOneWidget);
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(settings.opened, ['hotspot']);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('AC1: en inglés los textos de la guía salen de la '
        'traducción en', (tester) async {
      await _useEnglish(tester);
      await pumpGuide(tester);

      expect(_iconButton('Back'), findsOneWidget);
      expect(_label('Step 2 of 3'), findsOneWidget);
      expect(find.text('Set up the network'), findsOneWidget);
      expect(find.text('Turn on your hotspot'), findsOneWidget);
      expect(
        find.text("Your phone will be the group's antenna."),
        findsOneWidget,
      );
      expect(_label('Android'), findsOneWidget);
      expect(_label('iPhone'), findsOneWidget);
      expect(_steps(tester), [
        'Open Settings › Hotspot (the name varies by brand).',
        'Turn it on and share its name and password with your group.',
        _androidComeBackEn,
      ]);
      expect(find.text("It's on"), findsOneWidget);
      expect(find.text("We're already on the same Wi-Fi"), findsOneWidget);

      await tester.tap(_label('iPhone'));
      await tester.pumpAndSettle();

      expect(_steps(tester), [
        _iphoneOpenEn,
        'Share the password with your group so they join your network.',
        _iphoneKeepOpenEn,
      ]);
    });
  });

  group('De la guía a la nueva frecu', () {
    testWidgets('AC2: «Ya está activo» pasa a la nueva frecu', (tester) async {
      await pumpGuide(tester);

      await tester.tap(find.text('Ya está activo'));
      await tester.pumpAndSettle();

      expect(find.byType(NewRoomStep), findsOneWidget);
      expect(_label('Paso 3 de 3'), findsOneWidget);
      expect(find.text('Nueva frecu'), findsOneWidget);
      expect(find.byType(HotspotGuideStep), findsNothing);
    });

    testWidgets('AC2: «Ya estamos en la misma Wi-Fi» también pasa a la '
        'nueva frecu', (tester) async {
      await pumpGuide(tester);

      await tester.tap(find.text('Ya estamos en la misma Wi-Fi'));
      await tester.pumpAndSettle();

      expect(find.byType(NewRoomStep), findsOneWidget);
      expect(_label('Paso 3 de 3'), findsOneWidget);
    });

    testWidgets('AC2: Atrás en la nueva frecu vuelve a la guía y al volver '
        'conserva el nombre y el código', (tester) async {
      await pumpGuide(tester);
      await tester.tap(find.text('Ya está activo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Ruta del domingo');
      await tester.tap(_iconButton('Generar otro'));
      await tester.pumpAndSettle();
      expect(tester.widget<FrPinField>(find.byType(FrPinField)).value, '1593');

      await tester.tap(_iconButton('Atrás'));
      await tester.pumpAndSettle();

      expect(find.byType(NewRoomStep), findsNothing);
      expect(find.text('Prepara la red'), findsOneWidget);
      expect(find.byType(CreateRoomPage), findsOneWidget);

      await tester.tap(find.text('Ya está activo'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Ruta del domingo',
      );
      expect(tester.widget<FrPinField>(find.byType(FrPinField)).value, '1593');
    });

    testWidgets('AC2: el gesto de volver en la nueva frecu vuelve a la '
        'guía', (tester) async {
      await pumpGuide(tester);
      await tester.tap(find.text('Ya está activo'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(NewRoomStep), findsNothing);
      expect(find.byType(HotspotGuideStep), findsOneWidget);
    });

    testWidgets('AC1: Atrás en la guía vuelve a «¿Cómo se une tu grupo?» y, '
        'desde ahí, al inicio', (tester) async {
      await pumpGuide(tester);

      await tester.tap(_iconButton('Atrás'));
      await tester.pumpAndSettle();

      expect(find.byType(HotspotGuideStep), findsNothing);
      expect(find.text('¿Cómo se une tu grupo?'), findsOneWidget);

      await tester.tap(_iconButton('Atrás'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateRoomPage), findsNothing);
      expect(find.byType(LobbyPage), findsOneWidget);
    });
  });

  group('Movimiento de la ilustración', () {
    test('AC6: cada anillo nace en su cuarto de fase y avanza 0,35 por '
        'segundo sin pasar de 1', () {
      for (var ring = 0; ring < 4; ring++) {
        expect(hotspotRingPhase(0, ring), closeTo(ring / 4, 1e-9));
      }
      expect(hotspotRingPhase(1, 0), closeTo(0.35, 1e-9));
      expect(hotspotRingPhase(2, 3), closeTo(0.45, 1e-9));
      for (var s = 0.0; s < 20; s += 0.37) {
        expect(hotspotRingPhase(s, 2), inInclusiveRange(0, 1));
        expect(hotspotRingPhase(s, 2), lessThan(1));
      }
    });

    testWidgets('AC6: con movimiento reducido la ilustración queda quieta y '
        'no pide cuadros', (tester) async {
      await pumpGuide(tester);

      expect(tester.binding.hasScheduledFrame, isFalse);
      final before = _painter(tester).seconds.value;
      await tester.pump(const Duration(seconds: 1));
      expect(_painter(tester).seconds.value, before);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('AC6: sin movimiento reducido los anillos se mueven en cada '
        'cuadro', (tester) async {
      await pumpGuide(tester);

      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isTrue);
      final before = _painter(tester).seconds.value;
      await tester.pump(const Duration(milliseconds: 100));
      final after = _painter(tester).seconds.value;
      expect(after, greaterThan(before));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });
  });
}
