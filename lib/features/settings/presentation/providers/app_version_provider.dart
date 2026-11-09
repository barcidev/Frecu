import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/settings/data/datasources/app_info_datasource.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version_provider.g.dart';

/// Proveedor global de la fuente de datos de la app instalada.
@Riverpod(keepAlive: true)
AppInfoDataSource appInfoDataSource(Ref ref) => AppInfoDataSource();

/// Versión de la app instalada (p. ej. `0.1.0`); nula si no se pudo leer o
/// viene vacía.
@Riverpod(keepAlive: true)
Future<String?> appVersion(Ref ref) async {
  try {
    final version = await ref.watch(appInfoDataSourceProvider).version();
    return version.isEmpty ? null : version;
  } on Object catch (e, st) {
    AppLogger.e('Error reading the app version', e, st);
    return null;
  }
}
