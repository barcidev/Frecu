// AC1: CUANDO se abre la ruta de permisos ENTONCES el recorrido empieza en la bienvenida, en Portadora (`FrScaffold`): los pasos con el primero encendido y «01 / 03», la malla de 6 lugares, el aviso «Sin internet · sin cobertura», el título «Todo tu grupo en la misma frecu.», el texto y el botón Empezar; todos los textos del recorrido salen de slang en español y en inglés.
// AC2: CUANDO se dibuja la malla de la bienvenida ENTONCES sus 6 lugares, cada uno con la firma de su nombre, giran despacio sobre una elipse unidos por enlaces como en `drawOrbit` del prototipo, y cada 2,6 s habla el siguiente: su firma ondula con la voz simulada y salen paquetes hacia los demás.
// AC10: CUANDO el sistema pide reducir el movimiento ENTONCES la malla de la bienvenida y la firma del nombre quedan en un cuadro fijo y visibles, los pasos cambian con un fundido y la marca de concedido aparece sin resorte, sin ocultar ningún estado.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/bootstrap.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/fr_steps.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/permissions/presentation/widgets/welcome_mesh.dart';
import 'package:frecu/features/permissions/presentation/widgets/welcome_step.dart';
import 'package:frecu/i18n/strings.g.dart';

const Size _meshSize = Size(390, 380);

/// Centro esperado del lugar [index] en [seconds], como `drawOrbit`: ángulo
/// −π/2 + i·2π/6 + 0,06·t, radio 118 + 10·sin(0,5·t + i) (encogido bajo
/// 390 px de ancho), centro (ancho/2, alto/2 + 6) y eje vertical × 0,86.
Offset _expectedCenter(int index, double seconds, Size size) {
  final scale = math.min<double>(1, size.width / 390);
  final angle = -math.pi / 2 + index / 6 * 2 * math.pi + seconds * 0.06;
  final radius = (118 + 10 * math.sin(seconds * 0.5 + index)) * scale;
  return Offset(
    size.width / 2 + math.cos(angle) * radius,
    size.height / 2 + 6 + math.sin(angle) * radius * 0.86,
  );
}

/// Pide (o no) reducir el movimiento durante la prueba.
void _reduceMotion(WidgetTester tester, {required bool reduce}) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduce);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Dibuja solo la malla, en un cuadro de 390 × 380 centrado.
Future<void> _pumpMesh(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Center(
        child: SizedBox.fromSize(size: _meshSize, child: const WelcomeMesh()),
      ),
    ),
  );
  await tester.pump();
}

Finder _signature(int index) => find
    .descendant(
      of: find.byType(WelcomeMesh),
      matching: find.byType(SignalSignature),
    )
    .at(index);

/// Centro de cada firma de la malla, relativo a la esquina de la malla.
List<Offset> _signatureCenters(WidgetTester tester) {
  final origin = tester.getTopLeft(find.byType(WelcomeMesh));
  return [
    for (var i = 0; i < WelcomeMesh.names.length; i++)
      tester.getCenter(_signature(i)) - origin,
  ];
}

/// Abre la app como `bootstrap` en un teléfono de 390 × 844 con movimiento
/// reducido y entra a la ruta de permisos.
Future<void> _openOnboarding(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  _reduceMotion(tester, reduce: true);

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
}

Finder get _welcome => find.byType(WelcomeStep);

Finder _inWelcome(Finder matching) =>
    find.descendant(of: _welcome, matching: matching);

Finder _button(String label) => _inWelcome(
  find.byWidgetPredicate(
    (widget) => widget is FrButton && widget.label == label,
  ),
);

