// C1: CUANDO hay URL del punto de encuentro ENTONCES los sockets van por wss (o ws en local) con el id de la frecu.
// C2: CUANDO se invita por enlace ENTONCES el código va en el fragmento, que no llega al servidor.
// C3: CUANDO se crea una frecu por internet ENTONCES su id es de 128 bits en hexadecimal.
// C4: CUANDO llegan servidores ICE del punto de encuentro ENTONCES se leen con `urls` en texto o en lista.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/features/room/data/datasources/turn_credentials_datasource.dart';

void main() {
  const config = CloudConfig('https://frecu.example.workers.dev/');

  test('C1: sockets use wss with the room id', () {
    expect(
      config.hostSocket('ab', 's3').toString(),
      'wss://frecu.example.workers.dev/rooms/ab/host?secret=s3',
    );
    expect(
      config.guestSocket('ab').toString(),
      'wss://frecu.example.workers.dev/rooms/ab/guest',
    );
    expect(
      const CloudConfig('http://127.0.0.1:8787').guestSocket('ab').toString(),
      'ws://127.0.0.1:8787/rooms/ab/guest',
    );
    expect(CloudConfig.disabled.isEnabled, isFalse);
  });

  test('C2: the invite link keeps the code in the fragment', () {
    final link = config.inviteLink('ab', {'c': '1234'});

    expect(link.path, '/j/ab');
    expect(link.query, isEmpty);
    expect(link.fragment, 'c=1234');
  });

  test('C3: room ids are 128-bit hex', () {
    final id = CloudConfig.newRoomId();

    expect(CloudConfig.isRoomId(id), isTrue);
    expect(CloudConfig.newRoomId(), isNot(id));
    expect(CloudConfig.isRoomId('ABC'), isFalse);
  });

  test('C4: ICE servers parse with string or list urls', () {
    final servers = TurnCredentialsDataSource.parse(
      '{"iceServers":[{"urls":"stun:stun.cloudflare.com:3478"},'
      '{"urls":["turn:turn.cloudflare.com:3478?transport=udp"],'
      '"username":"u","credential":"p"},{"urls":42}]}',
    );

    expect(servers, hasLength(2));
    expect(servers.last.username, 'u');
    expect(servers.last.urls.single, startsWith('turn:'));
    expect(TurnCredentialsDataSource.parse('nope'), isEmpty);
  });
}
