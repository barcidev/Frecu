// AC3: CUANDO el usuario toca Empezar ENTONCES pasa al paso del nombre (segundo paso encendido, «02 / 03») con el título «¿Cómo te llamamos?», el texto, la firma de señal en su escenario con la leyenda, el campo «Nombre visible» con su ayuda (y el nombre guardado si ya había uno) y Continuar; Atrás o el gesto de volver del sistema regresan al paso anterior sin perder lo escrito.
// AC5: CUANDO el usuario toca Continuar o confirma desde el teclado con un nombre válido ENTONCES el nombre se guarda sin espacios alrededor con `preferencesProvider`, se conserva al reabrir la app y el recorrido pasa a los permisos.
// AC7: CUANDO se llega a los permisos ENTONCES se ven el tercer paso encendido y «03 / 03», el título «Tres permisos y listo.», el texto, las filas de micrófono, red local y dispositivos cercanos, y notificaciones, cada una con su porqué y su estado actual, la nota de que la cámara se pide solo al escanear un QR y el botón Conceder permisos, o Continuar si ya están todos concedidos.
// AC8: CUANDO el usuario toca Conceder permisos ENTONCES se piden uno por uno los que faltan; cada fila muestra su resultado (concedido con la marca de señal; negado con el borde de alerta y un botón Ajustes que abre los ajustes de la app) y el botón pasa a Continuar aunque alguno se haya negado; CUANDO el usuario vuelve a la app ENTONCES se leen de nuevo los estados.
// AC9: CUANDO el usuario toca Continuar en los permisos ENTONCES el recorrido termina en el inicio (`LobbyRoute`) como única pantalla.
// AC10: CUANDO el sistema pide reducir el movimiento ENTONCES la malla de la bienvenida y la firma del nombre quedan en un cuadro fijo y visibles, los pasos cambian con un fundido y la marca de concedido aparece sin resorte, sin ocultar ningún estado.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_steps.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:frecu/features/permissions/domain/repositories/permission_repository.dart';
import 'package:frecu/features/permissions/presentation/providers/onboarding_permissions_provider.dart';
import 'package:frecu/features/permissions/presentation/providers/permission_provider.dart';
import 'package:frecu/features/permissions/presentation/widgets/name_step.dart';
import 'package:frecu/features/permissions/presentation/widgets/permission_row.dart';
import 'package:frecu/features/permissions/presentation/widgets/permissions_step.dart';
import 'package:frecu/features/permissions/presentation/widgets/welcome_step.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _microphone = AppPermission.microphone;
const _nearby = AppPermission.bluetoothConnect;
const _notification = AppPermission.notification;

/// Permisos del teléfono en memoria: [current] es lo que lee `checkStatus` y
/// [answers] lo que responde la persona al pedirlos (concedido si falta).
class _FakePermissions implements PermissionRepository {
  _FakePermissions({
    Map<AppPermission, AppPermissionStatus>? current,
    Map<AppPermission, AppPermissionStatus>? answers,
    this.failing = const {},
  }) : current = {...?current},
       answers = {...?answers};

  final Map<AppPermission, AppPermissionStatus> current;
  final Map<AppPermission, AppPermissionStatus> answers;

  /// Permisos cuya solicitud falla.
  final Set<AppPermission> failing;

  final List<AppPermission> checked = [];
  final List<AppPermission> requested = [];
  int settingsOpened = 0;

  @override
  Future<Result<AppPermissionStatus>> checkStatus(
    AppPermission permission,
  ) async {
    checked.add(permission);
    return Result.success(current[permission] ?? AppPermissionStatus.denied);
  }

  @override
  Future<Result<AppPermissionStatus>> request(AppPermission permission) async {
    requested.add(permission);
    if (failing.contains(permission)) {
      return const Result.failure(Failure.unexpected(message: 'sin plugin'));
    }
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
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }
}

