// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Participant _$ParticipantFromJson(Map<String, dynamic> json) => _Participant(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  isHost: json['isHost'] as bool? ?? false,
  isSpeaking: json['isSpeaking'] as bool? ?? false,
  isMuted: json['isMuted'] as bool? ?? false,
  connectionState:
      $enumDecodeNullable(
        _$PeerConnectionStateEnumMap,
        json['connectionState'],
      ) ??
      PeerConnectionState.connected,
  remote: json['remote'] as bool? ?? false,
  ownsNetwork: json['ownsNetwork'] as bool? ?? false,
);

Map<String, dynamic> _$ParticipantToJson(
  _Participant instance,
) => <String, dynamic>{
  'id': instance.id,
  'displayName': instance.displayName,
  'isHost': instance.isHost,
  'isSpeaking': instance.isSpeaking,
  'isMuted': instance.isMuted,
  'connectionState': _$PeerConnectionStateEnumMap[instance.connectionState]!,
  'remote': instance.remote,
  'ownsNetwork': instance.ownsNetwork,
};

const _$PeerConnectionStateEnumMap = {
  PeerConnectionState.disconnected: 'disconnected',
  PeerConnectionState.connecting: 'connecting',
  PeerConnectionState.connected: 'connected',
  PeerConnectionState.reconnecting: 'reconnecting',
};
