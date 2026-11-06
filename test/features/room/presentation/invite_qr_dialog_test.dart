// AC4: CUANDO el anfitrión consulta la información de invitación de la frecu ENTONCES se genera y muestra un código QR con el formato URI `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Invite QR dialog in RoomPage', () {
    testWidgets(
      'AC4: RoomPage shows QR button and tapping it displays invite QR code',
      (tester) async {
        fail('Invite QR dialog not implemented yet');
      },
    );
  });
}
