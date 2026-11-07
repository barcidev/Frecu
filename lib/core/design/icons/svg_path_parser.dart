import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Segmento de un trazo SVG, ya en coordenadas absolutas.
///
/// [parseSvgPathData] lo produce desde el atributo `d` y [buildSvgPath] lo
/// vuelca en un [Path].
@immutable
sealed class SvgPathSegment {
  const SvgPathSegment();
}

/// Empieza un subtrazado en [to] (`M`).
final class SvgMoveTo extends SvgPathSegment {
  /// Crea un salto a [to].
  const SvgMoveTo(this.to);

  /// Punto de inicio.
  final Offset to;

  @override
  bool operator ==(Object other) => other is SvgMoveTo && other.to == to;

  @override
  int get hashCode => Object.hash(SvgMoveTo, to);

  @override
  String toString() => 'SvgMoveTo($to)';
}

/// Línea recta hasta [to] (`L`, `H` y `V`).
final class SvgLineTo extends SvgPathSegment {
  /// Crea una línea hasta [to].
  const SvgLineTo(this.to);

  /// Punto final.
  final Offset to;

  @override
  bool operator ==(Object other) => other is SvgLineTo && other.to == to;

  @override
  int get hashCode => Object.hash(SvgLineTo, to);

  @override
  String toString() => 'SvgLineTo($to)';
}

/// Curva cúbica de Bézier (`C` y `S`).
final class SvgCubicTo extends SvgPathSegment {
  /// Crea una cúbica hasta [to] con sus dos puntos de control.
  const SvgCubicTo(this.control1, this.control2, this.to);

  /// Primer punto de control.
  final Offset control1;

  /// Segundo punto de control.
  final Offset control2;

  /// Punto final.
  final Offset to;

  @override
  bool operator ==(Object other) =>
      other is SvgCubicTo &&
      other.control1 == control1 &&
      other.control2 == control2 &&
      other.to == to;

  @override
  int get hashCode => Object.hash(SvgCubicTo, control1, control2, to);

  @override
  String toString() => 'SvgCubicTo($control1, $control2, $to)';
}

/// Curva cuadrática de Bézier (`Q` y `T`).
final class SvgQuadTo extends SvgPathSegment {
  /// Crea una cuadrática hasta [to] con su punto de control.
  const SvgQuadTo(this.control, this.to);

  /// Punto de control.
  final Offset control;

  /// Punto final.
  final Offset to;

  @override
  bool operator ==(Object other) =>
      other is SvgQuadTo && other.control == control && other.to == to;

  @override
  int get hashCode => Object.hash(SvgQuadTo, control, to);

  @override
  String toString() => 'SvgQuadTo($control, $to)';
}

/// Arco de elipse hasta [to] (`A`), con la semántica de SVG.
final class SvgArcTo extends SvgPathSegment {
  /// Crea un arco hasta [to].
  const SvgArcTo(
    this.to, {
    required this.radius,
    this.rotation = 0,
    this.largeArc = false,
    this.clockwise = false,
  });

  /// Punto final.
  final Offset to;

  /// Radios de la elipse, siempre positivos.
  final Radius radius;

  /// Giro del eje x de la elipse, en grados.
  final double rotation;

  /// Bandera de arco grande: el recorrido supera 180°.
  final bool largeArc;

  /// Bandera de barrido: `true` recorre el arco en sentido horario en
  /// pantalla (`sweep-flag` 1).
  final bool clockwise;

  @override
  bool operator ==(Object other) =>
      other is SvgArcTo &&
      other.to == to &&
      other.radius == radius &&
      other.rotation == rotation &&
      other.largeArc == largeArc &&
      other.clockwise == clockwise;

  @override
  int get hashCode =>
      Object.hash(SvgArcTo, to, radius, rotation, largeArc, clockwise);

  @override
  String toString() =>
      'SvgArcTo($to, radius: $radius, rotation: $rotation, '
      'largeArc: $largeArc, clockwise: $clockwise)';
}

/// Cierra el subtrazado actual (`Z`).
final class SvgClose extends SvgPathSegment {
  /// Crea un cierre.
  const SvgClose();

  @override
  bool operator ==(Object other) => other is SvgClose;

