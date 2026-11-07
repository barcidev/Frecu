// AC5: CUANDO se abre Ajustes ENTONCES la tarjeta muestra el nombre guardado con su firma de señal, o «Sin nombre» si aún no hay, y el botón Editar.
// AC6: CUANDO el usuario toca Editar, escribe un nombre válido y toca Guardar o confirma desde el teclado ENTONCES la hoja se cierra y la tarjeta muestra el nombre sin espacios alrededor con su firma, que se conserva al reabrir la app; mientras escribe, la firma de la hoja sigue al texto.
// AC7: CUANDO el nombre queda vacío o solo con espacios, o pasa de 20 caracteres contados como el dominio (`runes`) ENTONCES Guardar queda deshabilitado, confirmar desde el teclado no guarda y, si pasa del largo, el campo muestra el error del largo; el campo limita el texto a `Preferences.displayNameMaxLength`; CUANDO el guardado falla ENTONCES la hoja sigue abierta con el error y el nombre guardado no cambia.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/settings/data/repositories/preferences_repository_impl.dart';
import 'package:frecu/features/settings/domain/entities/preferences.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/features/settings/presentation/widgets/edit_name_sheet.dart';
import 'package:frecu/features/settings/presentation/widgets/profile_card.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Almacenamiento con los datos dados que lee bien pero falla al guardar.
final class _FailingWrites extends InMemorySharedPreferencesAsync {
  _FailingWrites(super.data) : super.withData();

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
/// reducido (la firma no anima sin fin), entra a Ajustes y devuelve el
/// contenedor de la app.
Future<ProviderContainer> _openSettings(WidgetTester tester) async {
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
  return container;
}

/// Nombre que lee la app al reabrirse sobre el mismo almacenamiento.
Future<String?> _reopenedName() async {
  final container = await createAppContainer();
  addTearDown(container.dispose);
  return container.read(preferencesProvider).value?.displayName;
}

Finder get _card => find.byType(ProfileCard);

Finder get _sheet => find.byType(EditNameSheet);

/// Botón de Portadora con [label] dentro de [of].
Finder _button(Finder of, String label) => find.descendant(
  of: of,
  matching: find.byWidgetPredicate(
    (widget) => widget is FrButton && widget.label == label,
  ),
);

Finder get _editButton => _button(_card, t.settings.edit);

Finder get _saveButton => _button(_sheet, t.settings.editName.save);

Finder get _nameInput =>
    find.descendant(of: _sheet, matching: find.byType(TextField));

FrField _nameField(WidgetTester tester) =>
    tester.widget(find.descendant(of: _sheet, matching: find.byType(FrField)));

SignalSignature _signatureIn(WidgetTester tester, Finder of) => tester.widget(
  find.descendant(of: of, matching: find.byType(SignalSignature)),
);

bool _canSave(WidgetTester tester) =>
    tester.widget<FrButton>(_saveButton).onPressed != null;

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(_editButton);
  await tester.pumpAndSettle();
  expect(_sheet, findsOneWidget);
}

