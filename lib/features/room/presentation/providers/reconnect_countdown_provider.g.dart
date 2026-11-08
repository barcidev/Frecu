// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconnect_countdown_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Segundos que faltan para el próximo intento de reconexión («Reconectando
/// · 4 s»), o nulo si la frecu no reconecta. Baja cada segundo hasta 0, que
/// es mientras se intenta.

@ProviderFor(ReconnectCountdown)
final reconnectCountdownProvider = ReconnectCountdownProvider._();

/// Segundos que faltan para el próximo intento de reconexión («Reconectando
/// · 4 s»), o nulo si la frecu no reconecta. Baja cada segundo hasta 0, que
/// es mientras se intenta.
final class ReconnectCountdownProvider
    extends $NotifierProvider<ReconnectCountdown, int?> {
  /// Segundos que faltan para el próximo intento de reconexión («Reconectando
  /// · 4 s»), o nulo si la frecu no reconecta. Baja cada segundo hasta 0, que
  /// es mientras se intenta.
  ReconnectCountdownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reconnectCountdownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reconnectCountdownHash();

  @$internal
  @override
  ReconnectCountdown create() => ReconnectCountdown();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$reconnectCountdownHash() =>
    r'c16d97c2d432a1842f492a804fb5ef8fd1ef0a32';

/// Segundos que faltan para el próximo intento de reconexión («Reconectando
/// · 4 s»), o nulo si la frecu no reconecta. Baja cada segundo hasta 0, que
/// es mientras se intenta.

abstract class _$ReconnectCountdown extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
