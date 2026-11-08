// P110: CUANDO se muestra el QR de la invitación ENTONCES se dibuja con un pintor propio sobre el `QrCode` del paquete `qr` con corrección H: los módulos son puntos redondos, los tres ojos son aros de esquina suave con su centro (`drawQR` de `engine.js`), el cuadro del centro queda libre para la marca de Frecu (la Lissajous 2:3) y el contenido es el de la invitación.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/theme/app_theme.dart';
import 'package:frecu/features/room/presentation/widgets/invite_sheet.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _uri = 'frecu://join?h=192.168.43.1&p=47800&r=room-abc-123&c=4827';

Future<void> _pumpQr(WidgetTester tester) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(child: InviteQr(data: _uri)),
      ),
    ),
  );
}

InviteQrPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(const Key('invite_qr_code'))).painter!
        as InviteQrPainter;

void main() {
  testWidgets('P110: el QR codifica la invitación con corrección H', (
    tester,
  ) async {
    await _pumpQr(tester);

    final image = _painter(tester).image;
    final expected = QrImage(
      QrCode.fromData(data: _uri, errorCorrectLevel: QrErrorCorrectLevel.H),
    );
    expect(image.moduleCount, expected.moduleCount);
    for (var row = 0; row < expected.moduleCount; row++) {
      for (var col = 0; col < expected.moduleCount; col++) {
        expect(image.isDark(row, col), expected.isDark(row, col));
      }
    }
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('P110: módulos redondos y tres ojos de esquina suave', (
    tester,
  ) async {
    await _pumpQr(tester);

    final code = find.byKey(const Key('invite_qr_code'));
    expect(
      code,
      paints
        ..circle(color: InviteQr.ink)
        ..rrect(style: PaintingStyle.stroke, color: InviteQr.ink)
        ..rrect(style: PaintingStyle.fill, color: InviteQr.ink)
        ..rrect(style: PaintingStyle.stroke, color: InviteQr.ink)
        ..rrect(style: PaintingStyle.fill, color: InviteQr.ink)
        ..rrect(style: PaintingStyle.stroke, color: InviteQr.ink)
        ..rrect(style: PaintingStyle.fill, color: InviteQr.ink),
    );
    expect(code, isNot(paints..rect(color: InviteQr.ink)));
  });

  testWidgets('P110: el centro queda libre para la marca', (tester) async {
    await _pumpQr(tester);

    final painter = _painter(tester);
    expect(painter.hole, greaterThan(0));
    final size = tester.getSize(find.byKey(const Key('invite_qr_code')));
    final center = size.center(Offset.zero);
    expect(
      find.byKey(const Key('invite_qr_code')),
      isNot(
        paints..something(
          (method, arguments) =>
              method == #drawCircle &&
              ((arguments[0] as Offset) - center).distance <
                  painter.hole / 2 - 1,
        ),
      ),
    );
  });
}
