// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Room {

 String get id; String get name; String get hostAddress; int get port; String get accessCode; DateTime get createdAt; int get maxParticipants;/// Nota musical de la frecu, calculada con su hora de apertura.
@RoomNoteConverter() RoomNote? get note;/// Red de la frecu, si el anfitrión la creó con Frecu: la que creó este
/// teléfono o la que traía la invitación. Va en el QR para invitar.
 WifiCredentials? get wifi;/// Si este teléfono la creó (es el anfitrión). Solo vale en este
/// teléfono: no viaja en JSON.
@JsonKey(includeFromJson: false, includeToJson: false) bool get hosting;
/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomCopyWith<Room> get copyWith => _$RoomCopyWithImpl<Room>(this as Room, _$identity);

  /// Serializes this Room to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Room&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.port, port) || other.port == port)&&(identical(other.accessCode, accessCode) || other.accessCode == accessCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.note, note) || other.note == note)&&(identical(other.wifi, wifi) || other.wifi == wifi)&&(identical(other.hosting, hosting) || other.hosting == hosting));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hostAddress,port,accessCode,createdAt,maxParticipants,note,wifi,hosting);

@override
String toString() {
  return 'Room(id: $id, name: $name, hostAddress: $hostAddress, port: $port, accessCode: $accessCode, createdAt: $createdAt, maxParticipants: $maxParticipants, note: $note, wifi: $wifi, hosting: $hosting)';
}


}

/// @nodoc
abstract mixin class $RoomCopyWith<$Res>  {
  factory $RoomCopyWith(Room value, $Res Function(Room) _then) = _$RoomCopyWithImpl;
@useResult
$Res call({
 String id, String name, String hostAddress, int port, String accessCode, DateTime createdAt, int maxParticipants,@RoomNoteConverter() RoomNote? note, WifiCredentials? wifi,@JsonKey(includeFromJson: false, includeToJson: false) bool hosting
});


$RoomNoteCopyWith<$Res>? get note;$WifiCredentialsCopyWith<$Res>? get wifi;

}
/// @nodoc
class _$RoomCopyWithImpl<$Res>
    implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._self, this._then);

  final Room _self;
  final $Res Function(Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? hostAddress = null,Object? port = null,Object? accessCode = null,Object? createdAt = null,Object? maxParticipants = null,Object? note = freezed,Object? wifi = freezed,Object? hosting = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hostAddress: null == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,accessCode: null == accessCode ? _self.accessCode : accessCode // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,wifi: freezed == wifi ? _self.wifi : wifi // ignore: cast_nullable_to_non_nullable
as WifiCredentials?,hosting: null == hosting ? _self.hosting : hosting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Room
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
}/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WifiCredentialsCopyWith<$Res>? get wifi {
    if (_self.wifi == null) {
    return null;
  }

  return $WifiCredentialsCopyWith<$Res>(_self.wifi!, (value) {
    return _then(_self.copyWith(wifi: value));
  });
}
}


