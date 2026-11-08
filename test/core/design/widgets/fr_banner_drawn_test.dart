// AC2: CUANDO un `FrBanner` se crea con `FrBanner.drawn` y un ícono de `FrIcons` ENTONCES lo dibuja con `FrIcon` a 18 px con el color de ícono de su tono (`warn`, `alert` o `tx2` en info); y con `IconData` se comporta como antes.
// AC3: CUANDO un `FrBanner` tiene cierre (`onDismiss`), creado con cualquiera de sus dos constructores, ENTONCES el botón de cerrar dibuja `FrIcons.close` con `FrIcon` a 16 px en `tx3`, sin `Icons.close_rounded`, conserva su etiqueta accesible y al tocarlo el aviso se va y llama a `onDismiss`; sin `onDismiss` no hay cierre.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_banner.dart';

const c = FrColors.dark;
const title = 'Micrófono abierto con altavoz.';
const closeLabel = 'Cerrar aviso';

Future<void> pumpHost(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: child),
      ),
    ),
  ),
);

Finder drawn(FrIconData icon) =>
    find.byWidgetPredicate((widget) => widget is FrIcon && widget.icon == icon);

void main() {
  group('FrBanner.drawn', () {
    testWidgets('AC2: dibuja el ícono propio a 18 px con el color de su tono', (
      tester,
    ) async {
      for (final (tone, ink) in [
        (FrBannerTone.warn, c.warn),
        (FrBannerTone.alert, c.alert),
        (FrBannerTone.info, c.tx2),
      ]) {
        await pumpHost(
          tester,
          FrBanner.drawn(tone: tone, icon: FrIcons.headset, title: title),
        );

        final glyph = drawn(FrIcons.headset);
        expect(glyph, findsOneWidget, reason: '$tone');
        expect(tester.widget<FrIcon>(glyph).color, ink, reason: '$tone');
        expect(tester.getSize(glyph), const Size(18, 18), reason: '$tone');
        expect(find.byType(FrIcon), findsOneWidget, reason: '$tone');
        expect(find.byType(Icon), findsNothing, reason: '$tone');
      }
    });

    testWidgets(
      'AC3: el cierre dibuja FrIcons.close a 16 px en tx3 y llama a onDismiss',
      (tester) async {
        var dismissed = 0;
        await pumpHost(
          tester,
          FrBanner.drawn(
            tone: FrBannerTone.warn,
            icon: FrIcons.headset,
            title: title,
            floating: true,
            dismissLabel: closeLabel,
            onDismiss: () => dismissed++,
          ),
        );

        final close = drawn(FrIcons.close);
        expect(close, findsOneWidget);
        expect(tester.widget<FrIcon>(close).color, c.tx3);
        expect(tester.getSize(close), const Size(16, 16));
        expect(find.byType(Icon), findsNothing);
        expect(
          tester.getCenter(close).dx,
          greaterThan(tester.getCenter(find.text(title)).dx),
        );

        await tester.tap(find.bySemanticsLabel(closeLabel));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(dismissed, 1);
      },
    );

    testWidgets('AC3: sin onDismiss no hay cierre', (tester) async {
      await pumpHost(
        tester,
        const FrBanner.drawn(
          tone: FrBannerTone.alert,
          icon: FrIcons.alert,
          title: title,
        ),
      );

      expect(drawn(FrIcons.close), findsNothing);
      expect(find.bySemanticsLabel(closeLabel), findsNothing);
    });
  });

  group('FrBanner con IconData', () {
    testWidgets(
      'AC2: sigue dibujando su ícono de Material con el color del tono',
      (tester) async {
        await pumpHost(
          tester,
          const FrBanner(
            tone: FrBannerTone.alert,
            icon: Icons.wifi_off_rounded,
            title: title,
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.wifi_off_rounded));
        expect(icon.size, 18);
        expect(icon.color, c.alert);
        expect(find.byType(FrIcon), findsNothing);
      },
    );

    testWidgets(
      'AC3: el cierre también dibuja FrIcons.close y no Icons.close_rounded',
      (tester) async {
        var dismissed = 0;
        await pumpHost(
          tester,
          FrBanner(
            tone: FrBannerTone.warn,
            icon: Icons.headphones_rounded,
            title: title,
            dismissLabel: closeLabel,
            onDismiss: () => dismissed++,
          ),
        );

        final close = drawn(FrIcons.close);
        expect(close, findsOneWidget);
        expect(tester.widget<FrIcon>(close).color, c.tx3);
        expect(tester.getSize(close), const Size(16, 16));
        expect(find.byIcon(Icons.close_rounded), findsNothing);
        expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);

        await tester.tap(find.bySemanticsLabel(closeLabel));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(dismissed, 1);
      },
    );
  });
}
