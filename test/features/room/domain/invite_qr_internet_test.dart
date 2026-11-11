// X1: CUANDO la frecu se abrió por internet ENTONCES su QR lleva el id (`x`) y, sin red local, ni IP ni puerto.
// X2: CUANDO se escanea un QR o un enlace con `x` y sin IP ENTONCES se lee como una frecu por internet.
// X3: CUANDO `x` no tiene la forma de un id ENTONCES se ignora y, sin IP, la invitación no vale.
// X4: CUANDO una frecu mezclada lleva IP y `x` ENTONCES se leen las dos.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';

void main() {
  const build = BuildInviteQr();
  const parse = ParseInviteFromQr();
  const id = '0123456789abcdef0123456789abcdef';

  test('X1: an internet-only invite carries x and no host or port', () {
    final uri = build.buildUri(
      const RoomInvite(
        host: '',
        port: 0,
        roomId: 'room_1',
        accessCode: '1234',
        internetId: id,
      ),
    );

    expect(uri, 'frecu://join?r=room_1&c=1234&x=$id');
  });

  test('X2: a link with x and no host is an internet invite', () {
    final invite = parse
        .parse('frecu://join?x=$id&c=1234&name=Ruta')
        .dataOrNull;

    expect(invite, isNotNull);
    expect(invite!.internetId, id);
    expect(invite.host, isEmpty);
    expect(invite.roomId, id);
    expect(invite.name, 'Ruta');
  });

  test('X3: a malformed x is ignored, and without a host it is invalid', () {
    expect(parse.parse('frecu://join?x=nope&c=1234&r=r').isFailure, isTrue);
    expect(
      parse
          .parse('frecu://join?h=10.0.0.2&p=47800&r=r&c=1&x=nope')
          .dataOrNull
          ?.internetId,
      isNull,
    );
  });

  test('X4: a mixed room keeps both the local address and x', () {
    const invite = RoomInvite(
      host: '192.168.1.10',
      port: 47800,
      roomId: 'room_1',
      accessCode: '1234',
      internetId: id,
    );

    final parsed = parse.parse(build.buildUri(invite)).dataOrNull;

    expect(parsed, invite);
  });
}
