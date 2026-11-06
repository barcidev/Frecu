import 'package:frecu/core/result/result.dart';

/// Contrato base para casos de uso asíncronos en la capa de dominio.
abstract class UseCase<T, Params> {
  /// Constructor constante.
  const UseCase();

  /// Nombre descriptivo del caso de uso para logging y observabilidad.
  String get name => runtimeType.toString();

  /// Ejecuta el caso de uso con [params].
  Future<Result<T>> call(Params params);
}

/// Parámetro vacío para casos de uso sin parámetros requeridos.
final class NoParams {
  /// Constructor constante.
  const NoParams();
}
