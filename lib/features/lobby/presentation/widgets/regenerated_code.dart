import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_spring_curve.dart';
import 'package:frecu/core/design/motion/reduced_motion.dart';
import 'package:frecu/core/design/widgets/fr_pin_field.dart';

/// Código de acceso generado, en celdas de solo lectura ([FrPinField]).
///
/// Cuando cambia («Generar otro»), sus celdas aparecen escalonadas cada
/// 60 ms con el `pop` del prototipo: de 0,7 y casi transparentes a su tamaño
/// con el resorte `organic` en 460 ms. En reposo es un solo [FrPinField];
/// durante el pop, una celda por dígito con la misma medida. Con movimiento
/// reducido el código cambia sin animar.
class RegeneratedCode extends StatefulWidget {
  /// Muestra [code].
  const RegeneratedCode({required this.code, this.semanticLabel, super.key});

  /// Dígitos del código.
  final String code;

  /// Etiqueta accesible del código.
  final String? semanticLabel;

  /// Pop de cada celda.
  static const Duration pop = Duration(milliseconds: 460);

  /// Escalonado entre celdas.
  static const Duration stagger = Duration(milliseconds: 60);

  /// Separación entre celdas de [FrPinField].
  static const double gap = 10;

  @override
  State<RegeneratedCode> createState() => _RegeneratedCodeState();
}

class _RegeneratedCodeState extends State<RegeneratedCode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(RegeneratedCode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code == widget.code || context.reduceMotion) return;
    final cells = math.max(1, widget.code.length);
    _pop
      ..duration = RegeneratedCode.pop + RegeneratedCode.stagger * (cells - 1)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pop,
    builder: (context, _) {
      if (!_pop.isAnimating) {
        return FrPinField(
          value: widget.code,
          readOnly: true,
          semanticLabel: widget.semanticLabel,
        );
      }
      final code = widget.code;
      return Semantics(
        container: true,
        label: widget.semanticLabel,
        value: '${code.length}/${code.length}',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < code.length; i++) ...[
                if (i > 0) const SizedBox(width: RegeneratedCode.gap),
                _cell(context.fr, i),
              ],
            ],
          ),
        ),
      );
    },
  );

  /// La celda [index] en su momento del pop; antes de su turno, pequeña y
  /// casi transparente.
  Widget _cell(FrTheme fr, int index) {
    final total = _pop.duration!.inMicroseconds;
    final start = RegeneratedCode.stagger.inMicroseconds * index / total;
    final end = math.min(1, start + RegeneratedCode.pop.inMicroseconds / total);
    final shown = Interval(
      start,
      end.toDouble(),
      curve: FrSpringCurve(fr.motion.springOrganic, RegeneratedCode.pop),
    ).transform(_pop.value);
    return Opacity(
      opacity: (0.2 + 0.8 * shown).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.7 + 0.3 * shown,
        child: FrPinField(value: widget.code[index], length: 1, readOnly: true),
      ),
    );
  }
}
