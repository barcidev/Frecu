import 'package:frecu/core/constants/cloud_config.dart';
import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Caso de uso para parsear y validar la URI de invitación escaneada desde un QR.
final class ParseInviteFromQr implements UseCase<RoomInvite, String> {
  /// Constructor constante.
  const ParseInviteFromQr();

  @override
  String get name => 'ParseInviteFromQr';

  @override
  Future<Result<RoomInvite>> call(String params) async {
    return parse(params);
  }

  /// Parsea sincrónicamente la cadena escaneada.
  Result<RoomInvite> parse(String rawValue) {
    final uri = Uri.tryParse(rawValue.trim());
    if (uri == null || !_isValidSchemeAndHost(uri)) {
      return const Result.failure(
        Failure.unexpected(message: 'URI o esquema de invitación inválido'),
      );
    }
    return _extractInvite(uri);
  }

  bool _isValidSchemeAndHost(Uri uri) {
    if (uri.scheme.toLowerCase() != 'frecu') return false;
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return host == 'join' || path == 'join' || path == '/join';
  }

  int? _parsePort(String? portStr) {
    final port = int.tryParse(portStr?.trim() ?? '');
    if (port == null || port <= 0 || port > 65535) {
      return null;
    }
    return port;
  }

  /// Lee la nota `n`; ausente o inválida es sin nota.
  String? _parseInternetId(String? value) {
    final id = value?.trim().toLowerCase() ?? '';
    return CloudConfig.isRoomId(id) ? id : null;
  }

  RoomNote? _parseNote(String? noteStr) {
    return RoomNote.tryFromSemitone(int.tryParse(noteStr?.trim() ?? ''));
  }

  /// Lee el nombre `name`; ausente o vacío es sin nombre.
  String? _parseName(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Lee la red de la frecu: `ws` con su nombre y `wk` con su clave. Sin
  /// `ws` no hay red; sin `wk`, la red es abierta. El nombre y la clave van
  /// tal cual: los espacios cuentan.
  WifiCredentials? _parseWifi(String? ssid, String? key) {
    if (ssid == null || ssid.isEmpty) return null;
    return WifiCredentials(
      ssid: ssid,
      passphrase: key == null || key.isEmpty ? null : key,
    );
  }

  Result<RoomInvite> _extractInvite(Uri uri) {
    final internetId = _parseInternetId(uri.queryParameters['x']);
    final rawHost = uri.queryParameters['h']?.trim() ?? '';
    final rawPort = _parsePort(uri.queryParameters['p']);
    // Por internet basta el id: sin una dirección local válida, se entra
    // solo por la nube.
    final local = rawHost.isNotEmpty && rawPort != null;
    final host = local ? rawHost : '';
    final port = local ? rawPort : 0;
    final roomId =
        uri.queryParameters['r']?.trim().nonEmpty ?? internetId ?? '';
    final accessCode = uri.queryParameters['c']?.trim() ?? '';

    if (!local && internetId == null) {
      return const Result.failure(
        Failure.unexpected(message: 'Host o puerto inválido en la invitación'),
      );
    }

    if (roomId.isEmpty || accessCode.isEmpty) {
      return const Result.failure(
        Failure.unexpected(message: 'Sala o código de acceso faltante'),
      );
    }

    return Result.success(
      RoomInvite(
        host: host,
        port: port,
        roomId: roomId,
        accessCode: accessCode,
        note: _parseNote(uri.queryParameters['n']),
        name: _parseName(uri.queryParameters['name']),
        wifi: _parseWifi(uri.queryParameters['ws'], uri.queryParameters['wk']),
        internetId: internetId,
      ),
    );
  }
}

extension on String {
  String? get nonEmpty => isEmpty ? null : this;
}
