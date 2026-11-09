import 'dart:convert';

import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Protocolo de la invitación por Bluetooth (BLE).
///
/// El anfitrión anuncia el servicio [serviceUuid] y sirve dos
/// características:
/// - [infoUuid] (lectura): la frecu en JSON, sin nada secreto
///   (`{"v":1,"r":roomId,"name":…,"n":semitono}`), para listarla en
///   «Cercanas».
/// - [inviteUuid] (escritura y lectura): el invitado escribe el código de
///   acceso; si es el de la frecu, el anfitrión acepta la escritura y desde
///   entonces le deja leer la invitación completa, la misma URI del QR
///   (`frecu://join?…`, con la red y su clave). Con un código equivocado
///   rechaza la escritura, y la lectura sin código también.
abstract final class BluetoothInviteProtocol {
  /// Versión del protocolo.
  static const int version = 1;

  /// Servicio de Frecu.
  static const String serviceUuid = '51b1b2c2-069a-488c-94c8-c469ede80001';

  /// Característica con los datos públicos de la frecu.
  static const String infoUuid = '51b1b2c2-069a-488c-94c8-c469ede80002';

  /// Característica del código y la invitación.
  static const String inviteUuid = '51b1b2c2-069a-488c-94c8-c469ede80003';

  /// Datos públicos de la frecu.
  static List<int> encodeInfo({
    required String roomId,
    required String name,
    RoomNote? note,
  }) => utf8.encode(
    jsonEncode({
      'v': version,
      'r': roomId,
      'name': name,
      if (note != null) 'n': note.semitone,
    }),
  );

  /// La frecu de [bytes] encontrada en el anfitrión [bluetoothId], o nula si
  /// no se entiende o es de otra versión.
  static NearbyRoom? decodeInfo(
    List<int> bytes, {
    required String bluetoothId,
  }) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic>) return null;
      final roomId = json['r'];
      final name = json['name'];
      if (json['v'] != version || roomId is! String || roomId.isEmpty) {
        return null;
      }
      final semitone = json['n'];
      return NearbyRoom(
        roomId: roomId,
        name: name is String ? name : '',
        hostAddress: '',
        port: 0,
        note: RoomNote.tryFromSemitone(semitone is int ? semitone : null),
        bluetoothId: bluetoothId,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Limita los códigos equivocados que acepta el anfitrión por Bluetooth: tras
/// [maxFailures] en [window], rechaza todos durante [lockout]. Con un código
/// de 4 dígitos, probarlos todos tomaría horas.
class BluetoothUnlockGate {
  /// Crea el límite; [now] reemplaza al reloj en pruebas.
  BluetoothUnlockGate({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Códigos equivocados permitidos en [window].
  static const int maxFailures = 5;

  /// Ventana en la que se cuentan.
  static const Duration window = Duration(seconds: 30);

  /// Cuánto se rechaza todo al pasarse.
  static const Duration lockout = Duration(seconds: 30);

  final DateTime Function() _now;
  final List<DateTime> _failures = [];
  DateTime? _lockedUntil;

  /// Si [code] abre la frecu de código [accessCode]; cuenta el fallo si no.
  bool check(String code, {required String accessCode}) {
    final now = _now();
    final until = _lockedUntil;
    if (until != null && now.isBefore(until)) return false;
    _lockedUntil = null;
    if (code == accessCode) return true;
    _failures
      ..removeWhere((at) => now.difference(at) >= window)
      ..add(now);
    if (_failures.length >= maxFailures) {
      _failures.clear();
      _lockedUntil = now.add(lockout);
    }
    return false;
  }

  /// Olvida los fallos (frecu nueva).
  void reset() {
    _failures.clear();
    _lockedUntil = null;
  }
}
