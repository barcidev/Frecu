import 'package:frecu/core/error/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

/// Resultado funcional sellado para retornos libres de excepciones no controladas.
@freezed
sealed class Result<T> with _$Result<T> {
  const Result._();

  /// Operación exitosa con dato [data].
  const factory Result.success(T data) = Success<T>;

  /// Operación fallida con [failure].
  const factory Result.failure(Failure failure) = FailureResult<T>;

  /// Indica si el resultado fue exitoso.
  bool get isSuccess => this is Success<T>;

  /// Indica si el resultado fue fallido.
  bool get isFailure => this is FailureResult<T>;

  /// Retorna el dato si fue exitoso, o null si fue fallido.
  T? get dataOrNull => when(success: (data) => data, failure: (_) => null);

  /// Retorna la falla si fue fallido, o null si fue exitoso.
  Failure? get failureOrNull =>
      when(success: (_) => null, failure: (failure) => failure);
}
