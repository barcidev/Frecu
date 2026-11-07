// AC2: CUANDO se lee una nota ENTONCES expone su nombre, octava, clase de altura (0–11), semitono desde Do4 (0–23), posición en el círculo de quintas y frecuencia en Hz con La4 = 440 Hz y temperamento igual (Do4 ≈ 261,63 Hz; Mi5 ≈ 659,26 Hz; La5 = 880 Hz); se reconstruye desde su semitono y un semitono fuera de 0–23 no da nota.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Nombre de solfeo por clase de altura (0 = Do … 11 = Si).
const _namesByPitchClass = [
  'Do',
  'Re♭',
  'Re',
  'Mi♭',
  'Mi',
  'Fa',
  'Fa♯',
  'Sol',
  'La♭',
  'La',
  'Si♭',
  'Si',
];

/// Posición en el reloj de quintas por clase de altura (0 = 12 h).
const _fifthsPositionByPitchClass = [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5];

void main() {
  group('RoomNote', () {
    test('AC2: las 24 notas exponen nombre, octava, clase, semitono, MIDI, '
        'posición en las quintas y Hz derivados del semitono', () {
      for (var semitone = 0; semitone < 24; semitone++) {
        final note = RoomNote(semitone: semitone);
        final pitchClass = semitone % 12;
        final reason = 'semitono $semitone';

        expect(note.semitone, semitone, reason: reason);
        expect(note.pitchClass, pitchClass, reason: reason);
        expect(note.octave, semitone < 12 ? 4 : 5, reason: reason);
        expect(note.midi, 60 + semitone, reason: reason);
        expect(note.name, _namesByPitchClass[pitchClass], reason: reason);
        expect(
          note.fifthsPosition,
          _fifthsPositionByPitchClass[pitchClass],
          reason: reason,
        );
        expect(
          note.hz,
          closeTo(440 * math.pow(2, (60 + semitone - 69) / 12), 1e-9),
          reason: reason,
        );
      }
    });

    test('AC2: las frecuencias de referencia siguen La4 = 440 Hz', () {
      const do4 = RoomNote(semitone: 0);
      expect(do4.name, 'Do');
      expect(do4.octave, 4);
      expect(do4.hz, closeTo(261.63, 0.005));

      const la4 = RoomNote(semitone: 9);
      expect(la4.name, 'La');
      expect(la4.octave, 4);
      expect(la4.hz, closeTo(440, 1e-9));

      const mi5 = RoomNote(semitone: 16);
      expect(mi5.name, 'Mi');
      expect(mi5.octave, 5);
      expect(mi5.hz, closeTo(659.26, 0.005));

      const la5 = RoomNote(semitone: 21);
      expect(la5.name, 'La');
      expect(la5.octave, 5);
      expect(la5.hz, closeTo(880, 1e-9));

      const si5 = RoomNote(semitone: 23);
      expect(si5.name, 'Si');
      expect(si5.octave, 5);
      expect(si5.hz, closeTo(987.77, 0.005));
    });

    test(
      'AC2: el círculo de quintas empieza en Do y recorre las 12 clases',
      () {
        expect(RoomNote.semitoneCount, 24);
        expect(RoomNote.circleOfFifths, [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5]);
        expect(
          RoomNote.circleOfFifths
              .map((pitchClass) => _namesByPitchClass[pitchClass])
              .toList(),
          [
            'Do',
            'Sol',
            'Re',
            'La',
            'Mi',
            'Si',
            'Fa♯',
            'Re♭',
            'La♭',
            'Mi♭',
            'Si♭',
            'Fa',
          ],
        );
      },
    );

    test('AC2: la nota se reconstruye desde su semitono', () {
      for (var semitone = 0; semitone < 24; semitone++) {
        final rebuilt = RoomNote.tryFromSemitone(semitone);
        expect(rebuilt, RoomNote(semitone: semitone));
        expect(rebuilt?.semitone, semitone);
      }
      expect(RoomNote.tryFromSemitone(16), const RoomNote(semitone: 16));
      expect(const RoomNote(semitone: 16), isNot(const RoomNote(semitone: 4)));
    });

    test('AC2: un semitono ausente o fuera de 0–23 no da nota', () {
      expect(RoomNote.tryFromSemitone(null), isNull);
      expect(RoomNote.tryFromSemitone(-1), isNull);
      expect(RoomNote.tryFromSemitone(24), isNull);
      expect(RoomNote.tryFromSemitone(99), isNull);
    });
  });
}
