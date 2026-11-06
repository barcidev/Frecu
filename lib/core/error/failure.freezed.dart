// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _NetworkFailure value)?  network,TResult Function( _PermissionDeniedFailure value)?  permissionDenied,TResult Function( _RoomFullFailure value)?  roomFull,TResult Function( _InvalidAccessCodeFailure value)?  invalidAccessCode,TResult Function( _HostUnreachableFailure value)?  hostUnreachable,TResult Function( _AudioFailure value)?  audio,TResult Function( _UnexpectedFailure value)?  unexpected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetworkFailure() when network != null:
return network(_that);case _PermissionDeniedFailure() when permissionDenied != null:
return permissionDenied(_that);case _RoomFullFailure() when roomFull != null:
return roomFull(_that);case _InvalidAccessCodeFailure() when invalidAccessCode != null:
return invalidAccessCode(_that);case _HostUnreachableFailure() when hostUnreachable != null:
return hostUnreachable(_that);case _AudioFailure() when audio != null:
return audio(_that);case _UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _NetworkFailure value)  network,required TResult Function( _PermissionDeniedFailure value)  permissionDenied,required TResult Function( _RoomFullFailure value)  roomFull,required TResult Function( _InvalidAccessCodeFailure value)  invalidAccessCode,required TResult Function( _HostUnreachableFailure value)  hostUnreachable,required TResult Function( _AudioFailure value)  audio,required TResult Function( _UnexpectedFailure value)  unexpected,}){
final _that = this;
switch (_that) {
case _NetworkFailure():
return network(_that);case _PermissionDeniedFailure():
return permissionDenied(_that);case _RoomFullFailure():
return roomFull(_that);case _InvalidAccessCodeFailure():
return invalidAccessCode(_that);case _HostUnreachableFailure():
return hostUnreachable(_that);case _AudioFailure():
return audio(_that);case _UnexpectedFailure():
return unexpected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _NetworkFailure value)?  network,TResult? Function( _PermissionDeniedFailure value)?  permissionDenied,TResult? Function( _RoomFullFailure value)?  roomFull,TResult? Function( _InvalidAccessCodeFailure value)?  invalidAccessCode,TResult? Function( _HostUnreachableFailure value)?  hostUnreachable,TResult? Function( _AudioFailure value)?  audio,TResult? Function( _UnexpectedFailure value)?  unexpected,}){
final _that = this;
switch (_that) {
case _NetworkFailure() when network != null:
return network(_that);case _PermissionDeniedFailure() when permissionDenied != null:
return permissionDenied(_that);case _RoomFullFailure() when roomFull != null:
return roomFull(_that);case _InvalidAccessCodeFailure() when invalidAccessCode != null:
return invalidAccessCode(_that);case _HostUnreachableFailure() when hostUnreachable != null:
return hostUnreachable(_that);case _AudioFailure() when audio != null:
return audio(_that);case _UnexpectedFailure() when unexpected != null:
return unexpected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? message)?  network,TResult Function( String? permission)?  permissionDenied,TResult Function()?  roomFull,TResult Function()?  invalidAccessCode,TResult Function()?  hostUnreachable,TResult Function( String? message)?  audio,TResult Function( String? message,  Object? error)?  unexpected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetworkFailure() when network != null:
return network(_that.message);case _PermissionDeniedFailure() when permissionDenied != null:
return permissionDenied(_that.permission);case _RoomFullFailure() when roomFull != null:
return roomFull();case _InvalidAccessCodeFailure() when invalidAccessCode != null:
return invalidAccessCode();case _HostUnreachableFailure() when hostUnreachable != null:
return hostUnreachable();case _AudioFailure() when audio != null:
return audio(_that.message);case _UnexpectedFailure() when unexpected != null:
return unexpected(_that.message,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? message)  network,required TResult Function( String? permission)  permissionDenied,required TResult Function()  roomFull,required TResult Function()  invalidAccessCode,required TResult Function()  hostUnreachable,required TResult Function( String? message)  audio,required TResult Function( String? message,  Object? error)  unexpected,}) {final _that = this;
switch (_that) {
case _NetworkFailure():
return network(_that.message);case _PermissionDeniedFailure():
return permissionDenied(_that.permission);case _RoomFullFailure():
return roomFull();case _InvalidAccessCodeFailure():
return invalidAccessCode();case _HostUnreachableFailure():
return hostUnreachable();case _AudioFailure():
return audio(_that.message);case _UnexpectedFailure():
return unexpected(_that.message,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? message)?  network,TResult? Function( String? permission)?  permissionDenied,TResult? Function()?  roomFull,TResult? Function()?  invalidAccessCode,TResult? Function()?  hostUnreachable,TResult? Function( String? message)?  audio,TResult? Function( String? message,  Object? error)?  unexpected,}) {final _that = this;
switch (_that) {
case _NetworkFailure() when network != null:
return network(_that.message);case _PermissionDeniedFailure() when permissionDenied != null:
return permissionDenied(_that.permission);case _RoomFullFailure() when roomFull != null:
return roomFull();case _InvalidAccessCodeFailure() when invalidAccessCode != null:
return invalidAccessCode();case _HostUnreachableFailure() when hostUnreachable != null:
return hostUnreachable();case _AudioFailure() when audio != null:
return audio(_that.message);case _UnexpectedFailure() when unexpected != null:
return unexpected(_that.message,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _NetworkFailure implements Failure {
  const _NetworkFailure({this.message});
  

 final  String? message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkFailureCopyWith<_NetworkFailure> get copyWith => __$NetworkFailureCopyWithImpl<_NetworkFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.network(message: $message)';
}


}

/// @nodoc
abstract mixin class _$NetworkFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$NetworkFailureCopyWith(_NetworkFailure value, $Res Function(_NetworkFailure) _then) = __$NetworkFailureCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$NetworkFailureCopyWithImpl<$Res>
    implements _$NetworkFailureCopyWith<$Res> {
  __$NetworkFailureCopyWithImpl(this._self, this._then);

  final _NetworkFailure _self;
  final $Res Function(_NetworkFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_NetworkFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _PermissionDeniedFailure implements Failure {
  const _PermissionDeniedFailure({this.permission});
  

 final  String? permission;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PermissionDeniedFailureCopyWith<_PermissionDeniedFailure> get copyWith => __$PermissionDeniedFailureCopyWithImpl<_PermissionDeniedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PermissionDeniedFailure&&(identical(other.permission, permission) || other.permission == permission));
}


@override
int get hashCode => Object.hash(runtimeType,permission);

@override
String toString() {
  return 'Failure.permissionDenied(permission: $permission)';
}


}

/// @nodoc
abstract mixin class _$PermissionDeniedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$PermissionDeniedFailureCopyWith(_PermissionDeniedFailure value, $Res Function(_PermissionDeniedFailure) _then) = __$PermissionDeniedFailureCopyWithImpl;
@useResult
$Res call({
 String? permission
});




}
/// @nodoc
class __$PermissionDeniedFailureCopyWithImpl<$Res>
    implements _$PermissionDeniedFailureCopyWith<$Res> {
  __$PermissionDeniedFailureCopyWithImpl(this._self, this._then);

  final _PermissionDeniedFailure _self;
  final $Res Function(_PermissionDeniedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? permission = freezed,}) {
  return _then(_PermissionDeniedFailure(
permission: freezed == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _RoomFullFailure implements Failure {
  const _RoomFullFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomFullFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.roomFull()';
}


}




/// @nodoc


class _InvalidAccessCodeFailure implements Failure {
  const _InvalidAccessCodeFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvalidAccessCodeFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.invalidAccessCode()';
}


}




/// @nodoc


class _HostUnreachableFailure implements Failure {
  const _HostUnreachableFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostUnreachableFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Failure.hostUnreachable()';
}


}




/// @nodoc


class _AudioFailure implements Failure {
  const _AudioFailure({this.message});
  

 final  String? message;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioFailureCopyWith<_AudioFailure> get copyWith => __$AudioFailureCopyWithImpl<_AudioFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'Failure.audio(message: $message)';
}


}

