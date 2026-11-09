import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/logging/app_logger.dart';
import 'package:frecu/features/room/data/datasources/volume_buttons_datasource.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/presentation/providers/voice_provider.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';

/// Botones de volumen del teléfono (Android).
final volumeButtonsProvider = Provider<VolumeButtonsDataSource>(
  (ref) => VolumeButtonsDataSource(),
);

/// Hablar con el botón de volumen en la frecu activa, si la persona lo activó
/// en Ajustes (solo Android).
///
/// - En PTT, con la app al frente: pulsar habla y soltar calla; con la
///   pantalla apagada, cada pulsación empieza o termina.
/// - En micrófono abierto, cada pulsación silencia o abre el micrófono.
class RoomVolumePtt {
  StreamSubscription<VolumeKeyEvent>? _events;
  ProviderSubscription<bool>? _preference;
  VolumeButtonsDataSource? _buttons;

  /// Empieza a seguir la preferencia con [ref] (en el `initState`).
  void start(WidgetRef ref) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _buttons = ref.read(volumeButtonsProvider);
    _preference = ref.listenManual<bool>(
      preferencesProvider.select((p) => p.value?.volumePtt ?? false),
      (_, enabled) => _apply(ref, enabled: enabled),
      fireImmediately: true,
    );
  }

  void _apply(WidgetRef ref, {required bool enabled}) {
    final buttons = _buttons;
    if (buttons == null) return;
    unawaited(buttons.setEnabled(enabled: enabled));
    if (!enabled) {
      unawaited(_events?.cancel());
      _events = null;
      return;
    }
    _events ??= buttons.watch().listen((event) => _onKey(ref, event));
  }

  void _onKey(WidgetRef ref, VolumeKeyEvent event) {
    AppLogger.d('Volume PTT: ${event.name}');
    final voice = ref.read(voiceNotifierProvider.notifier);
    final ptt = ref.read(voiceNotifierProvider).talkMode == TalkMode.pushToTalk;
    final action = switch (event) {
      VolumeKeyEvent.down when ptt => voice.startTalking(),
      VolumeKeyEvent.up when ptt => voice.stopTalking(),
      VolumeKeyEvent.up => null,
      VolumeKeyEvent.down || VolumeKeyEvent.toggle => voice.toggleMicrophone(),
    };
    if (action != null) unawaited(action);
  }

  /// Deja de escuchar y devuelve los botones al volumen (en el `dispose`).
  void stop() {
    _preference?.close();
    _preference = null;
    unawaited(_events?.cancel());
    _events = null;
    final buttons = _buttons;
    if (buttons != null) unawaited(buttons.setEnabled(enabled: false));
  }
}
