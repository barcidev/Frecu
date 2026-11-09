import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/features/room/data/datasources/proximity_datasource.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';

/// Sensor de proximidad del teléfono.
final proximityProvider = Provider<ProximityDataSource>(
  (ref) => ProximityDataSource(),
);

/// Auricular al acercar: con el audio por el altavoz, llevarse el teléfono
/// a la oreja lo pasa al auricular (y apaga la pantalla); al alejarlo vuelve
/// al altavoz.
///
/// Solo con la app al frente: en el bolsillo el sensor también está «cerca»
/// y no hay que quitar el altavoz. Con audífonos no se usa. Se apaga en
/// Ajustes.
class RoomProximity {
  ProximityDataSource? _sensor;
  StreamSubscription<bool>? _readings;
  final List<ProviderSubscription<Object?>> _watches = [];
  AppLifecycleListener? _lifecycle;
  bool _foreground = true;
  bool _enabled = false;

  /// Pasó al auricular por el sensor (y debe volver al altavoz al alejar).
  bool _switched = false;

  /// Empieza a seguir la preferencia, la salida de audio y si la app está al
  /// frente con [ref] (en el `initState`).
  void start(WidgetRef ref) {
    _sensor = ref.read(proximityProvider);
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        _sync(ref);
      },
    );
    _watches
      ..add(
        ref.listenManual<bool>(
          preferencesProvider.select((p) => p.value?.earpieceOnRaise ?? true),
          (_, _) => _sync(ref),
        ),
      )
      ..add(
        ref.listenManual<AudioRoute>(
          voiceNotifierProvider.select((voice) => voice.audioRoute),
          (_, _) => _sync(ref),
          fireImmediately: true,
        ),
      );
  }

  /// Activa el sensor solo cuando puede servir.
  void _sync(WidgetRef ref) {
    final sensor = _sensor;
    if (sensor == null) return;
    final route = ref.read(voiceNotifierProvider).audioRoute;
    final wanted =
        _foreground &&
        (ref.read(preferencesProvider).value?.earpieceOnRaise ?? true) &&
        (route == AudioRoute.speaker ||
            (_switched && route == AudioRoute.earpiece));
    if (wanted == _enabled) return;
    _enabled = wanted;
    unawaited(sensor.setEnabled(enabled: wanted));
    if (wanted) {
      _readings ??= sensor.watch().listen((near) => _onReading(ref, near));
    } else {
      unawaited(_readings?.cancel());
      _readings = null;
      _restore(ref);
    }
  }

  void _onReading(WidgetRef ref, bool near) {
    final voice = ref.read(voiceNotifierProvider);
    if (near && voice.audioRoute == AudioRoute.speaker) {
      _switched = true;
      unawaited(
        ref
            .read(voiceNotifierProvider.notifier)
            .setAudioRoute(AudioRoute.earpiece),
      );
    } else if (!near) {
      _restore(ref);
    }
  }

  /// Vuelve al altavoz si fue el sensor quien lo quitó.
  void _restore(WidgetRef ref) {
    if (!_switched) return;
    _switched = false;
    if (ref.read(voiceNotifierProvider).audioRoute != AudioRoute.earpiece) {
      return;
    }
    unawaited(
      ref
          .read(voiceNotifierProvider.notifier)
          .setAudioRoute(AudioRoute.speaker),
    );
  }

  /// Apaga el sensor y deja de escuchar (en el `dispose`).
  void stop() {
    for (final watch in _watches) {
      watch.close();
    }
    _watches.clear();
    _lifecycle?.dispose();
    _lifecycle = null;
    unawaited(_readings?.cancel());
    _readings = null;
    if (_enabled) unawaited(_sensor?.setEnabled(enabled: false));
    _enabled = false;
  }
}