void main() {
  group('Nombre en Ajustes', () {
    testWidgets('AC5: la tarjeta muestra el nombre guardado con su firma y '
        'el botón Editar', (tester) async {
      _saveName('Ana');

      await _openSettings(tester);

      expect(_card, findsOneWidget);
      expect(
        find.descendant(
          of: _card,
          matching: find.text(t.settings.displayName.toUpperCase()),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _card, matching: find.text('Ana')),
        findsOneWidget,
      );
      expect(_signatureIn(tester, _card).name, 'Ana');
      expect(_editButton, findsOneWidget);
    });

    testWidgets('AC5: sin nombre guardado muestra «Sin nombre»', (
      tester,
    ) async {
      _saveName(null);

      await _openSettings(tester);

      expect(
        find.descendant(of: _card, matching: find.text(t.settings.noName)),
        findsOneWidget,
      );
      expect(_signatureIn(tester, _card).name, isEmpty);
      expect(_editButton, findsOneWidget);
    });

    testWidgets('AC6: Guardar cierra la hoja, la tarjeta muestra el nombre '
        'recortado con su firma y se conserva al reabrir', (tester) async {
      _saveName('Ana');
      await _openSettings(tester);

      await _openSheet(tester);
      expect(tester.widget<TextField>(_nameInput).controller?.text, 'Ana');
      expect(_signatureIn(tester, _sheet).name.trim(), 'Ana');

      await tester.enterText(_nameInput, '  Bea Luz  ');
      await tester.pump();
      expect(_signatureIn(tester, _sheet).name.trim(), 'Bea Luz');
      expect(_canSave(tester), isTrue);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      expect(
        find.descendant(of: _card, matching: find.text('Bea Luz')),
        findsOneWidget,
      );
      expect(_signatureIn(tester, _card).name, 'Bea Luz');
      expect(await _reopenedName(), 'Bea Luz');
    });

    testWidgets('AC6: confirmar desde el teclado también guarda', (
      tester,
    ) async {
      _saveName('Ana');
      await _openSettings(tester);

      await _openSheet(tester);
      await tester.enterText(_nameInput, 'Caro');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(_sheet, findsNothing);
      expect(
        find.descendant(of: _card, matching: find.text('Caro')),
        findsOneWidget,
      );
      expect(await _reopenedName(), 'Caro');
    });

    testWidgets('AC7: vacío o solo espacios deshabilita Guardar y el teclado '
        'no guarda', (tester) async {
      _saveName('Ana');
      final container = await _openSettings(tester);
      await _openSheet(tester);

      for (final text in ['', '   ']) {
        await tester.enterText(_nameInput, text);
        await tester.pump();
        expect(_canSave(tester), isFalse, reason: '«$text»');
        expect(_nameField(tester).error, isNull, reason: '«$text»');

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(_sheet, findsOneWidget, reason: '«$text»');
      }

      expect(container.read(preferencesProvider).value?.displayName, 'Ana');
      expect(await _reopenedName(), 'Ana');
    });

    testWidgets('AC7: más de 20 caracteres contados en runes deshabilita '
        'Guardar y muestra el error del largo', (tester) async {
      _saveName('Ana');
      await _openSettings(tester);
      await _openSheet(tester);

      // 11 grafemas que el campo deja pasar, pero 22 runes para el dominio.
      final composed = List.filled(11, '\u{1F44D}\u{1F3FD}').join();
      expect(composed.runes.length, 22);

      await tester.enterText(_nameInput, composed);
      await tester.pump();

      expect(tester.widget<TextField>(_nameInput).controller?.text, composed);
      expect(_canSave(tester), isFalse);
      expect(
        _nameField(tester).error,
        t.settings.editName.tooLong(max: Preferences.displayNameMaxLength),
      );

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_sheet, findsOneWidget);
      expect(await _reopenedName(), 'Ana');
    });

    testWidgets('AC7: el campo limita el texto a displayNameMaxLength', (
      tester,
    ) async {
      _saveName('Ana');
      await _openSettings(tester);
      await _openSheet(tester);

      expect(_nameField(tester).maxLength, Preferences.displayNameMaxLength);

      await tester.enterText(_nameInput, 'a' * 25);
      await tester.pump();

      final max = 'a' * Preferences.displayNameMaxLength;
      expect(tester.widget<TextField>(_nameInput).controller?.text, max);
      expect(_canSave(tester), isTrue);
      expect(_nameField(tester).error, isNull);
    });

    testWidgets('AC7: si el guardado falla la hoja sigue abierta con el error '
        'y el nombre no cambia', (tester) async {
      SharedPreferencesAsyncPlatform.instance = _FailingWrites({
        PreferencesRepositoryImpl.displayNameKey: 'Ana',
      });
      final container = await _openSettings(tester);
      await _openSheet(tester);

      await tester.enterText(_nameInput, 'Bea');
      await tester.pump();
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(_sheet, findsOneWidget);
      expect(_nameField(tester).error, t.settings.editName.saveError);
      expect(
        find.descendant(of: _card, matching: find.text('Ana')),
        findsOneWidget,
      );
      expect(container.read(preferencesProvider).value?.displayName, 'Ana');
    });
  });
}
