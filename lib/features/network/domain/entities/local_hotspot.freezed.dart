// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_hotspot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalHotspot {

 WifiCredentials get credentials; String? get interfaceName; String? get address;
/// Create a copy of LocalHotspot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalHotspotCopyWith<LocalHotspot> get copyWith => _$LocalHotspotCopyWithImpl<LocalHotspot>(this as LocalHotspot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalHotspot&&(identical(other.credentials, credentials) || other.credentials == credentials)&&(identical(other.interfaceName, interfaceName) || other.interfaceName == interfaceName)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,credentials,interfaceName,address);

@override
String toString() {
  return 'LocalHotspot(credentials: $credentials, interfaceName: $interfaceName, address: $address)';
}


}

/// @nodoc
abstract mixin class $LocalHotspotCopyWith<$Res>  {
  factory $LocalHotspotCopyWith(LocalHotspot value, $Res Function(LocalHotspot) _then) = _$LocalHotspotCopyWithImpl;
@useResult
$Res call({
 WifiCredentials credentials, String? interfaceName, String? address
});


$WifiCredentialsCopyWith<$Res> get credentials;

}
/// @nodoc
class _$LocalHotspotCopyWithImpl<$Res>
    implements $LocalHotspotCopyWith<$Res> {
  _$LocalHotspotCopyWithImpl(this._self, this._then);

  final LocalHotspot _self;
  final $Res Function(LocalHotspot) _then;

/// Create a copy of LocalHotspot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? credentials = null,Object? interfaceName = freezed,Object? address = freezed,}) {
  return _then(_self.copyWith(
credentials: null == credentials ? _self.credentials : credentials // ignore: cast_nullable_to_non_nullable
as WifiCredentials,interfaceName: freezed == interfaceName ? _self.interfaceName : interfaceName // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of LocalHotspot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WifiCredentialsCopyWith<$Res> get credentials {
  
  return $WifiCredentialsCopyWith<$Res>(_self.credentials, (value) {
    return _then(_self.copyWith(credentials: value));
  });
}
}


/// Adds pattern-matching-related methods to [LocalHotspot].
extension LocalHotspotPatterns on LocalHotspot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalHotspot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalHotspot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalHotspot value)  $default,){
final _that = this;
switch (_that) {
case _LocalHotspot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalHotspot value)?  $default,){
final _that = this;
switch (_that) {
case _LocalHotspot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WifiCredentials credentials,  String? interfaceName,  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalHotspot() when $default != null:
return $default(_that.credentials,_that.interfaceName,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WifiCredentials credentials,  String? interfaceName,  String? address)  $default,) {final _that = this;
switch (_that) {
case _LocalHotspot():
return $default(_that.credentials,_that.interfaceName,_that.address);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WifiCredentials credentials,  String? interfaceName,  String? address)?  $default,) {final _that = this;
switch (_that) {
case _LocalHotspot() when $default != null:
return $default(_that.credentials,_that.interfaceName,_that.address);case _:
  return null;

}
}

}

/// @nodoc


class _LocalHotspot implements LocalHotspot {
  const _LocalHotspot({required this.credentials, this.interfaceName, this.address});
  

@override final  WifiCredentials credentials;
@override final  String? interfaceName;
@override final  String? address;

/// Create a copy of LocalHotspot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalHotspotCopyWith<_LocalHotspot> get copyWith => __$LocalHotspotCopyWithImpl<_LocalHotspot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalHotspot&&(identical(other.credentials, credentials) || other.credentials == credentials)&&(identical(other.interfaceName, interfaceName) || other.interfaceName == interfaceName)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,credentials,interfaceName,address);

@override
String toString() {
  return 'LocalHotspot(credentials: $credentials, interfaceName: $interfaceName, address: $address)';
}


}

/// @nodoc
abstract mixin class _$LocalHotspotCopyWith<$Res> implements $LocalHotspotCopyWith<$Res> {
  factory _$LocalHotspotCopyWith(_LocalHotspot value, $Res Function(_LocalHotspot) _then) = __$LocalHotspotCopyWithImpl;
@override @useResult
$Res call({
 WifiCredentials credentials, String? interfaceName, String? address
});


@override $WifiCredentialsCopyWith<$Res> get credentials;

}
/// @nodoc
class __$LocalHotspotCopyWithImpl<$Res>
    implements _$LocalHotspotCopyWith<$Res> {
  __$LocalHotspotCopyWithImpl(this._self, this._then);

  final _LocalHotspot _self;
  final $Res Function(_LocalHotspot) _then;

/// Create a copy of LocalHotspot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? credentials = null,Object? interfaceName = freezed,Object? address = freezed,}) {
  return _then(_LocalHotspot(
credentials: null == credentials ? _self.credentials : credentials // ignore: cast_nullable_to_non_nullable
as WifiCredentials,interfaceName: freezed == interfaceName ? _self.interfaceName : interfaceName // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of LocalHotspot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WifiCredentialsCopyWith<$Res> get credentials {
  
  return $WifiCredentialsCopyWith<$Res>(_self.credentials, (value) {
    return _then(_self.copyWith(credentials: value));
  });
}
}

// dart format on
