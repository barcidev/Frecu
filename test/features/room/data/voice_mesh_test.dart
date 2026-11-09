// F1: CUANDO el `welcome` llega antes de que exista la voz (primera frecu de la sesión) ENTONCES la voz igual se une a la malla con el id local y quienes ya estaban: captura el micrófono, ofrece enlace y su `talk_state` lleva el id propio.
// F1: CUANDO alguien ofrece enlace al anfitrión ENTONCES el anfitrión ya escucha la señalización y responde, aunque la offer llegue antes de que sepa su id.
// F5: CUANDO se sale, se cierra o se pierde la frecu ENTONCES se cierran todos los enlaces, se para y suelta el micrófono y se olvida quién habla; la siguiente frecu captura el micrófono de nuevo y nunca reutiliza un enlace de la anterior.
// F13 y P111: CUANDO se conectan audífonos ENTONCES la salida cambia a ellos y muestra el nombre del Bluetooth; CUANDO se desconectan ENTONCES vuelve al altavoz.
// Reloj: CUANDO en Android hay un Bluetooth solo de llamadas (sin A2DP ni LE Audio, como un reloj) ENTONCES la salida no va sola a él (la voz se oiría en la muñeca): queda para elegirlo a mano; unos audífonos o unos de cable sí se llevan la salida.
// Reloj: CUANDO en Android el gestor de audio de WebRTC cambia de salida por su cuenta ENTONCES vuelve la ruta elegida.
// F15: CUANDO se pierde al anfitrión con el micrófono abierto ENTONCES deja de transmitir y al reconectar lo retoma.
// F16: CUANDO un candidato ICE llega antes que la descripción remota ENTONCES se aplica después de ella; un error de negociación no escapa.
// Enlace: CUANDO un enlace de voz no conecta a tiempo (sin ruta, p. ej. ICE sin pares) ENTONCES queda caído en lugar de dejar la frecu «conectando» para siempre; si conecta después, vuelve a conectado.
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/voice_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignaling extends Mock implements SignalingClientDataSource {}

class _MockAudioSession extends Mock implements AudioSessionDataSource {}

class _FakeTrack extends Fake implements MediaStreamTrack {
  @override
  bool enabled = true;

  bool stopped = false;

  @override
  Future<void> stop() async => stopped = true;
}

class _FakeStream extends Fake implements MediaStream {
  _FakeStream(this.track);

  final _FakeTrack track;
  bool disposed = false;

  @override
  List<MediaStreamTrack> getAudioTracks() => [track];

  @override
  List<MediaStreamTrack> getTracks() => [track];

  @override
  Future<void> dispose() async => disposed = true;
}

class _FakeSender extends Fake implements RTCRtpSender {}

class _FakeTransceiver extends Fake implements RTCRtpTransceiver {}

class _FakePc extends Fake implements RTCPeerConnection {
  final List<String> calls = [];
  final List<RTCIceCandidate> candidates = [];
  bool closed = false;
  bool failRemote = false;

  @override
  dynamic Function(RTCIceCandidate candidate)? onIceCandidate;

  @override
  dynamic Function(RTCIceConnectionState state)? onIceConnectionState;

  @override
  Future<RTCSessionDescription> createOffer([
    Map<String, dynamic> constraints = const {},
  ]) async {
    calls.add('createOffer');
    return RTCSessionDescription('offer-sdp', 'offer');
  }

  @override
  Future<RTCSessionDescription> createAnswer([
    Map<String, dynamic> constraints = const {},
  ]) async {
    calls.add('createAnswer');
    return RTCSessionDescription('answer-sdp', 'answer');
  }

  @override
  Future<void> setLocalDescription(RTCSessionDescription description) async {
    calls.add('setLocal:${description.type}');
  }

