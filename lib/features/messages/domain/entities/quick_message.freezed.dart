// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quick_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuickMessage {

/// Id en la frecu de quien lo envió.
 String get senderId;/// Qué dice.
 QuickMessageKind get kind;
/// Create a copy of QuickMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickMessageCopyWith<QuickMessage> get copyWith => _$QuickMessageCopyWithImpl<QuickMessage>(this as QuickMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickMessage&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,senderId,kind);

@override
String toString() {
  return 'QuickMessage(senderId: $senderId, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $QuickMessageCopyWith<$Res>  {
  factory $QuickMessageCopyWith(QuickMessage value, $Res Function(QuickMessage) _then) = _$QuickMessageCopyWithImpl;
@useResult
$Res call({
 String senderId, QuickMessageKind kind
});




}
/// @nodoc
class _$QuickMessageCopyWithImpl<$Res>
    implements $QuickMessageCopyWith<$Res> {
  _$QuickMessageCopyWithImpl(this._self, this._then);

  final QuickMessage _self;
  final $Res Function(QuickMessage) _then;

/// Create a copy of QuickMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? senderId = null,Object? kind = null,}) {
  return _then(_self.copyWith(
senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QuickMessageKind,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickMessage].
extension QuickMessagePatterns on QuickMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickMessage value)  $default,){
final _that = this;
switch (_that) {
case _QuickMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickMessage value)?  $default,){
final _that = this;
switch (_that) {
case _QuickMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String senderId,  QuickMessageKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickMessage() when $default != null:
return $default(_that.senderId,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String senderId,  QuickMessageKind kind)  $default,) {final _that = this;
switch (_that) {
case _QuickMessage():
return $default(_that.senderId,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String senderId,  QuickMessageKind kind)?  $default,) {final _that = this;
switch (_that) {
case _QuickMessage() when $default != null:
return $default(_that.senderId,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _QuickMessage implements QuickMessage {
  const _QuickMessage({required this.senderId, required this.kind});
  

/// Id en la frecu de quien lo envió.
@override final  String senderId;
/// Qué dice.
@override final  QuickMessageKind kind;

/// Create a copy of QuickMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickMessageCopyWith<_QuickMessage> get copyWith => __$QuickMessageCopyWithImpl<_QuickMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickMessage&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,senderId,kind);

@override
String toString() {
  return 'QuickMessage(senderId: $senderId, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$QuickMessageCopyWith<$Res> implements $QuickMessageCopyWith<$Res> {
  factory _$QuickMessageCopyWith(_QuickMessage value, $Res Function(_QuickMessage) _then) = __$QuickMessageCopyWithImpl;
@override @useResult
$Res call({
 String senderId, QuickMessageKind kind
});




}
/// @nodoc
class __$QuickMessageCopyWithImpl<$Res>
    implements _$QuickMessageCopyWith<$Res> {
  __$QuickMessageCopyWithImpl(this._self, this._then);

  final _QuickMessage _self;
  final $Res Function(_QuickMessage) _then;

/// Create a copy of QuickMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? senderId = null,Object? kind = null,}) {
  return _then(_QuickMessage(
senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QuickMessageKind,
  ));
}


}

// dart format on
