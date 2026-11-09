import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_point.freezed.dart';

/// Radio medio de la Tierra, en metros.
const double earthRadiusMeters = 6371000;

/// Punto de la superficie en grados.
@freezed
abstract class GeoPoint with _$GeoPoint {
  /// Crea el punto en [lat] y [lon], en grados.
  const factory GeoPoint({required double lat, required double lon}) =
      _GeoPoint;

  const GeoPoint._();

  /// Distancia hasta [other] en metros, por la fórmula del semiverseno.
  double distanceTo(GeoPoint other) {
    final dLat = _rad(other.lat - lat);
    final dLon = _rad(other.lon - lon);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(other.lat)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadiusMeters * math.asin(math.min(1, math.sqrt(a)));
  }

  /// Rumbo inicial hacia [other] en grados, de 0 (norte) a 360, en el
  /// sentido de las agujas del reloj.
  double bearingTo(GeoPoint other) {
    final phi1 = _rad(lat);
    final phi2 = _rad(other.lat);
    final dLon = _rad(other.lon - lon);
    final y = math.sin(dLon) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double _rad(double degrees) => degrees * math.pi / 180;
}

/// Los ocho rumbos de la rosa de los vientos.
enum CompassPoint {
  /// Norte.
  n,

  /// Noreste.
  ne,

  /// Este.
  e,

  /// Sureste.
  se,

  /// Sur.
  s,

  /// Suroeste.
  sw,

  /// Oeste.
  w,

  /// Noroeste.
  nw;

  /// Rumbo más cercano a [degrees] (0 = norte).
  static CompassPoint of(double degrees) =>
      values[((degrees % 360) / 45).round() % values.length];
}
