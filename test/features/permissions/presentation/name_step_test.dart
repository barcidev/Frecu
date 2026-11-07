// AC3: CUANDO el usuario toca Empezar ENTONCES pasa al paso del nombre (segundo paso encendido, «02 / 03») con el título «¿Cómo te llamamos?», el texto, la firma de señal en su escenario con la leyenda, el campo «Nombre visible» con su ayuda (y el nombre guardado si ya había uno) y Continuar; Atrás o el gesto de volver del sistema regresan al paso anterior sin perder lo escrito.
// AC4: CUANDO el usuario escribe su nombre ENTONCES la firma del escenario sigue al texto en vivo y habla con la voz simulada (`frVoice(t) * 0.55`).
// AC5: CUANDO el usuario toca Continuar o confirma desde el teclado con un nombre válido ENTONCES el nombre se guarda sin espacios alrededor con `preferencesProvider`, se conserva al reabrir la app y el recorrido pasa a los permisos.
// AC6: CUANDO el nombre queda vacío o solo con espacios, o pasa de 20 caracteres contados como el dominio (`runes`) ENTONCES Continuar queda deshabilitado, confirmar desde el teclado no avanza y, si pasa del largo, el campo muestra el error del largo; el campo limita el texto a `Preferences.displayNameMaxLength`; CUANDO el guardado falla ENTONCES el recorrido sigue en el nombre con el error en el campo.
// AC10: CUANDO el sistema pide reducir el movimiento ENTONCES la malla de la bienvenida y la firma del nombre quedan en un cuadro fijo y visibles, los pasos cambian con un fundido y la marca de concedido aparece sin resorte, sin ocultar ningún estado.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/core/design/widgets/fr_steps.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/permissions/presentation/widgets/name_step.dart';
import 'package:frecu/features/permissions/presentation/widgets/welcome_step.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Almacenamiento vacío que lee bien pero falla al guardar.
final class _FailingWrites extends InMemorySharedPreferencesAsync {
  _FailingWrites() : super.empty();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async => throw StateError('No se pudo guardar $key');
}

/// Deja guardado [name] antes de abrir la app; nulo si no hay nombre.
void _saveName(String? name) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        if (name != null) PreferencesRepositoryImpl.displayNameKey: name,
      });
}

/// Abre la app como `bootstrap` en un teléfono de 390 × 844 con movimiento
/// reducido, entra a la ruta de permisos y devuelve el router.
Future<AppRouter> _openOnboarding(WidgetTester tester) async {
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

  unawaited(router.push(const PermissionsRoute()));
  await tester.pumpAndSettle();
  return router;
}

/// Nombre que lee la app al reabrirse sobre el mismo almacenamiento.
Future<String?> _reopenedName() async {
  final container = await createAppContainer();
  addTearDown(container.dispose);
  return container.read(preferencesProvider).value?.displayName;
}

Finder get _welcome => find.byType(WelcomeStep);

Finder get _step => find.byType(NameStep);

Finder _inStep(Finder matching) =>
    find.descendant(of: _step, matching: matching);

Finder _buttonIn(Finder of, String label) => find.descendant(
  of: of,
  matching: find.byWidgetPredicate(
    (widget) => widget is FrButton && widget.label == label,
  ),
);

Finder get _continue => _buttonIn(_step, 'Continuar');

Finder get _back => _inStep(
  find.byWidgetPredicate(
    (widget) => widget is FrIconButton && widget.semanticLabel == 'Atrás',
  ),
);

Finder get _input => _inStep(find.byType(TextField));

FrField _field(WidgetTester tester) =>
    tester.widget(_inStep(find.byType(FrField)));

SignalSignature _signature(WidgetTester tester) =>
    tester.widget(_inStep(find.byType(SignalSignature)));

String _text(WidgetTester tester) =>
    tester.widget<TextField>(_input).controller!.text;

bool _canContinue(WidgetTester tester) =>
    tester.widget<FrButton>(_continue).onPressed != null;

/// Toca Empezar en la bienvenida y espera el paso del nombre.
Future<void> _start(WidgetTester tester) async {
  await tester.tap(_buttonIn(_welcome, 'Empezar'));
  await tester.pumpAndSettle();
  expect(_step, findsOneWidget);
}

