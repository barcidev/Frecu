// F12: CUANDO un socket no hizo `join` ENTONCES el servidor no enruta nada suyo; CUANDO un participante manda offer, answer, ICE o `talk_state` ENTONCES el remitente es siempre el id que el servidor le asignó; CUANDO el `join` habla otra versión ENTONCES lo rechaza con `versionMismatch`; CUANDO una dirección acumula 5 códigos incorrectos ENTONCES queda bloqueada; el tope sigue en 6.
// F4: CUANDO se abre una frecu con el servidor de otra aún en marcha ENTONCES el servidor se reinicia con el código y el nombre nuevos.
// F9: CUANDO alguien se une ENTONCES el `welcome` lleva el nombre de la frecu.
// F8: CUANDO el anfitrión no responde ENTONCES conectar se rinde en el límite de tiempo sin dar la conexión por abierta.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';

/// Un participante conectado al servidor, con todo lo que recibe.
class _Peer {
  _Peer(this.client) {
    _sub = client.messages.listen(received.add);
  }

  final SignalingClientDataSource client;
  final List<SignalingMessage> received = [];
  late final StreamSubscription<SignalingMessage> _sub;
  String? id;

  Iterable<T> of<T extends SignalingMessage>() => received.whereType<T>();

  Future<void> close() async {
    await _sub.cancel();
    await client.dispose();
  }
}

