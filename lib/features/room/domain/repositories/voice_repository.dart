import 'package:frecu/core/result/result.dart';
import 'package:frecu/features/room/domain/entities/audio_route.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/talk_mode.dart';

/// Contrato del repositorio para la captura, transmisión y gestión de voz.
abstract interface class VoiceRepository {
  /// Pide el permiso del micrófono, activa la sesión de audio y captura el
  /// micrófono, una sola vez por frecu: llamarlo de nuevo devuelve el mismo
  /// resultado.
  Future<Result<void>> initializeAudio();

  /// Une la voz de este teléfono a la malla de la frecu activa como
  /// [localPeerId] y ofrece enlace a [peerIds], los que ya estaban.
  ///
  /// Es idempotente por frecu: con el mismo id no hace nada; con otro (al
  /// reconectar) rehace los enlaces con el id nuevo.
  Future<void> joinMesh({
    required String localPeerId,
    required List<String> peerIds,
  });

  /// Sale de la malla: cierra los enlaces, suelta el micrófono y la sesión
  /// de audio, deja de transmitir y olvida quién habla.
  Future<void> leaveMesh();

  /// Inicia la transmisión de voz en el canal WebRTC.
  Future<Result<void>> startTalking();

  /// Detiene la transmisión de voz (silencia el micrófono).
  Future<Result<void>> stopTalking();

  /// Cambia el modo de habla (PTT o micrófono abierto) sin abrir el
  /// micrófono: el micrófono abierto empieza en silencio.
  Future<Result<void>> setTalkMode(TalkMode mode);

  /// Conmuta la salida de audio a la ruta seleccionada.
  Future<Result<void>> setAudioRoute(AudioRoute route);

  /// Activa o desactiva la salida por el altavoz externo.
  Future<Result<void>> setSpeakerOn(bool enabled);

  /// Stream reactivo que emite si el usuario local está hablando/transmitiendo.
  Stream<bool> watchIsTalking();

  /// En micrófono abierto con el micrófono abierto, si se oye la voz propia
  /// (su nivel supera el umbral, con retención); falso en PTT o con el
  /// micrófono cerrado. Empieza con el valor actual. Es lo que se anuncia
  /// a la frecu como `talk_state` en micrófono abierto.
  Stream<bool> watchVoiceDetected();

  /// Stream reactivo del conjunto de IDs de participantes remotos que están
  /// hablando: en PTT mientras transmiten y en micrófono abierto mientras su
  /// teléfono detecta su voz.
  Stream<Set<String>> watchSpeakingPeers();

  /// Ids de los participantes remotos que se silenciaron en micrófono
  /// abierto; empieza con el valor actual.
  Stream<Set<String>> watchMutedPeers();

  /// Estado del enlace de voz con cada participante remoto, por id; empieza
  /// con el valor actual. Quien no aparece aún no tiene enlace.
  Stream<Map<String, PeerConnectionState>> watchPeerLinks();

  /// Nivel de la voz propia, de 0 a 1, medido por WebRTC. Se lee solo
  /// mientras alguien escucha este flujo o [watchPeerLevels].
  Stream<double> watchLocalLevel();

  /// Nivel de la voz recibida de cada participante remoto por su id, de 0 a
  /// 1, medido por WebRTC. Se lee solo mientras alguien escucha.
  Stream<Map<String, double>> watchPeerLevels();

  /// Stream reactivo del modo de habla actual.
  Stream<TalkMode> watchTalkMode();

  /// Stream reactivo de la ruta de salida de audio activa.
  Stream<AudioRoute> watchAudioRoute();

  /// Stream reactivo del conjunto de rutas de audio disponibles en el dispositivo.
  Stream<Set<AudioRoute>> watchAvailableAudioRoutes();

  /// Nombre del dispositivo Bluetooth conectado (p. ej. «Sena 50S»), o nulo
  /// si no hay; empieza con el valor actual.
  Stream<String?> watchBluetoothName();

  /// Abre los ajustes de la app en el sistema, para conceder el micrófono.
  Future<bool> openMicrophoneSettings();

  /// Libera recursos y cierra pistas de audio y conexiones de voz.
  Future<void> dispose();
}
