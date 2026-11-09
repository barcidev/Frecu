// P69: CUANDO la app arranca ENTONCES antes de la primera ruta (bienvenida o inicio) muestra la intro del prototipo en noche: la portadora plana crece, se modula y se pliega en la marca de Frecu (Lissajous 2:3, fase 0,6) con el dial de marcas, y aparecen «frecu», «Voz de grupo. Sin internet.» y el pie con la versión, «Red local» y «Malla P2P»; a los 3,9 s, o con un toque, se funde y deja la primera ruta; con movimiento reducido queda quieta en su último cuadro y se funde sola; con un router inyectado (pruebas) no aparece.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/intro/frecu_intro.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/pages/lobby_page.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/permissions/data/repositories/onboarding_repository_impl.dart';
import 'package:frecu/features/settings/data/datasources/app_info_datasource.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/presentation/providers/app_version_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

/// Abre la app como al arrancar (sin router inyectado) en un teléfono de
/// 390 × 844, con el nombre guardado y el recorrido completo (abre el
/// inicio) y la versión 0.1.0; [reduceMotion] pide movimiento reducido.
Future<void> _launch(
  WidgetTester tester, {
  bool reduceMotion = false,
  AppRouter? router,
}) async {
  LocaleSettings.setLocaleSync(AppLocale.es);
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        PreferencesRepositoryImpl.displayNameKey: 'Ana',
        OnboardingRepositoryImpl.completedKey: true,
      });
  final discovery = _MockDiscoveryRepository();
  when(discovery.watchNearbyRooms)
      .thenAnswer((_) => Stream<List<NearbyRoom>>.value(const []));
  when(discovery.dispose).thenAnswer((_) async {});
  final container = ProviderContainer(
    overrides: [
      discoveryRepositoryProvider.overrideWithValue(discovery),
      appInfoDataSourceProvider.overrideWithValue(
        AppInfoDataSource(
          read: () async => PackageInfo(
            appName: 'Frecu',
            packageName: 'com.frecu',
            version: '0.1.0',
            buildNumber: '1',
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(preferencesProvider.future);
  await tester.pumpWidget(
    TranslationProvider(
      child: UncontrolledProviderScope(
        container: container,
        child: FrecuApp(appRouter: router),
      ),
    ),
  );
}

Finder get _intro => find.byType(FrecuIntro);

void main() {
  group('Intro', () {
    testWidgets('P69: muestra la marca, el lema y el pie sobre la primera '
        'ruta y, con movimiento reducido, se funde sola', (tester) async {
      await _launch(tester, reduceMotion: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_intro, findsOneWidget);
      expect(tester.widget<FrecuIntro>(_intro).still, isTrue);
      expect(find.text('frecu'), findsWidgets);
      expect(find.text('Voz de grupo. Sin internet.'), findsOneWidget);
      expect(find.text('V0.1.0'), findsOneWidget);
      expect(find.text('RED LOCAL'), findsOneWidget);
      expect(find.text('MALLA P2P'), findsOneWidget);
      // La primera ruta se abre debajo mientras tanto.
      expect(find.byType(LobbyPage), findsOneWidget);
      // Siempre en noche, como el splash nativo.
      expect(
        Theme.of(tester.element(find.text('MALLA P2P'))).brightness,
        Brightness.dark,
      );

      await tester.pumpAndSettle();

      expect(_intro, findsNothing);
      expect(find.byType(LobbyPage), findsOneWidget);
    });

    testWidgets('P69: los textos de la intro no llevan subrayado', (
      tester,
    ) async {
      await _launch(tester, reduceMotion: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // La intro va encima del navegador, fuera de todo `Material`: sus
      // textos no heredan el estilo de error de `MaterialApp` (subrayado
      // doble amarillo).
      final texts = tester
          .widgetList<RichText>(
            find.descendant(of: _intro, matching: find.byType(RichText)),
          )
          .map((text) => text.text)
          .toList();
      expect(
        texts.map((text) => text.toPlainText()),
        containsAll(<String>[
          'frecu',
          'Voz de grupo. Sin internet.',
          'V0.1.0',
          'RED LOCAL',
          'MALLA P2P',
        ]),
      );
      for (final text in texts) {
        expect(
          text.style?.decoration,
          anyOf(isNull, TextDecoration.none),
          reason: '«${text.toPlainText()}» no lleva subrayado',
        );
      }
    });

    testWidgets('P69: sin tocar, se funde a los 3,9 s', (tester) async {
      await _launch(tester);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(_intro, findsOneWidget);
      expect(tester.widget<FrecuIntro>(_intro).still, isFalse);

      await tester.pump(const Duration(seconds: 1));
      // El fundido arranca en el cuadro siguiente.
      await tester.pump();
      await tester.pump(
        FrecuIntroGate.exitDuration + const Duration(milliseconds: 1),
      );
      await tester.pump();

      expect(_intro, findsNothing);
      expect(find.byType(LobbyPage), findsOneWidget);
    });

    testWidgets('P69: un toque la salta', (tester) async {
      await _launch(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_intro, findsOneWidget);

      await tester.tapAt(const Offset(195, 300));
      await tester.pump();
      await tester.pump(
        FrecuIntroGate.exitDuration + const Duration(milliseconds: 1),
      );
      await tester.pump();

      expect(_intro, findsNothing);
      expect(find.byType(LobbyPage), findsOneWidget);
    });

    testWidgets('P69: con un router inyectado no aparece', (tester) async {
      await _launch(tester, reduceMotion: true, router: AppRouter());
      await tester.pump();

      expect(_intro, findsNothing);
      expect(find.byType(FrecuIntroGate), findsNothing);
    });
  });

  group('IntroCurve', () {
    const size = Size(390, 844);
    final center = IntroCurve.centerOf(size);

    test('P69: empieza como un punto en el centro', () {
      for (var i = 0; i <= IntroCurve.points; i += 13) {
        expect(IntroCurve.pointAt(i, 0, size), center);
      }
      expect(IntroCurve.dialAt(0), 0);
    });

    test('P69: a los 0,5 s es la portadora plana del 36 % del ancho', () {
      final left = IntroCurve.pointAt(0, 0.5, size);
      final right = IntroCurve.pointAt(IntroCurve.points, 0.5, size);
      expect(left.dy, closeTo(center.dy, 1e-9));
      expect(right.dy, closeTo(center.dy, 1e-9));
      expect(right.dx - left.dx, closeTo(2 * 0.36 * 390, 2));
    });

    test('P69: termina plegada en la marca de Frecu con radio 62', () {
      const t = FrecuIntro.stillAt;
      const brand = SignatureParams.brand;
      for (var i = 0; i <= IntroCurve.points; i += 7) {
        final turn = i / IntroCurve.points * math.pi * 2;
        final expected =
            center +
            Offset(
                  math.sin(brand.a * turn + brand.phase + t * 0.25),
                  math.sin(brand.b * turn),
                ) *
                62;
        final point = IntroCurve.pointAt(i, t, size);
        expect(point.dx, closeTo(expected.dx, 1e-6));
        expect(point.dy, closeTo(expected.dy, 1e-6));
      }
      expect(IntroCurve.dialAt(t), 1);
    });
  });
}
