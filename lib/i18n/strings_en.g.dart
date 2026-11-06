///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$en app = _Translations$app$en._(_root);
	@override late final _Translations$lobby$en lobby = _Translations$lobby$en._(_root);
	@override late final _Translations$room$en room = _Translations$room$en._(_root);
	@override late final _Translations$permissions$en permissions = _Translations$permissions$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$errors$en errors = _Translations$errors$en._(_root);
}

// Path: app
class _Translations$app$en extends Translations$app$es {
	_Translations$app$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Frecu';
}

// Path: lobby
class _Translations$lobby$en extends Translations$lobby$es {
	_Translations$lobby$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Frecu';
	@override String get createRoom => 'Create room';
	@override String get scanQr => 'Scan QR';
	@override String get joinRoom => 'Join room';
	@override String get nearbyRooms => 'Nearby rooms';
	@override String get noRoomsNearby => 'No rooms found on local network';
	@override String get accessCode => 'Access code';
	@override String get roomName => 'Room name';
	@override String get yourName => 'Your display name';
}

// Path: room
class _Translations$room$en extends Translations$room$es {
	_Translations$room$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Active room';
	@override String get leave => 'Leave room';
	@override String get participants => 'Participants';
	@override String get pushToTalk => 'Hold to talk';
	@override String get openMic => 'Open microphone';
	@override String get speaker => 'Speaker';
	@override String get bluetooth => 'Bluetooth';
	@override String get speaking => 'Speaking';
	@override String get muted => 'Muted';
	@override String get host => 'Host';
	@override String get roomClosed => 'Room has been closed by host';
}

// Path: permissions
class _Translations$permissions$en extends Translations$permissions$es {
	_Translations$permissions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Required permissions';
	@override String get description => 'Frecu needs permissions to communicate without internet.';
	@override String get microphone => 'Microphone';
	@override String get microphoneDesc => 'Transmits your voice to other peers in the room.';
	@override String get nearbyDevices => 'Local network & nearby devices';
	@override String get nearbyDevicesDesc => 'Discovers and connects with nearby phones on the network.';
	@override String get notifications => 'Notifications';
	@override String get notificationsDesc => 'Keeps the intercom active in background with screen off.';
	@override String get grant => 'Grant permissions';
	@override String get granted => 'Permissions granted';
}

// Path: settings
class _Translations$settings$en extends Translations$settings$es {
	_Translations$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get displayName => 'Display name';
	@override String get defaultTalkMode => 'Default talk mode';
	@override String get language => 'Language';
}

// Path: errors
class _Translations$errors$en extends Translations$errors$es {
	_Translations$errors$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get network => 'Local network error';
	@override String get permissionDenied => 'Required permission denied';
	@override String get roomFull => 'Room is full (max 6 participants)';
	@override String get invalidAccessCode => 'Invalid access code';
	@override String get hostUnreachable => 'Host is unreachable';
	@override String get audio => 'Audio subsystem error';
	@override String get unexpected => 'Unexpected error';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Frecu',
			'lobby.title' => 'Frecu',
			'lobby.createRoom' => 'Create room',
			'lobby.scanQr' => 'Scan QR',
			'lobby.joinRoom' => 'Join room',
			'lobby.nearbyRooms' => 'Nearby rooms',
			'lobby.noRoomsNearby' => 'No rooms found on local network',
			'lobby.accessCode' => 'Access code',
			'lobby.roomName' => 'Room name',
			'lobby.yourName' => 'Your display name',
			'room.title' => 'Active room',
			'room.leave' => 'Leave room',
			'room.participants' => 'Participants',
			'room.pushToTalk' => 'Hold to talk',
			'room.openMic' => 'Open microphone',
			'room.speaker' => 'Speaker',
			'room.bluetooth' => 'Bluetooth',
			'room.speaking' => 'Speaking',
			'room.muted' => 'Muted',
			'room.host' => 'Host',
			'room.roomClosed' => 'Room has been closed by host',
			'permissions.title' => 'Required permissions',
			'permissions.description' => 'Frecu needs permissions to communicate without internet.',
			'permissions.microphone' => 'Microphone',
			'permissions.microphoneDesc' => 'Transmits your voice to other peers in the room.',
			'permissions.nearbyDevices' => 'Local network & nearby devices',
			'permissions.nearbyDevicesDesc' => 'Discovers and connects with nearby phones on the network.',
			'permissions.notifications' => 'Notifications',
			'permissions.notificationsDesc' => 'Keeps the intercom active in background with screen off.',
			'permissions.grant' => 'Grant permissions',
			'permissions.granted' => 'Permissions granted',
			'settings.title' => 'Settings',
			'settings.displayName' => 'Display name',
			'settings.defaultTalkMode' => 'Default talk mode',
			'settings.language' => 'Language',
			'errors.network' => 'Local network error',
			'errors.permissionDenied' => 'Required permission denied',
			'errors.roomFull' => 'Room is full (max 6 participants)',
			'errors.invalidAccessCode' => 'Invalid access code',
			'errors.hostUnreachable' => 'Host is unreachable',
			'errors.audio' => 'Audio subsystem error',
			'errors.unexpected' => 'Unexpected error',
			_ => null,
		};
	}
}
