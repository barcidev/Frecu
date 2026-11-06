// AC1: CUANDO el anfitrión inicia la sala ENTONCES se ejecuta el servidor WebSocket de señalización en el puerto 47800 y responde a los mensajes de protocolo local.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';

void main() {
  group('SignalingMessage protocol serialization', () {
    T roundTrip<T extends SignalingMessage>(T message) {
      final jsonString = jsonEncode(message.toJson());
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return SignalingMessage.fromJson(map) as T;
    }

    // AC1
    test('AC1: serializes and deserializes all message variants', () {
      const join = SignalingMessage.join(
        displayName: 'Bob',
        accessCode: '1234',
        protocolVersion: 1,
      );
      expect(join.toJson()['type'], 'join');
      expect(roundTrip(join), join);

      const participant = Participant(id: 'peer-1', displayName: 'Alice');
      const welcome = SignalingMessage.welcome(
        peerId: 'peer-2',
        participants: [participant],
      );
      expect(welcome.toJson()['type'], 'welcome');
      expect(roundTrip(welcome), welcome);

      const rejected = SignalingMessage.rejected(reason: 'roomFull');
      expect(rejected.toJson()['type'], 'rejected');
      expect(roundTrip(rejected), rejected);

      const peerJoined = SignalingMessage.peerJoined(participant: participant);
      expect(peerJoined.toJson()['type'], 'peer_joined');
      expect(roundTrip(peerJoined), peerJoined);

      const peerLeft = SignalingMessage.peerLeft(peerId: 'peer-1');
      expect(peerLeft.toJson()['type'], 'peer_left');
      expect(roundTrip(peerLeft), peerLeft);

      const offer = SignalingMessage.offer(
        from: 'peer-1',
        to: 'peer-2',
        sdp: 'v=0...',
      );
      expect(offer.toJson()['type'], 'offer');
      expect(roundTrip(offer), offer);

      const answer = SignalingMessage.answer(
        from: 'peer-2',
        to: 'peer-1',
        sdp: 'v=0...',
      );
      expect(answer.toJson()['type'], 'answer');
      expect(roundTrip(answer), answer);

      const ice = SignalingMessage.ice(
        from: 'peer-1',
        to: 'peer-2',
        candidate: 'candidate:1...',
        sdpMid: '0',
        sdpMLineIndex: 0,
      );
      expect(ice.toJson()['type'], 'ice');
      expect(roundTrip(ice), ice);

      const talk = SignalingMessage.talkState(
        peerId: 'peer-1',
        isSpeaking: true,
      );
      expect(talk.toJson()['type'], 'talk_state');
      expect(roundTrip(talk), talk);

      const ping = SignalingMessage.ping(timestamp: 123456789);
      expect(ping.toJson()['type'], 'ping');
      expect(roundTrip(ping), ping);

      const pong = SignalingMessage.pong(timestamp: 123456789);
      expect(pong.toJson()['type'], 'pong');
      expect(roundTrip(pong), pong);

      const roomClosed = SignalingMessage.roomClosed(reason: 'host_left');
      expect(roomClosed.toJson()['type'], 'room_closed');
      expect(roundTrip(roomClosed), roomClosed);
    });
  });
}
