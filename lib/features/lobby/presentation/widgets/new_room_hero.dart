import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/features/lobby/presentation/widgets/fifths_clock.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_reach.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Héroe de la nueva frecu (`.ch-hero.fifths`): el reloj de quintas y, a su
/// lado, la nota, sus Hz y la hora de apertura.
class NewRoomHero extends StatelessWidget {
  /// Crea el héroe con la [note] de la frecu abierta en [openedAt].
  const NewRoomHero({
    required this.note,
    required this.openedAt,
    required this.reach,
    super.key,
  });

  /// Nota que tendrá la frecu.
  final RoomNote note;

  /// Hora de apertura.
  final DateTime openedAt;

  /// Tipo de frecu: su etiqueta va bajo la hora.
  final RoomReach reach;

  @override
  Widget build(BuildContext context) {
    return _HeroBox(
      children: [
        Positioned(
          left: 2,
          top: 6,
          child: FifthsClock(
            hour: openedAt.hour,
            minute: openedAt.minute,
            note: note,
          ),
        ),
        Positioned(
          left: 190,
          top: 24,
          right: 20,
          bottom: 12,
          child: Align(
            alignment: Alignment.topRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topRight,
              child: _NoteReading(note: note, openedAt: openedAt, reach: reach),
            ),
          ),
        ),
      ],
    );
  }
}

/// Caja del héroe: 196 px con margen 4 20 0, radio 28, `bg1` con el lavado
/// radial de señal desde abajo, borde `line1` y filo `spec`.
class _HeroBox extends StatelessWidget {
  const _HeroBox({required this.children});

  final List<Widget> children;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    final wash = math.min(1, 0.12 * c.washK).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: SizedBox(
        height: 196,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.bg1,
            shape: shape.copyWith(side: BorderSide(color: c.line1)),
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 1.4),
                        radius: 1.2,
                        colors: [
                          c.signal.withValues(alpha: wash),
                          c.signal.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.6],
                      ),
                    ),
                  ),
                ),
                // Filo especular arriba.
                Positioned(
                  top: 1,
                  left: _radius * 0.6,
                  right: _radius * 0.6,
                  height: 1,
                  child: ColoredBox(color: c.spec),
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Tu frecu suena en», la nota grande, sus Hz, «Abierta a las HH:MM» y,
/// debajo, el tipo de frecu.
class _NoteReading extends StatelessWidget {
  const _NoteReading({
    required this.note,
    required this.openedAt,
    required this.reach,
  });

  final RoomNote note;
  final DateTime openedAt;
  final RoomReach reach;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final newRoom = t.lobby.newRoom;
    final time = fifthsClockTime(openedAt.hour, openedAt.minute);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          newRoom.soundsIn.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx3),
        ),
        const SizedBox(height: 8),
        RoomNoteText(note: note, size: 64, octaveSize: 15, glow: true),
        const SizedBox(height: 8),
        Text(
          note.hzText.toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx2),
        ),
        const SizedBox(height: 8),
        Text(
          newRoom.openedAt(time: time).toUpperCase(),
          style: fr.type.labelS.copyWith(color: c.tx3),
        ),
        const SizedBox(height: 8),
        _ReachTag(reach: reach),
      ],
    );
  }
}

/// Etiqueta del tipo de frecu: `hotspot` y «Local», o `globe` y «Por
/// internet».
class _ReachTag extends StatelessWidget {
  const _ReachTag({required this.reach});

  final RoomReach reach;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final copy = t.lobby.newRoom.reach;
    final (icon, label) = switch (reach) {
      RoomReach.local => (FrIcons.hotspot, copy.local),
      RoomReach.internet => (FrIcons.globe, copy.internet),
    };
    return Row(
      key: const Key('new_room_reach_tag'),
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        FrIcon(icon, size: 12, color: c.signalFg),
        Text(label.toUpperCase(), style: fr.type.labelS.copyWith(color: c.tx2)),
      ],
    );
  }
}
