import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:frecu/core/logging/app_logger.dart';

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

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    AppLogger.d('Foreground service destroyed (timeout: $isTimeout)');
  }
}

/// Wrapper datasource for managing the persistent foreground service.
class ForegroundServiceDataSource {
  /// Constructor.
  ForegroundServiceDataSource();

  bool _isRunning = false;

  /// Whether the foreground service is active.
  bool get isRunning => _isRunning;

  static bool get _isTest =>
      Platform.environment.containsKey('FLUTTER_TEST') ||
      Zone.current[#test.declarer] != null;

  /// Initializes notification options and foreground task configurations.
  Future<void> init() async {
    if (_isTest) return;
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'frecu_foreground_service',
          channelName: 'Frecu en segundo plano',
          channelDescription:
              'Mantiene activa la conexión de Frecu con la pantalla apagada.',
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
        ),
      );
    } on Object catch (e, st) {
      AppLogger.w('Failed to init foreground task: $e', e, st);
    }
  }

  /// Starts the foreground service displaying a persistent notification.
  Future<void> startService({
    required String roomName,
    required String status,
  }) async {
    _isRunning = true;
    if (_isTest) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await updateNotification(roomName: roomName, status: status);
        return;
      }

      await FlutterForegroundTask.startService(
        serviceId: 4780,
        notificationTitle: 'Frecu activa',
        notificationText: '$roomName · $status',
        callback: startForegroundCallback,
      );
    } on Object catch (e, st) {
      AppLogger.e('Failed to start foreground service', e, st);
    }
  }

  /// Updates the notification content while service is running.
  Future<void> updateNotification({
    required String roomName,
    required String status,
  }) async {
    if (!_isRunning) return;
    if (_isTest) return;

    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Frecu activa',
        notificationText: '$roomName · $status',
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
