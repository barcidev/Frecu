import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';

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

  Result<RoomInvite> _extractInvite(Uri uri) {
    final host = uri.queryParameters['h']?.trim() ?? '';
    final port = _parsePort(uri.queryParameters['p']);
    final roomId = uri.queryParameters['r']?.trim() ?? '';
    final accessCode = uri.queryParameters['c']?.trim() ?? '';

    if (host.isEmpty || port == null) {
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
      ),
    );
  }
}
