import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/data/datasources/audio_session_datasource.dart';
import 'package:frecu/features/room/data/datasources/peer_connection_datasource.dart';
import 'package:frecu/features/room/data/repositories/voice_repository_impl.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/link_quality.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';
import 'package:frecu/features/room/domain/repositories/voice_repository.dart';
import 'package:frecu/features/room/presentation/providers/room_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'voice_provider.g.dart';

/// Estado inmutable de voz y micrófono de la sala.
class VoiceState {
  /// Constructor con valores por defecto.
  const VoiceState({
    this.isTalking = false,
    this.voiceDetected = false,
    this.talkMode = TalkMode.pushToTalk,
    this.audioRoute = AudioRoute.speaker,
    this.availableAudioRoutes = const {AudioRoute.speaker, AudioRoute.earpiece},
    this.speakingPeers = const {},
    this.isInitialized = false,
    this.mutedPeers = const {},
    this.peerLinks = const {},
    this.peerQuality = const {},
    this.bluetoothName,
  });

  /// Indica si el micrófono local está transmitiendo audio.
  final bool isTalking;

  /// En micrófono abierto con el micrófono abierto, si se oye la voz propia
  /// (su nivel supera el umbral).
  final bool voiceDetected;

  /// La persona propia sale «hablando» en la malla: en PTT mientras
  /// transmite y en micrófono abierto solo mientras se oye su voz, igual que
  /// la ven los demás.
  bool get selfSpeaking => switch (talkMode) {
    TalkMode.pushToTalk => isTalking,
    TalkMode.openMic => isTalking && voiceDetected,
  };

  /// Modo de habla activo (PTT o micrófono abierto).
  final TalkMode talkMode;

  /// Ruta de salida de audio activa (altavoz, auricular, Bluetooth).
  final AudioRoute audioRoute;

  /// Conjunto de rutas de salida de audio disponibles en el dispositivo.
  final Set<AudioRoute> availableAudioRoutes;

  /// Conjunto de identificadores de participantes remotos hablando.
  final Set<String> speakingPeers;

  /// Indica si la sesión de audio ya fue inicializada.
  final bool isInitialized;

  /// Participantes remotos silenciados en micrófono abierto.
  final Set<String> mutedPeers;

  /// Estado del enlace de voz con cada participante remoto, por id.
  final Map<String, PeerConnectionState> peerLinks;

  /// Calidad del enlace de voz con cada participante remoto, por id; quien no
  /// aparece cuenta como bueno.
  final Map<String, LinkQuality> peerQuality;

  /// Nombre del dispositivo Bluetooth conectado, si hay uno.
  final String? bluetoothName;

  /// Crea una copia del estado con los campos proporcionados; [bluetoothName]
  /// se reemplaza siempre que se pase [clearBluetoothName] o un nombre.
  VoiceState copyWith({
    bool? isTalking,
    bool? voiceDetected,
    TalkMode? talkMode,
    AudioRoute? audioRoute,
    Set<AudioRoute>? availableAudioRoutes,
    Set<String>? speakingPeers,
    bool? isInitialized,
    Set<String>? mutedPeers,
    Map<String, PeerConnectionState>? peerLinks,
    Map<String, LinkQuality>? peerQuality,
    String? bluetoothName,
    bool clearBluetoothName = false,
  }) {
    return VoiceState(
      isTalking: isTalking ?? this.isTalking,
      voiceDetected: voiceDetected ?? this.voiceDetected,
      talkMode: talkMode ?? this.talkMode,
      audioRoute: audioRoute ?? this.audioRoute,
      availableAudioRoutes: availableAudioRoutes ?? this.availableAudioRoutes,
      speakingPeers: speakingPeers ?? this.speakingPeers,
      isInitialized: isInitialized ?? this.isInitialized,
      mutedPeers: mutedPeers ?? this.mutedPeers,
      peerLinks: peerLinks ?? this.peerLinks,
      peerQuality: peerQuality ?? this.peerQuality,
      bluetoothName: clearBluetoothName
          ? bluetoothName
          : bluetoothName ?? this.bluetoothName,
    );
  }
}

