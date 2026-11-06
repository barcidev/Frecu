// AC4: CUANDO el anfitrión consulta la información de invitación de la frecu ENTONCES se genera y muestra un código QR con el formato URI `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
// AC5: CUANDO un participante escanea el código QR de invitación ENTONCES la aplicación parsea los parámetros de conexión y se une automáticamente a la sala sin ingresar la IP ni el código manualmente.
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Invite QR domain use cases', () {
    test(
      'AC4: BuildInviteQr generates standard frecu://join URI from room invite',
      () {
        fail('BuildInviteQr not implemented yet');
      },
    );

    test(
      'AC5: ParseInviteFromQr parses valid frecu://join URI into RoomInvite',
      () {
        fail('ParseInviteFromQr not implemented yet');
      },
    );
  });
}
