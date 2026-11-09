// AC1: CUANDO el usuario está en PTT ENTONCES ve el núcleo (zona de 248 con botón de 156) con «Mantén» y «Mantén para hablar»; con el dedo apoyado se llama `startTalking` una sola vez, el botón se achica a 0,94, se rellena de señal y muestra el tiempo al aire con «Al aire» y «Suelta para escuchar»; al levantar o cancelar el último dedo se llama `stopTalking`.
// AC2: CUANDO otra persona habla ENTONCES el bisel se enciende en su color, la pista la nombra y el núcleo sigue respondiendo; CUANDO el anfitrión está solo ENTONCES la pista invita a mostrar el QR.
// AC3: CUANDO el modo es micrófono abierto ENTONCES el núcleo es un conmutador («Silencio» o «Abierto») y con tema claro las letras sobre la señal van en `signalInk`.
// AC7: CUANDO la frecu conecta o reconecta ENTONCES el núcleo se ve al 35 %, dice «En espera» y no responde; si había un dedo apoyado se deja de transmitir.
// AC8: CUANDO el sistema pide reducir el movimiento ENTONCES el núcleo queda quieto, sin barrido, ondas ni escala.
// F4: CUANDO el núcleo se desmonta con el dedo apoyado ENTONCES deja de transmitir.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core_painter.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Llamadas del núcleo a sus callbacks.
class _Calls {
  int start = 0;
  int stop = 0;
  int toggle = 0;
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<_Calls> _pumpCore(
  WidgetTester tester,
  PttPhase phase, {
  _Calls? calls,
  ThemeData? theme,
  Duration onAirFor = Duration.zero,
  double level = 0,
  String? speakerName,
  Color? speakerColor,
  double speakerLevel = 0,
}) async {
  final record = calls ?? _Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: PttCore(
            phase: phase,
            onAirFor: onAirFor,
            level: level,
            speakerName: speakerName,
            speakerColor: speakerColor,
            speakerLevel: speakerLevel,
            onStart: () => record.start++,
            onStop: () => record.stop++,
            onToggle: () => record.toggle++,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return record;
}

String _label(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('ptt_core_label'))).data!;

String _hint(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('ptt_core_hint'))).data!;

Finder _icon(FrIconData icon) => find.descendant(
  of: find.byType(PttCore),
  matching: find.byWidgetPredicate((w) => w is FrIcon && w.icon == icon),
);

PttCorePainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<PttCorePainter>()
    .single;

double _scale(WidgetTester tester) => tester
    .widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PttCore),
        matching: find.byType(AnimatedScale),
      ),
    )
    .scale;

