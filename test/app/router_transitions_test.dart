// P53: CUANDO se navega por la app ENTONCES el inicio, Crear, Escanear y la frecu entran con la onda desde el dedo (`FrPageRoute` con `FrTransition.wave`) y Ajustes con el deslizamiento con paralaje (`FrTransition.slide`), como `app.js` (`data-tr`); las demás rutas de página usan la transición de Portadora del tema (`FrPageTransitionsBuilder`), y con movimiento reducido todas son un fundido.
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/features/lobby/presentation/pages/create_room_page.dart';
import 'package:frecu/features/lobby/presentation/pages/lobby_page.dart';
import 'package:frecu/features/settings/presentation/pages/settings_page.dart';
import 'package:frecu/i18n/strings.g.dart';

Matcher _frRoute(FrTransition transition) => isA<FrPageRoute<dynamic>>().having(
  (route) => route.transition,
  'transition',
  transition,
);

void main() {
  group('Rutas de Portadora', () {
    test('P53: cada pantalla tiene su transición del prototipo', () {
      expect(AppRouter.transitions, {
        LobbyRoute.name: FrTransition.wave,
        CreateRoomRoute.name: FrTransition.wave,
        ScanQrRoute.name: FrTransition.wave,
        RoomRoute.name: FrTransition.wave,
        SettingsRoute.name: FrTransition.slide,
      });
      final routes = {
        for (final route in AppRouter().routes) route.name: route,
      };
      for (final name in AppRouter.transitions.keys) {
        expect(
          routes[name]!.type,
          isA<CustomRouteType>().having(
            (type) => type.customRouteBuilder,
            'customRouteBuilder',
            isNotNull,
          ),
          reason: name,
        );
      }
    });

    test('P53: el tema da la transición de Portadora a las demás rutas', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final builders = theme.pageTransitionsTheme.builders;
        for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
          expect(
            builders[platform],
            isA<FrPageTransitionsBuilder>().having(
              (builder) => builder.transition,
              'transition',
              FrTransition.slide,
            ),
          );
        }
      }
      const builder = FrPageTransitionsBuilder();
      expect(builder.transitionDuration, FrTransitions.slideDuration);
      expect(builder.reverseTransitionDuration, FrTransitions.backDuration);
      expect(builder.delegatedTransition, isNotNull);
    });

    testWidgets('P53: el inicio y Crear entran con la onda y Ajustes con el '
        'deslizamiento', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.es);
      // El sintonizador del inicio anima sin fin: con movimiento reducido
      // queda quieto y pumpAndSettle termina.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final router = AppRouter();
      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(child: FrecuApp(appRouter: router)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        ModalRoute.of(tester.element(find.byType(LobbyPage))),
        _frRoute(FrTransition.wave),
      );

      unawaited(router.push(const SettingsRoute()));
      await tester.pumpAndSettle();
      final settings = ModalRoute.of(tester.element(find.byType(SettingsPage)));
      expect(settings, _frRoute(FrTransition.slide));
      // Con movimiento reducido, el fundido de 280 ms.
      expect(settings!.transitionDuration, FrTransitions.reducedDuration);

      unawaited(router.maybePop());
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsNothing);

      unawaited(router.push(const CreateRoomRoute()));
      await tester.pumpAndSettle();
      expect(router.current.name, CreateRoomRoute.name);
      expect(
        ModalRoute.of(tester.element(find.byType(CreateRoomPage))),
        _frRoute(FrTransition.wave),
      );
    });
  });
}
