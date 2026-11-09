// Invitar por Bluetooth (corte 8 de la épica de hardware V1), con los
// gestores de Bluetooth simulados: el anfitrión sirve los datos públicos a
// todos y la invitación solo a quien escribió el código; el invitado lista
// las frecus que encuentra y pide la invitación con el código.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/features/bluetooth_invite/data/repositories/bluetooth_invite_repository_impl.dart';
import 'package:frecu/features/bluetooth_invite/domain/entities/bluetooth_invite_protocol.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';
import 'package:mocktail/mocktail.dart';

class _MockPeripheralManager extends Mock implements PeripheralManager {}

class _MockCentralManager extends Mock implements CentralManager {}

/// Un teléfono al otro lado: anfitrión (periférico) o invitado (central).
class _Phone implements Peripheral, Central {
  _Phone(int n) : uuid = UUID([...List.filled(15, 0), n]);

  @override
  final UUID uuid;
}

class _Read implements GATTReadRequest {
  _Read([this.offset = 0]);

  @override
  final int offset;
}

class _Write implements GATTWriteRequest {
  _Write(String text) : value = Uint8List.fromList(utf8.encode(text));

  @override
  int get offset => 0;

  @override
  final Uint8List value;
}

final _service = UUID.fromString(BluetoothInviteProtocol.serviceUuid);
final _infoUuid = UUID.fromString(BluetoothInviteProtocol.infoUuid);
final _inviteUuid = UUID.fromString(BluetoothInviteProtocol.inviteUuid);

const _invite = RoomInvite(
  host: '192.168.49.1',
  port: 47800,
  roomId: 'room-1',
  accessCode: '4827',
  note: RoomNote(semitone: 9),
  name: 'Ruta 40',
  wifi: WifiCredentials(ssid: 'DIRECT-frecu', passphrase: 'clave-larga'),
);

