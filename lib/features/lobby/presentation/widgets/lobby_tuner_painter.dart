/// Pintor del sintonizador del inicio (`drawTuner` de `engine.js`) y lo que
/// recuerda entre cuadros.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/features/lobby/presentation/widgets/tuner_keyboard.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';

/// Lo que el sintonizador recuerda entre cuadros: la aguja, cuándo apareció
/// cada nota y el último instante pintado.
class TunerMotion {
  /// Aguja con resorte.
  final TunerNeedle needle = TunerNeedle();

  /// Semitono → segundo en que apareció su pico; nulo si nació crecido y
  /// `NaN` si apareció y aún no se pintó.
  final Map<int, double?> born = {};

  /// Último instante pintado; nulo antes del primer cuadro.
  double? lastSeconds;

  /// Sigue a las [notes] de ahora: olvida las que se fueron y anota las
  /// nuevas, ya crecidas si [grown] o por nacer en el próximo cuadro.
  void sync(List<RoomNote> notes, {required bool grown}) {
    final semitones = {for (final note in notes) note.semitone};
    born.removeWhere((semitone, _) => !semitones.contains(semitone));
    for (final semitone in semitones) {
      born.putIfAbsent(semitone, () => grown ? null : double.nan);
    }
  }
}

/// Colores y textos fijos del sintonizador: la etiqueta de cada semitono
/// («Mi4») y las del teclado («DO4», «DO5» y «SI5»).
typedef TunerLook = ({
  Color signal,
  Color signalFg,
  Color ink,
  double washK,
  List<String> noteLabels,
  String low,
  String middle,
  String high,
});

/// Port de `drawTuner`: teclas, etiquetas, piso de ruido, picos y aguja.
class LobbyTunerPainter extends CustomPainter {
  /// Crea el pintor; repinta con cada cambio de [seconds].
  LobbyTunerPainter({
    required this.seconds,
    required this.look,
    required this.motion,
    required this.notes,
    required this.selected,
    required this.reduceMotion,
  }) : super(repaint: seconds);

  static const double _inset = 16;
  static const double _keyHeight = 18;
  static const double _needleTop = 34;

  /// Tiempo del bucle en segundos.
  final ValueListenable<double> seconds;

  /// Colores y textos fijos.
  final TunerLook look;

  /// Estado entre cuadros: aguja y nacimiento de los picos.
  final TunerMotion motion;

  /// Notas con pico.
  final List<RoomNote> notes;

  /// Nota elegida: la aguja va a su tecla.
  final RoomNote? selected;

  /// Movimiento reducido: aguja en su destino y picos crecidos.
  final bool reduceMotion;

  final Map<String, TextPainter> _texts = {};

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    final w = size.width;
    final h = size.height;
    const x0 = _inset;
    final x1 = w - _inset;
    final keyWidth = (x1 - x0) / 14;
    final ky = h - _keyHeight - 22;
    final base = ky - 6;
    final selected = this.selected?.semitone;
    final lit = <int, double>{
      for (final note in notes)
        note.semitone: note.semitone == selected ? 1 : 0.5,
      if (selected != null) selected: 1,
    };

