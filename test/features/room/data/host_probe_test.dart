// AC9: CUANDO, en una frecu local en una Wi-Fi compartida, el anfitrión anterior vuelve con su frecu abierta o dos teléfonos llevan la misma frecu a la vez ENTONCES cada anfitrión pregunta con `host_probe` (código, turno, su id y su puerto) en las IPs de quienes salieron de su sucesión, y quien responde con el código correcto devuelve su propio `host_probe`. Gana el turno mayor y, a igual turno, el `peer_N` menor; el otro avisa a sus invitados `host_handover` con el id, la IP y el puerto del ganador, cierra su servidor sin `room_closed` y entra como invitado al ganador. Un `host_probe` con el código incorrecto se rechaza como un `join` incorrecto.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/host_probe.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';

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

RoomMember _member(String id, String name, String address) => RoomMember(
  id: id,
  displayName: name,
  joinedAt: DateTime(2026, 11, 11, 16),
  address: address,
);

RoomSuccession _state(int term, List<RoomMember> members) => RoomSuccession(
  term: term,
  handover: true,
  name: 'Ruta 40',
  accessCode: '4821',
  members: members,
);

Future<void> _until(bool Function() done) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met in time');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('AC9: gana el turno mayor', () {
    test('AC9: gana el turno mayor y, a igual turno, el peer_N menor', () {
      expect(
        outranks(term: 2, host: 'peer_3', otherTerm: 1, otherHost: 'peer_1'),
        isTrue,
      );
      expect(
        outranks(term: 1, host: 'peer_1', otherTerm: 2, otherHost: 'peer_3'),
        isFalse,
      );
      expect(
        outranks(term: 2, host: 'peer_2', otherTerm: 2, otherHost: 'peer_3'),
        isTrue,
      );
      expect(
        outranks(term: 2, host: 'peer_9', otherTerm: 2, otherHost: 'peer_10'),
        isTrue,
      );
      expect(
        outranks(term: 2, host: 'peer_2', otherTerm: 2, otherHost: 'peer_2'),
        isFalse,
      );
    });
  });

  group('AC9: el servidor responde y cede', () {
    late SignalingServerDataSource server;
    final peers = <_Peer>[];

    setUp(() => server = SignalingServerDataSource(maxCodeAttempts: 1));

    tearDown(() async {
      for (final peer in peers) {
        await peer.close();
      }
      peers.clear();
      await server.dispose();
    });

    Future<_Peer> join(String name, {String code = '4821'}) async {
      final peer = _Peer(SignalingClientDataSource());
      peers.add(peer);
      await peer.client.connect(Uri.parse('ws://127.0.0.1:${server.port}'));
      peer.client.send(
        SignalingMessage.join(displayName: name, accessCode: code),
      );
      await _until(
        () => peer.received.any(
          (m) => m is SignalingWelcomeMessage || m is SignalingRejectedMessage,
        ),
      );
      return peer;
    }

    /// Abre la frecu de Andrés con el turno [term] y lo une como anfitrión.
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
      await join('Andrés');
    }

    test('AC9: responde host_probe con su turno, su id y su puerto; quien '
        'pregunta con un turno menor sabe que perdió', () async {
      await start(term: 2);
      final rivals = <HostRival>[];
      server.onRival = rivals.add;

      final rival = await HostProbe().ask(
        '127.0.0.1',
        server.port,
        accessCode: '4821',
        term: 1,
        host: 'peer_1',
        serverPort: 47800,
      );

      expect(rival, isNotNull);
      expect(rival!.host, 'peer_1');
      expect(rival.term, 2);
      expect(rival.address, '127.0.0.1');
      expect(rival.port, server.port);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(rivals, isEmpty);
    });

    test('AC9: si quien pregunta lo supera, el servidor lo avisa con la IP '
        'del socket y el puerto del mensaje', () async {
      await start(term: 1);
      final rivals = <HostRival>[];
      server.onRival = rivals.add;

      final rival = await HostProbe().ask(
        '127.0.0.1',
        server.port,
        accessCode: '4821',
        term: 2,
        host: 'peer_2',
        serverPort: 47801,
      );

      expect(rival, isNull);
      await _until(() => rivals.isNotEmpty);
      expect(rivals.single.host, 'peer_2');
      expect(rivals.single.term, 2);
      expect(rivals.single.address, '127.0.0.1');
      expect(rivals.single.port, 47801);
    });

    test('AC9: un host_probe con el código incorrecto se rechaza y cuenta '
        'para el bloqueo, como un join', () async {
      await start(term: 1);
      final probe = HostProbe();

      final rival = await probe.ask(
        '127.0.0.1',
        server.port,
        accessCode: '0000',
        term: 2,
        host: 'peer_2',
        serverPort: 47801,
      );

      expect(rival, isNull);
      final blocked = await join('Leo');
      expect(
        blocked.received.whereType<SignalingRejectedMessage>().single.reason,
        RejectReason.invalidAccessCode,
      );
      // No vuelve a preguntar en esa IP.
      probe.remember(
        _state(1, [
          _member('peer_1', 'Andrés', '192.168.1.20'),
          _member('peer_2', 'Ana', '127.0.0.1'),
        ]),
      );
      expect(
        probe.absent(_state(1, [_member('peer_1', 'Andrés', '192.168.1.20')])),
        isEmpty,
      );
    });

    test('AC9: yieldTo avisa host_handover con el id, el turno, la IP y el '
        'puerto del ganador, y se detiene sin room_closed', () async {
      await start(term: 1);
      final leo = await join('Leo');

      await server.yieldTo(
        const HostRival(
          host: 'peer_2',
          term: 2,
          address: '192.168.1.21',
          port: 47800,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final handover = leo.received
          .whereType<SignalingHostHandoverMessage>()
          .single;
      expect(handover.to, 'peer_2');
      expect(handover.term, 2);
      expect(handover.address, '192.168.1.21');
      expect(handover.port, 47800);
      expect(leo.received.whereType<SignalingRoomClosedMessage>(), isEmpty);
      expect(server.isRunning, isFalse);
    });
  });

  group('AC9: pregunta en las IPs de quienes salieron', () {
    test('AC9: solo las de quienes ya no están, sin la propia ni las de '
        'quienes siguen', () {
      final probe = HostProbe()
        ..remember(
          _state(1, [
            _member('peer_1', 'Andrés', '192.168.1.20'),
            _member('peer_2', 'Ana', '192.168.1.21'),
            _member('peer_3', 'Leo', '192.168.1.22'),
            _member('peer_4', 'Sofi', '192.168.1.23'),
          ]),
        );

      final now = _state(2, [
        _member('peer_2', 'Ana', '192.168.1.21'),
        _member('peer_3', 'Leo', '192.168.1.22'),
        // Sofi volvió con un id nuevo: su IP sigue en la frecu.
        _member('peer_5', 'Sofi', '192.168.1.23'),
      ]);

      expect(probe.absent(now), ['192.168.1.20']);
      probe.remember(null);
      expect(probe.absent(now), isEmpty);
    });

    test('AC9: mientras lleva la frecu pregunta cada poco y avisa al rival '
        'que lo supera, una sola vez', () async {
      final winner = SignalingServerDataSource();
      addTearDown(winner.dispose);
      winner.succession.configure(
        reach: RoomReach.local,
        hostOwnsNetwork: false,
        hostAddress: '127.0.0.1',
        term: 2,
      );
      await winner.start(accessCode: '4821', host: '127.0.0.1', port: 0);
      final ana = _Peer(SignalingClientDataSource());
      addTearDown(ana.close);
      await ana.client.connect(Uri.parse('ws://127.0.0.1:${winner.port}'));
      ana.client.send(
        const SignalingMessage.join(displayName: 'Ana', accessCode: '4821'),
      );
      await _until(() => ana.received.any((m) => m is SignalingWelcomeMessage));

      final probe =
          HostProbe(
            port: winner.port,
            interval: const Duration(milliseconds: 50),
          )..remember(
            _state(1, [
              _member('peer_1', 'Andrés', '192.168.1.20'),
              _member('peer_2', 'Ana', '127.0.0.1'),
            ]),
          );
      addTearDown(probe.stop);
      final rivals = <HostRival>[];
      probe.start(
        state: () => _state(1, [_member('peer_1', 'Andrés', '192.168.1.20')]),
        me: 'peer_1',
        serverPort: 47800,
        onRival: rivals.add,
      );

      await _until(() => rivals.isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(rivals.single.term, 2);
      expect(rivals.single.address, '127.0.0.1');
      expect(rivals.single.port, winner.port);
      expect(probe.running, isFalse);
    });
  });
}
