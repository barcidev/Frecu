// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nearby_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NearbyRoom {

 String get roomId; String get name; String get hostAddress; int get port; int get protocolVersion;/// Nota musical anunciada por el anfitrión; nula si no la publica.
@RoomNoteConverter() RoomNote? get note;/// Id del anfitrión por Bluetooth si la frecu se encontró solo por
/// Bluetooth: aún no se está en su red, así que [hostAddress] va vacío y
/// la invitación se pide por Bluetooth con el código.
 String? get bluetoothId;
/// Create a copy of NearbyRoom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NearbyRoomCopyWith<NearbyRoom> get copyWith => _$NearbyRoomCopyWithImpl<NearbyRoom>(this as NearbyRoom, _$identity);

  /// Serializes this NearbyRoom to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NearbyRoom&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.name, name) || other.name == name)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.port, port) || other.port == port)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.note, note) || other.note == note)&&(identical(other.bluetoothId, bluetoothId) || other.bluetoothId == bluetoothId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,name,hostAddress,port,protocolVersion,note,bluetoothId);

@override
String toString() {
  return 'NearbyRoom(roomId: $roomId, name: $name, hostAddress: $hostAddress, port: $port, protocolVersion: $protocolVersion, note: $note, bluetoothId: $bluetoothId)';
}


}

/// @nodoc
abstract mixin class $NearbyRoomCopyWith<$Res>  {
  factory $NearbyRoomCopyWith(NearbyRoom value, $Res Function(NearbyRoom) _then) = _$NearbyRoomCopyWithImpl;
@useResult
$Res call({
 String roomId, String name, String hostAddress, int port, int protocolVersion,@RoomNoteConverter() RoomNote? note, String? bluetoothId
});


$RoomNoteCopyWith<$Res>? get note;

}
/// @nodoc
class _$NearbyRoomCopyWithImpl<$Res>
    implements $NearbyRoomCopyWith<$Res> {
  _$NearbyRoomCopyWithImpl(this._self, this._then);

  final NearbyRoom _self;
  final $Res Function(NearbyRoom) _then;

/// Create a copy of NearbyRoom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? name = null,Object? hostAddress = null,Object? port = null,Object? protocolVersion = null,Object? note = freezed,Object? bluetoothId = freezed,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hostAddress: null == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,bluetoothId: freezed == bluetoothId ? _self.bluetoothId : bluetoothId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of NearbyRoom
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoomNoteCopyWith<$Res>? get note {
    if (_self.note == null) {
    return null;
  }

  return $RoomNoteCopyWith<$Res>(_self.note!, (value) {
    return _then(_self.copyWith(note: value));
  });
}
}


/// Adds pattern-matching-related methods to [NearbyRoom].
extension NearbyRoomPatterns on NearbyRoom {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NearbyRoom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NearbyRoom() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NearbyRoom value)  $default,){
final _that = this;
switch (_that) {
case _NearbyRoom():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NearbyRoom value)?  $default,){
final _that = this;
switch (_that) {
case _NearbyRoom() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  String name,  String hostAddress,  int port,  int protocolVersion, @RoomNoteConverter()  RoomNote? note,  String? bluetoothId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NearbyRoom() when $default != null:
return $default(_that.roomId,_that.name,_that.hostAddress,_that.port,_that.protocolVersion,_that.note,_that.bluetoothId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  String name,  String hostAddress,  int port,  int protocolVersion, @RoomNoteConverter()  RoomNote? note,  String? bluetoothId)  $default,) {final _that = this;
switch (_that) {
case _NearbyRoom():
return $default(_that.roomId,_that.name,_that.hostAddress,_that.port,_that.protocolVersion,_that.note,_that.bluetoothId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  String name,  String hostAddress,  int port,  int protocolVersion, @RoomNoteConverter()  RoomNote? note,  String? bluetoothId)?  $default,) {final _that = this;
switch (_that) {
case _NearbyRoom() when $default != null:
return $default(_that.roomId,_that.name,_that.hostAddress,_that.port,_that.protocolVersion,_that.note,_that.bluetoothId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NearbyRoom extends NearbyRoom {
  const _NearbyRoom({required this.roomId, required this.name, required this.hostAddress, required this.port, this.protocolVersion = 1, @RoomNoteConverter() this.note, this.bluetoothId}): super._();
  factory _NearbyRoom.fromJson(Map<String, dynamic> json) => _$NearbyRoomFromJson(json);

@override final  String roomId;
@override final  String name;
@override final  String hostAddress;
@override final  int port;
@override@JsonKey() final  int protocolVersion;
/// Nota musical anunciada por el anfitrión; nula si no la publica.
@override@RoomNoteConverter() final  RoomNote? note;
/// Id del anfitrión por Bluetooth si la frecu se encontró solo por
/// Bluetooth: aún no se está en su red, así que [hostAddress] va vacío y
/// la invitación se pide por Bluetooth con el código.
@override final  String? bluetoothId;

/// Create a copy of NearbyRoom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NearbyRoomCopyWith<_NearbyRoom> get copyWith => __$NearbyRoomCopyWithImpl<_NearbyRoom>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NearbyRoomToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NearbyRoom&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.name, name) || other.name == name)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.port, port) || other.port == port)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.note, note) || other.note == note)&&(identical(other.bluetoothId, bluetoothId) || other.bluetoothId == bluetoothId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,name,hostAddress,port,protocolVersion,note,bluetoothId);

@override
String toString() {
  return 'NearbyRoom(roomId: $roomId, name: $name, hostAddress: $hostAddress, port: $port, protocolVersion: $protocolVersion, note: $note, bluetoothId: $bluetoothId)';
}


}

/// @nodoc
abstract mixin class _$NearbyRoomCopyWith<$Res> implements $NearbyRoomCopyWith<$Res> {
  factory _$NearbyRoomCopyWith(_NearbyRoom value, $Res Function(_NearbyRoom) _then) = __$NearbyRoomCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String name, String hostAddress, int port, int protocolVersion,@RoomNoteConverter() RoomNote? note, String? bluetoothId
});


@override $RoomNoteCopyWith<$Res>? get note;

}
/// @nodoc
class __$NearbyRoomCopyWithImpl<$Res>
    implements _$NearbyRoomCopyWith<$Res> {
  __$NearbyRoomCopyWithImpl(this._self, this._then);

  final _NearbyRoom _self;
  final $Res Function(_NearbyRoom) _then;

/// Create a copy of NearbyRoom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? name = null,Object? hostAddress = null,Object? port = null,Object? protocolVersion = null,Object? note = freezed,Object? bluetoothId = freezed,}) {
  return _then(_NearbyRoom(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hostAddress: null == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,bluetoothId: freezed == bluetoothId ? _self.bluetoothId : bluetoothId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NearbyRoom
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoomNoteCopyWith<$Res>? get note {
    if (_self.note == null) {
    return null;
  }

  return $RoomNoteCopyWith<$Res>(_self.note!, (value) {
    return _then(_self.copyWith(note: value));
  });
}
}

// dart format on
