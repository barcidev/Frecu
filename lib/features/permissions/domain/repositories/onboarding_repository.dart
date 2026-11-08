import 'package:frecu/core/result/result.dart';

/// Contrato del registro del recorrido de la primera vez (bienvenida, nombre
/// y permisos).
///
/// El recorrido se da por completo al pulsar Continuar en los permisos, con
/// cualquier respuesta: lo que falte se vuelve a pedir en contexto (el
/// micrófono al entrar a una frecu, la cámara al escanear).
abstract interface class OnboardingRepository {
  /// Si el recorrido ya se completó en este teléfono.
  Future<Result<bool>> isCompleted();

  /// Guarda que el recorrido se completó.
  Future<Result<void>> markCompleted();
}
