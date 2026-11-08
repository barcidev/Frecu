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

/// Nivel de la voz propia en la escala del VU ([voiceMeterLevel]). WebRTC
/// solo se lee mientras alguien lo escucha: la frecu activa.

@ProviderFor(localVoiceLevel)
final localVoiceLevelProvider = LocalVoiceLevelProvider._();

/// Nivel de la voz propia en la escala del VU ([voiceMeterLevel]). WebRTC
/// solo se lee mientras alguien lo escucha: la frecu activa.

final class LocalVoiceLevelProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  /// Nivel de la voz propia en la escala del VU ([voiceMeterLevel]). WebRTC
  /// solo se lee mientras alguien lo escucha: la frecu activa.
  LocalVoiceLevelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localVoiceLevelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localVoiceLevelHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return localVoiceLevel(ref);
  }
}

String _$localVoiceLevelHash() => r'35045d38d67d7016cdbddff651be53b40dd85fb0';

/// Nivel de la voz recibida de cada participante remoto por su id, en la
/// escala del VU ([voiceMeterLevel]).

@ProviderFor(peerVoiceLevels)
final peerVoiceLevelsProvider = PeerVoiceLevelsProvider._();

/// Nivel de la voz recibida de cada participante remoto por su id, en la
/// escala del VU ([voiceMeterLevel]).

final class PeerVoiceLevelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, double>>,
          Map<String, double>,
          Stream<Map<String, double>>
        >
    with
        $FutureModifier<Map<String, double>>,
        $StreamProvider<Map<String, double>> {
  /// Nivel de la voz recibida de cada participante remoto por su id, en la
  /// escala del VU ([voiceMeterLevel]).
  PeerVoiceLevelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'peerVoiceLevelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$peerVoiceLevelsHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, double>> create(Ref ref) {
    return peerVoiceLevels(ref);
  }
}

String _$peerVoiceLevelsHash() => r'20170cd572a41a9712d45988eac502989a107cf4';

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

/// Stream reactivo de la ruta de audio activa.

@ProviderFor(audioRoute)
final audioRouteProvider = AudioRouteProvider._();

/// Stream reactivo de la ruta de audio activa.

final class AudioRouteProvider
    extends
        $FunctionalProvider<
          AsyncValue<AudioRoute>,
          AudioRoute,
          Stream<AudioRoute>
        >
    with $FutureModifier<AudioRoute>, $StreamProvider<AudioRoute> {
  /// Stream reactivo de la ruta de audio activa.
  AudioRouteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioRouteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioRouteHash();

  @$internal
  @override
  $StreamProviderElement<AudioRoute> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AudioRoute> create(Ref ref) {
    return audioRoute(ref);
  }
}

String _$audioRouteHash() => r'6feeaa6ab44f1013656907a675e1a677859883d4';

/// Stream reactivo de las rutas de audio disponibles en el dispositivo.

@ProviderFor(availableAudioRoutes)
final availableAudioRoutesProvider = AvailableAudioRoutesProvider._();

/// Stream reactivo de las rutas de audio disponibles en el dispositivo.

final class AvailableAudioRoutesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<AudioRoute>>,
          Set<AudioRoute>,
          Stream<Set<AudioRoute>>
        >
    with $FutureModifier<Set<AudioRoute>>, $StreamProvider<Set<AudioRoute>> {
  /// Stream reactivo de las rutas de audio disponibles en el dispositivo.
  AvailableAudioRoutesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableAudioRoutesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableAudioRoutesHash();

  @$internal
  @override
  $StreamProviderElement<Set<AudioRoute>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<AudioRoute>> create(Ref ref) {
    return availableAudioRoutes(ref);
  }
}

String _$availableAudioRoutesHash() =>
    r'38cc50eb8e71f999d78eedbbb31fe96eec1220fd';

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

String _$voiceNotifierHash() => r'0badf71f1706d973e5a0168728b28031666a72d1';

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

/// Tiempo al aire de la transmisión PTT en curso: `Duration.zero` al
/// empezar, sube cada segundo y vuelve a nulo al soltar o al pasar a
/// micrófono abierto.

@ProviderFor(OnAirClock)
final onAirClockProvider = OnAirClockProvider._();

/// Tiempo al aire de la transmisión PTT en curso: `Duration.zero` al
/// empezar, sube cada segundo y vuelve a nulo al soltar o al pasar a
/// micrófono abierto.
final class OnAirClockProvider
    extends $NotifierProvider<OnAirClock, Duration?> {
  /// Tiempo al aire de la transmisión PTT en curso: `Duration.zero` al
  /// empezar, sube cada segundo y vuelve a nulo al soltar o al pasar a
  /// micrófono abierto.
  OnAirClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onAirClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onAirClockHash();

  @$internal
  @override
  OnAirClock create() => OnAirClock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration?>(value),
    );
  }
}

String _$onAirClockHash() => r'6a0761d1a311ff1d55a1fd222f6702d95aa377d5';

/// Tiempo al aire de la transmisión PTT en curso: `Duration.zero` al
/// empezar, sube cada segundo y vuelve a nulo al soltar o al pasar a
/// micrófono abierto.

abstract class _$OnAirClock extends $Notifier<Duration?> {
  Duration? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Duration?, Duration?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Duration?, Duration?>,
              Duration?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
