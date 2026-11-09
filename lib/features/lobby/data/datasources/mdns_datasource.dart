import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:frecu/core/constants/network_constants.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:nsd/nsd.dart' as nsd;

/// Representa el datasource para anuncio y descubrimiento de servicios mDNS.
///
/// Anunciar y retirar el anuncio van en fila, igual que empezar y detener la
/// búsqueda: un retiro pedido mientras se anuncia espera al anuncio y lo
/// retira, y una búsqueda reanudada no se cruza con la que se detiene.
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

  /// Frecus descubiertas, por su id.
  final Map<String, NearbyRoom> _discoveredRooms = {};

  /// Id de la frecu de cada servicio mDNS, por su nombre: el `lost` solo
  /// trae el nombre del servicio.
  final Map<String, String> _serviceRoomIds = {};

  final _Lane _publishing = _Lane();
  final _Lane _discovering = _Lane();

  /// Stream reactivo de las salas descubiertas.
  Stream<List<NearbyRoom>> get nearbyRooms => _nearbyRoomsController.stream;

  /// Frecus descubiertas ahora mismo.
  List<NearbyRoom> get rooms => List.unmodifiable(_discoveredRooms.values);

  /// Publica la sala actual en mDNS con sus atributos TXT.
  ///
  /// Si la frecu tiene [note], la suma como `n` (semitono desde Do4, 0–23).
  Future<void> publish({
    required String roomId,
    required String name,
    required int port,
    RoomNote? note,
  }) => _publishing.run(() async {
    await _unregister();

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
  });

  /// Detiene la publicación del servicio mDNS.
  Future<void> stopPublishing() => _publishing.run(_unregister);

  Future<void> _unregister() async {
    final registration = _registration;
    if (registration == null) return;
    try {
      await _unregisterFn(registration);
      AppLogger.i('Unregistered mDNS service');
    } on Object catch (e) {
      AppLogger.w('Failed to unregister mDNS service: $e');
    } finally {
      _registration = null;
    }
  }

  /// Inicia el descubrimiento de salas cercanas en la red.
  Future<void> startDiscovery() => _discovering.run(() async {
    if (_discovery != null) return;

    try {
      final discovery = await _startDiscoveryFn(
        NetworkConstants.mdnsServiceType,
        ipLookupType: nsd.IpLookupType.v4,
      );
      discovery.addServiceListener(_handleServiceEvent);
      _discovery = discovery;
      AppLogger.i(
        'Started mDNS discovery for ${NetworkConstants.mdnsServiceType}',
      );
    } on Object catch (e, st) {
      AppLogger.w('Failed to start mDNS discovery: $e\n$st');
      rethrow;
    }
  });

  /// IPv4 del anfitrión; su nombre (`.local`) solo si no trae ninguna.
  String? _extractHost(nsd.Service service) {
    final ipv4 = [
      for (final address in service.addresses ?? const <InternetAddress>[])
        if (address.type == InternetAddressType.IPv4 && !address.isLoopback)
          address.address,
    ];
    final ip =
        ipv4.where((address) => !address.startsWith('169.254.')).firstOrNull ??
        ipv4.firstOrNull;
    if (ip != null) return ip;
    final host = service.host?.trim();
    if (host == null || host.isEmpty) return null;
    return host.endsWith('.') ? host.substring(0, host.length - 1) : host;
  }

  String? _extractTxt(Map<String, Uint8List?> txt, String key) {
    final bytes = txt[key];
    return bytes != null ? utf8.decode(bytes, allowMalformed: true) : null;
  }

  /// Lee la nota `n`; ausente o inválida es sin nota.
  RoomNote? _extractNote(Map<String, Uint8List?> txt) {
    final bytes = txt['n'];
    if (bytes == null) return null;
    final value = utf8.decode(bytes, allowMalformed: true).trim();
    return RoomNote.tryFromSemitone(int.tryParse(value));
  }

  /// Id de la frecu en el TXT, o nulo si no lo trae.
  String? _txtRoomId(nsd.Service service) {
    final roomId = _extractTxt(service.txt ?? const {}, 'roomId')?.trim();
    return roomId == null || roomId.isEmpty ? null : roomId;
  }

  NearbyRoom? _buildNearbyRoom(nsd.Service service) {
    final host = _extractHost(service);
    final port = service.port;
    if (host == null || port == null) return null;

    final txt = service.txt ?? {};
    // Sin nombre en el TXT ni en el servicio, vacío: el inicio lo nombra en
    // el idioma de la app.
    final name = _extractTxt(txt, 'name') ?? service.name ?? '';
    final versionStr = _extractTxt(txt, 'v');
    final version = versionStr != null ? int.tryParse(versionStr) ?? 1 : 1;

    final id = _txtRoomId(service) ?? service.name ?? host;
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
    final changed = switch (status) {
      nsd.ServiceStatus.found => _onFound(service),
      nsd.ServiceStatus.lost => _onLost(service),
    };
    if (changed) _emit();
  }

  /// Suma o actualiza la frecu de [service]. Si el servicio ya anunciaba
  /// otra frecu con el mismo nombre (se cerró y se abrió otra), la nueva la
  /// sustituye con su TXT.
  bool _onFound(nsd.Service service) {
    final room = _buildNearbyRoom(service);
    if (room == null) return false;
    final name = service.name;
    if (name != null) {
      final previous = _serviceRoomIds[name];
      _serviceRoomIds[name] = room.roomId;
      if (previous != null && previous != room.roomId) _forget(previous);
    }
    _discoveredRooms[room.roomId] = room;
    return true;
  }

  /// Quita la frecu de [service] por el nombre del servicio, aunque el
  /// evento no traiga anfitrión ni puerto.
  bool _onLost(nsd.Service service) {
    final name = service.name;
    final roomId =
        (name != null ? _serviceRoomIds.remove(name) : null) ??
        _txtRoomId(service);
    if (roomId == null) return false;
    return _forget(roomId);
  }

  /// Olvida la frecu [roomId] si ningún otro servicio la anuncia.
  bool _forget(String roomId) {
    if (_serviceRoomIds.containsValue(roomId)) return false;
    return _discoveredRooms.remove(roomId) != null;
  }

  void _emit() {
    if (_nearbyRoomsController.isClosed) return;
    _nearbyRoomsController.add(rooms);
  }

  /// Detiene el descubrimiento mDNS y vacía la lista: al reanudarlo, las
  /// frecus se descubren de nuevo con su TXT al día.
  Future<void> stopDiscovery() => _discovering.run(() async {
    final discovery = _discovery;
    _discovery = null;
    if (discovery != null) {
      discovery.removeServiceListener(_handleServiceEvent);
      try {
        await _stopDiscoveryFn(discovery);
      } on Object catch (e) {
        AppLogger.w('Failed to stop mDNS discovery: $e');
      }
    }
    _discoveredRooms.clear();
    _serviceRoomIds.clear();
    _emit();
  });

  /// Libera recursos.
  Future<void> dispose() async {
    await stopPublishing();
    await stopDiscovery();
    await _nearbyRoomsController.close();
  }
}

/// Fila de operaciones: cada una empieza cuando terminó la anterior, haya
/// salido bien o no.
class _Lane {
  Future<void> _tail = Future<void>.value();

  Future<void> run(Future<void> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
