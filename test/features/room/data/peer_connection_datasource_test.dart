// AC1: CUANDO hasta 6 participantes se unen a la frecu ENTONCES cada nuevo participante negocia y establece una conexión WebRTC independiente con todos los participantes ya presentes en la sala formando una malla completa (mesh).
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:mocktail/mocktail.dart';

class MockSignalingClientDataSource extends Mock
    implements SignalingClientDataSource {}

class MockRTCPeerConnection extends Mock implements RTCPeerConnection {}

class MockMediaStream extends Mock implements MediaStream {}

class MockMediaStreamTrack extends Mock implements MediaStreamTrack {}

class MockRTCRtpSender extends Mock implements RTCRtpSender {}

class FakeMediaStreamTrack extends Fake implements MediaStreamTrack {}

class FakeMediaStream extends Fake implements MediaStream {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SignalingMessage.ping(timestamp: 0));
    registerFallbackValue(RTCSessionDescription('sdp', 'offer'));
    registerFallbackValue(RTCIceCandidate('candidate', '0', 0));
    registerFallbackValue(FakeMediaStreamTrack());
    registerFallbackValue(FakeMediaStream());
  });

  group('PeerConnectionDataSource multi-peer mesh', () {
    late MockSignalingClientDataSource mockSignaling;
    late MockMediaStream mockStream;
    late MockMediaStreamTrack mockAudioTrack;
    late StreamController<SignalingMessage> signalingStreamController;
    late List<SignalingMessage> sentMessages;
    late Map<String, MockRTCPeerConnection> mockPcs;
    var isTrackEnabled = false;

    setUp(() {
      mockSignaling = MockSignalingClientDataSource();
      mockStream = MockMediaStream();
      mockAudioTrack = MockMediaStreamTrack();
      signalingStreamController =
          StreamController<SignalingMessage>.broadcast();
      sentMessages = [];
      mockPcs = {};
      isTrackEnabled = false;

      when(() => mockSignaling.messages)
          .thenAnswer((_) => signalingStreamController.stream);
      when(() => mockSignaling.send(any())).thenAnswer((invocation) {
        sentMessages.add(invocation.positionalArguments[0] as SignalingMessage);
      });

      when(() => mockAudioTrack.enabled).thenAnswer((_) => isTrackEnabled);
      when(() => mockAudioTrack.enabled = any()).thenAnswer((invocation) {
        return isTrackEnabled = invocation.positionalArguments[0] as bool;
      });
      when(() => mockAudioTrack.stop()).thenAnswer((_) async {});

      when(() => mockStream.getTracks()).thenReturn([mockAudioTrack]);
      when(() => mockStream.getAudioTracks()).thenReturn([mockAudioTrack]);
      when(() => mockStream.dispose()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await signalingStreamController.close();
    });

    MockRTCPeerConnection createMockPc(String peerId) {
      final pc = MockRTCPeerConnection();
      mockPcs[peerId] = pc;

      when(() => pc.addTrack(any(), any()))
          .thenAnswer((_) async => MockRTCRtpSender());
      when(() => pc.createOffer(any())).thenAnswer(
        (_) async => RTCSessionDescription('offer_for_$peerId', 'offer'),
      );
      when(() => pc.createAnswer(any())).thenAnswer(
        (_) async => RTCSessionDescription('answer_for_$peerId', 'answer'),
      );
      when(() => pc.setLocalDescription(any())).thenAnswer((_) async {});
      when(() => pc.setRemoteDescription(any())).thenAnswer((_) async {});
      when(() => pc.addCandidate(any())).thenAnswer((_) async {});
      when(pc.close).thenAnswer((_) async {});

      return pc;
    }

    PeerConnectionDataSource createDataSource() {
      return PeerConnectionDataSource(
        signalingClient: mockSignaling,
        peerConnectionFactory: (config) async {
          expect(config['iceServers'], isEmpty);
          final peerIndex = mockPcs.length + 1;
          return createMockPc('peer_$peerIndex');
        },
        userMediaFactory: (_) async => mockStream,
      );
    }

    test('AC1: manages up to 5 concurrent peer connections, sends offers and tracks, and handles answers and ice candidates', () async {
      final ds = createDataSource()..attach('peer_local');
      await ds.prepareMedia(capture: true);

      // Conectar a 5 participantes remotos (malla de 6 participantes en total)
      for (var i = 1; i <= 5; i++) {
        await ds.connectToPeer('peer_$i');
      }

      expect(ds.peerConnections.length, 5);

      // Verificar que cada una de las 5 conexiones creó oferta y la envió
      final offers = sentMessages.whereType<SignalingOfferMessage>().toList();
      expect(offers.length, 5);
      for (var i = 1; i <= 5; i++) {
        expect(offers.any((o) => o.to == 'peer_$i'), isTrue);
      }

      // Simular respuestas (answer) de todos los pares
      for (var i = 1; i <= 5; i++) {
        signalingStreamController.add(
          SignalingMessage.answer(
            from: 'peer_$i',
            to: 'peer_local',
            sdp: 'answer_from_$i',
          ),
        );
      }
      await pumpEventQueue();

      // Enviar candidatos ICE hacia los pares remotos
      for (final entry in mockPcs.entries) {
        entry.value.onIceCandidate?.call(RTCIceCandidate('cand_data', '0', 0));
      }
      final iceMessages = sentMessages
          .whereType<SignalingIceMessage>()
          .toList();
      expect(iceMessages.length, 5);

      // Simular que un participante sale (peerLeft)
      signalingStreamController.add(
        const SignalingMessage.peerLeft(peerId: 'peer_3'),
      );
      await pumpEventQueue();

      expect(ds.peerConnections.containsKey('peer_3'), isFalse);
      expect(ds.peerConnections.length, 4);

      await ds.dispose();
      expect(ds.peerConnections.isEmpty, isTrue);
    });
  });
}
