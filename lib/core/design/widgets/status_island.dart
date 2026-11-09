import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';
import 'package:frecu/core/design/widgets/wave_loader.dart';

/// Tono de la [StatusIsland].
enum StatusIslandTone {
  /// Cápsula negra con borde tenue.
  neutral,

  /// Al aire: relleno de señal.
  onAir,

  /// Aviso: borde y halo ámbar.
  warn,

  /// Alarma (SOS): relleno rojo con texto claro.
  alert,
}

enum _IslandKind {
  custom,
  online,
  onAir,
  receiving,
  reconnecting,
  connecting,
  event,
}

/// Isla de estado de la frecu: cápsula de 36 px, siempre oscura (también en
/// tema claro), que cambia de ancho con el resorte `organic`.
///
/// El contenido nuevo entra fundido y subiendo 6 px; dentro del mismo estado
/// (p. ej. el contador de "al aire") el texto cambia sin volver a entrar. El
/// texto se anuncia a la accesibilidad. Con movimiento reducido el ancho
/// cambia sin resorte y el punto no parpadea.
class StatusIsland extends StatelessWidget {
  /// Isla con [label], [tone] y [leading] libres.
  const StatusIsland({
    required this.label,
    this.tone = StatusIslandTone.neutral,
    this.leading,
    this.labelColor,
    super.key,
  }) : _kind = _IslandKind.custom,
       _name = null;

  /// En línea (o micrófono abierto): punto de señal.
  const StatusIsland.online({required this.label, super.key})
    : tone = StatusIslandTone.neutral,
      leading = null,
      labelColor = null,
      _kind = _IslandKind.online,
      _name = null;

  /// Al aire: relleno de señal y punto que parpadea cada 0,8 s.
  const StatusIsland.onAir({required this.label, super.key})
    : tone = StatusIslandTone.onAir,
      leading = null,
      labelColor = null,
      _kind = _IslandKind.onAir,
      _name = null;

  /// Recibiendo: la firma de `name` hablando y el texto en su `color`.
  const StatusIsland.receiving({
    required String this._name,
    required Color color,
    required this.label,
    super.key,
  }) : tone = StatusIslandTone.neutral,
       leading = null,
       labelColor = color,
       _kind = _IslandKind.receiving;

  /// Reconectando: ámbar con punto que parpadea cada segundo.
  const StatusIsland.reconnecting({required this.label, super.key})
    : tone = StatusIslandTone.warn,
      leading = null,
      labelColor = null,
      _kind = _IslandKind.reconnecting,
      _name = null;

  /// Conectando: loader de onda.
  const StatusIsland.connecting({required this.label, super.key})
    : tone = StatusIslandTone.neutral,
      leading = null,
      labelColor = null,
      _kind = _IslandKind.connecting,
      _name = null;

  /// Evento pasajero (se unió, salió, ruta de audio), con [leading] opcional.
  const StatusIsland.event({required this.label, this.leading, super.key})
    : tone = StatusIslandTone.neutral,
      labelColor = null,
      _kind = _IslandKind.event,
      _name = null;

  /// Texto; se muestra en mayúsculas y se anuncia tal cual.
  final String label;

  /// Tono de la cápsula.
  final StatusIslandTone tone;

  /// Elemento antes del texto.
  final Widget? leading;

  /// Color del texto; por defecto, el del tono.
  final Color? labelColor;

  final _IslandKind _kind;
  final String? _name;

  /// Siempre la paleta de noche: la isla es una cápsula negra.
  static const FrColors _c = FrColors.dark;

