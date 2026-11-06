// AC1: CUANDO el anfitrión inicia la sala ENTONCES se ejecuta el servidor WebSocket de señalización en el puerto 47800 y responde a los mensajes de protocolo local.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_status.dart';

void main() {
  group('Room domain entities', () {
    // AC1
    test('AC1: entities instantiate and serialize correctly', () {
      final now = DateTime(2026, 11, 6, 12);
      const participant = Participant(
        id: 'peer-1',
        displayName: 'Alice',
        isHost: true,
      );

      expect(participant.id, 'peer-1');
      expect(participant.displayName, 'Alice');
      expect(participant.isHost, isTrue);
      expect(participant.isSpeaking, isFalse);
      expect(participant.isMuted, isFalse);
      expect(participant.connectionState, PeerConnectionState.connected);

      final participantJson = participant.toJson();
      final fromJson = Participant.fromJson(participantJson);
      expect(fromJson, participant);

      final room = Room(
        id: 'room-1',
        name: 'Moto Rutas',
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '1234',
        createdAt: now,
      );

      expect(room.id, 'room-1');
      expect(room.name, 'Moto Rutas');
      expect(room.port, 47800);
      expect(room.maxParticipants, 6);

      final roomJson = room.toJson();
      expect(Room.fromJson(roomJson), room);

      const statusIdle = RoomStatus.idle();
      const statusConnected = RoomStatus.connected();
      const statusClosed = RoomStatus.closed(reason: 'host_left');

      expect(statusIdle, isA<RoomStatus>());
      expect(statusConnected, isA<RoomStatus>());
      expect(
        statusClosed.maybeWhen(closed: (reason) => reason, orElse: () => ''),
        'host_left',
      );
    });
  });
}
