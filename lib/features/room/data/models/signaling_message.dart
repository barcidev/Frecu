import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:frecu/features/room/domain/entities/participant.dart';

part 'signaling_message.freezed.dart';
part 'signaling_message.g.dart';

/// Unión sellada para todos los mensajes de señalización del protocolo Frecu.
@Freezed(unionKey: 'type', makeCollectionsUnmodifiable: false)
sealed class SignalingMessage with _$SignalingMessage {
  /// Solicitud de unión a la sala enviada por un participante al anfitrión.
  const factory SignalingMessage.join({
    required String displayName,
    required String accessCode,
    @Default(1) int protocolVersion,
    @Default('join') String type,
  }) = SignalingJoinMessage;

  /// Bienvenida enviada por el anfitrión al participante aceptado.
  const factory SignalingMessage.welcome({
    required String peerId,
    required List<Participant> participants,
    @Default('welcome') String type,
  }) = SignalingWelcomeMessage;

  /// Rechazo de la solicitud de unión.
  const factory SignalingMessage.rejected({
    required String reason,
    @Default('rejected') String type,
  }) = SignalingRejectedMessage;

  /// Notificación de nuevo participante enviada a todos en la sala.
  @FreezedUnionValue('peer_joined')
  const factory SignalingMessage.peerJoined({
    required Participant participant,
    @Default('peer_joined') String type,
  }) = SignalingPeerJoinedMessage;

  /// Notificación de participante que abandonó la sala.
  @FreezedUnionValue('peer_left')
  const factory SignalingMessage.peerLeft({
    required String peerId,
    @Default('peer_left') String type,
  }) = SignalingPeerLeftMessage;

  /// Oferta SDP de WebRTC de un par hacia otro (enrutada por el host).
  const factory SignalingMessage.offer({
    required String from,
    required String to,
    required String sdp,
    @Default('offer') String type,
  }) = SignalingOfferMessage;

  /// Respuesta SDP de WebRTC de un par hacia otro (enrutada por el host).
  const factory SignalingMessage.answer({
    required String from,
    required String to,
    required String sdp,
    @Default('answer') String type,
  }) = SignalingAnswerMessage;

  /// Candidato ICE de WebRTC intercambiado entre pares.
  const factory SignalingMessage.ice({
    required String from,
    required String to,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
    @Default('ice') String type,
  }) = SignalingIceMessage;

  /// Estado de habla (PTT o micrófono activo) de un participante.
  @FreezedUnionValue('talk_state')
  const factory SignalingMessage.talkState({
    required String peerId,
    required bool isSpeaking,
    @Default('talk_state') String type,
  }) = SignalingTalkStateMessage;

  /// Latido enviado para comprobar liveness.
  const factory SignalingMessage.ping({
    required int timestamp,
    @Default('ping') String type,
  }) = SignalingPingMessage;

  /// Respuesta a latido.
  const factory SignalingMessage.pong({
    required int timestamp,
    @Default('pong') String type,
  }) = SignalingPongMessage;

  /// Notificación de cierre de sala.
  @FreezedUnionValue('room_closed')
  const factory SignalingMessage.roomClosed({
    required String reason,
    @Default('room_closed') String type,
  }) = SignalingRoomClosedMessage;

  /// Deserializa un mensaje desde JSON.
  factory SignalingMessage.fromJson(Map<String, dynamic> json) =>
      _$SignalingMessageFromJson(json);
}
