// AC5 (épica): CUANDO se abre Ajustes ENTONCES el grupo «General» tiene, después de «Idioma», la fila «Permisos», que muestra cuántos están concedidos y al tocarla pide los que faltan o abre los ajustes del sistema, y la fila «Guía del punto de acceso», que abre la guía y se vuelve a Ajustes; con sus textos en español y en inglés.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_tag.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/widgets/hotspot_guide_step.dart';
import 'package:frecu/features/permissions/domain/entities/app_permission.dart';
import 'package:frecu/features/permissions/domain/repositories/permission_repository.dart';
import 'package:frecu/features/permissions/presentation/providers/permission_provider.dart';
import 'package:frecu/features/settings/presentation/pages/settings_page.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/features/settings/presentation/widgets/language_sheet.dart';
import 'package:frecu/features/settings/presentation/widgets/permissions_row.dart';
import 'package:frecu/features/settings/presentation/widgets/settings_group.dart';
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
  }) : current = {...?current},
       answers = {...?answers};

  final Map<AppPermission, AppPermissionStatus> current;
  final Map<AppPermission, AppPermissionStatus> answers;

  final List<AppPermission> requested = [];
  int settingsOpened = 0;

  @override
  Future<Result<AppPermissionStatus>> checkStatus(
    AppPermission permission,
  ) async => Result.success(current[permission] ?? AppPermissionStatus.denied);

  @override
  Future<Result<AppPermissionStatus>> request(AppPermission permission) async {
    requested.add(permission);
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

/// Todos los permisos de la bienvenida concedidos.
const _allGranted = {
  _microphone: AppPermissionStatus.granted,
  _nearby: AppPermissionStatus.granted,
  _notification: AppPermissionStatus.granted,
};

/// Abre la app con [permissions] en un teléfono de 390 × 844 con movimiento
/// reducido (la firma no anima sin fin) y entra a Ajustes.
Future<void> _openSettings(
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

  final container = ProviderContainer(
    overrides: [permissionRepositoryProvider.overrideWithValue(permissions)],
  );
  addTearDown(container.dispose);
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

  unawaited(router.push(const SettingsRoute()));
  await tester.pumpAndSettle();
}

/// Envía a la app el estado [state] como lo haría el sistema.
Future<void> _lifecycle(WidgetTester tester, AppLifecycleState state) =>
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.lifecycle.name,
      SystemChannels.lifecycle.codec.encodeMessage(state.toString()),
      (_) {},
    );

