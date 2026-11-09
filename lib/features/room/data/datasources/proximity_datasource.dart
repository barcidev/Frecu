import 'package:flutter/services.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Sensor de proximidad por los canales nativos `frecu/proximity`.
///
/// Mientras está activado, el sistema apaga la pantalla con el teléfono en
/// la oreja (como en una llamada) y la enciende al alejarlo.
class ProximityDataSource {
  /// Crea la fuente; [invoke] y [events] reemplazan a los canales en pruebas.
  ProximityDataSource({
    Future<Object?> Function(String method, Object? arguments)? invoke,
    this.events,
  }) : _invoke = invoke ?? _channelInvoke;

  static const MethodChannel _methods = MethodChannel('frecu/proximity');
  static const EventChannel _eventChannel = EventChannel(
    'frecu/proximity/events',
  );

  final Future<Object?> Function(String method, Object? arguments) _invoke;

  /// Lecturas en crudo; en pruebas reemplazan al canal.
  final Stream<Object?>? events;

  static Future<Object?> _channelInvoke(String method, Object? arguments) =>
      _methods.invokeMethod<Object?>(method, arguments);

  /// Activa o desactiva el sensor; devuelve si el teléfono tiene uno. Un
  /// fallo (sin la parte nativa) cuenta como que no lo tiene.
  Future<bool> setEnabled({required bool enabled}) async {
    try {
      return await _invoke('setEnabled', enabled) == true;
    } on Object catch (e) {
      AppLogger.d('Proximity unavailable: $e');
      return false;
    }
  }

  /// `true` con algo cerca (la oreja) y `false` al alejarse.
  Stream<bool> watch() => (events ?? _eventChannel.receiveBroadcastStream())
      .where((raw) => raw is bool)
      .cast<bool>()
      .handleError((Object e) => AppLogger.d('Proximity events: $e'));
}
