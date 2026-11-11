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
  note: const RoomNoteConverter().fromJson((json['note'] as num?)?.toInt()),
  name: json['name'] as String?,
  wifi: json['wifi'] == null
      ? null
      : WifiCredentials.fromJson(json['wifi'] as Map<String, dynamic>),
  internetId: json['internetId'] as String?,
);

Map<String, dynamic> _$RoomInviteToJson(_RoomInvite instance) =>
    <String, dynamic>{
      'host': instance.host,
      'port': instance.port,
      'roomId': instance.roomId,
      'accessCode': instance.accessCode,
      'note': const RoomNoteConverter().toJson(instance.note),
      'name': instance.name,
      'wifi': instance.wifi,
      'internetId': instance.internetId,
    };
