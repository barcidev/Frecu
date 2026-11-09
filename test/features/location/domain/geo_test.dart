// Ubicación (corte 4 de la épica de hardware V1): distancia por el
// semiverseno, rumbo inicial y rosa de 8 rumbos; y la regla de «se quedó
// atrás»: con 3 o más posiciones, quien tiene al más cercano a más de 200 m
// durante 20 s.
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/features/location/domain/entities/behind_tracker.dart';
import 'package:frecu/features/location/domain/entities/geo_point.dart';

/// Punto a [north] y [east] metros de un origen en el ecuador (aprox.).
GeoPoint _at({double north = 0, double east = 0}) =>
    GeoPoint(lat: north / 111195, lon: east / 111195);

void main() {
  group('GeoPoint', () {
    test('distancia: 1° de latitud son unos 111 km', () {
      const a = GeoPoint(lat: 4, lon: -74);
      const b = GeoPoint(lat: 5, lon: -74);
      expect(a.distanceTo(b), closeTo(111195, 50));
      expect(a.distanceTo(a), 0);
    });

    test('distancia corta en metros', () {
      expect(_at().distanceTo(_at(north: 120)), closeTo(120, 0.5));
    });

    test('rumbo: norte 0, este 90, sur 180, oeste 270', () {
      final o = _at();
      expect(o.bearingTo(_at(north: 100)), closeTo(0, 0.01));
      expect(o.bearingTo(_at(east: 100)), closeTo(90, 0.01));
      expect(o.bearingTo(_at(north: -100)), closeTo(180, 0.01));
      expect(o.bearingTo(_at(east: -100)), closeTo(270, 0.01));
    });

    test('rosa de 8 rumbos', () {
      expect(CompassPoint.of(0), CompassPoint.n);
      expect(CompassPoint.of(44), CompassPoint.ne);
      expect(CompassPoint.of(100), CompassPoint.e);
      expect(CompassPoint.of(200), CompassPoint.s);
      expect(CompassPoint.of(225), CompassPoint.sw);
      expect(CompassPoint.of(350), CompassPoint.n);
    });
  });

  group('BehindTracker', () {
    final t0 = DateTime(2026, 11, 9, 10);

    test('con menos de 3 posiciones no hay grupo', () {
      final tracker = BehindTracker();
      final positions = {'a': _at(), 'b': _at(north: 5000)};
      expect(tracker.update(positions, t0), isEmpty);
      expect(tracker.update(positions, t0.add(behindHold)), isEmpty);
    });

    test('avisa solo tras seguir lejos el tiempo de espera', () {
      final tracker = BehindTracker();
      final positions = {
        'a': _at(),
        'b': _at(north: 50),
        'c': _at(north: -850),
      };

      expect(tracker.update(positions, t0), isEmpty);
      expect(
        tracker.update(positions, t0.add(const Duration(seconds: 10))),
        isEmpty,
      );
      expect(tracker.update(positions, t0.add(behindHold)), {'c'});
    });

    test('si se acerca antes, la cuenta empieza de nuevo', () {
      final tracker = BehindTracker();
      final far = {'a': _at(), 'b': _at(north: 50), 'c': _at(north: -850)};
      final near = {'a': _at(), 'b': _at(north: 50), 'c': _at(north: -100)};

      tracker
        ..update(far, t0)
        ..update(near, t0.add(const Duration(seconds: 15)));

      expect(tracker.update(far, t0.add(const Duration(seconds: 25))), isEmpty);
      expect(tracker.update(far, t0.add(const Duration(seconds: 45))), {'c'});
    });
  });
}
