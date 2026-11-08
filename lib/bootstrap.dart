import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/settings/domain/entities/locale_preference.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
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
  final container = await createAppContainer();
  await applySavedLocale(container);

  final app = await builder();
  runApp(
    TranslationProvider(
      child: UncontrolledProviderScope(container: container, child: app),
    ),
  );
}

/// Crea el contenedor de providers de la app con las preferencias ya leídas,
/// para que el primer cuadro use el tema guardado.
///
/// Si no se pueden leer, lo registra y devuelve el contenedor igualmente: la
/// app arranca con el tema del sistema.
Future<ProviderContainer> createAppContainer() async {
  final container = ProviderContainer();
  try {
    await container.read(preferencesProvider.future);
  } on Object catch (e, st) {
    AppLogger.e('Error preloading preferences', e, st);
  }
  return container;
}

/// Aplica el idioma guardado en las preferencias ya leídas de [container].
///
/// Auto, sin preferencias leídas o con un valor desconocido, usa el idioma
/// del teléfono.
Future<AppLocale> applySavedLocale(ProviderContainer container) =>
    applyLocalePreference(
      container.read(preferencesProvider).value?.localePreference ??
          LocalePreference.auto,
    );
