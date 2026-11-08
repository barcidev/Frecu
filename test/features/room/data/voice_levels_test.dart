// AC1: CUANDO la pantalla de la frecu activa escucha los niveles ENTONCES `VoiceRepository` lee `getStats()` de cada conexión cada 100 ms y emite por `watchLocalLevel` el `audioLevel` del `media-source` de audio y por `watchPeerLevels` el `audioLevel` del `inbound-rtp` de audio de cada participante por su id, de 0 a 1, solo cuando cambian; CUANDO nadie los escucha ENTONCES deja de leer y los niveles vuelven a 0.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/voice_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignaling extends Mock implements SignalingClientDataSource {}

class _MockAudioSession extends Mock implements AudioSessionDataSource {}

class _MockPeerConnections extends Mock implements PeerConnectionDataSource {}

class _MockPc extends Mock implements RTCPeerConnection {}

class _MockStream extends Mock implements MediaStream {}

class _MockTrack extends Mock implements MediaStreamTrack {}

class _MockSender extends Mock implements RTCRtpSender {}

class _FakeTrack extends Fake implements MediaStreamTrack {}

class _FakeStream extends Fake implements MediaStream {}

/// Informe de `getStats()` de tipo [type] con sus [values].
StatsReport _report(String type, Map<String, Object> values) =>
    StatsReport('$type-${values.length}', type, 0, values);

/// Libera [voice] fuera del tiempo falso de `testWidgets`, donde los `await`
/// de suscripciones ya terminadas no avanzan (por eso las suscripciones se
/// cancelan sin esperar).
Future<void> _release(WidgetTester tester, VoiceRepositoryImpl voice) =>
    tester.runAsync(voice.dispose);

