import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_icon_button.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Cabecera de la frecu activa (`.room-h` del prototipo): el chip con la
/// nota y sus Hz, el nombre de la frecu con su anfitrión y los botones de
/// ruta de audio, invitar y salir.
class RoomHeader extends StatelessWidget {
  /// Crea la cabecera de [room].
  const RoomHeader({
    required this.room,
    required this.participants,
    required this.localParticipantId,
    required this.audioRoute,
    required this.onCycleAudioRoute,
    required this.onInvite,
    required this.onLeave,
    super.key,
  });

  /// Frecu activa; nula mientras no hay una.
  final Room? room;

  /// Participantes, para saber quién es el anfitrión.
  final List<Participant> participants;

  /// Id de la persona de este teléfono.
  final String? localParticipantId;

  /// Ruta de audio activa.
  final AudioRoute audioRoute;

  /// Pasa a la siguiente ruta de audio.
  final VoidCallback onCycleAudioRoute;

  /// Abre la invitación QR; nulo si no hay frecu.
  final VoidCallback? onInvite;

  /// Sale de la frecu.
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final note = room?.note;
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          children: [
            if (note != null) ...[
              RoomNoteChip(note: note),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _RoomTitle(
                name: room?.name ?? t.room.title,
                hostLine: _hostLine(),
              ),
            ),
            const SizedBox(width: 8),
            _buttons(),
          ],
        ),
      ),
    );
  }

  String _hostLine() {
    final me = participants.where((p) => p.id == localParticipantId);
    if (me.isNotEmpty && me.first.isHost) return t.room.header.youAreHost;
    final host = participants.where((p) => p.isHost);
    if (host.isEmpty) return '';
    return t.room.header.hostedBy(name: host.first.displayName);
  }

  Widget _buttons() {
    final (routeIcon, routeLabel) = switch (audioRoute) {
      AudioRoute.bluetooth => (Icons.bluetooth_audio, t.room.bluetooth),
      AudioRoute.earpiece => (Icons.phone_in_talk, t.room.earpiece),
      AudioRoute.speaker => (Icons.volume_up, t.room.speaker),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        FrIconButton(
          key: const Key('audio_route_button'),
          icon: routeIcon,
          semanticLabel: routeLabel,
          onPressed: onCycleAudioRoute,
        ),
        FrIconButton(
          icon: Icons.qr_code,
          semanticLabel: t.room.header.invite,
          onPressed: onInvite,
        ),
        FrIconButton.drawn(
          key: const Key('leave_button'),
          icon: FrIcons.exit,
          semanticLabel: t.room.leave,
          variant: FrIconButtonVariant.danger,
          onPressed: onLeave,
        ),
      ],
    );
  }
}

/// Nombre de la frecu y, debajo, quién es el anfitrión.
class _RoomTitle extends StatelessWidget {
  const _RoomTitle({required this.name, required this.hostLine});

  final String name;
  final String hostLine;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: fr.type.title.copyWith(
            fontSize: 16.5,
            height: 1.15,
            fontWeight: const FontWeight(660),
            fontVariations: const [
              FontVariation.weight(660),
              FontVariation.width(104),
            ],
            color: fr.colors.tx1,
          ),
        ),
        if (hostLine.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            hostLine.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: fr.type.labelS.copyWith(color: fr.colors.tx3),
          ),
        ],
      ],
    );
  }
}

/// Chip de la nota de la frecu (`.room-h .chip`): sus Hz arriba y la nota
/// en Doto con la alteración arriba y la octava abajo.
class RoomNoteChip extends StatelessWidget {
  /// Crea el chip de [note].
  const RoomNoteChip({required this.note, super.key});

  /// Nota de la frecu.
  final RoomNote note;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final name = t.room.noteNames[note.pitchClass];
    final hz = '${note.hz.round()}';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: t.room.header.note(note: '$name${note.octave}', hz: hz),
      child: Container(
        key: const Key('room_note_chip'),
        width: 64,
        height: 50,
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        decoration: BoxDecoration(
          color: fr.colors.bg0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fr.colors.line2),
        ),
        // Filo de luz arriba (`inset 0 1px 0 var(--spec)`).
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fr.colors.spec, fr.colors.spec.withValues(alpha: 0)],
            stops: const [0, 0.06],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 1,
              left: 0,
              child: Text(
                t.room.header.hz(value: hz).toUpperCase(),
                style: fr.type.labelS.copyWith(color: fr.colors.tx3),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: _NoteName(name: name, octave: note.octave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nombre de una nota con la alteración en superíndice y la octava en
/// subíndice (`.note` del prototipo).
class _NoteName extends StatelessWidget {
  const _NoteName({required this.name, required this.octave});

  static final RegExp _accidental = RegExp('[♯♭]');

  final String name;
  final int octave;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final accidental = _accidental.firstMatch(name)?.group(0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          name.replaceAll(_accidental, ''),
          style: fr.type.digits.copyWith(
            fontSize: 22,
            height: 0.9,
            letterSpacing: 0.44,
            color: fr.colors.tx1,
          ),
        ),
        if (accidental != null)
          Padding(
            padding: const EdgeInsets.only(left: 1, bottom: 10),
            child: Text(
              accidental,
              style: fr.type.label.copyWith(
                fontWeight: FontWeight.w600,
                fontVariations: const [FontVariation.weight(600)],
                letterSpacing: 0,
                height: 1,
                color: fr.colors.tx1,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 1),
          child: Text(
            '$octave',
            style: fr.type.labelS.copyWith(
              fontSize: 8,
              height: 1,
              color: fr.colors.tx3,
            ),
          ),
        ),
      ],
    );
  }
}
