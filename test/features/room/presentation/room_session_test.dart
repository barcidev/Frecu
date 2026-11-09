// F1: CUANDO alguien se une o abre la frecu antes de que exista la pantalla (el `welcome` ya pasó) ENTONCES la voz igual entra a la malla: ofrece a quienes estaban, responde a quien llega y su `talk_state` lleva el id propio.
// F2: CUANDO la pantalla de la frecu se abre después del `welcome` ENTONCES muestra a todos, «tú», el anfitrión y su hoja correcta, sin esperar a que alguien entre o salga.
// F4: CUANDO se pulsa Atrás en la frecu ENTONCES se abre la hoja de salir (cerrar para todos si es el anfitrión) y nunca sale sin dejar la frecu; CUANDO la pantalla se desmonta estando en la frecu ENTONCES sale de ella.
// F5: CUANDO se sale de la frecu ENTONCES se suelta la voz.
// F16: CUANDO el micrófono no se puede usar ENTONCES la frecu lo avisa con un acceso a los ajustes.
// P101/P105, F11, F13 (malla y ruta): la isla avisa quién entra y sale, la ruta nueva (con el nombre del Bluetooth) y la conexión recuperada, y cuenta los segundos al reconectar; la malla dice «Silenciado» y «Conectando» según la voz.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/design/widgets/status_island.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/data/repositories/voice_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/link_quality.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/leave_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/room_closed_view.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

/// Señalización de mentira: contesta el `join` con un `welcome` (con los
/// que ya estaban y un id nuevo cada vez) y deja inyectar mensajes.
class _FakeSignaling extends SignalingClientDataSource {
  final _messages = StreamController<SignalingMessage>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  final List<SignalingMessage> sent = [];
  bool _connected = false;

  /// Quienes ya estaban; vacío si este teléfono abre la frecu.
  List<Participant> present = const [];

  /// Ids que el anfitrión va asignando a este teléfono.
  final List<String> ids = ['peer_2', 'peer_3', 'peer_4'];
  int _joins = 0;

  @override
  bool get isConnected => _connected;

  @override
  Stream<SignalingMessage> get messages => _messages.stream;

  @override
  Stream<bool> get connectionState => _connection.stream;

  @override
  Future<void> connect(Uri uri) async {
    _connected = true;
    _connection.add(true);
  }

  @override
  Future<void> disconnect() async => drop();

  /// Se cae la red.
  void drop() {
    if (!_connected) return;
    _connected = false;
    _connection.add(false);
  }

  @override
  void send(SignalingMessage message) {
    sent.add(message);
    if (message is! SignalingJoinMessage) return;
    final id = ids[_joins++];
    final me = Participant(
      id: id,
      displayName: message.displayName,
      isHost: present.isEmpty,
    );
    scheduleMicrotask(
      () => _messages.add(
        SignalingMessage.welcome(
          peerId: id,
          participants: [...present, me],
          roomName: 'Ruta 40',
        ),
      ),
    );
  }

  /// Llega [message] del anfitrión.
  void emit(SignalingMessage message) => _messages.add(message);

  Iterable<T> sentOf<T extends SignalingMessage>() => sent.whereType<T>();

  @override
  Future<void> dispose() async {
    await _messages.close();
    await _connection.close();
  }
}

/// Servidor de mentira: el anfitrión «abre» sin sockets.
class _FakeServer extends SignalingServerDataSource {
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  int get port => 47800;

  @override
  Future<void> start({
    required String accessCode,
    String? roomName,
    String host = '0.0.0.0',
    int port = 47800,
    RoomNote? note,
  }) async => _running = true;

  @override
  Future<void> stop({String reason = 'host_closed'}) async => _running = false;
}

class _MockVoice extends Mock implements VoiceRepository {}

class _MockAudioSession extends Mock implements AudioSessionDataSource {}

class _FakeTrack extends Fake implements MediaStreamTrack {
  @override
  bool enabled = true;

  @override
  Future<void> stop() async {}
}

class _FakeStream extends Fake implements MediaStream {
  final _FakeTrack track = _FakeTrack();

  @override
  List<MediaStreamTrack> getAudioTracks() => [track];

  @override
  List<MediaStreamTrack> getTracks() => [track];

  @override
  Future<void> dispose() async {}
}