    _paintKeys(canvas, lit, ky, keyWidth);
    _paintKeyLabels(canvas, h, x1, keyWidth);
    _paintNoise(canvas, x1, base, t);
    for (final note in notes) {
      _paintPeak(canvas, note.semitone, h, base, keyWidth, t);
    }
    _paintNeedle(canvas, w, ky, x1, keyWidth, t);
  }

  void _paintKeys(Canvas canvas, Map<int, double> lit, double ky, double kw) {
    final fill = Paint();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 14; i++) {
      final x = _inset + i * kw;
      final level = lit[tunerWhiteClasses[i % 7] + 12 * (i ~/ 7)];
      fill.color = level != null
          ? look.signal.withValues(alpha: 0.1 + 0.25 * level)
          : look.ink.withValues(alpha: 0.03);
      stroke.color = level != null
          ? look.signalFg.withValues(alpha: 0.4 + 0.5 * level)
          : look.ink.withValues(alpha: 0.13);
      canvas
        ..drawRect(Rect.fromLTWH(x + 1, ky, kw - 2, _keyHeight), fill)
        ..drawRect(
          Rect.fromLTWH(x + 1.5, ky + 0.5, kw - 3, _keyHeight - 1),
          stroke,
        );
    }
    for (var octave = 0; octave < 2; octave++) {
      for (final pitchClass in tunerBlackClasses) {
        final semitone = octave * 12 + pitchClass;
        final level = lit[semitone];
        final x = tunerKeyX(semitone, left: _inset, keyWidth: kw);
        fill.color = level != null
            ? look.signal.withValues(alpha: 0.55 + 0.4 * level)
            : look.ink.withValues(alpha: 0.3);
        canvas.drawRect(
          Rect.fromLTWH(x - kw * 0.28, ky, kw * 0.56, _keyHeight * 0.58),
          fill,
        );
      }
    }
  }

  void _paintKeyLabels(Canvas canvas, double h, double x1, double kw) {
    final color = look.ink.withValues(alpha: 0.38);
    const weight = FontWeight.w500;
    _drawText(canvas, look.low, color, 8.5, weight, _inset, h - 7);
    _drawText(canvas, look.middle, color, 8.5, weight, _inset + 7 * kw, h - 7);
    _drawText(
      canvas,
      look.high,
      color,
      8.5,
      weight,
      x1,
      h - 7,
      align: TextAlign.right,
    );
  }

  void _paintNoise(Canvas canvas, double x1, double base, double t) {
    final path = Path();
    final damp = notes.isEmpty ? 1.0 : 0.7;
    for (var x = _inset; x <= x1; x += 2) {
      final n =
          frNoise2(x * 0.045, t * 0.9).abs() * 9 +
          frNoise2(x * 0.3, t * 2.4).abs() * 3;
      final y = base - 2 - n * damp;
      x == _inset ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = look.ink.withValues(alpha: 0.22),
    );
  }

  void _paintPeak(
    Canvas canvas,
    int semitone,
    double h,
    double base,
    double kw,
    double t,
  ) {
    final chosen = selected?.semitone == semitone;
    final amplitude =
        (h - 96) *
        _growthOf(semitone, t) *
        (chosen ? 1.06 : 0.8) *
        (0.93 + 0.07 * math.sin(t * 3 + semitone));
    final cx = tunerKeyX(semitone, left: _inset, keyWidth: kw);
    _fillPeak(
      canvas,
      _peakPath(cx, base, amplitude, t),
      base,
      amplitude,
      chosen,
    );
    _drawText(
      canvas,
      look.noteLabels[semitone],
      look.signalFg.withValues(alpha: chosen ? 1 : 0.8),
      9,
      FontWeight.w600,
      cx,
      base - amplitude - 8,
      align: TextAlign.center,
    );
  }

  /// Relleno con degradado, brillo y trazo del pico; el elegido, más vivo.
  void _fillPeak(
    Canvas canvas,
    Path path,
    double base,
    double amplitude,
    bool chosen,
  ) {
    final wash = math.min(1, (chosen ? 0.38 : 0.2) * look.washK).toDouble();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas
      ..drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, base - amplitude),
            Offset(0, base),
            [
              look.signal.withValues(alpha: wash),
              look.signal.withValues(alpha: 0),
            ],
          ),
      )
      ..drawPath(
        path,
        Paint.from(line)
          ..color = look.signal.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, chosen ? 7 : 4),
      )
      ..drawPath(
        path,
        line..color = look.signalFg.withValues(alpha: chosen ? 1 : 0.75),
      );
  }

  /// Cuánto creció el pico de [semitone] (0–1): nace con el resorte del
  /// prototipo la primera vez que se pinta; con movimiento reducido, crecido.
  double _growthOf(int semitone, double t) {
    var born = motion.born[semitone];
    if (born != null && born.isNaN) {
      born = motion.born[semitone] = t;
    }
    if (reduceMotion || born == null) return 1;
    final age = t - born;
    return (1 - math.exp(-age * 4) * math.cos(age * 9)).clamp(0.0, 1.0);
  }

  /// Campana gaussiana sobre [cx] con algo de ruido, cerrada en [base].
  Path _peakPath(double cx, double base, double amplitude, double t) {
    const sd = 7.0;
    final path = Path()..moveTo(cx - sd * 4, base);
    for (var x = cx - sd * 4; x <= cx + sd * 4; x += 1) {
      final bell = math.exp(-((x - cx) * (x - cx)) / (2 * sd * sd));
      path.lineTo(
        x,
        base - amplitude * bell - frNoise2(x * 0.2, t * 3).abs() * 2,
      );
    }
    return path
      ..lineTo(cx + sd * 4, base)
      ..close();
  }

  void _paintNeedle(
    Canvas canvas,
    double w,
    double ky,
    double x1,
    double kw,
    double t,
  ) {
    final span = x1 - _inset;
    final nx = _inset + _advanceNeedle(span, kw, t) * span;
    const top = _needleTop;
    if (selected == null) _paintTrail(canvas, nx, ky);
    final bar = Rect.fromLTWH(nx - 0.75, top, 1.5, ky - top + _keyHeight);
    final head = Path()
      ..moveTo(nx - 5, top - 6)
      ..lineTo(nx + 5, top - 6)
      ..lineTo(nx, top)
      ..close();
    final glow = Paint()
      ..color = look.signal.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final ink = Paint()..color = look.signalFg;
    canvas
      ..drawRect(bar, glow)
      ..drawRect(bar, ink)
      ..drawPath(head, ink);
    if (selected == null) _paintReading(canvas, w, nx, kw);
  }

  /// Lleva la aguja hacia la nota elegida o hacia el barrido y devuelve su
  /// posición; con movimiento reducido salta a su destino.
  double _advanceNeedle(double span, double kw, double t) {
    final selected = this.selected;
    final target = selected != null
        ? (tunerKeyX(selected.semitone, left: _inset, keyWidth: kw) - _inset) /
              span
        : tunerSweep(t);
    final needle = motion.needle;
    final last = motion.lastSeconds;
    if (reduceMotion) {
      needle.jumpTo(target);
    } else if (last != null && t > last) {
      needle.advance(target, t - last);
    }
    motion.lastSeconds = t;
    return needle.position;
  }

  /// Estela que deja la aguja al barrer.
  void _paintTrail(Canvas canvas, double nx, double ky) {
    const top = _needleTop;
    final dir = motion.needle.velocity < 0 ? -1.0 : 1.0;
    final glow = math.min(1, 0.08 * look.washK).toDouble();
    canvas.drawRect(
      Rect.fromLTWH(math.min(nx, nx - 60 * dir), top, 60, ky - top),
      Paint()
        ..shader = ui.Gradient.linear(Offset(nx - 60 * dir, 0), Offset(nx, 0), [
          look.signal.withValues(alpha: 0),
          look.signal.withValues(alpha: glow),
        ]),
    );
  }

  /// Lectura: la nota más cercana a la aguja, a su lado.
  void _paintReading(Canvas canvas, double w, double nx, double kw) {
    final nearest = tunerNearestSemitone(nx, left: _inset, keyWidth: kw);
    final right = nx > w - 60;
    _drawText(
      canvas,
      look.noteLabels[nearest],
      look.signalFg,
      9,
      FontWeight.w600,
      right ? nx - 9 : nx + 9,
      _needleTop + 4,
      align: right ? TextAlign.right : TextAlign.left,
    );
  }

  /// Escribe [text] en Martian Mono con su línea base en [baseline].
  void _drawText(
    Canvas canvas,
    String text,
    Color color,
    double size,
    FontWeight weight,
    double x,
    double baseline, {
    TextAlign align = TextAlign.left,
  }) {
    final painter = _texts.putIfAbsent(
      '$text|${color.toARGB32()}|$size|${weight.value}',
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: FrFonts.mono,
            fontSize: size,
            fontWeight: weight,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    final ascent = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final dx = switch (align) {
      TextAlign.right => x - painter.width,
      TextAlign.center => x - painter.width / 2,
      _ => x,
    };
    painter.paint(canvas, Offset(dx, baseline - ascent));
  }

  @override
  bool shouldRepaint(LobbyTunerPainter oldDelegate) =>
      oldDelegate.seconds != seconds ||
      oldDelegate.look != look ||
      !listEquals(oldDelegate.notes, notes) ||
      oldDelegate.selected != selected ||
      oldDelegate.reduceMotion != reduceMotion;
}
