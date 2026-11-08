import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/features/room/presentation/widgets/ptt_core_painter.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Lado de la zona del núcleo (`.ptt`).
const double _zone = 248;

/// Lado del botón (`.ptt-core`).
const double _core = 156;

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
    this.speakerName,
    this.speakerColor,
    this.speakerSeed = 0,
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

  /// Nombre de quien habla.
  final String? speakerName;

  /// Color del lugar de quien habla.
  final Color? speakerColor;

  /// Semilla de la voz de quien habla.
  final int speakerSeed;

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

  void _down(PointerDownEvent event) {
    if (!widget.phase.isPush) return;
    final first = _pointers.isEmpty;
    setState(() => _pointers.add(event.pointer));
    if (!first) return;
    unawaited(HapticFeedback.lightImpact());
    widget.onStart();
  }

  void _up(PointerEvent event) {
    if (!_pointers.contains(event.pointer)) return;
    setState(() => _pointers.remove(event.pointer));
    if (_pressed) return;
    unawaited(HapticFeedback.lightImpact());
    widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final shown = _shown;
    final copy = _PttCopy.of(shown, widget.speakerName);
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

  Widget _face(PttPhase shown, _PttCopy copy) => _CoreFace(
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
      levelScale: shown == PttPhase.open ? 0.7 : 1,
      rxColor: shown == PttPhase.receiving ? widget.speakerColor : null,
      rxSeed: widget.speakerSeed,
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

/// Textos e ícono de una fase (`PTT_COPY` del prototipo).
@immutable
class _PttCopy {
  const _PttCopy(this.icon, this.label, this.hint);

  factory _PttCopy.of(PttPhase phase, String? speaker) {
    final core = t.room.talk.core;
    final hint = t.room.talk.hint;
    return switch (phase) {
      PttPhase.idle => _PttCopy(FrIcons.mic, core.hold, hint.idle),
      PttPhase.alone => _PttCopy(FrIcons.mic, core.hold, hint.alone),
      PttPhase.receiving => _PttCopy(
        FrIcons.mic,
        core.hold,
        hint.receiving(name: speaker ?? ''),
      ),
      PttPhase.onAir => _PttCopy(FrIcons.mic, core.onAir, hint.onAir),
      PttPhase.open => _PttCopy(FrIcons.openMic, core.open, hint.open),
      PttPhase.muted => _PttCopy(FrIcons.micOff, core.silence, hint.muted),
      PttPhase.connecting => _PttCopy(
        FrIcons.mic,
        core.standby,
        hint.connecting,
      ),
      PttPhase.reconnecting => _PttCopy(
        FrIcons.mic,
        core.standby,
        hint.reconnecting,
      ),
    };
  }

  final FrIconData icon;
  final String label;
  final String hint;
}

/// Botón de 156 px (`.ptt-core`): grafito en reposo y señal al aire.
class _CoreFace extends StatelessWidget {
  const _CoreFace({
    required this.phase,
    required this.pressed,
    required this.copy,
    required this.onAirFor,
    super.key,
  });

  final PttPhase phase;
  final bool pressed;
  final _PttCopy copy;
  final Duration onAirFor;

  bool get _lit => phase == PttPhase.onAir || phase == PttPhase.open;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final reduce = context.reduceMotion;
    const release = Duration(milliseconds: 520);
    return AnimatedScale(
      scale: pressed && !reduce ? 0.94 : 1,
      duration: pressed ? fr.motion.quick : release,
      curve: pressed
          ? fr.motion.easeOut
          : FrSpringCurve(fr.motion.springOrganic, release),
      child: AnimatedOpacity(
        opacity: phase.isWaiting ? 0.35 : 1,
        duration: fr.motion.quick,
        child: AnimatedContainer(
          width: _core,
          height: _core,
          duration: reduce
              ? fr.motion.quick
              : const Duration(milliseconds: 220),
          curve: fr.motion.easeOut,
          decoration: _decoration(fr),
          foregroundDecoration: _rim(fr),
          child: _content(fr),
        ),
      ),
    );
  }

  BoxDecoration _decoration(FrTheme fr) {
    final c = fr.colors;
    if (_lit) {
      return BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.82,
          colors: [c.signalHi, c.signal],
          stops: const [0, 0.62],
        ),
        border: Border.all(color: c.signal),
        boxShadow: [
          BoxShadow(
            color: c.signal.withValues(alpha: 0.75),
            blurRadius: 60,
            spreadRadius: -6,
          ),
        ],
      );
    }
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 0.86,
        colors: [c.coreHi, c.coreLo],
        stops: const [0, 0.7],
      ),
      border: Border.all(color: c.line2),
      boxShadow: [
        BoxShadow(
          color: c.shadow,
          offset: const Offset(0, 18),
          blurRadius: 40,
          spreadRadius: -12,
        ),
      ],
    );
  }

  /// Filo de luz arriba (`inset 0 1.5px 0 var(--spec)`).
  BoxDecoration _rim(FrTheme fr) {
    final light = _lit
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.7)
        : fr.colors.spec;
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, light.withValues(alpha: 0)],
        stops: const [0, 0.03],
      ),
    );
  }

  Widget _content(FrTheme fr) {
    final c = fr.colors;
    final ink = _lit ? c.signalInk : c.tx1;
    final timer = phase == PttPhase.onAir;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (timer)
          Text(
            formatOnAir(onAirFor),
            key: const Key('ptt_core_timer'),
            style: fr.type.digits.copyWith(
              fontSize: 26,
              height: 0.9,
              color: c.signalInk,
            ),
          )
        else
          FrIcon(
            copy.icon,
            size: 34,
            color: phase == PttPhase.muted ? c.tx3 : ink,
          ),
        const SizedBox(height: 8),
        Text(
          copy.label.toUpperCase(),
          key: const Key('ptt_core_label'),
          style: fr.type.label.copyWith(color: _lit ? c.signalInk : c.tx2),
        ),
      ],
    );
  }
}
