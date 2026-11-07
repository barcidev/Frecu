import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Parámetros para asignar la nota de una frecu.
final class AssignRoomNoteParams {
  /// Constructor.
  const AssignRoomNoteParams({
    required this.createdAt,
    this.nearbyNotes = const [],
  });

  /// Momento de apertura de la frecu; cuenta su hora local.
  final DateTime createdAt;

  /// Notas de las frecus cercanas, que no se repiten.
  final Iterable<RoomNote> nearbyNotes;
}

/// Caso de uso que asigna la nota de una frecu con su hora de apertura sobre
/// el círculo de quintas.
///
/// La hora mod 12 elige la quinta (12 → Do, 1 → Sol … 11 → Fa) y la mitad del
/// día la octava (4 de 0 a 11 h, 5 de 12 a 23 h). Si una frecu cercana ya usa
/// esa nota y octava, avanza a la siguiente quinta libre de la misma octava;
/// si las 12 están ocupadas, se queda con la de su hora.
final class AssignRoomNote implements UseCase<RoomNote, AssignRoomNoteParams> {
  /// Constructor constante.
  const AssignRoomNote();

  @override
  String get name => 'AssignRoomNote';

  @override
  Future<Result<RoomNote>> call(AssignRoomNoteParams params) async {
    return Result.success(
      assign(createdAt: params.createdAt, nearbyNotes: params.nearbyNotes),
    );
  }

  /// Calcula de forma sincrónica la nota de una frecu abierta en [createdAt].
  RoomNote assign({
    required DateTime createdAt,
    Iterable<RoomNote> nearbyNotes = const [],
  }) {
    final hour = createdAt.toLocal().hour;
    final octaveStart = hour < 12 ? 0 : 12;
    final start = hour % 12;
    final taken = {for (final note in nearbyNotes) note.semitone};
    const fifths = RoomNote.circleOfFifths;

    for (var step = 0; step < fifths.length; step++) {
      final semitone = octaveStart + fifths[(start + step) % fifths.length];
      if (!taken.contains(semitone)) {
        return RoomNote(semitone: semitone);
      }
    }
    return RoomNote(semitone: octaveStart + fifths[start]);
  }
}
