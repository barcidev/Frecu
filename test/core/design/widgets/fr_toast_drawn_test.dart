// CUANDO un `FrToast` se crea con `FrToast.drawn` y un ícono de `FrIcons` ENTONCES lo dibuja con `FrIcon` a 16 px en `signalFg` dentro del círculo de señal de 30 px, sin íconos de Material.
// CUANDO un `FrKeypad` no recibe `deleteIcon` ENTONCES la tecla de borrar dibuja `FrIcons.backspace`, sin íconos de Material.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/fr_keypad.dart';
import 'package:frecu/core/design/widgets/fr_toast.dart';

Future<void> pumpHost(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  ),
);

Finder drawn(FrIconData icon) =>
    find.byWidgetPredicate((widget) => widget is FrIcon && widget.icon == icon);

void main() {
  testWidgets('FrToast.drawn dibuja el ícono propio en el círculo de señal', (
    tester,
  ) async {
    await pumpHost(
      tester,
      const FrToast.drawn(icon: FrIcons.alert, message: 'No se pudo guardar'),
    );

    final glyph = drawn(FrIcons.alert);
    expect(glyph, findsOneWidget);
    expect(tester.widget<FrIcon>(glyph).color, FrColors.dark.signalFg);
    expect(tester.getSize(glyph), const Size(16, 16));
    expect(
      find
          .ancestor(of: glyph, matching: find.byType(SizedBox))
          .evaluate()
          .any((element) => element.size == const Size(30, 30)),
      isTrue,
    );
    expect(find.text('No se pudo guardar'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('FrKeypad sin deleteIcon borra con FrIcons.backspace', (
    tester,
  ) async {
    await pumpHost(
      tester,
      FrKeypad(onDigit: (_) {}, onDelete: () {}, deleteLabel: 'Borrar'),
    );

    expect(drawn(FrIcons.backspace), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });
}