void main() {
  late SignalingServerDataSource server;
  final peers = <_Peer>[];

  setUp(() => server = SignalingServerDataSource());

  tearDown(() async {
    for (final peer in peers) {
      await peer.close();
    }
    peers.clear();
    await server.dispose();
  });

  Future<void> start({String code = '4821', String? name = 'Ruta 40'}) => server
      .start(accessCode: code, roomName: name, host: '127.0.0.1', port: 0);

  Future<_Peer> connect() async {
    final peer = _Peer(SignalingClientDataSource());
    peers.add(peer);
    await peer.client.connect(Uri.parse('ws://127.0.0.1:${server.port}'));
    return peer;
  }

  /// Espera hasta [limit] a que [peer] reciba un [T].
  Future<T> next<T extends SignalingMessage>(
    _Peer peer, {
    Duration limit = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(limit);
    while (DateTime.now().isBefore(deadline)) {
      final found = peer.of<T>();
      if (found.isNotEmpty) return found.last;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw TimeoutException('No $T for ${peer.id}');
  }

  Future<_Peer> join(
    String name, {
    String code = '4821',
    int version = signalingProtocolVersion,
  }) async {
    final peer = await connect();
    peer.client.send(
      SignalingMessage.join(
        displayName: name,
        accessCode: code,
        protocolVersion: version,
      ),
    );
    final welcome = await next<SignalingWelcomeMessage>(peer);
    peer.id = welcome.peerId;
    return peer;
  }

  Future<String> rejection(_Peer peer) async =>
      (await next<SignalingRejectedMessage>(peer)).reason;

  test('F9: el welcome lleva el nombre de la frecu', () async {
    await start();
    final ana = await join('Ana');
    expect(ana.of<SignalingWelcomeMessage>().single.roomName, 'Ruta 40');
  });

  test('F12: antes del join no se enruta nada de ese socket', () async {
    await start();
    final ana = await join('Ana');
    final stranger = await connect();

    stranger.client
      ..send(SignalingMessage.offer(from: 'peer_9', to: ana.id!, sdp: 'x'))
      ..send(SignalingMessage.ice(from: 'peer_9', to: ana.id!, candidate: 'c'))
      ..send(SignalingMessage.talkState(peerId: ana.id!, isSpeaking: true));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(ana.of<SignalingOfferMessage>(), isEmpty);
    expect(ana.of<SignalingIceMessage>(), isEmpty);
    expect(ana.of<SignalingTalkStateMessage>(), isEmpty);
    expect(server.participants, hasLength(1));
  });

  test('F12: el remitente de offer, answer, ICE y talk_state es el id del '
      'socket, no el que dice el mensaje', () async {
    await start();
    final ana = await join('Ana');
    final leo = await join('Leo');
    final sofi = await join('Sofi');

    leo.client
      ..send(SignalingMessage.offer(from: sofi.id!, to: ana.id!, sdp: 'o'))
      ..send(SignalingMessage.answer(from: sofi.id!, to: ana.id!, sdp: 'a'))
      ..send(SignalingMessage.ice(from: sofi.id!, to: ana.id!, candidate: 'c'))
      ..send(SignalingMessage.talkState(peerId: sofi.id!, isSpeaking: true));

    expect((await next<SignalingOfferMessage>(ana)).from, leo.id);
    expect((await next<SignalingAnswerMessage>(ana)).from, leo.id);
    expect((await next<SignalingIceMessage>(ana)).from, leo.id);
    expect((await next<SignalingTalkStateMessage>(ana)).peerId, leo.id);
    expect((await next<SignalingTalkStateMessage>(sofi)).peerId, leo.id);
    expect(leo.of<SignalingTalkStateMessage>(), isEmpty);
  });

  test('F12: talk_state lleva el silencio del micrófono abierto', () async {
    await start();
    final ana = await join('Ana');
    final leo = await join('Leo');

    leo.client.send(
      SignalingMessage.talkState(
        peerId: leo.id!,
        isSpeaking: false,
        muted: true,
      ),
    );

    final talk = await next<SignalingTalkStateMessage>(ana);
    expect(talk.muted, isTrue);
    expect(talk.isSpeaking, isFalse);
  });

  test(
    'F12: un segundo join del mismo socket no crea otro participante',
    () async {
      await start();
      final ana = await join('Ana');
      ana.client.send(
        const SignalingMessage.join(displayName: 'Ana 2', accessCode: '4821'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(server.participants, hasLength(1));
      expect(ana.of<SignalingWelcomeMessage>(), hasLength(1));
    },
  );

  test('F12: rechaza una versión de protocolo incompatible', () async {
    await start();
    final old = await connect();
    old.client.send(
      const SignalingMessage.join(
        displayName: 'Futuro',
        accessCode: '4821',
        protocolVersion: signalingProtocolVersion + 1,
      ),
    );

    expect(await rejection(old), RejectReason.versionMismatch);
    expect(server.participants, isEmpty);
  });

  test('F12: tras 5 códigos incorrectos la dirección queda bloqueada, '
      'incluso con el código correcto', () async {
    await start();
    for (var attempt = 0; attempt < 5; attempt++) {
      final guess = await connect();
      guess.client.send(
        SignalingMessage.join(
          displayName: 'Intruso',
          accessCode: '000$attempt',
        ),
      );
      expect(await rejection(guess), RejectReason.invalidAccessCode);
    }

    final locked = await connect();
    locked.client.send(
      const SignalingMessage.join(displayName: 'Intruso', accessCode: '4821'),
    );
    expect(await rejection(locked), RejectReason.invalidAccessCode);
    expect(server.participants, isEmpty);
  });

  test('F12: el tope sigue en 6 personas', () async {
    await start();
    for (var i = 0; i < 6; i++) {
      await join('P$i');
    }
    final seventh = await connect();
    seventh.client.send(
      const SignalingMessage.join(displayName: 'P6', accessCode: '4821'),
    );
    expect(await rejection(seventh), RejectReason.roomFull);
  });

  test('F4: abrir otra frecu con el servidor en marcha lo reinicia con el '
      'código y el nombre nuevos', () async {
    await start(code: '1111', name: 'Vieja');
    final ana = await join('Ana', code: '1111');
    expect(server.participants, hasLength(1));

    await start(code: '2222', name: 'Nueva');

    // Quien estaba en la vieja se entera de que se cerró.
    expect((await next<SignalingRoomClosedMessage>(ana)).reason, isNotEmpty);
    expect(server.participants, isEmpty);

    final stale = await connect();
    stale.client.send(
      const SignalingMessage.join(displayName: 'Leo', accessCode: '1111'),
    );
    expect(await rejection(stale), RejectReason.invalidAccessCode);

    final leo = await join('Leo', code: '2222');
    expect(leo.of<SignalingWelcomeMessage>().single.roomName, 'Nueva');
  });

  test('F8: conectar a quien no responde se rinde en el límite y no da la '
      'conexión por abierta', () async {
    // Acepta TCP pero nunca contesta el handshake de WebSocket.
    final silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <Socket>[];
    silent.listen(sockets.add);
    final client = SignalingClientDataSource(
      connectTimeout: const Duration(milliseconds: 200),
    );
    final states = <bool>[];
    final sub = client.connectionState.listen(states.add);

    final watch = Stopwatch()..start();
    await expectLater(
      client.connect(Uri.parse('ws://127.0.0.1:${silent.port}')),
      throwsA(isA<TimeoutException>()),
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(client.isConnected, isFalse);
    await pumpEventQueue();
    expect(states, isEmpty);

    await sub.cancel();
    await client.dispose();
    for (final socket in sockets) {
      socket.destroy();
    }
    await silent.close();
  });
}
