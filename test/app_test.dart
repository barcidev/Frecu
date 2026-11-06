import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/guards/permissions_guard.dart';
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

    // AC3
    testWidgets('redirects to PermissionsPage when permissions are missing', (
      tester,
    ) async {
      final router = AppRouter(
        permissionsGuard: PermissionsGuard(hasPermissions: false),
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(child: FrecuApp(appRouter: router)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(t.permissions.title), findsOneWidget);
      expect(find.text(t.permissions.grant), findsOneWidget);
    });
  });
}