void main() {
  setUpAll(() {
    registerFallbackValue(const SignalingMessage.ping(timestamp: 0));
    registerFallbackValue(RTCSessionDescription('sdp', 'offer'));
    registerFallbackValue(_FakeTrack());
    registerFallbackValue(_FakeStream());
  });

  late _MockSignaling signaling;

  setUp(() {
    signaling = _MockSignaling();
    when(() => signaling.messages).thenAnswer((_) => const Stream.empty());
    when(() => signaling.send(any())).thenAnswer((_) {});
  });

  group('PeerConnectionDataSource.readVoiceLevels', () {
    late Map<String, _MockPc> pcs;
    late PeerConnectionDataSource dataSource;

    _MockPc mockPc() {
      final pc = _MockPc();
      when(() => pc.addTrack(any(), any()))
          .thenAnswer((_) async => _MockSender());
      when(() => pc.createOffer(any()))
          .thenAnswer((_) async => RTCSessionDescription('offer', 'offer'));
      when(() => pc.setLocalDescription(any())).thenAnswer((_) async {});
      when(pc.close).thenAnswer((_) async {});
      return pc;
    }

    setUp(() async {
      final track = _MockTrack();
      final stream = _MockStream();
      when(stream.getTracks).thenReturn([track]);
      when(stream.getAudioTracks).thenReturn([track]);
      pcs = {'peer-a': mockPc(), 'peer-b': mockPc()};
      final order = pcs.values.iterator;
      dataSource = PeerConnectionDataSource(
        signalingClient: signaling,
        peerConnectionFactory: (_) async => (order..moveNext()).current,
        userMediaFactory: (_) async => stream,
      );
      await dataSource.initialize(localPeerId: 'me');
    });

    test('AC1: sin conexiones el nivel propio es 0 y no hay niveles de '
        'pares', () async {
      final levels = await dataSource.readVoiceLevels();

      expect(levels.local, 0);
      expect(levels.peers, isEmpty);
    });

    test('AC1: el nivel propio es el mayor audioLevel de los media-source de '
        'audio y el de cada par, el de su inbound-rtp de audio', () async {
      when(() => pcs['peer-a']!.getStats()).thenAnswer(
        (_) async => [
          _report('media-source', {'kind': 'audio', 'audioLevel': 0.25}),
          _report('inbound-rtp', {'kind': 'audio', 'audioLevel': 0.5}),
          _report('inbound-rtp', {'kind': 'video', 'audioLevel': 0.9}),
          _report('outbound-rtp', {'kind': 'audio', 'audioLevel': 0.8}),
          _report('media-source', {'kind': 'audio'}),
          _report('candidate-pair', {'state': 'succeeded'}),
        ],
      );
      when(() => pcs['peer-b']!.getStats()).thenAnswer(
        (_) async => [
          _report('media-source', {'kind': 'audio', 'audioLevel': 0.4}),
          _report('inbound-rtp', {'mediaType': 'audio', 'audioLevel': 1}),
        ],
      );
      await dataSource.connectToPeer('peer-a');
      await dataSource.connectToPeer('peer-b');

      final levels = await dataSource.readVoiceLevels();

      expect(levels.local, 0.4);
      expect(levels.peers, {'peer-a': 0.5, 'peer-b': 1.0});
      expect(levels.peers['peer-b'], isA<double>());
    });

    test('AC1: una conexión cuyo getStats falla se salta', () async {
      when(() => pcs['peer-a']!.getStats())
          .thenThrow('Unable to RTCPeerConnection::getStats: closed');
      when(() => pcs['peer-b']!.getStats()).thenAnswer(
        (_) async => [
          _report('media-source', {'kind': 'audio', 'audioLevel': 0.2}),
          _report('inbound-rtp', {'kind': 'audio', 'audioLevel': 0.3}),
        ],
      );
      await dataSource.connectToPeer('peer-a');
      await dataSource.connectToPeer('peer-b');

      final levels = await dataSource.readVoiceLevels();

      expect(levels.local, 0.2);
      expect(levels.peers, {'peer-b': 0.3});
    });
  });

  group('VoiceRepositoryImpl niveles de voz', () {
    late _MockAudioSession audio;
    late _MockPeerConnections peers;
    late VoiceLevels next;
    late int reads;

    setUp(() {
      audio = _MockAudioSession();
      peers = _MockPeerConnections();
      next = (local: 0, peers: const {});
      reads = 0;
      when(() => audio.devicesStream).thenAnswer((_) => const Stream.empty());
      when(audio.deactivate).thenAnswer((_) async {});
      when(peers.dispose).thenAnswer((_) async {});
      when(peers.readVoiceLevels).thenAnswer((_) async {
        reads++;
        return next;
      });
    });

    VoiceRepositoryImpl repository() => VoiceRepositoryImpl(
      audioSessionDataSource: audio,
      peerConnectionDataSource: peers,
      signalingClientDataSource: signaling,
      permissionRequester: () async => true,
    );

    testWidgets('AC1: sin nadie escuchando no lee; escuchando lee cada '
        '100 ms con un solo temporizador y emite solo los cambios', (
      tester,
    ) async {
      final voice = repository();
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 0);

      final local = <double>[];
      final peerLevels = <Map<String, double>>[];
      final localSub = voice.watchLocalLevel().listen(local.add);
      final peersSub = voice.watchPeerLevels().listen(peerLevels.add);
      await tester.pump();
      expect(local, [0]);
      expect(peerLevels, [<String, double>{}]);

      next = (local: 0.3, peers: const {'p-2': 0.6});
      await tester.pump(const Duration(milliseconds: 99));
      expect(reads, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(reads, 1);
      expect(local, [0, 0.3]);
      expect(peerLevels.last, {'p-2': 0.6});

      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 2);
      expect(local, [0, 0.3]);
      expect(peerLevels, hasLength(2));

      next = (local: 0.3, peers: const {'p-2': 0.1, 'p-3': 0.7});
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 3);
      expect(local, [0, 0.3]);
      expect(peerLevels.last, {'p-2': 0.1, 'p-3': 0.7});

      unawaited(localSub.cancel());
      unawaited(peersSub.cancel());
      await _release(tester, voice);
    });

    testWidgets('AC1: cuando nadie escucha deja de leer y los niveles vuelven '
        'a 0', (tester) async {
      final voice = repository();
      next = (local: 0.5, peers: const {'p-2': 0.4});
      final sub = voice.watchLocalLevel().listen((_) {});
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 1);

      unawaited(sub.cancel());
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 1);

      final local = <double>[];
      final peerLevels = <Map<String, double>>[];
      final localSub = voice.watchLocalLevel().listen(local.add);
      final peersSub = voice.watchPeerLevels().listen(peerLevels.add);
      await tester.pump();
      expect(local, [0]);
      expect(peerLevels, [<String, double>{}]);

      await _release(tester, voice);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 1);
      unawaited(localSub.cancel());
      unawaited(peersSub.cancel());
    });

    testWidgets('AC1: si una lectura no terminó, se salta el tic siguiente', (
      tester,
    ) async {
      final voice = repository();
      final pending = Completer<VoiceLevels>();
      when(peers.readVoiceLevels).thenAnswer((_) {
        reads++;
        return pending.future;
      });
      final peerLevels = <Map<String, double>>[];
      final sub = voice.watchPeerLevels().listen(peerLevels.add);

      await tester.pump(const Duration(milliseconds: 350));
      expect(reads, 1);

      pending.complete((local: 0.0, peers: const {'p-3': 0.2}));
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 2);
      expect(peerLevels.last, {'p-3': 0.2});

      unawaited(sub.cancel());
      await _release(tester, voice);
    });
  });
}
