import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:frecu/i18n/strings.g.dart';

/// Nombre con el que esta persona crea una frecu o se une a ella: el que
/// guardó en el recorrido de la primera vez o cambió en Ajustes, sin volver a
/// pedirlo.
///
/// Las preferencias ya están leídas al llegar al inicio (se precargan al
/// arrancar); se lee al tocar el botón, así que vale el último nombre.
extension SavedDisplayName on WidgetRef {
  /// Nombre guardado, o nulo si aún no hay uno.
  String? get savedDisplayName => read(preferencesProvider).value?.displayName;

  /// Nombre para unirse: el guardado o, si aún no hay uno, «Participante»
  /// en el idioma de la app.
  String get joinDisplayName => savedDisplayName ?? t.lobby.join.defaultName;
}
