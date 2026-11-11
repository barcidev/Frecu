// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_succession.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomSuccession {

/// Turno del anfitrión vigente: 1 al abrir la frecu; sube con cada
/// traspaso y, entre dos anfitriones, gana el mayor.
 int get term;/// La frecu sobrevive a la salida del anfitrión.
 bool get handover;/// Nombre de la frecu.
 String get name;/// Código de acceso de la frecu.
 String get accessCode;/// Quienes están en la frecu, en orden de sucesión (de llegada): el
/// anfitrión primero.
 List<RoomMember> get members;/// Nota musical de la frecu.
@RoomNoteConverter() RoomNote? get note;/// Cómo se une el grupo: local o por internet.
 RoomReach get reach;/// Id de la frecu en el punto de encuentro, si es por internet.
@JsonKey(includeIfNull: false) String? get internetId;/// Secreto de anfitrión en el punto de encuentro, si es por internet:
/// con él, el sucesor toma la frecu.
@JsonKey(includeIfNull: false) String? get hostSecret;
/// Create a copy of RoomSuccession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomSuccessionCopyWith<RoomSuccession> get copyWith => _$RoomSuccessionCopyWithImpl<RoomSuccession>(this as RoomSuccession, _$identity);

  /// Serializes this RoomSuccession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomSuccession&&(identical(other.term, term) || other.term == term)&&(identical(other.handover, handover) || other.handover == handover)&&(identical(other.name, name) || other.name == name)&&(identical(other.accessCode, accessCode) || other.accessCode == accessCode)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.note, note) || other.note == note)&&(identical(other.reach, reach) || other.reach == reach)&&(identical(other.internetId, internetId) || other.internetId == internetId)&&(identical(other.hostSecret, hostSecret) || other.hostSecret == hostSecret));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,handover,name,accessCode,const DeepCollectionEquality().hash(members),note,reach,internetId,hostSecret);

@override
String toString() {
  return 'RoomSuccession(term: $term, handover: $handover, name: $name, accessCode: $accessCode, members: $members, note: $note, reach: $reach, internetId: $internetId, hostSecret: $hostSecret)';
}


}

