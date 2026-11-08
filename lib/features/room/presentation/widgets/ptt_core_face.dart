import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icon_data.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/features/room/presentation/widgets/room_talk.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Lado del botón (`.ptt-core`).
const double _core = 156;

/// Textos e ícono de una fase (`PTT_COPY` del prototipo).
@immutable
class PttCopy {
  /// Crea los textos con su [icon].
  const PttCopy(this.icon, this.label, this.hint);

  /// Textos de [phase]; la pista nombra a [speaker] al recibir.
  factory PttCopy.of(PttPhase phase, String? speaker) {
    final core = t.room.talk.core;
    final hint = t.room.talk.hint;
    return switch (phase) {
      PttPhase.idle => PttCopy(FrIcons.mic, core.hold, hint.idle),
      PttPhase.alone => PttCopy(FrIcons.mic, core.hold, hint.alone),
      PttPhase.receiving => PttCopy(
        FrIcons.mic,
        core.hold,
        hint.receiving(name: speaker ?? ''),
      ),
      PttPhase.onAir => PttCopy(FrIcons.mic, core.onAir, hint.onAir),
      PttPhase.open => PttCopy(FrIcons.openMic, core.open, hint.open),
      PttPhase.muted => PttCopy(FrIcons.micOff, core.silence, hint.muted),
      PttPhase.connecting => PttCopy(
        FrIcons.mic,
        core.standby,
        hint.connecting,
      ),
      PttPhase.reconnecting => PttCopy(
        FrIcons.mic,
        core.standby,
        hint.reconnecting,
      ),
    };
  }

  /// Ícono del botón.
  final FrIconData icon;

  /// Etiqueta del botón.
  final String label;

  /// Pista bajo el núcleo.
  final String hint;
}

/// Botón de 156 px (`.ptt-core`): grafito en reposo y señal al aire.
class PttCoreFace extends StatelessWidget {
  /// Crea el botón en la fase [phase].
  const PttCoreFace({
    required this.phase,
    required this.pressed,
    required this.copy,
    required this.onAirFor,
    super.key,
  });

  /// Fase que muestra.
  final PttPhase phase;

  /// Hay un dedo apoyado.
  final bool pressed;

  /// Textos e ícono de la fase.
  final PttCopy copy;

  /// Tiempo al aire.
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
