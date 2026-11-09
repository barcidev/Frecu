// Invitar por Bluetooth (corte 8 de la épica de hardware V1): los datos
// públicos de la frecu van y vuelven sin perder nada; lo que no se entiende
// se ignora; y el anfitrión limita los códigos equivocados.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/bluetooth_invite/domain/entities/bluetooth_invite_protocol.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/usecases/merge_nearby_rooms.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

void main() {
  group('BluetoothInviteProtocol', () {
    test('la frecu va y vuelve con su id, nombre y nota, sin dirección', () {
      final bytes = BluetoothInviteProtocol.encodeInfo(
        roomId: 'room-1',
        name: 'Ruta 40',
        note: const RoomNote(semitone: 9),
      );

      final room = BluetoothInviteProtocol.decodeInfo(bytes, bluetoothId: 'b1');

      expect(
        room,
        const NearbyRoom(
          roomId: 'room-1',
          name: 'Ruta 40',
          hostAddress: '',
          port: 0,
          note: RoomNote(semitone: 9),
          bluetoothId: 'b1',
        ),
      );
      expect(room!.viaBluetooth, isTrue);
      // Lo público no lleva el código ni la red.
      expect(utf8.decode(bytes), isNot(contains('4827')));
    });

    test('otra versión, JSON roto o sin id no se listan', () {
      List<int> json(Object value) => utf8.encode(jsonEncode(value));

      for (final bytes in [
        json({'v': 2, 'r': 'room-1', 'name': 'x'}),
        json({'v': 1, 'name': 'x'}),
        json([1, 2]),
        utf8.encode('{no es json'),
        [0xff, 0xfe],
      ]) {
        expect(
          BluetoothInviteProtocol.decodeInfo(bytes, bluetoothId: 'b1'),
          isNull,
        );
      }
    });
  });

  group('BluetoothUnlockGate', () {
    test('el código correcto abre; tras 5 equivocados en 30 s rechaza todo '
        '30 s, también el correcto', () {
      var now = DateTime(2026, 11, 10, 12);
      final gate = BluetoothUnlockGate(now: () => now);

      expect(gate.check('4827', accessCode: '4827'), isTrue);
      for (var i = 0; i < BluetoothUnlockGate.maxFailures; i++) {
        expect(gate.check('000$i', accessCode: '4827'), isFalse);
        now = now.add(const Duration(seconds: 1));
      }
      expect(gate.check('4827', accessCode: '4827'), isFalse);

      now = now.add(BluetoothUnlockGate.lockout);
      expect(gate.check('4827', accessCode: '4827'), isTrue);
    });

    test('los fallos viejos dejan de contar y reset los olvida', () {
      var now = DateTime(2026, 11, 10, 12);
      final gate = BluetoothUnlockGate(now: () => now);

      for (var i = 0; i < BluetoothUnlockGate.maxFailures - 1; i++) {
        gate.check('0000', accessCode: '4827');
      }
      now = now.add(BluetoothUnlockGate.window);
      gate.check('0000', accessCode: '4827');
      expect(gate.check('4827', accessCode: '4827'), isTrue);

      for (var i = 0; i < BluetoothUnlockGate.maxFailures; i++) {
        gate.check('0000', accessCode: '4827');
      }
      gate.reset();
      expect(gate.check('4827', accessCode: '4827'), isTrue);
    });
  });

  test('mergeNearbyRooms: una frecu en la red y por Bluetooth va una vez, '
      'la de la red', () {
    const local = NearbyRoom(
      roomId: 'a',
      name: 'A',
      hostAddress: '192.168.43.1',
      port: 47800,
    );
    const sameByBluetooth = NearbyRoom(
      roomId: 'a',
      name: 'A',
      hostAddress: '',
      port: 0,
      bluetoothId: 'b1',
    );
    const onlyBluetooth = NearbyRoom(
      roomId: 'b',
      name: 'B',
      hostAddress: '',
      port: 0,
      bluetoothId: 'b2',
    );

    expect(mergeNearbyRooms([local], const []), [local]);
    expect(mergeNearbyRooms([local], [sameByBluetooth, onlyBluetooth]), [
      local,
      onlyBluetooth,
    ]);
  });
}
