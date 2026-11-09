// Abierto: CUANDO se está en micrófono abierto con el micrófono abierto ENTONCES se sale «hablando» solo mientras el nivel propio supera el umbral (con retención para no parpadear), y se anuncia a la frecu con `talk_state` al empezar y al terminar.
// Abierto: CUANDO se silencia en micrófono abierto ENTONCES se sigue anunciando `muted` como antes.
// PTT: CUANDO se transmite en PTT ENTONCES se sigue anunciando `talk_state` al pulsar y al soltar, sin mirar el nivel.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/voice_activity_detector.dart';
import 'package:frecu/features/room/data/repositories/voice_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignaling extends Mock implements SignalingClientDataSource {}

class _MockAudioSession extends Mock implements AudioSessionDataSource {}

class _MockPeerConnections extends Mock implements PeerConnectionDataSource {}

/// Nivel justo por encima y justo por debajo del umbral.
const double _loud = 0.05;
const double _quiet = 0.005;

/// Libera [voice] fuera del tiempo falso de `testWidgets`.
Future<void> _release(WidgetTester tester, VoiceRepositoryImpl voice) =>
    tester.runAsync(voice.dispose);

void main() {
  group('VoiceActivityDetector', () {
    late List<bool> changes;
    late VoiceActivityDetector detector;

    setUp(() {
      changes = [];
      detector = VoiceActivityDetector(onChanged: changes.add);
    });

    test('el umbral por defecto es −36 dBFS y la retención 400 ms', () {
      expect(openMicVoiceThresholdDb, -36);
      expect(openMicVoiceHold, const Duration(milliseconds: 400));
      expect(detector.threshold, closeTo(0.01585, 0.00001));
      expect(_loud, greaterThan(detector.threshold));
      expect(_quiet, lessThan(detector.threshold));
    });

    testWidgets('bajo el umbral no se enciende', (tester) async {
      detector
        ..add(0)
        ..add(_quiet);
      await tester.pump(const Duration(seconds: 1));
      expect(detector.isActive, isFalse);
      expect(changes, isEmpty);
    });

    testWidgets('se enciende con el primer nivel sobre el umbral y se apaga '
        'cuando pasa la retención sin otro', (tester) async {
      detector.add(_loud);
      expect(detector.isActive, isTrue);
      expect(changes, [true]);

      detector.add(_quiet);
      await tester.pump(const Duration(milliseconds: 399));
      expect(detector.isActive, isTrue);
      await tester.pump(const Duration(milliseconds: 1));
      expect(detector.isActive, isFalse);
      expect(changes, [true, false]);
    });

    testWidgets('las pausas más cortas que la retención no parpadean', (
      tester,
    ) async {
      for (var i = 0; i < 5; i++) {
        detector.add(_loud);
        await tester.pump(const Duration(milliseconds: 100));
        // 100 + 250 ms desde el último nivel alto: menos que la retención.
        detector.add(_quiet);
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(changes, [true]);
      await tester.pump(const Duration(milliseconds: 50));
      expect(changes, [true, false]);
    });

    testWidgets('un nivel que sigue sobre el umbral sin cambiar no se apaga', (
      tester,
    ) async {
      // Los niveles llegan solo cuando cambian: una voz saturada en 1 no
      // manda más.
      detector.add(1);
      await tester.pump(const Duration(seconds: 2));
      expect(detector.isActive, isTrue);
      detector.add(0);
      await tester.pump(openMicVoiceHold);
      expect(changes, [true, false]);
    });

    testWidgets('reset vuelve al silencio sin avisar y cancela la '
        'retención', (tester) async {
      detector
        ..add(_loud)
        ..reset();
      expect(detector.isActive, isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(changes, [true]);
    });

    test('el umbral y la retención se pueden ajustar', () {
      final custom = VoiceActivityDetector(
        onChanged: (_) {},
        thresholdDb: -20,
        hold: const Duration(milliseconds: 300),
      );
      expect(custom.threshold, closeTo(0.1, 0.0001));
      expect(custom.hold, const Duration(milliseconds: 300));
    });
  });

  group('VoiceRepositoryImpl habla por nivel', () {
    late _MockSignaling signaling;
    late _MockAudioSession audio;
    late _MockPeerConnections peers;
    late VoiceLevels next;
    late List<({bool speaking, bool muted})> announced;
    late List<({bool enabled, bool muted, bool announce})> microphone;

    setUpAll(() {
      registerFallbackValue(const SignalingMessage.ping(timestamp: 0));
    });

    setUp(() {
      signaling = _MockSignaling();
      audio = _MockAudioSession();
      peers = _MockPeerConnections();
      next = (local: 0, peers: const {});
      announced = [];
      microphone = [];
      when(() => signaling.messages).thenAnswer((_) => const Stream.empty());
      when(() => signaling.connectionState)
          .thenAnswer((_) => const Stream.empty());
      when(() => audio.devicesStream).thenAnswer((_) => const Stream.empty());
      when(audio.activate).thenAnswer((_) async {});
      when(audio.deactivate).thenAnswer((_) async {});
      when(() => audio.setSpeakerphoneOn(any())).thenAnswer((_) async {});
      when(() => peers.attach(any())).thenReturn(null);
      when(() => peers.prepareMedia(capture: any(named: 'capture')))
          .thenAnswer((_) async {});
      when(() => peers.hasMicrophone).thenReturn(true);
      when(peers.dispose).thenAnswer((_) async {});
      when(peers.readVoiceLevels).thenAnswer((_) async => next);
      when(
        () => peers.announceTalkState(
          speaking: any(named: 'speaking'),
          muted: any(named: 'muted'),
        ),
      ).thenAnswer((invocation) {
        announced.add((
          speaking: invocation.namedArguments[#speaking] as bool,
          muted: invocation.namedArguments[#muted] as bool? ?? false,
        ));
      });
      when(
        () => peers.setMicrophoneEnabled(
          enabled: any(named: 'enabled'),
          muted: any(named: 'muted'),
          announce: any(named: 'announce'),
        ),
      ).thenAnswer((invocation) {
        final enabled = invocation.namedArguments[#enabled] as bool;
        final muted = invocation.namedArguments[#muted] as bool? ?? false;
        final announce = invocation.namedArguments[#announce] as bool? ?? true;
        microphone.add((enabled: enabled, muted: muted, announce: announce));
        // Como el datasource real: con announce, anuncia el estado.
        if (announce) announced.add((speaking: enabled, muted: muted));
      });
    });

    Future<VoiceRepositoryImpl> joined(WidgetTester tester) async {
      final voice = VoiceRepositoryImpl(
        audioSessionDataSource: audio,
        peerConnectionDataSource: peers,
        signalingClientDataSource: signaling,
        permissionRequester: () async => true,
        isAndroid: false,
      );
      await voice.joinMesh(localPeerId: 'me', peerIds: const []);
      await tester.pump();
      return voice;
    }

    testWidgets('en Abierto abrir el micrófono no es hablar: se anuncia sin '
        'silencio y sin habla', (tester) async {
      final voice = await joined(tester);
      await voice.setTalkMode(TalkMode.openMic);
      expect(announced.last, (speaking: false, muted: true));

      await voice.startTalking();
      expect(microphone.last, (enabled: true, muted: false, announce: false));
      expect(announced.last, (speaking: false, muted: false));
      expect(await voice.watchIsTalking().first, isTrue);
      expect(await voice.watchVoiceDetected().first, isFalse);

      await _release(tester, voice);
    });

    testWidgets('en Abierto la voz sobre el umbral se anuncia y, tras la '
        'retención en silencio, se anuncia que terminó', (tester) async {
      final voice = await joined(tester);
      final detected = <bool>[];
      final sub = voice.watchVoiceDetected().listen(detected.add);
      await voice.setTalkMode(TalkMode.openMic);
      await voice.startTalking();
      announced.clear();

      next = (local: _quiet, peers: const {});
      await tester.pump(const Duration(milliseconds: 300));
      expect(announced, isEmpty);

      next = (local: _loud, peers: const {});
      await tester.pump(const Duration(milliseconds: 100));
      expect(announced, [(speaking: true, muted: false)]);
      expect(detected, [false, true]);

      // Pausa corta entre palabras: sigue hablando.
      next = (local: _quiet, peers: const {});
      await tester.pump(const Duration(milliseconds: 200));
      next = (local: _loud * 2, peers: const {});
      await tester.pump(const Duration(milliseconds: 100));
      expect(announced, hasLength(1));

      next = (local: 0, peers: const {});
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(openMicVoiceHold);
      expect(announced, [
        (speaking: true, muted: false),
        (speaking: false, muted: false),
      ]);
      expect(detected, [false, true, false]);

      unawaited(sub.cancel());
      await _release(tester, voice);
    });

    testWidgets('quien entra mientras se habla en Abierto oye que se habla', (
      tester,
    ) async {
      final messages = StreamController<SignalingMessage>.broadcast();
      when(() => signaling.messages).thenAnswer((_) => messages.stream);
      final voice = await joined(tester);
      await voice.setTalkMode(TalkMode.openMic);
      await voice.startTalking();
      next = (local: _loud, peers: const {});
      await tester.pump(const Duration(milliseconds: 100));
      announced.clear();

      messages.add(
        const SignalingMessage.peerJoined(
          participant: Participant(id: 'p-2', displayName: 'Ana'),
        ),
      );
      await tester.pump();
      expect(announced, [(speaking: true, muted: false)]);

      await _release(tester, voice);
      await tester.runAsync(messages.close);
    });

    testWidgets('silenciarse en Abierto anuncia muted como antes y deja de '
        'mirar el nivel', (tester) async {
      final voice = await joined(tester);
      await voice.setTalkMode(TalkMode.openMic);
      await voice.startTalking();
      next = (local: _loud, peers: const {});
      await tester.pump(const Duration(milliseconds: 100));
      expect(await voice.watchVoiceDetected().first, isTrue);

      await voice.stopTalking();
      expect(microphone.last, (enabled: false, muted: true, announce: true));
      expect(announced.last, (speaking: false, muted: true));
      expect(await voice.watchVoiceDetected().first, isFalse);

      announced.clear();
      await tester.pump(const Duration(seconds: 1));
      expect(announced, isEmpty);

      await _release(tester, voice);
    });

    testWidgets('PTT no cambia: anuncia al pulsar y al soltar y el nivel no '
        'anuncia nada', (tester) async {
      final voice = await joined(tester);
      final detected = <bool>[];
      final sub = voice.watchVoiceDetected().listen(detected.add);
      // Alguien escucha el VU: el nivel se lee igual.
      final levels = voice.watchLocalLevel().listen((_) {});

      await voice.startTalking();
      expect(microphone.last, (enabled: true, muted: false, announce: true));
      expect(announced.last, (speaking: true, muted: false));

      announced.clear();
      next = (local: _quiet, peers: const {});
      await tester.pump(const Duration(milliseconds: 500));
      next = (local: _loud, peers: const {});
      await tester.pump(const Duration(milliseconds: 500));
      next = (local: 0, peers: const {});
      await tester.pump(const Duration(seconds: 1));
      expect(announced, isEmpty);

      await voice.stopTalking();
      expect(microphone.last, (enabled: false, muted: false, announce: true));
      expect(announced, [(speaking: false, muted: false)]);
      expect(detected, [false]);

      unawaited(sub.cancel());
      unawaited(levels.cancel());
      await _release(tester, voice);
    });

    testWidgets('pasar de Abierto a PTT deja de detectar la voz', (
      tester,
    ) async {
      final voice = await joined(tester);
      await voice.setTalkMode(TalkMode.openMic);
      await voice.startTalking();
      next = (local: _loud, peers: const {});
      await tester.pump(const Duration(milliseconds: 100));
      expect(await voice.watchVoiceDetected().first, isTrue);

      await voice.setTalkMode(TalkMode.pushToTalk);
      expect(await voice.watchVoiceDetected().first, isFalse);
      expect(announced.last, (speaking: false, muted: false));

      announced.clear();
      await tester.pump(const Duration(seconds: 1));
      expect(announced, isEmpty);

      await _release(tester, voice);
    });
  });

  group('VoiceState.selfSpeaking', () {
    test('en PTT es transmitir, sin mirar la voz', () {
      expect(const VoiceState(isTalking: true).selfSpeaking, isTrue);
      expect(const VoiceState().selfSpeaking, isFalse);
      expect(const VoiceState(voiceDetected: true).selfSpeaking, isFalse);
    });

    test('en Abierto es tener el micrófono abierto y que se oiga la voz', () {
      const open = VoiceState(talkMode: TalkMode.openMic, isTalking: true);
      expect(open.selfSpeaking, isFalse);
      expect(open.copyWith(voiceDetected: true).selfSpeaking, isTrue);
      expect(
        const VoiceState(
          talkMode: TalkMode.openMic,
          voiceDetected: true,
        ).selfSpeaking,
        isFalse,
      );
    });
  });
}
