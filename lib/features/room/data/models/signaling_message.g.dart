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
  protocolVersion: (json['protocolVersion'] as num?)?.toInt() ?? 1,
  type: json['type'] as String? ?? 'join',
);

Map<String, dynamic> _$SignalingJoinMessageToJson(
  SignalingJoinMessage instance,
) => <String, dynamic>{
  'displayName': instance.displayName,
  'accessCode': instance.accessCode,
  'protocolVersion': instance.protocolVersion,
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
  type: json['type'] as String? ?? 'welcome',
);

Map<String, dynamic> _$SignalingWelcomeMessageToJson(
  SignalingWelcomeMessage instance,
) => <String, dynamic>{
  'peerId': instance.peerId,
  'participants': instance.participants,
  'note': const RoomNoteConverter().toJson(instance.note),
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
  type: json['type'] as String? ?? 'talk_state',
);

Map<String, dynamic> _$SignalingTalkStateMessageToJson(
  SignalingTalkStateMessage instance,
) => <String, dynamic>{
  'peerId': instance.peerId,
  'isSpeaking': instance.isSpeaking,
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

SignalingRoomClosedMessage _$SignalingRoomClosedMessageFromJson(
  Map<String, dynamic> json,
) => SignalingRoomClosedMessage(
  reason: json['reason'] as String,
  type: json['type'] as String? ?? 'room_closed',
);

Map<String, dynamic> _$SignalingRoomClosedMessageToJson(
  SignalingRoomClosedMessage instance,
) => <String, dynamic>{'reason': instance.reason, 'type': instance.type};
