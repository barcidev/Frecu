import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/bluetooth_invite/domain/entities/bluetooth_invite_protocol.dart';
import 'package:frecu/features/bluetooth_invite/domain/repositories/bluetooth_invite_repository.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/domain/usecases/parse_invite_from_qr.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/usecases/build_invite_qr.dart';
import 'package:permission_handler/permission_handler.dart';

/// Invitación por Bluetooth con `bluetooth_low_energy`: el anfitrión es
/// periférico (anuncia y sirve GATT) y el invitado, central.
///
/// Solo en Android e iOS: en otra plataforma (las pruebas) no se busca ni se
/// anuncia. Las pruebas reemplazan los gestores, los permisos y la
/// plataforma.
class BluetoothInviteRepositoryImpl implements BluetoothInviteRepository {
  /// Crea el repositorio. [central] y [peripheral] crean los gestores la
  /// primera vez que hacen falta (en iOS, crearlos pide el permiso);
  /// [authorize] pide los permisos de Android; [requestsMtu] pide paquetes
  /// grandes al conectar (Android; iOS los negocia solo).
  BluetoothInviteRepositoryImpl({
    CentralManager Function()? central,
    PeripheralManager Function()? peripheral,
    Future<bool> Function({required bool advertise})? authorize,
    bool? supported,
    bool? requestsMtu,
    BluetoothUnlockGate? gate,
    this.timeout = const Duration(seconds: 10),
    this.forgetAfter = const Duration(seconds: 15),
  }) : _newCentral = central ?? CentralManager.new,
       _newPeripheral = peripheral ?? PeripheralManager.new,
       _authorize = authorize ?? _androidPermissions,
       _supported = supported ?? (Platform.isAndroid || Platform.isIOS),
       _requestsMtu = requestsMtu ?? Platform.isAndroid,
       _gate = gate ?? BluetoothUnlockGate();

  /// Tiempo máximo para conectar y hablar con un anfitrión.
  final Duration timeout;

  /// Tras cuánto sin verla una frecu sale de la lista.
  final Duration forgetAfter;

  final CentralManager Function() _newCentral;
  final PeripheralManager Function() _newPeripheral;
  final Future<bool> Function({required bool advertise}) _authorize;
  final bool _supported;
  final bool _requestsMtu;
  final BluetoothUnlockGate _gate;

  CentralManager? _centralManager;
  PeripheralManager? _peripheralManager;

  CentralManager get _central => _centralManager ??= _newCentral();
  PeripheralManager get _peripheral => _peripheralManager ??= _newPeripheral();

  static final UUID _service = UUID.fromString(
    BluetoothInviteProtocol.serviceUuid,
  );
  static final UUID _info = UUID.fromString(BluetoothInviteProtocol.infoUuid);
  static final UUID _invite = UUID.fromString(
    BluetoothInviteProtocol.inviteUuid,
  );

  /// Anfitriones vistos, por id, para pedirles la invitación.
  final Map<String, Peripheral> _hosts = {};

  /// Una conexión a la vez: los teléfonos llevan mal varias juntas.
  Future<void> _connections = Future.value();

  // --- Anfitrión ---

  /// Una operación del anfitrión a la vez (anunciar, cambiar, dejar).
  Future<void> _hostQueue = Future.value();
  bool _advertising = false;
  List<StreamSubscription<Object?>> _requests = const [];
  RoomInvite? _served;
  List<int> _infoBytes = const [];
  List<int> _inviteBytes = const [];

  /// Invitados que ya escribieron el código.
  final Set<UUID> _unlocked = {};

