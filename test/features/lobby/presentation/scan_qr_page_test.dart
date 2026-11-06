// AC5: CUANDO un participante escanea el código QR de invitación ENTONCES la aplicación parsea los parámetros de conexión y se une automáticamente a la sala sin ingresar la IP ni el código manualmente.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scan QR page and automatic join', () {
    testWidgets(
      'AC5: ScanQrPage detects invite QR and automatically joins room',
      (tester) async {
        fail('ScanQrPage automatic join not implemented yet');
      },
    );
  });
}
