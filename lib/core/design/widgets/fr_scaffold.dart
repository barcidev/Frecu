import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:frecu/core/design/fr_theme.dart';
import 'package:frecu/core/design/motion/fr_noise.dart';
import 'package:frecu/core/design/motion/fr_transitions.dart';

/// Pantalla de Portadora: fondo `bg0` con retícula de medición y grano, y un
/// dock opcional abajo para las acciones principales.
///
/// Registra cada toque en [FrTouchOrigin] para que la onda nazca del dedo.
class FrScaffold extends StatelessWidget {
  /// Crea una pantalla con [body].
  const FrScaffold({
    required this.body,
    this.dock,
    this.showGrid = true,
    this.showGrain = true,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  /// Contenido, dentro del área segura (abajo solo si no hay dock).
  final Widget body;

  /// Acciones fijas abajo, sobre un degradado hacia `bg0`.
  final Widget? dock;

  /// Pinta la retícula de puntos.
  final bool showGrid;

  /// Pinta el grano.
  final bool showGrain;

  /// Encoge el contenido cuando aparece el teclado.
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final fr = context.fr;
    final dock = this.dock;
    return Scaffold(
      backgroundColor: fr.colors.bg0,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => FrTouchOrigin.record(event.position),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: FrBackdrop(showGrid: showGrid, showGrain: showGrain),
            ),
            SafeArea(
              bottom: dock == null,
              child: DefaultTextStyle.merge(
                style: fr.type.body.copyWith(color: fr.colors.tx1),
                child: body,
              ),
            ),
            if (dock != null)
              Positioned(left: 0, right: 0, bottom: 0, child: _Dock(dock)),
          ],
        ),
      ),
    );
  }
}

/// Dock del prototipo: relleno 34/20/30 sobre un degradado de `bg0`
/// transparente a `bg0` al 34 %.
class _Dock extends StatelessWidget {
  const _Dock(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bg0 = context.fr.colors.bg0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg0.withValues(alpha: 0), bg0],
          stops: const [0, 0.34],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          34,
          20,
          30 + MediaQuery.paddingOf(context).bottom,
        ),
        child: child,
      ),
    );
  }
}

/// Punto de la retícula: centro y opacidad.
typedef FrGridDot = ({Offset center, double opacity});

/// Fondo de [FrScaffold]: retícula de puntos y grano, pintados una vez en su
/// propia capa.
class FrBackdrop extends StatelessWidget {
  /// Crea el fondo.
  const FrBackdrop({this.showGrid = true, this.showGrain = true, super.key});

  /// Separación de la retícula.
  static const double gridSpacing = 22;

  /// Opacidad de los puntos arriba.
  static const double gridOpacity = 0.06;

  /// Alto, en fracción de la pantalla, en el que la retícula desaparece.
  static const double gridFade = 0.55;

  /// Opacidad del grano.
  static const double grainOpacity = 0.05;

  /// Pinta la retícula.
  final bool showGrid;

  /// Pinta el grano.
  final bool showGrain;

  /// Puntos de la retícula en [size]: uno en el centro de cada celda de 22 px,
  /// en tinta al 6 % que se desvanece hasta el 55 % del alto.
  static List<FrGridDot> gridDots(Size size) {
    final fadeEnd = size.height * gridFade;
    return [
      for (var y = gridSpacing / 2; y < fadeEnd; y += gridSpacing)
        for (var x = gridSpacing / 2; x < size.width; x += gridSpacing)
          (center: Offset(x, y), opacity: gridOpacity * (1 - y / fadeEnd)),
    ];
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.infinite,
      painter: _BackdropPainter(
        ink: context.fr.colors.ink,
        showGrid: showGrid,
        showGrain: showGrain,
      ),
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.ink,
    required this.showGrid,
    required this.showGrain,
  });

  final Color ink;
  final bool showGrid;
  final bool showGrain;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) _paintGrid(canvas, size);
    if (showGrain) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ImageShader(
            FrGrain.tile,
            TileMode.repeated,
            TileMode.repeated,
            Matrix4.identity().storage,
          )
          ..colorFilter = ColorFilter.mode(
            ink.withValues(alpha: FrBackdrop.grainOpacity),
            BlendMode.modulate,
          ),
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final rows = <double, List<double>>{};
    final opacities = <double, double>{};
    for (final dot in FrBackdrop.gridDots(size)) {
      rows.putIfAbsent(dot.center.dy, () => []).addAll([
        dot.center.dx,
        dot.center.dy,
      ]);
      opacities[dot.center.dy] = dot.opacity;
    }
    final paint = Paint()
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round;
    for (final MapEntry(key: y, value: points) in rows.entries) {
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(points),
        paint..color = ink.withValues(alpha: opacities[y]),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.ink != ink ||
      oldDelegate.showGrid != showGrid ||
      oldDelegate.showGrain != showGrain;
}

/// Grano de Portadora: ruido sembrado en un mosaico de 128 × 128 px, igual en
/// cada arranque, pintado una sola vez y teñido de `ink` al dibujarlo.
abstract final class FrGrain {
  /// Lado del mosaico.
  static const int size = 128;

  /// Semilla del ruido.
  static const int seed = 0x6772616e;

  /// Opacidad máxima de un grano (el `feColorMatrix` del prototipo).
  static const double maxAlpha = 0.55;

  static const int _levels = 8;

  static ui.Image? _tile;

  /// Alfas del mosaico, fila por fila, de 0 a 140 (55 % de 255).
  static Uint8List alphas() {
    final random = FrRandom(seed);
    return Uint8List.fromList([
      for (var i = 0; i < size * size; i++)
        (random.next() * maxAlpha * 255).round(),
    ]);
  }

  /// Mosaico blanco con las alfas del grano; se crea la primera vez.
  static ui.Image get tile => _tile ??= _paintTile();

  static ui.Image _paintTile() {
    final alphas = FrGrain.alphas();
    final buckets = List.generate(_levels, (_) => <double>[]);
    const top = maxAlpha * 255;
    for (var i = 0; i < alphas.length; i++) {
      final level = (alphas[i] / top * _levels).floor().clamp(0, _levels - 1);
      buckets[level].addAll([i % size + 0.5, i ~/ size + 0.5]);
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.square;
    for (final (level, points) in buckets.indexed) {
      if (points.isEmpty) continue;
      // Máscara blanca: el pintor la tiñe con la tinta del tema.
      paint.color = Color.fromRGBO(
        255,
        255,
        255,
        (level + 0.5) / _levels * maxAlpha,
      );
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(points),
        paint,
      );
    }
    return recorder.endRecording().toImageSync(size, size);
  }
}
