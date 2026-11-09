import 'dart:async';
import 'dart:math' as math;

/// Umbral de voz en micrófono abierto, en dBFS sobre el `audioLevel` de
/// WebRTC (amplitud lineal de 0 a 1, ya con supresión de ruido y eco).
///
/// −36 dBFS (≈ 0,016) es un cuarto del VU (`voiceMeterLevel`): la voz a
/// distancia normal pica entre −25 y −10 dBFS y el ruido de fondo, tras la
/// supresión, suele quedar por debajo de −45. **Falta ajustarlo en teléfonos
/// reales**: súbelo (p. ej. −30) si el ruido enciende el indicador y bájalo
/// (p. ej. −42) si una voz baja no lo enciende.
const double openMicVoiceThresholdDb = -36;

/// Cuánto sigue «hablando» alguien después de su último nivel sobre el
/// umbral: cubre las pausas entre sílabas y palabras para que el indicador
/// no parpadee.
const Duration openMicVoiceHold = Duration(milliseconds: 400);

/// Decide si hay voz a partir del nivel: se enciende en cuanto un nivel
/// supera el umbral y se apaga cuando pasa [hold] sin ninguno que lo supere.
///
/// [onChanged] se llama solo cuando cambia, nunca al [reset].
class VoiceActivityDetector {
  /// Crea el detector con el umbral en dBFS y la retención.
  VoiceActivityDetector({
    required this.onChanged,
    double thresholdDb = openMicVoiceThresholdDb,
    this.hold = openMicVoiceHold,
  }) : threshold = math.pow(10, thresholdDb / 20).toDouble();

  /// Recibe cada cambio de [isActive].
  final void Function(bool active) onChanged;

  /// Umbral en amplitud lineal, de 0 a 1.
  final double threshold;

  /// Retención tras el último nivel sobre el umbral.
  final Duration hold;

  Timer? _holdTimer;
  double _level = 0;
  bool _active = false;

  /// Hay voz.
  bool get isActive => _active;

  /// Recibe un nivel nuevo, de 0 a 1.
  void add(double level) {
    _level = level;
    if (level < threshold) return;
    _holdTimer?.cancel();
    _holdTimer = Timer(hold, _release);
    if (_active) return;
    _active = true;
    onChanged(true);
  }

  /// Fin de la retención. Los niveles llegan solo cuando cambian: si el
  /// último sigue sobre el umbral (p. ej. una voz saturada en 1), la voz
  /// sigue.
  void _release() {
    if (_level >= threshold) {
      _holdTimer = Timer(hold, _release);
      return;
    }
    _holdTimer = null;
    _active = false;
    onChanged(false);
  }

  /// Vuelve al silencio sin avisar, p. ej. al cerrar el micrófono.
  void reset() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _level = 0;
    _active = false;
  }
}