/// @nodoc
abstract mixin class $RoomSuccessionCopyWith<$Res>  {
  factory $RoomSuccessionCopyWith(RoomSuccession value, $Res Function(RoomSuccession) _then) = _$RoomSuccessionCopyWithImpl;
@useResult
$Res call({
 int term, bool handover, String name, String accessCode, List<RoomMember> members,@RoomNoteConverter() RoomNote? note, RoomReach reach,@JsonKey(includeIfNull: false) String? internetId,@JsonKey(includeIfNull: false) String? hostSecret
});


$RoomNoteCopyWith<$Res>? get note;

}
/// @nodoc
class _$RoomSuccessionCopyWithImpl<$Res>
    implements $RoomSuccessionCopyWith<$Res> {
  _$RoomSuccessionCopyWithImpl(this._self, this._then);

  final RoomSuccession _self;
  final $Res Function(RoomSuccession) _then;

/// Create a copy of RoomSuccession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? term = null,Object? handover = null,Object? name = null,Object? accessCode = null,Object? members = null,Object? note = freezed,Object? reach = null,Object? internetId = freezed,Object? hostSecret = freezed,}) {
  return _then(_self.copyWith(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as int,handover: null == handover ? _self.handover : handover // ignore: cast_nullable_to_non_nullable
as bool,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,accessCode: null == accessCode ? _self.accessCode : accessCode // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<RoomMember>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,reach: null == reach ? _self.reach : reach // ignore: cast_nullable_to_non_nullable
as RoomReach,internetId: freezed == internetId ? _self.internetId : internetId // ignore: cast_nullable_to_non_nullable
as String?,hostSecret: freezed == hostSecret ? _self.hostSecret : hostSecret // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RoomSuccession
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


/// Adds pattern-matching-related methods to [RoomSuccession].
extension RoomSuccessionPatterns on RoomSuccession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomSuccession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomSuccession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomSuccession value)  $default,){
final _that = this;
switch (_that) {
case _RoomSuccession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomSuccession value)?  $default,){
final _that = this;
switch (_that) {
case _RoomSuccession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int term,  bool handover,  String name,  String accessCode,  List<RoomMember> members, @RoomNoteConverter()  RoomNote? note,  RoomReach reach, @JsonKey(includeIfNull: false)  String? internetId, @JsonKey(includeIfNull: false)  String? hostSecret)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomSuccession() when $default != null:
return $default(_that.term,_that.handover,_that.name,_that.accessCode,_that.members,_that.note,_that.reach,_that.internetId,_that.hostSecret);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int term,  bool handover,  String name,  String accessCode,  List<RoomMember> members, @RoomNoteConverter()  RoomNote? note,  RoomReach reach, @JsonKey(includeIfNull: false)  String? internetId, @JsonKey(includeIfNull: false)  String? hostSecret)  $default,) {final _that = this;
switch (_that) {
case _RoomSuccession():
return $default(_that.term,_that.handover,_that.name,_that.accessCode,_that.members,_that.note,_that.reach,_that.internetId,_that.hostSecret);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int term,  bool handover,  String name,  String accessCode,  List<RoomMember> members, @RoomNoteConverter()  RoomNote? note,  RoomReach reach, @JsonKey(includeIfNull: false)  String? internetId, @JsonKey(includeIfNull: false)  String? hostSecret)?  $default,) {final _that = this;
switch (_that) {
case _RoomSuccession() when $default != null:
return $default(_that.term,_that.handover,_that.name,_that.accessCode,_that.members,_that.note,_that.reach,_that.internetId,_that.hostSecret);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomSuccession extends RoomSuccession {
  const _RoomSuccession({required this.term, required this.handover, required this.name, required this.accessCode, required this.members, @RoomNoteConverter() this.note, this.reach = RoomReach.local, @JsonKey(includeIfNull: false) this.internetId, @JsonKey(includeIfNull: false) this.hostSecret}): super._();
  factory _RoomSuccession.fromJson(Map<String, dynamic> json) => _$RoomSuccessionFromJson(json);

/// Turno del anfitrión vigente: 1 al abrir la frecu; sube con cada
/// traspaso y, entre dos anfitriones, gana el mayor.
@override final  int term;
/// La frecu sobrevive a la salida del anfitrión.
@override final  bool handover;
/// Nombre de la frecu.
@override final  String name;
/// Código de acceso de la frecu.
@override final  String accessCode;
/// Quienes están en la frecu, en orden de sucesión (de llegada): el
/// anfitrión primero.
@override final  List<RoomMember> members;
/// Nota musical de la frecu.
@override@RoomNoteConverter() final  RoomNote? note;
/// Cómo se une el grupo: local o por internet.
@override@JsonKey() final  RoomReach reach;
/// Id de la frecu en el punto de encuentro, si es por internet.
@override@JsonKey(includeIfNull: false) final  String? internetId;
/// Secreto de anfitrión en el punto de encuentro, si es por internet:
/// con él, el sucesor toma la frecu.
@override@JsonKey(includeIfNull: false) final  String? hostSecret;

/// Create a copy of RoomSuccession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomSuccessionCopyWith<_RoomSuccession> get copyWith => __$RoomSuccessionCopyWithImpl<_RoomSuccession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomSuccessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomSuccession&&(identical(other.term, term) || other.term == term)&&(identical(other.handover, handover) || other.handover == handover)&&(identical(other.name, name) || other.name == name)&&(identical(other.accessCode, accessCode) || other.accessCode == accessCode)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.note, note) || other.note == note)&&(identical(other.reach, reach) || other.reach == reach)&&(identical(other.internetId, internetId) || other.internetId == internetId)&&(identical(other.hostSecret, hostSecret) || other.hostSecret == hostSecret));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,handover,name,accessCode,const DeepCollectionEquality().hash(members),note,reach,internetId,hostSecret);

@override
String toString() {
  return 'RoomSuccession(term: $term, handover: $handover, name: $name, accessCode: $accessCode, members: $members, note: $note, reach: $reach, internetId: $internetId, hostSecret: $hostSecret)';
}


}

/// @nodoc
abstract mixin class _$RoomSuccessionCopyWith<$Res> implements $RoomSuccessionCopyWith<$Res> {
  factory _$RoomSuccessionCopyWith(_RoomSuccession value, $Res Function(_RoomSuccession) _then) = __$RoomSuccessionCopyWithImpl;
@override @useResult
$Res call({
 int term, bool handover, String name, String accessCode, List<RoomMember> members,@RoomNoteConverter() RoomNote? note, RoomReach reach,@JsonKey(includeIfNull: false) String? internetId,@JsonKey(includeIfNull: false) String? hostSecret
});


@override $RoomNoteCopyWith<$Res>? get note;

}
/// @nodoc
class __$RoomSuccessionCopyWithImpl<$Res>
    implements _$RoomSuccessionCopyWith<$Res> {
  __$RoomSuccessionCopyWithImpl(this._self, this._then);

  final _RoomSuccession _self;
  final $Res Function(_RoomSuccession) _then;

/// Create a copy of RoomSuccession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? term = null,Object? handover = null,Object? name = null,Object? accessCode = null,Object? members = null,Object? note = freezed,Object? reach = null,Object? internetId = freezed,Object? hostSecret = freezed,}) {
  return _then(_RoomSuccession(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as int,handover: null == handover ? _self.handover : handover // ignore: cast_nullable_to_non_nullable
as bool,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,accessCode: null == accessCode ? _self.accessCode : accessCode // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<RoomMember>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,reach: null == reach ? _self.reach : reach // ignore: cast_nullable_to_non_nullable
as RoomReach,internetId: freezed == internetId ? _self.internetId : internetId // ignore: cast_nullable_to_non_nullable
as String?,hostSecret: freezed == hostSecret ? _self.hostSecret : hostSecret // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RoomSuccession
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


/// @nodoc
mixin _$RoomMember {

 String get id; String get displayName;/// Cuándo llegó a la frecu.
 DateTime get joinedAt;/// Su IPv4 en la red local, si entró por ella; por internet, nula.
@JsonKey(includeIfNull: false) String? get address;
/// Create a copy of RoomMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomMemberCopyWith<RoomMember> get copyWith => _$RoomMemberCopyWithImpl<RoomMember>(this as RoomMember, _$identity);

  /// Serializes this RoomMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomMember&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,joinedAt,address);

@override
String toString() {
  return 'RoomMember(id: $id, displayName: $displayName, joinedAt: $joinedAt, address: $address)';
}


}

/// @nodoc
abstract mixin class $RoomMemberCopyWith<$Res>  {
  factory $RoomMemberCopyWith(RoomMember value, $Res Function(RoomMember) _then) = _$RoomMemberCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, DateTime joinedAt,@JsonKey(includeIfNull: false) String? address
});




}
/// @nodoc
class _$RoomMemberCopyWithImpl<$Res>
    implements $RoomMemberCopyWith<$Res> {
  _$RoomMemberCopyWithImpl(this._self, this._then);

  final RoomMember _self;
  final $Res Function(RoomMember) _then;

/// Create a copy of RoomMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? joinedAt = null,Object? address = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomMember].
extension RoomMemberPatterns on RoomMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomMember value)  $default,){
final _that = this;
switch (_that) {
case _RoomMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomMember value)?  $default,){
final _that = this;
switch (_that) {
case _RoomMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  DateTime joinedAt, @JsonKey(includeIfNull: false)  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomMember() when $default != null:
return $default(_that.id,_that.displayName,_that.joinedAt,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  DateTime joinedAt, @JsonKey(includeIfNull: false)  String? address)  $default,) {final _that = this;
switch (_that) {
case _RoomMember():
return $default(_that.id,_that.displayName,_that.joinedAt,_that.address);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  DateTime joinedAt, @JsonKey(includeIfNull: false)  String? address)?  $default,) {final _that = this;
switch (_that) {
case _RoomMember() when $default != null:
return $default(_that.id,_that.displayName,_that.joinedAt,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomMember implements RoomMember {
  const _RoomMember({required this.id, required this.displayName, required this.joinedAt, @JsonKey(includeIfNull: false) this.address});
  factory _RoomMember.fromJson(Map<String, dynamic> json) => _$RoomMemberFromJson(json);

@override final  String id;
@override final  String displayName;
/// Cuándo llegó a la frecu.
@override final  DateTime joinedAt;
/// Su IPv4 en la red local, si entró por ella; por internet, nula.
@override@JsonKey(includeIfNull: false) final  String? address;

/// Create a copy of RoomMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomMemberCopyWith<_RoomMember> get copyWith => __$RoomMemberCopyWithImpl<_RoomMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomMember&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,joinedAt,address);

@override
String toString() {
  return 'RoomMember(id: $id, displayName: $displayName, joinedAt: $joinedAt, address: $address)';
}


}

/// @nodoc
abstract mixin class _$RoomMemberCopyWith<$Res> implements $RoomMemberCopyWith<$Res> {
  factory _$RoomMemberCopyWith(_RoomMember value, $Res Function(_RoomMember) _then) = __$RoomMemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, DateTime joinedAt,@JsonKey(includeIfNull: false) String? address
});




}
/// @nodoc
class __$RoomMemberCopyWithImpl<$Res>
    implements _$RoomMemberCopyWith<$Res> {
  __$RoomMemberCopyWithImpl(this._self, this._then);

  final _RoomMember _self;
  final $Res Function(_RoomMember) _then;

/// Create a copy of RoomMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? joinedAt = null,Object? address = freezed,}) {
  return _then(_RoomMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
