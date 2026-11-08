// AC1: CUANDO el anfitrión toca «Abrir frecu» en la nueva frecu ENTONCES la frecu abierta lleva exactamente la nota que mostraba la pantalla en ese momento, aunque la hora haya cambiado desde que se calculó. La publica con esa nota en mDNS y se la da al servidor para `welcome`, y la cabecera de la frecu activa la muestra.
// AC2: CUANDO alguien se une por IP manual, sin mDNS ni QR, ENTONCES la frecu activa muestra en la cabecera la nota del anfitrión. CUANDO la invitación trae una nota y `welcome` trae otra ENTONCES la frecu activa lleva la de `welcome`.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/repositories/room_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockRoomRepository extends Mock implements RoomRepository {}

/// Frecu que devuelve el repositorio: abierta a las 16:24 hora local (le
/// tocaría Mi5) y con la [note] que trajo `welcome`.
Room _room({RoomNote? note}) {
  return Room(
    id: 'room-123',
    name: 'Frecu',
    hostAddress: '192.168.43.1',
    port: 47800,
    accessCode: '1234',
    createdAt: DateTime(2026, 11, 8, 16, 24),
    note: note,
  );
}

void main() {
  late _MockRoomRepository repository;
  late ProviderContainer container;

  // Mi4: la nota de las 04:30, distinta de Mi5, la de las 16:24.
  const shownNote = RoomNote(semitone: 4);
  const hostNote = RoomNote(semitone: 21);
  const inviteNote = RoomNote(semitone: 7);

  setUpAll(() {
    registerFallbackValue(const RoomNote(semitone: 0));
  });

  void stubCreateRoom() {
    when(
      () => repository.createRoom(
        name: any(named: 'name'),
        accessCode: any(named: 'accessCode'),
        displayName: any(named: 'displayName'),
        note: any(named: 'note'),
      ),
    ).thenAnswer(
      (invocation) async => Result.success(
        _room(note: invocation.namedArguments[#note] as RoomNote?),
      ),
    );
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

  group('Nota recibida al crear la frecu', () {
    test('AC1: la frecu lleva la nota recibida, no la de su hora de '
        'apertura', () async {
      stubCreateRoom();
      final notifier = container.read(roomNotifierProvider.notifier);

      final result = await notifier.createRoom(
        name: 'Frecu',
        accessCode: '1234',
        displayName: 'Ana',
        nearbyNotes: const [RoomNote(semitone: 16)],
        note: shownNote,
      );

      expect(result.dataOrNull?.note, shownNote);
      expect(container.read(roomNotifierProvider)?.note, shownNote);
    });

    test('AC1: le da la nota al repositorio para que el servidor la mande '
        'en welcome', () async {
      stubCreateRoom();
      final notifier = container.read(roomNotifierProvider.notifier);

      await notifier.createRoom(
        name: 'Frecu',
        accessCode: '1234',
        displayName: 'Ana',
        note: shownNote,
      );

      verify(
        () => repository.createRoom(
          name: 'Frecu',
          accessCode: '1234',
          displayName: 'Ana',
          note: shownNote,
        ),
      ).called(1);
    });
  });

  group('Nota de welcome al unirse', () {
    test('AC2: al unirse por IP, sin invitación, lleva la nota que trajo '
        'welcome', () async {
      stubJoinRoom(_room(note: hostNote));
      final notifier = container.read(roomNotifierProvider.notifier);

      final result = await notifier.joinRoom(
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '1234',
        displayName: 'Bea',
      );

      expect(result.dataOrNull?.note, hostNote);
      expect(container.read(roomNotifierProvider)?.note, hostNote);
    });

    test('AC2: con nota en la invitación y otra en welcome lleva la de '
        'welcome', () async {
      stubJoinRoom(_room(note: hostNote));
      final notifier = container.read(roomNotifierProvider.notifier);

      final result = await notifier.joinRoom(
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '1234',
        displayName: 'Bea',
        note: inviteNote,
      );

      expect(result.dataOrNull?.note, hostNote);
      expect(container.read(roomNotifierProvider)?.note, hostNote);
    });

    test('AC2: si welcome no trae nota lleva la de la invitación', () async {
      stubJoinRoom(_room());
      final notifier = container.read(roomNotifierProvider.notifier);

      final result = await notifier.joinRoom(
        hostAddress: '192.168.43.1',
        port: 47800,
        accessCode: '1234',
        displayName: 'Bea',
        note: inviteNote,
      );

      expect(result.dataOrNull?.note, inviteNote);
      expect(container.read(roomNotifierProvider)?.note, inviteNote);
    });
  });
}
