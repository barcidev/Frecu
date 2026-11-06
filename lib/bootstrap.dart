import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Inicialización global, control de errores y montaje del árbol de widgets.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    AppLogger.e('FlutterError', details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('PlatformDispatcherError', error, stack);
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  await LocaleSettings.useDeviceLocale();

  final app = await builder();
  runApp(TranslationProvider(child: ProviderScope(child: app)));
}
