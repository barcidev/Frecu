import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Estado de la frecu que muestra la notificación mientras la app todavía no
/// mandó su contenido completo ([RoomNotificationContent]).
enum ForegroundStatus {
  /// En la frecu, con el anfitrión.
  connected,

  /// Reconectando con el anfitrión.
  reconnecting,
}

/// Botones de la tarjeta de la frecu; su nombre es el id que viaja al
/// servicio nativo y vuelve al tocarlos.
enum RoomNotificationAction {
  /// Micrófono: hablar y cortar, o silenciarse y activarlo. También el
  /// play/pausa de unos audífonos.
  mic,

  /// Pasar a la siguiente salida de audio.
  route,

  /// Salir de la frecu (el anfitrión la cierra).
  leave,

  /// Responder «Voy en camino» al SOS.
  sosGo,

  /// Quitar el aviso del SOS.
  sosAck,

  /// La persona tocó la tarjeta para invitar: abrir el QR.
  invite,
}

/// Íconos de los botones; el servicio nativo tiene un dibujable para cada
/// uno, con los trazos de `FrIcons`.
enum RoomNotificationIcon {
  /// Micrófono.
  mic,

  /// Micrófono silenciado.
  micOff,

  /// Cortar la transmisión.
  stop,

  /// Altavoz.
  speaker,

  /// Auricular.
  earpiece,

  /// Audífonos (salida por Bluetooth).
  headset,

  /// Salir.
  exit,

  /// Confirmar («Voy en camino»).
  check,

  /// Cerrar el aviso.
  close,
}

/// Botón de la tarjeta: qué hace, su ícono y su nombre accesible.
@immutable
class RoomNotificationButton {
  /// Crea el botón.
  const RoomNotificationButton(this.action, this.icon, this.label);

  /// Qué hace.
  final RoomNotificationAction action;

  /// Ícono que lo dibuja.
  final RoomNotificationIcon icon;

  /// Nombre para lectores de pantalla (y para Android 12 o anterior).
  final String label;

  /// Forma en que viaja al servicio nativo.
  Map<String, Object?> toMap() => {
    'id': action.name,
    'icon': icon.name,
    'label': label,
  };

  @override
  bool operator ==(Object other) =>
      other is RoomNotificationButton &&
      other.action == action &&
      other.icon == icon &&
      other.label == label;

  @override
  int get hashCode => Object.hash(action, icon, label);
}

/// Lo que muestra la tarjeta de la frecu, ya traducido y dibujado por la
/// capa de presentación: la capa de datos no tiene textos propios.
@immutable
class RoomNotificationContent {
  /// Crea el contenido.
  const RoomNotificationContent({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.buttons,
    this.note,
    this.art,
    this.tapInvites = false,
  });

  /// Título: el nombre de la frecu (o quién pide ayuda).
  final String title;

  /// Subtítulo: lo que dice la isla de estado.
  final String subtitle;

  /// Nota de la frecu («Sol4»), si tiene.
  final String? note;

  /// Color del estado (ARGB), para Android 12 o anterior.
  final int accent;

  /// Carátula en PNG, si ya está dibujada.
  final Uint8List? art;

  /// Botones, el del micrófono primero.
  final List<RoomNotificationButton> buttons;

  /// Tocar la tarjeta abre la frecu con el QR (anfitrión solo).
  final bool tapInvites;

  /// Forma en que viaja al servicio nativo.
  Map<String, Object?> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'note': note,
    'accent': accent,
    'art': art,
    'buttons': [for (final button in buttons) button.toMap()],
    'tapInvites': tapInvites,
  };
}

/// Textos de la notificación antes de que la app mande su contenido, ya
/// traducidos por la capa de presentación.
class ForegroundNotificationTexts {
  /// Crea los textos.
  const ForegroundNotificationTexts({
    required this.channelName,
    required this.channelDescription,
    required this.title,
    required this.connected,
    required this.reconnecting,
    this.leave = '',
  });

