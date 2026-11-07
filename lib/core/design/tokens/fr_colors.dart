import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Colores del sistema de diseño Portadora para un tema (noche o día).
///
/// Copia los tokens de `docs/diseno/prototipo/base.css`. La luz solo la emite
/// la señal: de día el verde rellena, brilla y subraya como marcatexto, y el
/// texto va en tinta (`signalFg`).
class FrColors extends ThemeExtension<FrColors> {
  /// Crea un juego de colores completo.
  const FrColors({
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.line1,
    required this.line2,
    required this.line3,
    required this.spec,
    required this.tx1,
    required this.tx2,
    required this.tx3,
    required this.tx4,
    required this.signal,
    required this.signalInk,
    required this.signalFg,
    required this.signalHi,
    required this.ink,
    required this.washK,
    required this.warn,
    required this.alert,
    required this.warnTx,
    required this.alertTx,
    required this.scrim,
    required this.sheetA,
    required this.sheetB,
    required this.coreHi,
    required this.coreLo,
    required this.touch,
    required this.shadow,
    required this.p1,
    required this.p2,
    required this.p3,
    required this.p4,
    required this.p5,
    this.signalMark,
    this.ledRing,
  });

  /// Recompone un juego desde [_values], en el mismo orden.
  FrColors._fromValues(List<Object?> v)
    : this(
        bg0: v[0]! as Color,
        bg1: v[1]! as Color,
        bg2: v[2]! as Color,
        bg3: v[3]! as Color,
        bg4: v[4]! as Color,
        line1: v[5]! as Color,
        line2: v[6]! as Color,
        line3: v[7]! as Color,
        spec: v[8]! as Color,
        tx1: v[9]! as Color,
        tx2: v[10]! as Color,
        tx3: v[11]! as Color,
        tx4: v[12]! as Color,
        signal: v[13]! as Color,
        signalInk: v[14]! as Color,
        signalFg: v[15]! as Color,
        signalHi: v[16]! as Color,
        ink: v[17]! as Color,
        washK: v[18]! as double,
        warn: v[19]! as Color,
        alert: v[20]! as Color,
        warnTx: v[21]! as Color,
        alertTx: v[22]! as Color,
        scrim: v[23]! as Color,
        sheetA: v[24]! as Color,
        sheetB: v[25]! as Color,
        coreHi: v[26]! as Color,
        coreLo: v[27]! as Color,
        touch: v[28]! as Color,
        shadow: v[29]! as Color,
        p1: v[30]! as Color,
        p2: v[31]! as Color,
        p3: v[32]! as Color,
        p4: v[33]! as Color,
        p5: v[34]! as Color,
        signalMark: v[35] as Color?,
        ledRing: v[36] as Color?,
      );

  /// Noche: grafito casi negro, amable con OLED y con la batería.
  static const FrColors dark = FrColors(
    bg0: Color(0xFF060708),
    bg1: Color(0xFF0C0E10),
    bg2: Color(0xFF13161A),
    bg3: Color(0xFF1B1F24),
    bg4: Color(0xFF262B31),
    line1: Color(0x12E2F0E9),
    line2: Color(0x21E2F0E9),
    line3: Color(0x3DE2F0E9),
    spec: Color(0x16FFFFFF),
    tx1: Color(0xFFF2F4F3),
    tx2: Color(0xFFA3ABA8),
    tx3: Color(0xFF7A8380),
    tx4: Color(0xFF3F4644),
    signal: Color(0xFFC4E05C),
    signalInk: Color(0xFF0A0C05),
    signalFg: Color(0xFFC4E05C),
    signalHi: Color(0xFFEEF5CF),
    ink: Color(0xFFE2F0E9),
    washK: 1,
    warn: Color(0xFFFFB547),
    alert: Color(0xFFFF5A4E),
    warnTx: Color(0xFFFFE2B8),
    alertTx: Color(0xFFFFD3CF),
    scrim: Color(0x8C020304),
    sheetA: Color(0xFF171B20),
    sheetB: Color(0xFF13161A),
    coreHi: Color(0xFF20252B),
    coreLo: Color(0xFF12151A),
    touch: Color(0x38FFFFFF),
    shadow: Color(0xFF000000),
    p1: Color(0xFF7FD6FF),
    p2: Color(0xFFC9A0FF),
    p3: Color(0xFFFF8E7A),
    p4: Color(0xFF5FF0C0),
    p5: Color(0xFFFFD166),
  );

