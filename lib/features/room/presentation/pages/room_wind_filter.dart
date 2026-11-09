import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/data/datasources/wind_filter_datasource.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';

/// Filtro de viento del micrófono.
final windFilterProvider = Provider<WindFilterDataSource>(
  (ref) => WindFilterDataSource(),
);

/// Filtro de viento en la frecu activa, según Ajustes (encendido por
/// defecto). Se engancha a WebRTC cuando la voz ya arrancó y se quita al
/// salir.
class RoomWindFilter {
  WindFilterDataSource? _filter;
  ProviderSubscription<(bool, bool)>? _watch;
  bool _on = false;

  /// Empieza a seguir la preferencia y el arranque de la voz con [ref] (en
  /// el `initState`).
  void start(WidgetRef ref) {
    _filter = ref.read(windFilterProvider);
    _watch = ref.listenManual<(bool, bool)>(
      _wanted,
      (_, next) => unawaited(_apply(wanted: next.$1 && next.$2)),
      fireImmediately: true,
    );
  }

  /// (Preferencia encendida, voz arrancada).
  static final _wanted = Provider.autoDispose<(bool, bool)>(
    (ref) => (
      ref.watch(preferencesProvider.select((p) => p.value?.windFilter ?? true)),
      ref.watch(voiceNotifierProvider.select((v) => v.isInitialized)),
    ),
  );

  Future<void> _apply({required bool wanted}) async {
    _wantedNow = wanted;
    final filter = _filter;
    if (filter == null || wanted == _on) return;
    // WebRTC crea su procesado con la primera conexión: hasta entonces no
    // hay dónde engancharse, así que se reintenta un rato.
    for (var attempt = 0; attempt < _attempts; attempt++) {
      if (_filter == null || _wantedNow != wanted) return;
      if (await filter.setEnabled(enabled: wanted)) {
        _on = wanted;
        return;
      }
      await Future<void>.delayed(retryEvery);
    }
  }

  /// Cada cuánto se reintenta enganchar el filtro.
  static const Duration retryEvery = Duration(seconds: 2);
  static const int _attempts = 30;
  bool _wantedNow = false;

  /// Quita el filtro y deja de escuchar (en el `dispose`).
  void stop() {
    _watch?.close();
    _watch = null;
    _wantedNow = false;
    if (_on) unawaited(_filter?.setEnabled(enabled: false));
    _on = false;
    _filter = null;
  }
}
