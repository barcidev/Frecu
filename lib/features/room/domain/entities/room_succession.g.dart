// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_succession.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomSuccession _$RoomSuccessionFromJson(Map<String, dynamic> json) =>
    _RoomSuccession(
      term: (json['term'] as num).toInt(),
      handover: json['handover'] as bool,
      name: json['name'] as String,
      accessCode: json['accessCode'] as String,
      members: (json['members'] as List<dynamic>)
          .map((e) => RoomMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: const RoomNoteConverter().fromJson((json['note'] as num?)?.toInt()),
      reach:
          $enumDecodeNullable(_$RoomReachEnumMap, json['reach']) ??
          RoomReach.local,
      internetId: json['internetId'] as String?,
      hostSecret: json['hostSecret'] as String?,
    );

Map<String, dynamic> _$RoomSuccessionToJson(_RoomSuccession instance) =>
    <String, dynamic>{
      'term': instance.term,
      'handover': instance.handover,
      'name': instance.name,
      'accessCode': instance.accessCode,
      'members': instance.members,
      'note': const RoomNoteConverter().toJson(instance.note),
      'reach': _$RoomReachEnumMap[instance.reach]!,
      'internetId': ?instance.internetId,
      'hostSecret': ?instance.hostSecret,
    };

const _$RoomReachEnumMap = {
  RoomReach.local: 'local',
  RoomReach.internet: 'internet',
};

_RoomMember _$RoomMemberFromJson(Map<String, dynamic> json) => _RoomMember(
  id: json['id'] as String,
  displayName: json['displayName'] as String,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
  address: json['address'] as String?,
);

Map<String, dynamic> _$RoomMemberToJson(_RoomMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'address': ?instance.address,
    };
