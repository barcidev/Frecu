// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_hotspot_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalHotspotState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalHotspotState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocalHotspotState()';
}


}

/// @nodoc
class $LocalHotspotStateCopyWith<$Res>  {
$LocalHotspotStateCopyWith(LocalHotspotState _, $Res Function(LocalHotspotState) __);
}


/// Adds pattern-matching-related methods to [LocalHotspotState].
extension LocalHotspotStatePatterns on LocalHotspotState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LocalHotspotOff value)?  off,TResult Function( LocalHotspotStarting value)?  starting,TResult Function( LocalHotspotReady value)?  ready,TResult Function( LocalHotspotFailed value)?  failed,TResult Function( LocalHotspotLost value)?  lost,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LocalHotspotOff() when off != null:
return off(_that);case LocalHotspotStarting() when starting != null:
return starting(_that);case LocalHotspotReady() when ready != null:
return ready(_that);case LocalHotspotFailed() when failed != null:
return failed(_that);case LocalHotspotLost() when lost != null:
return lost(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LocalHotspotOff value)  off,required TResult Function( LocalHotspotStarting value)  starting,required TResult Function( LocalHotspotReady value)  ready,required TResult Function( LocalHotspotFailed value)  failed,required TResult Function( LocalHotspotLost value)  lost,}){
final _that = this;
switch (_that) {
case LocalHotspotOff():
return off(_that);case LocalHotspotStarting():
return starting(_that);case LocalHotspotReady():
return ready(_that);case LocalHotspotFailed():
return failed(_that);case LocalHotspotLost():
return lost(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LocalHotspotOff value)?  off,TResult? Function( LocalHotspotStarting value)?  starting,TResult? Function( LocalHotspotReady value)?  ready,TResult? Function( LocalHotspotFailed value)?  failed,TResult? Function( LocalHotspotLost value)?  lost,}){
final _that = this;
switch (_that) {
case LocalHotspotOff() when off != null:
return off(_that);case LocalHotspotStarting() when starting != null:
return starting(_that);case LocalHotspotReady() when ready != null:
return ready(_that);case LocalHotspotFailed() when failed != null:
return failed(_that);case LocalHotspotLost() when lost != null:
return lost(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  off,TResult Function()?  starting,TResult Function( LocalHotspot hotspot)?  ready,TResult Function( HotspotFailureReason reason)?  failed,TResult Function()?  lost,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LocalHotspotOff() when off != null:
return off();case LocalHotspotStarting() when starting != null:
return starting();case LocalHotspotReady() when ready != null:
return ready(_that.hotspot);case LocalHotspotFailed() when failed != null:
return failed(_that.reason);case LocalHotspotLost() when lost != null:
return lost();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  off,required TResult Function()  starting,required TResult Function( LocalHotspot hotspot)  ready,required TResult Function( HotspotFailureReason reason)  failed,required TResult Function()  lost,}) {final _that = this;
switch (_that) {
case LocalHotspotOff():
return off();case LocalHotspotStarting():
return starting();case LocalHotspotReady():
return ready(_that.hotspot);case LocalHotspotFailed():
return failed(_that.reason);case LocalHotspotLost():
return lost();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  off,TResult? Function()?  starting,TResult? Function( LocalHotspot hotspot)?  ready,TResult? Function( HotspotFailureReason reason)?  failed,TResult? Function()?  lost,}) {final _that = this;
switch (_that) {
case LocalHotspotOff() when off != null:
return off();case LocalHotspotStarting() when starting != null:
return starting();case LocalHotspotReady() when ready != null:
return ready(_that.hotspot);case LocalHotspotFailed() when failed != null:
return failed(_that.reason);case LocalHotspotLost() when lost != null:
return lost();case _:
  return null;

}
}

}

/// @nodoc


class LocalHotspotOff implements LocalHotspotState {
  const LocalHotspotOff();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalHotspotOff);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocalHotspotState.off()';
}


}




/// @nodoc


class LocalHotspotStarting implements LocalHotspotState {
  const LocalHotspotStarting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalHotspotStarting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocalHotspotState.starting()';
}


}




/// @nodoc


class LocalHotspotReady implements LocalHotspotState {
  const LocalHotspotReady(this.hotspot);
  

 final  LocalHotspot hotspot;

/// Create a copy of LocalHotspotState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalHotspotReadyCopyWith<LocalHotspotReady> get copyWith => _$LocalHotspotReadyCopyWithImpl<LocalHotspotReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalHotspotReady&&(identical(other.hotspot, hotspot) || other.hotspot == hotspot));
}


@override
int get hashCode => Object.hash(runtimeType,hotspot);

@override
String toString() {
  return 'LocalHotspotState.ready(hotspot: $hotspot)';
}


}

/// @nodoc
abstract mixin class $LocalHotspotReadyCopyWith<$Res> implements $LocalHotspotStateCopyWith<$Res> {
  factory $LocalHotspotReadyCopyWith(LocalHotspotReady value, $Res Function(LocalHotspotReady) _then) = _$LocalHotspotReadyCopyWithImpl;
@useResult
$Res call({
 LocalHotspot hotspot
});


$LocalHotspotCopyWith<$Res> get hotspot;

}
/// @nodoc
class _$LocalHotspotReadyCopyWithImpl<$Res>
    implements $LocalHotspotReadyCopyWith<$Res> {
  _$LocalHotspotReadyCopyWithImpl(this._self, this._then);

  final LocalHotspotReady _self;
  final $Res Function(LocalHotspotReady) _then;

/// Create a copy of LocalHotspotState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hotspot = null,}) {
  return _then(LocalHotspotReady(
null == hotspot ? _self.hotspot : hotspot // ignore: cast_nullable_to_non_nullable
as LocalHotspot,
  ));
}

/// Create a copy of LocalHotspotState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalHotspotCopyWith<$Res> get hotspot {
  
  return $LocalHotspotCopyWith<$Res>(_self.hotspot, (value) {
    return _then(_self.copyWith(hotspot: value));
  });
}
}

/// @nodoc


class LocalHotspotFailed implements LocalHotspotState {
  const LocalHotspotFailed(this.reason);
  

 final  HotspotFailureReason reason;

/// Create a copy of LocalHotspotState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalHotspotFailedCopyWith<LocalHotspotFailed> get copyWith => _$LocalHotspotFailedCopyWithImpl<LocalHotspotFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalHotspotFailed&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'LocalHotspotState.failed(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $LocalHotspotFailedCopyWith<$Res> implements $LocalHotspotStateCopyWith<$Res> {
  factory $LocalHotspotFailedCopyWith(LocalHotspotFailed value, $Res Function(LocalHotspotFailed) _then) = _$LocalHotspotFailedCopyWithImpl;
@useResult
$Res call({
 HotspotFailureReason reason
});




}
/// @nodoc
class _$LocalHotspotFailedCopyWithImpl<$Res>
    implements $LocalHotspotFailedCopyWith<$Res> {
  _$LocalHotspotFailedCopyWithImpl(this._self, this._then);

  final LocalHotspotFailed _self;
  final $Res Function(LocalHotspotFailed) _then;

/// Create a copy of LocalHotspotState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(LocalHotspotFailed(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as HotspotFailureReason,
  ));
}


}

/// @nodoc


class LocalHotspotLost implements LocalHotspotState {
  const LocalHotspotLost();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalHotspotLost);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LocalHotspotState.lost()';
}


}




// dart format on