double _opacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(PttCore),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.es));

  group('PttCore', () {
    testWidgets('AC1: en reposo muestra el micrófono, «Mantén» y «Mantén '
        'para hablar» en una zona de 248 con un botón de 156', (tester) async {
      _reduceMotion(tester);
      await _pumpCore(tester, PttPhase.idle);

      expect(_label(tester), 'MANTÉN');
      expect(_hint(tester), 'MANTÉN PARA HABLAR');
      expect(_icon(FrIcons.mic), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('ptt_button'))),
        const Size(156, 156),
      );
      final zone = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PttCorePainter,
      );
      expect(tester.getSize(zone), const Size(248, 248));
      expect(find.byKey(const Key('mic_toggle_button')), findsNothing);
    });

    testWidgets('AC1: el primer dedo empieza a transmitir y el último en '
        'salir termina, una sola vez', (tester) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(tester, PttPhase.idle);
      final center = tester.getCenter(find.byKey(const Key('ptt_button')));

      final first = await tester.startGesture(center, pointer: 1);
      await tester.pump();
      final second = await tester.startGesture(
        center + const Offset(20, 20),
        pointer: 2,
      );
      await tester.pump();
      expect(calls.start, 1);

      await first.up();
      await tester.pump();
      expect(calls.stop, 0);

      await second.up();
      await tester.pump();
      expect(calls.start, 1);
      expect(calls.stop, 1);
    });

    testWidgets('AC1: al cancelar el dedo se deja de transmitir', (
      tester,
    ) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(tester, PttPhase.idle);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ptt_button'))),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      expect(calls.start, 1);
      expect(calls.stop, 1);
      expect(_label(tester), 'MANTÉN');
    });

    testWidgets('AC1: con el dedo apoyado se ve al aire con el tiempo', (
      tester,
    ) async {
      _reduceMotion(tester);
      await _pumpCore(tester, PttPhase.idle);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ptt_button'))),
      );
      await tester.pump();

      expect(_label(tester), 'AL AIRE');
      expect(_hint(tester), 'SUELTA PARA ESCUCHAR');
      expect(find.text('00:00'), findsOneWidget);
      expect(_icon(FrIcons.mic), findsNothing);
      expect(_painter(tester).look.onAir, isTrue);

      await gesture.up();
      await tester.pump();
      expect(_painter(tester).look.onAir, isFalse);
    });

    testWidgets('AC1: al aire muestra el tiempo que le llega', (tester) async {
      _reduceMotion(tester);
      await _pumpCore(
        tester,
        PttPhase.onAir,
        onAirFor: const Duration(minutes: 1, seconds: 4),
      );

      expect(
        tester.widget<Text>(find.byKey(const Key('ptt_core_timer'))).data,
        '01:04',
      );
      expect(_label(tester), 'AL AIRE');
    });

    testWidgets('AC1: sin movimiento reducido el botón se achica a 0,94 al '
        'apoyar el dedo y el bisel anima', (tester) async {
      await _pumpCore(tester, PttPhase.idle);
      expect(
        find.descendant(
          of: find.byType(PttCore),
          matching: find.byType(FrLoop),
        ),
        findsOneWidget,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ptt_button'))),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(_scale(tester), 0.94);
      expect(_painter(tester).motion.level, greaterThan(0));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 600));
      expect(_scale(tester), 1);
    });

    testWidgets('AC8: con movimiento reducido el núcleo no anima ni se '
        'achica', (tester) async {
      _reduceMotion(tester);
      await _pumpCore(tester, PttPhase.idle, level: 0.6);
      expect(
        find.descendant(
          of: find.byType(PttCore),
          matching: find.byType(FrLoop),
        ),
        findsNothing,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ptt_button'))),
      );
      await tester.pumpAndSettle();

      expect(_scale(tester), 1);
      expect(_painter(tester).motion.level, 0.6);
      expect(_painter(tester).motion.ripples, isEmpty);
      expect(_label(tester), 'AL AIRE');
      await gesture.up();
    });

    testWidgets('AC2: recibiendo, la pista nombra a quien habla, el bisel '
        'toma su color y el núcleo responde a la presión', (tester) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(
        tester,
        PttPhase.receiving,
        speakerName: 'Ana',
        speakerColor: FrColors.dark.p2,
        speakerLevel: 0.6,
      );

      expect(_label(tester), 'MANTÉN');
      expect(_hint(tester), 'ANA ESTÁ HABLANDO · PUEDES RESPONDER');
      expect(_painter(tester).look.rxColor, FrColors.dark.p2);
      expect(_painter(tester).motion.rxLevel, 0.6);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ptt_button'))),
      );
      await tester.pump();
      expect(calls.start, 1);
      expect(_painter(tester).look.rxColor, isNull);
      await gesture.up();
    });

    testWidgets('AC2: el anfitrión solo ve que puede mostrar el QR', (
      tester,
    ) async {
      _reduceMotion(tester);
      await _pumpCore(tester, PttPhase.alone);

      expect(_label(tester), 'MANTÉN');
      expect(_hint(tester), 'MUESTRA EL QR PARA QUE TU GRUPO SE UNA');
    });

    test('AC1: el bisel enciende sus 72 marcas con el nivel de voz', () {
      expect(pttTickCount, 72);
      expect(pttLitTicks(0, onAir: true), 6);
      expect(pttLitTicks(1, onAir: true), 72);
      expect(pttLitTicks(0.5, onAir: false), 32);
      expect(pttLitTicks(0, onAir: false), 0);
    });

    testWidgets('AC3: con micrófono abierto en silencio un toque lo abre', (
      tester,
    ) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(tester, PttPhase.muted);

      expect(_label(tester), 'SILENCIO');
      expect(_hint(tester), 'TOCA PARA ACTIVAR TU MICRÓFONO');
      expect(_icon(FrIcons.micOff), findsOneWidget);
      expect(find.byKey(const Key('ptt_button')), findsNothing);

      await tester.tap(find.byKey(const Key('mic_toggle_button')));
      await tester.pump();
      expect(calls.toggle, 1);
      expect(calls.start, 0);
    });

    testWidgets('AC3: con micrófono abierto transmitiendo un toque lo calla '
        'y de día sus letras van en signalInk', (tester) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(
        tester,
        PttPhase.open,
        theme: AppTheme.light,
      );

      expect(_label(tester), 'ABIERTO');
      expect(_hint(tester), 'TOCA PARA SILENCIARTE');
      expect(_icon(FrIcons.openMic), findsOneWidget);
      final label = tester.widget<Text>(
        find.byKey(const Key('ptt_core_label')),
      );
      expect(label.style?.color, FrColors.light.signalInk);
      expect(_painter(tester).look.onAir, isTrue);

      await tester.tap(find.byKey(const Key('mic_toggle_button')));
      await tester.pump();
      expect(calls.toggle, 1);
    });

    testWidgets('AC3: de día el tiempo al aire va en signalInk y en reposo '
        'la etiqueta en tx2', (tester) async {
      _reduceMotion(tester);
      await _pumpCore(tester, PttPhase.onAir, theme: AppTheme.light);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('ptt_core_timer')))
            .style
            ?.color,
        FrColors.light.signalInk,
      );

      await _pumpCore(tester, PttPhase.idle, theme: AppTheme.light);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('ptt_core_label')))
            .style
            ?.color,
        FrColors.light.tx2,
      );
    });

    testWidgets('AC7: reconectando el núcleo se ve al 35 %, dice «En espera» '
        'y no responde', (tester) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(tester, PttPhase.reconnecting);

      expect(_label(tester), 'EN ESPERA');
      expect(_hint(tester), 'RECUPERANDO LA CONEXIÓN…');
      expect(_opacity(tester), 0.35);
      expect(_painter(tester).look.waiting, isTrue);

      await tester.tap(find.byType(PttCore), warnIfMissed: false);
      await tester.pump();
      expect(calls.start, 0);
      expect(calls.toggle, 0);
    });

    testWidgets('AC7: conectando dice que conecta con el anfitrión', (
      tester,
    ) async {
      _reduceMotion(tester);
      await _pumpCore(tester, PttPhase.connecting);

      expect(_label(tester), 'EN ESPERA');
      expect(_hint(tester), 'CONECTANDO CON EL ANFITRIÓN…');
      expect(_opacity(tester), 0.35);
    });

    testWidgets('AC7: si pasa a espera con el dedo apoyado deja de '
        'transmitir una sola vez', (tester) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(tester, PttPhase.idle);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ptt_button'))),
      );
      await tester.pump();
      expect(calls.start, 1);

      await _pumpCore(tester, PttPhase.reconnecting, calls: calls);
      expect(calls.stop, 1);
      expect(_label(tester), 'EN ESPERA');

      await gesture.up();
      await tester.pump();
      expect(calls.stop, 1);
    });

    testWidgets('F4: si el núcleo se va con el dedo apoyado (p. ej. al '
        'cerrarse la frecu) deja de transmitir una sola vez', (tester) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(tester, PttPhase.idle);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('ptt_button'))),
      );
      await tester.pump();
      expect(calls.start, 1);

      await tester.pumpWidget(const SizedBox());
      expect(calls.stop, 1);

      await gesture.up();
      await tester.pump();
      expect(calls.stop, 1);
    });

    testWidgets('F4: si se va sin dedo apoyado no llama a nada', (
      tester,
    ) async {
      _reduceMotion(tester);
      final calls = await _pumpCore(tester, PttPhase.idle);

      await tester.pumpWidget(const SizedBox());
      expect(calls.stop, 0);
    });
  });
}
