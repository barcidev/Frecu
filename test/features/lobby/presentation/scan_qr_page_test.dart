// AC5: CUANDO un participante escanea el código QR de invitación ENTONCES la aplicación parsea los parámetros de conexión y se une automáticamente a la sala sin ingresar la IP ni el código manualmente.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/lobby/presentation/pages/scan_qr_page.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomRepository extends Mock implements RoomRepository {}

class MockVoiceRepository extends Mock implements VoiceRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scan QR page and automatic join', () {
    late MockRoomRepository roomRepository;
    late MockVoiceRepository voiceRepository;

    final testRoom = Room(
      id: 'room-qr-999',
      name: 'Frecu Escaneada',
      hostAddress: '192.168.1.100',
      port: 47800,
      accessCode: '4321',
      createdAt: DateTime(2026, 11, 7),
    );

    setUp(() {
      roomRepository = MockRoomRepository();
      voiceRepository = MockVoiceRepository();
      LocaleSettings.setLocale(AppLocale.es);

      when(() => roomRepository.watchStatus())
          .thenAnswer((_) => Stream.value(const RoomStatus.connected()));
      when(() => roomRepository.watchParticipants())
          .thenAnswer((_) => Stream.value([]));
      when(() => voiceRepository.initializeAudio())
          .thenAnswer((_) async => const Result.success(null));
      when(() => voiceRepository.watchIsTalking())
          .thenAnswer((_) => Stream.value(false));
      when(() => voiceRepository.watchSpeakingPeers())
          .thenAnswer((_) => Stream.value({}));
      when(() => voiceRepository.watchTalkMode())
          .thenAnswer((_) => Stream.value(TalkMode.openMic));
      when(
        () => roomRepository.joinRoom(
          hostAddress: any(named: 'hostAddress'),
          port: any(named: 'port'),
          accessCode: any(named: 'accessCode'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => Result.success(testRoom));
    });

    // AC5
    testWidgets(
      'AC5: ScanQrPage detects invite QR and automatically joins room',
      (tester) async {
        void Function(String)? triggerScan;

        await tester.pumpWidget(
          TranslationProvider(
            child: ProviderScope(
              overrides: [
                roomRepositoryProvider.overrideWithValue(roomRepository),
                voiceRepositoryProvider.overrideWithValue(voiceRepository),
              ],
              child: MaterialApp(
                home: ScanQrPage(
                  scannerBuilder: (context, onScan) {
                    triggerScan = onScan;
                    return const SizedBox(key: Key('scanner_stub'));
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(t.lobby.scanQr), findsOneWidget);
        expect(triggerScan, isNotNull);

        triggerScan!(
          'frecu://join?h=192.168.1.100&p=47800&r=room-qr-999&c=4321',
        );
        await tester.pumpAndSettle();

        verify(
          () => roomRepository.joinRoom(
            hostAddress: '192.168.1.100',
            port: 47800,
            accessCode: '4321',
            displayName: 'Participante',
          ),
        ).called(1);
      },
    );
  });
}
