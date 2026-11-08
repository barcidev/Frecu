// AC2: CUANDO el usuario transmite (PTT o micrófono abierto) ENTONCES el bisel y el anillo del núcleo PTT siguen, con su resorte, el nivel real de su micrófono en la escala del VU; CUANDO recibe a alguien ENTONCES el anillo de recepción sigue el nivel real del audio de esa persona; CUANDO no suenan ENTONCES vuelven a reposo (al aire, al mínimo de al aire). El núcleo ya no usa `frVoice`.
// AC4: CUANDO el sistema pide reducir el movimiento ENTONCES el núcleo y la malla muestran el nivel real a saltos, sin resorte, ondas ni paquetes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core_painter.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Muestra el núcleo en [phase] con el nivel propio [level] y el de quien
/// habla [speakerLevel].
Future<void> _pumpCore(
  WidgetTester tester,
  PttPhase phase, {
  double level = 0,
  double speakerLevel = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: PttCore(
            phase: phase,
            level: level,
            speakerName: 'Ana',
            speakerColor: FrColors.dark.p2,
            speakerLevel: speakerLevel,
            onStart: () {},
            onStop: () {},
            onToggle: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

PttMotion _motion(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<PttCorePainter>()
    .single
    .motion;

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  group('Núcleo PTT con nivel real', () {
    testWidgets('AC2: al aire el bisel sigue con su resorte el nivel del '
        'micrófono, a 0,7 con micrófono abierto y al mínimo en silencio', (
      tester,
    ) async {
      await _pumpCore(tester, PttPhase.onAir, level: 0.9);
      await tester.pump(const Duration(milliseconds: 16));
      final first = _motion(tester).level;
      expect(first, greaterThan(0.12));
      expect(first, lessThan(0.9));

      await tester.pump(const Duration(seconds: 1));
      expect(_motion(tester).level, closeTo(0.9, 0.01));
      expect(
        pttLitTicks(_motion(tester).level, onAir: true),
        greaterThan(pttLitTicks(0.12, onAir: true)),
      );

      await _pumpCore(tester, PttPhase.open, level: 0.9);
      await tester.pump(const Duration(seconds: 2));
      expect(_motion(tester).level, closeTo(0.63, 0.01));

      await _pumpCore(tester, PttPhase.onAir);
      await tester.pump(const Duration(seconds: 2));
      expect(_motion(tester).level, closeTo(0.12, 0.01));
    });

    testWidgets('AC2: recibiendo, el anillo sigue el nivel de quien habla y '
        'en silencio vuelve a reposo', (tester) async {
      await _pumpCore(tester, PttPhase.receiving, speakerLevel: 0.7);
      await tester.pump(const Duration(milliseconds: 16));
      expect(_motion(tester).rxLevel, greaterThan(0));
      expect(_motion(tester).rxLevel, lessThan(0.7));

      await tester.pump(const Duration(seconds: 1));
      expect(_motion(tester).rxLevel, closeTo(0.7, 0.01));
      expect(_motion(tester).level, 0);

      await _pumpCore(tester, PttPhase.receiving);
      await tester.pump(const Duration(seconds: 2));
      expect(_motion(tester).rxLevel, lessThan(0.01));
    });

    testWidgets('AC2: sin voz el núcleo no se mueve, porque ya no sigue una '
        'onda simulada', (tester) async {
      await _pumpCore(tester, PttPhase.receiving);
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(_motion(tester).rxLevel, 0);
      }

      await _pumpCore(tester, PttPhase.onAir);
      await tester.pump(const Duration(seconds: 2));
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(_motion(tester).level, closeTo(0.12, 1e-3));
      }
    });

    testWidgets('AC4: con movimiento reducido el núcleo muestra el nivel real '
        'a saltos, sin resorte ni ondas', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await _pumpCore(tester, PttPhase.onAir, level: 0.8);
      expect(_motion(tester).level, 0.8);
      expect(_motion(tester).ripples, isEmpty);

      await _pumpCore(tester, PttPhase.onAir, level: 0.3);
      expect(_motion(tester).level, 0.3);

      await _pumpCore(tester, PttPhase.receiving, speakerLevel: 0.45);
      expect(_motion(tester).rxLevel, 0.45);
      expect(_motion(tester).level, 0);
      expect(_motion(tester).ripples, isEmpty);
    });
  });
}
