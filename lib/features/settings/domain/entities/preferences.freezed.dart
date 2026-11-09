// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Preferences {

/// Nombre visible en las frecus; nulo si aún no se pidió.
 String? get displayName;/// Tema de la app: Auto (sigue al sistema), Claro u Oscuro.
 ThemePreference get themePreference;/// Modo de habla con el que se entra a una frecu.
 TalkMode get defaultTalkMode;/// Idioma de la app: Auto (sigue al teléfono), español o inglés.
 LocalePreference get localePreference;/// Vibrar al transmitir, cuando alguien empieza a hablar y si se pierde
/// la conexión.
 bool get vibration;/// Hablar con el botón de volumen (solo Android), apagado por defecto.
 bool get volumePtt;/// Pasar al auricular al llevarse el teléfono a la oreja.
 bool get earpieceOnRaise;
/// Create a copy of Preferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreferencesCopyWith<Preferences> get copyWith => _$PreferencesCopyWithImpl<Preferences>(this as Preferences, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Preferences&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.themePreference, themePreference) || other.themePreference == themePreference)&&(identical(other.defaultTalkMode, defaultTalkMode) || other.defaultTalkMode == defaultTalkMode)&&(identical(other.localePreference, localePreference) || other.localePreference == localePreference)&&(identical(other.vibration, vibration) || other.vibration == vibration)&&(identical(other.volumePtt, volumePtt) || other.volumePtt == volumePtt)&&(identical(other.earpieceOnRaise, earpieceOnRaise) || other.earpieceOnRaise == earpieceOnRaise));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,themePreference,defaultTalkMode,localePreference,vibration,volumePtt,earpieceOnRaise);

@override
String toString() {
  return 'Preferences(displayName: $displayName, themePreference: $themePreference, defaultTalkMode: $defaultTalkMode, localePreference: $localePreference, vibration: $vibration, volumePtt: $volumePtt, earpieceOnRaise: $earpieceOnRaise)';
}


}

/// @nodoc
abstract mixin class $PreferencesCopyWith<$Res>  {
  factory $PreferencesCopyWith(Preferences value, $Res Function(Preferences) _then) = _$PreferencesCopyWithImpl;
@useResult
$Res call({
 String? displayName, ThemePreference themePreference, TalkMode defaultTalkMode, LocalePreference localePreference, bool vibration, bool volumePtt, bool earpieceOnRaise
});




}
/// @nodoc
class _$PreferencesCopyWithImpl<$Res>
    implements $PreferencesCopyWith<$Res> {
  _$PreferencesCopyWithImpl(this._self, this._then);

  final Preferences _self;
  final $Res Function(Preferences) _then;

/// Create a copy of Preferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = freezed,Object? themePreference = null,Object? defaultTalkMode = null,Object? localePreference = null,Object? vibration = null,Object? volumePtt = null,Object? earpieceOnRaise = null,}) {
  return _then(_self.copyWith(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,themePreference: null == themePreference ? _self.themePreference : themePreference // ignore: cast_nullable_to_non_nullable
as ThemePreference,defaultTalkMode: null == defaultTalkMode ? _self.defaultTalkMode : defaultTalkMode // ignore: cast_nullable_to_non_nullable
as TalkMode,localePreference: null == localePreference ? _self.localePreference : localePreference // ignore: cast_nullable_to_non_nullable
as LocalePreference,vibration: null == vibration ? _self.vibration : vibration // ignore: cast_nullable_to_non_nullable
as bool,volumePtt: null == volumePtt ? _self.volumePtt : volumePtt // ignore: cast_nullable_to_non_nullable
as bool,earpieceOnRaise: null == earpieceOnRaise ? _self.earpieceOnRaise : earpieceOnRaise // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Preferences].
extension PreferencesPatterns on Preferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Preferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Preferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Preferences value)  $default,){
final _that = this;
switch (_that) {
case _Preferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Preferences value)?  $default,){
final _that = this;
switch (_that) {
case _Preferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? displayName,  ThemePreference themePreference,  TalkMode defaultTalkMode,  LocalePreference localePreference,  bool vibration,  bool volumePtt,  bool earpieceOnRaise)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Preferences() when $default != null:
return $default(_that.displayName,_that.themePreference,_that.defaultTalkMode,_that.localePreference,_that.vibration,_that.volumePtt,_that.earpieceOnRaise);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? displayName,  ThemePreference themePreference,  TalkMode defaultTalkMode,  LocalePreference localePreference,  bool vibration,  bool volumePtt,  bool earpieceOnRaise)  $default,) {final _that = this;
switch (_that) {
case _Preferences():
return $default(_that.displayName,_that.themePreference,_that.defaultTalkMode,_that.localePreference,_that.vibration,_that.volumePtt,_that.earpieceOnRaise);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? displayName,  ThemePreference themePreference,  TalkMode defaultTalkMode,  LocalePreference localePreference,  bool vibration,  bool volumePtt,  bool earpieceOnRaise)?  $default,) {final _that = this;
switch (_that) {
case _Preferences() when $default != null:
return $default(_that.displayName,_that.themePreference,_that.defaultTalkMode,_that.localePreference,_that.vibration,_that.volumePtt,_that.earpieceOnRaise);case _:
  return null;

}
}

}