/// Proveedor global singleton del repositorio de voz.
@Riverpod(keepAlive: true)
VoiceRepository voiceRepository(Ref ref) {
  final signaling = ref.watch(signalingClientProvider);
  final audioSession = AudioSessionDataSource();
  final peerConnection = PeerConnectionDataSource(signalingClient: signaling);
  final repository = VoiceRepositoryImpl(
    audioSessionDataSource: audioSession,
    peerConnectionDataSource: peerConnection,
    signalingClientDataSource: signaling,
  );
  ref.onDispose(repository.dispose);
  return repository;
}

/// Stream reactivo de si el usuario local está transmitiendo audio.
@riverpod
Stream<bool> isTalking(Ref ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  return repository.watchIsTalking();
}

/// Stream reactivo de los participantes remotos que están hablando.
@riverpod
Stream<Set<String>> speakingPeers(Ref ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  return repository.watchSpeakingPeers();
}

/// Nivel de la voz propia en la escala del VU ([voiceMeterLevel]). WebRTC
/// solo se lee mientras alguien lo escucha: la frecu activa.
@riverpod
Stream<double> localVoiceLevel(Ref ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  return repository.watchLocalLevel().map(voiceMeterLevel);
}

/// Nivel de la voz recibida de cada participante remoto por su id, en la
/// escala del VU ([voiceMeterLevel]).
@riverpod
Stream<Map<String, double>> peerVoiceLevels(Ref ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  return repository.watchPeerLevels().map(
    (levels) => {
      for (final MapEntry(:key, :value) in levels.entries)
        key: voiceMeterLevel(value),
    },
  );
}

/// Pasa el `audioLevel` de WebRTC (amplitud lineal de 0 a 1) a la escala del
/// VU en decibelios: −48 dB o menos es 0, −24 dB es 0,5 y 0 dB es 1.
double voiceMeterLevel(double audioLevel) {
  if (audioLevel <= 0) return 0;
  final decibels = 20 * math.log(audioLevel) / math.ln10;
  return (1 + decibels / 48).clamp(0, 1).toDouble();
}

/// Stream reactivo del modo de habla actual.
@riverpod
Stream<TalkMode> talkMode(Ref ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  return repository.watchTalkMode();
}

/// Stream reactivo de la ruta de audio activa.
@riverpod
Stream<AudioRoute> audioRoute(Ref ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  return repository.watchAudioRoute();
}

/// Stream reactivo de las rutas de audio disponibles en el dispositivo.
@riverpod
Stream<Set<AudioRoute>> availableAudioRoutes(Ref ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  return repository.watchAvailableAudioRoutes();
}

/// Alias para consistencia de nomenclatura con la clase Notifier.
VoiceNotifierProvider get voiceNotifierProvider => voiceProvider;

/// Gestor de estado del micrófono y transmisión de voz.
@Riverpod(keepAlive: true)
class VoiceNotifier extends _$VoiceNotifier {
  @override
  VoiceState build() {
    final repository = ref.watch(voiceRepositoryProvider);

    final talkingSub = repository.watchIsTalking().listen((talking) {
      state = state.copyWith(isTalking: talking);
    });
    final speakingSub = repository.watchSpeakingPeers().listen((peers) {
      state = state.copyWith(speakingPeers: peers);
    });
    final modeSub = repository.watchTalkMode().listen((mode) {
      state = state.copyWith(talkMode: mode);
    });

    StreamSubscription<AudioRoute>? routeSub;
    try {
      routeSub = repository.watchAudioRoute().listen((route) {
        state = state.copyWith(audioRoute: route);
      });
    } on Object catch (_) {}

    StreamSubscription<Set<AudioRoute>>? availSub;
    try {
      availSub = repository.watchAvailableAudioRoutes().listen((routes) {
        state = state.copyWith(availableAudioRoutes: routes);
      });
    } on Object catch (_) {}

    // Un stream que falte (p. ej. un doble de pruebas) nunca rompe la frecu.
    final mutedSub = _follow(repository.watchMutedPeers, (peers) {
      state = state.copyWith(mutedPeers: peers);
    });
    final linksSub = _follow(repository.watchPeerLinks, (links) {
      state = state.copyWith(peerLinks: links);
    });
    final qualitySub = _follow(repository.watchPeerQuality, (quality) {
      state = state.copyWith(peerQuality: quality);
    });
    final bluetoothSub = _follow(repository.watchBluetoothName, (name) {
      state = state.copyWith(bluetoothName: name, clearBluetoothName: true);
    });
    final voiceSub = _follow(repository.watchVoiceDetected, (detected) {
      state = state.copyWith(voiceDetected: detected);
    });

    ref.onDispose(() {
      talkingSub.cancel();
      speakingSub.cancel();
      modeSub.cancel();
      routeSub?.cancel();
      availSub?.cancel();
      mutedSub?.cancel();
      linksSub?.cancel();
      qualitySub?.cancel();
      bluetoothSub?.cancel();
      voiceSub?.cancel();
    });

    return const VoiceState();
  }

