// AC2: CUANDO alguien se une por IP manual, sin mDNS ni QR, ENTONCES la frecu activa muestra en la cabecera la nota del anfitrión. CUANDO la invitación trae una nota y `welcome` trae otra ENTONCES la frecu activa lleva la de `welcome`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/repositories/discovery_repository.dart';
import 'package:frecu/features/lobby/presentation/providers/discovery_provider.dart';
import 'package:frecu/features/lobby/presentation/widgets/ip_join_sheet.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/datasources/signaling_server_datasource.dart';
import 'package:frecu/features/room/data/repositories/room_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockVoiceRepository extends Mock implements VoiceRepository {}

/// Servidor de señalización del anfitrión en 127.0.0.1 y en un puerto libre,
/// para no chocar con otras pruebas que usan el 47800.
class _LoopbackServer extends SignalingServerDataSource {
  @override
  Future<void> start({
    required String accessCode,
    String host = '0.0.0.0',
    int port = NetworkConstants.signalingPort,
    RoomNote? note,
  }) {
    return super.start(
      accessCode: accessCode,
      host: '127.0.0.1',
      port: 0,
      note: note,
    );
  }
}

/// Cliente del invitado: la hoja de IP se une en el 47800 fijo, y aquí se
/// conecta al puerto libre del anfitrión.
class _HostPortClient extends SignalingClientDataSource {
  _HostPortClient(this._hostPort);

  final int Function() _hostPort;

  @override
  Future<void> connect(Uri uri) =>
      super.connect(uri.replace(port: _hostPort()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // La5 (880 Hz): no sale de la hora del invitado.
  const hostNote = RoomNote(semitone: 21);

  late _LoopbackServer hostServer;
  late RoomRepositoryImpl hostRepository;
  late RoomRepositoryImpl guestRepository;
  late _MockDiscoveryRepository discovery;
  late _MockVoiceRepository voice;
  late StreamController<List<NearbyRoom>> nearby;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.es);
    hostServer = _LoopbackServer();
    hostRepository = RoomRepositoryImpl(
      serverDataSource: hostServer,
      clientDataSource: SignalingClientDataSource(),
      networkInterfacesProvider: () async => [],
    );
    guestRepository = RoomRepositoryImpl(
      serverDataSource: SignalingServerDataSource(),
      clientDataSource: _HostPortClient(() => hostServer.port),
      networkInterfacesProvider: () async => [],
    );
    discovery = _MockDiscoveryRepository();
    voice = _MockVoiceRepository();
    nearby = StreamController<List<NearbyRoom>>.broadcast();

    when(() => discovery.watchNearbyRooms()).thenAnswer((_) => nearby.stream);
    when(() => discovery.dispose()).thenAnswer((_) async {});
    when(() => voice.initializeAudio())
        .thenAnswer((_) async => const Result.success(null));
    when(() => voice.watchIsTalking()).thenAnswer((_) => Stream.value(false));
    when(() => voice.watchSpeakingPeers()).thenAnswer((_) => Stream.value({}));
    when(() => voice.watchTalkMode())
        .thenAnswer((_) => Stream.value(TalkMode.openMic));
  });

  tearDown(() async {
    await nearby.close();
  });

  /// Espera con la red real, como mucho 3 s, a que se cumpla [done].
  Future<void> waitFor(bool Function() done) async {
    for (var i = 0; i < 150 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  testWidgets(
    'AC2: al unirse por IP manual la cabecera de la frecu activa muestra la '
    'nota del anfitrión',
    (tester) async {
      // La malla y las firmas animan sin fin: con movimiento reducido quedan
      // quietas y pumpAndSettle termina.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      // El anfitrión abre su frecu en La5 con su servidor real.
      final host = ProviderContainer(
        overrides: [roomRepositoryProvider.overrideWithValue(hostRepository)],
      );
      final created = await tester.runAsync(
        () => host
            .read(roomNotifierProvider.notifier)
            .createRoom(
              name: 'Ruta del domingo',
              accessCode: '1234',
              displayName: 'Ana',
              note: hostNote,
            ),
      );
      expect(created?.isSuccess, isTrue);

      // El invitado abre la app y se une por IP, sin mDNS ni QR.
      final guest = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(discovery),
          roomRepositoryProvider.overrideWithValue(guestRepository),
          voiceRepositoryProvider.overrideWithValue(voice),
        ],
      );
      await tester.pumpWidget(
        TranslationProvider(
          child: UncontrolledProviderScope(
            container: guest,
            child: FrecuApp(appRouter: AppRouter()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.lobby.joinRoom));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(IpJoinSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.first, '127.0.0.1');
      await tester.enterText(fields.last, '1234');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text(t.lobby.join.ip.connect));
        await waitFor(() => guest.read(roomNotifierProvider) != null);
      });
      await tester.pumpAndSettle();

      expect(guest.read(roomNotifierProvider)?.note, hostNote);
      final chip = find.byType(RoomNoteChip);
      expect(chip, findsOneWidget);
      expect(tester.widget<RoomNoteChip>(chip).note, hostNote);
      expect(find.bySemanticsLabel('Nota La5, 880 Hz'), findsOneWidget);

      // Cierra la app y las dos frecus con la red real.
      await tester.pumpWidget(const SizedBox());
      guest.dispose();
      await tester.runAsync(() async {
        await guestRepository.dispose();
        await hostRepository.dispose();
      });
      host.dispose();
    },
  );
}
