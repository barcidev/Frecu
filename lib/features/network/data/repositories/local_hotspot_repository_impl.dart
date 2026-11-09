import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/data/datasources/local_hotspot_datasource.dart';
import 'package:frecu/features/network/domain/entities/local_hotspot.dart';
import 'package:frecu/features/network/domain/entities/wifi_credentials.dart';
import 'package:frecu/features/network/domain/repositories/local_hotspot_repository.dart';

/// La red de la frecu sobre el canal `frecu/hotspot`.
///
/// Si Android dice que falta el permiso, lo pide una vez y reintenta; el
/// código nativo de cada fallo se traduce a [HotspotFailureReason].
class LocalHotspotRepositoryImpl implements LocalHotspotRepository {
  /// Crea el repositorio sobre [dataSource].
  const LocalHotspotRepositoryImpl({required LocalHotspotDataSource dataSource})
    : _source = dataSource;

  final LocalHotspotDataSource _source;

  @override
  Future<Result<LocalHotspot>> start() async {
    try {
      return Result.success(_hotspot(await _source.start()));
    } on LocalHotspotException catch (e) {
      final nearby = e.code == 'permission_nearby';
      if (!nearby && e.code != 'permission_location') {
        return Result.failure(Failure.hotspot(reasonOf(e.code)));
      }
      final granted = await _source.requestPermission(nearby: nearby);
      if (!granted) return Result.failure(Failure.hotspot(reasonOf(e.code)));
      return _startOnce();
    } on Object catch (e, st) {
      AppLogger.w('Could not create the local hotspot', e, st);
      return const Result.failure(Failure.hotspot(HotspotFailureReason.failed));
    }
  }

  /// Segundo intento, ya con el permiso: si vuelve a fallar, no pide nada.
  Future<Result<LocalHotspot>> _startOnce() async {
    try {
      return Result.success(_hotspot(await _source.start()));
    } on LocalHotspotException catch (e) {
      return Result.failure(Failure.hotspot(reasonOf(e.code)));
    } on Object catch (e, st) {
      AppLogger.w('Could not create the local hotspot', e, st);
      return const Result.failure(Failure.hotspot(HotspotFailureReason.failed));
    }
  }

  @override
  Future<void> stop() => _source.stop();

  @override
  Stream<void> watchStopped() => _source.stopped;

  static LocalHotspot _hotspot(LocalHotspotInfo info) => LocalHotspot(
    credentials: WifiCredentials(ssid: info.ssid, passphrase: info.passphrase),
    interfaceName: info.interfaceName,
    address: info.address,
  );

  /// Motivo del fallo con el código nativo [code].
  static HotspotFailureReason reasonOf(String code) => switch (code) {
    'unsupported' => HotspotFailureReason.unsupported,
    'permission_nearby' => HotspotFailureReason.nearbyDenied,
    'permission_location' => HotspotFailureReason.locationDenied,
    'location_off' => HotspotFailureReason.locationOff,
    'incompatible_mode' => HotspotFailureReason.hotspotOn,
    _ => HotspotFailureReason.failed,
  };
}
