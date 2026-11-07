import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_note.freezed.dart';

/// Nota musical de una frecu: su canal reconocible en voz alta
/// ("estamos en Mi").
///
/// Se guarda solo como [semitone] desde Do4 (0–23), la misma forma con la que
/// viaja por la red; el nombre, la octava, la clase de altura y la frecuencia
/// se derivan de él.
@freezed
abstract class RoomNote with _$RoomNote {
  /// Nota a [semitone] semitonos de Do4 (0–23).
  @Assert(
    'semitone >= 0 && semitone < RoomNote.semitoneCount',
    'El semitono de la nota va de 0 a 23.',
  )
  const factory RoomNote({required int semitone}) = _RoomNote;

  const RoomNote._();

  /// Cantidad de notas posibles: dos octavas desde Do4.
  static const int semitoneCount = 24;

  /// Clases de altura del círculo de quintas, en el orden de las horas del
  /// reloj (0 = 12 h → Do, 1 → Sol … 11 → Fa).
  static const List<int> circleOfFifths = [
    0,
    7,
    2,
    9,
    4,
    11,
    6,
    1,
    8,
    3,
    10,
    5,
  ];

  static const List<String> _solfegeNames = [
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

  /// Nota del [semitone] dado, o `null` si falta o está fuera de 0–23.
  static RoomNote? tryFromSemitone(int? semitone) {
    if (semitone == null || semitone < 0 || semitone >= semitoneCount) {
      return null;
    }
    return RoomNote(semitone: semitone);
  }

  /// Clase de altura (0 = Do … 11 = Si).
  int get pitchClass => semitone % 12;

  /// Octava científica (4 o 5).
  int get octave => 4 + semitone ~/ 12;

  /// Número MIDI (Do4 = 60).
  int get midi => 60 + semitone;

  /// Nombre de solfeo de la nota (Do, Re♭, Re …).
  String get name => _solfegeNames[pitchClass];

  /// Hora del reloj de quintas en la que cae la nota (0 = 12 h).
  int get fifthsPosition => pitchClass * 7 % 12;

  /// Frecuencia en Hz con La4 = 440 Hz y temperamento igual.
  double get hz => 440 * math.pow(2, (midi - 69) / 12).toDouble();
}

/// Guarda la nota en JSON como su semitono; un valor ausente o fuera de 0–23
/// se lee como sin nota.
final class RoomNoteConverter implements JsonConverter<RoomNote?, int?> {
  /// Constructor constante para usarlo como anotación.
  const RoomNoteConverter();

  @override
  RoomNote? fromJson(int? json) => RoomNote.tryFromSemitone(json);

  @override
  int? toJson(RoomNote? object) => object?.semitone;
}