class _FakeSender extends Fake implements RTCRtpSender {}

class _FakePc extends Fake implements RTCPeerConnection {
  @override
  dynamic Function(RTCIceCandidate candidate)? onIceCandidate;

  @override
  dynamic Function(RTCIceConnectionState state)? onIceConnectionState;

  @override
  Future<RTCSessionDescription> createOffer([
    Map<String, dynamic> constraints = const {},
  ]) async => RTCSessionDescription('offer', 'offer');

  @override
  Future<RTCSessionDescription> createAnswer([
    Map<String, dynamic> constraints = const {},
  ]) async => RTCSessionDescription('answer', 'answer');

  @override
  Future<void> setLocalDescription(RTCSessionDescription description) async {}

  @override
  Future<void> setRemoteDescription(RTCSessionDescription description) async {}

  @override
  Future<RTCRtpSender> addTrack(
    MediaStreamTrack track, [
    MediaStream? stream,
  ]) async => _FakeSender();

  @override
  Future<void> close() async {}
}

const _andres = Participant(id: 'peer_1', displayName: 'Andrés', isHost: true);
const Result<void> _ok = Result.success(null);

void main() {
  setUpAll(() {
    registerFallbackValue(TalkMode.pushToTalk);
    registerFallbackValue(AudioRoute.speaker);
    registerFallbackValue(const SignalingMessage.ping(timestamp: 0));
    LocaleSettings.setLocaleSync(AppLocale.es);
  });

  group('F1 y F2 · la frecu antes de la pantalla', () {
    late _FakeSignaling signaling;
    late RoomRepositoryImpl rooms;
    late _MockAudioSession audio;
    late ProviderContainer container;

    setUp(() {
      signaling = _FakeSignaling();
      rooms = RoomRepositoryImpl(
        serverDataSource: _FakeServer(),
        clientDataSource: signaling,
        networkInterfacesProvider: () async => [],
      );
      audio = _MockAudioSession();
      when(audio.activate).thenAnswer((_) async {});
      when(audio.deactivate).thenAnswer((_) async {});
      when(() => audio.devicesStream).thenAnswer((_) => const Stream.empty());
      when(() => audio.setSpeakerphoneOn(any())).thenAnswer((_) async {});
      container = ProviderContainer.test(
        overrides: [
          signalingClientProvider.overrideWithValue(signaling),
          roomRepositoryProvider.overrideWithValue(rooms),
          // Como en la app: la voz se crea cuando alguien la pide.
          voiceRepositoryProvider.overrideWith(
            (ref) => VoiceRepositoryImpl(
              audioSessionDataSource: audio,
              peerConnectionDataSource: PeerConnectionDataSource(
                signalingClient: signaling,
                peerConnectionFactory: (_) async => _FakePc(),
                userMediaFactory: (_) async => _FakeStream(),
              ),
              signalingClientDataSource: signaling,
              permissionRequester: () async => true,
            ),
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await rooms.dispose();
      await signaling.dispose();
    });

    test('F1: quien se une antes de abrir la pantalla ofrece al anfitrión y '
        'su talk_state lleva su id', () async {
      signaling.present = const [_andres];
      final result = await container
          .read(roomNotifierProvider.notifier)
          .joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '4821',
            displayName: 'Ana',
          );
      expect(result.isSuccess, isTrue);
      await pumpEventQueue();

      // La pantalla llega después del welcome.
      final voice = container.read(voiceNotifierProvider.notifier);
      expect((await voice.initialize()).isSuccess, isTrue);
      await pumpEventQueue();

      final offer = signaling.sentOf<SignalingOfferMessage>().single;
      expect(offer.from, 'peer_2');
      expect(offer.to, 'peer_1');

      await voice.startTalking();
      final talk = signaling.sentOf<SignalingTalkStateMessage>().last;
      expect(talk.peerId, 'peer_2');
      expect(talk.isSpeaking, isTrue);
    });

    test('F1: el anfitrión responde a quien llega aunque su pantalla aún no '
        'exista', () async {
      await container
          .read(roomNotifierProvider.notifier)
          .createRoom(
            name: 'Ruta 40',
            accessCode: '4821',
            displayName: 'Andrés',
          );
      await pumpEventQueue();

      signaling.emit(
        const SignalingMessage.offer(from: 'peer_3', to: 'peer_2', sdp: 'o'),
      );
      await pumpEventQueue();

      final answer = signaling.sentOf<SignalingAnswerMessage>().single;
      expect(answer.from, 'peer_2');
      expect(answer.to, 'peer_3');
    });

    test('F2: los participantes y el estado se ven aunque se pidan después '
        'del welcome', () async {
      signaling.present = const [_andres];
      await container
          .read(roomNotifierProvider.notifier)
          .joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '4821',
            displayName: 'Ana',
          );

      final people = container.listen(roomParticipantsProvider, (_, _) {});
      final status = container.listen(roomStatusProvider, (_, _) {});
      final list = await container
          .read(roomParticipantsProvider.future)
          .timeout(const Duration(seconds: 1));
      expect(list.map((p) => p.displayName), ['Andrés', 'Ana']);
      expect(
        await container
            .read(roomStatusProvider.future)
            .timeout(const Duration(seconds: 1)),
        const RoomStatus.connected(),
      );
      expect(container.read(roomNotifierProvider)?.name, 'Ruta 40');
      people.close();
      status.close();
    });

    test('F5: salir suelta la voz y la señalización', () async {
      signaling.present = const [_andres];
      await container
          .read(roomNotifierProvider.notifier)
          .joinRoom(
            hostAddress: '192.168.43.1',
            port: 47800,
            accessCode: '4821',
            displayName: 'Ana',
          );
      final voice = container.read(voiceNotifierProvider.notifier);
      await voice.initialize();
      await voice.startTalking();
      await pumpEventQueue();

      await container.read(roomNotifierProvider.notifier).leaveRoom();
      await pumpEventQueue();

      expect(container.read(voiceNotifierProvider).isTalking, isFalse);
      expect(signaling.isConnected, isFalse);
      expect(container.read(roomNotifierProvider), isNull);
      verify(audio.deactivate).called(1);
    });
  });

  group('La pantalla de la frecu', () {
    late _FakeSignaling signaling;
    late RoomRepositoryImpl rooms;
    late _MockVoice voice;
    late StreamController<bool> talking;
    late StreamController<Set<String>> speaking;
    late StreamController<Set<String>> muted;
    late StreamController<Map<String, PeerConnectionState>> links;
    late StreamController<Map<String, LinkQuality>> quality;
    late StreamController<TalkMode> mode;
    late StreamController<AudioRoute> route;
    late StreamController<Set<AudioRoute>> available;
    late StreamController<String?> bluetooth;
    late StreamController<int> notificationLeaves;

    setUp(() {
      // La malla, el núcleo y el inicio animan sin fin: con movimiento
      // reducido quedan quietos y pumpAndSettle termina.
      final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher
        ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      signaling = _FakeSignaling();
      voice = _MockVoice();
      talking = StreamController<bool>.broadcast();
      speaking = StreamController<Set<String>>.broadcast();
      muted = StreamController<Set<String>>.broadcast();
      links = StreamController<Map<String, PeerConnectionState>>.broadcast();
      quality = StreamController<Map<String, LinkQuality>>.broadcast();
      mode = StreamController<TalkMode>.broadcast();
      route = StreamController<AudioRoute>.broadcast();
      available = StreamController<Set<AudioRoute>>.broadcast();
      bluetooth = StreamController<String?>.broadcast();
      notificationLeaves = StreamController<int>.broadcast();
      when(() => voice.initializeAudio()).thenAnswer((_) async => _ok);
      when(
        () => voice.joinMesh(
          localPeerId: any(named: 'localPeerId'),
          peerIds: any(named: 'peerIds'),
        ),
      ).thenAnswer((_) async {});
      when(() => voice.leaveMesh()).thenAnswer((_) async {});
      when(() => voice.watchIsTalking()).thenAnswer((_) => talking.stream);
      when(() => voice.watchSpeakingPeers()).thenAnswer((_) => speaking.stream);
      when(() => voice.watchMutedPeers()).thenAnswer((_) => muted.stream);
      when(() => voice.watchPeerLinks()).thenAnswer((_) => links.stream);
      when(() => voice.watchPeerQuality()).thenAnswer((_) => quality.stream);
      when(() => voice.watchTalkMode()).thenAnswer((_) => mode.stream);
      when(() => voice.watchAudioRoute()).thenAnswer((_) => route.stream);
      when(() => voice.watchAvailableAudioRoutes())
          .thenAnswer((_) => available.stream);
      when(() => voice.watchBluetoothName())
          .thenAnswer((_) => bluetooth.stream);
      when(() => voice.setTalkMode(any())).thenAnswer((_) async => _ok);
      when(() => voice.startTalking()).thenAnswer((_) async => _ok);
      when(() => voice.stopTalking()).thenAnswer((_) async => _ok);
      when(() => voice.setAudioRoute(any())).thenAnswer((_) async => _ok);
      when(() => voice.openMicrophoneSettings()).thenAnswer((_) async => true);
      when(() => voice.dispose()).thenAnswer((_) async {});
    });

    tearDown(() async {
      for (final controller in [
        talking,
        speaking,
        muted,
        links,
        quality,
        mode,
        route,
        available,
        bluetooth,
        notificationLeaves,
      ]) {
        await controller.close();
      }
      await rooms.dispose();
      await signaling.dispose();
    });

    /// Abre la app, crea (o se une a) la frecu como lo hace el inicio y
    /// después abre la pantalla, como en la app.
    Future<AppRouter> enter(WidgetTester tester, {bool host = false}) async {
      // Dentro de la prueba, para que sus suscripciones vivan en su reloj.
      rooms = RoomRepositoryImpl(
        serverDataSource: _FakeServer(),
        clientDataSource: signaling,
        networkInterfacesProvider: () async => [],
        reconnectBaseDelay: const Duration(seconds: 4),
        maxReconnectAttempts: 1,
      );
      final router = AppRouter();
      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(
            overrides: [
              signalingClientProvider.overrideWithValue(signaling),
              roomRepositoryProvider.overrideWithValue(rooms),
              voiceRepositoryProvider.overrideWithValue(voice),
              notificationLeaveRequestsProvider.overrideWith(
                (ref) => notificationLeaves.stream,
              ),
            ],
            child: FrecuApp(appRouter: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FrecuApp)),
      );
      final notifier = container.read(roomNotifierProvider.notifier);
      if (host) {
        await notifier.createRoom(
          name: 'Ruta 40',
          accessCode: '4821',
          displayName: 'Andrés',
        );
      } else {
        signaling.present = const [_andres];
        await notifier.joinRoom(
          hostAddress: '192.168.43.1',
          port: 47800,
          accessCode: '4821',
          displayName: 'Ana',
        );
      }
      await tester.pumpAndSettle();
      unawaited(router.push(RoomRoute(roomId: 'room-1')));
      await tester.pumpAndSettle();
      return router;
    }

    String islandLabel(WidgetTester tester) =>
        tester.widget<StatusIsland>(find.byType(StatusIsland)).label;

    testWidgets('F2: quien se une ve a todos, «tú», al anfitrión y el nombre '
        'real de la frecu al entrar', (tester) async {
      await enter(tester);

      expect(islandLabel(tester), 'En línea · 2/6');
      expect(find.text('Ruta 40'), findsOneWidget);
      expect(find.text('ANFITRIÓN · ANDRÉS'), findsOneWidget);
      expect(find.text('Andrés'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('TÚ'), findsOneWidget);
      verify(() => voice.joinMesh(localPeerId: 'peer_2', peerIds: ['peer_1']))
          .called(1);
    });

    testWidgets('F2 y F4: el anfitrión se ve como anfitrión y Atrás le pide '
        'cerrar la frecu para todos', (tester) async {
      await enter(tester, host: true);

      expect(find.text('ERES EL ANFITRIÓN'), findsOneWidget);
      expect(find.text('TÚ · ANFITRIÓN'), findsOneWidget);
      expect(islandLabel(tester), 'Al aire · esperando a tu grupo');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LeaveSheet), findsOneWidget);
      expect(find.text('Cerrar la frecu para todos'), findsOneWidget);
      expect(rooms.localParticipantId, isNotNull);

      await tester.tap(find.byKey(const Key('leave_confirm')));
      await tester.pumpAndSettle();
      expect(find.byType(RoomClosedView), findsOneWidget);
      expect(rooms.localParticipantId, isNull);
      verify(() => voice.leaveMesh()).called(1);
    });

    testWidgets('F4: Atrás nunca sale sin dejar la frecu: abre la hoja, '
        'cancelar sigue en la frecu y confirmar sale', (tester) async {
      await enter(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la frecu?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('leave_cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(LeaveSheet), findsNothing);
      expect(rooms.localParticipantId, 'peer_2');
      verifyNever(() => voice.leaveMesh());

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('leave_confirm')));
      await tester.pumpAndSettle();

      expect(find.text('FRECUS CERCANAS'), findsOneWidget);
      expect(rooms.localParticipantId, isNull);
      expect(signaling.isConnected, isFalse);
      verify(() => voice.leaveMesh()).called(1);
    });

    testWidgets('F16: «Salir» de la notificación saca a quien se unió y lo '
        'lleva al inicio', (tester) async {
      await enter(tester);

      notificationLeaves.add(1);
      await tester.pumpAndSettle();

      expect(find.text('FRECUS CERCANAS'), findsOneWidget);
      expect(rooms.localParticipantId, isNull);
      verify(() => voice.leaveMesh()).called(1);
    });

    testWidgets('F16: «Salir» de la notificación cierra la frecu del '
        'anfitrión y muestra el cierre', (tester) async {
      await enter(tester, host: true);

      notificationLeaves.add(1);
      await tester.pumpAndSettle();

      expect(find.byType(RoomClosedView), findsOneWidget);
      expect(rooms.localParticipantId, isNull);
    });

    testWidgets('F4: si la pantalla se va estando en la frecu, sale de ella', (
      tester,
    ) async {
      final router = await enter(tester);

      unawaited(router.replaceAll([const LobbyRoute()]));
      await tester.pumpAndSettle();

      expect(rooms.localParticipantId, isNull);
      expect(signaling.isConnected, isFalse);
      verify(() => voice.leaveMesh()).called(1);
    });

    testWidgets('F16: sin micrófono avisa y lleva a los ajustes', (
      tester,
    ) async {
      when(() => voice.initializeAudio()).thenAnswer(
        (_) async => const Result.failure(
          Failure.permissionDenied(permission: 'microphone'),
        ),
      );
      await enter(tester);

      expect(find.byKey(const Key('mic_notice')), findsOneWidget);
      expect(
        find.textContaining('Tu micrófono no está disponible.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Abrir ajustes'));
      await tester.pump();
      verify(() => voice.openMicrophoneSettings()).called(1);

      await tester.tap(find.bySemanticsLabel('Cerrar aviso'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mic_notice')), findsNothing);
    });

    testWidgets('F16: con micrófono no hay aviso', (tester) async {
      await enter(tester);
      expect(find.byKey(const Key('mic_notice')), findsNothing);
    });

    testWidgets('P101: la isla avisa quién se une y quién sale', (
      tester,
    ) async {
      await enter(tester);

      signaling.emit(
        const SignalingMessage.peerJoined(
          participant: Participant(id: 'peer_5', displayName: 'Leo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(islandLabel(tester), 'Leo se unió');

      await tester.pump(RoomIslandEvent.duration);
      await tester.pumpAndSettle();
      expect(islandLabel(tester), 'En línea · 3/6');

      signaling.emit(const SignalingMessage.peerLeft(peerId: 'peer_5'));
      await tester.pumpAndSettle();
      expect(islandLabel(tester), 'Leo salió');
      await tester.pump(RoomIslandEvent.duration);
      await tester.pumpAndSettle();
    });

    testWidgets('P101 y P111: al cambiar la salida la isla y la pastilla '
        'dicen el nombre del Bluetooth', (tester) async {
      await enter(tester);

      bluetooth.add('Sena 50S');
      available.add({
        AudioRoute.speaker,
        AudioRoute.earpiece,
        AudioRoute.bluetooth,
      });
      await tester.pumpAndSettle();
      route.add(AudioRoute.bluetooth);
      await tester.pumpAndSettle();

      expect(islandLabel(tester), 'Audio por Sena 50S');
      expect(
        find.descendant(
          of: find.byKey(const Key('audio_route_button')),
          matching: find.text('Sena 50S'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('audio_route_button')));
      await tester.pumpAndSettle();
      final option = find.byKey(const Key('audio_route_option_bluetooth'));
      expect(
        find.descendant(of: option, matching: find.text('Sena 50S')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: option,
          matching: find.text('BLUETOOTH · CONECTADO'),
        ),
        findsOneWidget,
      );
      await tester.pump(RoomIslandEvent.duration);
      await tester.pumpAndSettle();
    });

    testWidgets('P105: al reconectar cuenta los segundos y al volver dice '
        '«Conexión recuperada», sin contar a la persona propia como nueva', (
      tester,
    ) async {
      await enter(tester);

      signaling.drop();
      await tester.pump();
      await tester.pump();
      expect(islandLabel(tester), 'Reconectando · 4 s');

      await tester.pump(const Duration(seconds: 1));
      expect(islandLabel(tester), 'Reconectando · 3 s');

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(rooms.localParticipantId, 'peer_3');
      expect(islandLabel(tester), 'Conexión recuperada');

      await tester.pump(RoomIslandEvent.duration);
      await tester.pumpAndSettle();
      expect(islandLabel(tester), 'En línea · 2/6');
    });

    testWidgets('F13 (malla): quien se silencia en Abierto dice «Silenciado», '
        'también la persona propia', (tester) async {
      await enter(tester);

      muted.add({'peer_1'});
      await tester.pumpAndSettle();
      expect(find.text('SILENCIADO'), findsOneWidget);

      mode.add(TalkMode.openMic);
      talking.add(false);
      await tester.pumpAndSettle();
      expect(find.text('SILENCIADO'), findsNWidgets(2));
    });

    testWidgets('F11: mientras se negocia el enlace la frecu está conectando '
        'y la malla lo marca', (tester) async {
      await enter(tester);

      links.add({'peer_1': PeerConnectionState.connecting});
      await tester.pumpAndSettle();
      expect(islandLabel(tester), 'Conectando…');
      expect(find.text('CONECTANDO'), findsWidgets);

      links.add({'peer_1': PeerConnectionState.connected});
      await tester.pumpAndSettle();
      expect(islandLabel(tester), 'En línea · 2/6');
      expect(find.text('CONECTANDO'), findsNothing);
    });

    testWidgets('Señal débil: la malla y la isla avisan una vez y se va al '
        'mejorar', (tester) async {
      await enter(tester);

      quality.add({'peer_1': LinkQuality.weak});
      await tester.pumpAndSettle();
      expect(find.text('SEÑAL DÉBIL'), findsOneWidget);
      expect(islandLabel(tester), 'Andrés · señal débil');
      expect(
        tester.widget<StatusIsland>(find.byType(StatusIsland)).tone,
        StatusIslandTone.warn,
      );

      // Sigue débil: la leyenda queda, el aviso no se repite.
      await tester.pump(RoomIslandEvent.duration);
      await tester.pumpAndSettle();
      quality.add({'peer_1': LinkQuality.weak});
      await tester.pumpAndSettle();
      expect(islandLabel(tester), 'En línea · 2/6');
      expect(find.text('SEÑAL DÉBIL'), findsOneWidget);

      quality.add({'peer_1': LinkQuality.good});
      await tester.pumpAndSettle();
      expect(find.text('SEÑAL DÉBIL'), findsNothing);
    });

    testWidgets('F15: elegir «Abierto» abre el micrófono al instante', (
      tester,
    ) async {
      await enter(tester);

      await tester.tap(find.byKey(const Key('mode_open_mic')));
      await tester.pumpAndSettle();

      verify(() => voice.setTalkMode(TalkMode.openMic)).called(1);
      verify(() => voice.startTalking()).called(1);
    });
  });

  test('F16: la notificación usa textos traducidos y el nombre genérico si '
      'falta', () async {
    LocaleSettings.setLocaleSync(AppLocale.es);
    var texts = roomNotificationTexts();
    expect(texts.title, 'Frecu activa');
    expect(texts.connected('Ruta 40'), 'Ruta 40 · Conectado');
    expect(texts.reconnecting(''), 'Frecu activa · Reconectando…');

    await LocaleSettings.setLocale(AppLocale.en);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.es));
    texts = roomNotificationTexts();
    expect(texts.connected('Ruta 40'), 'Ruta 40 · Connected');
    expect(texts.channelName, 'Frecu in the background');
  });
}
