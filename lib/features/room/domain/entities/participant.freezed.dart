// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Participant {

 String get id; String get displayName; bool get isHost; bool get isSpeaking; bool get isMuted; PeerConnectionState get connectionState;
/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipantCopyWith<Participant> get copyWith => _$ParticipantCopyWithImpl<Participant>(this as Participant, _$identity);

  /// Serializes this Participant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Participant&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isSpeaking, isSpeaking) || other.isSpeaking == isSpeaking)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.connectionState, connectionState) || other.connectionState == connectionState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,isHost,isSpeaking,isMuted,connectionState);

@override
String toString() {
  return 'Participant(id: $id, displayName: $displayName, isHost: $isHost, isSpeaking: $isSpeaking, isMuted: $isMuted, connectionState: $connectionState)';
}


}

/// @nodoc
abstract mixin class $ParticipantCopyWith<$Res>  {
  factory $ParticipantCopyWith(Participant value, $Res Function(Participant) _then) = _$ParticipantCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, bool isHost, bool isSpeaking, bool isMuted, PeerConnectionState connectionState
});




}
/// @nodoc
class _$ParticipantCopyWithImpl<$Res>
    implements $ParticipantCopyWith<$Res> {
  _$ParticipantCopyWithImpl(this._self, this._then);

  final Participant _self;
  final $Res Function(Participant) _then;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? isHost = null,Object? isSpeaking = null,Object? isMuted = null,Object? connectionState = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isSpeaking: null == isSpeaking ? _self.isSpeaking : isSpeaking // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,connectionState: null == connectionState ? _self.connectionState : connectionState // ignore: cast_nullable_to_non_nullable
as PeerConnectionState,
  ));
}

}


/// Adds pattern-matching-related methods to [Participant].
extension ParticipantPatterns on Participant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Participant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Participant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Participant value)  $default,){
final _that = this;
switch (_that) {
case _Participant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Participant value)?  $default,){
final _that = this;
switch (_that) {
case _Participant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  bool isHost,  bool isSpeaking,  bool isMuted,  PeerConnectionState connectionState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Participant() when $default != null:
return $default(_that.id,_that.displayName,_that.isHost,_that.isSpeaking,_that.isMuted,_that.connectionState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  bool isHost,  bool isSpeaking,  bool isMuted,  PeerConnectionState connectionState)  $default,) {final _that = this;
switch (_that) {
case _Participant():
return $default(_that.id,_that.displayName,_that.isHost,_that.isSpeaking,_that.isMuted,_that.connectionState);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  bool isHost,  bool isSpeaking,  bool isMuted,  PeerConnectionState connectionState)?  $default,) {final _that = this;
switch (_that) {
case _Participant() when $default != null:
return $default(_that.id,_that.displayName,_that.isHost,_that.isSpeaking,_that.isMuted,_that.connectionState);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Participant implements Participant {
  const _Participant({required this.id, required this.displayName, this.isHost = false, this.isSpeaking = false, this.isMuted = false, this.connectionState = PeerConnectionState.connected});
  factory _Participant.fromJson(Map<String, dynamic> json) => _$ParticipantFromJson(json);

@override final  String id;
@override final  String displayName;
@override@JsonKey() final  bool isHost;
@override@JsonKey() final  bool isSpeaking;
@override@JsonKey() final  bool isMuted;
@override@JsonKey() final  PeerConnectionState connectionState;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParticipantCopyWith<_Participant> get copyWith => __$ParticipantCopyWithImpl<_Participant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Participant&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isSpeaking, isSpeaking) || other.isSpeaking == isSpeaking)&&(identical(other.isMuted, isMuted) || other.isMuted == isMuted)&&(identical(other.connectionState, connectionState) || other.connectionState == connectionState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,isHost,isSpeaking,isMuted,connectionState);

@override
String toString() {
  return 'Participant(id: $id, displayName: $displayName, isHost: $isHost, isSpeaking: $isSpeaking, isMuted: $isMuted, connectionState: $connectionState)';
}


}

/// @nodoc
abstract mixin class _$ParticipantCopyWith<$Res> implements $ParticipantCopyWith<$Res> {
  factory _$ParticipantCopyWith(_Participant value, $Res Function(_Participant) _then) = __$ParticipantCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, bool isHost, bool isSpeaking, bool isMuted, PeerConnectionState connectionState
});




}
/// @nodoc
class __$ParticipantCopyWithImpl<$Res>
    implements _$ParticipantCopyWith<$Res> {
  __$ParticipantCopyWithImpl(this._self, this._then);

  final _Participant _self;
  final $Res Function(_Participant) _then;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? isHost = null,Object? isSpeaking = null,Object? isMuted = null,Object? connectionState = null,}) {
  return _then(_Participant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isSpeaking: null == isSpeaking ? _self.isSpeaking : isSpeaking // ignore: cast_nullable_to_non_nullable
as bool,isMuted: null == isMuted ? _self.isMuted : isMuted // ignore: cast_nullable_to_non_nullable
as bool,connectionState: null == connectionState ? _self.connectionState : connectionState // ignore: cast_nullable_to_non_nullable
as PeerConnectionState,
  ));
}


}

// dart format on
