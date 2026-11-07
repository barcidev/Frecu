import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

void main() {
  group('SignalingMessage protocol serialization', () {
    T roundTrip<T extends SignalingMessage>(T message) {
      final jsonString = jsonEncode(message.toJson());
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return SignalingMessage.fromJson(map) as T;
    }

    test('AC1: serializes and deserializes all message variants', () {
      const join = SignalingMessage.join(
        displayName: 'Bob',
        accessCode: '1234',
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

    test('AC1: welcome message serializes RoomNote and deserializes without note for v=1 backward compatibility', () {
      const participant = Participant(id: 'peer-1', displayName: 'Alice');
      const note = RoomNote(semitone: 16);
      const welcomeWithNote = SignalingMessage.welcome(
        peerId: 'peer-2',
        participants: [participant],
        note: note,
      );
      final json = welcomeWithNote.toJson();
      expect(json['note'], 16);
      expect(roundTrip(welcomeWithNote), welcomeWithNote);

      final legacyJson = {
        'type': 'welcome',
        'peerId': 'peer-3',
        'participants': [
          {'id': 'peer-1', 'displayName': 'Alice', 'isHost': true},
        ],
      };
      SignalingMessage.fromJson(legacyJson).maybeWhen(
        welcome: (peerId, participants, deserializedNote, _) {
          expect(peerId, 'peer-3');
          expect(deserializedNote, isNull);
        },
        orElse: () => fail('Se esperaba SignalingWelcomeMessage'),
      );

      final nullNoteJson = {
        'type': 'welcome',
        'peerId': 'peer-4',
        'participants': <Map<String, dynamic>>[],
        'note': null,
      };
      SignalingMessage.fromJson(nullNoteJson).maybeWhen(
        welcome: (peerId, participants, deserializedNote, _) {
          expect(deserializedNote, isNull);
        },
        orElse: () => fail('Se esperaba SignalingWelcomeMessage'),
      );

      final invalidNoteJson = {
        'type': 'welcome',
        'peerId': 'peer-5',
        'participants': <Map<String, dynamic>>[],
        'note': 99,
      };
      SignalingMessage.fromJson(invalidNoteJson).maybeWhen(
        welcome: (peerId, participants, deserializedNote, _) {
          expect(deserializedNote, isNull);
        },
        orElse: () => fail('Se esperaba SignalingWelcomeMessage'),
      );
    });

    test('AC5: protocolo.md documents additive note in welcome message maintaining v=1', () {
      final docFile = File('docs/protocolo.md');
      expect(docFile.existsSync(), isTrue);
      final content = docFile.readAsStringSync();
      expect(content, contains('welcome'));
      expect(content, contains('note'));
    });
  });
}
