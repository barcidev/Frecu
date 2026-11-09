// AC1: CUANDO se abre Ajustes ENTONCES el botón Atrás dibuja `FrIcons.back`, el botón Editar de la tarjeta del nombre `FrIcons.edit` y los segmentos PTT y Abierto del modo de habla `FrIcons.walkie` y `FrIcons.openMic`, todos con `FrIcon`; CUANDO no se puede guardar una preferencia ENTONCES el aviso de error dibuja `FrIcons.alert`; y Ajustes no muestra ningún `Icon` de Material.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_segmented.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/settings/presentation/pages/settings_page.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Almacenamiento que lee bien pero falla al guardar.
final class _FailingWrites extends InMemorySharedPreferencesAsync {
  _FailingWrites() : super.empty();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async => throw StateError('No se pudo guardar $key');
}

/// Abre la app en un teléfono de 390 × 844 con movimiento reducido (la firma
/// no anima sin fin) y entra a Ajustes.
Future<void> _openSettings(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final container = await createAppContainer();
  addTearDown(container.dispose);
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

/// [FrIcon] de [icon] dentro de [of].
Finder _drawn(Finder of, FrIconData icon) => find.descendant(
  of: of,
  matching: find.byWidgetPredicate(
    (widget) => widget is FrIcon && widget.icon == icon,
  ),
);

/// Íconos de Material dentro de [of].
Finder _material(Finder of) =>
    find.descendant(of: of, matching: find.byType(Icon));

Finder get _page => find.byType(SettingsPage);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('Íconos de Ajustes', () {
    testWidgets('AC1: Atrás, Editar y los modos de habla dibujan FrIcons, sin '
        'Material', (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      await _openSettings(tester);

      final back = find.byWidgetPredicate(
        (widget) =>
            widget is FrIconButton && widget.semanticLabel == t.settings.back,
      );
      expect(back, findsOneWidget);
      expect(tester.widget<FrIconButton>(back).drawnIcon, FrIcons.back);
      expect(_drawn(back, FrIcons.back), findsOneWidget);

      final edit = find.byWidgetPredicate(
        (widget) => widget is FrButton && widget.label == t.settings.edit,
      );
      expect(edit, findsOneWidget);
      expect(tester.widget<FrButton>(edit).drawnIcon, FrIcons.edit);
      expect(_drawn(edit, FrIcons.edit), findsOneWidget);

      final talkMode = find.byType(FrSegmented<TalkMode>);
      expect(_drawn(talkMode, FrIcons.walkie), findsOneWidget);
      expect(_drawn(talkMode, FrIcons.openMic), findsOneWidget);

      expect(_material(_page), findsNothing);
    });

    testWidgets('AC1: el aviso de error dibuja FrIcons.alert, sin Material', (
      tester,
    ) async {
      SharedPreferencesAsyncPlatform.instance = _FailingWrites();
      await _openSettings(tester);

      // El tema queda bajo el borde: se lleva a la vista antes de tocarlo.
      await tester.ensureVisible(
        find.text(t.settings.themeMode.light.toUpperCase()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.themeMode.light.toUpperCase()));
      await tester.pumpAndSettle();

      final toast = find.byWidgetPredicate(
        (widget) => widget is FrToast && widget.message == t.settings.saveError,
      );
      expect(toast, findsOneWidget);
      expect(_drawn(toast, FrIcons.alert), findsOneWidget);
      expect(_material(toast), findsNothing);
      expect(_material(_page), findsNothing);

      // Deja pasar el aviso hasta que se va.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(toast, findsNothing);
    });
  });
}
