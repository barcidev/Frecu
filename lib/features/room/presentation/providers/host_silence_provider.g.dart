// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'host_silence_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Espera de la frecu activa si su anfitrión dejó de responder y la frecu
/// admite traspaso ([HostSilence.find]), o nula. La sucesión se lee al
/// cambiar el estado: es la que mandó el anfitrión antes de caerse.

@ProviderFor(hostSilence)
final hostSilenceProvider = HostSilenceProvider._();

/// Espera de la frecu activa si su anfitrión dejó de responder y la frecu
/// admite traspaso ([HostSilence.find]), o nula. La sucesión se lee al
/// cambiar el estado: es la que mandó el anfitrión antes de caerse.

final class HostSilenceProvider
    extends $FunctionalProvider<HostSilence?, HostSilence?, HostSilence?>
    with $Provider<HostSilence?> {
  /// Espera de la frecu activa si su anfitrión dejó de responder y la frecu
  /// admite traspaso ([HostSilence.find]), o nula. La sucesión se lee al
  /// cambiar el estado: es la que mandó el anfitrión antes de caerse.
  HostSilenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostSilenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostSilenceHash();

  @$internal
  @override
  $ProviderElement<HostSilence?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HostSilence? create(Ref ref) {
    return hostSilence(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HostSilence? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HostSilence?>(value),
    );
  }
}

String _$hostSilenceHash() => r'26cc5221477511703e245f8a633e569bbb7ff18d';

/// Segundos que lleva sin responder el anfitrión de la espera («Andrés no
/// responde · 3 s»), o nulo sin espera. Sube cada segundo desde 0 y vuelve
/// a empezar con otra espera.

@ProviderFor(HostSilenceClock)
final hostSilenceClockProvider = HostSilenceClockProvider._();

/// Segundos que lleva sin responder el anfitrión de la espera («Andrés no
/// responde · 3 s»), o nulo sin espera. Sube cada segundo desde 0 y vuelve
/// a empezar con otra espera.
final class HostSilenceClockProvider
    extends $NotifierProvider<HostSilenceClock, int?> {
  /// Segundos que lleva sin responder el anfitrión de la espera («Andrés no
  /// responde · 3 s»), o nulo sin espera. Sube cada segundo desde 0 y vuelve
  /// a empezar con otra espera.
  HostSilenceClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostSilenceClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostSilenceClockHash();

  @$internal
  @override
  HostSilenceClock create() => HostSilenceClock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$hostSilenceClockHash() => r'd2eec936f7a5d3ed5d32c042bbe7fec1422058f0';

/// Segundos que lleva sin responder el anfitrión de la espera («Andrés no
/// responde · 3 s»), o nulo sin espera. Sube cada segundo desde 0 y vuelve
/// a empezar con otra espera.

abstract class _$HostSilenceClock extends $Notifier<int?> {
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
