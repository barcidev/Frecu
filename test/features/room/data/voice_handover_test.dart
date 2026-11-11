// AC1: CUANDO se pierde el socket de señalización en una frecu con traspaso ENTONCES la voz sigue transmitiendo: el PTT presionado y el micrófono abierto siguen activos, los enlaces con los demás siguen abiertos (sin cerrar ni volver a ofrecer), y solo el anfitrión deja de verse hablando.
// AC2: CUANDO llega la sucesión con otro anfitrión (traspaso voluntario, por caída o por internet) ENTONCES se cierra solo el enlace de voz con el anfitrión anterior; los demás enlaces siguen sin renegociar.
// AC3: CUANDO se vuelve a la frecu con el mismo id tras perder al anfitrión ENTONCES no se rehace la malla, se anuncia el estado de habla propio y, si el micrófono abierto se había cortado, se retoma solo.
// AC4: CUANDO se vuelve a la frecu con un id nuevo (una reconexión normal, o el anfitrión anterior que vuelve como invitado) ENTONCES la voz cierra los enlaces del id viejo, ofrece a todos los presentes salvo a su id viejo y retoma el micrófono abierto; en PTT, si seguía transmitiendo, lo anuncia.
// AC5: CUANDO la frecu no tiene traspaso ENTONCES sin anfitrión no se transmite, como hoy, y al volver se retoma el micrófono abierto.
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/voice_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignaling extends Mock implements SignalingClientDataSource {}

class _MockAudioSession extends Mock implements AudioSessionDataSource {}

class _FakeTrack extends Fake implements MediaStreamTrack {
  @override
  bool enabled = true;

  @override
  Future<void> stop() async {}
}

class _FakeStream extends Fake implements MediaStream {
  _FakeStream(this.track);

  final _FakeTrack track;

  @override
  List<MediaStreamTrack> getAudioTracks() => [track];

  @override
  List<MediaStreamTrack> getTracks() => [track];

  @override
  Future<void> dispose() async {}
}

class _FakeSender extends Fake implements RTCRtpSender {}

class _FakePc extends Fake implements RTCPeerConnection {
  bool closed = false;

  @override
  dynamic Function(RTCIceCandidate candidate)? onIceCandidate;

  @override
  dynamic Function(RTCIceConnectionState state)? onIceConnectionState;

  @override
  Future<RTCSessionDescription> createOffer([
    Map<String, dynamic> constraints = const {},
  ]) async => RTCSessionDescription('offer-sdp', 'offer');

  @override
  Future<RTCSessionDescription> createAnswer([
    Map<String, dynamic> constraints = const {},
  ]) async => RTCSessionDescription('answer-sdp', 'answer');

  @override
  Future<void> setLocalDescription(RTCSessionDescription description) async {}

  @override
  Future<void> setRemoteDescription(RTCSessionDescription description) async {}

  @override
  Future<void> addCandidate(RTCIceCandidate candidate) async {}

  @override
  Future<RTCRtpSender> addTrack(
    MediaStreamTrack track, [
    MediaStream? stream,
  ]) async => _FakeSender();

  @override
  Future<void> close() async => closed = true;
}

/// Señalización, sesión de audio y WebRTC de mentira para una voz real.
class _Rig {
  _Rig() {
    when(() => signaling.messages).thenAnswer((_) => messages.stream);
    when(() => signaling.connectionState).thenAnswer((_) => connection.stream);
    when(() => signaling.send(any())).thenAnswer((invocation) {
      sent.add(invocation.positionalArguments.first as SignalingMessage);
    });
    when(audio.activate).thenAnswer((_) async {});
    when(audio.deactivate).thenAnswer((_) async {});
    when(() => audio.devicesStream)
        .thenAnswer((_) => const Stream<Set<AudioDevice>>.empty());
    when(() => audio.webRtcDeviceChanges)
        .thenAnswer((_) => const Stream<void>.empty());
    when(() => audio.setSpeakerphoneOn(any())).thenAnswer((_) async {});
    when(audio.setSpeakerphoneOnButPreferBluetooth).thenAnswer((_) async {});
  }

  final signaling = _MockSignaling();
  final audio = _MockAudioSession();
  final messages = StreamController<SignalingMessage>.broadcast();
  final connection = StreamController<bool>.broadcast();
  final sent = <SignalingMessage>[];
  final streams = <_FakeStream>[];

  late final PeerConnectionDataSource peers = PeerConnectionDataSource(
    signalingClient: signaling,
    peerConnectionFactory: (_) async => _FakePc(),
    userMediaFactory: (_) async {
      final stream = _FakeStream(_FakeTrack());
      streams.add(stream);
      return stream;
    },
  );

