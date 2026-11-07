import 'package:flutter/material.dart';

/// Familias tipográficas de Portadora, todas con licencia OFL.
abstract final class FrFonts {
  /// Interfaz y titulares: Archivo, variable de ancho y peso.
  static const String ui = 'Archivo';

  /// Datos y etiquetas: Martian Mono.
  static const String mono = 'Martian Mono';

  /// Numerales de señal en matriz de puntos: Doto.
  static const String dot = 'Doto';
}

/// Escala tipográfica de Portadora.
///
/// Cada estilo declara el peso exacto (que mueve el eje `wght`) y los ejes
/// variables (`wdth` y, en Doto, `ROND`). Los estilos no llevan color: lo pone
/// el tema. Las etiquetas van en mayúsculas, pero `TextStyle` no transforma el
/// texto: lo hace el widget que las dibuja.
class FrType extends ThemeExtension<FrType> {
  /// Crea una escala completa.
  const FrType({
    required this.display,
    required this.titleL,
    required this.title,
    required this.bodyL,
    required this.body,
    required this.bodyS,
    required this.label,
    required this.labelS,
    required this.data,
    required this.digits,
    required this.button,
  });

  FrType._fromValues(List<TextStyle> v)
    : this(
        display: v[0],
        titleL: v[1],
        title: v[2],
        bodyL: v[3],
        body: v[4],
        bodyS: v[5],
        label: v[6],
        labelS: v[7],
        data: v[8],
        digits: v[9],
        button: v[10],
      );

  /// Escala del prototipo (`.t-*` en `base.css`, `.btn` en `ui.css`).
  static const FrType standard = FrType(
    display: TextStyle(
      fontFamily: FrFonts.ui,
      fontSize: 34,
      height: 38 / 34,
      fontWeight: FontWeight(720),
      letterSpacing: -0.51,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(720), FontVariation.width(125)],
    ),
    titleL: TextStyle(
      fontFamily: FrFonts.ui,
      fontSize: 24,
      height: 28 / 24,
      fontWeight: FontWeight(650),
      letterSpacing: -0.24,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(650), FontVariation.width(118)],
    ),
    title: TextStyle(
      fontFamily: FrFonts.ui,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight(620),
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(620), FontVariation.width(110)],
    ),
    bodyL: TextStyle(
      fontFamily: FrFonts.ui,
      fontSize: 17,
      height: 25 / 17,
      fontWeight: FontWeight.w400,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(400), FontVariation.width(100)],
    ),
    body: TextStyle(
      fontFamily: FrFonts.ui,
      fontSize: 15,
      height: 22 / 15,
      fontWeight: FontWeight.w400,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(400), FontVariation.width(100)],
    ),
    bodyS: TextStyle(
      fontFamily: FrFonts.ui,
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(400), FontVariation.width(100)],
    ),
    label: TextStyle(
      fontFamily: FrFonts.mono,
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.88,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(500), FontVariation.width(87.5)],
    ),
    labelS: TextStyle(
      fontFamily: FrFonts.mono,
      fontSize: 9.5,
      height: 12 / 9.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.95,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(500), FontVariation.width(87.5)],
    ),
    data: TextStyle(
      fontFamily: FrFonts.mono,
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(400), FontVariation.width(87.5)],
    ),
    digits: TextStyle(
      fontFamily: FrFonts.dot,
      fontSize: 32,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.64,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(800), FontVariation('ROND', 100)],
    ),
    button: TextStyle(
      fontFamily: FrFonts.ui,
      fontSize: 16,
      height: 1,
      fontWeight: FontWeight(640),
      letterSpacing: -0.08,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: [FontVariation.weight(640), FontVariation.width(112)],
    ),
  );

  /// Titular expandido: 34/38, Archivo 720, ancho 125.
  final TextStyle display;

  /// Titular de pantalla: 24/28, Archivo 650, ancho 118.
  final TextStyle titleL;

  /// Título de sección: 18/24, Archivo 620, ancho 110.
  final TextStyle title;

  /// Lectura destacada: 17/25, Archivo 400.
  final TextStyle bodyL;

  /// Lectura: 15/22, Archivo 400.
  final TextStyle body;

  /// Lectura pequeña: 13/18, Archivo 400.
  final TextStyle bodyS;

  /// Etiqueta en mayúsculas: 11/14, Martian Mono 500, ancho 87,5, +8 %.
  final TextStyle label;

  /// Etiqueta pequeña en mayúsculas: 9,5/12, Martian Mono 500, +10 %.
  final TextStyle labelS;

  /// Dato técnico (IP, puerto, Hz): 13/18, Martian Mono 400.
  final TextStyle data;

  /// Numerales de señal (nota, PIN, tiempo): Doto 800 redondeada; el tamaño
  /// se ajusta con `copyWith` entre 22 y 72.
  final TextStyle digits;

  /// Texto de botón: 16, Archivo 640, ancho 112.
  final TextStyle button;

  List<TextStyle> get _values => [
    // dart format off
    display, titleL, title, bodyL, body, bodyS,
    label, labelS, data, digits, button,
    // dart format on
  ];

  @override
  FrType copyWith({
    // dart format off
    TextStyle? display, TextStyle? titleL, TextStyle? title, TextStyle? bodyL,
    TextStyle? body, TextStyle? bodyS, TextStyle? label, TextStyle? labelS,
    TextStyle? data, TextStyle? digits, TextStyle? button,
    // dart format on
  }) {
    final overrides = [
      // dart format off
      display, titleL, title, bodyL, body, bodyS,
      label, labelS, data, digits, button,
      // dart format on
    ];
    return FrType._fromValues([
      for (final (i, style) in _values.indexed) overrides[i] ?? style,
    ]);
  }

  @override
  FrType lerp(covariant ThemeExtension<FrType>? other, double t) {
    if (other is! FrType) return this;
    final to = other._values;
    return FrType._fromValues([
      for (final (i, from) in _values.indexed) TextStyle.lerp(from, to[i], t)!,
    ]);
  }
}
