import 'package:flutter/widgets.dart';
import 'package:frecu/core/design/fr_theme.dart';

/// Texto de señal de Portadora (`.cs` del prototipo): de noche, en lima; de
/// día, en tinta (`signalFg`) sobre el marcatexto verde (`signalMark`).
///
/// El marcatexto es el subrayado grueso del prototipo (`--mark-deco:
/// underline #C4E05C .5em` con `text-underline-offset: -.3em`): una franja de
/// [thickness] em que empieza [rise] em sobre la línea base de cada renglón,
/// detrás de las letras y a lo ancho del texto. Sirve para lo que se destaca
/// con la señal, como «2 señales» del inicio, «Frecu encontrada» del escáner
/// o «Código correcto».
class FrMarkText extends StatelessWidget {
  /// Crea el texto [text] con [style] (sobre el estilo por defecto); el
  /// color siempre es `signalFg`.
  const FrMarkText(
    this.text, {
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    super.key,
  });

  /// Texto.
  final String text;

  /// Estilo; su color se ignora.
  final TextStyle? style;

  /// Alineación.
  final TextAlign? textAlign;

  /// Renglones máximos.
  final int? maxLines;

  /// Qué hacer si no cabe.
  final TextOverflow? overflow;

  /// Grosor del marcatexto, en em.
  static const double thickness = 0.5;

  /// Altura del marcatexto sobre la línea base, en em.
  static const double rise = 0.3;

  @override
  Widget build(BuildContext context) {
    final colors = context.fr.colors;
    final defaults = DefaultTextStyle.of(context);
    final effective = defaults.style
        .merge(style)
        .copyWith(color: colors.signalFg);
    final align = textAlign ?? defaults.textAlign ?? TextAlign.start;
    final lines = maxLines ?? defaults.maxLines;
    final label = Text(
      text,
      style: effective,
      textAlign: align,
      maxLines: lines,
      overflow: overflow,
    );
    final mark = colors.signalMark;
    if (mark == null) return label;
    return CustomPaint(
      painter: _MarkPainter(
        text: text,
        style: effective,
        textAlign: align,
        maxLines: lines,
        ellipsis: overflow == TextOverflow.ellipsis ? '…' : null,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        textHeightBehavior: defaults.textHeightBehavior,
        color: mark,
      ),
      child: label,
    );
  }
}

/// Franja del marcatexto bajo cada renglón, con el mismo trazado del texto.
class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.maxLines,
    required this.ellipsis,
    required this.textDirection,
    required this.textScaler,
    required this.textHeightBehavior,
    required this.color,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int? maxLines;
  final String? ellipsis;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final TextHeightBehavior? textHeightBehavior;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
      ellipsis: ellipsis,
      textHeightBehavior: textHeightBehavior,
    )..layout(minWidth: _alignsToStart ? 0 : size.width, maxWidth: size.width);
    final em = textScaler.scale(style.fontSize ?? 14);
    final paint = Paint()..color = color;
    for (final line in painter.computeLineMetrics()) {
      if (line.width <= 0) continue;
      canvas.drawRect(
        Rect.fromLTWH(
          line.left,
          line.baseline - FrMarkText.rise * em,
          line.width,
          FrMarkText.thickness * em,
        ),
        paint,
      );
    }
    painter.dispose();
  }

  /// Con alineación al inicio, el texto se traza como el párrafo, sin ancho
  /// mínimo; con otra, ocupa el ancho del párrafo para alinearse igual.
  bool get _alignsToStart => switch (textAlign) {
    TextAlign.start || TextAlign.justify => true,
    TextAlign.left => textDirection == TextDirection.ltr,
    TextAlign.right => textDirection == TextDirection.rtl,
    TextAlign.center || TextAlign.end => false,
  };

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.textAlign != textAlign ||
      oldDelegate.maxLines != maxLines ||
      oldDelegate.ellipsis != ellipsis ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.textHeightBehavior != textHeightBehavior ||
      oldDelegate.color != color;
}