  /// Textos vacíos, mientras no se inyectan los traducidos.
  static const ForegroundNotificationTexts empty = ForegroundNotificationTexts(
    channelName: '',
    channelDescription: '',
    title: '',
    connected: '',
    reconnecting: '',
  );

  /// Nombre del canal de notificaciones (Android).
  final String channelName;

  /// Descripción del canal de notificaciones (Android).
  final String channelDescription;

  /// Título si la frecu no tiene nombre (anfitrión de una versión anterior).
  final String title;

  /// Subtítulo con la frecu en línea.
  final String connected;

  /// Subtítulo mientras se reconecta.
  final String reconnecting;

  /// Nombre del botón para salir; vacío, sin botón.
  final String leave;

  /// Texto de [status].
  String line(ForegroundStatus status) => switch (status) {
    ForegroundStatus.connected => connected,
    ForegroundStatus.reconnecting => reconnecting,
  };
}

/// Servicio en primer plano de la frecu activa (solo Android), por el canal
/// `frecu/room_service` (`FrecuRoomService.kt`).
///
/// Mantiene la voz con la pantalla apagada y muestra la frecu como un
/// reproductor. El repositorio lo arranca y lo para con la frecu; la
/// pantalla de la frecu le manda el contenido completo con [show]. En iOS no
/// hace nada: no hay notificaciones fijas y la voz sigue por el modo de audio
/// en segundo plano.
class ForegroundServiceDataSource {
  /// Crea la fuente; [texts] da los textos de arranque en el idioma de cada
  /// momento. [invoke] reemplaza al canal en pruebas, y con él la fuente
  /// funciona en cualquier plataforma.
  ForegroundServiceDataSource({
    ForegroundNotificationTexts Function()? texts,
    Future<Object?> Function(String method, Object? arguments)? invoke,
  }) : _texts = texts ?? (() => ForegroundNotificationTexts.empty),
       _invoke = invoke ?? _channelInvoke,
       _usesChannel = invoke == null && _isAndroidApp,
       _native = invoke != null || _isAndroidApp;

  static const MethodChannel _channel = MethodChannel('frecu/room_service');

  static Future<Object?> _channelInvoke(String method, Object? arguments) =>
      _channel.invokeMethod<Object?>(method, arguments);

  static bool get _isAndroidApp =>
      !kIsWeb &&
      Platform.isAndroid &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  final ForegroundNotificationTexts Function() _texts;
  final Future<Object?> Function(String method, Object? arguments) _invoke;

  /// Hay servicio nativo al que hablar.
  final bool _native;

  /// Habla por el canal de plataforma (no por un [_invoke] de prueba).
  final bool _usesChannel;

  bool _isRunning = false;

  /// Con la ubicación compartida el servicio también es de tipo `location`:
  /// sin ese tipo Android no da la ubicación con la pantalla apagada.
  bool _locationActive = false;
  String _roomName = '';
  ForegroundStatus _status = ForegroundStatus.connected;

  /// Último contenido completo de la app; mientras no hay, se muestra el de
  /// arranque con [_roomName] y [_status].
  RoomNotificationContent? _content;

  final StreamController<int> _leaveRequests =
      StreamController<int>.broadcast();
  final StreamController<RoomNotificationAction> _actions =
      StreamController<RoomNotificationAction>.broadcast();
  int _leaveCount = 0;

  /// Toques en «Salir» de la tarjeta, numerados para que dos toques seguidos
  /// no se confundan.
  Stream<int> get leaveRequests => _leaveRequests.stream;

  /// Los demás botones de la tarjeta (y el play/pausa de los audífonos).
  Stream<RoomNotificationAction> get actions => _actions.stream;

  /// Whether the foreground service is active.
  bool get isRunning => _isRunning;

