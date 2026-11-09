// AC1: CUANDO el usuario conmuta la salida de audio entre altavoz, auricular y Bluetooth ENTONCES la sesión de audio redirige la salida al dispositivo seleccionado y actualiza el icono de ruta de audio en tiempo real.
// AC2: CUANDO se conecta o desconecta un accesorio de audio (auriculares cableados o Bluetooth) ENTONCES el sistema detecta el cambio de periférico y actualiza la ruta de audio activa.
// AC3: CUANDO un participante silencia su micrófono ENTONCES se desactiva la pista local de audio (`track.enabled = false`) sin renegociar la sesión WebRTC y se notifica a la sala el cese de habla.
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/voice_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:mocktail/mocktail.dart';

class MockSignalingClientDataSource extends Mock
    implements SignalingClientDataSource {}

class MockAudioSessionDataSource extends Mock
    implements AudioSessionDataSource {}

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
    registerFallbackValue(AudioRoute.speaker);
  });

  group('VoiceRepository integration', () {
    late MockSignalingClientDataSource mockSignaling;
    late MockAudioSessionDataSource mockAudioSession;
    late MockRTCPeerConnection mockPc;
    late MockMediaStream mockStream;
    late MockMediaStreamTrack mockAudioTrack;
    late StreamController<SignalingMessage> signalingStreamController;
    late List<SignalingMessage> sentMessages;
    late Map<String, dynamic> capturedPcConfig;
    var isTrackEnabled = false;

    setUp(() {
      mockSignaling = MockSignalingClientDataSource();
      mockAudioSession = MockAudioSessionDataSource();
      mockPc = MockRTCPeerConnection();
      mockStream = MockMediaStream();
      mockAudioTrack = MockMediaStreamTrack();
      signalingStreamController =
          StreamController<SignalingMessage>.broadcast();
      sentMessages = [];
      capturedPcConfig = {};
      isTrackEnabled = false;

      when(() => mockSignaling.messages)
          .thenAnswer((_) => signalingStreamController.stream);
      when(() => mockSignaling.connectionState)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => mockSignaling.send(any())).thenAnswer((invocation) {
        sentMessages.add(invocation.positionalArguments[0] as SignalingMessage);
      });

      when(() => mockAudioSession.activate()).thenAnswer((_) async {});
      when(() => mockAudioSession.deactivate()).thenAnswer((_) async {});
      when(() => mockAudioSession.devicesStream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockAudioSession.getDevices())
          .thenAnswer((_) async => <AudioDevice>{});
      when(() => mockAudioSession.setSpeakerphoneOn(any()))
          .thenAnswer((_) async {});
      when(() => mockAudioSession.setSpeakerphoneOnButPreferBluetooth())
          .thenAnswer((_) async {});

      when(() => mockAudioTrack.enabled).thenAnswer((_) => isTrackEnabled);
      when(() => mockAudioTrack.enabled = any()).thenAnswer((invocation) {
        return isTrackEnabled = invocation.positionalArguments[0] as bool;
      });
      when(() => mockAudioTrack.stop()).thenAnswer((_) async {});

      when(() => mockStream.getTracks()).thenReturn([mockAudioTrack]);
      when(() => mockStream.getAudioTracks()).thenReturn([mockAudioTrack]);
      when(() => mockStream.dispose()).thenAnswer((_) async {});

      when(() => mockPc.addTrack(any(), any()))
          .thenAnswer((_) async => MockRTCRtpSender());
      when(() => mockPc.createOffer(any()))
          .thenAnswer((_) async => RTCSessionDescription('offer_sdp', 'offer'));
      when(
        () => mockPc.createAnswer(any()),
      ).thenAnswer((_) async => RTCSessionDescription('answer_sdp', 'answer'));
      when(() => mockPc.setLocalDescription(any())).thenAnswer((_) async {});
      when(() => mockPc.setRemoteDescription(any())).thenAnswer((_) async {});
      when(() => mockPc.addCandidate(any())).thenAnswer((_) async {});
      when(() => mockPc.close()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await signalingStreamController.close();
    });

    PeerConnectionDataSource createPeerConnectionDataSource() {
      return PeerConnectionDataSource(
        signalingClient: mockSignaling,
        peerConnectionFactory: (config) async {
          capturedPcConfig = config;
          return mockPc;
        },
        userMediaFactory: (_) async => mockStream,
      );
    }

    VoiceRepositoryImpl createRepository(PeerConnectionDataSource pcDs) {
      return VoiceRepositoryImpl(
        audioSessionDataSource: mockAudioSession,
        peerConnectionDataSource: pcDs,
        signalingClientDataSource: mockSignaling,
        permissionRequester: () async => true,
      );
    }

    // AC1
    test(
      'AC1: establishes peer connection on welcome message without STUN/TURN',
      () async {
        final pcDataSource = createPeerConnectionDataSource();
        final repository = createRepository(pcDataSource);

        final initResult = await repository.initializeAudio();
        expect(initResult.isSuccess, isTrue);

        const host = Participant(
          id: 'host_peer_1',
          displayName: 'Anfitrión',
          isHost: true,
        );

        signalingStreamController.add(
          const SignalingMessage.welcome(
            peerId: 'joining_peer_2',
            participants: [host],
          ),
        );

        await pumpEventQueue();

        expect(capturedPcConfig['iceServers'], isEmpty);
        verify(() => mockPc.createOffer(any())).called(1);
        verify(() => mockPc.setLocalDescription(any())).called(1);

        final offerMsg = sentMessages.whereType<SignalingOfferMessage>().first;
        expect(offerMsg.from, 'joining_peer_2');
        expect(offerMsg.to, 'host_peer_1');
        expect(offerMsg.sdp, 'offer_sdp');

        signalingStreamController
          ..add(
            const SignalingMessage.answer(
              from: 'host_peer_1',
              to: 'joining_peer_2',
              sdp: 'answer_sdp',
            ),
          )
          ..add(
            const SignalingMessage.ice(
              from: 'host_peer_1',
              to: 'joining_peer_2',
              candidate: 'candidate:1 1 UDP ...',
            ),
          );

        await pumpEventQueue();

        verify(() => mockPc.setRemoteDescription(any())).called(1);
        verify(() => mockPc.addCandidate(any())).called(1);

        await repository.dispose();
      },
    );

    // AC1
    test('AC1: welcome message with multiple existing participants creates offers to all peers', () async {
      final pcDataSource = createPeerConnectionDataSource();
      final repository = createRepository(pcDataSource);

      await repository.initializeAudio();

      const participants = [
        Participant(id: 'peer_1', displayName: 'P1', isHost: true),
        Participant(id: 'peer_2', displayName: 'P2'),
        Participant(id: 'peer_3', displayName: 'P3'),
        Participant(id: 'peer_4', displayName: 'P4'),
        Participant(id: 'peer_5', displayName: 'P5'),
      ];

      signalingStreamController.add(
        const SignalingMessage.welcome(
          peerId: 'peer_6',
          participants: participants,
        ),
      );

      await pumpEventQueue();

      final offerMsgs = sentMessages
          .whereType<SignalingOfferMessage>()
          .toList();
      expect(offerMsgs.length, 5);
      expect(offerMsgs.map((m) => m.to).toSet(), {
        'peer_1',
        'peer_2',
        'peer_3',
        'peer_4',
        'peer_5',
      });
      for (final msg in offerMsgs) {
        expect(msg.from, 'peer_6');
      }

      await repository.dispose();
    });

    // AC2
    test(
      'AC2: startTalking (PTT) enables audio track and sends talk_state true',
      () async {
        final pcDataSource = createPeerConnectionDataSource();
        final repository = createRepository(pcDataSource);

        await repository.joinMesh(localPeerId: 'my_peer_id', peerIds: const []);

        final startResult = await repository.startTalking();
        expect(startResult.isSuccess, isTrue);
        expect(isTrackEnabled, isTrue);

        final talkStateMsgs = sentMessages
            .whereType<SignalingTalkStateMessage>()
            .toList();
        expect(talkStateMsgs.isNotEmpty, isTrue);
        expect(talkStateMsgs.last.peerId, 'my_peer_id');
        expect(talkStateMsgs.last.isSpeaking, isTrue);

        expect(await repository.watchIsTalking().first, isTrue);

        signalingStreamController.add(
          const SignalingMessage.talkState(
            peerId: 'remote_peer_1',
            isSpeaking: true,
          ),
        );

        await pumpEventQueue();

        final speaking = await repository.watchSpeakingPeers().first;
        expect(speaking.contains('remote_peer_1'), isTrue);

        await repository.dispose();
      },
    );

    // AC3
    test(
      'AC3: stopTalking disables audio track without renegotiating',
      () async {
        final pcDataSource = createPeerConnectionDataSource();
        final repository = createRepository(pcDataSource);

        await repository.joinMesh(localPeerId: 'my_peer_id', peerIds: const []);
        await repository.startTalking();
        expect(isTrackEnabled, isTrue);

        sentMessages.clear();
        clearInteractions(mockPc);

        final stopResult = await repository.stopTalking();
        expect(stopResult.isSuccess, isTrue);
        expect(isTrackEnabled, isFalse);

        verifyNever(() => mockPc.createOffer(any()));
        verifyNever(() => mockPc.createAnswer(any()));

        final talkStateMsgs = sentMessages
            .whereType<SignalingTalkStateMessage>()
            .toList();
        expect(talkStateMsgs.isNotEmpty, isTrue);
        expect(talkStateMsgs.last.isSpeaking, isFalse);
        expect(await repository.watchIsTalking().first, isFalse);

        await repository.dispose();
      },
    );

    // AC1
    test('AC1: setAudioRoute switches audio routing between speaker, earpiece and bluetooth', () async {
      final pcDataSource = createPeerConnectionDataSource();
      final repository = createRepository(pcDataSource);

      final resSpeaker = await repository.setAudioRoute(AudioRoute.speaker);
      expect(resSpeaker.isSuccess, isTrue);
      expect(await repository.watchAudioRoute().first, AudioRoute.speaker);
      verify(() => mockAudioSession.setSpeakerphoneOn(true)).called(1);

      final resEarpiece = await repository.setAudioRoute(AudioRoute.earpiece);
      expect(resEarpiece.isSuccess, isTrue);
      expect(await repository.watchAudioRoute().first, AudioRoute.earpiece);
      verify(() => mockAudioSession.setSpeakerphoneOn(false)).called(1);

      final resBt = await repository.setAudioRoute(AudioRoute.bluetooth);
      expect(resBt.isSuccess, isTrue);
      expect(await repository.watchAudioRoute().first, AudioRoute.bluetooth);
      verify(() => mockAudioSession.setSpeakerphoneOnButPreferBluetooth())
          .called(1);

      await repository.dispose();
    });

    // AC2
    test(
      'AC2: audio accessory disconnect triggers safe fallback to speaker route',
      () async {
        final devicesController =
            StreamController<Set<AudioDevice>>.broadcast();
        when(() => mockAudioSession.devicesStream)
            .thenAnswer((_) => devicesController.stream);

        final pcDataSource = createPeerConnectionDataSource();
        final repository = createRepository(pcDataSource);

        await repository.setAudioRoute(AudioRoute.bluetooth);
        expect(await repository.watchAudioRoute().first, AudioRoute.bluetooth);

        // Accessory disconnected: stream emits device set without bluetooth
        devicesController.add({
          AudioDevice(
            id: 'speaker',
            name: 'Speaker',
            type: AudioDeviceType.builtInSpeaker,
            isInput: false,
            isOutput: true,
          ),
        });
        await pumpEventQueue();

        // Safe fallback to speaker
        expect(await repository.watchAudioRoute().first, AudioRoute.speaker);

        await devicesController.close();
        await repository.dispose();
      },
    );
  });
}
