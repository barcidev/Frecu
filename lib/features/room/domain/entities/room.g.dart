// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Room _$RoomFromJson(Map<String, dynamic> json) => _Room(
  id: json['id'] as String,
  name: json['name'] as String,
  hostAddress: json['hostAddress'] as String,
  port: (json['port'] as num).toInt(),
  accessCode: json['accessCode'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 6,
  note: const RoomNoteConverter().fromJson((json['note'] as num?)?.toInt()),
  wifi: json['wifi'] == null
      ? null
      : WifiCredentials.fromJson(json['wifi'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RoomToJson(_Room instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hostAddress': instance.hostAddress,
  'port': instance.port,
  'accessCode': instance.accessCode,
  'createdAt': instance.createdAt.toIso8601String(),
  'maxParticipants': instance.maxParticipants,
  'note': const RoomNoteConverter().toJson(instance.note),
  'wifi': instance.wifi,
};
