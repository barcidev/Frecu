import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/features/lobby/domain/entities/nearby_room.dart';
import 'package:frecu/features/lobby/presentation/extensions/nearby_room_extension.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Tarjeta de una frecu cercana (`UI.rtile` del prototipo): la caja de canal
/// con la chispa, los Hz y la nota; el nombre y la IP; y la flecha.
///
/// Elegida, se enciende con el aro y el brillo de la señal.
class NearbyRoomTile extends StatelessWidget {
  /// Crea la tarjeta de [room].
  const NearbyRoomTile({
    required this.room,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  /// Frecu cercana.
  final NearbyRoom room;

  /// Encendida: es la frecu elegida.
  final bool selected;

  /// Acción al tocarla.
  final VoidCallback? onPressed;

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    return FrPressable(
      onPressed: onPressed,
      pressedScale: 0.975,
      builder: (context, pressed, _) => _body(context.fr),
    );
  }

  Widget _body(FrTheme fr) {
    final c = fr.colors;
    return AnimatedContainer(
      duration: fr.motion.smooth,
      decoration: _decorationOf(c),
      child: Stack(
        children: [
          // Filo especular arriba.
          Positioned(
            top: 1,
            left: _radius * 0.6,
            right: _radius * 0.6,
            height: 1,
            child: ColoredBox(color: c.spec),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: _ChannelBox(note: room.note, selected: selected),
                ),
                const SizedBox(width: 14),
                Expanded(child: _RoomInfo(room: room)),
                const SizedBox(width: 14),
                _GoBox(selected: selected),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// `bg1` con borde `line1`; elegida, con el aro y el brillo de la señal.
  ShapeDecoration _decorationOf(FrColors c) {
    final ring = c.ledRing;
    final side = !selected
        ? BorderSide(color: c.line1)
        : ring != null
        ? BorderSide(color: ring, width: 1.25)
        : BorderSide(color: c.signal.withValues(alpha: 0.5));
    return ShapeDecoration(
      color: c.bg1,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: side,
      ),
      shadows: [
        if (selected)
          BoxShadow(
            color: c.signal.withValues(alpha: 0.6),
            blurRadius: 34,
            spreadRadius: -14,
          ),
      ],
    );
  }
}

/// Caja de canal de 60 px: la chispa, los Hz arriba y la nota abajo; sin
/// nota, solo «—».
class _ChannelBox extends StatelessWidget {
  const _ChannelBox({required this.note, required this.selected});

  final RoomNote? note;
  final bool selected;

  static const double _radius = 15;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final note = this.note;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    return SizedBox(
      height: 60,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: c.bg0,
          shape: shape.copyWith(side: BorderSide(color: c.line1)),
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (note != null) ..._spark(note, fr),
              Positioned(
                left: 8,
                bottom: 6,
                child: note != null
                    ? RoomNoteText(note: note)
                    : Text(
                        t.lobby.noNote,
                        style: fr.type.digits.copyWith(
                          fontSize: 24,
                          height: 0.9,
                          color: c.tx3,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// La chispa de la nota y sus Hz arriba.
  List<Widget> _spark(RoomNote note, FrTheme fr) => [
    RepaintBoundary(
      child: FrLoop(
        builder: (context, seconds) => CustomPaint(
          painter: _SparkPainter(
            seconds: seconds,
            semitone: note.semitone,
            on: selected,
            color: fr.colors.signalFg,
          ),
        ),
      ),
    ),
    Positioned(
      top: 7,
      left: 8,
      right: 4,
      child: Text(
        note.hzText.toUpperCase(),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: fr.type.labelS.copyWith(color: fr.colors.tx3),
      ),
    ),
  ];
}

/// Nombre de la frecu y su IP tras el candado.
class _RoomInfo extends StatelessWidget {
  const _RoomInfo({required this.room});

  final NearbyRoom room;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final address = fr.type.labelS.copyWith(color: c.tx3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          room.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: FrFonts.ui,
            fontSize: 16.5,
            height: 1.15,
            fontWeight: const FontWeight(620),
            fontVariations: const [
              FontVariation.weight(620),
              FontVariation.width(106),
            ],
            color: c.tx1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            FrIcon(FrIcons.lock, size: 16, color: c.tx3),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                room.hostAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: address,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Caja de 40 × 40 con la flecha; elegida, en señal.
class _GoBox extends StatelessWidget {
  const _GoBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    return AnimatedContainer(
      duration: fr.motion.smooth,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: selected ? c.signal : c.bg2,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(13),
          side: selected ? BorderSide.none : BorderSide(color: c.line1),
        ),
      ),
      child: FrIcon(
        FrIcons.arrow,
        size: 18,
        color: selected ? c.signalInk : c.tx2,
      ),
    );
  }
}

/// Chispa de la caja de canal (`drawSpark` del prototipo): una campana sobre
/// la posición de la nota en las dos octavas, con algo de ruido.
class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.seconds,
    required this.semitone,
    required this.on,
    required this.color,
  }) : super(repaint: seconds);

  final ValueListenable<double> seconds;
  final int semitone;
  final bool on;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = seconds.value;
    final w = size.width;
    final h = size.height;
    final cx = w * (0.2 + 0.7 * semitone / (RoomNote.semitoneCount - 1));
    final base = h * 0.5;
    final path = Path();
    for (var x = 0.0; x <= w; x += 1.5) {
      final y =
          base -
          math.exp(-((x - cx) * (x - cx)) / 30) *
              (h * 0.34) *
              (0.9 + 0.1 * math.sin(t * 3)) -
          frNoise2(x * 0.2, t * 1.5).abs() * 2;
      x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = color.withValues(alpha: on ? 0.9 : 0.3),
    );
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) =>
      oldDelegate.seconds != seconds ||
      oldDelegate.semitone != semitone ||
      oldDelegate.on != on ||
      oldDelegate.color != color;
}