/// Adds pattern-matching-related methods to [Room].
extension RoomPatterns on Room {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Room value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Room() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Room value)  $default,){
final _that = this;
switch (_that) {
case _Room():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Room value)?  $default,){
final _that = this;
switch (_that) {
case _Room() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String hostAddress,  int port,  String accessCode,  DateTime createdAt,  int maxParticipants, @RoomNoteConverter()  RoomNote? note,  WifiCredentials? wifi, @JsonKey(includeFromJson: false, includeToJson: false)  bool hosting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.name,_that.hostAddress,_that.port,_that.accessCode,_that.createdAt,_that.maxParticipants,_that.note,_that.wifi,_that.hosting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String hostAddress,  int port,  String accessCode,  DateTime createdAt,  int maxParticipants, @RoomNoteConverter()  RoomNote? note,  WifiCredentials? wifi, @JsonKey(includeFromJson: false, includeToJson: false)  bool hosting)  $default,) {final _that = this;
switch (_that) {
case _Room():
return $default(_that.id,_that.name,_that.hostAddress,_that.port,_that.accessCode,_that.createdAt,_that.maxParticipants,_that.note,_that.wifi,_that.hosting);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String hostAddress,  int port,  String accessCode,  DateTime createdAt,  int maxParticipants, @RoomNoteConverter()  RoomNote? note,  WifiCredentials? wifi, @JsonKey(includeFromJson: false, includeToJson: false)  bool hosting)?  $default,) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.name,_that.hostAddress,_that.port,_that.accessCode,_that.createdAt,_that.maxParticipants,_that.note,_that.wifi,_that.hosting);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Room implements Room {
  const _Room({required this.id, required this.name, required this.hostAddress, required this.port, required this.accessCode, required this.createdAt, this.maxParticipants = 6, @RoomNoteConverter() this.note, this.wifi, @JsonKey(includeFromJson: false, includeToJson: false) this.hosting = false});
  factory _Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

@override final  String id;
@override final  String name;
@override final  String hostAddress;
@override final  int port;
@override final  String accessCode;
@override final  DateTime createdAt;
@override@JsonKey() final  int maxParticipants;
/// Nota musical de la frecu, calculada con su hora de apertura.
@override@RoomNoteConverter() final  RoomNote? note;
/// Red de la frecu, si el anfitrión la creó con Frecu: la que creó este
/// teléfono o la que traía la invitación. Va en el QR para invitar.
@override final  WifiCredentials? wifi;
/// Si este teléfono la creó (es el anfitrión). Solo vale en este
/// teléfono: no viaja en JSON.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool hosting;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomCopyWith<_Room> get copyWith => __$RoomCopyWithImpl<_Room>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Room&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.port, port) || other.port == port)&&(identical(other.accessCode, accessCode) || other.accessCode == accessCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.maxParticipants, maxParticipants) || other.maxParticipants == maxParticipants)&&(identical(other.note, note) || other.note == note)&&(identical(other.wifi, wifi) || other.wifi == wifi)&&(identical(other.hosting, hosting) || other.hosting == hosting));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hostAddress,port,accessCode,createdAt,maxParticipants,note,wifi,hosting);

@override
String toString() {
  return 'Room(id: $id, name: $name, hostAddress: $hostAddress, port: $port, accessCode: $accessCode, createdAt: $createdAt, maxParticipants: $maxParticipants, note: $note, wifi: $wifi, hosting: $hosting)';
}


}

/// @nodoc
abstract mixin class _$RoomCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$RoomCopyWith(_Room value, $Res Function(_Room) _then) = __$RoomCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String hostAddress, int port, String accessCode, DateTime createdAt, int maxParticipants,@RoomNoteConverter() RoomNote? note, WifiCredentials? wifi,@JsonKey(includeFromJson: false, includeToJson: false) bool hosting
});


@override $RoomNoteCopyWith<$Res>? get note;@override $WifiCredentialsCopyWith<$Res>? get wifi;

}
/// @nodoc
class __$RoomCopyWithImpl<$Res>
    implements _$RoomCopyWith<$Res> {
  __$RoomCopyWithImpl(this._self, this._then);

  final _Room _self;
  final $Res Function(_Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? hostAddress = null,Object? port = null,Object? accessCode = null,Object? createdAt = null,Object? maxParticipants = null,Object? note = freezed,Object? wifi = freezed,Object? hosting = null,}) {
  return _then(_Room(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hostAddress: null == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,accessCode: null == accessCode ? _self.accessCode : accessCode // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,maxParticipants: null == maxParticipants ? _self.maxParticipants : maxParticipants // ignore: cast_nullable_to_non_nullable
as int,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,wifi: freezed == wifi ? _self.wifi : wifi // ignore: cast_nullable_to_non_nullable
as WifiCredentials?,hosting: null == hosting ? _self.hosting : hosting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Room
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
}/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WifiCredentialsCopyWith<$Res>? get wifi {
    if (_self.wifi == null) {
    return null;
  }

  return $WifiCredentialsCopyWith<$Res>(_self.wifi!, (value) {
    return _then(_self.copyWith(wifi: value));
  });
}
}

// dart format on
