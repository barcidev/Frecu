import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/signal_signature.dart';

/// Toast de Portadora: píldora de 46 px con una firma o un ícono y un texto
/// corto. Se muestra con [showFrToast].
class FrToast extends StatelessWidget {
  /// Toast con [leading] libre.
  const FrToast({required this.message, this.title, this.leading, super.key})
    : icon = null,
      signatureName = null,
      signatureColor = null;

  /// Toast con [icon] en un círculo de señal.
  const FrToast.icon({
    required IconData this.icon,
    required this.message,
    this.title,
    super.key,
  }) : leading = null,
       signatureName = null,
       signatureColor = null;

  /// Toast con la firma de [name] hablando, en [color].
  const FrToast.signature({
    required String name,
    required Color color,
    required this.message,
    this.title,
    super.key,
  }) : leading = null,
       icon = null,
       signatureName = name,
       signatureColor = color;

  /// Texto.
  final String message;

  /// Texto en negrita antes de [message] (p. ej. un nombre).
  final String? title;

  /// Elemento a la izquierda.
  final Widget? leading;

  /// Ícono a la izquierda, en un círculo de señal.
  final IconData? icon;

  /// Nombre de la firma a la izquierda.
  final String? signatureName;

  /// Color de la firma.
  final Color? signatureColor;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final lead = _leading(fr);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: c.bg3,
        shape: StadiumBorder(side: BorderSide(color: c.line2)),
        shadows: [
          BoxShadow(
            color: c.shadow,
            offset: const Offset(0, 18),
            blurRadius: 40,
            spreadRadius: -16,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Filo especular arriba.
          Positioned(
            top: 1,
            left: 23,
            right: 23,
            height: 1,
            child: ColoredBox(color: c.spec),
          ),
          SizedBox(
            height: 46,
            child: Padding(
              padding: EdgeInsets.fromLTRB(lead == null ? 16 : 8, 0, 16, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lead != null) ...[lead, const SizedBox(width: 10)],
                  _text(fr),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _text(FrTheme fr) {
    final title = this.title;
    return Text.rich(
      TextSpan(
        children: [
          if (title != null) ...[
            TextSpan(
              text: title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontVariations: [FontVariation.weight(600)],
              ),
            ),
            const TextSpan(text: ' '),
          ],
          TextSpan(text: message),
        ],
      ),
      style: fr.type.body.copyWith(
        fontSize: 14,
        height: 1,
        color: fr.colors.tx1,
        fontWeight: FontWeight.w500,
        fontVariations: const [
          FontVariation.weight(500),
          FontVariation.width(100),
        ],
      ),
    );
  }

  Widget? _leading(FrTheme fr) {
    final name = signatureName;
    final icon = this.icon;
    if (name != null) {
      return SignalSignature(
        name: name,
        size: 30,
        color: signatureColor,
        mode: SignatureMode.speak,
        levelOf: frVoice,
      );
    }
    if (icon != null) {
      return SizedBox.square(
        dimension: 30,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fr.colors.signal.withValues(alpha: 0.14),
          ),
          child: Icon(icon, size: 16, color: fr.colors.signalFg),
        ),
      );
    }
    return leading;
  }
}

/// Muestra [toast] abajo al centro, sobre todo lo demás, durante [duration].
///
/// Entra subiendo 18 px desde escala 0,98 con el resorte `flow` en 600 ms y
/// sale fundido en 240 ms; con movimiento reducido solo se funde. Un toast
/// nuevo reemplaza al anterior.
void showFrToast(
  BuildContext context,
  FrToast toast, {
  Duration duration = const Duration(milliseconds: 2600),
  double bottom = 112,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _FrToastSlot.current?.close();
  late final _FrToastSlot slot;
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 16,
      right: 16,
      bottom: bottom + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: Center(
          child: _ToastPresenter(
            duration: duration,
            onDone: () => slot.close(),
            child: toast,
          ),
        ),
      ),
    ),
  );
  slot = _FrToastSlot(entry);
  _FrToastSlot.current = slot;
  overlay.insert(entry);
}

class _FrToastSlot {
  _FrToastSlot(this.entry);

  static _FrToastSlot? current;

  final OverlayEntry entry;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    if (identical(current, this)) current = null;
    entry
      ..remove()
      ..dispose();
  }
}

const Duration _riseDuration = Duration(milliseconds: 600);

class _ToastPresenter extends StatefulWidget {
  const _ToastPresenter({
    required this.duration,
    required this.onDone,
    required this.child,
  });

  final Duration duration;
  final VoidCallback onDone;
  final Widget child;

  @override
  State<_ToastPresenter> createState() => _ToastPresenterState();
}

class _ToastPresenterState extends State<_ToastPresenter>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );
  late final AnimationController _exit =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 240),
        animationBehavior: AnimationBehavior.preserve,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      });
  Timer? _timer;
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = context.reduceMotion;
    if (_timer != null) return;
    _enter
      ..duration = _reduce ? context.fr.motion.quick : _riseDuration
      ..forward();
    _timer = Timer(widget.duration, _exit.forward);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.fr.motion;
    final rise = FrSpringCurve(motion.springFlow, _riseDuration);
    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _exit]),
      child: widget.child,
      builder: (context, child) {
        final t = _enter.value;
        final opacity = _reduce
            ? t
            : const Interval(0, 0.5, curve: Curves.easeOut).transform(t);
        final position = _reduce ? 1.0 : rise.transform(t);
        return Opacity(
          opacity: opacity * (1 - _exit.value),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - position)),
            child: Transform.scale(scale: 0.98 + 0.02 * position, child: child),
          ),
        );
      },
    );
  }
}
