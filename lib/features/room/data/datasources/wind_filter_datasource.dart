import 'package:flutter/services.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Filtro de viento nativo por el canal `frecu/wind_filter`: un paso alto de
/// 4.º orden a 150 Hz sobre el micrófono, después del procesado de WebRTC.
class WindFilterDataSource {
  /// Crea la fuente; [invoke] reemplaza al canal en pruebas.
  WindFilterDataSource({
    Future<Object?> Function(String method, Object? arguments)? invoke,
  }) : _invoke = invoke ?? _channelInvoke;

  static const MethodChannel _methods = MethodChannel('frecu/wind_filter');

  final Future<Object?> Function(String method, Object? arguments) _invoke;

  static Future<Object?> _channelInvoke(String method, Object? arguments) =>
      _methods.invokeMethod<Object?>(method, arguments);

  /// Engancha o quita el filtro; devuelve si quedó como se pidió (falla si
  /// WebRTC aún no arrancó o sin la parte nativa).
  Future<bool> setEnabled({required bool enabled}) async {
    try {
      return await _invoke('setEnabled', enabled) == true;
    } on Object catch (e) {
      AppLogger.d('Wind filter unavailable: $e');
      return false;
    }
  }
}
