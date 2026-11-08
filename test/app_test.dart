import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/guards/permissions_guard.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/i18n/strings.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Application bootstrap & navigation', () {
    // AC3
    testWidgets(
      'mounts TranslationProvider, ProviderScope and AppRouter navigates to LobbyPage',
      (tester) async {
        final router = AppRouter();

        await tester.pumpWidget(
          TranslationProvider(
            child: ProviderScope(child: FrecuApp(appRouter: router)),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text(t.lobby.createRoom), findsOneWidget);
        expect(find.text(t.lobby.scanQr), findsOneWidget);
      },
    );

    // AC3; AC1 de la bienvenida: la ruta de permisos empieza en la bienvenida.
    testWidgets('redirects to the onboarding welcome when permissions are '
        'missing', (tester) async {
      // La malla de la bienvenida anima sin fin: con movimiento reducido
      // queda quieta y pumpAndSettle termina.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final router = AppRouter(
        permissionsGuard: PermissionsGuard(hasPermissions: false),
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(child: FrecuApp(appRouter: router)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(t.permissions.welcome.title), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is FrButton && widget.label == t.permissions.welcome.start,
        ),
        findsOneWidget,
      );
    });
  });
}
