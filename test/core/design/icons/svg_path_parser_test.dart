// AC1: CUANDO se lee el atributo `d` de un trazo SVG con comandos M, L, H, V, C, S, Q, T, A y Z, absolutos o relativos, con repeticiones implícitas y números compactos (`.5.5`, `-2-2`, `1e-1`, banderas de arco pegadas) ENTONCES devuelve segmentos absolutos equivalentes al SVG; CUANDO el trazo está mal formado ENTONCES lanza `FormatException` con la posición del error.
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:frecu/core/design/icons/svg_path_parser.dart';

/// Tipo y números de un segmento, para compararlos con tolerancia.
(String, List<double>) describe(SvgPathSegment segment) => switch (segment) {
  SvgMoveTo(:final to) => ('M', [to.dx, to.dy]),
  SvgLineTo(:final to) => ('L', [to.dx, to.dy]),
  SvgCubicTo(:final control1, :final control2, :final to) => (
    'C',
    [control1.dx, control1.dy, control2.dx, control2.dy, to.dx, to.dy],
  ),
  SvgQuadTo(:final control, :final to) => (
    'Q',
    [control.dx, control.dy, to.dx, to.dy],
  ),
  SvgArcTo(
    :final to,
    :final radius,
    :final rotation,
    :final largeArc,
    :final clockwise,
  ) =>
    (
      'A',
      [
        radius.x,
        radius.y,
        rotation,
        if (largeArc) 1 else 0,
        if (clockwise) 1 else 0,
        to.dx,
        to.dy,
      ],
    ),
  SvgClose() => ('Z', const []),
};

void expectSegments(String d, List<(String, List<double>)> expected) {
  final actual = parseSvgPathData(d).map(describe).toList();
  expect(
    actual.map((s) => s.$1).toList(),
    expected.map((s) => s.$1).toList(),
    reason: d,
  );
  for (var i = 0; i < expected.length; i++) {
    final numbers = actual[i].$2;
    final wanted = expected[i].$2;
    expect(numbers.length, wanted.length, reason: '$d · segmento $i');
    for (var j = 0; j < wanted.length; j++) {
      expect(
        numbers[j],
        closeTo(wanted[j], 1e-9),
        reason: '$d · segmento $i · número $j',
      );
    }
  }
}

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

void expectRect(Rect actual, Rect expected, {double tolerance = 0.02}) {
  expect(actual.left, closeTo(expected.left, tolerance), reason: 'left');
  expect(actual.top, closeTo(expected.top, tolerance), reason: 'top');
  expect(actual.right, closeTo(expected.right, tolerance), reason: 'right');
  expect(actual.bottom, closeTo(expected.bottom, tolerance), reason: 'bottom');
}

Matcher formatErrorAt(int offset) =>
    throwsA(isA<FormatException>().having((e) => e.offset, 'offset', offset));

