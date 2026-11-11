import 'dart:convert';

import 'package:frecu/features/room/domain/entities/participant.dart';
import 'package:frecu/features/room/domain/entities/room_note.dart';
import 'package:frecu/features/room/domain/entities/room_succession.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'signaling_message.freezed.dart';
part 'signaling_message.g.dart';

/// Versión del protocolo de señalización que habla esta app (`v` del TXT y
/// `protocolVersion` del `join`). Los campos aditivos no la cambian.
const int signalingProtocolVersion = 1;

/// Unión sellada para todos los mensajes de señalización del protocolo Frecu.
@Freezed(unionKey: 'type', makeCollectionsUnmodifiable: false)
sealed class SignalingMessage with _$SignalingMessage {
  /// Solicitud de unión a la sala enviada por un participante al anfitrión.
  /// Con [peerId] (aditivo), vuelve a su lugar en la frecu que heredó otro
  /// anfitrión, con su mismo id y su mismo orden de sucesión. Con [term]
  /// (aditivo), el turno de la sucesión que conoce: un servidor con un turno
  /// menor lo rechaza con `stale_term`.
  const factory SignalingMessage.join({
    required String displayName,
    required String accessCode,
    @Default(signalingProtocolVersion) int protocolVersion,
    @JsonKey(includeIfNull: false) String? peerId,
    @JsonKey(includeIfNull: false) int? term,
    @Default('join') String type,
  }) = SignalingJoinMessage;

  /// Bienvenida enviada por el anfitrión al participante aceptado, con el
  /// nombre de la frecu (`roomName`, aditivo: nulo si el anfitrión es de una
  /// versión anterior).
  const factory SignalingMessage.welcome({
    required String peerId,
    required List<Participant> participants,
    @RoomNoteConverter() RoomNote? note,
    @JsonKey(includeIfNull: false) String? roomName,
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

  /// Estado de habla (PTT o micrófono activo) de un participante; `muted`
  /// (aditivo) es `true` si se silenció en micrófono abierto.
  @FreezedUnionValue('talk_state')
  const factory SignalingMessage.talkState({
    required String peerId,
    required bool isSpeaking,
    @JsonKey(includeIfNull: false) bool? muted,
    @Default('talk_state') String type,
  }) = SignalingTalkStateMessage;

  /// Mensaje rápido para toda la frecu: [kind] es el nombre de uno de los
  /// mensajes predefinidos (`behind`, `stop`, `fuel`, `ok`, `onMyWay`) o
  /// `sos`. El anfitrión lo reenvía a todos menos a quien lo envía, con
  /// [peerId] forzado al remitente. Un tipo desconocido se ignora al
  /// recibirlo, así que se pueden sumar tipos sin cambiar la versión.
  @FreezedUnionValue('quick_message')
  const factory SignalingMessage.quickMessage({
    required String peerId,
    required String kind,
    @Default('quick_message') String type,
  }) = SignalingQuickMessage;

  /// Posición de quien comparte su ubicación: [lat] y [lon] en grados y
  /// [accuracy] en metros. Sin [lat] ni [lon] avisa que dejó de compartirla.
  /// El anfitrión la reenvía a todos menos a quien la envía, con [peerId]
  /// forzado al remitente.
  @FreezedUnionValue('position')
  const factory SignalingMessage.position({
    required String peerId,
    @JsonKey(includeIfNull: false) double? lat,
    @JsonKey(includeIfNull: false) double? lon,
    @JsonKey(includeIfNull: false) double? accuracy,
    @Default('position') String type,
  }) = SignalingPositionMessage;

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

  /// Sucesión, turno y estado de la frecu ([state]): el anfitrión lo envía a
  /// todos al entrar alguien y en cada cambio. Es aditivo: una app anterior
  /// no lo conoce y lo descarta.
  @FreezedUnionValue('room_state')
  const factory SignalingMessage.roomState({
    required RoomSuccession state,
    @Default('room_state') String type,
  }) = SignalingRoomStateMessage;

  /// El anfitrión pasa la frecu a [to] y sale: quien la recibe la abre con
  /// el turno [term], y los demás se reconectan a su IP con su mismo id. Con
  /// [address] y [port] (aditivos), la frecu ya la lleva [to] allí: así va
  /// quien no lo tiene en su sucesión. Es aditivo: una app anterior lo
  /// descarta.
  @FreezedUnionValue('host_handover')
  const factory SignalingMessage.hostHandover({
    required String to,
    required int term,
    @JsonKey(includeIfNull: false) String? address,
    @JsonKey(includeIfNull: false) int? port,
    @Default('host_handover') String type,
  }) = SignalingHostHandoverMessage;

  /// Un anfitrión pregunta a otro servidor si lleva la misma frecu
  /// ([accessCode]), con su turno [term], su id [host] y el [port] de su
  /// servidor; el otro responde con el suyo. Gana el turno mayor y, a igual
  /// turno, el `peer_N` menor: el otro entra como invitado. Es aditivo.
  @FreezedUnionValue('host_probe')
  const factory SignalingMessage.hostProbe({
    required String accessCode,
    required int term,
    required String host,
    required int port,
    @Default('host_probe') String type,
  }) = SignalingHostProbeMessage;

  /// Quien tomó la frecu ([host], con el turno [term]) se lo dice a cada
  /// persona que vuelve: [reason] es `left` si el anfitrión anterior se la
  /// pasó al salir y `lost` si se cayó. Es aditivo.
  @FreezedUnionValue('host_changed')
  const factory SignalingMessage.hostChanged({
    required String host,
    required int term,
    required String reason,
    @Default('host_changed') String type,
  }) = SignalingHostChangedMessage;

  /// Notificación de cierre de sala.
  @FreezedUnionValue('room_closed')
  const factory SignalingMessage.roomClosed({
    required String reason,
    @Default('room_closed') String type,
  }) = SignalingRoomClosedMessage;

  /// Deserializa un mensaje desde JSON.
  factory SignalingMessage.fromJson(Map<String, dynamic> json) =>
      _$SignalingMessageFromJson(json);

  /// Lee un mensaje de texto del socket; nulo si no es un mensaje válido.
  static SignalingMessage? tryDecode(Object? data) {
    if (data is! String) return null;
    try {
      return SignalingMessage.fromJson(
        jsonDecode(data) as Map<String, dynamic>,
      );
    } on Object {
      return null;
    }
  }
}
