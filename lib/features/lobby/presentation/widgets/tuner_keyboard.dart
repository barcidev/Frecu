/// Teclado de dos octavas (Do4–Si5) del sintonizador del inicio y su aguja:
/// funciones puras que copian `keyX` y el barrido de `drawTuner` de
/// `engine.js`. Dart puro.
library;

import 'dart:math' as math;

import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Clases de altura de las teclas blancas (`WHITE` del prototipo).
const List<int> tunerWhiteClasses = [0, 2, 4, 5, 7, 9, 11];

/// Clases de altura de las teclas negras.
const List<int> tunerBlackClasses = [1, 3, 6, 8, 10];

/// Centro de la tecla del [semitone] (0 = Do4 … 23 = Si5) en un teclado de
/// dos octavas que empieza en [left] con teclas blancas de [keyWidth]
/// (`keyX` del prototipo): una blanca en el centro de su tecla y una negra en
/// la juntura de las dos blancas que la rodean.
double tunerKeyX(
  int semitone, {
  required double left,
  required double keyWidth,
}) {
  final octave = semitone ~/ 12;
  final pitchClass = semitone % 12;
  final white = tunerWhiteClasses.indexOf(pitchClass);
  final keys = white >= 0
      ? octave * 7 + white + 0.5
      : octave * 7 + tunerWhiteClasses.indexOf(pitchClass - 1) + 1.0;
  return left + keys * keyWidth;
}

/// Semitono cuya tecla queda más cerca de [x] en el teclado de
/// [tunerKeyX]: la nota que nombra la lectura de la aguja.
int tunerNearestSemitone(
  double x, {
  required double left,
  required double keyWidth,
}) {
  var nearest = 0;
  var distance = double.infinity;
  for (var semitone = 0; semitone < RoomNote.semitoneCount; semitone++) {
    final d = (tunerKeyX(semitone, left: left, keyWidth: keyWidth) - x).abs();
    if (d < distance) {
      distance = d;
      nearest = semitone;
    }
  }
  return nearest;
}

/// Destino de la aguja sin frecu elegida en el segundo [seconds], en
/// fracción del teclado: barre las dos octavas sin salirse.
double tunerSweep(double seconds) =>
    0.5 + 0.44 * math.sin(seconds * 0.42) + 0.02 * frNoise1(seconds * 3);

/// Aguja del sintonizador: un resorte (rigidez 90, amortiguación 16) que
/// avanza en pasos de 1/60 s con Euler semiimplícito, como el prototipo.
///
/// La posición va en fracción del teclado (0 = borde izquierdo).
class TunerNeedle {
  /// Crea la aguja quieta en el centro del teclado, como el prototipo.
  TunerNeedle();

  /// Rigidez del resorte.
  static const double stiffness = 90;

  /// Amortiguación del resorte.
  static const double damping = 16;

  /// Paso de la integración.
  static const double step = 1 / 60;

  /// Pasos como máximo por avance: tras una pausa larga no se pone al día.
  static const int _maxSteps = 30;

  double _position = 0.5;
  double _velocity = 0;
  double _pending = 0;

  /// Posición en fracción del teclado.
  double get position => _position;

  /// Velocidad en fracciones del teclado por segundo.
  double get velocity => _velocity;

  /// Avanza [seconds] hacia [target] en pasos de 1/60 s; lo que no llega a
  /// un paso queda para el siguiente avance.
  void advance(double target, double seconds) {
    _pending += seconds;
    var steps = 0;
    while (_pending >= step - 1e-9 && steps < _maxSteps) {
      final acceleration =
          -stiffness * (_position - target) - damping * _velocity;
      _velocity += acceleration * step;
      _position += _velocity * step;
      _pending -= step;
      steps++;
    }
    if (steps == _maxSteps) _pending = 0;
  }

  /// Salta a [target] y queda quieta.
  void jumpTo(double target) {
    _position = target;
    _velocity = 0;
    _pending = 0;
  }
}
