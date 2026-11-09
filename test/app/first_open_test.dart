// AC1: CUANDO la app se abre sin nombre guardado ENTONCES muestra la bienvenida del recorrido de la primera vez en lugar del inicio.
// AC2: CUANDO la app se abre con el nombre guardado pero sin haber completado el recorrido (sin pulsar Continuar en los permisos) ENTONCES muestra la bienvenida del recorrido, y su paso del nombre trae el nombre guardado ya escrito.
// AC3: CUANDO la app se abre con el nombre guardado y el recorrido completado ENTONCES va directo al inicio, sin la bienvenida, aunque algún permiso siga negado o por pedir (Android responde `denied` al consultar un permiso negado, nunca `permanentlyDenied`).
// AC4: CUANDO el recorrido termina con Continuar, aunque se haya negado algún permiso ENTONCES se guarda que se completó, el inicio queda como única pantalla y el recorrido no se vuelve a abrir mientras la app siga abierta, tampoco al volver al inicio ni al volver a abrir la app.
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/pages/lobby_page.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/permissions/data/repositories/onboarding_repository_impl.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:frecu/features/permissions/domain/repositories/permission_repository.dart';
import 'package:frecu/features/permissions/presentation/providers/permission_provider.dart';
import 'package:frecu/features/permissions/presentation/widgets/name_step.dart';
import 'package:frecu/features/permissions/presentation/widgets/permissions_step.dart';
import 'package:frecu/features/permissions/presentation/widgets/welcome_step.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _microphone = AppPermission.microphone;
const _nearby = AppPermission.bluetoothConnect;
const _notification = AppPermission.notification;

/// Los tres permisos del recorrido concedidos.
const _allGranted = {
  _microphone: AppPermissionStatus.granted,
  _nearby: AppPermissionStatus.granted,
  _notification: AppPermissionStatus.granted,
};

/// Permisos de un Android en memoria: [current] es lo que lee `checkStatus`
/// (`denied`, por pedir, si falta: Android nunca informa `permanentlyDenied`
/// al consultar) y [answers] lo que responde la persona al pedirlos
/// (concedido si falta).
class _FakePermissions implements PermissionRepository {
  _FakePermissions({
    Map<AppPermission, AppPermissionStatus>? current,
    Map<AppPermission, AppPermissionStatus>? answers,
  }) : current = {...?current},
       answers = {...?answers};

  final Map<AppPermission, AppPermissionStatus> current;
  final Map<AppPermission, AppPermissionStatus> answers;

  @override
  Future<Result<AppPermissionStatus>> checkStatus(
    AppPermission permission,
  ) async {
    final status = current[permission] ?? AppPermissionStatus.denied;
    // Como en Android: lo negado para siempre se lee como `denied`.
    return Result.success(
      status == AppPermissionStatus.permanentlyDenied
          ? AppPermissionStatus.denied
          : status,
    );
  }

  @override
  Future<Result<AppPermissionStatus>> request(AppPermission permission) async {
    final status = answers[permission] ?? AppPermissionStatus.granted;
    current[permission] = status;
    return Result.success(status);
  }

  @override
  Future<Result<Map<AppPermission, AppPermissionStatus>>> requestAll(
    List<AppPermission> permissions,
  ) async => Result.success({
    for (final permission in permissions)
      permission: (await request(permission)).dataOrNull!,
  });

  @override
  Future<bool> openAppSettings() async => true;
}

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

/// Guarda en el almacenamiento en memoria el [name] y, si [completed], que el
/// recorrido ya se completó.
void _useStorage({String? name, bool completed = false}) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        if (name != null) PreferencesRepositoryImpl.displayNameKey: name,
        if (completed) OnboardingRepositoryImpl.completedKey: true,
      });
}

