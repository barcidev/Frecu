// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomStatus {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoomStatus()';
}


}

/// @nodoc
class $RoomStatusCopyWith<$Res>  {
$RoomStatusCopyWith(RoomStatus _, $Res Function(RoomStatus) __);
}


/// Adds pattern-matching-related methods to [RoomStatus].
extension RoomStatusPatterns on RoomStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _RoomStatusIdle value)?  idle,TResult Function( _RoomStatusConnecting value)?  connecting,TResult Function( _RoomStatusConnected value)?  connected,TResult Function( _RoomStatusReconnecting value)?  reconnecting,TResult Function( _RoomStatusClosed value)?  closed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomStatusIdle() when idle != null:
return idle(_that);case _RoomStatusConnecting() when connecting != null:
return connecting(_that);case _RoomStatusConnected() when connected != null:
return connected(_that);case _RoomStatusReconnecting() when reconnecting != null:
return reconnecting(_that);case _RoomStatusClosed() when closed != null:
return closed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _RoomStatusIdle value)  idle,required TResult Function( _RoomStatusConnecting value)  connecting,required TResult Function( _RoomStatusConnected value)  connected,required TResult Function( _RoomStatusReconnecting value)  reconnecting,required TResult Function( _RoomStatusClosed value)  closed,}){
final _that = this;
switch (_that) {
case _RoomStatusIdle():
return idle(_that);case _RoomStatusConnecting():
return connecting(_that);case _RoomStatusConnected():
return connected(_that);case _RoomStatusReconnecting():
return reconnecting(_that);case _RoomStatusClosed():
return closed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _RoomStatusIdle value)?  idle,TResult? Function( _RoomStatusConnecting value)?  connecting,TResult? Function( _RoomStatusConnected value)?  connected,TResult? Function( _RoomStatusReconnecting value)?  reconnecting,TResult? Function( _RoomStatusClosed value)?  closed,}){
final _that = this;
switch (_that) {
case _RoomStatusIdle() when idle != null:
return idle(_that);case _RoomStatusConnecting() when connecting != null:
return connecting(_that);case _RoomStatusConnected() when connected != null:
return connected(_that);case _RoomStatusReconnecting() when reconnecting != null:
return reconnecting(_that);case _RoomStatusClosed() when closed != null:
return closed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  connecting,TResult Function()?  connected,TResult Function()?  reconnecting,TResult Function( String reason)?  closed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomStatusIdle() when idle != null:
return idle();case _RoomStatusConnecting() when connecting != null:
return connecting();case _RoomStatusConnected() when connected != null:
return connected();case _RoomStatusReconnecting() when reconnecting != null:
return reconnecting();case _RoomStatusClosed() when closed != null:
return closed(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  connecting,required TResult Function()  connected,required TResult Function()  reconnecting,required TResult Function( String reason)  closed,}) {final _that = this;
switch (_that) {
case _RoomStatusIdle():
return idle();case _RoomStatusConnecting():
return connecting();case _RoomStatusConnected():
return connected();case _RoomStatusReconnecting():
return reconnecting();case _RoomStatusClosed():
return closed(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  connecting,TResult? Function()?  connected,TResult? Function()?  reconnecting,TResult? Function( String reason)?  closed,}) {final _that = this;
switch (_that) {
case _RoomStatusIdle() when idle != null:
return idle();case _RoomStatusConnecting() when connecting != null:
return connecting();case _RoomStatusConnected() when connected != null:
return connected();case _RoomStatusReconnecting() when reconnecting != null:
return reconnecting();case _RoomStatusClosed() when closed != null:
return closed(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _RoomStatusIdle implements RoomStatus {
  const _RoomStatusIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomStatusIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoomStatus.idle()';
}


}




/// @nodoc


class _RoomStatusConnecting implements RoomStatus {
  const _RoomStatusConnecting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomStatusConnecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoomStatus.connecting()';
}


}




/// @nodoc


class _RoomStatusConnected implements RoomStatus {
  const _RoomStatusConnected();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomStatusConnected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoomStatus.connected()';
}


}




/// @nodoc


class _RoomStatusReconnecting implements RoomStatus {
  const _RoomStatusReconnecting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomStatusReconnecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoomStatus.reconnecting()';
}


}




/// @nodoc


class _RoomStatusClosed implements RoomStatus {
  const _RoomStatusClosed({required this.reason});
  

 final  String reason;

/// Create a copy of RoomStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomStatusClosedCopyWith<_RoomStatusClosed> get copyWith => __$RoomStatusClosedCopyWithImpl<_RoomStatusClosed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomStatusClosed&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'RoomStatus.closed(reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$RoomStatusClosedCopyWith<$Res> implements $RoomStatusCopyWith<$Res> {
  factory _$RoomStatusClosedCopyWith(_RoomStatusClosed value, $Res Function(_RoomStatusClosed) _then) = __$RoomStatusClosedCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class __$RoomStatusClosedCopyWithImpl<$Res>
    implements _$RoomStatusClosedCopyWith<$Res> {
  __$RoomStatusClosedCopyWithImpl(this._self, this._then);

  final _RoomStatusClosed _self;
  final $Res Function(_RoomStatusClosed) _then;

/// Create a copy of RoomStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(_RoomStatusClosed(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