  /// Día: papel claro para leer bajo el sol.
  static const FrColors light = FrColors(
    bg0: Color(0xFFEEF0EC),
    bg1: Color(0xFFFFFFFF),
    bg2: Color(0xFFF6F7F4),
    bg3: Color(0xFFE6E9E3),
    bg4: Color(0xFFD3D8D1),
    line1: Color(0x140E1411),
    line2: Color(0x240E1411),
    line3: Color(0x420E1411),
    spec: Color(0xF2FFFFFF),
    tx1: Color(0xFF0C0F0D),
    tx2: Color(0xFF49524D),
    tx3: Color(0xFF5F6964),
    tx4: Color(0xFFA9B0AB),
    signal: Color(0xFFC4E05C),
    signalInk: Color(0xFF0A0C05),
    signalFg: Color(0xFF0C0F0D),
    signalHi: Color(0xFFEEF5CF),
    ink: Color(0xFF0E1411),
    washK: 5,
    warn: Color(0xFFA86400),
    alert: Color(0xFFD2362B),
    warnTx: Color(0xFF5A3700),
    alertTx: Color(0xFF6B1610),
    scrim: Color(0x47101412),
    sheetA: Color(0xFFFFFFFF),
    sheetB: Color(0xFFF9FAF8),
    coreHi: Color(0xFFFFFFFF),
    coreLo: Color(0xFFE1E5DE),
    touch: Color(0x120E1411),
    shadow: Color(0x590E1411),
    p1: Color(0xFF0B84B8),
    p2: Color(0xFF7A4BD1),
    p3: Color(0xFFCF4B33),
    p4: Color(0xFF0B9A70),
    p5: Color(0xFFA97800),
    signalMark: Color(0xFFC4E05C),
    ledRing: Color(0xFF0C0F0D),
  );

  /// Vacío: fondo de la app.
  final Color bg0;

  /// Grafito: tarjetas.
  final Color bg1;

  /// Pizarra: hojas y campos.
  final Color bg2;

  /// Acero: teclas y estado presionado.
  final Color bg3;

  /// Titanio: bordes de control.
  final Color bg4;

  /// Línea tenue.
  final Color line1;

  /// Línea media.
  final Color line2;

  /// Línea marcada.
  final Color line3;

  /// Filo especular superior.
  final Color spec;

  /// Texto principal.
  final Color tx1;

  /// Texto secundario.
  final Color tx2;

  /// Texto terciario.
  final Color tx3;

  /// Texto decorativo o deshabilitado (no apto para lectura).
  final Color tx4;

  /// Señal: el único acento, el mismo lima mate de noche y de día.
  final Color signal;

  /// Tinta sobre un relleno de señal.
  final Color signalInk;

  /// Señal para texto, trazos y marcas: lima de noche, tinta de día.
  final Color signalFg;

  /// Brillo del núcleo PTT al aire.
  final Color signalHi;

  /// Tinta neutra para retículas y reglas (se usa con opacidad).
  final Color ink;

  /// Multiplicador de los lavados de señal.
  final double washK;

  /// Aviso.
  final Color warn;

  /// Alerta o error.
  final Color alert;

  /// Texto sobre un fondo de aviso.
  final Color warnTx;

  /// Texto sobre un fondo de alerta.
  final Color alertTx;

  /// Velo detrás de hojas y diálogos.
  final Color scrim;

