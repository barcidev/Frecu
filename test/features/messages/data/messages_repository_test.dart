// Mensajes rápidos (corte 3 de la épica de hardware V1): CUANDO llega un
// `quick_message` de un tipo conocido ENTONCES se entrega con su remitente;
// los tipos desconocidos se ignoran. CUANDO se envía uno ENTONCES va por la
// señalización, y sin conexión con el anfitrión falla sin enviar nada.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/messages/data/repositories/messages_repository_impl.dart';
import 'package:frecu/features/messages/domain/entities/quick_message.dart';
import 'package:frecu/features/room/data/datasources/signaling_client_datasource.dart';
import 'package:frecu/features/room/data/models/signaling_message.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignaling extends Mock implements SignalingClientDataSource {}

void main() {
  setUpAll(
    () => registerFallbackValue(const SignalingMessage.ping(timestamp: 0)),
  );

  late _MockSignaling signaling;
  late StreamController<SignalingMessage> incoming;
  late MessagesRepositoryImpl repository;

  setUp(() {
    signaling = _MockSignaling();
    incoming = StreamController<SignalingMessage>.broadcast();
    when(() => signaling.messages).thenAnswer((_) => incoming.stream);
    when(() => signaling.send(any())).thenAnswer((_) {});
    repository = MessagesRepositoryImpl(signaling);
  });

  tearDown(() => incoming.close());

  test(
    'entrega los tipos conocidos con su remitente e ignora el resto',
    () async {
      final received = <QuickMessage>[];
      final sub = repository.watchIncoming().listen(received.add);

      incoming
        ..add(
          const SignalingMessage.quickMessage(peerId: 'peer_2', kind: 'stop'),
        )
        ..add(
          const SignalingMessage.quickMessage(peerId: 'peer_3', kind: 'nuevo'),
        )
        ..add(
          const SignalingMessage.talkState(peerId: 'peer_2', isSpeaking: true),
        )
        ..add(
          const SignalingMessage.quickMessage(peerId: 'peer_3', kind: 'sos'),
        );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received, const [
        QuickMessage(senderId: 'peer_2', kind: QuickMessageKind.stop),
        QuickMessage(senderId: 'peer_3', kind: QuickMessageKind.sos),
      ]);
    },
  );

  test('envía por la señalización con el nombre del tipo', () async {
    when(() => signaling.isConnected).thenReturn(true);

    final result = await repository.send(QuickMessageKind.fuel);

    expect(result.isSuccess, isTrue);
    final sent =
        verify(() => signaling.send(captureAny())).captured.single
            as SignalingQuickMessage;
    expect(sent.kind, 'fuel');
  });

  test('sin conexión con el anfitrión falla y no envía', () async {
    when(() => signaling.isConnected).thenReturn(false);

    final result = await repository.send(QuickMessageKind.sos);

    expect(result.failureOrNull, const Failure.hostUnreachable());
    verifyNever(() => signaling.send(any()));
  });
}
