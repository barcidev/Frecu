import 'package:freezed_annotation/freezed_annotation.dart';

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

  /// Error en la captura, reproducción o sesión de audio.
  const factory Failure.audio({String? message}) = _AudioFailure;

  /// Error inesperado no categorizado.
  const factory Failure.unexpected({String? message, Object? error}) =
      _UnexpectedFailure;
}
