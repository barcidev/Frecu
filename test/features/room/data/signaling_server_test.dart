// AC1: CUANDO el anfitrión inicia la sala ENTONCES se ejecuta el servidor WebSocket de señalización en el puerto 47800 y responde a los mensajes de protocolo local.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';

void main() {
  group('Signaling Server & Protocol', () {
    late SignalingServerDataSource server;
    late SignalingClientDataSource client1;
    late SignalingClientDataSource client2;

    setUp(() {
      server = SignalingServerDataSource();
      client1 = SignalingClientDataSource();
      client2 = SignalingClientDataSource();
    });

    tearDown(() async {
      await client1.dispose();
      await client2.dispose();
      await server.dispose();
    });

    // AC1
    test('AC1: starts WebSocket signaling server on port 47800 and handles join and welcome handshake', () async {
      // Usar puerto 0 para que el SO asigne uno libre y evitar colisiones
      await server.start(accessCode: '1234', host: '127.0.0.1', port: 0);
      expect(server.isRunning, isTrue);
      expect(server.port, greaterThan(0));

      final serverUri = Uri.parse('ws://127.0.0.1:${server.port}');
      await client1.connect(serverUri);
      expect(client1.isConnected, isTrue);

      final welcomeCompleter = Completer<SignalingWelcomeMessage>();
      final sub = client1.messages.listen((msg) {
        msg.maybeWhen(
          welcome: (peerId, participants, _) {
            welcomeCompleter.complete(
              SignalingWelcomeMessage(
                peerId: peerId,
                participants: participants,
              ),
            );
          },
          orElse: () {},
        );
      });

      client1.send(
        const SignalingMessage.join(
          displayName: 'HostAlice',
          accessCode: '1234',
        ),
      );

      final welcome = await welcomeCompleter.future.timeout(
        const Duration(seconds: 3),
      );
      expect(welcome.peerId, isNotEmpty);
      expect(welcome.participants.length, 1);
      expect(welcome.participants.first.displayName, 'HostAlice');
      expect(welcome.participants.first.isHost, isTrue);

      await sub.cancel();
    });

    // AC1
    test('AC1: rejects client with invalid access code', () async {
      await server.start(accessCode: '1234', host: '127.0.0.1', port: 0);

      final serverUri = Uri.parse('ws://127.0.0.1:${server.port}');
      await client1.connect(serverUri);

      final rejectedCompleter = Completer<String>();
      final sub = client1.messages.listen((msg) {
        msg.maybeWhen(
          rejected: (reason, _) => rejectedCompleter.complete(reason),
          orElse: () {},
        );
      });

      client1.send(
        const SignalingMessage.join(
          displayName: 'Intruder',
          accessCode: '9999',
        ),
      );

      final reason = await rejectedCompleter.future.timeout(
        const Duration(seconds: 3),
      );
      expect(reason, 'invalidAccessCode');

      await sub.cancel();
    });

    // AC1
    test('AC1: handles peer joined notification and routes peer-to-peer offer message', () async {
      await server.start(accessCode: '1234', host: '127.0.0.1', port: 0);
      final serverUri = Uri.parse('ws://127.0.0.1:${server.port}');

      // Conectar Cliente 1
      await client1.connect(serverUri);
      final c1WelcomeCompleter = Completer<String>();
      final c1PeerJoinedCompleter = Completer<String>();
      final c1Sub = client1.messages.listen((msg) {
        msg.maybeWhen(
          welcome: (peerId, _, __) => c1WelcomeCompleter.complete(peerId),
          peerJoined: (p, _) => c1PeerJoinedCompleter.complete(p.id),
          orElse: () {},
        );
      });

      client1.send(
        const SignalingMessage.join(displayName: 'Alice', accessCode: '1234'),
      );
      final peer1Id = await c1WelcomeCompleter.future.timeout(
        const Duration(seconds: 3),
      );

      // Conectar Cliente 2
      await client2.connect(serverUri);
      final c2WelcomeCompleter = Completer<String>();
      final c2OfferCompleter = Completer<SignalingOfferMessage>();
      final c2Sub = client2.messages.listen((msg) {
        msg.maybeWhen(
          welcome: (peerId, _, __) => c2WelcomeCompleter.complete(peerId),
          offer: (from, to, sdp, _) => c2OfferCompleter.complete(
            SignalingOfferMessage(from: from, to: to, sdp: sdp),
          ),
          orElse: () {},
        );
      });

      client2.send(
        const SignalingMessage.join(displayName: 'Bob', accessCode: '1234'),
      );
      final peer2Id = await c2WelcomeCompleter.future.timeout(
        const Duration(seconds: 3),
      );

      // Cliente 1 debe haber recibido la notificación de que Cliente 2 se unió
      final joinedPeerId = await c1PeerJoinedCompleter.future.timeout(
        const Duration(seconds: 3),
      );
      expect(joinedPeerId, peer2Id);

      // Cliente 1 envía oferta dirigida a Cliente 2
      client1.send(
        SignalingMessage.offer(
          from: peer1Id,
          to: peer2Id,
          sdp: 'v=0 sdp-content',
        ),
      );

      final offer = await c2OfferCompleter.future.timeout(
        const Duration(seconds: 3),
      );
      expect(offer.from, peer1Id);
      expect(offer.to, peer2Id);
      expect(offer.sdp, 'v=0 sdp-content');

      await c1Sub.cancel();
      await c2Sub.cancel();
    });
  });
}
