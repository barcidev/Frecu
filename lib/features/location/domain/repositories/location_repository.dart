import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/location/domain/entities/geo_point.dart';

/// Ubicación compartida dentro de la frecu activa. Es voluntaria: nadie
/// comparte la suya hasta que lo activa.
abstract interface class LocationRepository {
  /// Posición de cada persona que comparte la suya, por su id; empieza con
  /// el valor actual. Quien deja de compartir o sale de la frecu desaparece.
  Stream<Map<String, GeoPoint>> watchPeers();

  /// Posición propia mientras se comparte.
  Stream<GeoPoint> watchOwn();

  /// Si se está compartiendo la propia.
  bool get isSharing;

  /// Empieza a compartir la propia con la frecu (el permiso ya concedido).
  Future<Result<void>> startSharing();

  /// Deja de compartirla y avisa a la frecu.
  Future<void> stopSharing();
}
