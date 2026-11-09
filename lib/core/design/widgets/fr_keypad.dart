import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/icons/fr_icon.dart';
import 'package:frecu/core/design/icons/fr_icons.dart';
import 'package:frecu/core/design/widgets/fr_pressable.dart';
import 'package:frecu/core/design/widgets/fr_specular.dart';

/// Teclado numérico propio de Portadora, de teclas grandes (aptas con
/// guantes), para escribir el código de un `FrPinField`.
///
/// Tres columnas: 1–9, la tecla de función opcional ([leading]), 0 y borrar.
/// Cada tecla se hunde a 0,93 con el resorte `press` y pasa a `bg3`; con
/// movimiento reducido no se hunde, pero responde.
class FrKeypad extends StatelessWidget {
  /// Crea un teclado que entrega cada dígito a [onDigit].
  const FrKeypad({
    required this.onDigit,
    required this.onDelete,
    required this.deleteLabel,
    this.deleteIcon,
    this.leading,
    this.leadingLabel,
    this.onLeading,
    super.key,
  });

  /// Llamado con el dígito de la tecla tocada (0–9).
  final ValueChanged<int> onDigit;

  /// Llamado al tocar borrar.
  final VoidCallback onDelete;

  /// Etiqueta accesible de borrar.
  final String deleteLabel;

  /// Ícono de borrar; por defecto, `FrIcons.backspace`.
  final Widget? deleteIcon;

  /// Contenido de la tecla de función, a la izquierda del 0; sin él, el hueco
  /// queda vacío.
  final Widget? leading;

  /// Etiqueta accesible de la tecla de función.
  final String? leadingLabel;

  /// Acción de la tecla de función.
  final VoidCallback? onLeading;

  static const double _gap = 8;

  static const List<List<int>> _digits = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ];

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _digits) ...[
          _row([for (final d in row) _digit(d)]),
          const SizedBox(height: _gap),
        ],
        _row([
          if (leading != null)
            _FrKey(
              id: 'fn',
              function: true,
              semanticLabel: leadingLabel,
              onPressed: onLeading,
              child: leading,
            )
          else
            const SizedBox(height: _FrKey.height),
          _digit(0),
          _FrKey(
            id: 'del',
            function: true,
            semanticLabel: deleteLabel,
            onPressed: onDelete,
            child: deleteIcon ?? const FrIcon(FrIcons.backspace),
          ),
        ]),
      ],
    );
  }

  Widget _digit(int digit) => _FrKey(
    id: '$digit',
    onPressed: () => onDigit(digit),
    child: Text('$digit'),
  );

  static Widget _row(List<Widget> keys) => Row(
    children: [
      for (final (i, key) in keys.indexed) ...[
        if (i > 0) const SizedBox(width: _gap),
        Expanded(child: key),
      ],
    ],
  );
}

class _FrKey extends StatelessWidget {
  const _FrKey({
    required this.id,
    required this.onPressed,
    required this.child,
    this.function = false,
    this.semanticLabel,
  });

  static const double height = 56;

  final String id;
  final VoidCallback? onPressed;
  final Widget child;
  final bool function;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return FrPressable(
      onPressed: onPressed,
      pressedScale: 0.93,
      semanticLabel: semanticLabel,
      builder: (context, pressed, _) => _body(context.fr, pressed),
    );
  }

  Widget _body(FrTheme fr, bool pressed) {
    final c = fr.colors;
    final ink = function ? c.tx2 : c.tx1;
    final background = function
        ? c.bg1.withValues(alpha: 0)
        : pressed
        ? c.bg3
        : c.bg1;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(fr.radii.m),
      side: function ? BorderSide.none : BorderSide(color: c.line1),
    );
    // Filo especular en las teclas de dígito (`.keys button`).
    return CustomPaint(
      foregroundPainter: function
          ? null
          : FrSpecularPainter(shape: shape, color: c.spec),
      child: AnimatedContainer(
        key: ValueKey('fr-key-$id'),
        duration: fr.motion.instant,
        height: height,
        alignment: Alignment.center,
        decoration: ShapeDecoration(color: background, shape: shape),
        child: _content(fr, ink),
      ),
    );
  }

  Widget _content(FrTheme fr, Color ink) {
    return IconTheme.merge(
      data: IconThemeData(color: ink, size: 22),
      child: DefaultTextStyle.merge(
        style: fr.type.button.copyWith(
          fontSize: 24,
          height: 1,
          letterSpacing: 0,
          fontWeight: const FontWeight(560),
          fontVariations: const [
            FontVariation.weight(560),
            FontVariation.width(115),
          ],
          color: ink,
        ),
        child: child,
      ),
    );
  }
}
