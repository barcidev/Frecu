// AC1: CUANDO un `FrField` se crea con `FrField.drawn` y un ícono de `FrIcons` ENTONCES lo dibuja con `FrIcon` antes del texto, a 18 px, en `tx3` y a 10 px del texto, sin ningún `Icon` de Material; y con `IconData` o sin ícono se comporta como antes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_field.dart';

const colors = FrColors.dark;

Future<void> pumpHost(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: child,
        ),
      ),
    ),
  ),
);

void main() {
  group('FrField.drawn', () {
    testWidgets(
      'AC1: dibuja el ícono propio antes del texto, a 18 px y en tx3',
      (tester) async {
        await pumpHost(
          tester,
          const FrField.drawn(
            label: 'IP del anfitrión',
            hint: '192.168.43.1',
            mono: true,
            icon: FrIcons.nodes,
          ),
        );

        final glyph = find.byType(FrIcon);
        expect(glyph, findsOneWidget);
        final icon = tester.widget<FrIcon>(glyph);
        expect(icon.icon, FrIcons.nodes);
        expect(icon.color, colors.tx3);
        expect(tester.getSize(glyph), const Size(18, 18));
        expect(find.byType(Icon), findsNothing);

        final text = tester.getRect(find.byType(TextField));
        final drawn = tester.getRect(glyph);
        expect(drawn.right, lessThanOrEqualTo(text.left));
        expect(text.left - drawn.right, closeTo(10, 0.5));
        expect(drawn.center.dy, closeTo(text.center.dy, 1));
      },
    );

    testWidgets('AC1: sin ícono no dibuja ninguno', (tester) async {
      await pumpHost(tester, const FrField.drawn(label: 'Código de acceso'));

      expect(find.byType(FrIcon), findsNothing);
      expect(find.byType(Icon), findsNothing);
      expect(find.text('CÓDIGO DE ACCESO'), findsOneWidget);
    });

    testWidgets(
      'AC1: con el ícono propio escribe, cuenta y marca el error como antes',
      (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await pumpHost(
          tester,
          FrField.drawn(
            label: 'Código de acceso',
            controller: controller,
            maxLength: 4,
            error: 'Código incorrecto',
            icon: FrIcons.lock,
          ),
        );

        await tester.enterText(find.byType(EditableText), '123456');
        await tester.pump();

        expect(controller.text, '1234');
        expect(find.text('4/4'), findsOneWidget);
        expect(find.text('Código incorrecto'), findsOneWidget);
        expect(tester.widget<FrIcon>(find.byType(FrIcon)).icon, FrIcons.lock);
      },
    );
  });

  group('FrField con IconData', () {
    testWidgets('AC1: sigue dibujando el ícono de Material como antes', (
      tester,
    ) async {
      await pumpHost(
        tester,
        const FrField(label: 'IP del anfitrión', icon: Icons.hub_outlined),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.hub_outlined));
      expect(icon.size, 18);
      expect(icon.color, colors.tx3);
      expect(find.byType(FrIcon), findsNothing);
    });
  });
}