  /// Parte alta del degradado de las hojas.
  final Color sheetA;

  /// Parte baja del degradado de las hojas.
  final Color sheetB;

  /// Luz del núcleo PTT.
  final Color coreHi;

  /// Sombra del núcleo PTT.
  final Color coreLo;

  /// Luz que sigue al dedo al tocar.
  final Color touch;

  /// Sombra de lo que flota.
  final Color shadow;

  /// Canal de participante Hielo.
  final Color p1;

  /// Canal de participante Orquídea.
  final Color p2;

  /// Canal de participante Coral.
  final Color p3;

  /// Canal de participante Menta.
  final Color p4;

  /// Canal de participante Oro.
  final Color p5;

  /// Marcatexto de señal bajo la tinta; nulo de noche.
  final Color? signalMark;

  /// Aro de tinta alrededor de lo encendido; nulo de noche.
  final Color? ledRing;

  /// Canales de los demás participantes, en orden (tú usas la señal).
  List<Color> get channels => [p1, p2, p3, p4, p5];

  /// Todos los tokens, en el orden del constructor; los usan `copyWith` y `lerp`.
  List<Object?> get _values => [
    // dart format off
    bg0, bg1, bg2, bg3, bg4, line1,
    line2, line3, spec, tx1, tx2, tx3,
    tx4, signal, signalInk, signalFg, signalHi, ink,
    washK, warn, alert, warnTx, alertTx, scrim,
    sheetA, sheetB, coreHi, coreLo, touch, shadow,
    p1, p2, p3, p4, p5, signalMark,
    ledRing,
    // dart format on
  ];

  /// Copia con los tokens indicados; los nulos conservan su valor (de día,
  /// `signalMark` y `ledRing` no pueden volver a nulo por esta vía).
  @override
  FrColors copyWith({
    // dart format off
    Color? bg0, Color? bg1, Color? bg2, Color? bg3,
    Color? bg4, Color? line1, Color? line2, Color? line3,
    Color? spec, Color? tx1, Color? tx2, Color? tx3,
    Color? tx4, Color? signal, Color? signalInk, Color? signalFg,
    Color? signalHi, Color? ink, double? washK, Color? warn,
    Color? alert, Color? warnTx, Color? alertTx, Color? scrim,
    Color? sheetA, Color? sheetB, Color? coreHi, Color? coreLo,
    Color? touch, Color? shadow, Color? p1, Color? p2,
    Color? p3, Color? p4, Color? p5, Color? signalMark,
    Color? ledRing,
    // dart format on
  }) {
    final overrides = <Object?>[
      // dart format off
      bg0, bg1, bg2, bg3, bg4, line1,
      line2, line3, spec, tx1, tx2, tx3,
      tx4, signal, signalInk, signalFg, signalHi, ink,
      washK, warn, alert, warnTx, alertTx, scrim,
      sheetA, sheetB, coreHi, coreLo, touch, shadow,
      p1, p2, p3, p4, p5, signalMark,
      ledRing,
      // dart format on
    ];
    return FrColors._fromValues([
      for (final (i, value) in _values.indexed) overrides[i] ?? value,
    ]);
  }

  @override
  FrColors lerp(covariant ThemeExtension<FrColors>? other, double t) {
    if (other is! FrColors) return this;
    // En los extremos, el juego exacto: `Color.lerp` deja un color transparente
    // donde el destino es nulo (`signalMark`, `ledRing`).
    if (t >= 1) return other;
    final to = other._values;
    return FrColors._fromValues([
      for (final (i, from) in _values.indexed) _lerpToken(from, to[i], t),
    ]);
  }

  static Object? _lerpToken(Object? from, Object? to, double t) {
    return switch ((from, to)) {
      (final double a, final double b) => lerpDouble(a, b, t),
      (final Color? a, final Color? b) => Color.lerp(a, b, t),
      _ => to,
    };
  }
}
