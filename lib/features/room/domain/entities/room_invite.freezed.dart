// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomInvite {

 String get host; int get port; String get roomId; String get accessCode;/// Nota musical de la frecu; nula si la invitación no la trae.
@RoomNoteConverter() RoomNote? get note;
/// Create a copy of RoomInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomInviteCopyWith<RoomInvite> get copyWith => _$RoomInviteCopyWithImpl<RoomInvite>(this as RoomInvite, _$identity);

  /// Serializes this RoomInvite to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomInvite&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.accessCode, accessCode) || other.accessCode == accessCode)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,host,port,roomId,accessCode,note);

@override
String toString() {
  return 'RoomInvite(host: $host, port: $port, roomId: $roomId, accessCode: $accessCode, note: $note)';
}


}

/// @nodoc
abstract mixin class $RoomInviteCopyWith<$Res>  {
  factory $RoomInviteCopyWith(RoomInvite value, $Res Function(RoomInvite) _then) = _$RoomInviteCopyWithImpl;
@useResult
$Res call({
 String host, int port, String roomId, String accessCode,@RoomNoteConverter() RoomNote? note
});


$RoomNoteCopyWith<$Res>? get note;

}
/// @nodoc
class _$RoomInviteCopyWithImpl<$Res>
    implements $RoomInviteCopyWith<$Res> {
  _$RoomInviteCopyWithImpl(this._self, this._then);

  final RoomInvite _self;
  final $Res Function(RoomInvite) _then;

/// Create a copy of RoomInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? host = null,Object? port = null,Object? roomId = null,Object? accessCode = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,accessCode: null == accessCode ? _self.accessCode : accessCode // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,
  ));
}
/// Create a copy of RoomInvite
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


/// Adds pattern-matching-related methods to [RoomInvite].
extension RoomInvitePatterns on RoomInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomInvite value)  $default,){
final _that = this;
switch (_that) {
case _RoomInvite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomInvite value)?  $default,){
final _that = this;
switch (_that) {
case _RoomInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String host,  int port,  String roomId,  String accessCode, @RoomNoteConverter()  RoomNote? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomInvite() when $default != null:
return $default(_that.host,_that.port,_that.roomId,_that.accessCode,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String host,  int port,  String roomId,  String accessCode, @RoomNoteConverter()  RoomNote? note)  $default,) {final _that = this;
switch (_that) {
case _RoomInvite():
return $default(_that.host,_that.port,_that.roomId,_that.accessCode,_that.note);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String host,  int port,  String roomId,  String accessCode, @RoomNoteConverter()  RoomNote? note)?  $default,) {final _that = this;
switch (_that) {
case _RoomInvite() when $default != null:
return $default(_that.host,_that.port,_that.roomId,_that.accessCode,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomInvite implements RoomInvite {
  const _RoomInvite({required this.host, required this.port, required this.roomId, required this.accessCode, @RoomNoteConverter() this.note});
  factory _RoomInvite.fromJson(Map<String, dynamic> json) => _$RoomInviteFromJson(json);

@override final  String host;
@override final  int port;
@override final  String roomId;
@override final  String accessCode;
/// Nota musical de la frecu; nula si la invitación no la trae.
@override@RoomNoteConverter() final  RoomNote? note;

/// Create a copy of RoomInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomInviteCopyWith<_RoomInvite> get copyWith => __$RoomInviteCopyWithImpl<_RoomInvite>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomInviteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomInvite&&(identical(other.host, host) || other.host == host)&&(identical(other.port, port) || other.port == port)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.accessCode, accessCode) || other.accessCode == accessCode)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,host,port,roomId,accessCode,note);

@override
String toString() {
  return 'RoomInvite(host: $host, port: $port, roomId: $roomId, accessCode: $accessCode, note: $note)';
}


}

/// @nodoc
abstract mixin class _$RoomInviteCopyWith<$Res> implements $RoomInviteCopyWith<$Res> {
  factory _$RoomInviteCopyWith(_RoomInvite value, $Res Function(_RoomInvite) _then) = __$RoomInviteCopyWithImpl;
@override @useResult
$Res call({
 String host, int port, String roomId, String accessCode,@RoomNoteConverter() RoomNote? note
});


@override $RoomNoteCopyWith<$Res>? get note;

}
/// @nodoc
class __$RoomInviteCopyWithImpl<$Res>
    implements _$RoomInviteCopyWith<$Res> {
  __$RoomInviteCopyWithImpl(this._self, this._then);

  final _RoomInvite _self;
  final $Res Function(_RoomInvite) _then;

/// Create a copy of RoomInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? host = null,Object? port = null,Object? roomId = null,Object? accessCode = null,Object? note = freezed,}) {
  return _then(_RoomInvite(
host: null == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,accessCode: null == accessCode ? _self.accessCode : accessCode // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,
  ));
}

/// Create a copy of RoomInvite
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
