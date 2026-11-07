// AC4: CUANDO se crea un `Room`, un `NearbyRoom` o un `RoomInvite` sin nota ENTONCES su nota es nula y lo demás no cambia; con nota, la conserva y sobrevive a `toJson`/`fromJson` como el semitono `note`, y un `note` ausente, nulo o fuera de 0–23 se lee como sin nota.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Pasa [json] por texto, como si viajara o se guardara.
Map<String, dynamic> _throughText(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  final createdAt = DateTime(2026, 11, 7, 16, 24);
  const mi5 = RoomNote(semitone: 16);

  Room buildRoom({RoomNote? note}) => Room(
    id: 'room-1',
    name: 'Moto Rutas',
    hostAddress: '192.168.43.1',
    port: 47800,
    accessCode: '1234',
    createdAt: createdAt,
    note: note,
  );

  RoomInvite buildInvite({RoomNote? note}) => RoomInvite(
    host: '192.168.43.1',
    port: 47800,
    roomId: 'room-1',
    accessCode: '1234',
    note: note,
  );

  group('Room con nota opcional', () {
    test('AC4: sin nota la nota es nula y lo demás no cambia', () {
      final room = Room(
        id: 'room-1',
        name: 'Moto Rutas',
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '1234',
        createdAt: createdAt,
      );

      expect(room.note, isNull);
      expect(room.id, 'room-1');
      expect(room.name, 'Moto Rutas');
      expect(room.hostAddress, '192.168.43.1');
      expect(room.port, 47800);
      expect(room.accessCode, '1234');
      expect(room.createdAt, createdAt);
      expect(room.maxParticipants, 6);
      expect(room, buildRoom());
      expect(Room.fromJson(_throughText(room.toJson())), room);
    });

    test('AC4: con nota la conserva y viaja en JSON como semitono', () {
      final room = buildRoom(note: mi5);

      expect(room.note, mi5);
      expect(room, isNot(buildRoom()));

      final json = _throughText(room.toJson());
      expect(json['note'], 16);

      final restored = Room.fromJson(json);
      expect(restored, room);
      expect(restored.note?.name, 'Mi');
      expect(restored.note?.octave, 5);
      expect(buildRoom().copyWith(note: mi5), room);
    });

    test('AC4: un note ausente, nulo o fuera de 0–23 se lee como sin nota', () {
      final base = _throughText(buildRoom().toJson());

      final absent = Map<String, dynamic>.of(base)..remove('note');
      expect(Room.fromJson(absent).note, isNull);
      expect(Room.fromJson(absent), buildRoom());

      expect(Room.fromJson({...base, 'note': null}).note, isNull);
      expect(Room.fromJson({...base, 'note': -1}).note, isNull);
      expect(Room.fromJson({...base, 'note': 24}).note, isNull);
      expect(Room.fromJson({...base, 'note': 99}).note, isNull);
      expect(
        Room.fromJson({...base, 'note': 0}).note,
        const RoomNote(semitone: 0),
      );
      expect(
        Room.fromJson({...base, 'note': 23}).note,
        const RoomNote(semitone: 23),
      );
    });
  });

  group('RoomInvite con nota opcional', () {
    test('AC4: sin nota la nota es nula y lo demás no cambia', () {
      const invite = RoomInvite(
        host: '192.168.43.1',
        port: 47800,
        roomId: 'room-1',
        accessCode: '1234',
      );

      expect(invite.note, isNull);
      expect(invite.host, '192.168.43.1');
      expect(invite.port, 47800);
      expect(invite.roomId, 'room-1');
      expect(invite.accessCode, '1234');
      expect(invite, buildInvite());
      expect(RoomInvite.fromJson(_throughText(invite.toJson())), invite);
    });

    test('AC4: con nota la conserva y viaja en JSON como semitono', () {
      final invite = buildInvite(note: mi5);

      expect(invite.note, mi5);
      expect(invite, isNot(buildInvite()));

      final json = _throughText(invite.toJson());
      expect(json['note'], 16);
      expect(RoomInvite.fromJson(json), invite);
      expect(buildInvite().copyWith(note: mi5), invite);
    });

    test('AC4: un note ausente, nulo o fuera de 0–23 se lee como sin nota', () {
      final base = _throughText(buildInvite().toJson());

      final absent = Map<String, dynamic>.of(base)..remove('note');
      expect(RoomInvite.fromJson(absent).note, isNull);
      expect(RoomInvite.fromJson(absent), buildInvite());

      expect(RoomInvite.fromJson({...base, 'note': null}).note, isNull);
      expect(RoomInvite.fromJson({...base, 'note': -1}).note, isNull);
      expect(RoomInvite.fromJson({...base, 'note': 24}).note, isNull);
      expect(
        RoomInvite.fromJson({...base, 'note': 21}).note,
        const RoomNote(semitone: 21),
      );
    });
  });
}