  late final VoiceRepositoryImpl voice = VoiceRepositoryImpl(
    audioSessionDataSource: audio,
    peerConnectionDataSource: peers,
    signalingClientDataSource: signaling,
    isAndroid: false,
    permissionRequester: () async => true,
    settingsOpener: () async => true,
  );

  _FakeTrack get track => streams.single.track;

  /// El enlace de voz con [peerId].
  _FakePc pc(String peerId) => peers.peerConnections[peerId]! as _FakePc;

  Iterable<T> sentOf<T extends SignalingMessage>() => sent.whereType<T>();

  Future<void> send(SignalingMessage message) async {
    messages.add(message);
    await pumpEventQueue();
  }

  /// La sucesión de la frecu con [members] (el anfitrión primero).
  Future<void> roomState(List<String> members, {bool handover = true}) => send(
    SignalingMessage.roomState(
      state: RoomSuccession(
        term: 1,
        handover: handover,
        name: 'Ruta',
        accessCode: '1234',
        members: [
          for (final id in members)
            RoomMember(id: id, displayName: id, joinedAt: DateTime(2026)),
        ],
      ),
    ),
  );

  /// Se cae el socket de señalización.
  Future<void> drop() async {
    connection.add(false);
    await pumpEventQueue();
  }

  /// La voz de `peer_3` en la frecu de `peer_1` con `peer_2`.
  Future<void> join({bool handover = true}) async {
    await voice.joinMesh(localPeerId: 'peer_3', peerIds: ['peer_1', 'peer_2']);
    await roomState(['peer_1', 'peer_2', 'peer_3'], handover: handover);
  }

  Future<void> close() async {
    await voice.dispose();
    await messages.close();
    await connection.close();
  }
}

Participant _p(String id, {bool host = false}) =>
    Participant(id: id, displayName: id, isHost: host);

