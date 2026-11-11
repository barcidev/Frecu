// AC8: CUANDO el anfitrión de una frecu local en una Wi-Fi compartida deja de responder ENTONCES cada invitado lo reintenta y sigue la sucesión en orden. Todo `join` lleva el turno que conoce, y un servidor con un turno menor lo rechaza con `stale_term`.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';

/// Un teléfono conectado al servidor, con todo lo que recibe.
class _Peer {
  _Peer(this.client) {
    _sub = client.messages.listen(received.add);
  }

  final SignalingClientDataSource client;
  final List<SignalingMessage> received = [];
  late final StreamSubscription<SignalingMessage> _sub;

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

  /// Abre la frecu de Andrés con el turno [term], como quien la tomó.
  Future<void> start({required int term}) async {
    server.succession.configure(
      reach: RoomReach.local,
      hostOwnsNetwork: false,
      hostAddress: '127.0.0.1',
      term: term,
    );
    await server.start(
      accessCode: '4821',
      roomName: 'Ruta 40',
      host: '127.0.0.1',
      port: 0,
    );
  }

  /// Envía un `join` con el turno [term] y espera la respuesta: el
  /// `welcome` o el `rejected`.
  Future<SignalingMessage> join(String name, {int? term}) async {
    final peer = _Peer(SignalingClientDataSource());
    peers.add(peer);
    await peer.client.connect(Uri.parse('ws://127.0.0.1:${server.port}'));
    peer.client.send(
      SignalingMessage.join(displayName: name, accessCode: '4821', term: term),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(deadline)) {
      final answer = peer.received
          .where(
            (m) => m is SignalingWelcomeMessage || m is SignalingRejectedMessage,
          )
          .firstOrNull;
      if (answer != null) return answer;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw TimeoutException('No answer to the join of $name');
  }

  group('AC8: turno en el join', () {
    test('AC8: el join lleva el turno que conoce y, sin él, no lo envía', () {
      final withTerm = const SignalingMessage.join(
        displayName: 'Ana',
        accessCode: '4821',
        peerId: 'peer_2',
        term: 3,
      ).toJson();
      expect(withTerm['term'], 3);
      expect(SignalingMessage.fromJson(withTerm), isA<SignalingJoinMessage>());
      expect(
        (SignalingMessage.fromJson(withTerm) as SignalingJoinMessage).term,
        3,
      );

      final without = const SignalingMessage.join(
        displayName: 'Ana',
        accessCode: '4821',
      ).toJson();
      expect(without.containsKey('term'), isFalse);
      expect(
        (SignalingMessage.fromJson(without) as SignalingJoinMessage).term,
        isNull,
      );
    });

    test('AC8: un servidor con un turno menor rechaza el join con '
        'stale_term', () async {
      await start(term: 2);

      final answer = await join('Leo', term: 3);

      expect(answer, isA<SignalingRejectedMessage>());
      expect(
        (answer as SignalingRejectedMessage).reason,
        RejectReason.staleTerm,
      );
      expect(RejectReason.staleTerm, 'stale_term');
      expect(server.participants, isEmpty);
    });

    test('AC8: con el mismo turno, uno menor o sin turno (una app anterior) '
        'se entra como hoy', () async {
      await start(term: 2);

      expect(await join('Andrés', term: 2), isA<SignalingWelcomeMessage>());
      expect(await join('Ana', term: 1), isA<SignalingWelcomeMessage>());
      expect(await join('Leo'), isA<SignalingWelcomeMessage>());
      expect(server.participants, hasLength(3));
    });
  });
}
