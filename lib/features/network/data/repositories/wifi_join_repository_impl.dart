import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/data/datasources/wifi_join_datasource.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/domain/repositories/wifi_join_repository.dart';

/// Cómo llega el invitado a la red del anfitrión, sobre el canal
/// `frecu/wifi`.
///
/// Tras conectar a la red, espera a que el anfitrión responda: la IP y las
/// rutas tardan un poco, y en iOS el permiso de red local puede salir en ese
/// momento.
class WifiJoinRepositoryImpl implements WifiJoinRepository {
  /// Crea el repositorio sobre [dataSource]; los tiempos son configurables
  /// para pruebas.
  const WifiJoinRepositoryImpl({
    required WifiJoinDataSource dataSource,
    this.probeTimeout = const Duration(milliseconds: 1500),
    this.joinTimeout = const Duration(seconds: 12),
    this.retryDelay = const Duration(milliseconds: 500),
  }) : _source = dataSource;

  final WifiJoinDataSource _source;

  /// Espera máxima de cada prueba de conexión al anfitrión.
  final Duration probeTimeout;

  /// Espera máxima a que el anfitrión responda tras conectar a la red.
  final Duration joinTimeout;

  /// Pausa entre pruebas de conexión.
  final Duration retryDelay;

  @override
  Future<bool> route(String host) => _source.route(host);

  @override
  Future<bool> reaches(String host, int port) async {
    await _source.route(host);
    return _source.probe(host, port, probeTimeout);
  }

  @override
  Future<Result<void>> join(
    WifiCredentials credentials, {
    required String host,
    required int port,
  }) async {
    try {
      await _source.join(credentials.ssid, credentials.passphrase);
    } on WifiJoinException catch (e) {
      return Result.failure(Failure.wifiJoin(reasonOf(e.code)));
    } on Object {
      return const Result.failure(
        Failure.wifiJoin(WifiJoinFailureReason.failed),
      );
    }
    final deadline = DateTime.now().add(joinTimeout);
    while (true) {
      if (await reaches(host, port)) return const Result<void>.success(null);
      if (!DateTime.now().isBefore(deadline)) break;
      await Future<void>.delayed(retryDelay);
    }
    return const Result.failure(
      Failure.wifiJoin(WifiJoinFailureReason.notFound),
    );
  }

  @override
  Future<void> release() => _source.release();

  /// Motivo del fallo con el código nativo [code].
  static WifiJoinFailureReason reasonOf(String code) => switch (code) {
    'unsupported' => WifiJoinFailureReason.unsupported,
    'declined' => WifiJoinFailureReason.declined,
    'not_found' => WifiJoinFailureReason.notFound,
    _ => WifiJoinFailureReason.failed,
  };
}