/// @nodoc


class _Preferences implements Preferences {
  const _Preferences({this.displayName, this.themePreference = ThemePreference.auto, this.defaultTalkMode = TalkMode.pushToTalk, this.localePreference = LocalePreference.auto, this.vibration = true, this.volumePtt = false, this.earpieceOnRaise = true});
  

/// Nombre visible en las frecus; nulo si aún no se pidió.
@override final  String? displayName;
/// Tema de la app: Auto (sigue al sistema), Claro u Oscuro.
@override@JsonKey() final  ThemePreference themePreference;
/// Modo de habla con el que se entra a una frecu.
@override@JsonKey() final  TalkMode defaultTalkMode;
/// Idioma de la app: Auto (sigue al teléfono), español o inglés.
@override@JsonKey() final  LocalePreference localePreference;
/// Vibrar al transmitir, cuando alguien empieza a hablar y si se pierde
/// la conexión.
@override@JsonKey() final  bool vibration;
/// Hablar con el botón de volumen (solo Android), apagado por defecto.
@override@JsonKey() final  bool volumePtt;
/// Pasar al auricular al llevarse el teléfono a la oreja.
@override@JsonKey() final  bool earpieceOnRaise;

/// Create a copy of Preferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreferencesCopyWith<_Preferences> get copyWith => __$PreferencesCopyWithImpl<_Preferences>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Preferences&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.themePreference, themePreference) || other.themePreference == themePreference)&&(identical(other.defaultTalkMode, defaultTalkMode) || other.defaultTalkMode == defaultTalkMode)&&(identical(other.localePreference, localePreference) || other.localePreference == localePreference)&&(identical(other.vibration, vibration) || other.vibration == vibration)&&(identical(other.volumePtt, volumePtt) || other.volumePtt == volumePtt)&&(identical(other.earpieceOnRaise, earpieceOnRaise) || other.earpieceOnRaise == earpieceOnRaise));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,themePreference,defaultTalkMode,localePreference,vibration,volumePtt,earpieceOnRaise);

@override
String toString() {
  return 'Preferences(displayName: $displayName, themePreference: $themePreference, defaultTalkMode: $defaultTalkMode, localePreference: $localePreference, vibration: $vibration, volumePtt: $volumePtt, earpieceOnRaise: $earpieceOnRaise)';
}


}

/// @nodoc
abstract mixin class _$PreferencesCopyWith<$Res> implements $PreferencesCopyWith<$Res> {
  factory _$PreferencesCopyWith(_Preferences value, $Res Function(_Preferences) _then) = __$PreferencesCopyWithImpl;
@override @useResult
$Res call({
 String? displayName, ThemePreference themePreference, TalkMode defaultTalkMode, LocalePreference localePreference, bool vibration, bool volumePtt, bool earpieceOnRaise
});




}
/// @nodoc
class __$PreferencesCopyWithImpl<$Res>
    implements _$PreferencesCopyWith<$Res> {
  __$PreferencesCopyWithImpl(this._self, this._then);

  final _Preferences _self;
  final $Res Function(_Preferences) _then;

/// Create a copy of Preferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = freezed,Object? themePreference = null,Object? defaultTalkMode = null,Object? localePreference = null,Object? vibration = null,Object? volumePtt = null,Object? earpieceOnRaise = null,}) {
  return _then(_Preferences(
displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,themePreference: null == themePreference ? _self.themePreference : themePreference // ignore: cast_nullable_to_non_nullable
as ThemePreference,defaultTalkMode: null == defaultTalkMode ? _self.defaultTalkMode : defaultTalkMode // ignore: cast_nullable_to_non_nullable
as TalkMode,localePreference: null == localePreference ? _self.localePreference : localePreference // ignore: cast_nullable_to_non_nullable
as LocalePreference,vibration: null == vibration ? _self.vibration : vibration // ignore: cast_nullable_to_non_nullable
as bool,volumePtt: null == volumePtt ? _self.volumePtt : volumePtt // ignore: cast_nullable_to_non_nullable
as bool,earpieceOnRaise: null == earpieceOnRaise ? _self.earpieceOnRaise : earpieceOnRaise // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
