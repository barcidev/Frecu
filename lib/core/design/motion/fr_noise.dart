/// Hash, aleatorio determinista, ruido Perlin y voz simulada de Portadora.
///
/// Copian `hash`, `rng`, `noise2` y `voice` de `engine.js` del prototipo para
/// que la firma de un nombre y el movimiento orgánico sean iguales en todos
/// los teléfonos. Dart puro.
library;

import 'dart:math' as math;

const int _mask32 = 0xFFFFFFFF;
const double _tau = math.pi * 2;

/// FNV-1a de 32 bits sobre las unidades UTF-16 de [text].
int frHash(String text) {
  var hash = 0x811C9DC5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & _mask32;
  }
  return hash;
}

/// Producto de 32 bits sin signo (`Math.imul`) sin desbordar el entero de 64.
int _imul(int a, int b) {
  final low = (a & 0xFFFF) * b;
  final high = (((a >> 16) & 0xFFFF) * b) & 0xFFFF;
  return (low + (high << 16)) & _mask32;
}

/// Aleatorio determinista mulberry32: la misma semilla da la misma serie.
class FrRandom {
  /// Crea la serie de [seed].
  FrRandom(int seed) : _state = seed & _mask32;

  int _state;

  /// Siguiente valor en [0, 1).
  double next() {
    _state = (_state + 0x6D2B79F5) & _mask32;
    var t = _imul(_state ^ (_state >> 15), 1 | _state);
    t = ((t + _imul(t ^ (t >> 7), 61 | t)) & _mask32) ^ t;
    return ((t ^ (t >> 14)) & _mask32) / 4294967296;
  }
}

final List<int> _perm = _buildPermutation();

List<int> _buildPermutation() {
  final random = FrRandom(1337);
  final p = List<int>.generate(256, (i) => i);
  for (var i = 255; i > 0; i--) {
    final j = (random.next() * (i + 1)).floor();
    final swap = p[i];
    p[i] = p[j];
    p[j] = swap;
  }
  return List<int>.generate(512, (i) => p[i & 255]);
}

double _grad(int hash, double x, double y) => switch (hash & 7) {
  0 => x + y,
  1 => -x + y,
  2 => x - y,
  3 => -x - y,
  4 => x,
  5 => -x,
  6 => y,
  _ => -y,
};

double _fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _clamp01(double value) => math.min(1, math.max(0, value));

double _smooth(double a, double b, double value) {
  final t = _clamp01((value - a) / (b - a));
  return t * t * (3 - 2 * t);
}

/// Ruido Perlin 2D, aproximadamente en [-1, 1].
double frNoise2(double x, double y) {
  final fx = x.floor();
  final fy = y.floor();
  final xi = fx & 255;
  final yi = fy & 255;
  final dx = x - fx;
  final dy = y - fy;
  final u = _fade(dx);
  final v = _fade(dy);
  final aa = _perm[_perm[xi] + yi];
  final ab = _perm[_perm[xi] + yi + 1];
  final ba = _perm[_perm[xi + 1] + yi];
  final bb = _perm[_perm[xi + 1] + yi + 1];
  return _lerp(
    _lerp(_grad(aa, dx, dy), _grad(ba, dx - 1, dy), u),
    _lerp(_grad(ab, dx, dy - 1), _grad(bb, dx - 1, dy - 1), u),
    v,
  );
}

/// Ruido Perlin 1D (un corte de [frNoise2]).
double frNoise1(double x) => frNoise2(x, 0.37);

/// Envolvente de voz simulada en [0, 1] en el segundo [t]: sílabas, frases y
/// pausas. [seed] separa a las personas.
double frVoice(double t, [int seed = 0]) {
  final s = seed * 17.3;
  final syllable = math.max(
    0,
    math.sin(t * _tau * 4.1 + frNoise1(t * 0.8 + s) * 4),
  );
  final phrase = _smooth(-0.12, 0.22, frNoise1(t * 0.45 + s + 9));
  final grain = 0.62 + 0.38 * frNoise1(t * 6 + s);
  return _clamp01(syllable * phrase * grain * 1.35);
}
