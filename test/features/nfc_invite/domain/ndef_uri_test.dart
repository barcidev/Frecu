// Invitar por NFC (corte 9 de la épica de hardware V1): el registro URI de
// NDEF guarda la invitación sin abreviar y se lee con los prefijos del
// estándar; lo que no es un registro URI no cuenta.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/nfc_invite/domain/entities/ndef_uri.dart';

void main() {
  const invite = 'frecu://join?h=192.168.49.1&p=47800&r=room-1&c=4827';

  test('la invitación va y vuelve, sin prefijo abreviado', () {
    final payload = NdefUri.payload(invite);

    expect(payload.first, 0x00);
    expect(NdefUri.parse(NdefUri.type, payload), invite);
  });

  test('los prefijos del estándar se expanden', () {
    expect(
      NdefUri.parse(NdefUri.type, [0x04, ...utf8.encode('frecu.app')]),
      'https://frecu.app',
    );
  });

  test('otro tipo, sin contenido, un prefijo desconocido o UTF-8 roto no '
      'cuentan', () {
    expect(NdefUri.parse([0x54], NdefUri.payload(invite)), isNull);
    expect(NdefUri.parse(NdefUri.type, const []), isNull);
    expect(NdefUri.parse(NdefUri.type, const [0x40, 0x61]), isNull);
    expect(NdefUri.parse(NdefUri.type, const [0x00, 0xff, 0xfe]), isNull);
  });
}
