// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signaling_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
SignalingMessage _$SignalingMessageFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'join':
          return SignalingJoinMessage.fromJson(
            json
          );
                case 'welcome':
          return SignalingWelcomeMessage.fromJson(
            json
          );
                case 'rejected':
          return SignalingRejectedMessage.fromJson(
            json
          );
                case 'peer_joined':
          return SignalingPeerJoinedMessage.fromJson(
            json
          );
                case 'peer_left':
          return SignalingPeerLeftMessage.fromJson(
            json
          );
                case 'offer':
          return SignalingOfferMessage.fromJson(
            json
          );
                case 'answer':
          return SignalingAnswerMessage.fromJson(
            json
          );
                case 'ice':
          return SignalingIceMessage.fromJson(
            json
          );
                case 'talk_state':
          return SignalingTalkStateMessage.fromJson(
            json
          );
                case 'quick_message':
          return SignalingQuickMessage.fromJson(
            json
          );
                case 'ping':
          return SignalingPingMessage.fromJson(
            json
          );
                case 'pong':
          return SignalingPongMessage.fromJson(
            json
          );
                case 'room_closed':
          return SignalingRoomClosedMessage.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'SignalingMessage',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$SignalingMessage {

 String get type;
/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingMessageCopyWith<SignalingMessage> get copyWith => _$SignalingMessageCopyWithImpl<SignalingMessage>(this as SignalingMessage, _$identity);

  /// Serializes this SignalingMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingMessage&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'SignalingMessage(type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingMessageCopyWith<$Res>  {
  factory $SignalingMessageCopyWith(SignalingMessage value, $Res Function(SignalingMessage) _then) = _$SignalingMessageCopyWithImpl;
@useResult
$Res call({
 String type
});




}
/// @nodoc
class _$SignalingMessageCopyWithImpl<$Res>
    implements $SignalingMessageCopyWith<$Res> {
  _$SignalingMessageCopyWithImpl(this._self, this._then);

  final SignalingMessage _self;
  final $Res Function(SignalingMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SignalingMessage].
extension SignalingMessagePatterns on SignalingMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SignalingJoinMessage value)?  join,TResult Function( SignalingWelcomeMessage value)?  welcome,TResult Function( SignalingRejectedMessage value)?  rejected,TResult Function( SignalingPeerJoinedMessage value)?  peerJoined,TResult Function( SignalingPeerLeftMessage value)?  peerLeft,TResult Function( SignalingOfferMessage value)?  offer,TResult Function( SignalingAnswerMessage value)?  answer,TResult Function( SignalingIceMessage value)?  ice,TResult Function( SignalingTalkStateMessage value)?  talkState,TResult Function( SignalingQuickMessage value)?  quickMessage,TResult Function( SignalingPingMessage value)?  ping,TResult Function( SignalingPongMessage value)?  pong,TResult Function( SignalingRoomClosedMessage value)?  roomClosed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SignalingJoinMessage() when join != null:
return join(_that);case SignalingWelcomeMessage() when welcome != null:
return welcome(_that);case SignalingRejectedMessage() when rejected != null:
return rejected(_that);case SignalingPeerJoinedMessage() when peerJoined != null:
return peerJoined(_that);case SignalingPeerLeftMessage() when peerLeft != null:
return peerLeft(_that);case SignalingOfferMessage() when offer != null:
return offer(_that);case SignalingAnswerMessage() when answer != null:
return answer(_that);case SignalingIceMessage() when ice != null:
return ice(_that);case SignalingTalkStateMessage() when talkState != null:
return talkState(_that);case SignalingQuickMessage() when quickMessage != null:
return quickMessage(_that);case SignalingPingMessage() when ping != null:
return ping(_that);case SignalingPongMessage() when pong != null:
return pong(_that);case SignalingRoomClosedMessage() when roomClosed != null:
return roomClosed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SignalingJoinMessage value)  join,required TResult Function( SignalingWelcomeMessage value)  welcome,required TResult Function( SignalingRejectedMessage value)  rejected,required TResult Function( SignalingPeerJoinedMessage value)  peerJoined,required TResult Function( SignalingPeerLeftMessage value)  peerLeft,required TResult Function( SignalingOfferMessage value)  offer,required TResult Function( SignalingAnswerMessage value)  answer,required TResult Function( SignalingIceMessage value)  ice,required TResult Function( SignalingTalkStateMessage value)  talkState,required TResult Function( SignalingQuickMessage value)  quickMessage,required TResult Function( SignalingPingMessage value)  ping,required TResult Function( SignalingPongMessage value)  pong,required TResult Function( SignalingRoomClosedMessage value)  roomClosed,}){
final _that = this;
switch (_that) {
case SignalingJoinMessage():
return join(_that);case SignalingWelcomeMessage():
return welcome(_that);case SignalingRejectedMessage():
return rejected(_that);case SignalingPeerJoinedMessage():
return peerJoined(_that);case SignalingPeerLeftMessage():
return peerLeft(_that);case SignalingOfferMessage():
return offer(_that);case SignalingAnswerMessage():
return answer(_that);case SignalingIceMessage():
return ice(_that);case SignalingTalkStateMessage():
return talkState(_that);case SignalingQuickMessage():
return quickMessage(_that);case SignalingPingMessage():
return ping(_that);case SignalingPongMessage():
return pong(_that);case SignalingRoomClosedMessage():
return roomClosed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SignalingJoinMessage value)?  join,TResult? Function( SignalingWelcomeMessage value)?  welcome,TResult? Function( SignalingRejectedMessage value)?  rejected,TResult? Function( SignalingPeerJoinedMessage value)?  peerJoined,TResult? Function( SignalingPeerLeftMessage value)?  peerLeft,TResult? Function( SignalingOfferMessage value)?  offer,TResult? Function( SignalingAnswerMessage value)?  answer,TResult? Function( SignalingIceMessage value)?  ice,TResult? Function( SignalingTalkStateMessage value)?  talkState,TResult? Function( SignalingQuickMessage value)?  quickMessage,TResult? Function( SignalingPingMessage value)?  ping,TResult? Function( SignalingPongMessage value)?  pong,TResult? Function( SignalingRoomClosedMessage value)?  roomClosed,}){
final _that = this;
switch (_that) {
case SignalingJoinMessage() when join != null:
return join(_that);case SignalingWelcomeMessage() when welcome != null:
return welcome(_that);case SignalingRejectedMessage() when rejected != null:
return rejected(_that);case SignalingPeerJoinedMessage() when peerJoined != null:
return peerJoined(_that);case SignalingPeerLeftMessage() when peerLeft != null:
return peerLeft(_that);case SignalingOfferMessage() when offer != null:
return offer(_that);case SignalingAnswerMessage() when answer != null:
return answer(_that);case SignalingIceMessage() when ice != null:
return ice(_that);case SignalingTalkStateMessage() when talkState != null:
return talkState(_that);case SignalingQuickMessage() when quickMessage != null:
return quickMessage(_that);case SignalingPingMessage() when ping != null:
return ping(_that);case SignalingPongMessage() when pong != null:
return pong(_that);case SignalingRoomClosedMessage() when roomClosed != null:
return roomClosed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String displayName,  String accessCode,  int protocolVersion,  String type)?  join,TResult Function( String peerId,  List<Participant> participants, @RoomNoteConverter()  RoomNote? note, @JsonKey(includeIfNull: false)  String? roomName,  String type)?  welcome,TResult Function( String reason,  String type)?  rejected,TResult Function( Participant participant,  String type)?  peerJoined,TResult Function( String peerId,  String type)?  peerLeft,TResult Function( String from,  String to,  String sdp,  String type)?  offer,TResult Function( String from,  String to,  String sdp,  String type)?  answer,TResult Function( String from,  String to,  String candidate,  String? sdpMid,  int? sdpMLineIndex,  String type)?  ice,TResult Function( String peerId,  bool isSpeaking, @JsonKey(includeIfNull: false)  bool? muted,  String type)?  talkState,TResult Function( String peerId,  String kind,  String type)?  quickMessage,TResult Function( int timestamp,  String type)?  ping,TResult Function( int timestamp,  String type)?  pong,TResult Function( String reason,  String type)?  roomClosed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SignalingJoinMessage() when join != null:
return join(_that.displayName,_that.accessCode,_that.protocolVersion,_that.type);case SignalingWelcomeMessage() when welcome != null:
return welcome(_that.peerId,_that.participants,_that.note,_that.roomName,_that.type);case SignalingRejectedMessage() when rejected != null:
return rejected(_that.reason,_that.type);case SignalingPeerJoinedMessage() when peerJoined != null:
return peerJoined(_that.participant,_that.type);case SignalingPeerLeftMessage() when peerLeft != null:
return peerLeft(_that.peerId,_that.type);case SignalingOfferMessage() when offer != null:
return offer(_that.from,_that.to,_that.sdp,_that.type);case SignalingAnswerMessage() when answer != null:
return answer(_that.from,_that.to,_that.sdp,_that.type);case SignalingIceMessage() when ice != null:
return ice(_that.from,_that.to,_that.candidate,_that.sdpMid,_that.sdpMLineIndex,_that.type);case SignalingTalkStateMessage() when talkState != null:
return talkState(_that.peerId,_that.isSpeaking,_that.muted,_that.type);case SignalingQuickMessage() when quickMessage != null:
return quickMessage(_that.peerId,_that.kind,_that.type);case SignalingPingMessage() when ping != null:
return ping(_that.timestamp,_that.type);case SignalingPongMessage() when pong != null:
return pong(_that.timestamp,_that.type);case SignalingRoomClosedMessage() when roomClosed != null:
return roomClosed(_that.reason,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String displayName,  String accessCode,  int protocolVersion,  String type)  join,required TResult Function( String peerId,  List<Participant> participants, @RoomNoteConverter()  RoomNote? note, @JsonKey(includeIfNull: false)  String? roomName,  String type)  welcome,required TResult Function( String reason,  String type)  rejected,required TResult Function( Participant participant,  String type)  peerJoined,required TResult Function( String peerId,  String type)  peerLeft,required TResult Function( String from,  String to,  String sdp,  String type)  offer,required TResult Function( String from,  String to,  String sdp,  String type)  answer,required TResult Function( String from,  String to,  String candidate,  String? sdpMid,  int? sdpMLineIndex,  String type)  ice,required TResult Function( String peerId,  bool isSpeaking, @JsonKey(includeIfNull: false)  bool? muted,  String type)  talkState,required TResult Function( String peerId,  String kind,  String type)  quickMessage,required TResult Function( int timestamp,  String type)  ping,required TResult Function( int timestamp,  String type)  pong,required TResult Function( String reason,  String type)  roomClosed,}) {final _that = this;
switch (_that) {
case SignalingJoinMessage():
return join(_that.displayName,_that.accessCode,_that.protocolVersion,_that.type);case SignalingWelcomeMessage():
return welcome(_that.peerId,_that.participants,_that.note,_that.roomName,_that.type);case SignalingRejectedMessage():
return rejected(_that.reason,_that.type);case SignalingPeerJoinedMessage():
return peerJoined(_that.participant,_that.type);case SignalingPeerLeftMessage():
return peerLeft(_that.peerId,_that.type);case SignalingOfferMessage():
return offer(_that.from,_that.to,_that.sdp,_that.type);case SignalingAnswerMessage():
return answer(_that.from,_that.to,_that.sdp,_that.type);case SignalingIceMessage():
return ice(_that.from,_that.to,_that.candidate,_that.sdpMid,_that.sdpMLineIndex,_that.type);case SignalingTalkStateMessage():
return talkState(_that.peerId,_that.isSpeaking,_that.muted,_that.type);case SignalingQuickMessage():
return quickMessage(_that.peerId,_that.kind,_that.type);case SignalingPingMessage():
return ping(_that.timestamp,_that.type);case SignalingPongMessage():
return pong(_that.timestamp,_that.type);case SignalingRoomClosedMessage():
return roomClosed(_that.reason,_that.type);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String displayName,  String accessCode,  int protocolVersion,  String type)?  join,TResult? Function( String peerId,  List<Participant> participants, @RoomNoteConverter()  RoomNote? note, @JsonKey(includeIfNull: false)  String? roomName,  String type)?  welcome,TResult? Function( String reason,  String type)?  rejected,TResult? Function( Participant participant,  String type)?  peerJoined,TResult? Function( String peerId,  String type)?  peerLeft,TResult? Function( String from,  String to,  String sdp,  String type)?  offer,TResult? Function( String from,  String to,  String sdp,  String type)?  answer,TResult? Function( String from,  String to,  String candidate,  String? sdpMid,  int? sdpMLineIndex,  String type)?  ice,TResult? Function( String peerId,  bool isSpeaking, @JsonKey(includeIfNull: false)  bool? muted,  String type)?  talkState,TResult? Function( String peerId,  String kind,  String type)?  quickMessage,TResult? Function( int timestamp,  String type)?  ping,TResult? Function( int timestamp,  String type)?  pong,TResult? Function( String reason,  String type)?  roomClosed,}) {final _that = this;
switch (_that) {
case SignalingJoinMessage() when join != null:
return join(_that.displayName,_that.accessCode,_that.protocolVersion,_that.type);case SignalingWelcomeMessage() when welcome != null:
return welcome(_that.peerId,_that.participants,_that.note,_that.roomName,_that.type);case SignalingRejectedMessage() when rejected != null:
return rejected(_that.reason,_that.type);case SignalingPeerJoinedMessage() when peerJoined != null:
return peerJoined(_that.participant,_that.type);case SignalingPeerLeftMessage() when peerLeft != null:
return peerLeft(_that.peerId,_that.type);case SignalingOfferMessage() when offer != null:
return offer(_that.from,_that.to,_that.sdp,_that.type);case SignalingAnswerMessage() when answer != null:
return answer(_that.from,_that.to,_that.sdp,_that.type);case SignalingIceMessage() when ice != null:
return ice(_that.from,_that.to,_that.candidate,_that.sdpMid,_that.sdpMLineIndex,_that.type);case SignalingTalkStateMessage() when talkState != null:
return talkState(_that.peerId,_that.isSpeaking,_that.muted,_that.type);case SignalingQuickMessage() when quickMessage != null:
return quickMessage(_that.peerId,_that.kind,_that.type);case SignalingPingMessage() when ping != null:
return ping(_that.timestamp,_that.type);case SignalingPongMessage() when pong != null:
return pong(_that.timestamp,_that.type);case SignalingRoomClosedMessage() when roomClosed != null:
return roomClosed(_that.reason,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class SignalingJoinMessage implements SignalingMessage {
  const SignalingJoinMessage({required this.displayName, required this.accessCode, this.protocolVersion = signalingProtocolVersion, this.type = 'join'});
  factory SignalingJoinMessage.fromJson(Map<String, dynamic> json) => _$SignalingJoinMessageFromJson(json);

 final  String displayName;
 final  String accessCode;
@JsonKey() final  int protocolVersion;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingJoinMessageCopyWith<SignalingJoinMessage> get copyWith => _$SignalingJoinMessageCopyWithImpl<SignalingJoinMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingJoinMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingJoinMessage&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.accessCode, accessCode) || other.accessCode == accessCode)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,displayName,accessCode,protocolVersion,type);

@override
String toString() {
  return 'SignalingMessage.join(displayName: $displayName, accessCode: $accessCode, protocolVersion: $protocolVersion, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingJoinMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingJoinMessageCopyWith(SignalingJoinMessage value, $Res Function(SignalingJoinMessage) _then) = _$SignalingJoinMessageCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String accessCode, int protocolVersion, String type
});




}
/// @nodoc
class _$SignalingJoinMessageCopyWithImpl<$Res>
    implements $SignalingJoinMessageCopyWith<$Res> {
  _$SignalingJoinMessageCopyWithImpl(this._self, this._then);

  final SignalingJoinMessage _self;
  final $Res Function(SignalingJoinMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? accessCode = null,Object? protocolVersion = null,Object? type = null,}) {
  return _then(SignalingJoinMessage(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,accessCode: null == accessCode ? _self.accessCode : accessCode // ignore: cast_nullable_to_non_nullable
as String,protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingWelcomeMessage implements SignalingMessage {
  const SignalingWelcomeMessage({required this.peerId, required this.participants, @RoomNoteConverter() this.note, @JsonKey(includeIfNull: false) this.roomName, this.type = 'welcome'});
  factory SignalingWelcomeMessage.fromJson(Map<String, dynamic> json) => _$SignalingWelcomeMessageFromJson(json);

 final  String peerId;
 final  List<Participant> participants;
@RoomNoteConverter() final  RoomNote? note;
@JsonKey(includeIfNull: false) final  String? roomName;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingWelcomeMessageCopyWith<SignalingWelcomeMessage> get copyWith => _$SignalingWelcomeMessageCopyWithImpl<SignalingWelcomeMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingWelcomeMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingWelcomeMessage&&(identical(other.peerId, peerId) || other.peerId == peerId)&&const DeepCollectionEquality().equals(other.participants, participants)&&(identical(other.note, note) || other.note == note)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,peerId,const DeepCollectionEquality().hash(participants),note,roomName,type);

@override
String toString() {
  return 'SignalingMessage.welcome(peerId: $peerId, participants: $participants, note: $note, roomName: $roomName, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingWelcomeMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingWelcomeMessageCopyWith(SignalingWelcomeMessage value, $Res Function(SignalingWelcomeMessage) _then) = _$SignalingWelcomeMessageCopyWithImpl;
@override @useResult
$Res call({
 String peerId, List<Participant> participants,@RoomNoteConverter() RoomNote? note,@JsonKey(includeIfNull: false) String? roomName, String type
});


$RoomNoteCopyWith<$Res>? get note;

}
/// @nodoc
class _$SignalingWelcomeMessageCopyWithImpl<$Res>
    implements $SignalingWelcomeMessageCopyWith<$Res> {
  _$SignalingWelcomeMessageCopyWithImpl(this._self, this._then);

  final SignalingWelcomeMessage _self;
  final $Res Function(SignalingWelcomeMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = null,Object? participants = null,Object? note = freezed,Object? roomName = freezed,Object? type = null,}) {
  return _then(SignalingWelcomeMessage(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<Participant>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as RoomNote?,roomName: freezed == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoomNoteCopyWith<$Res>? get note {
    if (_self.note == null) {
    return null;
  }

  return $RoomNoteCopyWith<$Res>(_self.note!, (value) {
    return _then(_self.copyWith(note: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class SignalingRejectedMessage implements SignalingMessage {
  const SignalingRejectedMessage({required this.reason, this.type = 'rejected'});
  factory SignalingRejectedMessage.fromJson(Map<String, dynamic> json) => _$SignalingRejectedMessageFromJson(json);

 final  String reason;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingRejectedMessageCopyWith<SignalingRejectedMessage> get copyWith => _$SignalingRejectedMessageCopyWithImpl<SignalingRejectedMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingRejectedMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingRejectedMessage&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason,type);

@override
String toString() {
  return 'SignalingMessage.rejected(reason: $reason, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingRejectedMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingRejectedMessageCopyWith(SignalingRejectedMessage value, $Res Function(SignalingRejectedMessage) _then) = _$SignalingRejectedMessageCopyWithImpl;
@override @useResult
$Res call({
 String reason, String type
});




}
/// @nodoc
class _$SignalingRejectedMessageCopyWithImpl<$Res>
    implements $SignalingRejectedMessageCopyWith<$Res> {
  _$SignalingRejectedMessageCopyWithImpl(this._self, this._then);

  final SignalingRejectedMessage _self;
  final $Res Function(SignalingRejectedMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? type = null,}) {
  return _then(SignalingRejectedMessage(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingPeerJoinedMessage implements SignalingMessage {
  const SignalingPeerJoinedMessage({required this.participant, this.type = 'peer_joined'});
  factory SignalingPeerJoinedMessage.fromJson(Map<String, dynamic> json) => _$SignalingPeerJoinedMessageFromJson(json);

 final  Participant participant;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingPeerJoinedMessageCopyWith<SignalingPeerJoinedMessage> get copyWith => _$SignalingPeerJoinedMessageCopyWithImpl<SignalingPeerJoinedMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingPeerJoinedMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingPeerJoinedMessage&&(identical(other.participant, participant) || other.participant == participant)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,participant,type);

@override
String toString() {
  return 'SignalingMessage.peerJoined(participant: $participant, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingPeerJoinedMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingPeerJoinedMessageCopyWith(SignalingPeerJoinedMessage value, $Res Function(SignalingPeerJoinedMessage) _then) = _$SignalingPeerJoinedMessageCopyWithImpl;
@override @useResult
$Res call({
 Participant participant, String type
});


$ParticipantCopyWith<$Res> get participant;

}
/// @nodoc
class _$SignalingPeerJoinedMessageCopyWithImpl<$Res>
    implements $SignalingPeerJoinedMessageCopyWith<$Res> {
  _$SignalingPeerJoinedMessageCopyWithImpl(this._self, this._then);

  final SignalingPeerJoinedMessage _self;
  final $Res Function(SignalingPeerJoinedMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? participant = null,Object? type = null,}) {
  return _then(SignalingPeerJoinedMessage(
participant: null == participant ? _self.participant : participant // ignore: cast_nullable_to_non_nullable
as Participant,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParticipantCopyWith<$Res> get participant {
  
  return $ParticipantCopyWith<$Res>(_self.participant, (value) {
    return _then(_self.copyWith(participant: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class SignalingPeerLeftMessage implements SignalingMessage {
  const SignalingPeerLeftMessage({required this.peerId, this.type = 'peer_left'});
  factory SignalingPeerLeftMessage.fromJson(Map<String, dynamic> json) => _$SignalingPeerLeftMessageFromJson(json);

 final  String peerId;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingPeerLeftMessageCopyWith<SignalingPeerLeftMessage> get copyWith => _$SignalingPeerLeftMessageCopyWithImpl<SignalingPeerLeftMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingPeerLeftMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingPeerLeftMessage&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,peerId,type);

@override
String toString() {
  return 'SignalingMessage.peerLeft(peerId: $peerId, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingPeerLeftMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingPeerLeftMessageCopyWith(SignalingPeerLeftMessage value, $Res Function(SignalingPeerLeftMessage) _then) = _$SignalingPeerLeftMessageCopyWithImpl;
@override @useResult
$Res call({
 String peerId, String type
});




}
/// @nodoc
class _$SignalingPeerLeftMessageCopyWithImpl<$Res>
    implements $SignalingPeerLeftMessageCopyWith<$Res> {
  _$SignalingPeerLeftMessageCopyWithImpl(this._self, this._then);

  final SignalingPeerLeftMessage _self;
  final $Res Function(SignalingPeerLeftMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = null,Object? type = null,}) {
  return _then(SignalingPeerLeftMessage(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingOfferMessage implements SignalingMessage {
  const SignalingOfferMessage({required this.from, required this.to, required this.sdp, this.type = 'offer'});
  factory SignalingOfferMessage.fromJson(Map<String, dynamic> json) => _$SignalingOfferMessageFromJson(json);

 final  String from;
 final  String to;
 final  String sdp;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingOfferMessageCopyWith<SignalingOfferMessage> get copyWith => _$SignalingOfferMessageCopyWithImpl<SignalingOfferMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingOfferMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingOfferMessage&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.sdp, sdp) || other.sdp == sdp)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,sdp,type);

@override
String toString() {
  return 'SignalingMessage.offer(from: $from, to: $to, sdp: $sdp, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingOfferMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingOfferMessageCopyWith(SignalingOfferMessage value, $Res Function(SignalingOfferMessage) _then) = _$SignalingOfferMessageCopyWithImpl;
@override @useResult
$Res call({
 String from, String to, String sdp, String type
});




}
/// @nodoc
class _$SignalingOfferMessageCopyWithImpl<$Res>
    implements $SignalingOfferMessageCopyWith<$Res> {
  _$SignalingOfferMessageCopyWithImpl(this._self, this._then);

  final SignalingOfferMessage _self;
  final $Res Function(SignalingOfferMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? sdp = null,Object? type = null,}) {
  return _then(SignalingOfferMessage(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,sdp: null == sdp ? _self.sdp : sdp // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingAnswerMessage implements SignalingMessage {
  const SignalingAnswerMessage({required this.from, required this.to, required this.sdp, this.type = 'answer'});
  factory SignalingAnswerMessage.fromJson(Map<String, dynamic> json) => _$SignalingAnswerMessageFromJson(json);

 final  String from;
 final  String to;
 final  String sdp;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingAnswerMessageCopyWith<SignalingAnswerMessage> get copyWith => _$SignalingAnswerMessageCopyWithImpl<SignalingAnswerMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingAnswerMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingAnswerMessage&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.sdp, sdp) || other.sdp == sdp)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,sdp,type);

@override
String toString() {
  return 'SignalingMessage.answer(from: $from, to: $to, sdp: $sdp, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingAnswerMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingAnswerMessageCopyWith(SignalingAnswerMessage value, $Res Function(SignalingAnswerMessage) _then) = _$SignalingAnswerMessageCopyWithImpl;
@override @useResult
$Res call({
 String from, String to, String sdp, String type
});




}
/// @nodoc
class _$SignalingAnswerMessageCopyWithImpl<$Res>
    implements $SignalingAnswerMessageCopyWith<$Res> {
  _$SignalingAnswerMessageCopyWithImpl(this._self, this._then);

  final SignalingAnswerMessage _self;
  final $Res Function(SignalingAnswerMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? sdp = null,Object? type = null,}) {
  return _then(SignalingAnswerMessage(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,sdp: null == sdp ? _self.sdp : sdp // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingIceMessage implements SignalingMessage {
  const SignalingIceMessage({required this.from, required this.to, required this.candidate, this.sdpMid, this.sdpMLineIndex, this.type = 'ice'});
  factory SignalingIceMessage.fromJson(Map<String, dynamic> json) => _$SignalingIceMessageFromJson(json);

 final  String from;
 final  String to;
 final  String candidate;
 final  String? sdpMid;
 final  int? sdpMLineIndex;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingIceMessageCopyWith<SignalingIceMessage> get copyWith => _$SignalingIceMessageCopyWithImpl<SignalingIceMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingIceMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingIceMessage&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.candidate, candidate) || other.candidate == candidate)&&(identical(other.sdpMid, sdpMid) || other.sdpMid == sdpMid)&&(identical(other.sdpMLineIndex, sdpMLineIndex) || other.sdpMLineIndex == sdpMLineIndex)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to,candidate,sdpMid,sdpMLineIndex,type);

@override
String toString() {
  return 'SignalingMessage.ice(from: $from, to: $to, candidate: $candidate, sdpMid: $sdpMid, sdpMLineIndex: $sdpMLineIndex, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingIceMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingIceMessageCopyWith(SignalingIceMessage value, $Res Function(SignalingIceMessage) _then) = _$SignalingIceMessageCopyWithImpl;
@override @useResult
$Res call({
 String from, String to, String candidate, String? sdpMid, int? sdpMLineIndex, String type
});




}
/// @nodoc
class _$SignalingIceMessageCopyWithImpl<$Res>
    implements $SignalingIceMessageCopyWith<$Res> {
  _$SignalingIceMessageCopyWithImpl(this._self, this._then);

  final SignalingIceMessage _self;
  final $Res Function(SignalingIceMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? candidate = null,Object? sdpMid = freezed,Object? sdpMLineIndex = freezed,Object? type = null,}) {
  return _then(SignalingIceMessage(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,candidate: null == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as String,sdpMid: freezed == sdpMid ? _self.sdpMid : sdpMid // ignore: cast_nullable_to_non_nullable
as String?,sdpMLineIndex: freezed == sdpMLineIndex ? _self.sdpMLineIndex : sdpMLineIndex // ignore: cast_nullable_to_non_nullable
as int?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingTalkStateMessage implements SignalingMessage {
  const SignalingTalkStateMessage({required this.peerId, required this.isSpeaking, @JsonKey(includeIfNull: false) this.muted, this.type = 'talk_state'});
  factory SignalingTalkStateMessage.fromJson(Map<String, dynamic> json) => _$SignalingTalkStateMessageFromJson(json);

 final  String peerId;
 final  bool isSpeaking;
@JsonKey(includeIfNull: false) final  bool? muted;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingTalkStateMessageCopyWith<SignalingTalkStateMessage> get copyWith => _$SignalingTalkStateMessageCopyWithImpl<SignalingTalkStateMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingTalkStateMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingTalkStateMessage&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.isSpeaking, isSpeaking) || other.isSpeaking == isSpeaking)&&(identical(other.muted, muted) || other.muted == muted)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,peerId,isSpeaking,muted,type);

@override
String toString() {
  return 'SignalingMessage.talkState(peerId: $peerId, isSpeaking: $isSpeaking, muted: $muted, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingTalkStateMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingTalkStateMessageCopyWith(SignalingTalkStateMessage value, $Res Function(SignalingTalkStateMessage) _then) = _$SignalingTalkStateMessageCopyWithImpl;
@override @useResult
$Res call({
 String peerId, bool isSpeaking,@JsonKey(includeIfNull: false) bool? muted, String type
});




}
/// @nodoc
class _$SignalingTalkStateMessageCopyWithImpl<$Res>
    implements $SignalingTalkStateMessageCopyWith<$Res> {
  _$SignalingTalkStateMessageCopyWithImpl(this._self, this._then);

  final SignalingTalkStateMessage _self;
  final $Res Function(SignalingTalkStateMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = null,Object? isSpeaking = null,Object? muted = freezed,Object? type = null,}) {
  return _then(SignalingTalkStateMessage(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String,isSpeaking: null == isSpeaking ? _self.isSpeaking : isSpeaking // ignore: cast_nullable_to_non_nullable
as bool,muted: freezed == muted ? _self.muted : muted // ignore: cast_nullable_to_non_nullable
as bool?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingQuickMessage implements SignalingMessage {
  const SignalingQuickMessage({required this.peerId, required this.kind, this.type = 'quick_message'});
  factory SignalingQuickMessage.fromJson(Map<String, dynamic> json) => _$SignalingQuickMessageFromJson(json);

 final  String peerId;
 final  String kind;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingQuickMessageCopyWith<SignalingQuickMessage> get copyWith => _$SignalingQuickMessageCopyWithImpl<SignalingQuickMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingQuickMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingQuickMessage&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,peerId,kind,type);

@override
String toString() {
  return 'SignalingMessage.quickMessage(peerId: $peerId, kind: $kind, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingQuickMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingQuickMessageCopyWith(SignalingQuickMessage value, $Res Function(SignalingQuickMessage) _then) = _$SignalingQuickMessageCopyWithImpl;
@override @useResult
$Res call({
 String peerId, String kind, String type
});




}
/// @nodoc
class _$SignalingQuickMessageCopyWithImpl<$Res>
    implements $SignalingQuickMessageCopyWith<$Res> {
  _$SignalingQuickMessageCopyWithImpl(this._self, this._then);

  final SignalingQuickMessage _self;
  final $Res Function(SignalingQuickMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = null,Object? kind = null,Object? type = null,}) {
  return _then(SignalingQuickMessage(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingPingMessage implements SignalingMessage {
  const SignalingPingMessage({required this.timestamp, this.type = 'ping'});
  factory SignalingPingMessage.fromJson(Map<String, dynamic> json) => _$SignalingPingMessageFromJson(json);

 final  int timestamp;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingPingMessageCopyWith<SignalingPingMessage> get copyWith => _$SignalingPingMessageCopyWithImpl<SignalingPingMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingPingMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingPingMessage&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,type);

@override
String toString() {
  return 'SignalingMessage.ping(timestamp: $timestamp, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingPingMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingPingMessageCopyWith(SignalingPingMessage value, $Res Function(SignalingPingMessage) _then) = _$SignalingPingMessageCopyWithImpl;
@override @useResult
$Res call({
 int timestamp, String type
});




}
/// @nodoc
class _$SignalingPingMessageCopyWithImpl<$Res>
    implements $SignalingPingMessageCopyWith<$Res> {
  _$SignalingPingMessageCopyWithImpl(this._self, this._then);

  final SignalingPingMessage _self;
  final $Res Function(SignalingPingMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? type = null,}) {
  return _then(SignalingPingMessage(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingPongMessage implements SignalingMessage {
  const SignalingPongMessage({required this.timestamp, this.type = 'pong'});
  factory SignalingPongMessage.fromJson(Map<String, dynamic> json) => _$SignalingPongMessageFromJson(json);

 final  int timestamp;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingPongMessageCopyWith<SignalingPongMessage> get copyWith => _$SignalingPongMessageCopyWithImpl<SignalingPongMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingPongMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingPongMessage&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,type);

@override
String toString() {
  return 'SignalingMessage.pong(timestamp: $timestamp, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingPongMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingPongMessageCopyWith(SignalingPongMessage value, $Res Function(SignalingPongMessage) _then) = _$SignalingPongMessageCopyWithImpl;
@override @useResult
$Res call({
 int timestamp, String type
});




}
/// @nodoc
class _$SignalingPongMessageCopyWithImpl<$Res>
    implements $SignalingPongMessageCopyWith<$Res> {
  _$SignalingPongMessageCopyWithImpl(this._self, this._then);

  final SignalingPongMessage _self;
  final $Res Function(SignalingPongMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? type = null,}) {
  return _then(SignalingPongMessage(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SignalingRoomClosedMessage implements SignalingMessage {
  const SignalingRoomClosedMessage({required this.reason, this.type = 'room_closed'});
  factory SignalingRoomClosedMessage.fromJson(Map<String, dynamic> json) => _$SignalingRoomClosedMessageFromJson(json);

 final  String reason;
@override@JsonKey() final  String type;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalingRoomClosedMessageCopyWith<SignalingRoomClosedMessage> get copyWith => _$SignalingRoomClosedMessageCopyWithImpl<SignalingRoomClosedMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SignalingRoomClosedMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalingRoomClosedMessage&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason,type);

@override
String toString() {
  return 'SignalingMessage.roomClosed(reason: $reason, type: $type)';
}


}

/// @nodoc
abstract mixin class $SignalingRoomClosedMessageCopyWith<$Res> implements $SignalingMessageCopyWith<$Res> {
  factory $SignalingRoomClosedMessageCopyWith(SignalingRoomClosedMessage value, $Res Function(SignalingRoomClosedMessage) _then) = _$SignalingRoomClosedMessageCopyWithImpl;
@override @useResult
$Res call({
 String reason, String type
});




}
/// @nodoc
class _$SignalingRoomClosedMessageCopyWithImpl<$Res>
    implements $SignalingRoomClosedMessageCopyWith<$Res> {
  _$SignalingRoomClosedMessageCopyWithImpl(this._self, this._then);

  final SignalingRoomClosedMessage _self;
  final $Res Function(SignalingRoomClosedMessage) _then;

/// Create a copy of SignalingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,Object? type = null,}) {
  return _then(SignalingRoomClosedMessage(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
