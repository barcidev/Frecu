import 'package:frecu/features/location/domain/entities/geo_point.dart';

/// Distancia al compañero más cercano a partir de la cual alguien se va
/// quedando atrás. Es un primer valor: se ajusta probándolo en ruta.
const double behindDistanceMeters = 200;

/// Tiempo que alguien debe seguir lejos para avisar, y así no avisar por una
/// curva o un adelantamiento.
const Duration behindHold = Duration(seconds: 20);

/// Personas que comparten su ubicación necesarias para hablar de «grupo»:
/// con dos no se sabe quién se quedó atrás.
const int behindMinGroup = 3;

/// Decide quién se quedó atrás: alguien cuyo compañero más cercano está a más
/// de [threshold] metros durante al menos [hold]. Solo hay grupo con
/// [behindMinGroup] o más posiciones.
class BehindTracker {
  /// Crea la regla con sus límites.
  BehindTracker({
    this.threshold = behindDistanceMeters,
    this.hold = behindHold,
  });

  /// Distancia al más cercano para contar como lejos.
  final double threshold;

  /// Tiempo lejos para avisar.
  final Duration hold;

  final Map<String, DateTime> _farSince = {};

  /// Con las posiciones de ahora por id (la propia incluida), devuelve
  /// quiénes se quedaron atrás en [now].
  Set<String> update(Map<String, GeoPoint> positions, DateTime now) {
    _farSince.removeWhere((id, _) => !positions.containsKey(id));
    if (positions.length < behindMinGroup) {
      _farSince.clear();
      return const {};
    }
    final behind = <String>{};
    for (final MapEntry(key: id, value: point) in positions.entries) {
      final nearest = positions.entries
          .where((other) => other.key != id)
          .map((other) => point.distanceTo(other.value))
          .reduce((a, b) => a < b ? a : b);
      if (nearest <= threshold) {
        _farSince.remove(id);
        continue;
      }
      final since = _farSince.putIfAbsent(id, () => now);
      if (now.difference(since) >= hold) behind.add(id);
    }
    return behind;
  }

  /// Olvida todo, p. ej. al dejar de compartir.
  void reset() => _farSince.clear();
}