  @override
  int get hashCode => (SvgClose).hashCode;

  @override
  String toString() => 'SvgClose()';
}

/// Lee el atributo `d` de un trazo SVG y lo devuelve en segmentos absolutos.
///
/// Acepta M, L, H, V, C, S, Q, T, A y Z en mayúscula (absolutos) y minúscula
/// (relativos), con las repeticiones implícitas de SVG y números compactos
/// (`.5.5`, `-2-2`, `1e-1`, banderas de arco pegadas). H y V se devuelven
/// como líneas, S y T como curvas con el control reflejado, un arco con
/// radio 0 como línea, y un arco que no se mueve se omite.
///
/// Lanza [FormatException] con la posición del error si el trazo está mal
/// formado.
List<SvgPathSegment> parseSvgPathData(String d) => _SvgPathReader(d).read();

/// Vuelca [segments] en un [Path].
Path buildSvgPath(Iterable<SvgPathSegment> segments) {
  final path = Path();
  for (final segment in segments) {
    switch (segment) {
      case SvgMoveTo(:final to):
        path.moveTo(to.dx, to.dy);
      case SvgLineTo(:final to):
        path.lineTo(to.dx, to.dy);
      case SvgCubicTo(:final control1, :final control2, :final to):
        path.cubicTo(
          control1.dx,
          control1.dy,
          control2.dx,
          control2.dy,
          to.dx,
          to.dy,
        );
      case SvgQuadTo(:final control, :final to):
        path.quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
      case SvgArcTo(
        :final to,
        :final radius,
        :final rotation,
        :final largeArc,
        :final clockwise,
      ):
        path.arcToPoint(
          to,
          radius: radius,
          rotation: rotation,
          largeArc: largeArc,
          clockwise: clockwise,
        );
      case SvgClose():
        path.close();
    }
  }
  return path;
}

class _SvgPathReader {
  _SvgPathReader(this._source);

  static const _commands = 'MmLlHhVvCcSsQqTtAaZz';

  final String _source;
  final _segments = <SvgPathSegment>[];
  int _at = 0;
  Offset _current = Offset.zero;
  Offset _start = Offset.zero;

  /// Segundo control de la cúbica anterior, para reflejarlo en `S`.
  Offset? _cubicControl;

  /// Control de la cuadrática anterior, para reflejarlo en `T`.
  Offset? _quadControl;

  bool get _atEnd => _at >= _source.length;

  List<SvgPathSegment> read() {
    String? command;
    while (true) {
      _skipSeparators();
      if (_atEnd) return _segments;
      final char = _source[_at];
      final position = _at;
      if (_commands.contains(char)) {
        command = char;
        _at++;
      } else if (command != null &&
          command.toUpperCase() != 'Z' &&
          _startsNumber(char)) {
        // Los pares que siguen a M son líneas; los demás repiten su comando.
        command = switch (command) {
          'M' => 'L',
          'm' => 'l',
          _ => command,
        };
      } else {
        throw FormatException(
          'Comando de trazo inesperado: «$char»',
          _source,
          position,
        );
      }
      if (_segments.isEmpty && command.toUpperCase() != 'M') {
        throw FormatException(
          'El trazo debe empezar con M o m',
          _source,
          position,
        );
      }
      _run(command);
    }
  }

  void _run(String command) {
    final upper = command.toUpperCase();
    final base = command == upper ? Offset.zero : _current;
    Offset? cubicControl;
    Offset? quadControl;
    switch (upper) {
      case 'C' || 'S':
        cubicControl = _cubic(base, smooth: upper == 'S');
      case 'Q' || 'T':
        quadControl = _quad(base, smooth: upper == 'T');
      default:
        _straight(upper, base);
    }
    // S y T solo reflejan el control de una curva de su mismo tipo.
    _cubicControl = cubicControl;
    _quadControl = quadControl;
  }

  /// Comandos sin punto de control: M, L, H, V, A y Z.
  void _straight(String command, Offset base) {
    switch (command) {
      case 'M':
        final to = _point(base);
        _segments.add(SvgMoveTo(to));
        _start = to;
        _current = to;
      case 'L':
        _lineTo(_point(base));
      case 'H':
        _lineTo(Offset(base.dx + _number(), _current.dy));
      case 'V':
        _lineTo(Offset(_current.dx, base.dy + _number()));
      case 'A':
        _arc(base);
      case 'Z':
        _segments.add(const SvgClose());
        _current = _start;
    }
  }