void main() {
  group('parseSvgPathData', () {
    test('AC1: lee M, L, H, V y Z absolutos', () {
      expectSegments('M1 2L3 4H5V6Z', [
        ('M', [1, 2]),
        ('L', [3, 4]),
        ('L', [5, 4]),
        ('L', [5, 6]),
        ('Z', []),
      ]);
    });

    test('AC1: lee m, l, h, v y z relativos al punto actual', () {
      expectSegments('m1 2l3 4h5v6z', [
        ('M', [1, 2]),
        ('L', [4, 6]),
        ('L', [9, 6]),
        ('L', [9, 12]),
        ('Z', []),
      ]);
    });

    test('AC1: tras z el punto actual vuelve al inicio del subtrazado', () {
      expectSegments('M1 1l3 0l0 3zl1 1', [
        ('M', [1, 1]),
        ('L', [4, 1]),
        ('L', [4, 4]),
        ('Z', []),
        ('L', [2, 2]),
      ]);
    });

    test('AC1: los pares que siguen a M y a L repiten el comando', () {
      expectSegments('M1 1 2 2 3 3', [
        ('M', [1, 1]),
        ('L', [2, 2]),
        ('L', [3, 3]),
      ]);
      expectSegments('m1 1 2 2', [
        ('M', [1, 1]),
        ('L', [3, 3]),
      ]);
      expectSegments('M0 0l1.5 4-2 1.6', [
        ('M', [0, 0]),
        ('L', [1.5, 4]),
        ('L', [-0.5, 5.6]),
      ]);
    });

    test('AC1: lee números compactos, exponentes, comas y espacios', () {
      expectSegments('M.5.5L-2-2', [
        ('M', [0.5, 0.5]),
        ('L', [-2, -2]),
      ]);
      expectSegments('M1e-1 2E1', [
        ('M', [0.1, 20]),
      ]);
      expectSegments(' M 0,0\n\tL1 , 2 ', [
        ('M', [0, 0]),
        ('L', [1, 2]),
      ]);
      expectSegments('M20 14v.01', [
        ('M', [20, 14]),
        ('L', [20, 14.01]),
      ]);
    });

    test('AC1: un trazo vacío no tiene segmentos', () {
      expect(parseSvgPathData(''), isEmpty);
      expect(parseSvgPathData('  \n'), isEmpty);
    });

    test('AC1: lee curvas cúbicas absolutas y relativas', () {
      expectSegments('M1 1C2 2 3 3 4 4c1 0 1 1 0 1', [
        ('M', [1, 1]),
        ('C', [2, 2, 3, 3, 4, 4]),
        ('C', [5, 4, 5, 5, 4, 5]),
      ]);
    });

    test('AC1: S refleja el segundo control de la cúbica anterior', () {
      expectSegments('M0 0C1 2 3 2 4 0S7 -2 8 0', [
        ('M', [0, 0]),
        ('C', [1, 2, 3, 2, 4, 0]),
        ('C', [5, -2, 7, -2, 8, 0]),
      ]);
      expectSegments('M0 0c1 2 3 2 4 0s3-2 4 0', [
        ('M', [0, 0]),
        ('C', [1, 2, 3, 2, 4, 0]),
        ('C', [5, -2, 7, -2, 8, 0]),
      ]);
    });

    test('AC1: S sin cúbica anterior usa el punto actual como control', () {
      expectSegments('M0 0S1 1 2 0', [
        ('M', [0, 0]),
        ('C', [0, 0, 1, 1, 2, 0]),
      ]);
      expectSegments('M0 0L1 0S2 1 3 0', [
        ('M', [0, 0]),
        ('L', [1, 0]),
        ('C', [1, 0, 2, 1, 3, 0]),
      ]);
    });

    test(
      'AC1: lee Q y T, y T refleja el control de la cuadrática anterior',
      () {
        expectSegments('M0 0Q1 2 2 0T4 0T6 0', [
          ('M', [0, 0]),
          ('Q', [1, 2, 2, 0]),
          ('Q', [3, -2, 4, 0]),
          ('Q', [5, 2, 6, 0]),
        ]);
        expectSegments('M0 0q1 2 2 0t2 0', [
          ('M', [0, 0]),
          ('Q', [1, 2, 2, 0]),
          ('Q', [3, -2, 4, 0]),
        ]);
        expectSegments('M0 0T2 0', [
          ('M', [0, 0]),
          ('Q', [0, 0, 2, 0]),
        ]);
      },
    );

    test('AC1: lee arcos absolutos y relativos con radio, giro y banderas', () {
      expectSegments('M5.5 11.5a6.5 6.5 0 0 0 13 0', [
        ('M', [5.5, 11.5]),
        ('A', [6.5, 6.5, 0, 0, 0, 18.5, 11.5]),
      ]);
      expectSegments('M0 0A2 3 30 1 1 4 4', [
        ('M', [0, 0]),
        ('A', [2, 3, 30, 1, 1, 4, 4]),
      ]);
      expectSegments('M19.5 12a7.5 7.5 0 1 1-2.2-5.3', [
        ('M', [19.5, 12]),
        ('A', [7.5, 7.5, 0, 1, 1, 17.3, 6.7]),
      ]);
    });

    test('AC1: lee banderas de arco pegadas entre sí y al número', () {
      expectSegments('M0 0a2 2 0 012 2', [
        ('M', [0, 0]),
        ('A', [2, 2, 0, 0, 1, 2, 2]),
      ]);
      expectSegments('M0 0a2 2 0 1,0 2,2', [
        ('M', [0, 0]),
        ('A', [2, 2, 0, 1, 0, 2, 2]),
      ]);
    });

    test(
      'AC1: normaliza arcos sin radio, sin recorrido y con radio negativo',
      () {
        expectSegments('M0 0A0 2 0 0 1 4 4', [
          ('M', [0, 0]),
          ('L', [4, 4]),
        ]);
        expectSegments('M1 1A2 2 0 0 1 1 1', [
          ('M', [1, 1]),
        ]);
        expectSegments('M0 0A-2 -2 0 0 1 4 0', [
          ('M', [0, 0]),
          ('A', [2, 2, 0, 0, 1, 4, 0]),
        ]);
      },
    );

    test('AC1: un trazo que no empieza con M es un error en la posición 0', () {
      expect(() => parseSvgPathData('L1 1'), formatErrorAt(0));
    });

    test('AC1: un comando desconocido es un error en su posición', () {
      expect(() => parseSvgPathData('M1 1X2'), formatErrorAt(4));
    });

    test('AC1: una bandera de arco que no es 0 ni 1 es un error', () {
      expect(() => parseSvgPathData('M0 0A1 1 0 2 1 3 3'), formatErrorAt(11));
    });

    test('AC1: faltan números o sobran tras Z', () {
      expect(() => parseSvgPathData('M1'), throwsFormatException);
      expect(() => parseSvgPathData('M0 0L1'), throwsFormatException);
      expect(() => parseSvgPathData('M0 0z1 1'), throwsFormatException);
    });
  });

  group('buildSvgPath', () {
    Path build(String d) => buildSvgPath(parseSvgPathData(d));

    test('AC1: dibuja líneas y cierres como el SVG', () {
      final path = build('M1 1H5V4Z');
      expectRect(tightBounds(path), const Rect.fromLTRB(1, 1, 5, 4));
      final length = path.computeMetrics().fold<double>(
        0,
        (sum, metric) => sum + metric.length,
      );
      expect(length, closeTo(4 + 3 + 5, 0.01));
    });

    test('AC1: un arco con barrido 0 baja y con barrido 1 sube', () {
      final down = build('M5.5 11.5a6.5 6.5 0 0 0 13 0');
      expectRect(tightBounds(down), const Rect.fromLTRB(5.5, 11.5, 18.5, 18));
      expect(down.computeMetrics().single.length, closeTo(math.pi * 6.5, 0.02));

      final up = build('M5.5 11.5a6.5 6.5 0 0 1 13 0');
      expectRect(tightBounds(up), const Rect.fromLTRB(5.5, 5, 18.5, 11.5));
    });

    test('AC1: un arco grande recorre tres cuartos del círculo', () {
      final path = build('M10 5A5 5 0 1 1 5 10');
      expectRect(tightBounds(path), const Rect.fromLTRB(5, 5, 15, 15));
      expect(
        path.computeMetrics().single.length,
        closeTo(1.5 * math.pi * 5, 0.03),
      );
    });

    test('AC1: un radio que no alcanza se agranda hasta el punto final', () {
      final path = build('M0 0A1 1 0 0 1 10 0');
      expectRect(tightBounds(path), const Rect.fromLTRB(0, -5, 10, 0));
    });

    test('AC1: dibuja cúbicas y cuadráticas hasta su punto final', () {
      final cubic = build('M0 0C0 4 4 4 4 0');
      expectRect(tightBounds(cubic), const Rect.fromLTRB(0, 0, 4, 3));
      final quad = build('M0 0Q2 4 4 0');
      expectRect(tightBounds(quad), const Rect.fromLTRB(0, 0, 4, 2));
    });
  });
}
