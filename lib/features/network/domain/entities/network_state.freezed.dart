// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NetworkState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NetworkState()';
}


}

/// @nodoc
class $NetworkStateCopyWith<$Res>  {
$NetworkStateCopyWith(NetworkState _, $Res Function(NetworkState) __);
}


/// Adds pattern-matching-related methods to [NetworkState].
extension NetworkStatePatterns on NetworkState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkDisconnected value)?  disconnected,TResult Function( NetworkConnected value)?  connected,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkDisconnected() when disconnected != null:
return disconnected(_that);case NetworkConnected() when connected != null:
return connected(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkDisconnected value)  disconnected,required TResult Function( NetworkConnected value)  connected,}){
final _that = this;
switch (_that) {
case NetworkDisconnected():
return disconnected(_that);case NetworkConnected():
return connected(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkDisconnected value)?  disconnected,TResult? Function( NetworkConnected value)?  connected,}){
final _that = this;
switch (_that) {
case NetworkDisconnected() when disconnected != null:
return disconnected(_that);case NetworkConnected() when connected != null:
return connected(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  disconnected,TResult Function( String ipAddress,  String interfaceName,  bool isHotspot)?  connected,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkDisconnected() when disconnected != null:
return disconnected();case NetworkConnected() when connected != null:
return connected(_that.ipAddress,_that.interfaceName,_that.isHotspot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  disconnected,required TResult Function( String ipAddress,  String interfaceName,  bool isHotspot)  connected,}) {final _that = this;
switch (_that) {
case NetworkDisconnected():
return disconnected();case NetworkConnected():
return connected(_that.ipAddress,_that.interfaceName,_that.isHotspot);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  disconnected,TResult? Function( String ipAddress,  String interfaceName,  bool isHotspot)?  connected,}) {final _that = this;
switch (_that) {
case NetworkDisconnected() when disconnected != null:
return disconnected();case NetworkConnected() when connected != null:
return connected(_that.ipAddress,_that.interfaceName,_that.isHotspot);case _:
  return null;

}
}

}

/// @nodoc


class NetworkDisconnected extends NetworkState {
  const NetworkDisconnected(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkDisconnected);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NetworkState.disconnected()';
}


}




/// @nodoc


class NetworkConnected extends NetworkState {
  const NetworkConnected({required this.ipAddress, required this.interfaceName, required this.isHotspot}): super._();
  

 final  String ipAddress;
 final  String interfaceName;
 final  bool isHotspot;

/// Create a copy of NetworkState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkConnectedCopyWith<NetworkConnected> get copyWith => _$NetworkConnectedCopyWithImpl<NetworkConnected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkConnected&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.interfaceName, interfaceName) || other.interfaceName == interfaceName)&&(identical(other.isHotspot, isHotspot) || other.isHotspot == isHotspot));
}


@override
int get hashCode => Object.hash(runtimeType,ipAddress,interfaceName,isHotspot);

@override
String toString() {
  return 'NetworkState.connected(ipAddress: $ipAddress, interfaceName: $interfaceName, isHotspot: $isHotspot)';
}


}

/// @nodoc
abstract mixin class $NetworkConnectedCopyWith<$Res> implements $NetworkStateCopyWith<$Res> {
  factory $NetworkConnectedCopyWith(NetworkConnected value, $Res Function(NetworkConnected) _then) = _$NetworkConnectedCopyWithImpl;
@useResult
$Res call({
 String ipAddress, String interfaceName, bool isHotspot
});




}
/// @nodoc
class _$NetworkConnectedCopyWithImpl<$Res>
    implements $NetworkConnectedCopyWith<$Res> {
  _$NetworkConnectedCopyWithImpl(this._self, this._then);

  final NetworkConnected _self;
  final $Res Function(NetworkConnected) _then;

/// Create a copy of NetworkState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ipAddress = null,Object? interfaceName = null,Object? isHotspot = null,}) {
  return _then(NetworkConnected(
ipAddress: null == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String,interfaceName: null == interfaceName ? _self.interfaceName : interfaceName // ignore: cast_nullable_to_non_nullable
as String,isHotspot: null == isHotspot ? _self.isHotspot : isHotspot // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
