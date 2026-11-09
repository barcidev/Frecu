import 'package:frecu/core/result/result.dart';
import 'package:frecu/core/usecase/usecase.dart';
import 'package:frecu/features/room/domain/entities/room_invite.dart';

/// Caso de uso para construir el URI del código QR de invitación a una frecu.
final class BuildInviteQr implements UseCase<String, RoomInvite> {
  /// Constructor constante.
  const BuildInviteQr();

  @override
  String get name => 'BuildInviteQr';

  @override
  Future<Result<String>> call(RoomInvite params) async {
    return Result.success(buildUri(params));
  }

  /// Construye de forma sincrónica la URI estándar frecu://join.
  ///
  /// Si la invitación tiene nota, suma al final `n` con su semitono (0–23),
  /// si tiene nombre, `name` tras ella, y si trae la red de la frecu, `ws`
  /// con su nombre y `wk` con su clave (sin clave, la red es abierta).
  String buildUri(RoomInvite invite) {
    final name = invite.name?.trim() ?? '';
    final ssid = invite.wifi?.ssid ?? '';
    final key = invite.wifi?.passphrase ?? '';
    final uri = Uri(
      scheme: 'frecu',
      host: 'join',
      queryParameters: {
        'h': invite.host,
        'p': invite.port.toString(),
        'r': invite.roomId,
        'c': invite.accessCode,
        if (invite.note case final note?) 'n': note.semitone.toString(),
        if (name.isNotEmpty) 'name': name,
        if (ssid.isNotEmpty) 'ws': ssid,
        if (ssid.isNotEmpty && key.isNotEmpty) 'wk': key,
      },
    );
    return uri.toString();
  }
}
