import 'package:frecu/core/result/result.dart';

/// Contrato base para casos de uso asíncronos en la capa de dominio.
abstract interface class UseCase<Type, Params> {
  /// Ejecuta el caso de uso con [params].
  Future<Result<Type>> call(Params params);
}

/// Parámetro vacío para casos de uso sin parámetros requeridos.
final class NoParams {
  /// Constructor constante.
  const NoParams();
}
