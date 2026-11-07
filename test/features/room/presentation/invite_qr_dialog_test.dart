// AC4: CUANDO el anfitrión consulta la información de invitación de la frecu ENTONCES se genera y muestra un código QR con el formato URI `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/app/app.dart';
import 'package:frecu/app/router/app_router.dart';
import 'package:frecu/app/router/app_router.gr.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/i18n/strings.g.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MockRoomRepository extends Mock implements RoomRepository {}

class MockVoiceRepository extends Mock implements VoiceRepository {}

class _TestRoomNotifier extends RoomNotifier {
  _TestRoomNotifier(this._initialRoom);

  final Room _initialRoom;

  @override
  Room? build() => _initialRoom;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Invite QR dialog in RoomPage', () {
    late MockRoomRepository roomRepository;
    late MockVoiceRepository voiceRepository;

    final testRoom = Room(
      id: 'room-abc-123',
      name: 'Frecu Anfitrión',
      hostAddress: '192.168.1.50',
      port: 47800,
      accessCode: '7788',
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
    });

    // AC4
    testWidgets(
      'AC4: RoomPage shows QR button and tapping it displays invite QR code',
      (tester) async {
        final router = AppRouter();
        await tester.pumpWidget(
          TranslationProvider(
            child: ProviderScope(
              overrides: [
                roomRepositoryProvider.overrideWithValue(roomRepository),
                voiceRepositoryProvider.overrideWithValue(voiceRepository),
                roomNotifierProvider.overrideWith(
                  () => _TestRoomNotifier(testRoom),
                ),
              ],
              child: FrecuApp(appRouter: router),
            ),
          ),
        );

        unawaited(router.push(RoomRoute(roomId: testRoom.id)));
        await tester.pumpAndSettle();

        final qrButton = find.byIcon(Icons.qr_code);
        expect(qrButton, findsOneWidget);

        await tester.tap(qrButton);
        await tester.pumpAndSettle();

        expect(find.text('Código QR de invitación'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(
          find.text(
            'frecu://join?h=192.168.1.50&p=47800&r=room-abc-123&c=7788',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