void main() {
  group('Malla de la bienvenida', () {
    test('AC2: cada lugar gira sobre la elipse del prototipo', () {
      for (final seconds in <double>[0, 1.7, 9.3, 41]) {
        for (var i = 0; i < 6; i++) {
          final center = WelcomeMesh.nodeCenter(i, seconds, _meshSize);
          final expected = _expectedCenter(i, seconds, _meshSize);
          expect(center.dx, closeTo(expected.dx, 1e-9));
          expect(center.dy, closeTo(expected.dy, 1e-9));
        }
      }
      const narrow = Size(312, 380);
      final center = WelcomeMesh.nodeCenter(2, 3, narrow);
      final expected = _expectedCenter(2, 3, narrow);
      expect(center.dx, closeTo(expected.dx, 1e-9));
      expect(center.dy, closeTo(expected.dy, 1e-9));
    });

    test('AC2: cada 2,6 s habla el siguiente lugar con la voz simulada', () {
      expect(WelcomeMesh.speakerAt(1.3), 0);
      expect(WelcomeMesh.speakerAt(3.9), 1);
      expect(WelcomeMesh.speakerAt(14.3), 5);
      expect(WelcomeMesh.speakerAt(16.9), 0);

      expect(WelcomeMesh.levelAt(1, 3.9), frVoice(3.9, 1));
      expect(WelcomeMesh.levelAt(0, 3.9), 0);
      expect(WelcomeMesh.levelAt(5, 3.9), 0);
    });

    testWidgets('AC2: la malla dibuja la firma de cada nombre en su lugar', (
      tester,
    ) async {
      _reduceMotion(tester, reduce: true);

      await _pumpMesh(tester);

      final signatures = tester
          .widgetList<SignalSignature>(
            find.descendant(
              of: find.byType(WelcomeMesh),
              matching: find.byType(SignalSignature),
            ),
          )
          .toList();
      expect(signatures.map((signature) => signature.name), [
        'Jorge',
        'Ana',
        'Leo',
        'Sofi',
        'Andrés',
        'Marta',
      ]);
      final centers = _signatureCenters(tester);
      for (var i = 0; i < 6; i++) {
        final expected = _expectedCenter(i, 0, _meshSize);
        expect(centers[i].dx, closeTo(expected.dx, 0.01));
        expect(centers[i].dy, closeTo(expected.dy, 0.01));
      }
      // En el instante 0 habla el primero, con la voz simulada.
      expect(signatures[0].levelOf!(0), frVoice(0));
      expect(signatures[1].levelOf!(0), 0);
    });

    testWidgets(
      'AC2: sin movimiento reducido los lugares giran con el tiempo',
      (tester) async {
        _reduceMotion(tester, reduce: false);

        await _pumpMesh(tester);
        final before = _signatureCenters(tester);
        await tester.pump(const Duration(seconds: 2));
        final after = _signatureCenters(tester);

        for (var i = 0; i < 6; i++) {
          expect((after[i] - before[i]).distance, greaterThan(1));
        }
      },
    );

    testWidgets('AC10: con movimiento reducido la malla queda en un cuadro '
        'fijo y visible', (tester) async {
      _reduceMotion(tester, reduce: true);

      await _pumpMesh(tester);
      final before = _signatureCenters(tester);
      await tester.pump(const Duration(seconds: 3));

      expect(
        find.descendant(
          of: find.byType(WelcomeMesh),
          matching: find.byType(SignalSignature),
        ),
        findsNWidgets(6),
      );
      expect(_signatureCenters(tester), before);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('Bienvenida', () {
    testWidgets('AC1: la ruta de permisos empieza en la bienvenida', (
      tester,
    ) async {
      await _openOnboarding(tester);

      expect(_welcome, findsOneWidget);
      expect(_inWelcome(find.byType(FrScaffold)), findsOneWidget);
      final steps = tester.widget<FrSteps>(_inWelcome(find.byType(FrSteps)));
      expect(steps.count, 3);
      expect(steps.current, 0);
      expect(_inWelcome(find.text('01 / 03')), findsOneWidget);
      expect(_inWelcome(find.byType(WelcomeMesh)), findsOneWidget);
      expect(
        _inWelcome(find.text('SIN INTERNET · SIN COBERTURA')),
        findsOneWidget,
      );
      expect(
        _inWelcome(find.text('Todo tu grupo en la misma frecu.')),
        findsOneWidget,
      );
      expect(
        _inWelcome(
          find.text(
            'Habla en tiempo real con hasta 6 personas cerca de ti. '
            'Solo necesitan compartir una red Wi-Fi.',
          ),
        ),
        findsOneWidget,
      );
      expect(_button('Empezar'), findsOneWidget);
    });

    testWidgets('AC1: en inglés los textos salen de la traducción en', (
      tester,
    ) async {
      // El inglés se carga diferido: hay que esperarlo fuera del reloj falso.
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));

      await _openOnboarding(tester);

      expect(
        _inWelcome(find.text('NO INTERNET · NO COVERAGE')),
        findsOneWidget,
      );
      expect(
        _inWelcome(find.text('Your whole group on the same frecu.')),
        findsOneWidget,
      );
      expect(_button('Get started'), findsOneWidget);
    });

    testWidgets('AC10: con movimiento reducido la bienvenida queda quieta y '
        'completa', (tester) async {
      await _openOnboarding(tester);

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(
        find.descendant(
          of: _inWelcome(find.byType(WelcomeMesh)),
          matching: find.byType(SignalSignature),
        ),
        findsNWidgets(6),
      );
      expect(_button('Empezar'), findsOneWidget);
    });
  });
}
