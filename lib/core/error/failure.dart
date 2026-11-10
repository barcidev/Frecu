import 'package:frecu/core/error/network_failure_reasons.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

export 'package:frecu/core/error/network_failure_reasons.dart';

part 'failure.freezed.dart';

/// Representa cualquier falla o error controlado en la aplicación.
@freezed
sealed class Failure with _$Failure {
  /// Error relacionado con conectividad o red local.
  const factory Failure.network({String? message}) = _NetworkFailure;

  /// Permiso del sistema rechazado (audio, red local, etc.).
  const factory Failure.permissionDenied({String? permission}) =
      _PermissionDeniedFailure;

  /// La sala alcanzó el límite máximo de participantes (6).
  const factory Failure.roomFull() = _RoomFullFailure;

  /// El código de acceso de 4 dígitos es inválido.
  const factory Failure.invalidAccessCode() = _InvalidAccessCodeFailure;

  /// No se puede contactar al anfitrión de la frecu.
  const factory Failure.hostUnreachable() = _HostUnreachableFailure;

  /// El anfitrión usa una versión del protocolo que esta app no entiende.
  const factory Failure.versionMismatch() = _VersionMismatchFailure;

  /// Error en la captura, reproducción o sesión de audio.
  const factory Failure.audio({String? message}) = _AudioFailure;

  /// No se pudo crear la red de la frecu en este teléfono.
  const factory Failure.hotspot(HotspotFailureReason reason) = _HotspotFailure;

  /// El teléfono no entró a la red de la frecu.
  const factory Failure.wifiJoin(WifiJoinFailureReason reason) =
      _WifiJoinFailure;

  /// No se pudo leer o grabar la invitación por NFC.
  const factory Failure.nfc(NfcFailureReason reason) = _NfcFailure;

  /// Error inesperado no categorizado.
  const factory Failure.unexpected({String? message, Object? error}) =
      _UnexpectedFailure;
}