/// Vuelve a la app, p. ej. desde sus ajustes en el teléfono.
Future<void> _resume(WidgetTester tester) async {
  await _lifecycle(tester, AppLifecycleState.inactive);
  await _lifecycle(tester, AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

Finder get _permissionsRow => find.byType(PermissionsRow);

Finder get _guideRow => find.byWidgetPredicate(
  (widget) => widget is SettingsRow && widget.title == t.settings.hotspotGuide,
);

/// Etiqueta de la fila «Permisos».
FrTag _tag(WidgetTester tester) => tester.widget(
  find.descendant(of: _permissionsRow, matching: find.byType(FrTag)),
);

Finder _chevronIn(Finder row) => find.descendant(
  of: row,
  matching: find.byWidgetPredicate(
    (widget) => widget is FrIcon && widget.icon == FrIcons.chevron,
  ),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('Fila Permisos', () {
    testWidgets('va después de Idioma y antes de la guía, con lo que pide la '
        'bienvenida, cuántos están concedidos y un chevron', (tester) async {
      await _openSettings(
        tester,
        _FakePermissions(current: {_microphone: AppPermissionStatus.granted}),
      );

      final language = tester.getTopLeft(find.byType(LanguageRow)).dy;
      final permissions = tester.getTopLeft(_permissionsRow).dy;
      final guide = tester.getTopLeft(_guideRow).dy;
      final appearance = tester
          .getTopLeft(find.text(t.settings.appearance.toUpperCase()))
          .dy;
      expect(language, lessThan(permissions));
      expect(permissions, lessThan(guide));
      expect(guide, lessThan(appearance));

      expect(
        find.descendant(of: _permissionsRow, matching: find.text('Permisos')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _permissionsRow,
          matching: find.text('Micrófono, red local, notificaciones'),
        ),
        findsOneWidget,
      );
      expect(_tag(tester).label, '1/3');
      expect(_tag(tester).tone, FrTagTone.neutral);
      expect(_chevronIn(_permissionsRow), findsOneWidget);
    });

    testWidgets('con todos concedidos la etiqueta va en señal', (tester) async {
      await _openSettings(tester, _FakePermissions(current: _allGranted));

      expect(_tag(tester).label, '3/3');
      expect(_tag(tester).tone, FrTagTone.signal);
    });

    testWidgets('al tocarla pide los que faltan y la etiqueta se actualiza', (
      tester,
    ) async {
      final permissions = _FakePermissions(
        current: {_microphone: AppPermissionStatus.granted},
      );
      await _openSettings(tester, permissions);

      await tester.tap(_permissionsRow);
      await tester.pumpAndSettle();

      expect(permissions.requested, [_nearby, _notification]);
      expect(permissions.settingsOpened, 0);
      expect(_tag(tester).label, '3/3');
      expect(_tag(tester).tone, FrTagTone.signal);
    });

    testWidgets('si alguno queda negado para siempre abre los ajustes de la '
        'app, y al volver se leen los permisos', (tester) async {
      final permissions = _FakePermissions(
        answers: {_nearby: AppPermissionStatus.permanentlyDenied},
      );
      await _openSettings(tester, permissions);
      expect(_tag(tester).label, '0/3');

      await tester.tap(_permissionsRow);
      await tester.pumpAndSettle();

      expect(permissions.requested, [_microphone, _nearby, _notification]);
      expect(permissions.settingsOpened, 1);
      expect(_tag(tester).label, '2/3');

      // La persona lo concede en los ajustes del teléfono y vuelve.
      permissions.current[_nearby] = AppPermissionStatus.granted;
      await _resume(tester);

      expect(_tag(tester).label, '3/3');
      expect(_tag(tester).tone, FrTagTone.signal);
    });

    testWidgets('si lo niega sin que sea para siempre no abre los ajustes', (
      tester,
    ) async {
      final permissions = _FakePermissions(
        answers: {_notification: AppPermissionStatus.denied},
      );
      await _openSettings(tester, permissions);

      await tester.tap(_permissionsRow);
      await tester.pumpAndSettle();

      expect(permissions.settingsOpened, 0);
      expect(_tag(tester).label, '2/3');
    });

    testWidgets('con todos concedidos abre los ajustes de la app sin pedir '
        'nada', (tester) async {
      final permissions = _FakePermissions(current: _allGranted);
      await _openSettings(tester, permissions);

      await tester.tap(_permissionsRow);
      await tester.pumpAndSettle();

      expect(permissions.requested, isEmpty);
      expect(permissions.settingsOpened, 1);
    });

    testWidgets('al volver a la app se leen los permisos', (tester) async {
      final permissions = _FakePermissions();
      await _openSettings(tester, permissions);
      expect(_tag(tester).label, '0/3');

      permissions.current.addAll(_allGranted);
      await _resume(tester);

      expect(_tag(tester).label, '3/3');
    });
  });

  group('Fila Guía del punto de acceso', () {
    testWidgets('abre la guía sola con un chevron, y Atrás vuelve a Ajustes', (
      tester,
    ) async {
      await _openSettings(tester, _FakePermissions(current: _allGranted));
      expect(
        find.descendant(
          of: _guideRow,
          matching: find.text('Guía del punto de acceso'),
        ),
        findsOneWidget,
      );
      expect(_chevronIn(_guideRow), findsOneWidget);

      await tester.tap(_guideRow);
      await tester.pumpAndSettle();

      expect(find.byType(HotspotGuideStep), findsOneWidget);
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.text(t.lobby.newRoom.guide.heading), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is FrIconButton &&
              widget.semanticLabel == t.lobby.newRoom.back,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HotspotGuideStep), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    for (final label in ['Ya está activo', 'Ya estamos en la misma Wi-Fi']) {
      testWidgets('«$label» también vuelve a Ajustes', (tester) async {
        await _openSettings(tester, _FakePermissions(current: _allGranted));
        await tester.tap(_guideRow);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is FrButton && widget.label == label,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HotspotGuideStep), findsNothing);
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    }
  });

  testWidgets('en inglés las dos filas salen de la traducción en', (
    tester,
  ) async {
    // El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    await _openSettings(
      tester,
      _FakePermissions(current: {_microphone: AppPermissionStatus.granted}),
    );

    expect(
      find.descendant(of: _permissionsRow, matching: find.text('Permissions')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _permissionsRow,
        matching: find.text('Microphone, local network, notifications'),
      ),
      findsOneWidget,
    );
    expect(_tag(tester).label, '1/3');
    expect(
      find.descendant(of: _guideRow, matching: find.text('Hotspot guide')),
      findsOneWidget,
    );

    await tester.tap(_guideRow);
    await tester.pumpAndSettle();
    expect(find.text('Turn on your hotspot'), findsOneWidget);
  });
}
