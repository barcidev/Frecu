import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_button.dart';
import 'package:frecu/core/design/widgets/fr_scaffold.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/presentation/widgets/invite_sheet.dart';
import 'package:frecu/features/room/presentation/widgets/room_header.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Cómo terminó la frecu para esta persona.
enum RoomClosureKind {
  /// La persona propia, anfitriona, cerró la frecu.
  hostClosed,

  /// El anfitrión cerró la frecu.
  closedByHost,

  /// Se perdió la señal del anfitrión.
  lostHost,

  /// Se perdió la red que creaba el teléfono del anfitrión y no volvió.
  lostHostNetwork,
}

/// Resumen de una frecu que salió del aire.
@immutable
class RoomClosure {
  /// Crea el resumen.
  const RoomClosure({
    required this.kind,
    required this.duration,
    required this.people,
    this.note,
  });

  /// Cómo terminó.
  final RoomClosureKind kind;

  /// Tiempo desde que la persona entró a la frecu hasta el cierre.
  final Duration duration;

  /// Mayor número de personas que hubo a la vez.
  final int people;

  /// Nota de la frecu; nula si no tenía.
  final RoomNote? note;
}

/// Duración del cierre: «mm:ss», o «h:mm:ss» desde una hora.
String formatClosureDuration(Duration duration) {
  String two(int value) => value.toString().padLeft(2, '0');
  final seconds = two(duration.inSeconds % 60);
  final minutes = duration.inMinutes;
  if (minutes < 60) return '${two(minutes)}:$seconds';
  return '${duration.inHours}:${two(minutes % 60)}:$seconds';
}

/// Pantalla «Fin de la transmisión» (`V.closed` del prototipo): la firma de
/// Frecu se aplana en una línea, el motivo del cierre, la duración, las
/// personas y la nota, y «Volver al inicio».
class RoomClosedView extends StatelessWidget {
  /// Crea la pantalla de [closure]; [onHome] vuelve al inicio.
  const RoomClosedView({
    required this.closure,
    required this.onHome,
    super.key,
  });

  /// Resumen del cierre.
  final RoomClosure closure;

  /// Vuelve al inicio.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return FrScaffold(
      dock: FrButton(
        key: const Key('closure_home'),
        label: t.room.closure.home,
        expand: true,
        onPressed: onHome,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 40, bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 300, child: ClosureLine()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ClosureCopy(closure: closure),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ClosureStats(closure: closure),
            ),
          ],
        ),
      ),
    );
  }
}

/// Motivo del cierre, centrado: nota fuera del aire, título y mensaje.
class _ClosureCopy extends StatelessWidget {
  const _ClosureCopy({required this.closure});

  final RoomClosure closure;

  String get _kicker {
    final note = closure.note;
    if (note == null) return t.room.closure.offAir;
    final name = t.room.noteNames[note.pitchClass];
    return t.room.closure.noteOffAir(note: '$name${note.octave}');
  }

