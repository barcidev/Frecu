// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_handover.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HostChange {

/// Id de quien lleva ahora la frecu.
 String get hostId;/// Nombre de quien lleva ahora la frecu.
 String get hostName;/// La lleva este teléfono.
 bool get you;/// Por qué cambió.
 HostChangeReason get reason;/// IPv4 de quien la lleva, para la invitación.
 String get hostAddress;/// Puerto de su servidor.
 int get port;/// Nombre de quien la llevaba, si se conoce.
 String? get previousHost;
/// Create a copy of HostChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostChangeCopyWith<HostChange> get copyWith => _$HostChangeCopyWithImpl<HostChange>(this as HostChange, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostChange&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.you, you) || other.you == you)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.port, port) || other.port == port)&&(identical(other.previousHost, previousHost) || other.previousHost == previousHost));
}


@override
int get hashCode => Object.hash(runtimeType,hostId,hostName,you,reason,hostAddress,port,previousHost);

@override
String toString() {
  return 'HostChange(hostId: $hostId, hostName: $hostName, you: $you, reason: $reason, hostAddress: $hostAddress, port: $port, previousHost: $previousHost)';
}


}

/// @nodoc
abstract mixin class $HostChangeCopyWith<$Res>  {
  factory $HostChangeCopyWith(HostChange value, $Res Function(HostChange) _then) = _$HostChangeCopyWithImpl;
@useResult
$Res call({
 String hostId, String hostName, bool you, HostChangeReason reason, String hostAddress, int port, String? previousHost
});




}
/// @nodoc
class _$HostChangeCopyWithImpl<$Res>
    implements $HostChangeCopyWith<$Res> {
  _$HostChangeCopyWithImpl(this._self, this._then);

  final HostChange _self;
  final $Res Function(HostChange) _then;

/// Create a copy of HostChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hostId = null,Object? hostName = null,Object? you = null,Object? reason = null,Object? hostAddress = null,Object? port = null,Object? previousHost = freezed,}) {
  return _then(_self.copyWith(
hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,hostName: null == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String,you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as HostChangeReason,hostAddress: null == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,previousHost: freezed == previousHost ? _self.previousHost : previousHost // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HostChange].
extension HostChangePatterns on HostChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HostChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HostChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HostChange value)  $default,){
final _that = this;
switch (_that) {
case _HostChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HostChange value)?  $default,){
final _that = this;
switch (_that) {
case _HostChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String hostId,  String hostName,  bool you,  HostChangeReason reason,  String hostAddress,  int port,  String? previousHost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostChange() when $default != null:
return $default(_that.hostId,_that.hostName,_that.you,_that.reason,_that.hostAddress,_that.port,_that.previousHost);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String hostId,  String hostName,  bool you,  HostChangeReason reason,  String hostAddress,  int port,  String? previousHost)  $default,) {final _that = this;
switch (_that) {
case _HostChange():
return $default(_that.hostId,_that.hostName,_that.you,_that.reason,_that.hostAddress,_that.port,_that.previousHost);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String hostId,  String hostName,  bool you,  HostChangeReason reason,  String hostAddress,  int port,  String? previousHost)?  $default,) {final _that = this;
switch (_that) {
case _HostChange() when $default != null:
return $default(_that.hostId,_that.hostName,_that.you,_that.reason,_that.hostAddress,_that.port,_that.previousHost);case _:
  return null;

}
}

}

/// @nodoc


class _HostChange implements HostChange {
  const _HostChange({required this.hostId, required this.hostName, required this.you, required this.reason, required this.hostAddress, required this.port, this.previousHost});
  

/// Id de quien lleva ahora la frecu.
@override final  String hostId;
/// Nombre de quien lleva ahora la frecu.
@override final  String hostName;
/// La lleva este teléfono.
@override final  bool you;
/// Por qué cambió.
@override final  HostChangeReason reason;
/// IPv4 de quien la lleva, para la invitación.
@override final  String hostAddress;
/// Puerto de su servidor.
@override final  int port;
/// Nombre de quien la llevaba, si se conoce.
@override final  String? previousHost;

/// Create a copy of HostChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostChangeCopyWith<_HostChange> get copyWith => __$HostChangeCopyWithImpl<_HostChange>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostChange&&(identical(other.hostId, hostId) || other.hostId == hostId)&&(identical(other.hostName, hostName) || other.hostName == hostName)&&(identical(other.you, you) || other.you == you)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.hostAddress, hostAddress) || other.hostAddress == hostAddress)&&(identical(other.port, port) || other.port == port)&&(identical(other.previousHost, previousHost) || other.previousHost == previousHost));
}


@override
int get hashCode => Object.hash(runtimeType,hostId,hostName,you,reason,hostAddress,port,previousHost);

@override
String toString() {
  return 'HostChange(hostId: $hostId, hostName: $hostName, you: $you, reason: $reason, hostAddress: $hostAddress, port: $port, previousHost: $previousHost)';
}


}

/// @nodoc
abstract mixin class _$HostChangeCopyWith<$Res> implements $HostChangeCopyWith<$Res> {
  factory _$HostChangeCopyWith(_HostChange value, $Res Function(_HostChange) _then) = __$HostChangeCopyWithImpl;
@override @useResult
$Res call({
 String hostId, String hostName, bool you, HostChangeReason reason, String hostAddress, int port, String? previousHost
});




}
/// @nodoc
class __$HostChangeCopyWithImpl<$Res>
    implements _$HostChangeCopyWith<$Res> {
  __$HostChangeCopyWithImpl(this._self, this._then);

  final _HostChange _self;
  final $Res Function(_HostChange) _then;

/// Create a copy of HostChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hostId = null,Object? hostName = null,Object? you = null,Object? reason = null,Object? hostAddress = null,Object? port = null,Object? previousHost = freezed,}) {
  return _then(_HostChange(
hostId: null == hostId ? _self.hostId : hostId // ignore: cast_nullable_to_non_nullable
as String,hostName: null == hostName ? _self.hostName : hostName // ignore: cast_nullable_to_non_nullable
as String,you: null == you ? _self.you : you // ignore: cast_nullable_to_non_nullable
as bool,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as HostChangeReason,hostAddress: null == hostAddress ? _self.hostAddress : hostAddress // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,previousHost: freezed == previousHost ? _self.previousHost : previousHost // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
