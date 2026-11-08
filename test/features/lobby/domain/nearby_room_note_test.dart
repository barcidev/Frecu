// AC4: CUANDO se crea un `Room`, un `NearbyRoom` o un `RoomInvite` sin nota ENTONCES su nota es nula y lo demás no cambia; con nota, la conserva y sobrevive a `toJson`/`fromJson` como el semitono `note`, y un `note` ausente, nulo o fuera de 0–23 se lee como sin nota.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Pasa [json] por texto, como si viajara o se guardara.
Map<String, dynamic> _throughText(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

NearbyRoom _buildNearby({RoomNote? note}) => NearbyRoom(
  roomId: 'room-1',
  name: 'Moto Rutas',
  hostAddress: '192.168.43.1',
  port: 47800,
  note: note,
);

void main() {
  const la5 = RoomNote(semitone: 21);

  group('NearbyRoom con nota opcional', () {
    test('AC4: sin nota la nota es nula y lo demás no cambia', () {
      const nearby = NearbyRoom(
        roomId: 'room-1',
        name: 'Moto Rutas',
        hostAddress: '192.168.43.1',
        port: 47800,
      );

      expect(nearby.note, isNull);
      expect(nearby.roomId, 'room-1');
      expect(nearby.name, 'Moto Rutas');
      expect(nearby.hostAddress, '192.168.43.1');
      expect(nearby.port, 47800);
      expect(nearby.protocolVersion, 1);
      expect(nearby, _buildNearby());
      expect(NearbyRoom.fromJson(_throughText(nearby.toJson())), nearby);
    });

    test('AC4: con nota la conserva y viaja en JSON como semitono', () {
      final nearby = _buildNearby(note: la5);

      expect(nearby.note, la5);
      expect(nearby, isNot(_buildNearby()));

      final json = _throughText(nearby.toJson());
      expect(json['note'], 21);

      final restored = NearbyRoom.fromJson(json);
      expect(restored, nearby);
      expect(restored.note?.name, 'La');
      expect(restored.note?.octave, 5);
      expect(restored.note?.hz, closeTo(880, 1e-9));
      expect(_buildNearby().copyWith(note: la5), nearby);
    });

    test('AC4: un note ausente, nulo o fuera de 0–23 se lee como sin nota', () {
      final base = _throughText(_buildNearby().toJson());

      final absent = Map<String, dynamic>.of(base)..remove('note');
      expect(NearbyRoom.fromJson(absent).note, isNull);
      expect(NearbyRoom.fromJson(absent), _buildNearby());

      expect(NearbyRoom.fromJson({...base, 'note': null}).note, isNull);
      expect(NearbyRoom.fromJson({...base, 'note': -1}).note, isNull);
      expect(NearbyRoom.fromJson({...base, 'note': 24}).note, isNull);
      expect(
        NearbyRoom.fromJson({...base, 'note': 4}).note,
        const RoomNote(semitone: 4),
      );
    });
  });
}