  @override
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (failRemote) throw StateError('bad sdp');
    calls.add('setRemote:${description.type}');
  }

  @override
  Future<void> addCandidate(RTCIceCandidate candidate) async {
    calls.add('addCandidate');
    candidates.add(candidate);
  }

  @override
  Future<RTCRtpSender> addTrack(
    MediaStreamTrack track, [
    MediaStream? stream,
  ]) async {
    calls.add('addTrack');
    return _FakeSender();
  }

  @override
  Future<RTCRtpTransceiver> addTransceiver({
    MediaStreamTrack? track,
    RTCRtpMediaType? kind,
    RTCRtpTransceiverInit? init,
  }) async {
    calls.add('addTransceiver');
    return _FakeTransceiver();
  }

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
    when(() => audio.devicesStream).thenAnswer((_) => devices.stream);
    when(() => audio.webRtcDeviceChanges)
        .thenAnswer((_) => webRtcDevices.stream);
    when(() => audio.setSpeakerphoneOn(any())).thenAnswer((_) async {});
    when(audio.setSpeakerphoneOnButPreferBluetooth).thenAnswer((_) async {});
  }

  final signaling = _MockSignaling();
  final audio = _MockAudioSession();
  final messages = StreamController<SignalingMessage>.broadcast();
  final connection = StreamController<bool>.broadcast();
  final devices = StreamController<Set<AudioDevice>>.broadcast();
  final webRtcDevices = StreamController<void>.broadcast();
  final sent = <SignalingMessage>[];
  final pcs = <_FakePc>[];
  final streams = <_FakeStream>[];
  bool micGranted = true;

  /// El sistema deja capturar el micrófono.
  bool micAvailable = true;
  int settingsOpened = 0;

  PeerConnectionDataSource peerConnections({
    Duration linkWaitLimit = const Duration(seconds: 15),
  }) => PeerConnectionDataSource(
    signalingClient: signaling,
    linkWaitLimit: linkWaitLimit,
    peerConnectionFactory: (config) async {
      expect(config['iceServers'], isEmpty);
      final pc = _FakePc();
      pcs.add(pc);
      return pc;
    },
    userMediaFactory: (_) async {
      if (!micAvailable) throw StateError('Permission denied');
      final stream = _FakeStream(_FakeTrack());
      streams.add(stream);
      return stream;
    },
  );

  VoiceRepositoryImpl voice([
    PeerConnectionDataSource? peers,
    bool? isAndroid,
  ]) => VoiceRepositoryImpl(
    audioSessionDataSource: audio,
    peerConnectionDataSource: peers ?? peerConnections(),
    signalingClientDataSource: signaling,
    isAndroid: isAndroid,
    permissionRequester: () async => micGranted,
    settingsOpener: () async {
      settingsOpened++;
      return true;
    },
  );

  Iterable<T> sentOf<T extends SignalingMessage>() => sent.whereType<T>();

  Future<void> close() async {
    await messages.close();
    await connection.close();
    await devices.close();
    await webRtcDevices.close();
  }
}

const _host = Participant(id: 'peer_1', displayName: 'Andrés', isHost: true);
const _ana = Participant(id: 'peer_2', displayName: 'Ana');

AudioDevice _device(String name, AudioDeviceType type) => AudioDevice(
  id: name,
  name: name,
  type: type,
  isInput: false,
  isOutput: true,
);