  static StreamSubscription<T>? _follow<T>(
    Stream<T> Function() watch,
    void Function(T value) onData,
  ) {
    try {
      return watch().listen(onData, onError: (Object _) {});
    } on Object catch (_) {
      return null;
    }
  }

  /// Inicializa la captura y sesión de audio con permisos.
  Future<Result<void>> initialize() async {
    final repository = ref.read(voiceRepositoryProvider);
    final result = await repository.initializeAudio();
    if (result.isSuccess) {
      state = state.copyWith(isInitialized: true);
    }
    return result;
  }

  /// Inicia la transmisión de voz en el canal WebRTC.
  Future<Result<void>> startTalking() async {
    final repository = ref.read(voiceRepositoryProvider);
    return repository.startTalking();
  }

  /// Silencia el micrófono y detiene la transmisión de voz.
  Future<Result<void>> stopTalking() async {
    final repository = ref.read(voiceRepositoryProvider);
    return repository.stopTalking();
  }

  /// Alterna el estado del micrófono (silenciar / transmitir).
  Future<Result<void>> toggleMicrophone() async {
    if (state.isTalking) {
      return stopTalking();
    } else {
      return startTalking();
    }
  }

  /// Cambia el modo de habla (PTT o micrófono abierto) sin abrir el
  /// micrófono, como al aplicar el modo por defecto al entrar.
  Future<Result<void>> setTalkMode(TalkMode mode) async {
    final repository = ref.read(voiceRepositoryProvider);
    return repository.setTalkMode(mode);
  }

  /// Elige el modo en el selector: «Abierto» abre el micrófono al instante
  /// y «PTT» lo cierra.
  Future<Result<void>> chooseTalkMode(TalkMode mode) async {
    final result = await setTalkMode(mode);
    if (result.isFailure || mode != TalkMode.openMic) return result;
    return startTalking();
  }

  /// Conmuta la salida a la ruta de audio especificada.
  Future<Result<void>> setAudioRoute(AudioRoute route) async {
    final repository = ref.read(voiceRepositoryProvider);
    return repository.setAudioRoute(route);
  }

  /// Activa o desactiva la salida por el altavoz externo.
  Future<Result<void>> setSpeakerOn(bool enabled) async {
    final repository = ref.read(voiceRepositoryProvider);
    return repository.setSpeakerOn(enabled);
  }

  /// Abre los ajustes del sistema para conceder el micrófono.
  Future<bool> openMicrophoneSettings() =>
      ref.read(voiceRepositoryProvider).openMicrophoneSettings();

  /// Conmuta/cicla entre las rutas de audio disponibles en el dispositivo.
  Future<Result<void>> cycleAudioRoute() async {
    final available = state.availableAudioRoutes.toList();
    if (available.isEmpty) {
      return const Result.success(null);
    }
    final currentIndex = available.indexOf(state.audioRoute);
    final nextIndex = (currentIndex + 1) % available.length;
    return setAudioRoute(available[nextIndex]);
  }
}

/// Tiempo al aire de la transmisión PTT en curso: `Duration.zero` al
/// empezar, sube cada segundo y vuelve a nulo al soltar o al pasar a
/// micrófono abierto.
@riverpod
class OnAirClock extends _$OnAirClock {
  @override
  Duration? build() {
    final onAir = ref.watch(
      voiceNotifierProvider.select(
        (voice) => voice.isTalking && voice.talkMode == TalkMode.pushToTalk,
      ),
    );
    if (!onAir) return null;
    final timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => state = Duration(seconds: timer.tick),
    );
    ref.onDispose(timer.cancel);
    return Duration.zero;
  }
}
