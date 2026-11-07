// AC3: CUANDO se construye el QR de una invitación con nota ENTONCES la URI es `frecu://join?h=<ip>&p=<puerto>&r=<roomId>&c=<codigo>&n=<semitono>`, y sin nota es la misma URI de antes sin `n`; CUANDO se escanea una URI con `n` entre 0 y 23 ENTONCES la invitación trae esa nota, y si `n` falta o es inválido la invitación es válida, sin nota y con los demás datos iguales.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';

void main() {
  group('Nota en el QR de invitación', () {
    const buildUsecase = BuildInviteQr();
    const parseUsecase = ParseInviteFromQr();

    const invite = RoomInvite(
      host: '192.168.1.10',
      port: 47800,
      roomId: 'room-alpha-123',
      accessCode: '5678',
    );
    const baseUri =
        'frecu://join?h=192.168.1.10&p=47800&r=room-alpha-123&c=5678';

    test('AC3: con nota, la URI suma n=<semitono> al final', () async {
      final withNote = invite.copyWith(note: const RoomNote(semitone: 16));

      expect(buildUsecase.buildUri(withNote), '$baseUri&n=16');

      final result = await buildUsecase(withNote);
      expect(result.dataOrNull, '$baseUri&n=16');

      expect(
        buildUsecase.buildUri(
          invite.copyWith(note: const RoomNote(semitone: 0)),
        ),
        '$baseUri&n=0',
      );
      expect(
        buildUsecase.buildUri(
          invite.copyWith(note: const RoomNote(semitone: 23)),
        ),
        '$baseUri&n=23',
      );
    });

    test('AC3: sin nota, la URI es la misma de antes, sin n', () {
      expect(buildUsecase.buildUri(invite), baseUri);
    });

    test(
      'AC3: al escanear una URI con n válido la invitación trae esa nota',
      () {
        final result = parseUsecase.parse('$baseUri&n=16');

        expect(result.isSuccess, isTrue);
        expect(
          result.dataOrNull,
          invite.copyWith(note: const RoomNote(semitone: 16)),
        );
        expect(result.dataOrNull?.note?.name, 'Mi');
        expect(result.dataOrNull?.note?.octave, 5);
      },
    );

    test('AC3: las 24 notas sobreviven a construir y escanear el QR', () {
      for (var semitone = 0; semitone < RoomNote.semitoneCount; semitone++) {
        final withNote = invite.copyWith(note: RoomNote(semitone: semitone));

        final parsed = parseUsecase.parse(buildUsecase.buildUri(withNote));

        expect(parsed.dataOrNull, withNote, reason: 'semitono $semitone');
      }
    });

    test(
      'AC3: si n falta o es inválido, la invitación es válida, sin nota y con '
      'los demás datos iguales',
      () {
        const rawUris = [
          baseUri,
          '$baseUri&n=',
          '$baseUri&n=Mi',
          '$baseUri&n=4.5',
          '$baseUri&n=-1',
          '$baseUri&n=24',
          '$baseUri&n=99',
        ];

        for (final rawUri in rawUris) {
          final result = parseUsecase.parse(rawUri);

          expect(result.isSuccess, isTrue, reason: rawUri);
          expect(result.dataOrNull, invite, reason: rawUri);
          expect(result.dataOrNull?.note, isNull, reason: rawUri);
        }
      },
    );
  });
}
