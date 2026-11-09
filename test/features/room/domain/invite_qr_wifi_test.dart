// Red de Frecu: el QR de invitación puede llevar la red de la frecu como datos aditivos `ws` (nombre) y `wk` (clave), tras el nombre; un QR sin red se construye y se lee como antes, una red sin clave es abierta y una clave sin red no cuenta. El nombre y la clave sobreviven a espacios y símbolos.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';

void main() {
  const build = BuildInviteQr();
  const parse = ParseInviteFromQr();

  const invite = RoomInvite(
    host: '192.168.62.1',
    port: 47800,
    roomId: 'room-qr',
    accessCode: '4827',
    note: RoomNote(semitone: 7),
    name: 'Ruta',
  );
  const baseUri =
      'frecu://join?h=192.168.62.1&p=47800&r=room-qr&c=4827&n=7&name=Ruta';
  const wifi = WifiCredentials(
    ssid: 'AndroidShare_4821',
    passphrase: 'a3f91c7e5b2d',
  );

  test('sin red la URI es la de antes', () {
    expect(build.buildUri(invite), baseUri);
    expect(
      build.buildUri(invite.copyWith(wifi: const WifiCredentials(ssid: ''))),
      baseUri,
    );
  });

  test('con red suma ws y wk tras el nombre y se lee igual', () {
    final withWifi = invite.copyWith(wifi: wifi);

    final uri = build.buildUri(withWifi);

    expect(uri, '$baseUri&ws=AndroidShare_4821&wk=a3f91c7e5b2d');
    expect(parse.parse(uri).dataOrNull, withWifi);
  });

  test('una red sin clave es abierta: lleva ws y no wk', () {
    final open = invite.copyWith(
      wifi: const WifiCredentials(ssid: 'Frecu abierta'),
    );

    final uri = build.buildUri(open);

    expect(uri, isNot(contains('wk=')));
    expect(parse.parse(uri).dataOrNull, open);
    expect(parse.parse('$uri&wk=').dataOrNull, open);
  });

  test('el nombre y la clave sobreviven a espacios y símbolos', () {
    const tricky = WifiCredentials(
      ssid: 'Moto de Andrés & Co',
      passphrase: 'a b=c?d#e&f',
    );

    final read = parse.parse(build.buildUri(invite.copyWith(wifi: tricky)));

    expect(read.dataOrNull?.wifi, tricky);
  });

  test('un QR anterior, sin ws, se lee sin red; wk solo no cuenta', () {
    expect(parse.parse(baseUri).dataOrNull?.wifi, isNull);
    expect(parse.parse('$baseUri&wk=secreta').dataOrNull?.wifi, isNull);
    expect(parse.parse('$baseUri&ws=').dataOrNull?.wifi, isNull);
  });

  test('el orden de los parámetros no importa', () {
    final read = parse.parse(
      'frecu://join?ws=AndroidShare_4821&wk=a3f91c7e5b2d&h=192.168.62.1'
      '&p=47800&r=room-qr&c=4827&n=7&name=Ruta',
    );

    expect(read.dataOrNull, invite.copyWith(wifi: wifi));
  });
}
