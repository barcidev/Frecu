// AC4: CUANDO el anfitrión consulta la información de invitación de la frecu ENTONCES se genera y muestra un código QR con el formato URI `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>`.
// AC5: CUANDO un participante escanea el código QR de invitación ENTONCES la aplicación parsea los parámetros de conexión y se une automáticamente a la sala sin ingresar la IP ni el código manualmente.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';

void main() {
  group('Invite QR domain use cases', () {
    const buildUsecase = BuildInviteQr();
    const parseUsecase = ParseInviteFromQr();

    const testInvite = RoomInvite(
      host: '192.168.1.10',
      port: 47800,
      roomId: 'room-alpha-123',
      accessCode: '5678',
    );

    // AC4
    test(
      'AC4: BuildInviteQr generates standard frecu://join URI from room invite',
      () async {
        final result = await buildUsecase(testInvite);
        expect(result.isSuccess, isTrue);
        expect(
          result.dataOrNull,
          equals('frecu://join?h=192.168.1.10&p=47800&r=room-alpha-123&c=5678'),
        );

        final syncUri = buildUsecase.buildUri(testInvite);
        expect(
          syncUri,
          equals('frecu://join?h=192.168.1.10&p=47800&r=room-alpha-123&c=5678'),
        );
      },
    );

    // AC5
    test(
      'AC5: ParseInviteFromQr parses valid frecu://join URI into RoomInvite',
      () async {
        const rawUri =
            'frecu://join?h=192.168.1.10&p=47800&r=room-alpha-123&c=5678';
        final result = await parseUsecase(rawUri);

        expect(result.isSuccess, isTrue);
        final invite = result.dataOrNull;
        expect(invite, isNotNull);
        expect(invite?.host, equals('192.168.1.10'));
        expect(invite?.port, equals(47800));
        expect(invite?.roomId, equals('room-alpha-123'));
        expect(invite?.accessCode, equals('5678'));
      },
    );

    test('AC5: ParseInviteFromQr accepts case-insensitive scheme', () {
      const rawUri = 'FRECU://join?h=192.168.43.1&p=8080&r=test-room&c=9999';
      final result = parseUsecase.parse(rawUri);

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.host, equals('192.168.43.1'));
      expect(result.dataOrNull?.port, equals(8080));
      expect(result.dataOrNull?.roomId, equals('test-room'));
      expect(result.dataOrNull?.accessCode, equals('9999'));
    });

    test(
      'AC5: ParseInviteFromQr rejects invalid scheme or missing parameters',
      () {
        expect(
          parseUsecase.parse('https://join?h=1.2.3.4&p=80&r=r&c=c').isFailure,
          isTrue,
        );
        expect(
          parseUsecase
              .parse('frecu://unknown?h=1.2.3.4&p=80&r=r&c=c')
              .isFailure,
          isTrue,
        );
        expect(
          parseUsecase.parse('frecu://join?p=80&r=r&c=c').isFailure,
          isTrue,
        );
        expect(
          parseUsecase
              .parse('frecu://join?h=1.2.3.4&p=not_a_number&r=r&c=c')
              .isFailure,
          isTrue,
        );
        expect(
          parseUsecase.parse('frecu://join?h=1.2.3.4&p=80&c=c').isFailure,
          isTrue,
        );
        expect(
          parseUsecase.parse('frecu://join?h=1.2.3.4&p=80&r=r').isFailure,
          isTrue,
        );
      },
    );
  });
}