  /// Lee una cúbica (`C`, o `S` si [smooth]) y devuelve su segundo control.
  Offset _cubic(Offset base, {required bool smooth}) {
    final control1 = smooth ? _reflect(_cubicControl) : _point(base);
    final control2 = _point(base);
    final to = _point(base);
    _segments.add(SvgCubicTo(control1, control2, to));
    _current = to;
    return control2;
  }

  /// Lee una cuadrática (`Q`, o `T` si [smooth]) y devuelve su control.
  Offset _quad(Offset base, {required bool smooth}) {
    final control = smooth ? _reflect(_quadControl) : _point(base);
    final to = _point(base);
    _segments.add(SvgQuadTo(control, to));
    _current = to;
    return control;
  }

  void _lineTo(Offset to) {
    _segments.add(SvgLineTo(to));
    _current = to;
  }

  void _arc(Offset base) {
    final rx = _number().abs();
    final ry = _number().abs();
    final rotation = _number();
    final largeArc = _flag();
    final clockwise = _flag();
    final to = _point(base);
    if (to == _current) return;
    if (rx == 0 || ry == 0) {
      _lineTo(to);
      return;
    }
    _segments.add(
      SvgArcTo(
        to,
        radius: Radius.elliptical(rx, ry),
        rotation: rotation,
        largeArc: largeArc,
        clockwise: clockwise,
      ),
    );
    _current = to;
  }

  /// Refleja [control] sobre el punto actual; sin control, el punto actual.
  Offset _reflect(Offset? control) =>
      control == null ? _current : _current * 2 - control;

  Offset _point(Offset base) {
    final x = _number();
    final y = _number();
    return Offset(base.dx + x, base.dy + y);
  }

  double _number() {
    _skipSeparators();
    final begin = _at;
    _skipSign();
    final integer = _skipDigits();
    final fraction = _skipFraction();
    if (!integer && !fraction) {
      throw FormatException('Se esperaba un número', _source, begin);
    }
    _skipExponent();
    return _parseNumber(_source.substring(begin, _at));
  }

  void _skipSign() {
    if (!_atEnd && '+-'.contains(_source[_at])) _at++;
  }

  /// Salta `.` y sus decimales; dice si había alguno.
  bool _skipFraction() {
    if (_atEnd || _source[_at] != '.') return false;
    _at++;
    return _skipDigits();
  }

  /// Salta `e±n`; si no lleva dígitos, no es un exponente y no lo consume.
  void _skipExponent() {
    if (_atEnd || !'eE'.contains(_source[_at])) return;
    final mark = _at;
    _at++;
    _skipSign();
    if (!_skipDigits()) _at = mark;
  }

  /// Convierte un número de SVG (`+.5`, `1.`, `1.e2`) al formato de Dart.
  static double _parseNumber(String text) {
    final unsigned = text.startsWith('+') ? text.substring(1) : text;
    return double.parse(unsigned.replaceFirst(RegExp(r'\.(?=[eE]|$)'), '.0'));
  }

  bool _flag() {
    _skipSeparators();
    final char = _atEnd ? '' : _source[_at];
    if (char != '0' && char != '1') {
      throw FormatException(
        'Se esperaba una bandera de arco (0 o 1)',
        _source,
        _at,
      );
    }
    _at++;
    return char == '1';
  }

  bool _skipDigits() {
    final begin = _at;
    while (!_atEnd && _isDigit(_source.codeUnitAt(_at))) {
      _at++;
    }
    return _at > begin;
  }

  void _skipSeparators() {
    while (!_atEnd && ' \t\n\r\f,'.contains(_source[_at])) {
      _at++;
    }
  }

  static bool _isDigit(int unit) => unit >= 0x30 && unit <= 0x39;

  static bool _startsNumber(String char) =>
      char == '+' || char == '-' || char == '.' || _isDigit(char.codeUnitAt(0));
}
