import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Movimiento reducido pedido por el sistema ("Quitar animaciones" en
/// Android, "Reducir movimiento" en iOS).
extension FrReducedMotion on BuildContext {
  /// Verdadero si las animaciones orgánicas deben detenerse o pasar a
  /// fundidos.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}

/// Construye el contenido de un [FrLoop] con el tiempo del bucle.
typedef FrLoopBuilder = Widget Function(
  BuildContext context,
  ValueListenable<double> seconds,
);

/// Bucle de animación continua para pintores (firma, onda, malla).
///
/// Da el tiempo en segundos como [ValueListenable] para repintar sin
/// reconstruir widgets. Usa un único `Ticker`, que se pausa fuera de pantalla
/// (`TickerMode`) y se detiene con movimiento reducido: el tiempo se congela
/// en el último cuadro y sigue desde ahí si el sistema vuelve a animar.
class FrLoop extends StatefulWidget {
  /// Crea un bucle que entrega su tiempo a [builder].
  const FrLoop({required this.builder, super.key});

  /// Construye el contenido con el tiempo del bucle.
  final FrLoopBuilder builder;

  @override
  State<FrLoop> createState() => _FrLoopState();
}

class _FrLoopState extends State<FrLoop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<double> _seconds = ValueNotifier<double>(0);
  double _start = 0;

  void _onTick(Duration elapsed) {
    _seconds.value =
        _start + elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _start = _seconds.value;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _seconds);
}
