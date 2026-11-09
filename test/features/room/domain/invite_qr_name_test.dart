// P98: el QR de invitación puede llevar el nombre de la frecu como parámetro opcional y aditivo `name`, tras la nota; un QR sin nombre se construye y se lee como antes, y uno con nombre se lee con él, aunque tenga espacios, acentos o símbolos.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';

void main() {
  const build = BuildInviteQr();
  const parse = ParseInviteFromQr();

  const invite = RoomInvite(
    host: '192.168.43.1',
    port: 47800,
    roomId: 'room-qr',
    accessCode: '4827',
    note: RoomNote(semitone: 7),
  );
  const baseUri = 'frecu://join?h=192.168.43.1&p=47800&r=room-qr&c=4827&n=7';

  test('sin nombre la URI es la de antes', () {
    expect(build.buildUri(invite), baseUri);
    expect(build.buildUri(invite.copyWith(name: '   ')), baseUri);
  });

  test('con nombre suma name tras la nota y se lee igual', () {
    final named = invite.copyWith(name: 'Ruta del domingo');

    final uri = build.buildUri(named);

    expect(uri, startsWith('$baseUri&name='));
    expect(parse.parse(uri).dataOrNull, named);
  });

  test('el nombre sobrevive a espacios, acentos y símbolos', () {
    for (final name in [
      'Brigada Norte',
      'Señal & Café',
      'a=b?c#d',
      'Frecu 7/6',
    ]) {
      final named = invite.copyWith(name: name);

      expect(
        parse.parse(build.buildUri(named)).dataOrNull?.name,
        name,
        reason: name,
      );
    }
  });

  test('un QR sin name o con name vacío se lee sin nombre', () {
    expect(parse.parse(baseUri).dataOrNull, invite);
    expect(parse.parse('$baseUri&name=').dataOrNull, invite);
    expect(parse.parse('$baseUri&name=%20%20').dataOrNull, invite);
  });

  test('el nombre puede ir antes de la nota sin cambiar nada', () {
    final result = parse.parse(
      'frecu://join?h=192.168.43.1&p=47800&r=room-qr&c=4827&name=Brigada&n=7',
    );

    expect(result.dataOrNull, invite.copyWith(name: 'Brigada'));
  });
}
