import 'package:frecu/features/room/domain/entities/link_quality.dart';
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

    /// Entró por internet (por el punto de encuentro), no por la red local.
    /// Lo pone el anfitrión; una app anterior no lo manda y vale `false`.
    @Default(false) bool remote,

    /// Su teléfono es la red de la frecu (la red de Frecu o su zona Wi-Fi):
    /// solo el anfitrión, y entonces la frecu no admite traspaso. Lo pone el
    /// anfitrión; una app anterior no lo manda y vale `false`.
    @Default(false) bool ownsNetwork,

    /// Calidad del enlace de voz que mide este teléfono; es local, así que
    /// no viaja en la señalización.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(LinkQuality.good)
    LinkQuality linkQuality,
  }) = _Participant;

  /// Deserializa desde JSON.
  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}
