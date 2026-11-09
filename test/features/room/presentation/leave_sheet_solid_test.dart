// P109: CUANDO se abre la hoja para salir o cerrar la frecu ENTONCES el botón de confirmar es el botón sólido de alerta (`FrButtonVariant.dangerSolid`, `.btn-danger-solid` del prototipo) y Cancelar sigue siendo secundario.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/features/room/presentation/widgets/leave_sheet.dart';
import 'package:frecu/i18n/strings.g.dart';

void main() {
  for (final host in [true, false]) {
    testWidgets('P109: confirmar es sólido de alerta (anfitrión: $host)', (
      tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.es);
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: SingleChildScrollView(
                child: LeaveSheet(host: host, others: 2),
              ),
            ),
          ),
        ),
      );

      final confirm = tester.widget<FrButton>(
        find.byKey(const Key('leave_confirm')),
      );
      expect(confirm.variant, FrButtonVariant.dangerSolid);
      final cancel = tester.widget<FrButton>(
        find.byKey(const Key('leave_cancel')),
      );
      expect(cancel.variant, FrButtonVariant.secondary);
    });
  }
}
