import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core_face.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core_painter.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Lado de la zona del núcleo (`.ptt`).
const double _zone = 248;

/// Núcleo PTT de la frecu activa (`pttZone` y `drawPtt` del prototipo): el
/// botón circular sobre el bisel de 72 marcas, que es un VU circular, el
/// anillo líquido y las ondas, con la pista debajo.
///
/// En las fases de presión el primer dedo llama [onStart] y el último en
/// salir [onStop]; mientras hay un dedo apoyado se ve al aire. Con micrófono
/// abierto un toque llama [onToggle]. En espera no responde. Si la fase deja
/// de ser de presión con un dedo apoyado, llama [onStop].
class PttCore extends StatefulWidget {
  /// Crea el núcleo en la fase [phase].
  const PttCore({
    required this.phase,
    required this.onStart,
    required this.onStop,
    required this.onToggle,
    this.onAirFor = Duration.zero,
    this.level = 0,
    this.speakerName,
    this.speakerColor,
    this.speakerLevel = 0,
    this.idleHint,
    super.key,
  });

  /// Lo que muestra el núcleo.
  final PttPhase phase;

  /// Empieza a transmitir.
  final VoidCallback onStart;

  /// Deja de transmitir.
  final VoidCallback onStop;

  /// Abre o calla el micrófono abierto.
  final VoidCallback onToggle;

  /// Tiempo al aire.
  final Duration onAirFor;

  /// Nivel real de la voz propia, de 0 a 1.
  final double level;

  /// Nombre de quien habla.
  final String? speakerName;

  /// Color del lugar de quien habla.
  final Color? speakerColor;

  /// Nivel real de la voz de quien habla, de 0 a 1.
  final double speakerLevel;

  /// Pista en reposo en lugar de «Mantén para hablar», si la hay.
  final String? idleHint;

  @override
  State<PttCore> createState() => _PttCoreState();
}

class _PttCoreState extends State<PttCore> {
  static const ValueListenable<double> _still = AlwaysStoppedAnimation<double>(
    0,
  );

  final Set<int> _pointers = {};
  final PttMotion _motion = PttMotion();
  final GlobalKey _faceKey = GlobalKey();

  bool get _pressed => _pointers.isNotEmpty;

  PttPhase get _shown =>
      _pressed && widget.phase.isPush ? PttPhase.onAir : widget.phase;

  @override
  void didUpdateWidget(PttCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pressed && !widget.phase.isPush) {
      _pointers.clear();
      widget.onStop();
    }
  }

  @override
  void dispose() {
    // Si el núcleo se va con el dedo apoyado (p. ej. al cerrarse la frecu),
    // deja de transmitir: el `onPointerUp` ya no va a llegar.
    if (_pressed) {
      _pointers.clear();
      widget.onStop();
    }
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    if (!widget.phase.isPush) return;
    final first = _pointers.isEmpty;
    setState(() => _pointers.add(event.pointer));
    if (!first) return;
    // La vibración la da la pantalla de la frecu al empezar a transmitir.
    widget.onStart();
  }

  void _up(PointerEvent event) {
    if (!_pointers.contains(event.pointer)) return;
    setState(() => _pointers.remove(event.pointer));
    if (_pressed) return;
    widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final shown = _shown;
    final copy = PttCopy.of(
      shown,
      widget.speakerName,
      idleHint: widget.idleHint,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: _zone,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: RepaintBoundary(child: _bezel(shown))),
              Semantics(
                button: true,
                enabled: !shown.isWaiting,
                label: t.room.talk.core.talk,
                value: copy.label,
                onTap: shown.isToggle ? widget.onToggle : null,
                excludeSemantics: true,
                child: _interaction(_face(shown, copy)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          copy.hint.toUpperCase(),
          key: const Key('ptt_core_hint'),
          textAlign: TextAlign.center,
          style: fr.type.labelS.copyWith(color: fr.colors.tx3),
        ),
      ],
    );
  }

  Widget _interaction(Widget face) {
    final phase = widget.phase;
    if (phase.isToggle) {
      return GestureDetector(
        key: const Key('mic_toggle_button'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggle,
        child: face,
      );
    }
    if (phase.isWaiting) {
      return IgnorePointer(key: const Key('ptt_waiting'), child: face);
    }
    return Listener(
      key: const Key('ptt_button'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: face,
    );
  }

  Widget _face(PttPhase shown, PttCopy copy) => PttCoreFace(
    key: _faceKey,
    phase: shown,
    pressed: _pressed,
    copy: copy,
    onAirFor: widget.onAirFor,
  );

  Widget _bezel(PttPhase shown) {
    final reduced = context.reduceMotion;
    final look = PttLook(
      onAir: shown == PttPhase.onAir || shown == PttPhase.open,
      waiting: shown.isWaiting,
      level: widget.level,
      levelScale: shown == PttPhase.open ? 0.7 : 1,
      rxColor: shown == PttPhase.receiving ? widget.speakerColor : null,
      rxLevel: widget.speakerLevel,
    );
    final colors = context.fr.colors;
    final dayK = Theme.of(context).brightness == Brightness.light ? 2.2 : 1.0;
    CustomPaint paint(ValueListenable<double> seconds) => CustomPaint(
      painter: PttCorePainter(
        look: look,
        motion: _motion,
        seconds: seconds,
        colors: colors,
        dayK: dayK,
        reduced: reduced,
      ),
    );
    if (reduced) return paint(_still);
    return FrLoop(builder: (context, seconds) => paint(seconds));
  }
}
