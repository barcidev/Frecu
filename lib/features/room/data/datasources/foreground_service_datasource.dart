import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:frecu/core/logging/app_logger.dart';

/// Id del botón «Salir» de la notificación de la frecu.
const String kLeaveNotificationButton = 'leave';

/// Top-level callback required by flutter_foreground_task.
@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(FrecuForegroundTaskHandler());
}

/// Handler for the foreground task events.
class FrecuForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    AppLogger.d('Foreground service started: $starter');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  /// «Salir» de la notificación: avisa a la app, que deja la frecu.
  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain(id);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    AppLogger.d('Foreground service destroyed (timeout: $isTimeout)');
  }
}

/// Estado de la frecu que muestra la notificación persistente.
enum ForegroundStatus {
  /// En la frecu, con el anfitrión.
  connected,

  /// Reconectando con el anfitrión.
  reconnecting,
}

/// Textos visibles de la notificación, ya traducidos por la capa de
/// presentación: la capa de datos no tiene textos propios.
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
    connected: _blank,
    reconnecting: _blank,
  );

  static String _blank(String roomName) => '';

  /// Nombre del canal de notificaciones (Android).
  final String channelName;

  /// Descripción del canal de notificaciones (Android).
  final String channelDescription;

  /// Título de la notificación.
  final String title;

  /// Texto con la frecu en línea; recibe el nombre de la frecu (vacío si
  /// el anfitrión no lo mandó).
  final String Function(String roomName) connected;

  /// Texto mientras se reconecta; recibe el nombre de la frecu.
  final String Function(String roomName) reconnecting;

  /// Botón para salir de la frecu desde la notificación; vacío, sin botón.
  final String leave;

  /// Texto de [status] para la frecu [roomName].
  String line(String roomName, ForegroundStatus status) => switch (status) {
    ForegroundStatus.connected => connected(roomName),
    ForegroundStatus.reconnecting => reconnecting(roomName),
  };
}

/// Wrapper datasource for managing the persistent foreground service.
class ForegroundServiceDataSource {
  /// Constructor; [texts] da los textos visibles ya traducidos en el
  /// idioma de cada momento.
  ForegroundServiceDataSource({ForegroundNotificationTexts Function()? texts})
    : _texts = texts ?? (() => ForegroundNotificationTexts.empty);

  final ForegroundNotificationTexts Function() _texts;

  bool _isRunning = false;

  final StreamController<int> _leaveRequests =
      StreamController<int>.broadcast();
  int _leaveCount = 0;

  /// Toques en «Salir» de la notificación (Android), numerados para que dos
  /// toques seguidos no se confundan.
  Stream<int> get leaveRequests => _leaveRequests.stream;

  /// Recibe lo que manda el servicio en primer plano: «Salir» solo cuenta
  /// con el servicio activo.
  void handleTaskData(Object data) {
    if (data == kLeaveNotificationButton && _isRunning) {
      _leaveRequests.add(++_leaveCount);
    }
  }

  /// Botones de la notificación con los textos de ahora.
  List<NotificationButton>? _buttons(ForegroundNotificationTexts texts) =>
      texts.leave.isEmpty
      ? null
      : [NotificationButton(id: kLeaveNotificationButton, text: texts.leave)];

  /// Deja de escuchar al servicio.
  Future<void> dispose() async {
    if (!_isTest) FlutterForegroundTask.removeTaskDataCallback(handleTaskData);
    await _leaveRequests.close();
  }

  /// Whether the foreground service is active.
  bool get isRunning => _isRunning;

  static bool get _isTest =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Zone.current[#test.declarer] != null;

  /// Initializes notification options and foreground task configurations.
  Future<void> init() async {
    if (_isTest) return;
    try {
      final texts = _texts();
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'frecu_foreground_service',
          channelName: texts.channelName,
          channelDescription: texts.channelDescription,
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
        ),
      );
      // El botón «Salir» de la notificación llega por este puerto.
      FlutterForegroundTask.initCommunicationPort();
      FlutterForegroundTask.addTaskDataCallback(handleTaskData);
    } on Object catch (e, st) {
      AppLogger.w('Failed to init foreground task: $e', e, st);
    }
  }

  /// Starts the foreground service displaying a persistent notification.
  Future<void> startService({
    required String roomName,
    required ForegroundStatus status,
  }) async {
    _isRunning = true;
    if (_isTest) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await updateNotification(roomName: roomName, status: status);
        return;
      }

      final texts = _texts();
      await FlutterForegroundTask.startService(
        serviceId: 4780,
        notificationTitle: texts.title,
        notificationText: texts.line(roomName, status),
        notificationButtons: _buttons(texts),
        callback: startForegroundCallback,
      );
    } on Object catch (e, st) {
      AppLogger.e('Failed to start foreground service', e, st);
    }
  }

  /// Updates the notification content while service is running.
  Future<void> updateNotification({
    required String roomName,
    required ForegroundStatus status,
  }) async {
    if (!_isRunning) return;
    if (_isTest) return;

    try {
      final texts = _texts();
      await FlutterForegroundTask.updateService(
        notificationTitle: texts.title,
        notificationText: texts.line(roomName, status),
        notificationButtons: _buttons(texts),
      );
    } on Object catch (e, st) {
      AppLogger.w('Failed to update foreground service notification', e, st);
    }
  }

  /// Stops the foreground service.
  Future<void> stopService() async {
    _isRunning = false;
    if (_isTest) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } on Object catch (e, st) {
      AppLogger.w('Failed to stop foreground service', e, st);
    }
  }
}
