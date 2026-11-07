// AC1: CUANDO se asigna la nota a una frecu abierta a la hora H (0–23) sin frecus cercanas ENTONCES la nota es la de la posición H mod 12 del círculo de quintas (12→Do, 1→Sol, 2→Re, 3→La, 4→Mi, 5→Si, 6→Fa♯, 7→Re♭, 8→La♭, 9→Mi♭, 10→Si♭, 11→Fa), en octava 4 de 0 a 11 h y en octava 5 de 12 a 23 h, sin importar los minutos (16:24 → Mi5; 15:05 → La5).
// AC3: CUANDO una frecu cercana ya usa la nota y la octava de la hora ENTONCES se asigna la siguiente quinta libre de la misma octava, dando la vuelta de Fa a Do; la misma nota en la otra octava no la ocupa, y si las 12 notas de esa octava están ocupadas se queda con la de su hora.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/usecases/assign_room_note.dart';

/// Nota de cada hora del reloj sobre el círculo de quintas (0 = 12 h).
const _fifthsByHour = [
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
];

/// Clase de altura de cada nota del círculo de quintas.
const _pitchClassByName = {
  'Do': 0,
  'Re♭': 1,
  'Re': 2,
  'Mi♭': 3,
  'Mi': 4,
  'Fa': 5,
  'Fa♯': 6,
  'Sol': 7,
  'La♭': 8,
  'La': 9,
  'Si♭': 10,
  'Si': 11,
};

/// Nota de [name] en la [octave] indicada (4 o 5).
RoomNote _note(String name, int octave) =>
    RoomNote(semitone: (octave - 4) * 12 + _pitchClassByName[name]!);

DateTime _at(int hour, [int minute = 0]) => DateTime(2026, 11, 7, hour, minute);

void main() {
  const assignRoomNote = AssignRoomNote();

  group('AssignRoomNote sin frecus cercanas', () {
    test('AC1: las 24 horas caen en su quinta, en octava 4 de 0 a 11 h y en '
        'octava 5 de 12 a 23 h', () {
      for (var hour = 0; hour < 24; hour++) {
        final note = assignRoomNote.assign(createdAt: _at(hour));
        final expectedName = _fifthsByHour[hour % 12];
        final expectedOctave = hour < 12 ? 4 : 5;
        final reason = '$hour h';

        expect(note.name, expectedName, reason: reason);
        expect(note.octave, expectedOctave, reason: reason);
        expect(note, _note(expectedName, expectedOctave), reason: reason);
        expect(note.fifthsPosition, hour % 12, reason: reason);
      }
    });

    test('AC1: los minutos no cambian la nota', () {
      for (var hour = 0; hour < 24; hour++) {
        final onTheHour = assignRoomNote.assign(createdAt: _at(hour));
        for (final minute in [1, 24, 30, 59]) {
          expect(
            assignRoomNote.assign(createdAt: _at(hour, minute)),
            onTheHour,
            reason: '$hour:$minute',
          );
        }
      }
    });

    test('AC1: 16:24 es Mi5 (659,26 Hz) y 15:05 es La5 (880 Hz)', () {
      final mi5 = assignRoomNote.assign(createdAt: _at(16, 24));
      expect(mi5.name, 'Mi');
      expect(mi5.octave, 5);
      expect(mi5.semitone, 16);
      expect(mi5.hz, closeTo(659.26, 0.005));

      final la5 = assignRoomNote.assign(createdAt: _at(15, 5));
      expect(la5.name, 'La');
      expect(la5.octave, 5);
      expect(la5.semitone, 21);
      expect(la5.hz, closeTo(880, 1e-9));
    });

    test('AC1: medianoche es Do4 y mediodía es Do5', () {
      expect(assignRoomNote.assign(createdAt: _at(0)), _note('Do', 4));
      expect(assignRoomNote.assign(createdAt: _at(12)), _note('Do', 5));
      expect(assignRoomNote.assign(createdAt: _at(11, 59)), _note('Fa', 4));
      expect(assignRoomNote.assign(createdAt: _at(23, 59)), _note('Fa', 5));
    });

    test('AC1: el caso de uso devuelve la misma nota como éxito', () async {
      final result = await assignRoomNote(
        AssignRoomNoteParams(createdAt: _at(16, 24)),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, _note('Mi', 5));
      expect(assignRoomNote.name, 'AssignRoomNote');
    });
  });

  group('AssignRoomNote con frecus cercanas', () {
    test(
      'AC3: si la nota de la hora está ocupada avanza a la siguiente quinta',
      () {
        final note = assignRoomNote.assign(
          createdAt: _at(16, 24),
          nearbyNotes: [_note('Mi', 5)],
        );

        expect(note, _note('Si', 5));
      },
    );

    test('AC3: salta todas las quintas ocupadas seguidas', () {
      final note = assignRoomNote.assign(
        createdAt: _at(16),
        nearbyNotes: [_note('Mi', 5), _note('Si', 5), _note('Fa♯', 5)],
      );

      expect(note, _note('Re♭', 5));
    });

    test('AC3: da la vuelta de Fa a Do', () {
      expect(
        assignRoomNote.assign(
          createdAt: _at(11),
          nearbyNotes: [_note('Fa', 4)],
        ),
        _note('Do', 4),
      );
      expect(
        assignRoomNote.assign(
          createdAt: _at(23),
          nearbyNotes: [_note('Fa', 5), _note('Do', 5)],
        ),
        _note('Sol', 5),
      );
    });

    test('AC3: la misma nota en la otra octava no la ocupa', () {
      expect(
        assignRoomNote.assign(
          createdAt: _at(16),
          nearbyNotes: [_note('Mi', 4)],
        ),
        _note('Mi', 5),
      );
      expect(
        assignRoomNote.assign(createdAt: _at(4), nearbyNotes: [_note('Mi', 5)]),
        _note('Mi', 4),
      );
    });

    test('AC3: las notas que no son de la hora no cambian la asignación', () {
      final note = assignRoomNote.assign(
        createdAt: _at(15, 5),
        nearbyNotes: [_note('Mi', 5), _note('Do', 5), _note('La', 4)],
      );

      expect(note, _note('La', 5));
    });

    test('AC3: notas repetidas cuentan como una sola ocupación', () {
      final note = assignRoomNote.assign(
        createdAt: _at(16),
        nearbyNotes: [_note('Mi', 5), _note('Mi', 5)],
      );

      expect(note, _note('Si', 5));
    });

    test('AC3: si las 12 notas de la octava están ocupadas se queda con la de '
        'su hora', () {
      final octave5 = [
        for (var pitchClass = 0; pitchClass < 12; pitchClass++)
          RoomNote(semitone: 12 + pitchClass),
      ];

      expect(
        assignRoomNote.assign(createdAt: _at(16), nearbyNotes: octave5),
        _note('Mi', 5),
      );
      expect(
        assignRoomNote.assign(createdAt: _at(4), nearbyNotes: octave5),
        _note('Mi', 4),
      );
    });

    test(
      'AC3: el caso de uso aplica las notas cercanas de sus parámetros',
      () async {
        final result = await assignRoomNote(
          AssignRoomNoteParams(
            createdAt: _at(16, 24),
            nearbyNotes: [_note('Mi', 5)],
          ),
        );

        expect(result.dataOrNull, _note('Si', 5));
      },
    );
  });
}