  /// En Android 12+, buscar y anunciar piden «Dispositivos cercanos». Al
  /// buscar no se pide si no se dio en la bienvenida (no se interrumpe el
  /// inicio con un aviso); con el permiso del grupo ya dado, pedir el resto
  /// no muestra nada.
  static Future<bool> _androidPermissions({required bool advertise}) async {
    if (!Platform.isAndroid) return true;
    if (!advertise && !await Permission.bluetoothConnect.isGranted) {
      return false;
    }
    final statuses = await [
      Permission.bluetoothConnect,
      if (advertise)
        Permission.bluetoothAdvertise
      else
        Permission.bluetoothScan,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<T> _serialHost<T>(Future<T> Function() action) {
    final result = _hostQueue.then((_) => action());
    _hostQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<Result<void>> advertise(RoomInvite invite) => _serialHost(() async {
    final previous = _served;
    if (previous == null ||
        previous.roomId != invite.roomId ||
        previous.accessCode != invite.accessCode) {
      _unlocked.clear();
      _gate.reset();
    }
    _served = invite;
    _infoBytes = BluetoothInviteProtocol.encodeInfo(
      roomId: invite.roomId,
      name: invite.name ?? '',
      note: invite.note,
    );
    _inviteBytes = utf8.encode(const BuildInviteQr().buildUri(invite));
    if (_advertising) return const Result.success(null);
    if (!_supported) {
      return const Result.failure(
        Failure.unexpected(message: 'Bluetooth unsupported'),
      );
    }
    if (!await _authorize(advertise: true)) {
      return const Result.failure(
        Failure.permissionDenied(permission: 'bluetooth'),
      );
    }
    try {
      final manager = _peripheral;
      if (!await _poweredOn(manager)) {
        return const Result.failure(
          Failure.unexpected(message: 'Bluetooth off'),
        );
      }
      _requests = [
        manager.characteristicReadRequested.listen(_onRead),
        manager.characteristicWriteRequested.listen(_onWrite),
      ];
      await manager.removeAllServices();
      await manager.addService(
        GATTService(
          uuid: _service,
          isPrimary: true,
          includedServices: const [],
          characteristics: [
            GATTCharacteristic.mutable(
              uuid: _info,
              properties: const [GATTCharacteristicProperty.read],
              permissions: const [GATTCharacteristicPermission.read],
              descriptors: const [],
            ),
            GATTCharacteristic.mutable(
              uuid: _invite,
              properties: const [
                GATTCharacteristicProperty.read,
                GATTCharacteristicProperty.write,
              ],
              permissions: const [
                GATTCharacteristicPermission.read,
                GATTCharacteristicPermission.write,
              ],
              descriptors: const [],
            ),
          ],
        ),
      );
      await manager.startAdvertising(Advertisement(serviceUUIDs: [_service]));
      _advertising = true;
      return const Result.success(null);
    } on Object catch (error, stackTrace) {
      AppLogger.w('Could not advertise over Bluetooth', error, stackTrace);
      await _teardown();
      return Result.failure(Failure.unexpected(error: error));
    }
  });

  @override
  Future<void> stopAdvertising() => _serialHost(() async {
    _served = null;
    _unlocked.clear();
    if (!_advertising && _requests.isEmpty) return;
    await _teardown();
  });

  Future<void> _teardown() async {
    final requests = _requests;
    _requests = const [];
    for (final subscription in requests) {
      await subscription.cancel();
    }
    final manager = _peripheralManager;
    _advertising = false;
    if (manager == null) return;
    try {
      await manager.stopAdvertising();
      await manager.removeAllServices();
    } on Object catch (error) {
      AppLogger.d('Bluetooth teardown: $error');
    }
  }

  Future<void> _onRead(GATTCharacteristicReadRequestedEventArgs event) async {
    final manager = _peripheral;
    final uuid = event.characteristic.uuid;
    final value = uuid == _info
        ? _infoBytes
        : uuid == _invite && _unlocked.contains(event.central.uuid)
        ? _inviteBytes
        : null;
    final offset = event.request.offset;
    try {
      if (value == null || _served == null) {
        await manager.respondReadRequestWithError(
          event.request,
          error: GATTError.readNotPermitted,
        );
      } else if (offset > value.length) {
        await manager.respondReadRequestWithError(
          event.request,
          error: GATTError.invalidOffset,
        );
      } else {
        // Lecturas largas: cada una pide desde su [offset].
        await manager.respondReadRequestWithValue(
          event.request,
          value: Uint8List.fromList(value.sublist(offset)),
        );
      }
    } on Object catch (error) {
      AppLogger.d('Bluetooth read: $error');
    }
  }

  Future<void> _onWrite(GATTCharacteristicWriteRequestedEventArgs event) async {
    final manager = _peripheral;
    final served = _served;
    final code = utf8.decode(event.request.value, allowMalformed: true).trim();
    final accepted =
        served != null &&
        event.characteristic.uuid == _invite &&
        _gate.check(code, accessCode: served.accessCode);
    try {
      if (accepted) {
        _unlocked.add(event.central.uuid);
        await manager.respondWriteRequest(event.request);
      } else {
        await manager.respondWriteRequestWithError(
          event.request,
          error: GATTError.insufficientAuthorization,
        );
      }
    } on Object catch (error) {
      AppLogger.d('Bluetooth write: $error');
    }
  }

  // --- Invitado ---

  @override
  Stream<List<NearbyRoom>> watchNearbyRooms() {
    if (!_supported) return Stream.value(const []);
    return Stream<List<NearbyRoom>>.multi((controller) {
      final seen = <String, ({NearbyRoom room, DateTime at})>{};
      final reading = <String>{};
      final failedAt = <String, DateTime>{};
      final subscriptions = <StreamSubscription<Object?>>[];
      Timer? sweep;
      var closed = false;
      var scanning = false;

      void emit() {
        if (!closed) controller.add([for (final s in seen.values) s.room]);
      }

      Future<void> readInfo(Peripheral host, String id) async {
        try {
          final room = await _withHost(host, (services) async {
            final info = _characteristic(services, _info);
            if (info == null) return null;
            final bytes = await _central.readCharacteristic(host, info);
            return BluetoothInviteProtocol.decodeInfo(bytes, bluetoothId: id);
          });
          if (room == null) {
            failedAt[id] = DateTime.now();
          } else {
            seen[id] = (room: room, at: DateTime.now());
            emit();
          }
        } on Object catch (error) {
          AppLogger.d('Bluetooth room info: $error');
          failedAt[id] = DateTime.now();
        } finally {
          reading.remove(id);
        }
      }

      void onDiscovered(DiscoveredEventArgs event) {
        final host = event.peripheral;
        final id = host.uuid.toString();
        _hosts[id] = host;
        final known = seen[id];
        if (known != null) {
          seen[id] = (room: known.room, at: DateTime.now());
          return;
        }
        final failed = failedAt[id];
        if (reading.contains(id) ||
            (failed != null &&
                DateTime.now().difference(failed) < forgetAfter)) {
          return;
        }
        reading.add(id);
        unawaited(_serialConnection(() => readInfo(host, id)));
      }

      Future<void> startScan() async {
        if (scanning || closed) return;
        scanning = true;
        try {
          await _central.startDiscovery(serviceUUIDs: [_service]);
        } on Object catch (error) {
          scanning = false;
          AppLogger.d('Bluetooth scan: $error');
        }
      }

      Future<void> start() async {
        if (!await _authorize(advertise: false) || closed) {
          emit();
          return;
        }
        final central = _central;
        subscriptions
          ..add(central.discovered.listen(onDiscovered))
          ..add(
            central.stateChanged.listen((event) {
              if (event.state == BluetoothLowEnergyState.poweredOn) {
                unawaited(startScan());
              } else {
                scanning = false;
                seen.clear();
                emit();
              }
            }),
          );
        sweep = Timer.periodic(const Duration(seconds: 5), (_) {
          final now = DateTime.now();
          final before = seen.length;
          seen.removeWhere((_, s) => now.difference(s.at) > forgetAfter);
          if (seen.length != before) emit();
        });
        emit();
        if (central.state == BluetoothLowEnergyState.poweredOn) {
          await startScan();
        }
      }

      unawaited(start());
      controller.onCancel = () async {
        closed = true;
        sweep?.cancel();
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
        if (scanning) {
          try {
            await _central.stopDiscovery();
          } on Object catch (error) {
            AppLogger.d('Bluetooth stop scan: $error');
          }
        }
      };
    });
  }

  @override
  Future<Result<RoomInvite>> requestInvite(
    NearbyRoom room,
    String accessCode,
  ) async {
    final host = _hosts[room.bluetoothId];
    if (host == null) return const Result.failure(Failure.hostUnreachable());
    try {
      return await _serialConnection(
        () => _withHost<Result<RoomInvite>>(host, (services) async {
          final invite = _characteristic(services, _invite);
          if (invite == null) {
            return const Result.failure(Failure.hostUnreachable());
          }
          try {
            await _central.writeCharacteristic(
              host,
              invite,
              value: Uint8List.fromList(utf8.encode(accessCode)),
              type: GATTCharacteristicWriteType.withResponse,
            );
          } on Object catch (error) {
            AppLogger.d('Bluetooth code rejected: $error');
            return const Result.failure(Failure.invalidAccessCode());
          }
          final bytes = await _central.readCharacteristic(host, invite);
          final parsed = const ParseInviteFromQr().parse(utf8.decode(bytes));
          return parsed.isSuccess
              ? parsed
              : const Result.failure(Failure.hostUnreachable());
        }),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.w('Could not ask for the invite', error, stackTrace);
      return const Result.failure(Failure.hostUnreachable());
    }
  }

  Future<T> _serialConnection<T>(Future<T> Function() action) {
    final result = _connections.then((_) => action());
    _connections = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Conecta a [host], descubre su GATT, corre [body] y desconecta.
  Future<T> _withHost<T>(
    Peripheral host,
    Future<T> Function(List<GATTService> services) body,
  ) async {
    final central = _central;
    try {
      await central.connect(host).timeout(timeout);
      if (_requestsMtu) {
        try {
          await central.requestMTU(host, mtu: 512);
        } on Object catch (error) {
          AppLogger.d('Bluetooth MTU: $error');
        }
      }
      final services = await central.discoverGATT(host).timeout(timeout);
      return await body(services).timeout(timeout);
    } finally {
      try {
        await central.disconnect(host);
      } on Object catch (error) {
        AppLogger.d('Bluetooth disconnect: $error');
      }
    }
  }

  static GATTCharacteristic? _characteristic(
    List<GATTService> services,
    UUID uuid,
  ) {
    for (final service in services) {
      if (service.uuid != _service) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == uuid) return characteristic;
      }
    }
    return null;
  }

  /// Espera a que el Bluetooth esté encendido (en iOS el estado llega
  /// después de crear el gestor, o tras el aviso del permiso).
  Future<bool> _poweredOn(BluetoothLowEnergyManager manager) async {
    if (manager.state == BluetoothLowEnergyState.poweredOn) return true;
    try {
      await manager.stateChanged
          .firstWhere((e) => e.state == BluetoothLowEnergyState.poweredOn)
          .timeout(timeout);
      return true;
    } on Object {
      return false;
    }
  }
}
