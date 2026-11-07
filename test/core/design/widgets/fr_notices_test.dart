// AC4: CUANDO se muestra un `FrBanner` ENTONCES lleva el tono de aviso, alerta o info (lavado y borde del color, ícono, título en negrita, mensaje y acción subrayada) y, al tocar cerrar, se funde subiendo 6 px y luego llama a `onDismiss`; y CUANDO se muestra un `FrToast` con `showFrToast` ENTONCES es una píldora de 46 px con la firma o el ícono que entra subiendo, se va sola al terminar su duración y uno nuevo reemplaza al anterior.
// AC5: CUANDO la isla de estado muestra en línea, al aire, recibiendo, reconectando, conectando o un evento ENTONCES es una cápsula de 36 px siempre oscura (también en tema claro): al aire con relleno de señal y punto que parpadea, recibiendo con la firma y el nombre en el color de la persona, reconectando en ámbar con punto que parpadea y conectando con la onda; cambia de ancho con el resorte `organic`, el contenido nuevo entra fundido y subiendo, y su texto se anuncia a la accesibilidad.
// AC6: CUANDO el sistema pide reducir el movimiento ENTONCES onda, deslizamiento, expansión y hoja pasan a un fundido de 280 ms sin desplazamientos ni escalas, la pantalla de abajo no se aleja, la isla cambia sin resorte y su punto no parpadea, el aviso y el toast solo se funden, y ningún estado ni texto se oculta.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/core/design/widgets/status_island.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';

const c = FrColors.dark;
const title = 'Micrófono abierto con altavoz.';
const message = 'Usa audífonos para evitar eco.';

late BuildContext hostContext;

Future<void> pumpHost(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
  ThemeData? theme,
}) async {
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            hostContext = context;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: child),
            );
          },
        ),
      ),
    ),
  );
}

/// Opacidad visible de [finder]: producto de sus `Opacity` y `FadeTransition`
/// y las de sus ancestros.
double opacityOf(WidgetTester tester, Finder finder) {
  final element = finder.evaluate().first;
  var value = 1.0;
  void apply(Widget widget) {
    if (widget is Opacity) value *= widget.opacity;
    if (widget is FadeTransition) value *= widget.opacity.value;
  }

  apply(element.widget);
  element.visitAncestorElements((ancestor) {
    apply(ancestor.widget);
    return true;
  });
  return value;
}

/// Estilo efectivo del tramo de texto exacto [text].
TextStyle? styleOf(WidgetTester tester, String text) {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    TextStyle? found;
    void walk(InlineSpan span, TextStyle? inherited) {
      final style = inherited?.merge(span.style) ?? span.style;
      if (span is TextSpan) {
        if (span.text == text) found ??= style;
        for (final child in span.children ?? const <InlineSpan>[]) {
          walk(child, style);
        }
      }
    }

    walk(rich.text, null);
    if (found != null) return found;
  }
  return null;
}

typedef Look = ({Color? color, Color? side, List<BoxShadow> shadows});

Look lookOf(Decoration decoration) => switch (decoration) {
  BoxDecoration(:final color, :final border, :final boxShadow) => (
    color: color,
    side: border is Border ? border.top.color : null,
    shadows: boxShadow ?? const <BoxShadow>[],
  ),
  ShapeDecoration(:final color, :final shape, :final shadows) => (
    color: color,
    side: shape is OutlinedBorder ? shape.side.color : null,
    shadows: shadows ?? const <BoxShadow>[],
  ),
  _ => (color: null, side: null, shadows: const <BoxShadow>[]),
};

List<Look> looksIn(WidgetTester tester, Finder of) => tester
    .widgetList<DecoratedBox>(
      find.descendant(of: of, matching: find.byType(DecoratedBox)),
    )
    .map((box) => lookOf(box.decoration))
    .toList();

bool hasBoxOfSize(WidgetTester tester, Finder of, Size size) => find
    .descendant(of: of, matching: find.byWidgetPredicate((_) => true))
    .evaluate()
    .any((element) {
      final box = element.renderObject;
      return box is RenderBox && box.hasSize && box.size == size;
    });

/// Opacidad del punto de 7 px de la isla (1 si no tiene opacidad propia).
double dotOpacity(WidgetTester tester) {
  final dots = find
      .descendant(
        of: find.byType(StatusIsland),
        matching: find.byWidgetPredicate(
          (widget) => widget is Opacity || widget is FadeTransition,
        ),
      )
      .evaluate()
      .where((element) {
        final box = element.renderObject;
        return box is RenderBox && box.hasSize && box.size == const Size(7, 7);
      });
  if (dots.isEmpty) return 1;
  final widget = dots.first.widget;
  return widget is Opacity
      ? widget.opacity
      : (widget as FadeTransition).opacity.value;
}

