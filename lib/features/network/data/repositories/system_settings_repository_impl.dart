import 'package:frecu/core/error/failure.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/data/datasources/system_settings_datasource.dart';
import 'package:frecu/features/network/domain/repositories/system_settings_repository.dart';

/// Implementación de [SystemSettingsRepository] con los plugins de Ajustes.
class SystemSettingsRepositoryImpl implements SystemSettingsRepository {
  /// Crea el repositorio sobre [dataSource].
  const SystemSettingsRepositoryImpl({required this.dataSource});

  /// Plugins de Ajustes.
  final SystemSettingsDataSource dataSource;

  @override
  Future<Result<void>> openWifiSettings() => _open(() async {
    await dataSource.openWifi();
    return true;
  });

  @override
  Future<Result<void>> openHotspotSettings() => _open(() async {
    await dataSource.openHotspot();
    return true;
  });

  @override
  Future<Result<void>> openAppSettings() => _open(dataSource.openApp);

  @override
  Future<Result<void>> openLocationSettings() => _open(() async {
    await dataSource.openLocation();
    return true;
  });

  /// Abre con [open], que dice si el sistema mostró los Ajustes.
  Future<Result<void>> _open(Future<bool> Function() open) async {
    try {
      if (await open()) return const Result.success(null);
      AppLogger.w('The system settings did not open');
      return const Result.failure(
        Failure.unexpected(message: 'The system settings did not open'),
      );
    } on Object catch (error, stackTrace) {
      AppLogger.w('Could not open the system settings', error, stackTrace);
      return Result.failure(
        Failure.unexpected(message: error.toString(), error: error),
      );
    }
  }
}