void main() {
  group('Paso del nombre', () {
    testWidgets('AC3: Empezar lleva al nombre con la firma, el campo y '
        'Continuar', (tester) async {
      _saveName(null);
      await _openOnboarding(tester);

      await _start(tester);

      final steps = tester.widget<FrSteps>(_inStep(find.byType(FrSteps)));
      expect(steps.count, 3);
      expect(steps.current, 1);
      expect(_inStep(find.text('02 / 03')), findsOneWidget);
      expect(_inStep(find.text('¿Cómo te llamamos?')), findsOneWidget);
      expect(
        _inStep(find.text('Así te verán y escucharán en cada frecu.')),
        findsOneWidget,
      );
      expect(
        _inStep(find.text('TU FIRMA DE SEÑAL · NACE DE TU NOMBRE')),
        findsOneWidget,
      );
      final field = _field(tester);
      expect(field.label, 'Nombre visible');
      expect(field.help, 'Puedes cambiarlo cuando quieras en Ajustes.');
      expect(_text(tester), isEmpty);
      expect(_back, findsOneWidget);
      expect(_continue, findsOneWidget);
    });

    testWidgets('AC3: con un nombre guardado el campo empieza con él', (
      tester,
    ) async {
      _saveName('Ana');
      await _openOnboarding(tester);

      await _start(tester);

      expect(_text(tester), 'Ana');
      expect(_signature(tester).name, 'Ana');
      expect(_canContinue(tester), isTrue);
    });

    testWidgets('AC3: Atrás y el gesto de volver regresan a la bienvenida '
        'sin perder lo escrito', (tester) async {
      _saveName(null);
      final router = await _openOnboarding(tester);
      await _start(tester);
      await tester.enterText(_input, 'Leo');
      await tester.pump();

      await tester.tap(_back);
      await tester.pumpAndSettle();
      expect(_step, findsNothing);
      expect(_welcome, findsOneWidget);

      await _start(tester);
      expect(_text(tester), 'Leo');
      expect(_signature(tester).name, 'Leo');

      // El gesto de volver del sistema regresa un paso sin salir de la ruta.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_step, findsNothing);
      expect(_welcome, findsOneWidget);
      expect(router.current.name, PermissionsRoute.name);

      await _start(tester);
      expect(_text(tester), 'Leo');
    });

    testWidgets('AC4: la firma sigue al texto en vivo y habla con la voz '
        'simulada', (tester) async {
      _saveName(null);
      await _openOnboarding(tester);
      await _start(tester);

      await tester.enterText(_input, 'A');
      await tester.pump();
      expect(_signature(tester).name, 'A');

      await tester.enterText(_input, 'Ana');
      await tester.pump();
      final signature = _signature(tester);
      expect(signature.name, 'Ana');
      expect(signature.mode, SignatureMode.speak);
      expect(signature.size, 210);
      for (final seconds in <double>[0.4, 1.3, 7.25]) {
        expect(signature.levelOf!(seconds), frVoice(seconds) * 0.55);
      }
    });

    testWidgets('AC5: Continuar guarda el nombre sin espacios alrededor y se '
        'conserva al reabrir', (tester) async {
      _saveName(null);
      await _openOnboarding(tester);
      await _start(tester);

      await tester.enterText(_input, '  Ana  ');
      await tester.pump();
      expect(_canContinue(tester), isTrue);
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      expect(await _reopenedName(), 'Ana');
    });

    testWidgets('AC5: confirmar desde el teclado también guarda el nombre', (
      tester,
    ) async {
      _saveName(null);
      await _openOnboarding(tester);
      await _start(tester);

      await tester.enterText(_input, 'Leo');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(await _reopenedName(), 'Leo');
    });

    testWidgets('AC6: vacío o solo con espacios no se puede continuar', (
      tester,
    ) async {
      _saveName(null);
      await _openOnboarding(tester);
      await _start(tester);

      expect(_canContinue(tester), isFalse);

      await tester.enterText(_input, '   ');
      await tester.pump();
      expect(_canContinue(tester), isFalse);
      expect(_field(tester).error, isNull);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_step, findsOneWidget);
      expect(await _reopenedName(), isNull);
    });

    testWidgets('AC6: el campo limita el largo y un nombre de más de 20 '
        'caracteres del dominio muestra el error', (tester) async {
      _saveName(null);
      await _openOnboarding(tester);
      await _start(tester);

      expect(_field(tester).maxLength, Preferences.displayNameMaxLength);
      await tester.enterText(_input, 'a' * 25);
      await tester.pump();
      expect(_text(tester), 'a' * 20);
      expect(_canContinue(tester), isTrue);

      // 5 grafemas que el campo deja pasar, pero 25 runes para el dominio.
      await tester.enterText(_input, '👨‍👩‍👧' * 5);
      await tester.pump();
      expect(_canContinue(tester), isFalse);
      expect(_field(tester).error, 'Usa como máximo 20 caracteres.');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_step, findsOneWidget);
      expect(await _reopenedName(), isNull);
    });

    testWidgets('AC6: si el guardado falla sigue en el nombre con el error', (
      tester,
    ) async {
      SharedPreferencesAsyncPlatform.instance = _FailingWrites();
      await _openOnboarding(tester);
      await _start(tester);

      await tester.enterText(_input, 'Ana');
      await tester.pump();
      await tester.tap(_continue);
      await tester.pumpAndSettle();

      expect(_step, findsOneWidget);
      expect(
        _field(tester).error,
        'No se pudo guardar tu nombre. Inténtalo de nuevo.',
      );
      expect(_text(tester), 'Ana');
      expect(await _reopenedName(), isNull);
    });

    testWidgets('AC1: en inglés el paso del nombre sale de la traducción en', (
      tester,
    ) async {
      // El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
      _saveName(null);
      await _openOnboarding(tester);

      await tester.tap(_buttonIn(_welcome, 'Get started'));
      await tester.pumpAndSettle();

      expect(_inStep(find.text('What should we call you?')), findsOneWidget);
      expect(_field(tester).label, 'Display name');
      expect(_buttonIn(_step, 'Continue'), findsOneWidget);
    });

    testWidgets('AC10: con movimiento reducido el paso entra con un fundido y '
        'la firma queda en un cuadro fijo', (tester) async {
      _saveName('Ana');
      await _openOnboarding(tester);

      await tester.tap(_buttonIn(_welcome, 'Empezar'));
      await tester.pump();
      await tester.pump(FrTransitions.reducedDuration ~/ 2);
      final fade = tester.widget<FadeTransition>(
        find.ancestor(of: _step, matching: find.byType(FadeTransition)).first,
      );
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));

      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_inStep(find.byType(SignalSignature)), findsOneWidget);
      expect(_signature(tester).name, 'Ana');
    });
  });
}
