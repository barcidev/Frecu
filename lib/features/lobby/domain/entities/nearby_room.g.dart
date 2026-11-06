// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NearbyRoom _$NearbyRoomFromJson(Map<String, dynamic> json) => _NearbyRoom(
  roomId: json['roomId'] as String,
  name: json['name'] as String,
  hostAddress: json['hostAddress'] as String,
  port: (json['port'] as num).toInt(),
  protocolVersion: (json['protocolVersion'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$NearbyRoomToJson(_NearbyRoom instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'name': instance.name,
      'hostAddress': instance.hostAddress,
      'port': instance.port,
      'protocolVersion': instance.protocolVersion,
    };
