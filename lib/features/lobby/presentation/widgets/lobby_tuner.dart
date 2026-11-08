import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/features/lobby/presentation/widgets/lobby_tuner_painter.dart';
import 'package:frecu/features/lobby/presentation/widgets/room_note_label.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/i18n/strings.g.dart';

export 'package:frecu/features/lobby/presentation/widgets/tuner_keyboard.dart';

/// Sintonizador de dos octavas del inicio (`drawTuner` del prototipo): un
/// teclado de Do4 a Si5 con un pico sobre la tecla de la nota de cada frecu
/// cercana y una aguja con resorte que va a la nota elegida o barre el
/// teclado leyendo la nota más cercana.
///
/// Un único [FrLoop] lo anima; con movimiento reducido queda quieto: la
/// aguja en su destino y los picos ya crecidos.
class LobbyTuner extends StatefulWidget {
  /// Crea el sintonizador con las [notes] de las frecus cercanas.
  const LobbyTuner({
    required this.notes,
    required this.signalCount,
    this.selected,
    this.paused = false,
    super.key,
  });

  /// Notas de las frecus cercanas que la publican: un pico por cada una.
  final List<RoomNote> notes;

  /// Frecus cercanas, con nota o sin ella.
  final int signalCount;

  /// Nota de la frecu elegida: la aguja va a su tecla.
  final RoomNote? selected;

  /// Búsqueda en pausa (sin red local): atenuado.
  final bool paused;

  /// Alto de la caja.
  static const double height = 158;

  @override
  State<LobbyTuner> createState() => _LobbyTunerState();
}

class _LobbyTunerState extends State<LobbyTuner> {
  final TunerMotion _motion = TunerMotion();

  @override
  void initState() {
    super.initState();
    _motion.sync(widget.notes, grown: true);
  }

  @override
  void didUpdateWidget(LobbyTuner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _motion.sync(widget.notes, grown: false);
  }

  @override
  Widget build(BuildContext context) {
    final look = _lookOf(context.fr);
    final reduceMotion = context.reduceMotion;
    return Opacity(
      opacity: widget.paused ? 0.35 : 1,
      child: _TunerBox(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: FrLoop(
                builder: (context, seconds) => CustomPaint(
                  painter: LobbyTunerPainter(
                    seconds: seconds,
                    look: look,
                    motion: _motion,
                    notes: widget.notes,
                    selected: widget.selected,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: _TunerCaption(
              paused: widget.paused,
              signalCount: widget.signalCount,
            ),
          ),
        ],
      ),
    );
  }

  /// Colores del tema y textos del idioma para el pintor.
  TunerLook _lookOf(FrTheme fr) {
    final c = fr.colors;
    final names = t.lobby.noteNames;
    return (
      signal: c.signal,
      signalFg: c.signalFg,
      ink: c.ink,
      washK: c.washK,
      noteLabels: [
        for (var s = 0; s < RoomNote.semitoneCount; s++)
          RoomNote(semitone: s).label,
      ],
      low: '${names.first}4'.toUpperCase(),
      middle: '${names.first}5'.toUpperCase(),
      high: '${names.last}5'.toUpperCase(),
    );
  }
}

/// Caja de 158 px (`.tuner`): margen 0 20, radio 26, degradado `bg1`→`bg0`,
/// borde `line1` y filo `spec`.
class _TunerBox extends StatelessWidget {
  const _TunerBox({required this.children});

  final List<Widget> children;

  static const double _radius = 26;

  @override
  Widget build(BuildContext context) {
    final c = context.fr.colors;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: LobbyTuner.height,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.bg1, c.bg0],
            ),
            shape: shape.copyWith(side: BorderSide(color: c.line1)),
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: Stack(
              children: [
                ...children,
                // Filo especular arriba.
                Positioned(
                  top: 1,
                  left: _radius * 0.6,
                  right: _radius * 0.6,
                  height: 1,
                  child: ColoredBox(color: c.spec),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que hace la búsqueda y cuántas señales hay, en `labelS` y mayúsculas.
class _TunerCaption extends StatelessWidget {
  const _TunerCaption({required this.paused, required this.signalCount});

  final bool paused;
  final int signalCount;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final tuner = t.lobby.tuner;
    final caption = fr.type.labelS.copyWith(color: c.tx3);
    return Row(
      children: [
        Expanded(
          child: Text(
            (paused ? tuner.paused : tuner.scanning).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: caption,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          tuner.signals(n: signalCount).toUpperCase(),
          maxLines: 1,
          style: signalCount > 0
              ? caption.copyWith(color: c.signalFg)
              : caption,
        ),
      ],
    );
  }
}
