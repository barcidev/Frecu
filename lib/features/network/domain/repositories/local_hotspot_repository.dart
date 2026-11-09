import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/network/domain/entities/local_hotspot.dart';

/// La red de la frecu que crea el anfitrión Android desde la app.
abstract interface class LocalHotspotRepository {
  /// Crea la red, pidiendo antes el permiso que Android exige, o devuelve la
  /// que ya estaba al aire. Falla con `Failure.hotspot`.
  Future<Result<LocalHotspot>> start();

  /// Apaga la red; no hace nada si no estaba al aire.
  Future<void> stop();

  /// Avisa cada vez que Android apaga la red sin que la app lo pida (se
  /// encendió la zona Wi-Fi, modo avión…).
  Stream<void> watchStopped();
}
