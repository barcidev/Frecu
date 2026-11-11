// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signaling_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignalingJoinMessage _$SignalingJoinMessageFromJson(
  Map<String, dynamic> json,
) => SignalingJoinMessage(
  displayName: json['displayName'] as String,
  accessCode: json['accessCode'] as String,
  protocolVersion:
      (json['protocolVersion'] as num?)?.toInt() ?? signalingProtocolVersion,
  peerId: json['peerId'] as String?,
  term: (json['term'] as num?)?.toInt(),
  type: json['type'] as String? ?? 'join',
);

Map<String, dynamic> _$SignalingJoinMessageToJson(
  SignalingJoinMessage instance,
) => <String, dynamic>{
  'displayName': instance.displayName,
  'accessCode': instance.accessCode,
  'protocolVersion': instance.protocolVersion,
  'peerId': ?instance.peerId,
  'term': ?instance.term,
  'type': instance.type,
};

SignalingWelcomeMessage _$SignalingWelcomeMessageFromJson(
  Map<String, dynamic> json,
) => SignalingWelcomeMessage(
  peerId: json['peerId'] as String,
  participants: (json['participants'] as List<dynamic>)
      .map((e) => Participant.fromJson(e as Map<String, dynamic>))
      .toList(),
  note: const RoomNoteConverter().fromJson((json['note'] as num?)?.toInt()),
  roomName: json['roomName'] as String?,
  type: json['type'] as String? ?? 'welcome',
);

Map<String, dynamic> _$SignalingWelcomeMessageToJson(
  SignalingWelcomeMessage instance,
) => <String, dynamic>{
  'peerId': instance.peerId,
  'participants': instance.participants,
  'note': const RoomNoteConverter().toJson(instance.note),
  'roomName': ?instance.roomName,
  'type': instance.type,
};

SignalingRejectedMessage _$SignalingRejectedMessageFromJson(
  Map<String, dynamic> json,
) => SignalingRejectedMessage(
  reason: json['reason'] as String,
  type: json['type'] as String? ?? 'rejected',
);

Map<String, dynamic> _$SignalingRejectedMessageToJson(
  SignalingRejectedMessage instance,
) => <String, dynamic>{'reason': instance.reason, 'type': instance.type};

SignalingPeerJoinedMessage _$SignalingPeerJoinedMessageFromJson(
  Map<String, dynamic> json,
) => SignalingPeerJoinedMessage(
  participant: Participant.fromJson(
    json['participant'] as Map<String, dynamic>,
  ),
  type: json['type'] as String? ?? 'peer_joined',
);

Map<String, dynamic> _$SignalingPeerJoinedMessageToJson(
  SignalingPeerJoinedMessage instance,
) => <String, dynamic>{
  'participant': instance.participant,
  'type': instance.type,
};

SignalingPeerLeftMessage _$SignalingPeerLeftMessageFromJson(
  Map<String, dynamic> json,
) => SignalingPeerLeftMessage(
  peerId: json['peerId'] as String,
  type: json['type'] as String? ?? 'peer_left',
);

Map<String, dynamic> _$SignalingPeerLeftMessageToJson(
  SignalingPeerLeftMessage instance,
) => <String, dynamic>{'peerId': instance.peerId, 'type': instance.type};

SignalingOfferMessage _$SignalingOfferMessageFromJson(
  Map<String, dynamic> json,
) => SignalingOfferMessage(
  from: json['from'] as String,
  to: json['to'] as String,
  sdp: json['sdp'] as String,
  type: json['type'] as String? ?? 'offer',
);

Map<String, dynamic> _$SignalingOfferMessageToJson(
  SignalingOfferMessage instance,
) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'sdp': instance.sdp,
  'type': instance.type,
};

SignalingAnswerMessage _$SignalingAnswerMessageFromJson(
  Map<String, dynamic> json,
) => SignalingAnswerMessage(
  from: json['from'] as String,
  to: json['to'] as String,
  sdp: json['sdp'] as String,
  type: json['type'] as String? ?? 'answer',
);

Map<String, dynamic> _$SignalingAnswerMessageToJson(
  SignalingAnswerMessage instance,
) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'sdp': instance.sdp,
  'type': instance.type,
};

SignalingIceMessage _$SignalingIceMessageFromJson(Map<String, dynamic> json) =>
    SignalingIceMessage(
      from: json['from'] as String,
      to: json['to'] as String,
      candidate: json['candidate'] as String,
      sdpMid: json['sdpMid'] as String?,
      sdpMLineIndex: (json['sdpMLineIndex'] as num?)?.toInt(),
      type: json['type'] as String? ?? 'ice',
    );

Map<String, dynamic> _$SignalingIceMessageToJson(
  SignalingIceMessage instance,
) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'candidate': instance.candidate,
  'sdpMid': instance.sdpMid,
  'sdpMLineIndex': instance.sdpMLineIndex,
  'type': instance.type,
};

SignalingTalkStateMessage _$SignalingTalkStateMessageFromJson(
  Map<String, dynamic> json,
) => SignalingTalkStateMessage(
  peerId: json['peerId'] as String,
  isSpeaking: json['isSpeaking'] as bool,
  muted: json['muted'] as bool?,
  type: json['type'] as String? ?? 'talk_state',
);

