// AC2: CUANDO se dibuja un ícono de `FrIcons` ENTONCES su trazado sale en código de los trazos del prototipo (37 íconos, de `mic` a `dot`), cabe en la rejilla de 24 y respeta su geometría (por ejemplo, el arco del micrófono baja hasta y = 18 y el círculo de `info` ocupa de 3 a 21), sin fuentes de íconos, assets ni red.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';

/// Nombres del objeto `ICONS` de `docs/diseno/prototipo/components.js`, en
/// su orden.
const prototypeNames = [
  'mic',
  'micOff',
  'walkie',
  'openMic',
  'speaker',
  'earpiece',
  'bluetooth',
  'headset',
  'qr',
  'scan',
  'plus',
  'sliders',
  'back',
  'chevron',
  'down',
  'arrow',
  'close',
  'lock',
  'antenna',
  'users',
  'exit',
  'regen',
  'check',
  'alert',
  'info',
  'wifi',
  'hotspot',
  'globe',
  'flash',
  'signal',
  'backspace',
  'edit',
  'bell',
  'camera',
  'nodes',
  'volume',
  'dot',
  'pin',
  'msg',
  'sos',
  'nfc',
  'wind',
  'vibrate',
  'ear',
  'fuel',
  'flag',
  'share',
  'link',
  'globeOff',
];

/// Puntos sobre el trazado, cada 0,01 unidades.
List<Offset> samplesOf(Path path) => [
  for (final metric in path.computeMetrics()) ...[
    for (var d = 0.0; d < metric.length; d += 0.01)
      metric.getTangentForOffset(d)!.position,
    metric.getTangentForOffset(metric.length)!.position,
  ],
];

/// Límites del trazo dibujado (no de sus puntos de control).
Rect tightBounds(Path path) {
  final points = samplesOf(path);
  return Rect.fromLTRB(
    points.map((p) => p.dx).reduce(math.min),
    points.map((p) => p.dy).reduce(math.min),
    points.map((p) => p.dx).reduce(math.max),
    points.map((p) => p.dy).reduce(math.max),
  );
}

/// Distancia de [point] al trazado.
double distanceTo(Path path, Offset point) =>
    samplesOf(path).map((p) => (p - point).distance).reduce(math.min);

void expectRect(Rect actual, Rect expected, {double tolerance = 0.02}) {
  expect(actual.left, closeTo(expected.left, tolerance), reason: 'left');
  expect(actual.top, closeTo(expected.top, tolerance), reason: 'top');
  expect(actual.right, closeTo(expected.right, tolerance), reason: 'right');
  expect(actual.bottom, closeTo(expected.bottom, tolerance), reason: 'bottom');
}

void main() {
  test('AC2: el catálogo tiene los 49 íconos del prototipo, en su orden', () {
    expect(FrIcons.values.map((icon) => icon.name).toList(), prototypeNames);
  });

  test('AC2: las formas son las del prototipo, copiadas tal cual', () {
    expect(FrIcons.mic.shapes, const [
      FrIconRect(9, 3, 6, 11.5, rx: 3),
      FrIconPath('M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v3M8.5 21h7'),
    ]);
    expect(FrIcons.sliders.shapes, const [
      FrIconPath('M4 7h9M17 7h3M4 17h3M11 17h9'),
      FrIconCircle(15, 7, 2),
      FrIconCircle(9, 17, 2),
    ]);
    expect(FrIcons.dot.shapes, const [FrIconCircle(12, 12, 3, filled: true)]);
  });

  test('AC2: cada ícono se dibuja y cabe en la rejilla de 24', () {
    for (final icon in FrIcons.values) {
      final bounds = tightBounds(icon.geometry.stroke);
      expect(bounds.width + bounds.height, greaterThan(1), reason: icon.name);
      expect(bounds.left, greaterThanOrEqualTo(-1e-6), reason: icon.name);
      expect(bounds.top, greaterThanOrEqualTo(-1e-6), reason: icon.name);
      expect(bounds.right, lessThanOrEqualTo(24 + 1e-6), reason: icon.name);
      expect(bounds.bottom, lessThanOrEqualTo(24 + 1e-6), reason: icon.name);
    }
  });

  test('AC2: el arco del micrófono baja hasta y = 18', () {
    final mic = FrIcons.mic.geometry.stroke;
    expectRect(tightBounds(mic), const Rect.fromLTRB(5.5, 3, 18.5, 21));
    expect(distanceTo(mic, const Offset(12, 18)), lessThan(0.05));
    expect(distanceTo(mic, const Offset(12, 5)), greaterThan(1));
  });

  test('AC2: el círculo de info ocupa de 3 a 21', () {
    final info = FrIcons.info.geometry.stroke;
    expectRect(tightBounds(info), const Rect.fromLTRB(3, 3, 21, 21));
    expect(distanceTo(info, const Offset(12, 16.5)), lessThan(0.05));
    expect(distanceTo(info, const Offset(12, 7.5)), lessThan(0.05));
  });

  test('AC2: líneas, rectángulos redondeados y arcos grandes en su sitio', () {
    expectRect(
      tightBounds(FrIcons.check.geometry.stroke),
      const Rect.fromLTRB(5, 7.5, 19, 17),
    );
    expectRect(
      tightBounds(FrIcons.plus.geometry.stroke),
      const Rect.fromLTRB(5, 5, 19, 19),
    );
    expectRect(
      tightBounds(FrIcons.volume.geometry.stroke),
      const Rect.fromLTRB(8, 2.5, 19.5, 21.5),
    );
    final regen = FrIcons.regen.geometry.stroke;
    expect(distanceTo(regen, const Offset(4.5, 12)), lessThan(0.05));
    expect(distanceTo(regen, const Offset(12, 19.5)), lessThan(0.05));
  });

  test('AC2: solo dot tiene relleno', () {
    for (final icon in FrIcons.values) {
      final filled = icon.geometry.fill.computeMetrics().isNotEmpty;
      expect(filled, icon == FrIcons.dot, reason: icon.name);
    }
    expectRect(
      tightBounds(FrIcons.dot.geometry.fill),
      const Rect.fromLTRB(9, 9, 15, 15),
    );
  });

  test('AC2: la geometría se calcula una vez y se reutiliza', () {
    expect(
      identical(FrIcons.antenna.geometry, FrIcons.antenna.geometry),
      isTrue,
    );
  });

  testWidgets('AC2: FrIcon dibuja en código, sin texto de fuente ni imagen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: FrIcon(FrIcons.walkie)),
      ),
    );
    final icon = find.byType(FrIcon);
    expect(
      find.descendant(of: icon, matching: find.byType(CustomPaint)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: icon, matching: find.byType(RichText)),
      findsNothing,
    );
    expect(
      find.descendant(of: icon, matching: find.byType(Image)),
      findsNothing,
    );
  });
}
