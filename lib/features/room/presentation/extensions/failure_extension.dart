import 'package:frecu/core/error/failure.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Extensión para mapear instancias de [Failure] a mensajes localizados legibles.
extension FailureLocalization on Failure {
  /// Retorna la cadena localizada correspondiente a la falla actual.
  String toLocalizedMessage() {
    return when(
      network: (msg) => msg ?? t.errors.network,
      permissionDenied: (permission) => permission != null
          ? '${t.errors.permissionDenied}: $permission'
          : t.errors.permissionDenied,
      roomFull: () => t.errors.roomFull,
      invalidAccessCode: () => t.errors.invalidAccessCode,
      hostUnreachable: () => t.errors.hostUnreachable,
      versionMismatch: () => t.errors.versionMismatch,
      audio: (msg) => msg ?? t.errors.audio,
      unexpected: (msg, _) => msg ?? t.errors.unexpected,
    );
  }
}