/// Abre la app como al arrancar (preferencias ya leídas, sin router inyectado
/// y sin la intro) en un teléfono de 390 × 844 con movimiento reducido, con
/// lo guardado en el almacenamiento y los [permissions] del teléfono.
Future<void> _openApp(
  WidgetTester tester, {
  required _FakePermissions permissions,
}) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // La malla de la bienvenida anima sin fin: con movimiento reducido queda
  // quieta y pumpAndSettle termina.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final discovery = _MockDiscoveryRepository();
  when(discovery.watchNearbyRooms)
      .thenAnswer((_) => Stream<List<NearbyRoom>>.value(const []));
  when(discovery.dispose).thenAnswer((_) async {});

  final container = ProviderContainer(
    overrides: [
      permissionRepositoryProvider.overrideWithValue(permissions),
      discoveryRepositoryProvider.overrideWithValue(discovery),
    ],
  );
  addTearDown(container.dispose);
  await container.read(preferencesProvider.future);

  await tester.pumpWidget(
    TranslationProvider(
      child: UncontrolledProviderScope(
        container: container,
        child: const FrecuApp(showIntro: false),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _buttonIn(Finder of, String label) => find.descendant(
  of: of,
  matching: find.byWidgetPredicate(
    (widget) => widget is FrButton && widget.label == label,
  ),
);

Finder get _nameInput => find.descendant(
  of: find.byType(NameStep),
  matching: find.byType(TextField),
);

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

StackRouter _routerOf(WidgetTester tester) =>
    AutoRouter.of(tester.element(find.byType(LobbyPage)));

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.es));

  group('Primera apertura', () {
    testWidgets('AC1: sin nombre guardado abre la bienvenida y no el inicio', (
      tester,
    ) async {
      _useStorage();
      await _openApp(
        tester,
        permissions: _FakePermissions(current: _allGranted),
      );

      expect(find.byType(WelcomeStep), findsOneWidget);
      expect(find.text(t.permissions.welcome.title), findsOneWidget);
      expect(find.byType(LobbyPage), findsNothing);
    });

    testWidgets(
      'AC2: con nombre y el recorrido sin completar abre la bienvenida y el '
      'paso del nombre trae el guardado',
      (tester) async {
        _useStorage(name: 'Ana');
        await _openApp(
          tester,
          permissions: _FakePermissions(current: _allGranted),
        );

        expect(find.byType(WelcomeStep), findsOneWidget);
        expect(find.byType(LobbyPage), findsNothing);

        await _tapAndSettle(
          tester,
          _buttonIn(find.byType(WelcomeStep), t.permissions.welcome.start),
        );

        expect(tester.widget<TextField>(_nameInput).controller?.text, 'Ana');
      },
    );

    testWidgets(
      'AC3: con nombre y el recorrido completado va directo al inicio',
      (tester) async {
        _useStorage(name: 'Ana', completed: true);
        await _openApp(
          tester,
          permissions: _FakePermissions(current: _allGranted),
        );

        expect(find.byType(LobbyPage), findsOneWidget);
        expect(find.byType(WelcomeStep), findsNothing);
        expect(_routerOf(tester).current.name, LobbyRoute.name);
      },
    );

    testWidgets(
      'AC3: con el recorrido completado y permisos que Android lee como por '
      'pedir va directo al inicio',
      (tester) async {
        _useStorage(name: 'Ana', completed: true);
        await _openApp(
          tester,
          permissions: _FakePermissions(
            current: {
              _microphone: AppPermissionStatus.permanentlyDenied,
              _nearby: AppPermissionStatus.granted,
              _notification: AppPermissionStatus.denied,
            },
          ),
        );

        expect(find.byType(LobbyPage), findsOneWidget);
        expect(find.byType(WelcomeStep), findsNothing);
      },
    );

    testWidgets(
      'AC4: al terminar el recorrido con un permiso negado queda el inicio y '
      'no vuelve a abrirse, tampoco al volver a abrir la app',
      (tester) async {
        _useStorage();
        final permissions = _FakePermissions(
          answers: {_notification: AppPermissionStatus.denied},
        );
        await _openApp(tester, permissions: permissions);

        await _tapAndSettle(
          tester,
          _buttonIn(find.byType(WelcomeStep), t.permissions.welcome.start),
        );
        await tester.enterText(_nameInput, 'Ana');
        await tester.pump();
        await _tapAndSettle(
          tester,
          _buttonIn(find.byType(NameStep), t.permissions.name.next),
        );
        final step = find.byType(PermissionsStep);
        await _tapAndSettle(tester, _buttonIn(step, t.permissions.grant));
        await _tapAndSettle(tester, _buttonIn(step, t.permissions.finish));

        expect(find.byType(LobbyPage), findsOneWidget);
        expect(find.byType(WelcomeStep), findsNothing);
        expect(find.byType(PermissionsStep), findsNothing);
        final router = _routerOf(tester);
        expect(router.stack, hasLength(1));
        expect(router.current.name, LobbyRoute.name);

        // Volver al inicio no reabre el recorrido.
        unawaited(router.replaceAll([const LobbyRoute()]));
        await tester.pumpAndSettle();

        expect(find.byType(LobbyPage), findsOneWidget);
        expect(find.byType(WelcomeStep), findsNothing);
        expect(_routerOf(tester).stack, hasLength(1));

        // Al volver a abrir la app (mismo almacenamiento, notificaciones aún
        // por pedir según Android) va directo al inicio.
        await tester.pumpWidget(const SizedBox());
        await _openApp(tester, permissions: permissions);

        expect(find.byType(LobbyPage), findsOneWidget);
        expect(find.byType(WelcomeStep), findsNothing);
      },
    );
  });
}
