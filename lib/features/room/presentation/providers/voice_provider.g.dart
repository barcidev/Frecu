// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Proveedor global singleton del repositorio de voz.

@ProviderFor(voiceRepository)
final voiceRepositoryProvider = VoiceRepositoryProvider._();

/// Proveedor global singleton del repositorio de voz.

final class VoiceRepositoryProvider
    extends
        $FunctionalProvider<VoiceRepository, VoiceRepository, VoiceRepository>
    with $Provider<VoiceRepository> {
  /// Proveedor global singleton del repositorio de voz.
  VoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<VoiceRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VoiceRepository create(Ref ref) {
    return voiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceRepository>(value),
    );
  }
}

String _$voiceRepositoryHash() => r'959dae60dbbb72f1934353346d5a70658326d39e';

/// Stream reactivo de si el usuario local está transmitiendo audio.

@ProviderFor(isTalking)
final isTalkingProvider = IsTalkingProvider._();

/// Stream reactivo de si el usuario local está transmitiendo audio.

final class IsTalkingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Stream reactivo de si el usuario local está transmitiendo audio.
  IsTalkingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isTalkingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isTalkingHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return isTalking(ref);
  }
}

String _$isTalkingHash() => r'2aba2b272c702dc8b89f510af1b79e9d043e3d86';

/// Stream reactivo de los participantes remotos que están hablando.

@ProviderFor(speakingPeers)
final speakingPeersProvider = SpeakingPeersProvider._();

/// Stream reactivo de los participantes remotos que están hablando.

final class SpeakingPeersProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// Stream reactivo de los participantes remotos que están hablando.
  SpeakingPeersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speakingPeersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speakingPeersHash();

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    return speakingPeers(ref);
  }
}

String _$speakingPeersHash() => r'c35086769e29f11e8c45700e7f1413d84e7fb1c8';

/// Stream reactivo del modo de habla actual.

@ProviderFor(talkMode)
final talkModeProvider = TalkModeProvider._();

/// Stream reactivo del modo de habla actual.

final class TalkModeProvider
    extends
        $FunctionalProvider<AsyncValue<TalkMode>, TalkMode, Stream<TalkMode>>
    with $FutureModifier<TalkMode>, $StreamProvider<TalkMode> {
  /// Stream reactivo del modo de habla actual.
  TalkModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'talkModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$talkModeHash();

  @$internal
  @override
  $StreamProviderElement<TalkMode> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<TalkMode> create(Ref ref) {
    return talkMode(ref);
  }
}

String _$talkModeHash() => r'db4fe0595803f0b9eca0a5e0ba97795069b2bda3';

/// Gestor de estado del micrófono y transmisión de voz.

@ProviderFor(VoiceNotifier)
final voiceProvider = VoiceNotifierProvider._();

/// Gestor de estado del micrófono y transmisión de voz.
final class VoiceNotifierProvider
    extends $NotifierProvider<VoiceNotifier, VoiceState> {
  /// Gestor de estado del micrófono y transmisión de voz.
  VoiceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceNotifierHash();

  @$internal
  @override
  VoiceNotifier create() => VoiceNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoiceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoiceState>(value),
    );
  }
}

String _$voiceNotifierHash() => r'016a63bbb7f93e561bcf99b817cde868666d76ce';

/// Gestor de estado del micrófono y transmisión de voz.

abstract class _$VoiceNotifier extends $Notifier<VoiceState> {
  VoiceState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VoiceState, VoiceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VoiceState, VoiceState>,
              VoiceState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