void main() {
  setUpAll(
    () => registerFallbackValue(const SignalingMessage.ping(timestamp: 0)),
  );

  late _Rig rig;

  setUp(() => rig = _Rig());
  tearDown(() => rig.close());

  group('AC1 · sin el anfitrión la voz sigue', () {
    test('AC1: en PTT sigue transmitiendo, los enlaces siguen y solo el '
        'anfitrión deja de verse hablando', () async {
      await rig.join();
      await rig.voice.startTalking();
      await rig.send(
        const SignalingMessage.talkState(peerId: 'peer_1', isSpeaking: true),
      );
      await rig.send(
        const SignalingMessage.talkState(peerId: 'peer_2', isSpeaking: true),
      );
      final host = rig.pc('peer_1');
      final ana = rig.pc('peer_2');
      rig.sent.clear();

      await rig.drop();

      expect(await rig.voice.watchIsTalking().first, isTrue);
      expect(rig.track.enabled, isTrue);
      expect(await rig.voice.watchSpeakingPeers().first, {'peer_2'});
      expect(host.closed, isFalse);
      expect(ana.closed, isFalse);
      expect(rig.peers.localPeerId, 'peer_3');
      expect(rig.sentOf<SignalingOfferMessage>(), isEmpty);
    });

    test('AC1: con el micrófono abierto sigue abierto', () async {
      await rig.join();
      await rig.voice.setTalkMode(TalkMode.openMic);
      await rig.voice.startTalking();

      await rig.drop();

      expect(await rig.voice.watchIsTalking().first, isTrue);
      expect(rig.track.enabled, isTrue);
      expect(rig.pc('peer_2').closed, isFalse);
    });
  });

  group('AC2 · cambio de anfitrión', () {
    test('AC2: llega la sucesión de otro anfitrión y se cierra solo el '
        'enlace con el anterior', () async {
      await rig.join();
      await rig.voice.startTalking();
      final host = rig.pc('peer_1');
      final ana = rig.pc('peer_2');
      await rig.drop();
      rig.sent.clear();

      await rig.roomState(['peer_2', 'peer_3']);

      expect(host.closed, isTrue);
      expect(ana.closed, isFalse);
      expect(rig.peers.peerConnections.keys, ['peer_2']);
      expect(rig.peers.links.containsKey('peer_1'), isFalse);
      expect(rig.sentOf<SignalingOfferMessage>(), isEmpty);
      expect(await rig.voice.watchIsTalking().first, isTrue);
      expect(rig.track.enabled, isTrue);
    });

    test('AC2: si este teléfono toma la frecu, cierra solo el enlace con el '
        'anterior', () async {
      await rig.join();
      final host = rig.pc('peer_1');
      final ana = rig.pc('peer_2');
      await rig.drop();

      await rig.roomState(['peer_3', 'peer_2']);

      expect(host.closed, isTrue);
      expect(ana.closed, isFalse);
    });

    test(
      'AC2: la misma sucesión con el mismo anfitrión no cierra nada',
      () async {
        await rig.join();
        await rig.roomState(['peer_1', 'peer_2', 'peer_3']);

        expect(rig.pc('peer_1').closed, isFalse);
        expect(rig.pc('peer_2').closed, isFalse);
      },
    );
  });

  group('AC3 · volver con el mismo id', () {
    test(
      'AC3: tras el traspaso no rehace la malla y anuncia que habla',
      () async {
        await rig.join();
        await rig.voice.startTalking();
        final ana = rig.pc('peer_2');
        await rig.drop();
        rig.sent.clear();

        await rig.send(
          SignalingMessage.welcome(
            peerId: 'peer_3',
            participants: [_p('peer_2', host: true), _p('peer_3')],
          ),
        );

        expect(ana.closed, isFalse);
        expect(rig.sentOf<SignalingOfferMessage>(), isEmpty);
        final talk = rig.sentOf<SignalingTalkStateMessage>().last;
        expect(talk.peerId, 'peer_3');
        expect(talk.isSpeaking, isTrue);
      },
    );

    test(
      'AC3: si el micrófono abierto se cortó (P160), lo retoma solo',
      () async {
        // Sin sucesión aún, la voz no sabe del traspaso y corta.
        await rig.voice.joinMesh(
          localPeerId: 'peer_3',
          peerIds: ['peer_1', 'peer_2'],
        );
        await rig.voice.setTalkMode(TalkMode.openMic);
        await rig.voice.startTalking();
        await rig.drop();
        expect(await rig.voice.watchIsTalking().first, isFalse);
        expect(rig.track.enabled, isFalse);
        rig.sent.clear();

        await rig.send(
          SignalingMessage.welcome(
            peerId: 'peer_3',
            participants: [_p('peer_2', host: true), _p('peer_3')],
          ),
        );

        expect(await rig.voice.watchIsTalking().first, isTrue);
        expect(rig.track.enabled, isTrue);
        final talk = rig.sentOf<SignalingTalkStateMessage>().last;
        expect(talk.peerId, 'peer_3');
        expect(talk.muted, isNull);
        expect(rig.sentOf<SignalingOfferMessage>(), isEmpty);
      },
    );
  });

  group('AC4 · volver con un id nuevo', () {
    test('AC4: con el micrófono abierto cierra los enlaces viejos, ofrece a '
        'los presentes salvo a su id viejo y sigue abierto', () async {
      await rig.join();
      await rig.voice.setTalkMode(TalkMode.openMic);
      await rig.voice.startTalking();
      final host = rig.pc('peer_1');
      final ana = rig.pc('peer_2');
      await rig.drop();
      rig.sent.clear();

      await rig.send(
        SignalingMessage.welcome(
          peerId: 'peer_7',
          participants: [_p('peer_2', host: true), _p('peer_3'), _p('peer_7')],
        ),
      );

      expect(host.closed, isTrue);
      expect(ana.closed, isTrue);
      final offers = rig.sentOf<SignalingOfferMessage>().toList();
      expect(offers.map((o) => o.to).toList(), ['peer_2']);
      expect(offers.single.from, 'peer_7');
      expect(await rig.voice.watchIsTalking().first, isTrue);
      expect(rig.track.enabled, isTrue);
    });

    test('AC4: en PTT, si seguía transmitiendo, lo anuncia con el id nuevo '
        '(P178)', () async {
      await rig.join();
      await rig.voice.startTalking();
      await rig.drop();
      rig.sent.clear();

      await rig.send(
        SignalingMessage.welcome(
          peerId: 'peer_7',
          participants: [_p('peer_2', host: true), _p('peer_7')],
        ),
      );

      final talk = rig.sentOf<SignalingTalkStateMessage>().last;
      expect(talk.peerId, 'peer_7');
      expect(talk.isSpeaking, isTrue);
      expect(rig.track.enabled, isTrue);
    });
  });

  group('AC5 · sin traspaso', () {
    test('AC5: sin anfitrión no se transmite y al volver retoma el micrófono '
        'abierto', () async {
      await rig.join(handover: false);
      await rig.voice.setTalkMode(TalkMode.openMic);
      await rig.voice.startTalking();

      await rig.drop();
      expect(await rig.voice.watchIsTalking().first, isFalse);
      expect(rig.track.enabled, isFalse);

      await rig.send(
        SignalingMessage.welcome(
          peerId: 'peer_7',
          participants: [_p('peer_1', host: true), _p('peer_7')],
        ),
      );
      expect(await rig.voice.watchIsTalking().first, isTrue);
      expect(rig.track.enabled, isTrue);
    });

    test('AC5: en PTT sin traspaso deja de transmitir', () async {
      await rig.join(handover: false);
      await rig.voice.startTalking();

      await rig.drop();

      expect(await rig.voice.watchIsTalking().first, isFalse);
      expect(rig.track.enabled, isFalse);
    });
  });
}
