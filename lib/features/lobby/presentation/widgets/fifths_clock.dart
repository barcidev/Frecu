/// Reloj del círculo de quintas de la nueva frecu (`drawFifths` de
/// `engine.js`): la aguja de la hora señala la nota de la frecu.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/i18n/strings.g.dart';

const double _tau = 2 * math.pi;

/// Ángulo en radianes de la [position] del reloj (0 = 12 h, 1 = 1 h … y
/// fracciones), en sentido horario desde las 12.
double fifthsAngle(double position) => -math.pi / 2 + position * _tau / 12;

/// Ángulo de la aguja de la hora a las [hour]:[minute].
double fifthsHourAngle(int hour, int minute) =>
    fifthsAngle(hour % 12 + minute / 60);

/// Ángulo de la aguja de los minutos en el minuto [minute].
double fifthsMinuteAngle(int minute) => -math.pi / 2 + minute / 60 * _tau;

/// Nombres de las 12 notas en el orden del reloj (12 h → Do, 1 h → Sol …
/// 11 h → Fa), tomados de [noteNames] por clase de altura.
List<String> fifthsLabels(List<String> noteNames) => [
  for (final pitchClass in RoomNote.circleOfFifths) noteNames[pitchClass],
];

/// Hora en dos cifras («16:24»).
String fifthsClockTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Colores del reloj.
typedef FifthsClockLook = ({
  Color signal,
  Color signalFg,
  Color ink,
  double washK,
});

/// Reloj del círculo de quintas: las 12 notas cada 30°, las marcas de los
/// minutos, la estrella {12/5}, las agujas a las [hour]:[minute] y encendida
/// la posición de la nota [note]. No anima.
class FifthsClock extends StatelessWidget {
  /// Crea el reloj de [size] px de lado.
  const FifthsClock({
    required this.hour,
    required this.minute,
    required this.note,
    this.size = 184,
    super.key,
  });

  /// Hora (0–23).
  final int hour;

  /// Minuto (0–59).
  final int minute;

  /// Nota de la frecu: se enciende su posición.
  final RoomNote note;

  /// Lado en px.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    return Semantics(
      label: t.lobby.newRoom.clockLabel(
        time: fifthsClockTime(hour, minute),
        note: note.label,
      ),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: FifthsClockPainter(
            hour: hour,
            minute: minute,
            position: note.fifthsPosition,
            labels: fifthsLabels(t.lobby.noteNames),
            look: (
              signal: c.signal,
              signalFg: c.signalFg,
              ink: c.ink,
              washK: c.washK,
            ),
          ),
        ),
      ),
    );
  }
}

/// Port de `drawFifths` sin pie: sector, estrella, marcas, notas y agujas.
class FifthsClockPainter extends CustomPainter {
  /// Crea el pintor.
  const FifthsClockPainter({
    required this.hour,
    required this.minute,
    required this.position,
    required this.labels,
    required this.look,
  });

  /// Hora (0–23).
  final int hour;

  /// Minuto (0–59).
  final int minute;

  /// Posición encendida del reloj (0–11).
  final int position;

  /// Nombres de las notas en el orden del reloj.
  final List<String> labels;

  /// Colores.
  final FifthsClockLook look;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = math.min(size.width, size.height) * 0.36;
    _paintSector(canvas, center, r);
    _paintStar(canvas, center, r);
    _paintTicks(canvas, center, r);
    _paintLabels(canvas, center, r);
    _paintHands(canvas, center, r);
  }

  static Offset _at(Offset center, double angle, double radius) =>
      center + Offset(math.cos(angle), math.sin(angle)) * radius;

  void _paintSector(Canvas canvas, Offset center, double r) {
    final a0 = fifthsAngle(position.toDouble());
    final wash = math.min(1, 0.14 * look.washK).toDouble();
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: r),
        a0 - _tau / 24,
        _tau / 12,
        false,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          r,
          [
            look.signal.withValues(alpha: 0),
            look.signal.withValues(alpha: wash),
          ],
          const [0.2, 1],
        ),
    );
  }

  /// La escala cromática trazada sobre las quintas: la estrella {12/5}.
  void _paintStar(Canvas canvas, Offset center, double r) {
    final path = Path();
    for (var i = 0; i <= 12; i++) {
      final point = _at(center, fifthsAngle((i * 5 % 12).toDouble()), r * .8);
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = look.ink.withValues(alpha: 0.07),
    );
  }

  void _paintTicks(Canvas canvas, Offset center, double r) {
    final paint = Paint();
    for (var i = 0; i < 60; i++) {
      final angle = fifthsMinuteAngle(i);
      final major = i % 5 == 0;
      paint
        ..color = look.ink.withValues(alpha: major ? 0.32 : 0.12)
        ..strokeWidth = major ? 1.4 : 1;
      canvas.drawLine(
        _at(center, angle, r * (major ? 0.88 : 0.94)),
        _at(center, angle, r),
        paint,
      );
    }
  }

  void _paintLabels(Canvas canvas, Offset center, double r) {
    final fontSize = math.max(9, (r * 0.17).roundToDouble()).toDouble();
    for (var i = 0; i < 12; i++) {
      final on = i == position;
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontFamily: FrFonts.mono,
            fontSize: fontSize,
            height: 1,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            fontVariations: [FontVariation.weight(on ? 700 : 500)],
            color: on ? look.signalFg : look.ink.withValues(alpha: 0.42),
            shadows: on ? [Shadow(color: look.signal, blurRadius: 12)] : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = _at(center, fifthsAngle(i.toDouble()), r * 1.22);
      painter
        ..paint(canvas, at - Offset(painter.width / 2, painter.height / 2))
        ..dispose();
    }
  }

  void _paintHands(Canvas canvas, Offset center, double r) {
    final minuteTip = _at(center, fifthsMinuteAngle(minute), r * 0.82);
    final hourTip = _at(center, fifthsHourAngle(hour, minute), r * 0.6);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        center,
        minuteTip,
        line
          ..color = look.ink.withValues(alpha: 0.5)
          ..strokeWidth = 1.3,
      )
      ..drawLine(
        center,
        hourTip,
        Paint()
          ..color = look.signal
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawLine(
        center,
        hourTip,
        line
          ..color = look.signalFg
          ..strokeWidth = 2.6,
      )
      ..drawCircle(center, 3.5, Paint()..color = look.signalFg);
  }

  @override
  bool shouldRepaint(FifthsClockPainter oldDelegate) =>
      oldDelegate.hour != hour ||
      oldDelegate.minute != minute ||
      oldDelegate.position != position ||
      !listEquals(oldDelegate.labels, labels) ||
      oldDelegate.look != look;
}
