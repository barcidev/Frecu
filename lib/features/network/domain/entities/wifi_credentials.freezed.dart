// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wifi_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WifiCredentials {

 String get ssid; String? get passphrase;
/// Create a copy of WifiCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WifiCredentialsCopyWith<WifiCredentials> get copyWith => _$WifiCredentialsCopyWithImpl<WifiCredentials>(this as WifiCredentials, _$identity);

  /// Serializes this WifiCredentials to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WifiCredentials&&(identical(other.ssid, ssid) || other.ssid == ssid)&&(identical(other.passphrase, passphrase) || other.passphrase == passphrase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ssid,passphrase);

@override
String toString() {
  return 'WifiCredentials(ssid: $ssid, passphrase: $passphrase)';
}


}

/// @nodoc
abstract mixin class $WifiCredentialsCopyWith<$Res>  {
  factory $WifiCredentialsCopyWith(WifiCredentials value, $Res Function(WifiCredentials) _then) = _$WifiCredentialsCopyWithImpl;
@useResult
$Res call({
 String ssid, String? passphrase
});




}
/// @nodoc
class _$WifiCredentialsCopyWithImpl<$Res>
    implements $WifiCredentialsCopyWith<$Res> {
  _$WifiCredentialsCopyWithImpl(this._self, this._then);

  final WifiCredentials _self;
  final $Res Function(WifiCredentials) _then;

/// Create a copy of WifiCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ssid = null,Object? passphrase = freezed,}) {
  return _then(_self.copyWith(
ssid: null == ssid ? _self.ssid : ssid // ignore: cast_nullable_to_non_nullable
as String,passphrase: freezed == passphrase ? _self.passphrase : passphrase // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WifiCredentials].
extension WifiCredentialsPatterns on WifiCredentials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WifiCredentials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WifiCredentials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WifiCredentials value)  $default,){
final _that = this;
switch (_that) {
case _WifiCredentials():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WifiCredentials value)?  $default,){
final _that = this;
switch (_that) {
case _WifiCredentials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ssid,  String? passphrase)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WifiCredentials() when $default != null:
return $default(_that.ssid,_that.passphrase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ssid,  String? passphrase)  $default,) {final _that = this;
switch (_that) {
case _WifiCredentials():
return $default(_that.ssid,_that.passphrase);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ssid,  String? passphrase)?  $default,) {final _that = this;
switch (_that) {
case _WifiCredentials() when $default != null:
return $default(_that.ssid,_that.passphrase);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WifiCredentials implements WifiCredentials {
  const _WifiCredentials({required this.ssid, this.passphrase});
  factory _WifiCredentials.fromJson(Map<String, dynamic> json) => _$WifiCredentialsFromJson(json);

@override final  String ssid;
@override final  String? passphrase;

/// Create a copy of WifiCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WifiCredentialsCopyWith<_WifiCredentials> get copyWith => __$WifiCredentialsCopyWithImpl<_WifiCredentials>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WifiCredentialsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WifiCredentials&&(identical(other.ssid, ssid) || other.ssid == ssid)&&(identical(other.passphrase, passphrase) || other.passphrase == passphrase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ssid,passphrase);

@override
String toString() {
  return 'WifiCredentials(ssid: $ssid, passphrase: $passphrase)';
}


}

/// @nodoc
abstract mixin class _$WifiCredentialsCopyWith<$Res> implements $WifiCredentialsCopyWith<$Res> {
  factory _$WifiCredentialsCopyWith(_WifiCredentials value, $Res Function(_WifiCredentials) _then) = __$WifiCredentialsCopyWithImpl;
@override @useResult
$Res call({
 String ssid, String? passphrase
});




}
/// @nodoc
class __$WifiCredentialsCopyWithImpl<$Res>
    implements _$WifiCredentialsCopyWith<$Res> {
  __$WifiCredentialsCopyWithImpl(this._self, this._then);

  final _WifiCredentials _self;
  final $Res Function(_WifiCredentials) _then;

/// Create a copy of WifiCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ssid = null,Object? passphrase = freezed,}) {
  return _then(_WifiCredentials(
ssid: null == ssid ? _self.ssid : ssid // ignore: cast_nullable_to_non_nullable
as String,passphrase: freezed == passphrase ? _self.passphrase : passphrase // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
