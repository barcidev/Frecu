import 'package:freezed_annotation/freezed_annotation.dart';

part 'participant.freezed.dart';
part 'participant.g.dart';

/// Estado de conexión de un participante.
enum PeerConnectionState {
  /// Inicial o desconectado.
  disconnected,

  /// Estableciendo conexión.
  connecting,

  /// Conectado activamente.
  connected,

  /// Reintentando conexión.
  reconnecting,
}

/// Representa a un participante dentro de una frecu (sala).
@freezed
sealed class Participant with _$Participant {
  /// Constructor de la entidad inmutable.
  const factory Participant({
    required String id,
    required String displayName,
    @Default(false) bool isHost,
    @Default(false) bool isSpeaking,
    @Default(false) bool isMuted,
    @Default(PeerConnectionState.connected) PeerConnectionState connectionState,
  }) = _Participant;

  /// Deserializa desde JSON.
  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}
