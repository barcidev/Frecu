import 'dart:io';

import 'package:frecu/features/location/domain/entities/geo_point.dart';
import 'package:geolocator/geolocator.dart';

/// Posición del GPS del teléfono con `geolocator`.
///
/// Pide una medida cada 10 m de movimiento. En iOS sigue con la pantalla
/// apagada (modo de fondo `location`, con el indicador azul) y en Android lo
/// hace el servicio en primer plano de tipo `location`.
class PositionDataSource {
  /// Crea la fuente; [positions] reemplaza al GPS en pruebas.
  PositionDataSource({Stream<GeoPoint> Function()? positions})
    : _positions = positions ?? _gps;

  final Stream<GeoPoint> Function() _positions;

  /// Medidas del GPS mientras se escuchan.
  Stream<GeoPoint> watch() => _positions();

  static Stream<GeoPoint> _gps() =>
      Geolocator.getPositionStream(locationSettings: _settings())
          .map((p) => GeoPoint(lat: p.latitude, lon: p.longitude));

  static LocationSettings _settings() {
    const distanceFilter = 10;
    if (Platform.isIOS) {
      return AppleSettings(
        distanceFilter: distanceFilter,
        activityType: ActivityType.otherNavigation,
        // Por defecto no se pausa y sigue con la pantalla apagada; el
        // indicador azul avisa que la ubicación está en uso.
        showBackgroundLocationIndicator: true,
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        distanceFilter: distanceFilter,
        intervalDuration: const Duration(seconds: 5),
      );
    }
    return const LocationSettings(distanceFilter: distanceFilter);
  }
}