ProviderContainer _container(_FakePermissions permissions) {
  final container = ProviderContainer(
    overrides: [permissionRepositoryProvider.overrideWithValue(permissions)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Abre la app en un teléfono de 390 × 844 con movimiento reducido y
/// [permissions], recorre la bienvenida y el nombre («Ana») y devuelve el
/// router ya en los permisos.
Future<AppRouter> _reachPermissions(
  WidgetTester tester,
  _FakePermissions permissions,
) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();

  final container = _container(permissions);
  await container.read(preferencesProvider.future);
  final router = AppRouter();
  await tester.pumpWidget(
    TranslationProvider(
      child: UncontrolledProviderScope(
        container: container,
        child: FrecuApp(appRouter: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  unawaited(router.push(const PermissionsRoute()));
  await tester.pumpAndSettle();

  await tester.tap(
    _buttonIn(find.byType(WelcomeStep), t.permissions.welcome.start),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byType(NameStep),
      matching: find.byType(TextField),
    ),
    'Ana',
  );
  await tester.pump();
  await tester.tap(_buttonIn(find.byType(NameStep), t.permissions.name.next));
  await tester.pumpAndSettle();
  return router;
}

/// Envía a la app el estado [state] como lo haría el sistema.
Future<void> _lifecycle(WidgetTester tester, AppLifecycleState state) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );

Finder get _step => find.byType(PermissionsStep);

Finder _inStep(Finder matching) =>
    find.descendant(of: _step, matching: matching);

Finder _buttonIn(Finder of, String label) => find.descendant(
  of: of,
  matching: find.byWidgetPredicate(
    (widget) => widget is FrButton && widget.label == label,
  ),
);

Finder get _grant => _buttonIn(_step, 'Conceder permisos');

Finder get _finish => _buttonIn(_step, 'Continuar');

Finder _row(String title) => _inStep(
  find.byWidgetPredicate(
    (widget) => widget is PermissionRow && widget.title == title,
  ),
);

PermissionState _rowState(WidgetTester tester, String title) =>
    tester.widget<PermissionRow>(_row(title)).state;

void main() {
  group('Estado de los permisos del recorrido', () {
    test('AC7: lee el estado actual de cada permiso', () async {
      final permissions = _FakePermissions(
        current: {
          _microphone: AppPermissionStatus.granted,
          _nearby: AppPermissionStatus.permanentlyDenied,
          _notification: AppPermissionStatus.denied,
        },
      );
      final container = _container(permissions);

      final state = await container.read(onboardingPermissionsProvider.future);

      expect(onboardingPermissions, [_microphone, _nearby, _notification]);
      expect(state.stateOf(_microphone), PermissionState.granted);
      expect(state.stateOf(_nearby), PermissionState.denied);
      expect(state.stateOf(_notification), PermissionState.pending);
      expect(state.allGranted, isFalse);
      expect(state.canContinue, isFalse);
      expect(permissions.requested, isEmpty);
    });

    test('AC7: concedidos, limitados o provisionales permiten continuar sin '
        'pedirlos', () async {
      final container = _container(
        _FakePermissions(
          current: {
            _microphone: AppPermissionStatus.granted,
            _nearby: AppPermissionStatus.limited,
            _notification: AppPermissionStatus.provisional,
          },
        ),
      );

      final state = await container.read(onboardingPermissionsProvider.future);

      expect(state.allGranted, isTrue);
      expect(state.canContinue, isTrue);
    });

    test(
      'AC7: en iOS la red local no se pide y cuenta como concedida',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final permissions = _FakePermissions();
        final container = _container(permissions);

        final state = await container.read(
          onboardingPermissionsProvider.future,
        );
        expect(state.stateOf(_nearby), PermissionState.granted);
        await container
            .read(onboardingPermissionsProvider.notifier)
            .requestMissing();

        expect(permissions.checked, isNot(contains(_nearby)));
        expect(permissions.requested, [_microphone, _notification]);
      },
    );

    test('AC8: pide uno por uno solo los que faltan', () async {
      final permissions = _FakePermissions(
        current: {_microphone: AppPermissionStatus.granted},
        answers: {_notification: AppPermissionStatus.permanentlyDenied},
      );
      final container = _container(permissions);
      await container.read(onboardingPermissionsProvider.future);

      await container
          .read(onboardingPermissionsProvider.notifier)
          .requestMissing();

      final state = container.read(onboardingPermissionsProvider).requireValue;
      expect(permissions.requested, [_nearby, _notification]);
      expect(state.stateOf(_microphone), PermissionState.granted);
      expect(state.stateOf(_nearby), PermissionState.granted);
      expect(state.stateOf(_notification), PermissionState.denied);
      expect(state.requesting, isFalse);
      expect(state.requested, isTrue);
      expect(state.canContinue, isTrue);
    });

    test('AC8: un permiso que no se pudo pedir queda negado', () async {
      final container = _container(_FakePermissions(failing: {_microphone}));
      await container.read(onboardingPermissionsProvider.future);

      await container
          .read(onboardingPermissionsProvider.notifier)
          .requestMissing();

      final state = container.read(onboardingPermissionsProvider).requireValue;
      expect(state.stateOf(_microphone), PermissionState.denied);
      expect(state.stateOf(_nearby), PermissionState.granted);
    });

    test('AC8: al releer, lo concedido en los ajustes se enciende y lo negado '
        'no vuelve a pendiente', () async {
      final permissions = _FakePermissions(
        answers: {
          _microphone: AppPermissionStatus.denied,
          _notification: AppPermissionStatus.denied,
        },
      );
      final container = _container(permissions);
      await container.read(onboardingPermissionsProvider.future);
      final notifier = container.read(onboardingPermissionsProvider.notifier);
      await notifier.requestMissing();

      permissions.current[_microphone] = AppPermissionStatus.granted;
      await notifier.refresh();

      final state = container.read(onboardingPermissionsProvider).requireValue;
      expect(state.stateOf(_microphone), PermissionState.granted);
      expect(state.stateOf(_notification), PermissionState.denied);
      expect(state.requested, isTrue);
    });

    test('AC8: Ajustes abre los ajustes de la app', () async {
      final permissions = _FakePermissions();
      final container = _container(permissions);
      await container.read(onboardingPermissionsProvider.future);

      await container
          .read(onboardingPermissionsProvider.notifier)
          .openSettings();

      expect(permissions.settingsOpened, 1);
    });
  });

  group('Paso de permisos', () {
    testWidgets('AC5 y AC7: tras guardar el nombre el recorrido llega a los '
        'permisos con su porqué', (tester) async {
      await _reachPermissions(tester, _FakePermissions());

      expect(_step, findsOneWidget);
      final steps = tester.widget<FrSteps>(_inStep(find.byType(FrSteps)));
      expect(steps.count, 3);
      expect(steps.current, 2);
      expect(_inStep(find.text('03 / 03')), findsOneWidget);
      expect(_inStep(find.text('Tres permisos y listo.')), findsOneWidget);
      expect(
        _inStep(
          find.text(
            'Frecu solo habla con tu red local. Tu voz nunca sale de tu grupo.',
          ),
        ),
        findsOneWidget,
      );
      for (final (title, why) in [
        ('Micrófono', 'Para que tu grupo te escuche.'),
        (
          'Red local y dispositivos cercanos',
          'Para encontrar frecus y usar audífonos Bluetooth.',
        ),
        ('Notificaciones', 'Mantienen la frecu viva con la pantalla apagada.'),
      ]) {
        expect(_row(title), findsOneWidget);
        expect(tester.widget<PermissionRow>(_row(title)).description, why);
        expect(_rowState(tester, title), PermissionState.pending);
      }
      expect(
        _inStep(find.text('La cámara se pedirá solo al escanear un QR.')),
        findsOneWidget,
      );
      expect(_grant, findsOneWidget);
      expect(_finish, findsNothing);
    });

    testWidgets('AC7: si ya están todos concedidos el botón es Continuar', (
      tester,
    ) async {
      await _reachPermissions(
        tester,
        _FakePermissions(
          current: {
            _microphone: AppPermissionStatus.granted,
            _nearby: AppPermissionStatus.granted,
            _notification: AppPermissionStatus.granted,
          },
        ),
      );

      expect(_rowState(tester, 'Micrófono'), PermissionState.granted);
      expect(_finish, findsOneWidget);
      expect(_grant, findsNothing);
    });

    testWidgets('AC8: Conceder permisos pide los que faltan, marca cada '
        'resultado y pasa a Continuar', (tester) async {
      final permissions = _FakePermissions(
        answers: {_nearby: AppPermissionStatus.permanentlyDenied},
      );
      await _reachPermissions(tester, permissions);

      await tester.tap(_grant);
      await tester.pumpAndSettle();

      expect(permissions.requested, [_microphone, _nearby, _notification]);
      expect(_rowState(tester, 'Micrófono'), PermissionState.granted);
      expect(
        _rowState(tester, 'Red local y dispositivos cercanos'),
        PermissionState.denied,
      );
      expect(_rowState(tester, 'Notificaciones'), PermissionState.granted);
      expect(
        find.descendant(
          of: _row('Red local y dispositivos cercanos'),
          matching: find.text('AJUSTES'),
        ),
        findsOneWidget,
      );
      expect(_finish, findsOneWidget);
      expect(_grant, findsNothing);
    });

    testWidgets('AC8: Ajustes abre los ajustes de la app y al volver se leen '
        'los estados', (tester) async {
      final permissions = _FakePermissions(
        answers: {_nearby: AppPermissionStatus.permanentlyDenied},
      );
      await _reachPermissions(tester, permissions);
      await tester.tap(_grant);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: _row('Red local y dispositivos cercanos'),
          matching: find.text('AJUSTES'),
        ),
      );
      await tester.pumpAndSettle();
      expect(permissions.settingsOpened, 1);

      permissions.current[_nearby] = AppPermissionStatus.granted;
      await _lifecycle(tester, AppLifecycleState.inactive);
      await _lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(
        _rowState(tester, 'Red local y dispositivos cercanos'),
        PermissionState.granted,
      );
    });

    testWidgets('AC9: Continuar termina en el inicio como única pantalla', (
      tester,
    ) async {
      final router = await _reachPermissions(
        tester,
        _FakePermissions(
          current: {
            _microphone: AppPermissionStatus.granted,
            _nearby: AppPermissionStatus.granted,
            _notification: AppPermissionStatus.granted,
          },
        ),
      );

      await tester.tap(_finish);
      await tester.pumpAndSettle();

      expect(router.stack, hasLength(1));
      expect(router.current.name, LobbyRoute.name);
      expect(_step, findsNothing);
    });

    testWidgets('AC3: Atrás en los permisos vuelve al nombre con lo escrito', (
      tester,
    ) async {
      await _reachPermissions(tester, _FakePermissions());

      await tester.tap(
        _inStep(
          find.byWidgetPredicate(
            (widget) =>
                widget is FrIconButton && widget.semanticLabel == 'Atrás',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_step, findsNothing);
      final input = find.descendant(
        of: find.byType(NameStep),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(input).controller!.text, 'Ana');
    });

    testWidgets('AC10: con movimiento reducido la marca de concedido aparece '
        'sin resorte y queda visible', (tester) async {
      await _reachPermissions(tester, _FakePermissions());

      await tester.tap(_grant);
      final marks = find.descendant(
        of: _step,
        matching: find.byType(PermissionStatusMark),
      );
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        // Sin resorte: la marca nunca escala.
        expect(
          find.descendant(of: marks, matching: find.byType(Transform)),
          findsNothing,
        );
      }
      expect(marks, findsNWidgets(3));
      final opacities = tester.widgetList<Opacity>(
        find.descendant(of: marks, matching: find.byType(Opacity)),
      );
      expect(opacities.map((opacity) => opacity.opacity), everyElement(1));

      await tester.pumpAndSettle();
      for (final title in [
        'Micrófono',
        'Red local y dispositivos cercanos',
        'Notificaciones',
      ]) {
        expect(_rowState(tester, title), PermissionState.granted);
      }
      expect(_finish, findsOneWidget);
    });

    testWidgets('AC1: en inglés los permisos salen de la traducción en', (
      tester,
    ) async {
      // El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

      await _reachPermissions(tester, _FakePermissions());

      expect(
        _inStep(find.text("Three permissions and you're set.")),
        findsOneWidget,
      );
      expect(_row('Microphone'), findsOneWidget);
      expect(_buttonIn(_step, 'Grant permissions'), findsOneWidget);
    });
  });
}