Map<String, dynamic> _$SignalingTalkStateMessageToJson(
  SignalingTalkStateMessage instance,
) => <String, dynamic>{
  'peerId': instance.peerId,
  'isSpeaking': instance.isSpeaking,
  'muted': ?instance.muted,
  'type': instance.type,
};

SignalingQuickMessage _$SignalingQuickMessageFromJson(
  Map<String, dynamic> json,
) => SignalingQuickMessage(
  peerId: json['peerId'] as String,
  kind: json['kind'] as String,
  type: json['type'] as String? ?? 'quick_message',
);

Map<String, dynamic> _$SignalingQuickMessageToJson(
  SignalingQuickMessage instance,
) => <String, dynamic>{
  'peerId': instance.peerId,
  'kind': instance.kind,
  'type': instance.type,
};

SignalingPositionMessage _$SignalingPositionMessageFromJson(
  Map<String, dynamic> json,
) => SignalingPositionMessage(
  peerId: json['peerId'] as String,
  lat: (json['lat'] as num?)?.toDouble(),
  lon: (json['lon'] as num?)?.toDouble(),
  accuracy: (json['accuracy'] as num?)?.toDouble(),
  type: json['type'] as String? ?? 'position',
);

Map<String, dynamic> _$SignalingPositionMessageToJson(
  SignalingPositionMessage instance,
) => <String, dynamic>{
  'peerId': instance.peerId,
  'lat': ?instance.lat,
  'lon': ?instance.lon,
  'accuracy': ?instance.accuracy,
  'type': instance.type,
};

SignalingPingMessage _$SignalingPingMessageFromJson(
  Map<String, dynamic> json,
) => SignalingPingMessage(
  timestamp: (json['timestamp'] as num).toInt(),
  type: json['type'] as String? ?? 'ping',
);

Map<String, dynamic> _$SignalingPingMessageToJson(
  SignalingPingMessage instance,
) => <String, dynamic>{'timestamp': instance.timestamp, 'type': instance.type};

SignalingPongMessage _$SignalingPongMessageFromJson(
  Map<String, dynamic> json,
) => SignalingPongMessage(
  timestamp: (json['timestamp'] as num).toInt(),
  type: json['type'] as String? ?? 'pong',
);

Map<String, dynamic> _$SignalingPongMessageToJson(
  SignalingPongMessage instance,
) => <String, dynamic>{'timestamp': instance.timestamp, 'type': instance.type};

SignalingRoomStateMessage _$SignalingRoomStateMessageFromJson(
  Map<String, dynamic> json,
) => SignalingRoomStateMessage(
  state: RoomSuccession.fromJson(json['state'] as Map<String, dynamic>),
  type: json['type'] as String? ?? 'room_state',
);

Map<String, dynamic> _$SignalingRoomStateMessageToJson(
  SignalingRoomStateMessage instance,
) => <String, dynamic>{'state': instance.state, 'type': instance.type};

SignalingHostHandoverMessage _$SignalingHostHandoverMessageFromJson(
  Map<String, dynamic> json,
) => SignalingHostHandoverMessage(
  to: json['to'] as String,
  term: (json['term'] as num).toInt(),
  address: json['address'] as String?,
  port: (json['port'] as num?)?.toInt(),
  type: json['type'] as String? ?? 'host_handover',
);

Map<String, dynamic> _$SignalingHostHandoverMessageToJson(
  SignalingHostHandoverMessage instance,
) => <String, dynamic>{
  'to': instance.to,
  'term': instance.term,
  'address': ?instance.address,
  'port': ?instance.port,
  'type': instance.type,
};

SignalingHostProbeMessage _$SignalingHostProbeMessageFromJson(
  Map<String, dynamic> json,
) => SignalingHostProbeMessage(
  accessCode: json['accessCode'] as String,
  term: (json['term'] as num).toInt(),
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  type: json['type'] as String? ?? 'host_probe',
);

Map<String, dynamic> _$SignalingHostProbeMessageToJson(
  SignalingHostProbeMessage instance,
) => <String, dynamic>{
  'accessCode': instance.accessCode,
  'term': instance.term,
  'host': instance.host,
  'port': instance.port,
  'type': instance.type,
};

SignalingHostChangedMessage _$SignalingHostChangedMessageFromJson(
  Map<String, dynamic> json,
) => SignalingHostChangedMessage(
  host: json['host'] as String,
  term: (json['term'] as num).toInt(),
  reason: json['reason'] as String,
  type: json['type'] as String? ?? 'host_changed',
);

Map<String, dynamic> _$SignalingHostChangedMessageToJson(
  SignalingHostChangedMessage instance,
) => <String, dynamic>{
  'host': instance.host,
  'term': instance.term,
  'reason': instance.reason,
  'type': instance.type,
};

SignalingRoomClosedMessage _$SignalingRoomClosedMessageFromJson(
  Map<String, dynamic> json,
) => SignalingRoomClosedMessage(
  reason: json['reason'] as String,
  type: json['type'] as String? ?? 'room_closed',
);

Map<String, dynamic> _$SignalingRoomClosedMessageToJson(
  SignalingRoomClosedMessage instance,
) => <String, dynamic>{'reason': instance.reason, 'type': instance.type};
