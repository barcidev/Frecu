// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vibration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Vibración nativa del teléfono.

@ProviderFor(haptics)
final hapticsProvider = HapticsProvider._();

/// Vibración nativa del teléfono.

final class HapticsProvider
    extends $FunctionalProvider<Haptics, Haptics, Haptics>
    with $Provider<Haptics> {
  /// Vibración nativa del teléfono.
  HapticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hapticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hapticsHash();

  @$internal
  @override
  $ProviderElement<Haptics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Haptics create(Ref ref) {
    return haptics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Haptics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Haptics>(value),
    );
  }
}

String _$hapticsHash() => r'3643a952e9ec54ab489db91aeb4029447129fdbc';

/// Vibra con los avisos de la frecu solo si la persona no la apagó en
/// Ajustes (encendida por defecto, también mientras las preferencias cargan).

@ProviderFor(vibration)
final vibrationProvider = VibrationProvider._();

/// Vibra con los avisos de la frecu solo si la persona no la apagó en
/// Ajustes (encendida por defecto, también mientras las preferencias cargan).

final class VibrationProvider
    extends $FunctionalProvider<Vibration, Vibration, Vibration>
    with $Provider<Vibration> {
  /// Vibra con los avisos de la frecu solo si la persona no la apagó en
  /// Ajustes (encendida por defecto, también mientras las preferencias cargan).
  VibrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'vibrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vibrationHash();

  @$internal
  @override
  $ProviderElement<Vibration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Vibration create(Ref ref) {
    return vibration(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Vibration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Vibration>(value),
    );
  }
}

String _$vibrationHash() => r'ac2428ca9331bf1597b30d52199b4b0cfc7e0a7c';
