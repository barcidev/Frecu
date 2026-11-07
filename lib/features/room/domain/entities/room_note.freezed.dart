// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomNote {

 int get semitone;
/// Create a copy of RoomNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomNoteCopyWith<RoomNote> get copyWith => _$RoomNoteCopyWithImpl<RoomNote>(this as RoomNote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomNote&&(identical(other.semitone, semitone) || other.semitone == semitone));
}


@override
int get hashCode => Object.hash(runtimeType,semitone);

@override
String toString() {
  return 'RoomNote(semitone: $semitone)';
}


}

/// @nodoc
abstract mixin class $RoomNoteCopyWith<$Res>  {
  factory $RoomNoteCopyWith(RoomNote value, $Res Function(RoomNote) _then) = _$RoomNoteCopyWithImpl;
@useResult
$Res call({
 int semitone
});




}
/// @nodoc
class _$RoomNoteCopyWithImpl<$Res>
    implements $RoomNoteCopyWith<$Res> {
  _$RoomNoteCopyWithImpl(this._self, this._then);

  final RoomNote _self;
  final $Res Function(RoomNote) _then;

/// Create a copy of RoomNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? semitone = null,}) {
  return _then(_self.copyWith(
semitone: null == semitone ? _self.semitone : semitone // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomNote].
extension RoomNotePatterns on RoomNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomNote value)  $default,){
final _that = this;
switch (_that) {
case _RoomNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomNote value)?  $default,){
final _that = this;
switch (_that) {
case _RoomNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int semitone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomNote() when $default != null:
return $default(_that.semitone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int semitone)  $default,) {final _that = this;
switch (_that) {
case _RoomNote():
return $default(_that.semitone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int semitone)?  $default,) {final _that = this;
switch (_that) {
case _RoomNote() when $default != null:
return $default(_that.semitone);case _:
  return null;

}
}

}

/// @nodoc


class _RoomNote extends RoomNote {
  const _RoomNote({required this.semitone}): assert(semitone >= 0 && semitone < RoomNote.semitoneCount, 'El semitono de la nota va de 0 a 23.'),super._();
  

@override final  int semitone;

/// Create a copy of RoomNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomNoteCopyWith<_RoomNote> get copyWith => __$RoomNoteCopyWithImpl<_RoomNote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomNote&&(identical(other.semitone, semitone) || other.semitone == semitone));
}


@override
int get hashCode => Object.hash(runtimeType,semitone);

@override
String toString() {
  return 'RoomNote(semitone: $semitone)';
}


}

/// @nodoc
abstract mixin class _$RoomNoteCopyWith<$Res> implements $RoomNoteCopyWith<$Res> {
  factory _$RoomNoteCopyWith(_RoomNote value, $Res Function(_RoomNote) _then) = __$RoomNoteCopyWithImpl;
@override @useResult
$Res call({
 int semitone
});




}
/// @nodoc
class __$RoomNoteCopyWithImpl<$Res>
    implements _$RoomNoteCopyWith<$Res> {
  __$RoomNoteCopyWithImpl(this._self, this._then);

  final _RoomNote _self;
  final $Res Function(_RoomNote) _then;

/// Create a copy of RoomNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? semitone = null,}) {
  return _then(_RoomNote(
semitone: null == semitone ? _self.semitone : semitone // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