  /// Hay servicio nativo (Android, o un canal de prueba): solo entonces
  /// vale la pena armar la tarjeta.
  bool get isAvailable => _native;

  /// Si el servicio lleva el tipo `location`.
  bool get locationActive => _locationActive;

  /// Recibe un botón del servicio nativo: solo cuenta con el servicio activo.
  void handleAction(String id) {
    if (!_isRunning) return;
    final action = RoomNotificationAction.values.asNameMap()[id];
    if (action == null) return;
    if (action == RoomNotificationAction.leave) {
      _leaveRequests.add(++_leaveCount);
    } else {
      _actions.add(action);
    }
  }

  /// Empieza a escuchar los botones del servicio.
  Future<void> init() async {
    if (!_usesChannel) return;
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'action' && call.arguments is String) {
          handleAction(call.arguments as String);
        }
      });
    } on Object catch (e, st) {
      AppLogger.w('Room service channel unavailable: $e', e, st);
    }
  }

  /// Deja de escuchar al servicio.
  Future<void> dispose() async {
    if (_usesChannel) {
      try {
        _channel.setMethodCallHandler(null);
      } on Object catch (_) {}
    }
    await _leaveRequests.close();
    await _actions.close();
  }

  /// Arranca el servicio con la frecu [roomName]; si ya corre, solo cambia
  /// su [status] (el contenido de la app, si lo hay, manda).
  Future<void> startService({
    required String roomName,
    required ForegroundStatus status,
  }) async {
    final wasRunning = _isRunning;
    _isRunning = true;
    _roomName = roomName;
    _status = status;
    if (wasRunning) {
      if (_content == null) await _send('update', _baseContent().toMap());
      return;
    }
    final texts = _texts();
    await _send('start', {
      'channelName': texts.channelName,
      'channelDescription': texts.channelDescription,
      'location': _locationActive,
      'content': (_content ?? _baseContent()).toMap(),
    });
  }

  /// Cambia el estado de arranque; no pisa el contenido de la app.
  Future<void> updateNotification({
    required String roomName,
    required ForegroundStatus status,
  }) async {
    if (!_isRunning) return;
    _roomName = roomName;
    _status = status;
    if (_content != null) return;
    await _send('update', _baseContent().toMap());
  }

  /// Muestra [content] en la tarjeta de la frecu.
  Future<void> show(RoomNotificationContent content) async {
    // Fuera de la frecu no se guarda: la próxima empezaría con este.
    if (!_isRunning) return;
    _content = content;
    await _send('update', content.toMap());
  }

  /// Suma o quita el tipo `location` al servicio. Android solo deja sumarlo
  /// con la app al frente (al tocar «Compartir mi ubicación»).
  Future<void> setLocationActive({required bool active}) async {
    if (_locationActive == active) return;
    _locationActive = active;
    if (!_isRunning) return;
    await _send('setLocation', active);
  }

  /// Stops the foreground service.
  Future<void> stopService() async {
    _isRunning = false;
    _locationActive = false;
    _content = null;
    await _send('stop', null);
  }

  /// Contenido de arranque: el nombre de la frecu, su estado y «Salir».
  RoomNotificationContent _baseContent() {
    final texts = _texts();
    return RoomNotificationContent(
      title: _roomName.isEmpty ? texts.title : _roomName,
      subtitle: texts.line(_status),
      accent: _status == ForegroundStatus.reconnecting
          ? 0xFFFFB547
          : 0xFFC4E05C,
      buttons: [
        if (texts.leave.isNotEmpty)
          RoomNotificationButton(
            RoomNotificationAction.leave,
            RoomNotificationIcon.exit,
            texts.leave,
          ),
      ],
    );
  }

  Future<void> _send(String method, Object? arguments) async {
    if (!_native) return;
    try {
      await _invoke(method, arguments);
    } on Object catch (e, st) {
      AppLogger.w('Room service call "$method" failed: $e', e, st);
    }
  }
}