  String get _identity => switch (_kind) {
    _IslandKind.receiving => 'receiving:$_name',
    _IslandKind.event || _IslandKind.custom => '$_kind:$tone:$label',
    _ => '$_kind',
  };

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final reduce = context.reduceMotion;
    const organic = Duration(milliseconds: 640);
    final content = _content(fr, reduce);
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: fr.motion.smooth,
          curve: fr.motion.easeOut,
          height: 36,
          constraints: const BoxConstraints(minWidth: 36),
          padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
          clipBehavior: Clip.antiAlias,
          decoration: _decoration(),
          // Con movimiento reducido el ancho cambia de golpe.
          child: reduce
              ? content
              : AnimatedSize(
                  duration: organic,
                  curve: FrSpringCurve(fr.motion.springOrganic, organic),
                  alignment: Alignment.centerLeft,
                  child: content,
                ),
        ),
      ),
    );
  }

  /// Contenido del estado; uno nuevo entra con su animación.
  Widget _content(FrTheme fr, bool reduce) {
    final lead = _leading();
    return KeyedSubtree(
      key: ValueKey<String>(_identity),
      child: _IslandEntry(
        reduce: reduce,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 9)],
            Text(
              label.toUpperCase(),
              maxLines: 1,
              softWrap: false,
              style: fr.type.label.copyWith(color: _labelColor),
            ),
          ],
        ),
      ),
    );
  }

  Color get _labelColor =>
      labelColor ??
      switch (tone) {
        StatusIslandTone.neutral => _c.tx1,
        StatusIslandTone.onAir => _c.signalInk,
        StatusIslandTone.warn => _c.warn,
        StatusIslandTone.alert => const Color(0xFFFFFFFF),
      };

  BoxDecoration _decoration() => switch (tone) {
    StatusIslandTone.neutral => BoxDecoration(
      color: _c.shadow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _c.line2),
      boxShadow: [
        BoxShadow(
          color: _c.shadow,
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -10,
        ),
      ],
    ),
    StatusIslandTone.onAir => BoxDecoration(
      color: _c.signal,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _c.signal),
      boxShadow: [
        BoxShadow(
          color: _c.signal.withValues(alpha: 0.8),
          blurRadius: 30,
          spreadRadius: -6,
        ),
      ],
    ),
    StatusIslandTone.warn => BoxDecoration(
      color: _c.shadow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _c.warn.withValues(alpha: 0.45)),
      boxShadow: [
        BoxShadow(
          color: _c.warn.withValues(alpha: 0.6),
          blurRadius: 26,
          spreadRadius: -8,
        ),
      ],
    ),
    StatusIslandTone.alert => BoxDecoration(
      color: _c.alert,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _c.alert),
      boxShadow: [
        BoxShadow(
          color: _c.alert.withValues(alpha: 0.85),
          blurRadius: 30,
          spreadRadius: -6,
        ),
      ],
    ),
  };

  Widget? _leading() => switch (_kind) {
    _IslandKind.online => _IslandDot(color: _c.signalFg, glow: _c.signal),
    _IslandKind.onAir => _IslandDot(color: _c.signalInk, period: 0.8),
    _IslandKind.reconnecting => _IslandDot(
      color: _c.warn,
      glow: _c.warn,
      period: 1,
    ),
    _IslandKind.receiving => SignalSignature(
      name: _name ?? '',
      size: 24,
      color: labelColor,
      mode: SignatureMode.speak,
      levelOf: frVoice,
    ),
    _IslandKind.connecting => const WaveLoader(width: 34, height: 16),
    _IslandKind.event => leading,
    _IslandKind.custom =>
      leading ??
          switch (tone) {
            StatusIslandTone.onAir => _IslandDot(color: _c.signalInk),
            StatusIslandTone.alert => const _IslandDot(
              color: Color(0xFFFFFFFF),
              period: 0.6,
            ),
            _ => _IslandDot(color: _c.signalFg),
          },
  };
}

/// Punto de 7 px con halo; parpadea a pasos cada [period] segundos.
class _IslandDot extends StatelessWidget {
  const _IslandDot({required this.color, this.glow, this.period});

  final Color color;
  final Color? glow;
  final double? period;

  @override
  Widget build(BuildContext context) {
    final glow = this.glow;
    final dot = SizedBox.square(
      dimension: 7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            if (glow != null)
              BoxShadow(color: glow.withValues(alpha: 0.8), blurRadius: 10),
          ],
        ),
      ),
    );
    final period = this.period;
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 4),
      child: period == null
          ? dot
          : FrLoop(
              builder: (context, seconds) => ValueListenableBuilder<double>(
                valueListenable: seconds,
                child: dot,
                builder: (context, t, dot) => Opacity(
                  opacity: t % period < period / 2 ? 1 : 0.25,
                  child: dot,
                ),
              ),
            ),
    );
  }
}

/// Entrada del contenido nuevo: fundido y 6 px hacia arriba en 420 ms; con
/// movimiento reducido, solo un fundido rápido.
class _IslandEntry extends StatefulWidget {
  const _IslandEntry({required this.reduce, required this.child});

  final bool reduce;
  final Widget child;

  @override
  State<_IslandEntry> createState() => _IslandEntryState();
}

class _IslandEntryState extends State<_IslandEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.reduce
        ? const Duration(milliseconds: 160)
        : const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final easeOut = context.fr.motion.easeOut;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = easeOut.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.reduce ? 0 : 6 * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