GATTService _gatt() => GATTService(
  uuid: _service,
  isPrimary: true,
  includedServices: const [],
  characteristics: [
    for (final uuid in [_infoUuid, _inviteUuid])
      GATTCharacteristic.mutable(
        uuid: uuid,
        properties: const [GATTCharacteristicProperty.read],
        permissions: const [GATTCharacteristicPermission.read],
        descriptors: const [],
      ),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(_Phone(0));
    registerFallbackValue(_gatt());
    registerFallbackValue(_gatt().characteristics.first);
    registerFallbackValue(Advertisement());
    registerFallbackValue(_Read());
    registerFallbackValue(_Write(''));
    registerFallbackValue(GATTError.readNotPermitted);
    registerFallbackValue(GATTCharacteristicWriteType.withResponse);
    registerFallbackValue(Uint8List(0));
  });

  group('Anfitrión', () {
    late _MockPeripheralManager manager;
    late StreamController<GATTCharacteristicReadRequestedEventArgs> reads;
    late StreamController<GATTCharacteristicWriteRequestedEventArgs> writes;
    late BluetoothInviteRepositoryImpl repository;

    setUp(() {
      manager = _MockPeripheralManager();
      reads = StreamController.broadcast();
      writes = StreamController.broadcast();
      when(() => manager.state).thenReturn(BluetoothLowEnergyState.poweredOn);
      when(() => manager.stateChanged).thenAnswer((_) => const Stream.empty());
      when(() => manager.characteristicReadRequested)
          .thenAnswer((_) => reads.stream);
      when(() => manager.characteristicWriteRequested)
          .thenAnswer((_) => writes.stream);
      when(() => manager.removeAllServices()).thenAnswer((_) async {});
      when(() => manager.addService(any())).thenAnswer((_) async {});
      when(() => manager.startAdvertising(any())).thenAnswer((_) async {});
      when(() => manager.stopAdvertising()).thenAnswer((_) async {});
      when(
        () => manager.respondReadRequestWithValue(
          any(),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => manager.respondReadRequestWithError(
          any(),
          error: any(named: 'error'),
        ),
      ).thenAnswer((_) async {});
      when(() => manager.respondWriteRequest(any())).thenAnswer((_) async {});
      when(
        () => manager.respondWriteRequestWithError(
          any(),
          error: any(named: 'error'),
        ),
      ).thenAnswer((_) async {});
      repository = BluetoothInviteRepositoryImpl(
        peripheral: () => manager,
        central: _MockCentralManager.new,
        authorize: ({required advertise}) async => true,
        supported: true,
        requestsMtu: false,
      );
    });

    tearDown(() async {
      await reads.close();
      await writes.close();
    });

    Future<GATTService> advertise() async {
      expect((await repository.advertise(_invite)).isSuccess, isTrue);
      final captured = verify(() => manager.addService(captureAny())).captured;
      return captured.single as GATTService;
    }

    GATTCharacteristic characteristic(GATTService service, UUID uuid) =>
        service.characteristics.firstWhere((c) => c.uuid == uuid);

    Future<Uint8List> readValue(
      GATTCharacteristic characteristic,
      Central guest, [
      int offset = 0,
    ]) async {
      reads.add(
        GATTCharacteristicReadRequestedEventArgs(
          guest,
          characteristic,
          _Read(offset),
        ),
      );
      await pumpEventQueue();
      return verify(
            () => manager.respondReadRequestWithValue(
              any(),
              value: captureAny(named: 'value'),
            ),
          ).captured.single
          as Uint8List;
    }

    Future<GATTError> readError(
      GATTCharacteristic characteristic,
      Central guest,
    ) async {
      reads.add(
        GATTCharacteristicReadRequestedEventArgs(
          guest,
          characteristic,
          _Read(),
        ),
      );
      await pumpEventQueue();
      return verify(
            () => manager.respondReadRequestWithError(
              any(),
              error: captureAny(named: 'error'),
            ),
          ).captured.single
          as GATTError;
    }

    test('anuncia el servicio de Frecu y da a cualquiera los datos '
        'públicos', () async {
      final service = await advertise();

      expect(service.uuid, _service);
      final advertisement =
          verify(() => manager.startAdvertising(captureAny())).captured.single
              as Advertisement;
      expect(advertisement.serviceUUIDs, [_service]);
      expect(advertisement.name, isNull);

      final info = await readValue(
        characteristic(service, _infoUuid),
        _Phone(1),
      );
      final room = BluetoothInviteProtocol.decodeInfo(info, bluetoothId: 'x');
      expect(room?.roomId, 'room-1');
      expect(room?.name, 'Ruta 40');
      expect(room?.note, const RoomNote(semitone: 9));
    });

    test(
      'la invitación solo se lee tras escribir el código correcto, y '
      'solo quien lo escribió; las lecturas largas siguen el offset',
      () async {
        final service = await advertise();
        final invite = characteristic(service, _inviteUuid);
        final guest = _Phone(1);

        expect(await readError(invite, guest), GATTError.readNotPermitted);

        writes.add(
          GATTCharacteristicWriteRequestedEventArgs(
            guest,
            invite,
            _Write('0000'),
          ),
        );
        await pumpEventQueue();
        verify(
          () => manager.respondWriteRequestWithError(
            any(),
            error: GATTError.insufficientAuthorization,
          ),
        ).called(1);
        expect(await readError(invite, guest), GATTError.readNotPermitted);

        writes.add(
          GATTCharacteristicWriteRequestedEventArgs(
            guest,
            invite,
            _Write('4827'),
          ),
        );
        await pumpEventQueue();
        verify(() => manager.respondWriteRequest(any())).called(1);

        final uri = utf8.encode(const BuildInviteQr().buildUri(_invite));
        expect(await readValue(invite, guest, 10), uri.sublist(10));
        expect(await readError(invite, _Phone(2)), GATTError.readNotPermitted);
      },
    );

    test('dejar de anunciar quita el anuncio y el servicio, y olvida a '
        'quien tenía el código', () async {
      final service = await advertise();
      final invite = characteristic(service, _inviteUuid);
      final guest = _Phone(1);
      writes.add(
        GATTCharacteristicWriteRequestedEventArgs(
          guest,
          invite,
          _Write('4827'),
        ),
      );
      await pumpEventQueue();

      await repository.stopAdvertising();

      verify(() => manager.stopAdvertising()).called(1);
      verify(() => manager.removeAllServices()).called(2);
      reads.add(
        GATTCharacteristicReadRequestedEventArgs(guest, invite, _Read()),
      );
      await pumpEventQueue();
      verifyNever(
        () => manager.respondReadRequestWithValue(
          any(),
          value: any(named: 'value'),
        ),
      );
    });

    test('sin permiso o sin Bluetooth en la plataforma no anuncia', () async {
      final denied = BluetoothInviteRepositoryImpl(
        peripheral: () => manager,
        authorize: ({required advertise}) async => false,
        supported: true,
      );
      expect(
        (await denied.advertise(_invite)).failureOrNull,
        const Failure.permissionDenied(permission: 'bluetooth'),
      );
      final unsupported = BluetoothInviteRepositoryImpl(
        peripheral: () => manager,
        supported: false,
      );
      expect((await unsupported.advertise(_invite)).isFailure, isTrue);
      verifyNever(() => manager.startAdvertising(any()));
    });
  });

  group('Invitado', () {
    late _MockCentralManager manager;
    late StreamController<DiscoveredEventArgs> discovered;
    late BluetoothInviteRepositoryImpl repository;
    final host = _Phone(7);
    final gatt = _gatt();

    setUp(() {
      manager = _MockCentralManager();
      discovered = StreamController.broadcast();
      when(() => manager.state).thenReturn(BluetoothLowEnergyState.poweredOn);
      when(() => manager.stateChanged).thenAnswer((_) => const Stream.empty());
      when(() => manager.discovered).thenAnswer((_) => discovered.stream);
      when(
        () => manager.startDiscovery(serviceUUIDs: any(named: 'serviceUUIDs')),
      ).thenAnswer((_) async {});
      when(() => manager.stopDiscovery()).thenAnswer((_) async {});
      when(() => manager.connect(any())).thenAnswer((_) async {});
      when(() => manager.disconnect(any())).thenAnswer((_) async {});
      when(() => manager.discoverGATT(any())).thenAnswer((_) async => [gatt]);
      when(() => manager.readCharacteristic(any(), any())).thenAnswer((call) {
        final characteristic =
            call.positionalArguments[1] as GATTCharacteristic;
        final bytes = characteristic.uuid == _infoUuid
            ? BluetoothInviteProtocol.encodeInfo(
                roomId: 'room-1',
                name: 'Ruta 40',
                note: const RoomNote(semitone: 9),
              )
            : utf8.encode(const BuildInviteQr().buildUri(_invite));
        return Future.value(Uint8List.fromList(bytes));
      });
      when(
        () => manager.writeCharacteristic(
          any(),
          any(),
          value: any(named: 'value'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async {});
      repository = BluetoothInviteRepositoryImpl(
        central: () => manager,
        authorize: ({required advertise}) async => true,
        supported: true,
        requestsMtu: false,
      );
    });

    tearDown(() => discovered.close());

    /// Busca, encuentra al anfitrión y devuelve la frecu listada.
    Future<NearbyRoom> find(List<List<NearbyRoom>> seen) async {
      await pumpEventQueue();
      discovered.add(DiscoveredEventArgs(host, -50, Advertisement()));
      await pumpEventQueue();
      return seen.last.single;
    }

    test('busca solo el servicio de Frecu, lee la frecu de cada anfitrión una '
        'vez y al dejar de escuchar para', () async {
      final seen = <List<NearbyRoom>>[];
      final subscription = repository.watchNearbyRooms().listen(seen.add);

      final room = await find(seen);
      discovered.add(DiscoveredEventArgs(host, -48, Advertisement()));
      await pumpEventQueue();

      verify(() => manager.startDiscovery(serviceUUIDs: [_service])).called(1);
      expect(room.roomId, 'room-1');
      expect(room.name, 'Ruta 40');
      expect(room.bluetoothId, host.uuid.toString());
      verify(() => manager.connect(host)).called(1);
      verify(() => manager.disconnect(host)).called(1);

      await subscription.cancel();
      verify(() => manager.stopDiscovery()).called(1);
    });

    test('con el código correcto recibe la invitación completa, con la '
        'red', () async {
      final seen = <List<NearbyRoom>>[];
      final subscription = repository.watchNearbyRooms().listen(seen.add);
      final room = await find(seen);

      final result = await repository.requestInvite(room, '4827');

      expect(result.dataOrNull, _invite);
      final written = verify(
        () => manager.writeCharacteristic(
          host,
          any(),
          value: captureAny(named: 'value'),
          type: GATTCharacteristicWriteType.withResponse,
        ),
      ).captured.single;
      expect(utf8.decode(written as Uint8List), '4827');
      await subscription.cancel();
    });

    test('si el anfitrión rechaza el código, código incorrecto; si no se '
        'puede conectar, no responde', () async {
      final seen = <List<NearbyRoom>>[];
      final subscription = repository.watchNearbyRooms().listen(seen.add);
      final room = await find(seen);

      when(
        () => manager.writeCharacteristic(
          any(),
          any(),
          value: any(named: 'value'),
          type: any(named: 'type'),
        ),
      ).thenThrow(Exception('GATT 0x08'));
      expect(
        (await repository.requestInvite(room, '0000')).failureOrNull,
        const Failure.invalidAccessCode(),
      );

      when(() => manager.connect(any())).thenThrow(Exception('133'));
      expect(
        (await repository.requestInvite(room, '4827')).failureOrNull,
        const Failure.hostUnreachable(),
      );
      await subscription.cancel();
    });

    test('una frecu que no se vio por Bluetooth no responde', () async {
      const unknown = NearbyRoom(
        roomId: 'x',
        name: 'x',
        hostAddress: '',
        port: 0,
        bluetoothId: 'nadie',
      );
      expect(
        (await repository.requestInvite(unknown, '4827')).failureOrNull,
        const Failure.hostUnreachable(),
      );
    });

    test('sin permiso o sin la plataforma no busca: ninguna frecu', () async {
      final denied = BluetoothInviteRepositoryImpl(
        central: () => manager,
        authorize: ({required advertise}) async => false,
        supported: true,
      );
      expect(await denied.watchNearbyRooms().first, isEmpty);
      final unsupported = BluetoothInviteRepositoryImpl(supported: false);
      expect(await unsupported.watchNearbyRooms().first, isEmpty);
      verifyNever(
        () => manager.startDiscovery(serviceUUIDs: any(named: 'serviceUUIDs')),
      );
    });
  });
}
