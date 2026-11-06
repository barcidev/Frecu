// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_invite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomInvite _$RoomInviteFromJson(Map<String, dynamic> json) => _RoomInvite(
  host: json['host'] as String,
  port: (json['port'] as num).toInt(),
  roomId: json['roomId'] as String,
  accessCode: json['accessCode'] as String,
);

Map<String, dynamic> _$RoomInviteToJson(_RoomInvite instance) =>
    <String, dynamic>{
      'host': instance.host,
      'port': instance.port,
      'roomId': instance.roomId,
      'accessCode': instance.accessCode,
    };
