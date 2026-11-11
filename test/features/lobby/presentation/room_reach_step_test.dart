// AC1: CUANDO el usuario toca «Crear frecu» ENTONCES el primer paso pregunta «¿Cómo se une tu grupo?» con «Local» (marcada por defecto) y «Por internet». Local sigue a «Prepara la red» y luego a «Nueva frecu» (pasos de 3); Por internet va directo a «Nueva frecu» (pasos de 2). Sin internet, o sin punto de encuentro configurado, «Por internet» se ve atenuada y dice qué falta. «Nueva frecu» ya no tiene el interruptor «Permitir internet», y bajo «Abierta a las HH:MM» lleva la etiqueta «Local» o «Por internet».
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/providers/new_room_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/new_room_step.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_reach_step.dart';
import 'package:frecu/features/network/domain/entities/network_state.dart';
import 'package:frecu/features/network/domain/repositories/network_repository.dart';
import 'package:frecu/features/network/presentation/providers/network_provider.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockNetworkRepository extends Mock implements NetworkRepository {}

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

/// Vacía la app antes de acabar para no dejar temporizadores pendientes.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockDiscoveryRepository discovery;
  late _MockNetworkRepository network;
  late StreamController<List<NearbyRoom>> nearby;
  late StreamController<NetworkState> networkStates;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    discovery = _MockDiscoveryRepository();
    network = _MockNetworkRepository();
    nearby = StreamController<List<NearbyRoom>>.broadcast();
    networkStates = StreamController<NetworkState>.broadcast();
    when(() => discovery.watchNearbyRooms()).thenAnswer((_) => nearby.stream);
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(() => network.watchNetworkState())
        .thenAnswer((_) => networkStates.stream);
  });

  tearDown(() async {
    await nearby.close();
    await networkStates.close();
  });

  /// Abre la app en el inicio (390 × 844, movimiento reducido) con el
  /// punto de encuentro [cloud] y toca Crear frecu. [online] dice si hay
  /// internet; por defecto, sí.
  Future<void> pumpReach(
    WidgetTester tester, {
    CloudConfig cloud = CloudConfig.disabled,
    bool Function()? online,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          PreferencesRepositoryImpl.displayNameKey: 'Ana',
        });
    final container = ProviderContainer(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(discovery),
        networkRepositoryProvider.overrideWithValue(network),
        newRoomClockProvider.overrideWithValue(
          () => DateTime(2026, 11, 8, 16, 24),
        ),
        accessCodeGeneratorProvider.overrideWithValue(() => '4827'),
        cloudConfigProvider.overrideWithValue(cloud),
        internetCheckProvider.overrideWithValue(
          () async => online?.call() ?? true,
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(preferencesProvider.future));
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: FrecuApp(appRouter: AppRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.lobby.createRoom));
    await tester.pumpAndSettle();
  }

  group('¿Cómo se une tu grupo?', () {
    const cloud = CloudConfig('https://frecu.example.workers.dev');
    final local = find.byKey(const Key('room_reach_option_local'));
    final internet = find.byKey(const Key('room_reach_option_internet'));

    RoomReachOption option(WidgetTester tester, Finder finder) =>
        tester.widget<RoomReachOption>(finder);

    testWidgets('AC1: Crear frecu abre «¿Cómo se une tu grupo?» con Local '
        'marcada, Por internet y Seguir', (tester) async {
      await pumpReach(tester, cloud: cloud);

      expect(find.byType(RoomReachStep), findsOneWidget);
      expect(_label('Paso 1 de 3'), findsOneWidget);
      expect(find.text('Nueva frecu'), findsOneWidget);
      expect(find.text('¿Cómo se une tu grupo?'), findsOneWidget);
      expect(
        find.text('Se elige una vez. La frecu no mezcla las dos formas.'),
        findsOneWidget,
      );
      expect(find.text('Local'), findsOneWidget);
      expect(
        _label(
          'Todos conectados a la misma Wi-Fi: la que crea tu teléfono o una '
          'que ya tengan, como la de la casa o la oficina. Sin internet y sin '
          'gastar datos.',
        ),
        findsOneWidget,
      );
      expect(find.text('Por internet'), findsOneWidget);
      expect(
        _label(
          'Desde cualquier lugar, con el QR o el enlace. Usa datos móviles.',
        ),
        findsOneWidget,
      );
      expect(option(tester, local).selected, isTrue);
      expect(option(tester, internet).selected, isFalse);
      expect(option(tester, internet).enabled, isTrue);
      expect(find.text('Seguir'), findsOneWidget);
      expect(find.text('Permitir internet'), findsNothing);
    });

    testWidgets('AC1: Local sigue a «Prepara la red» en el paso 2 de 3', (
      tester,
    ) async {
      await pumpReach(tester, cloud: cloud);

      await tester.tap(find.text('Seguir'));
      await tester.pumpAndSettle();

      expect(find.text('Prepara la red'), findsOneWidget);
      expect(_label('Paso 2 de 3'), findsOneWidget);
    });

    testWidgets('AC1: al marcar Por internet el paso es 1 de 2 y Seguir va '
        'directo a «Nueva frecu»', (tester) async {
      await pumpReach(tester, cloud: cloud);

      await tester.tap(internet);
      await tester.pumpAndSettle();
      expect(option(tester, internet).selected, isTrue);
      expect(option(tester, local).selected, isFalse);
      expect(_label('Paso 1 de 2'), findsOneWidget);

      await tester.tap(find.text('Seguir'));
      await tester.pumpAndSettle();

      expect(find.text('Prepara la red'), findsNothing);
      expect(find.byType(NewRoomStep), findsOneWidget);
      expect(_label('Paso 2 de 2'), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('AC1: sin internet, Por internet se ve atenuada, dice qué '
        'falta y no se marca; al volver internet se habilita', (tester) async {
      var online = false;
      await pumpReach(tester, cloud: cloud, online: () => online);

      expect(option(tester, internet).enabled, isFalse);
      expect(
        tester
            .widget<Opacity>(
              find
                  .descendant(of: internet, matching: find.byType(Opacity))
                  .first,
            )
            .opacity,
        lessThan(1),
      );
      expect(
        _label(
          'Necesitas internet para crearla. Conéctate a una Wi-Fi con '
          'internet o activa tus datos.',
        ),
        findsOneWidget,
      );
      await tester.tap(internet, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(option(tester, local).selected, isTrue);
      expect(_label('Paso 1 de 3'), findsOneWidget);

      online = true;
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(option(tester, internet).enabled, isTrue);
      expect(
        _label(
          'Desde cualquier lugar, con el QR o el enlace. Usa datos móviles.',
        ),
        findsOneWidget,
      );
      await _unmount(tester);
    });

    testWidgets('AC1: sin punto de encuentro, Por internet se ve atenuada y '
        'lo dice', (tester) async {
      await pumpReach(tester);

      expect(option(tester, internet).enabled, isFalse);
      expect(
        _label('Esta versión de Frecu no crea frecus por internet.'),
        findsOneWidget,
      );
      expect(option(tester, local).selected, isTrue);
    });

    testWidgets('AC1: en inglés los textos salen de la traducción en', (
      tester,
    ) async {
      await _useEnglish(tester);
      await pumpReach(tester, cloud: cloud);

      expect(_label('Step 1 of 3'), findsOneWidget);
      expect(find.text('How does your group join?'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Over the internet'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