void main() {
  setUpAll(
    () => registerFallbackValue(const SignalingMessage.ping(timestamp: 0)),
  );

  late _Rig rig;

  setUp(() => rig = _Rig());
  tearDown(() => rig.close());

  group('F1 · la voz entra a la malla aunque llegue tarde', () {
    test(
      'F1: con el welcome ya consumido, joinMesh captura el micrófono, '
      'ofrece a quienes estaban y el talk_state lleva el id propio',
      () async {
        // El welcome pasa antes de que exista la voz: nadie lo oye.
        rig.messages.add(
          const SignalingMessage.welcome(
            peerId: 'peer_3',
            participants: [_host, _ana],
          ),
        );
        await pumpEventQueue();

        final voice = rig.voice();
        await voice.joinMesh(
          localPeerId: 'peer_3',
          peerIds: ['peer_1', 'peer_2'],
        );

        expect(rig.streams, hasLength(1));
        final offers = rig.sentOf<SignalingOfferMessage>().toList();
        expect(offers.map((o) => o.to).toSet(), {'peer_1', 'peer_2'});
        expect(offers.every((o) => o.from == 'peer_3'), isTrue);
        expect(rig.pcs.every((pc) => pc.calls.contains('addTrack')), isTrue);

        await voice.startTalking();
        final talk = rig.sentOf<SignalingTalkStateMessage>().last;
        expect(talk.peerId, 'peer_3');
        expect(talk.isSpeaking, isTrue);
        expect(rig.streams.single.track.enabled, isTrue);

        await voice.dispose();
      },
    );

    test('F1: si el welcome también llega, no hay doble inicio: un solo '
        'micrófono y una sola offer por par', () async {
      final voice = rig.voice();
      rig.messages.add(
        const SignalingMessage.welcome(peerId: 'peer_3', participants: [_host]),
      );
      await voice.joinMesh(localPeerId: 'peer_3', peerIds: ['peer_1']);
      await pumpEventQueue();

      expect(rig.streams, hasLength(1));
      expect(rig.sentOf<SignalingOfferMessage>(), hasLength(1));
      expect(rig.pcs, hasLength(1));

      await voice.dispose();
    });

    test(
      'F1: el anfitrión responde la offer que llega antes de saber su id',
      () async {
        final voice = rig.voice();
        // La offer llega antes que el id local (p. ej. la pantalla aún no
        // abre): se guarda y se atiende al entrar a la malla.
        rig.messages.add(
          const SignalingMessage.offer(
            from: 'peer_2',
            to: 'peer_1',
            sdp: 'remote-offer',
          ),
        );
        await pumpEventQueue();
        expect(rig.sentOf<SignalingAnswerMessage>(), isEmpty);

        await voice.joinMesh(localPeerId: 'peer_1', peerIds: const []);
        await pumpEventQueue();

        final answer = rig.sentOf<SignalingAnswerMessage>().single;
        expect(answer.from, 'peer_1');
        expect(answer.to, 'peer_2');
        expect(
          rig.pcs.single.calls,
          containsAllInOrder([
            'setRemote:offer',
            'createAnswer',
            'setLocal:answer',
          ]),
        );

        await voice.dispose();
      },
    );

    test('F1: una offer dirigida a otro id no se atiende', () async {
      final voice = rig.voice();
      await voice.joinMesh(localPeerId: 'peer_1', peerIds: const []);
      rig.messages.add(
        const SignalingMessage.offer(from: 'peer_2', to: 'peer_9', sdp: 'x'),
      );
      await pumpEventQueue();

      expect(rig.pcs, isEmpty);
      expect(rig.sentOf<SignalingAnswerMessage>(), isEmpty);
      await voice.dispose();
    });
  });

  group('F5 · salir suelta la voz', () {
    test('F5: leaveMesh cierra los enlaces, para el micrófono y reinicia '
        'quién habla; la frecu siguiente captura de nuevo y no reutiliza '
        'enlaces', () async {
      final voice = rig.voice();
      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
      await voice.startTalking();
      rig.messages.add(
        const SignalingMessage.talkState(peerId: 'peer_1', isSpeaking: true),
      );
      await pumpEventQueue();
      expect(await voice.watchSpeakingPeers().first, {'peer_1'});

      await voice.leaveMesh();

      final first = rig.pcs.single;
      expect(first.closed, isTrue);
      expect(rig.streams.single.track.stopped, isTrue);
      expect(rig.streams.single.disposed, isTrue);
      expect(await voice.watchIsTalking().first, isFalse);
      expect(await voice.watchSpeakingPeers().first, isEmpty);
      verify(rig.audio.deactivate).called(1);

      // Otra frecu: el mismo id remoto ya no es el mismo par.
      rig.sent.clear();
      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);

      expect(rig.streams, hasLength(2));
      expect(rig.pcs, hasLength(2));
      expect(identical(rig.pcs.last, first), isFalse);
      expect(rig.sentOf<SignalingOfferMessage>().single.to, 'peer_1');

      await voice.dispose();
    });

    test(
      'F5: el cierre de la frecu por el anfitrión también suelta la voz',
      () async {
        final voice = rig.voice();
        await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);

        rig.messages.add(
          const SignalingMessage.roomClosed(reason: 'host_closed'),
        );
        await pumpEventQueue();

        expect(rig.pcs.single.closed, isTrue);
        expect(rig.streams.single.track.stopped, isTrue);
        await voice.dispose();
      },
    );

    test('F5: al reconectar con otro id cierra los enlaces viejos, rehace las '
        'offers y no vuelve a capturar el micrófono', () async {
      final voice = rig.voice();
      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
      rig.sent.clear();

      rig.messages.add(
        const SignalingMessage.welcome(
          peerId: 'peer_4',
          participants: [
            _host,
            Participant(id: 'peer_4', displayName: 'Ana'),
          ],
        ),
      );
      await pumpEventQueue();

      expect(rig.pcs.first.closed, isTrue);
      expect(rig.pcs, hasLength(2));
      expect(rig.streams, hasLength(1));
      final offer = rig.sentOf<SignalingOfferMessage>().single;
      expect(offer.from, 'peer_4');
      expect(offer.to, 'peer_1');
      await voice.dispose();
    });
  });

  group('F16 · negociación robusta', () {
    test('F16: un candidato ICE que llega antes de la offer se aplica después '
        'de la descripción remota', () async {
      final voice = rig.voice();
      await voice.joinMesh(localPeerId: 'peer_1', peerIds: const []);

      rig.messages
        ..add(
          const SignalingMessage.ice(
            from: 'peer_2',
            to: 'peer_1',
            candidate: 'candidate:early',
            sdpMid: '0',
            sdpMLineIndex: 0,
          ),
        )
        ..add(
          const SignalingMessage.offer(from: 'peer_2', to: 'peer_1', sdp: 'o'),
        );
      await pumpEventQueue();

      final pc = rig.pcs.single;
      expect(pc.candidates.single.candidate, 'candidate:early');
      expect(
        pc.calls.indexOf('addCandidate'),
        greaterThan(pc.calls.indexOf('setRemote:offer')),
      );
      await voice.dispose();
    });

    test('F16: un error al negociar no escapa y el resto sigue', () async {
      final peers = PeerConnectionDataSource(
        signalingClient: rig.signaling,
        peerConnectionFactory: (_) async {
          final pc = _FakePc()..failRemote = rig.pcs.isEmpty;
          rig.pcs.add(pc);
          return pc;
        },
        userMediaFactory: (_) async => _FakeStream(_FakeTrack()),
      );
      final voice = rig.voice(peers);
      await voice.joinMesh(localPeerId: 'peer_1', peerIds: const []);

      rig.messages
        ..add(
          const SignalingMessage.offer(from: 'peer_2', to: 'peer_1', sdp: 'x'),
        )
        ..add(
          const SignalingMessage.offer(from: 'peer_3', to: 'peer_1', sdp: 'y'),
        );
      await pumpEventQueue();

      expect(rig.sentOf<SignalingAnswerMessage>().single.to, 'peer_3');
      await voice.dispose();
    });

    test(
      'F11: el estado ICE de cada enlace llega como estado del par',
      () async {
        final voice = rig.voice();
        final links = <Map<String, PeerConnectionState>>[];
        final sub = voice.watchPeerLinks().listen(links.add);
        await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
        await pumpEventQueue();
        expect(links.last, {'peer_1': PeerConnectionState.connecting});

        rig.pcs.single.onIceConnectionState!(
          RTCIceConnectionState.RTCIceConnectionStateConnected,
        );
        await pumpEventQueue();
        expect(links.last, {'peer_1': PeerConnectionState.connected});

        rig.messages.add(const SignalingMessage.peerLeft(peerId: 'peer_1'));
        await pumpEventQueue();
        expect(links.last, isEmpty);
        expect(rig.pcs.single.closed, isTrue);

        await sub.cancel();
        await voice.dispose();
      },
    );

    test('Enlace: si no conecta a tiempo queda caído y la frecu deja de '
        'estar conectando; si conecta después, vuelve a conectado', () async {
      final voice = rig.voice(
        rig.peerConnections(linkWaitLimit: const Duration(milliseconds: 40)),
      );
      final links = <Map<String, PeerConnectionState>>[];
      final sub = voice.watchPeerLinks().listen(links.add);
      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
      await pumpEventQueue();
      expect(links.last, {'peer_1': PeerConnectionState.connecting});

      // ICE sin pares: nunca llega a conectar ni a fallar.
      rig.pcs.single.onIceConnectionState!(
        RTCIceConnectionState.RTCIceConnectionStateChecking,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(links.last, {'peer_1': PeerConnectionState.disconnected});

      rig.pcs.single.onIceConnectionState!(
        RTCIceConnectionState.RTCIceConnectionStateConnected,
      );
      await pumpEventQueue();
      expect(links.last, {'peer_1': PeerConnectionState.connected});

      await sub.cancel();
      await voice.dispose();
    });

    test('Enlace: un enlace que conecta a tiempo no se da por caído y la '
        'espera no revive a quien salió', () async {
      final voice = rig.voice(
        rig.peerConnections(linkWaitLimit: const Duration(milliseconds: 40)),
      );
      final links = <Map<String, PeerConnectionState>>[];
      final sub = voice.watchPeerLinks().listen(links.add);
      await voice.joinMesh(
        localPeerId: 'peer_3',
        peerIds: ['peer_1', 'peer_2'],
      );
      await pumpEventQueue();

      rig.pcs.first.onIceConnectionState!(
        RTCIceConnectionState.RTCIceConnectionStateConnected,
      );
      rig.messages.add(const SignalingMessage.peerLeft(peerId: 'peer_2'));
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(links.last, {'peer_1': PeerConnectionState.connected});
      await sub.cancel();
      await voice.dispose();
    });

    test('F16: sin permiso de micrófono falla con permissionDenied y la malla '
        'igual escucha (solo recibe)', () async {
      rig
        ..micGranted = false
        ..micAvailable = false;
      final voice = rig.voice();
      final result = await voice.initializeAudio();
      expect(
        result.failureOrNull,
        const Failure.permissionDenied(permission: 'microphone'),
      );

      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
      expect(rig.streams, isEmpty);
      expect(rig.pcs.single.calls, contains('addTransceiver'));
      expect(rig.sentOf<SignalingOfferMessage>(), hasLength(1));
      await voice.dispose();
    });

    test('F1: si el plugin de permisos dice que no pero el sistema deja '
        'capturar (iOS sin macros), la voz igual transmite', () async {
      rig.micGranted = false;
      final voice = rig.voice();
      expect((await voice.initializeAudio()).isSuccess, isTrue);

      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
      expect(rig.streams, hasLength(1));
      expect(rig.pcs.single.calls, contains('addTrack'));
      await voice.dispose();
    });
  });

  group('F15 · micrófono abierto', () {
    test('F15: en Abierto silenciarse avisa muted y quien recibe lo marca '
        'silenciado', () async {
      final voice = rig.voice();
      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
      await voice.setTalkMode(TalkMode.openMic);
      expect(rig.sentOf<SignalingTalkStateMessage>().last.muted, isTrue);

      await voice.startTalking();
      expect(rig.sentOf<SignalingTalkStateMessage>().last.muted, isNull);
      await voice.stopTalking();
      final muted = rig.sentOf<SignalingTalkStateMessage>().last;
      expect(muted.isSpeaking, isFalse);
      expect(muted.muted, isTrue);

      rig.messages.add(
        const SignalingMessage.talkState(
          peerId: 'peer_1',
          isSpeaking: false,
          muted: true,
        ),
      );
      await pumpEventQueue();
      expect(await voice.watchMutedPeers().first, {'peer_1'});

      rig.messages.add(
        const SignalingMessage.talkState(peerId: 'peer_1', isSpeaking: true),
      );
      await pumpEventQueue();
      expect(await voice.watchMutedPeers().first, isEmpty);
      expect(await voice.watchSpeakingPeers().first, {'peer_1'});
      await voice.dispose();
    });

    test('F15: sin anfitrión deja de transmitir y al volver retoma el '
        'micrófono abierto', () async {
      final voice = rig.voice();
      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
      await voice.setTalkMode(TalkMode.openMic);
      await voice.startTalking();
      final track = rig.streams.single.track;
      expect(track.enabled, isTrue);

      rig.connection.add(false);
      await pumpEventQueue();
      expect(await voice.watchIsTalking().first, isFalse);
      expect(track.enabled, isFalse);

      rig.sent.clear();
      rig.messages.add(
        const SignalingMessage.welcome(
          peerId: 'peer_5',
          participants: [
            _host,
            Participant(id: 'peer_5', displayName: 'Ana'),
          ],
        ),
      );
      await pumpEventQueue();

      expect(await voice.watchIsTalking().first, isTrue);
      expect(track.enabled, isTrue);
      final talk = rig.sentOf<SignalingTalkStateMessage>().last;
      expect(talk.peerId, 'peer_5');
      expect(talk.isSpeaking, isTrue);
      await voice.dispose();
    });

    test('F15: en PTT la reconexión no reabre el micrófono', () async {
      final voice = rig.voice();
      await voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']);
      await voice.startTalking();

      rig.connection.add(false);
      await pumpEventQueue();
      rig.messages.add(
        const SignalingMessage.welcome(
          peerId: 'peer_5',
          participants: [
            _host,
            Participant(id: 'peer_5', displayName: 'Ana'),
          ],
        ),
      );
      await pumpEventQueue();

      expect(await voice.watchIsTalking().first, isFalse);
      await voice.dispose();
    });
  });

  group('F13 y P111 · salida de audio', () {
    test('F13: al conectar un Bluetooth la salida cambia a él con su nombre y '
        'al desconectarlo vuelve al altavoz', () async {
      final voice = rig.voice();
      rig.devices.add({_device('Altavoz', AudioDeviceType.builtInSpeaker)});
      await pumpEventQueue();
      expect(await voice.watchAudioRoute().first, AudioRoute.speaker);
      expect(await voice.watchBluetoothName().first, isNull);

      rig.devices.add({
        _device('Altavoz', AudioDeviceType.builtInSpeaker),
        _device('Sena 50S', AudioDeviceType.bluetoothSco),
      });
      await pumpEventQueue();
      expect(await voice.watchAudioRoute().first, AudioRoute.bluetooth);
      expect(await voice.watchBluetoothName().first, 'Sena 50S');
      expect(
        await voice.watchAvailableAudioRoutes().first,
        contains(AudioRoute.bluetooth),
      );
      verify(rig.audio.setSpeakerphoneOnButPreferBluetooth).called(1);

      rig.devices.add({_device('Altavoz', AudioDeviceType.builtInSpeaker)});
      await pumpEventQueue();
      expect(await voice.watchAudioRoute().first, AudioRoute.speaker);
      expect(await voice.watchBluetoothName().first, isNull);
      await voice.dispose();
    });

    test('F13: al conectar audífonos de cable la salida deja el altavoz y al '
        'desconectarlos vuelve a él', () async {
      final voice = rig.voice();
      rig.devices.add({_device('Altavoz', AudioDeviceType.builtInSpeaker)});
      await pumpEventQueue();

      rig.devices.add({
        _device('Altavoz', AudioDeviceType.builtInSpeaker),
        _device('Audífonos', AudioDeviceType.wiredHeadphones),
      });
      await pumpEventQueue();
      expect(await voice.watchAudioRoute().first, AudioRoute.earpiece);
      verify(() => rig.audio.setSpeakerphoneOn(false)).called(1);

      rig.devices.add({_device('Altavoz', AudioDeviceType.builtInSpeaker)});
      await pumpEventQueue();
      expect(await voice.watchAudioRoute().first, AudioRoute.speaker);
      await voice.dispose();
    });

    test('Reloj: en Android un Bluetooth solo de llamadas no se lleva la '
        'salida al entrar ni al conectarse, pero se puede elegir', () async {
      final voice = rig.voice(null, true);
      rig.devices.add({
        _device('Altavoz', AudioDeviceType.builtInSpeaker),
        _device('HUAWEI WATCH GT 2 Pro', AudioDeviceType.bluetoothSco),
      });
      await pumpEventQueue();

      expect(await voice.watchAudioRoute().first, AudioRoute.speaker);
      expect(
        await voice.watchAvailableAudioRoutes().first,
        contains(AudioRoute.bluetooth),
      );
      expect(await voice.watchBluetoothName().first, 'HUAWEI WATCH GT 2 Pro');
      verifyNever(rig.audio.setSpeakerphoneOnButPreferBluetooth);

      // Elegido a mano, sí va a él.
      await voice.setAudioRoute(AudioRoute.bluetooth);
      expect(await voice.watchAudioRoute().first, AudioRoute.bluetooth);
      await voice.dispose();
    });

    test('Reloj: en Android unos audífonos con A2DP sí se llevan la salida '
        'aunque haya un reloj, y unos de cable también', () async {
      final voice = rig.voice(null, true);
      rig.devices.add({
        _device('Altavoz', AudioDeviceType.builtInSpeaker),
        _device('HUAWEI WATCH GT 2 Pro', AudioDeviceType.bluetoothSco),
      });
      await pumpEventQueue();

      rig.devices.add({
        _device('Altavoz', AudioDeviceType.builtInSpeaker),
        _device('HUAWEI WATCH GT 2 Pro', AudioDeviceType.bluetoothSco),
        _device('Audífonos', AudioDeviceType.wiredHeadphones),
      });
      await pumpEventQueue();
      expect(await voice.watchAudioRoute().first, AudioRoute.earpiece);

      rig.devices.add({
        _device('Altavoz', AudioDeviceType.builtInSpeaker),
        _device('HUAWEI WATCH GT 2 Pro', AudioDeviceType.bluetoothSco),
        AudioDevice(
          id: 'Buds-sco',
          name: 'Galaxy Buds',
          type: AudioDeviceType.bluetoothSco,
          isInput: true,
          isOutput: true,
        ),
        AudioDevice(
          id: 'Buds-a2dp',
          name: 'Galaxy Buds',
          type: AudioDeviceType.bluetoothA2dp,
          isInput: false,
          isOutput: true,
        ),
      });
      await pumpEventQueue();
      expect(await voice.watchAudioRoute().first, AudioRoute.bluetooth);
      expect(await voice.watchBluetoothName().first, 'Galaxy Buds');
      await voice.dispose();
    });

    test('Reloj: en Android, si el gestor de audio de WebRTC cambia de '
        'salida por su cuenta, vuelve la ruta elegida', () async {
      final voice = rig.voice(null, true);
      rig.devices.add({
        _device('Altavoz', AudioDeviceType.builtInSpeaker),
        _device('HUAWEI WATCH GT 2 Pro', AudioDeviceType.bluetoothSco),
      });
      await pumpEventQueue();
      clearInteractions(rig.audio);

      // audioswitch eligió el reloj sin que nadie lo pidiera.
      rig.webRtcDevices
        ..add(null)
        ..add(null);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      verify(() => rig.audio.setSpeakerphoneOn(true)).called(1);
      expect(await voice.watchAudioRoute().first, AudioRoute.speaker);
      await voice.dispose();
    });

    test('Reloj: fuera de Android no escucha al gestor de audio de WebRTC', () {
      final voice = rig.voice(null, false);
      verifyNever(() => rig.audio.webRtcDeviceChanges);
      return voice.dispose();
    });

    test(
      'F13: si al entrar ya hay un Bluetooth conectado, la salida es él',
      () async {
        final voice = rig.voice();
        rig.devices.add({_device('Sena 50S', AudioDeviceType.bluetoothA2dp)});
        await pumpEventQueue();
        expect(await voice.watchAudioRoute().first, AudioRoute.bluetooth);
        await voice.dispose();
      },
    );
  });

  test('F16: abrir los ajustes del micrófono pasa por la voz', () async {
    final voice = rig.voice();
    expect(await voice.openMicrophoneSettings(), isTrue);
    expect(rig.settingsOpened, 1);
    await voice.dispose();
  });
}