void main() {
  group('FrBanner', () {
    testWidgets(
      'AC4: el aviso lleva lavado, borde e ícono de su tono, título en negrita y acción subrayada',
      (tester) async {
        var actions = 0;
        await pumpHost(
          tester,
          FrBanner(
            tone: FrBannerTone.warn,
            icon: Icons.headset,
            title: title,
            message: message,
            actionLabel: 'Cambiar salida',
            onAction: () => actions++,
          ),
        );

        final looks = looksIn(tester, find.byType(FrBanner));
        expect(
          looks.any(
            (look) =>
                look.color == c.warn.withValues(alpha: 0.08) &&
                look.side == c.warn.withValues(alpha: 0.3),
          ),
          isTrue,
        );
        expect(tester.widget<Icon>(find.byIcon(Icons.headset)).color, c.warn);
        final titleStyle = styleOf(tester, title)!;
        expect(titleStyle.fontWeight!.value, greaterThanOrEqualTo(600));
        expect(titleStyle.color, c.warnTx);
        expect(styleOf(tester, message)!.color, c.warnTx);
        final action = styleOf(tester, 'Cambiar salida')!;
        expect(action.decoration, TextDecoration.underline);
        expect(action.color, c.tx1);

        await tester.tap(find.text('Cambiar salida'));
        expect(actions, 1);
      },
    );

    testWidgets('AC4: alerta e info usan sus colores', (tester) async {
      for (final (tone, wash, side, ink, icon) in [
        (
          FrBannerTone.alert,
          c.alert.withValues(alpha: 0.08),
          c.alert.withValues(alpha: 0.32),
          c.alertTx,
          c.alert,
        ),
        (FrBannerTone.info, c.bg1, c.line1, c.tx2, c.tx2),
      ]) {
        await pumpHost(
          tester,
          FrBanner(tone: tone, icon: Icons.wifi, title: title),
        );

        expect(
          looksIn(
            tester,
            find.byType(FrBanner),
          ).any((look) => look.color == wash && look.side == side),
          isTrue,
          reason: '$tone',
        );
        expect(styleOf(tester, title)!.color, ink, reason: '$tone');
        expect(
          tester.widget<Icon>(find.byIcon(Icons.wifi)).color,
          icon,
          reason: '$tone',
        );
      }
    });

    testWidgets('AC4: el aviso flotante (eco) es opaco y proyecta sombra', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const FrBanner(
          tone: FrBannerTone.warn,
          icon: Icons.headset,
          title: title,
          floating: true,
        ),
      );

      expect(
        looksIn(
          tester,
          find.byType(FrBanner),
        ).any((look) => look.color?.a == 1 && look.shadows.isNotEmpty),
        isTrue,
      );
    });

    testWidgets(
      'AC4: al cerrar se funde subiendo 6 px y luego llama a onDismiss',
      (tester) async {
        var dismissed = 0;
        await pumpHost(
          tester,
          FrBanner(
            tone: FrBannerTone.warn,
            icon: Icons.headset,
            title: title,
            message: message,
            onDismiss: () => dismissed++,
            dismissLabel: 'Cerrar aviso',
          ),
        );
        final text = find.textContaining('Micrófono');
        final before = tester.getRect(text).top;

        await tester.tap(find.bySemanticsLabel('Cerrar aviso'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        final top = tester.getRect(text).top;
        expect(top, lessThan(before));
        expect(top, greaterThanOrEqualTo(before - 6.01));
        final fading = opacityOf(tester, text);
        expect(fading, greaterThan(0));
        expect(fading, lessThan(1));
        expect(dismissed, 0);

        await tester.pump(const Duration(milliseconds: 160));

        expect(dismissed, 1);
      },
    );

    testWidgets(
      'AC6: con movimiento reducido el aviso solo se funde al cerrar',
      (tester) async {
        var dismissed = 0;
        await pumpHost(
          tester,
          FrBanner(
            tone: FrBannerTone.warn,
            icon: Icons.headset,
            title: title,
            onDismiss: () => dismissed++,
            dismissLabel: 'Cerrar aviso',
          ),
          reduceMotion: true,
        );
        final text = find.textContaining('Micrófono');
        final before = tester.getRect(text).top;

        await tester.tap(find.bySemanticsLabel('Cerrar aviso'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(tester.getRect(text).top, closeTo(before, 0.01));
        final fading = opacityOf(tester, text);
        expect(fading, greaterThan(0));
        expect(fading, lessThan(1));

        await tester.pump(const Duration(milliseconds: 160));
        expect(dismissed, 1);
      },
    );
  });

  group('FrToast', () {
    testWidgets(
      'AC4: el toast es una píldora de 46 px con su ícono que entra subiendo y se va sola',
      (tester) async {
        await pumpHost(tester, const SizedBox());

        showFrToast(
          hostContext,
          const FrToast.icon(icon: Icons.check, message: 'Código copiado'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final early = tester.getRect(find.byType(FrToast));
        expect(opacityOf(tester, find.byType(FrToast)), lessThan(1));

        await tester.pump(const Duration(milliseconds: 600));

        final settled = tester.getRect(find.byType(FrToast));
        expect(early.top, greaterThan(settled.top));
        expect(settled.height, closeTo(46, 0.5));
        expect(opacityOf(tester, find.byType(FrToast)), 1);
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(
          hasBoxOfSize(tester, find.byType(FrToast), const Size(30, 30)),
          isTrue,
        );
        expect(
          looksIn(
            tester,
            find.byType(FrToast),
          ).any((look) => look.color == c.bg3),
          isTrue,
        );

        await tester.pump(const Duration(milliseconds: 2600));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(find.text('Código copiado'), findsNothing);
      },
    );

    testWidgets(
      'AC4: el toast con firma muestra la firma de 30 px hablando y uno nuevo reemplaza al anterior',
      (tester) async {
        await pumpHost(tester, const SizedBox());

        showFrToast(
          hostContext,
          FrToast.signature(
            name: 'Ana',
            color: c.p2,
            title: 'Ana',
            message: 'se unió',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final signature = tester.widget<SignalSignature>(
          find.byType(SignalSignature),
        );
        expect(signature.name, 'Ana');
        expect(signature.size, 30);
        expect(signature.color, c.p2);
        expect(signature.mode, SignatureMode.speak);
        expect(
          styleOf(tester, 'Ana')!.fontWeight!.value,
          greaterThanOrEqualTo(600),
        );

        showFrToast(
          hostContext,
          const FrToast.icon(icon: Icons.check, message: 'Copiado'),
        );
        await tester.pump();

        expect(find.byType(SignalSignature), findsNothing);
        expect(find.text('Copiado'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 3000));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(find.byType(FrToast), findsNothing);
      },
    );

    testWidgets(
      'AC6: con movimiento reducido el toast entra fundido sin subir',
      (tester) async {
        await pumpHost(tester, const SizedBox(), reduceMotion: true);

        showFrToast(
          hostContext,
          const FrToast.icon(icon: Icons.check, message: 'Código copiado'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        final early = tester.getRect(find.byType(FrToast));
        final fading = opacityOf(tester, find.byType(FrToast));
        expect(fading, greaterThan(0));
        expect(fading, lessThan(1));

        await tester.pump(const Duration(milliseconds: 600));

        expect(
          tester.getRect(find.byType(FrToast)),
          rectMoreOrLessEquals(early, epsilon: 0.01),
        );
        expect(early.height, closeTo(46, 0.5));

        await tester.pump(const Duration(milliseconds: 2600));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(find.byType(FrToast), findsNothing);
      },
    );
  });

  group('StatusIsland', () {
    testWidgets(
      'AC5: es una cápsula negra de 36 px también en tema claro, con el texto claro',
      (tester) async {
        await pumpHost(
          tester,
          const StatusIsland.online(label: 'En línea · 5/6'),
          theme: AppTheme.light,
        );

        expect(tester.getSize(find.byType(StatusIsland)).height, 36);
        expect(
          looksIn(
            tester,
            find.byType(StatusIsland),
          ).any((look) => look.color == const Color(0xFF000000)),
          isTrue,
        );
        expect(styleOf(tester, 'EN LÍNEA · 5/6')!.color, FrColors.dark.tx1);
      },
    );

    testWidgets(
      'AC5: al aire se rellena de señal con texto signalInk y el punto parpadea',
      (tester) async {
        await pumpHost(
          tester,
          const StatusIsland.onAir(label: 'Al aire · 00:04'),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          looksIn(
            tester,
            find.byType(StatusIsland),
          ).any((look) => look.color == c.signal),
          isTrue,
        );
        expect(styleOf(tester, 'AL AIRE · 00:04')!.color, c.signalInk);
        final first = dotOpacity(tester);
        await tester.pump(const Duration(milliseconds: 600));
        expect(dotOpacity(tester), isNot(first));
      },
    );

    testWidgets(
      'AC5: recibiendo muestra la firma y el nombre en el color de la persona',
      (tester) async {
        await pumpHost(
          tester,
          StatusIsland.receiving(
            name: 'Ana',
            color: c.p2,
            label: 'Ana · hablando',
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        final signature = tester.widget<SignalSignature>(
          find.byType(SignalSignature),
        );
        expect(signature.name, 'Ana');
        expect(signature.size, 24);
        expect(signature.color, c.p2);
        expect(signature.mode, SignatureMode.speak);
        expect(styleOf(tester, 'ANA · HABLANDO')!.color, c.p2);
      },
    );

    testWidgets(
      'AC5: reconectando va en ámbar con el punto que parpadea, y conectando muestra la onda',
      (tester) async {
        await pumpHost(
          tester,
          const StatusIsland.reconnecting(label: 'Reconectando · 4 s'),
        );
        await tester.pump(const Duration(milliseconds: 600));

        expect(
          looksIn(
            tester,
            find.byType(StatusIsland),
          ).any((look) => look.side == c.warn.withValues(alpha: 0.45)),
          isTrue,
        );
        expect(styleOf(tester, 'RECONECTANDO · 4 S')!.color, c.warn);
        final first = dotOpacity(tester);
        await tester.pump(const Duration(milliseconds: 700));
        expect(dotOpacity(tester), isNot(first));

        await pumpHost(
          tester,
          const StatusIsland.connecting(label: 'Conectando…'),
        );
        await tester.pump(const Duration(milliseconds: 500));

        final wave = tester.widget<WaveLoader>(find.byType(WaveLoader));
        expect(wave.width, 34);
        expect(wave.height, 16);
        expect(find.text('CONECTANDO…'), findsOneWidget);
      },
    );

    testWidgets(
      'AC5: al cambiar de estado cambia de ancho con el resorte organic y el contenido nuevo entra fundido y subiendo',
      (tester) async {
        await pumpHost(
          tester,
          const StatusIsland.online(label: 'En línea · 5/6'),
        );
        final before = tester.getSize(find.byType(StatusIsland)).width;

        await pumpHost(
          tester,
          const StatusIsland.event(label: 'Conexión recuperada con la frecu'),
        );
        await tester.pump(const Duration(milliseconds: 100));

        final label = find.text('CONEXIÓN RECUPERADA CON LA FRECU');
        final width = tester.getSize(find.byType(StatusIsland)).width;
        final entering = tester.getRect(label).top;
        expect(opacityOf(tester, label), lessThan(1));

        await tester.pump(const Duration(milliseconds: 700));

        final after = tester.getSize(find.byType(StatusIsland)).width;
        expect(after, greaterThan(before));
        expect(width, greaterThan(before));
        expect(width, lessThan(after));
        expect(entering, greaterThan(tester.getRect(label).top));
        expect(opacityOf(tester, label), 1);
      },
    );

    testWidgets('AC5: su texto se anuncia a la accesibilidad', (tester) async {
      await pumpHost(
        tester,
        const StatusIsland.reconnecting(label: 'Reconectando · 4 s'),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        tester.getSemantics(find.byType(StatusIsland)),
        isSemantics(label: 'Reconectando · 4 s', isLiveRegion: true),
      );
    });

    testWidgets(
      'AC6: con movimiento reducido la isla cambia sin resorte, su punto no parpadea y el texto sigue visible',
      (tester) async {
        await pumpHost(
          tester,
          const StatusIsland.online(label: 'En línea · 5/6'),
          reduceMotion: true,
        );
        final before = tester.getSize(find.byType(StatusIsland)).width;

        await pumpHost(
          tester,
          const StatusIsland.reconnecting(label: 'Reconectando · 4 s'),
          reduceMotion: true,
        );
        await tester.pump();

        final width = tester.getSize(find.byType(StatusIsland)).width;
        expect(width, isNot(before));

        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.getSize(find.byType(StatusIsland)).width, width);
        expect(opacityOf(tester, find.text('RECONECTANDO · 4 S')), 1);
        expect(dotOpacity(tester), 1);
        await tester.pump(const Duration(milliseconds: 500));
        expect(dotOpacity(tester), 1);
      },
    );
  });
}
