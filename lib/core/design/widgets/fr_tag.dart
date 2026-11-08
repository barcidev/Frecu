import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';

/// Tono de una [FrTag].
enum FrTagTone {
  /// `bg3` con texto `tx2`.
  neutral,

  /// Lavado de señal (más intenso de día) con texto `signalFg`.
  signal,

  /// Lavado de aviso con texto ámbar (`warnFg`: de día, el tono de texto que
  /// llega a 4,5:1).
  warn,
}

/// Etiqueta de Portadora: texto en mayúsculas en una caja de 20 px
/// (anfitrión, `3/3`, `v1`).
class FrTag extends StatelessWidget {
  /// Crea una etiqueta con [label].
  const FrTag({required this.label, this.tone = FrTagTone.neutral, super.key});

  /// Texto; se muestra en mayúsculas.
  final String label;

  /// Tono del relleno y del texto.
  final FrTagTone tone;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final c = fr.colors;
    final (fill, ink) = switch (tone) {
      FrTagTone.neutral => (c.bg3, c.tx2),
      FrTagTone.signal => (
        c.signal.withValues(alpha: 0.12 * c.washK),
        c.signalFg,
      ),
      FrTagTone.warn => (c.warn.withValues(alpha: 0.12), c.warnFg),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(fr.radii.xs),
      ),
      child: SizedBox(
        height: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: fr.type.labelS.copyWith(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
