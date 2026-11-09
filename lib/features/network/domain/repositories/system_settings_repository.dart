import 'package:frecu/core/result/result.dart';

/// Contrato para abrir pantallas de Ajustes del sistema desde la app.
///
/// iOS no deja abrir la Wi-Fi ni el punto de acceso desde otra app: allí
/// las tres abren los Ajustes de Frecu, desde donde se vuelve a Ajustes.
abstract interface class SystemSettingsRepository {
  /// Abre los ajustes de Wi-Fi.
  Future<Result<void>> openWifiSettings();

  /// Abre los ajustes del punto de acceso (zona Wi-Fi).
  Future<Result<void>> openHotspotSettings();

  /// Abre los ajustes de la app, donde están sus permisos (cámara…).
  Future<Result<void>> openAppSettings();

  /// Abre los ajustes de ubicación (Android 12 o anterior la exige para
  /// crear la red de la frecu).
  Future<Result<void>> openLocationSettings();
}
