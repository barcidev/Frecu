import 'package:frecu/features/location/domain/entities/geo_point.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Distancia legible: de 10 en 10 m hasta 1 km y después en km con un
/// decimal, con la coma o el punto del idioma.
String distanceLabel(double meters) {
  final texts = t.location;
  if (meters < 1000) {
    final rounded = ((meters / 10).round() * 10).clamp(10, 990);
    return texts.meters(value: '$rounded');
  }
  final km = (meters / 1000).toStringAsFixed(1);
  final decimal = LocaleSettings.currentLocale == AppLocale.en
      ? km
      : km.replaceAll('.', ',');
  return texts.kilometers(value: decimal);
}

/// Rumbo corto (N, NE…) de [bearing] en grados.
String compassLabel(double bearing) {
  final c = t.location.compass;
  return switch (CompassPoint.of(bearing)) {
    CompassPoint.n => c.n,
    CompassPoint.ne => c.ne,
    CompassPoint.e => c.e,
    CompassPoint.se => c.se,
    CompassPoint.s => c.s,
    CompassPoint.sw => c.sw,
    CompassPoint.w => c.w,
    CompassPoint.nw => c.nw,
  };
}

/// Rumbo largo (norte, noreste…) de [bearing] en grados.
String compassLongLabel(double bearing) {
  final c = t.location.compassLong;
  return switch (CompassPoint.of(bearing)) {
    CompassPoint.n => c.n,
    CompassPoint.ne => c.ne,
    CompassPoint.e => c.e,
    CompassPoint.se => c.se,
    CompassPoint.s => c.s,
    CompassPoint.sw => c.sw,
    CompassPoint.w => c.w,
    CompassPoint.nw => c.nw,
  };
}

/// «120 m NE»: distancia y rumbo hacia alguien.
String towardsLabel(({double meters, double bearing}) towards) =>
    t.location.towards(
      distance: distanceLabel(towards.meters),
      direction: compassLabel(towards.bearing),
    );
