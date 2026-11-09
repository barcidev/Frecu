import 'package:flutter/services.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Pulsación del botón de volumen para hablar.
enum VolumeKeyEvent {
  /// Se pulsó (app al frente): empezar a hablar.
  down,

  /// Se soltó (app al frente): dejar de hablar.
  up,

  /// Pulsación con la pantalla apagada, sin soltar: empezar o terminar.
  toggle,
}

/// Botones de volumen como PTT, por los canales nativos `frecu/volume_ptt`
/// (solo Android: iOS no deja usar los botones de volumen para otra cosa).
class VolumeButtonsDataSource {
  /// Crea la fuente; [invoke] y [events] reemplazan a los canales en pruebas.
  VolumeButtonsDataSource({
    Future<void> Function(String method, Object? arguments)? invoke,
    this.events,
  }) : _invoke = invoke ?? _channelInvoke;

  static const MethodChannel _methods = MethodChannel('frecu/volume_ptt');
  static const EventChannel _eventChannel = EventChannel(
    'frecu/volume_ptt/events',
  );

  final Future<void> Function(String method, Object? arguments) _invoke;

  /// Pulsaciones en crudo; en pruebas reemplazan al canal.
  final Stream<Object?>? events;

  static Future<void> _channelInvoke(String method, Object? arguments) =>
      _methods.invokeMethod<void>(method, arguments);

  /// Activa o desactiva el botón de volumen como PTT; un fallo (sin la parte
  /// nativa) se registra y no rompe nada.
  Future<void> setEnabled({required bool enabled}) async {
    try {
      await _invoke('setEnabled', enabled);
    } on Object catch (e) {
      AppLogger.d('Volume PTT unavailable: $e');
    }
  }

  /// Pulsaciones mientras está activado.
  Stream<VolumeKeyEvent> watch() =>
      (events ?? _eventChannel.receiveBroadcastStream())
          .map((raw) => VolumeKeyEvent.values.asNameMap()['$raw'])
          .where((event) => event != null)
          .cast<VolumeKeyEvent>()
          .handleError((Object e) => AppLogger.d('Volume PTT events: $e'));
}
