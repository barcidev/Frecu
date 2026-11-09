import 'package:flutter/services.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Patrones de vibración de la frecu. Cada uno se nota distinto sin mirar el
/// teléfono, p. ej. en el bolsillo o con guantes.
enum HapticPattern {
  /// Un toque corto: empiezas o dejas de transmitir, o volvió la conexión.
  tick,

  /// Dos toques suaves: alguien empieza a hablar.
  talk,

  /// Dos toques firmes: se perdió la conexión o una señal llega débil.
  alert,

  /// Tres pulsos largos: llegó un SOS.
  sos,
}

/// Vibración nativa por el canal `frecu/haptics`.
///
/// En Android usa el vibrador del sistema como aviso de comunicación, que
/// también suena con la pantalla apagada mientras corre el servicio en primer
/// plano. En iOS permite la vibración durante la grabación del micrófono,
/// que el sistema calla por defecto. Un fallo (p. ej. sin la parte nativa en
/// pruebas) se registra y no rompe nada.
class Haptics {
  /// Crea la vibración; [invoke] reemplaza al canal en pruebas.
  Haptics({Future<void> Function(String method, Object? arguments)? invoke})
    : _invoke = invoke ?? _channelInvoke;

  /// Canal nativo.
  static const MethodChannel channel = MethodChannel('frecu/haptics');

  final Future<void> Function(String method, Object? arguments) _invoke;

  static Future<void> _channelInvoke(String method, Object? arguments) =>
      channel.invokeMethod<void>(method, arguments);

  /// Vibra con [pattern].
  Future<void> play(HapticPattern pattern) async {
    try {
      await _invoke('play', pattern.name);
    } on Object catch (e) {
      AppLogger.d('Haptics unavailable: $e');
    }
  }
}
