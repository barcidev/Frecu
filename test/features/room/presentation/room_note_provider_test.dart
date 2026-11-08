// AC4: CUANDO el anfitrión abre una frecu ENTONCES su nota se calcula una vez con la hora local de apertura y las notas de las frecus cercanas descubiertas (si una ya usa la nota de su hora, toma la siguiente quinta libre), queda en la frecu activa y se publica con esa misma nota en el TXT de mDNS y en el QR de invitación.
// AC5: CUANDO un participante se une a una frecu descubierta por mDNS o escaneada por QR ENTONCES su frecu activa lleva la nota que trajo la invitación, sin recalcularla con su propia hora; si la invitación no trae nota, o se une por IP, la frecu activa queda sin nota y la unión funciona igual.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

/// Frecu que devuelve el repositorio, abierta a [createdAt] (hora local).
Room _roomOpenedAt(DateTime createdAt) {
  return Room(
    id: 'room-123',
    name: 'Frecu',
    hostAddress: '192.168.43.1',
    port: 47800,
    accessCode: '1234',
    createdAt: createdAt,
  );
}

void main() {
  late _MockRoomRepository repository;
  late ProviderContainer container;

  // 04:30 hora local: Mi4 (semitono 4) sin choques.
  final morning = DateTime(2026, 11, 8, 4, 30);
  // 16:24 hora local: Mi5 (semitono 16) sin choques.
  final afternoon = DateTime(2026, 11, 8, 16, 24);

  void stubCreateRoom(Room room) {
    when(
      () => repository.createRoom(
        name: any(named: 'name'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => Result.success(room));
  }

  void stubJoinRoom(Room room) {
    when(
      () => repository.joinRoom(
        hostAddress: any(named: 'hostAddress'),
        port: any(named: 'port'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => Result.success(room));
  }

  setUp(() {
    repository = _MockRoomRepository();
    container = ProviderContainer.test(
      overrides: [roomRepositoryProvider.overrideWithValue(repository)],
    );
  });

  group('Nota de la frecu en RoomNotifier', () {
    test(
      'AC4: al abrir la frecu asigna la nota de su hora local de apertura',
      () async {
        stubCreateRoom(_roomOpenedAt(morning));
        final notifier = container.read(roomNotifierProvider.notifier);

        final result = await notifier.createRoom(
          name: 'Frecu',
          accessCode: '1234',
        );

        expect(result.dataOrNull?.note, const RoomNote(semitone: 4));
        expect(
          container.read(roomNotifierProvider)?.note,
          const RoomNote(semitone: 4),
        );
        expect(container.read(roomNotifierProvider), result.dataOrNull);
      },
    );

    test(
      'AC4: usa la hora de apertura de la frecu, no la hora actual',
      () async {
        stubCreateRoom(_roomOpenedAt(afternoon));
        final notifier = container.read(roomNotifierProvider.notifier);

        final result = await notifier.createRoom(
          name: 'Frecu',
          accessCode: '1234',
        );

        expect(result.dataOrNull?.note, const RoomNote(semitone: 16));
        expect(
          container.read(roomNotifierProvider)?.note,
          const RoomNote(semitone: 16),
        );
      },
    );

    test(
      'AC4: si una frecu cercana ya usa la nota de su hora toma la siguiente '
      'quinta libre',
      () async {
        stubCreateRoom(_roomOpenedAt(morning));
        final notifier = container.read(roomNotifierProvider.notifier);

        // Mi4 ocupada (Mi5 es otra octava y no la ocupa): sigue Si4.
        final firstFree = await notifier.createRoom(
          name: 'Frecu',
          accessCode: '1234',
          nearbyNotes: const [RoomNote(semitone: 4), RoomNote(semitone: 16)],
        );
        expect(firstFree.dataOrNull?.note, const RoomNote(semitone: 11));
        expect(
          container.read(roomNotifierProvider)?.note,
          const RoomNote(semitone: 11),
        );

        // Mi4 y Si4 ocupadas: sigue Fa♯4.
        final secondFree = await notifier.createRoom(
          name: 'Frecu',
          accessCode: '1234',
          nearbyNotes: const [RoomNote(semitone: 4), RoomNote(semitone: 11)],
        );
        expect(secondFree.dataOrNull?.note, const RoomNote(semitone: 6));
      },
    );

    test('AC5: al unirse con la nota de la invitación la conserva sin '
        'recalcularla con su propia hora', () async {
      stubJoinRoom(_roomOpenedAt(morning));
      final notifier = container.read(roomNotifierProvider.notifier);

      final result = await notifier.joinRoom(
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '1234',
        displayName: 'Ana',
        note: const RoomNote(semitone: 21),
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.note, const RoomNote(semitone: 21));
      expect(
        container.read(roomNotifierProvider)?.note,
        const RoomNote(semitone: 21),
      );
    });

    test('AC5: al unirse sin nota la frecu activa queda sin nota y la unión '
        'funciona igual', () async {
      stubJoinRoom(_roomOpenedAt(morning));
      final notifier = container.read(roomNotifierProvider.notifier);

      final result = await notifier.joinRoom(
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '1234',
        displayName: 'Ana',
      );

      expect(result.isSuccess, isTrue);
      expect(container.read(roomNotifierProvider), isNotNull);
      expect(container.read(roomNotifierProvider)?.id, 'room-123');
      expect(container.read(roomNotifierProvider)?.note, isNull);
    });
  });
}
