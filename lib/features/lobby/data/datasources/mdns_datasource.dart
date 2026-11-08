import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:nsd/nsd.dart' as nsd;

/// Representa el datasource para anuncio y descubrimiento de servicios mDNS.
class MdnsDataSource {
  /// Constructor con inyección opcional de funciones nsd para pruebas.
  MdnsDataSource({
    Future<nsd.Registration> Function(nsd.Service service)? registerFn,
    Future<void> Function(nsd.Registration registration)? unregisterFn,
    Future<nsd.Discovery> Function(
      String serviceType, {
      bool autoResolve,
      nsd.IpLookupType ipLookupType,
    })?
    startDiscoveryFn,
    Future<void> Function(nsd.Discovery discovery)? stopDiscoveryFn,
  }) : _registerFn = registerFn ?? nsd.register,
       _unregisterFn = unregisterFn ?? nsd.unregister,
       _startDiscoveryFn = startDiscoveryFn ?? nsd.startDiscovery,
       _stopDiscoveryFn = stopDiscoveryFn ?? nsd.stopDiscovery;

  final Future<nsd.Registration> Function(nsd.Service service) _registerFn;
  final Future<void> Function(nsd.Registration registration) _unregisterFn;
  final Future<nsd.Discovery> Function(
    String serviceType, {
    bool autoResolve,
    nsd.IpLookupType ipLookupType,
  })
  _startDiscoveryFn;
  final Future<void> Function(nsd.Discovery discovery) _stopDiscoveryFn;

  nsd.Registration? _registration;
  nsd.Discovery? _discovery;
  final StreamController<List<NearbyRoom>> _nearbyRoomsController =
      StreamController<List<NearbyRoom>>.broadcast();
  final Map<String, NearbyRoom> _discoveredRooms = {};

  /// Stream reactivo de las salas descubiertas.
  Stream<List<NearbyRoom>> get nearbyRooms => _nearbyRoomsController.stream;

  /// Publica la sala actual en mDNS con sus atributos TXT.
  ///
  /// Si la frecu tiene [note], la suma como `n` (semitono desde Do4, 0–23).
  Future<void> publish({
    required String roomId,
    required String name,
    required int port,
    RoomNote? note,
  }) async {
    await stopPublishing();

    final txt = <String, Uint8List?>{
      'roomId': Uint8List.fromList(utf8.encode(roomId)),
      'name': Uint8List.fromList(utf8.encode(name)),
      'v': Uint8List.fromList(utf8.encode('1')),
      if (note != null)
        'n': Uint8List.fromList(utf8.encode(note.semitone.toString())),
    };

    final service = nsd.Service(
      name: name,
      type: NetworkConstants.mdnsServiceType,
      port: port,
      txt: txt,
    );

    try {
      _registration = await _registerFn(service);
      AppLogger.i('Published mDNS service: $name ($roomId) on port $port');
    } on Object catch (e, st) {
      AppLogger.w('Failed to publish mDNS service: $e\n$st');
      rethrow;
    }
  }

  /// Detiene la publicación del servicio mDNS.
  Future<void> stopPublishing() async {
    if (_registration != null) {
      try {
        await _unregisterFn(_registration!);
        AppLogger.i('Unregistered mDNS service');
      } on Object catch (e) {
        AppLogger.w('Failed to unregister mDNS service: $e');
      } finally {
        _registration = null;
      }
    }
  }

  /// Inicia el descubrimiento de salas cercanas en la red.
  Future<void> startDiscovery() async {
    if (_discovery != null) return;

    try {
      _discovery = await _startDiscoveryFn(
        NetworkConstants.mdnsServiceType,
        ipLookupType: nsd.IpLookupType.v4,
      );

      _discovery!.addServiceListener(_handleServiceEvent);
      AppLogger.i(
        'Started mDNS discovery for ${NetworkConstants.mdnsServiceType}',
      );
    } on Object catch (e, st) {
      AppLogger.w('Failed to start mDNS discovery: $e\n$st');
      rethrow;
    }
  }

  String? _extractHost(nsd.Service service) {
    if (service.host != null) return service.host;
    final addresses = service.addresses;
    if (addresses != null && addresses.isNotEmpty) {
      return addresses.first.address;
    }
    return null;
  }

  String? _extractTxt(Map<String, Uint8List?> txt, String key) {
    final bytes = txt[key];
    return bytes != null ? utf8.decode(bytes) : null;
  }

  /// Lee la nota `n`; ausente o inválida es sin nota.
  RoomNote? _extractNote(Map<String, Uint8List?> txt) {
    final bytes = txt['n'];
    if (bytes == null) return null;
    final value = utf8.decode(bytes, allowMalformed: true).trim();
    return RoomNote.tryFromSemitone(int.tryParse(value));
  }

  NearbyRoom? _buildNearbyRoom(nsd.Service service) {
    final host = _extractHost(service);
    final port = service.port;
    if (host == null || port == null) return null;

    final txt = service.txt ?? {};
    final roomId = _extractTxt(txt, 'roomId');
    final name = _extractTxt(txt, 'name') ?? service.name ?? 'Frecu';
    final versionStr = _extractTxt(txt, 'v');
    final version = versionStr != null ? int.tryParse(versionStr) ?? 1 : 1;

    final id = roomId ?? service.name ?? host;
    return NearbyRoom(
      roomId: id,
      name: name,
      hostAddress: host,
      port: port,
      protocolVersion: version,
      note: _extractNote(txt),
    );
  }

  void _handleServiceEvent(nsd.Service service, nsd.ServiceStatus status) {
    final room = _buildNearbyRoom(service);
    if (room == null) return;

    if (status == nsd.ServiceStatus.found) {
      _discoveredRooms[room.roomId] = room;
    } else if (status == nsd.ServiceStatus.lost) {
      _discoveredRooms.remove(room.roomId);
    }
    _nearbyRoomsController.add(_discoveredRooms.values.toList());
  }

  /// Detiene el descubrimiento mDNS.
  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      try {
        await _stopDiscoveryFn(_discovery!);
      } on Object catch (e) {
        AppLogger.w('Failed to stop mDNS discovery: $e');
      } finally {
        _discovery = null;
      }
    }
    _discoveredRooms.clear();
    _nearbyRoomsController.add([]);
  }

  /// Libera recursos.
  Future<void> dispose() async {
    await stopPublishing();
    await stopDiscovery();
    await _nearbyRoomsController.close();
  }
}