/// @nodoc
abstract mixin class _$AudioFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$AudioFailureCopyWith(_AudioFailure value, $Res Function(_AudioFailure) _then) = __$AudioFailureCopyWithImpl;
@useResult
$Res call({
 String? message
});




}
/// @nodoc
class __$AudioFailureCopyWithImpl<$Res>
    implements _$AudioFailureCopyWith<$Res> {
  __$AudioFailureCopyWithImpl(this._self, this._then);

  final _AudioFailure _self;
  final $Res Function(_AudioFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(_AudioFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _UnexpectedFailure implements Failure {
  const _UnexpectedFailure({this.message, this.error});
  

 final  String? message;
 final  Object? error;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnexpectedFailureCopyWith<_UnexpectedFailure> get copyWith => __$UnexpectedFailureCopyWithImpl<_UnexpectedFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnexpectedFailure&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'Failure.unexpected(message: $message, error: $error)';
}


}

/// @nodoc
abstract mixin class _$UnexpectedFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory _$UnexpectedFailureCopyWith(_UnexpectedFailure value, $Res Function(_UnexpectedFailure) _then) = __$UnexpectedFailureCopyWithImpl;
@useResult
$Res call({
 String? message, Object? error
});




}
/// @nodoc
class __$UnexpectedFailureCopyWithImpl<$Res>
    implements _$UnexpectedFailureCopyWith<$Res> {
  __$UnexpectedFailureCopyWithImpl(this._self, this._then);

  final _UnexpectedFailure _self;
  final $Res Function(_UnexpectedFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = freezed,Object? error = freezed,}) {
  return _then(_UnexpectedFailure(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