  String get _message => switch (closure.kind) {
    RoomClosureKind.hostClosed => t.room.closure.host,
    RoomClosureKind.closedByHost => t.room.closure.peer,
    RoomClosureKind.lostHost => t.room.closure.lost,
    RoomClosureKind.lostHostNetwork => t.room.closure.lostNetwork,
  };

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return Column(
      spacing: 12,
      children: [
        Text(
          _kicker.toUpperCase(),
          textAlign: TextAlign.center,
          style: fr.type.label.copyWith(color: c.tx3),
        ),
        Text(
          t.room.closure.title,
          textAlign: TextAlign.center,
          style: fr.type.display.copyWith(
            color: c.tx1,
            fontSize: 30,
            height: 1.06,
            letterSpacing: -0.6,
            fontWeight: const FontWeight(720),
            fontVariations: const [
              FontVariation.weight(720),
              FontVariation.width(122),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: fr.type.body.copyWith(
              color: c.tx2,
              fontSize: 15.5,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

/// Estadísticas del cierre (`.stats`): duración, personas y nota.
class _ClosureStats extends StatelessWidget {
  const _ClosureStats({required this.closure});

  final RoomClosure closure;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final copy = t.room.closure;
    final note = closure.note;
    final big = fr.type.digits.copyWith(
      fontSize: 24,
      height: 0.9,
      color: fr.colors.tx1,
    );
    return RoomFacts(
      facts: [
        RoomFact(
          label: copy.duration,
          values: [
            Text(
              formatClosureDuration(closure.duration),
              key: const Key('closure_duration'),
              style: big,
            ),
          ],
        ),
        RoomFact(
          label: copy.people,
          values: [
            Text(
              closure.people.toString().padLeft(2, '0'),
              key: const Key('closure_people'),
              style: big,
            ),
          ],
        ),
        RoomFact(
          label: copy.note,
          values: [
            if (note == null)
              Text(t.lobby.noNote, style: big)
            else
              RoomNoteName(note: note, size: 24),
          ],
        ),
      ],
    );
  }
}

/// Línea del cierre (`drawFlat`): la firma de Frecu se aplana y la recorre
/// un pulso; plana y quieta con movimiento reducido.
class ClosureLine extends StatelessWidget {
  /// Crea la línea.
  const ClosureLine({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final still = context.reduceMotion;
    return RepaintBoundary(
      child: FrLoop(
        builder: (context, seconds) => CustomPaint(
          size: Size.infinite,
          painter: ClosureLinePainter(
            seconds: seconds,
            still: still,
            line: c.tx2.withValues(alpha: 0.7),
            ticks: c.ink.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}

/// Pinta la firma que se aplana en ciclos de 6 s: en 2,4 s queda plana y
/// desde los 3 s la recorre un pulso.
class ClosureLinePainter extends CustomPainter {
  /// Crea el pintor con el tiempo del bucle.
  ClosureLinePainter({
    required this.seconds,
    required this.still,
    required this.line,
    required this.ticks,
  }) : super(repaint: seconds);

  /// Tiempo del bucle en segundos.
  final ValueListenable<double> seconds;

  /// Movimiento reducido: la línea plana, sin pulso.
  final bool still;

  /// Color del trazo.
  final Color line;

  /// Color de las marcas de abajo.
  final Color ticks;

  static const int _steps = 220;
  static final SignatureParams _frecu = SignatureParams.fromName('frecu');

  /// Curva `easeInOut` de cuarto grado del prototipo.
  static double _ease(double t) {
    final x = t.clamp(0.0, 1.0);
    final eased = x < 0.5
        ? 8 * math.pow(x, 4)
        : 1 - math.pow(-2 * x + 2, 4) / 2;
    return eased.toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = still ? 2.4 : seconds.value % 6;
    final k = 1 - _ease(p / 2.4);
    final center = size.center(Offset.zero);
    final path = Path();
    for (var i = 0; i <= _steps; i++) {
      final f = i / _steps;
      final u = f * math.pi * 2;
      final lx = math.sin(_frecu.a * u + _frecu.phase) * 80;
      final ly = math.sin(_frecu.b * u) * 80;
      final fx = (f - 0.5) * (size.width - 60);
      final d = f - (p - 3) / 3;
      final blip = p > 3
          ? math.exp(-d * d / 0.0008) * 10 * math.sin(i * 0.9)
          : 0;
      final x = center.dx + fx + (lx - fx) * k;
      final y = center.dy + blip + (ly - blip) * k;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = line,
    );
    final tick = Paint()..color = ticks;
    for (var x = 30.0; x < size.width - 20; x += 22) {
      canvas.drawRect(Rect.fromLTWH(x, center.dy + 70, 1, 6), tick);
    }
  }

  @override
  bool shouldRepaint(ClosureLinePainter old) =>
      old.still != still || old.line != line || old.ticks != ticks;
}
