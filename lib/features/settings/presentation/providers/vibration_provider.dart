import 'package:frecu/core/haptics/haptics.dart';
import 'package:frecu/features/settings/presentation/providers/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'vibration_provider.g.dart';

/// Vibración nativa del teléfono.
@Riverpod(keepAlive: true)
Haptics haptics(Ref ref) => Haptics();

/// Vibra con los avisos de la frecu solo si la persona no la apagó en
/// Ajustes (encendida por defecto, también mientras las preferencias cargan).
@Riverpod(keepAlive: true)
Vibration vibration(Ref ref) => Vibration(
  ref.watch(hapticsProvider),
  enabled: () => ref.read(preferencesProvider).value?.vibration ?? true,
);

/// Vibración que respeta la preferencia de Ajustes.
class Vibration {
  /// Crea la vibración sobre [haptics]; [enabled] dice si está encendida.
  Vibration(this._haptics, {required this.enabled});

  final Haptics _haptics;

  /// Si la vibración está encendida en Ajustes.
  final bool Function() enabled;

  /// Vibra con [pattern] si está encendida.
  Future<void> call(HapticPattern pattern) async {
    if (!enabled()) return;
    await _haptics.play(pattern);
  }
}
