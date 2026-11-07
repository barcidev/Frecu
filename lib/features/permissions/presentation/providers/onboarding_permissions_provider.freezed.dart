// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_permissions_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingPermissionsState implements DiagnosticableTreeMixin {

/// Estado de cada permiso; el que falta está pendiente.
 Map<AppPermission, PermissionState> get states;/// Se están pidiendo los permisos que faltan.
 bool get requesting;/// Ya se pidieron una vez, con cualquier resultado.
 bool get requested;
/// Create a copy of OnboardingPermissionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingPermissionsStateCopyWith<OnboardingPermissionsState> get copyWith => _$OnboardingPermissionsStateCopyWithImpl<OnboardingPermissionsState>(this as OnboardingPermissionsState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'OnboardingPermissionsState'))
    ..add(DiagnosticsProperty('states', states))..add(DiagnosticsProperty('requesting', requesting))..add(DiagnosticsProperty('requested', requested));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingPermissionsState&&const DeepCollectionEquality().equals(other.states, states)&&(identical(other.requesting, requesting) || other.requesting == requesting)&&(identical(other.requested, requested) || other.requested == requested));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(states),requesting,requested);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'OnboardingPermissionsState(states: $states, requesting: $requesting, requested: $requested)';
}


}

/// @nodoc
abstract mixin class $OnboardingPermissionsStateCopyWith<$Res>  {
  factory $OnboardingPermissionsStateCopyWith(OnboardingPermissionsState value, $Res Function(OnboardingPermissionsState) _then) = _$OnboardingPermissionsStateCopyWithImpl;
@useResult
$Res call({
 Map<AppPermission, PermissionState> states, bool requesting, bool requested
});




}
/// @nodoc
class _$OnboardingPermissionsStateCopyWithImpl<$Res>
    implements $OnboardingPermissionsStateCopyWith<$Res> {
  _$OnboardingPermissionsStateCopyWithImpl(this._self, this._then);

  final OnboardingPermissionsState _self;
  final $Res Function(OnboardingPermissionsState) _then;

/// Create a copy of OnboardingPermissionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? states = null,Object? requesting = null,Object? requested = null,}) {
  return _then(_self.copyWith(
states: null == states ? _self.states : states // ignore: cast_nullable_to_non_nullable
as Map<AppPermission, PermissionState>,requesting: null == requesting ? _self.requesting : requesting // ignore: cast_nullable_to_non_nullable
as bool,requested: null == requested ? _self.requested : requested // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingPermissionsState].
extension OnboardingPermissionsStatePatterns on OnboardingPermissionsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingPermissionsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingPermissionsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingPermissionsState value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingPermissionsState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingPermissionsState value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingPermissionsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<AppPermission, PermissionState> states,  bool requesting,  bool requested)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingPermissionsState() when $default != null:
return $default(_that.states,_that.requesting,_that.requested);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<AppPermission, PermissionState> states,  bool requesting,  bool requested)  $default,) {final _that = this;
switch (_that) {
case _OnboardingPermissionsState():
return $default(_that.states,_that.requesting,_that.requested);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<AppPermission, PermissionState> states,  bool requesting,  bool requested)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingPermissionsState() when $default != null:
return $default(_that.states,_that.requesting,_that.requested);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingPermissionsState extends OnboardingPermissionsState with DiagnosticableTreeMixin {
  const _OnboardingPermissionsState({this.states = const <AppPermission, PermissionState>{}, this.requesting = false, this.requested = false}): super._();
  

/// Estado de cada permiso; el que falta está pendiente.
@override@JsonKey() final  Map<AppPermission, PermissionState> states;
/// Se están pidiendo los permisos que faltan.
@override@JsonKey() final  bool requesting;
/// Ya se pidieron una vez, con cualquier resultado.
@override@JsonKey() final  bool requested;

/// Create a copy of OnboardingPermissionsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingPermissionsStateCopyWith<_OnboardingPermissionsState> get copyWith => __$OnboardingPermissionsStateCopyWithImpl<_OnboardingPermissionsState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'OnboardingPermissionsState'))
    ..add(DiagnosticsProperty('states', states))..add(DiagnosticsProperty('requesting', requesting))..add(DiagnosticsProperty('requested', requested));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingPermissionsState&&const DeepCollectionEquality().equals(other.states, states)&&(identical(other.requesting, requesting) || other.requesting == requesting)&&(identical(other.requested, requested) || other.requested == requested));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(states),requesting,requested);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'OnboardingPermissionsState(states: $states, requesting: $requesting, requested: $requested)';
}


}

/// @nodoc
abstract mixin class _$OnboardingPermissionsStateCopyWith<$Res> implements $OnboardingPermissionsStateCopyWith<$Res> {
  factory _$OnboardingPermissionsStateCopyWith(_OnboardingPermissionsState value, $Res Function(_OnboardingPermissionsState) _then) = __$OnboardingPermissionsStateCopyWithImpl;
@override @useResult
$Res call({
 Map<AppPermission, PermissionState> states, bool requesting, bool requested
});




}
/// @nodoc
class __$OnboardingPermissionsStateCopyWithImpl<$Res>
    implements _$OnboardingPermissionsStateCopyWith<$Res> {
  __$OnboardingPermissionsStateCopyWithImpl(this._self, this._then);

  final _OnboardingPermissionsState _self;
  final $Res Function(_OnboardingPermissionsState) _then;

/// Create a copy of OnboardingPermissionsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? states = null,Object? requesting = null,Object? requested = null,}) {
  return _then(_OnboardingPermissionsState(
states: null == states ? _self.states : states // ignore: cast_nullable_to_non_nullable
as Map<AppPermission, PermissionState>,requesting: null == requesting ? _self.requesting : requesting // ignore: cast_nullable_to_non_nullable
as bool,requested: null == requested ? _self.requested : requested // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
