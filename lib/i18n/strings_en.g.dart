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
	@override String get title => 'frecu';
	@override String get settings => 'Settings';
	@override String get heading => 'Pick your room';
	@override String get createRoom => 'Create room';
	@override String get scanQr => 'Scan';
	@override String get joinRoom => 'Connect by IP';
	@override String get nearbyRooms => 'Nearby rooms';
	@override String get accessCode => 'Access code';
	@override String get roomName => 'Room name';
	@override late final _Translations$lobby$network$en network = _Translations$lobby$network$en._(_root);
	@override late final _Translations$lobby$tuner$en tuner = _Translations$lobby$tuner$en._(_root);
	@override late final _Translations$lobby$empty$en empty = _Translations$lobby$empty$en._(_root);
	@override late final _Translations$lobby$offline$en offline = _Translations$lobby$offline$en._(_root);
	@override List<String> get noteNames => [
		'C',
		'D♭',
		'D',
		'E♭',
		'E',
		'F',
		'F♯',
		'G',
		'A♭',
		'A',
		'B♭',
		'B',
	];
	@override String get noNote => '—';
	@override String hz({required Object value}) => '${value} Hz';
	@override String get decimalSeparator => '.';
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
	@override String get earpiece => 'Earpiece';
	@override String get bluetooth => 'Bluetooth';
	@override String get speaking => 'Speaking';
	@override String get muted => 'Muted';
	@override String get host => 'Host';
	@override String get roomClosed => 'Room has been closed by host';
	@override String get reconnecting => 'Reconnecting...';
	@override String get accept => 'Accept';
}

// Path: permissions
class _Translations$permissions$en extends Translations$permissions$es {
	_Translations$permissions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get back => 'Back';
	@override String stepOf({required Object current, required Object total}) => '${current} / ${total}';
	@override late final _Translations$permissions$welcome$en welcome = _Translations$permissions$welcome$en._(_root);
	@override late final _Translations$permissions$name$en name = _Translations$permissions$name$en._(_root);
	@override String get title => 'Three permissions and you\'re set.';
	@override String get description => 'Frecu only talks to your local network. Your voice never leaves your group.';
	@override String get microphone => 'Microphone';
	@override String get microphoneDesc => 'So your group can hear you.';
	@override String get nearbyDevices => 'Local network & nearby devices';
	@override String get nearbyDevicesDesc => 'To find frecus and use Bluetooth headphones.';
	@override String get notifications => 'Notifications';
	@override String get notificationsDesc => 'They keep the frecu alive with the screen off.';
	@override String get camera => 'The camera is only requested when scanning a QR code.';
	@override String get grant => 'Grant permissions';
	@override String get openSettings => 'Settings';
	@override String get finish => 'Continue';
	@override late final _Translations$permissions$status$en status = _Translations$permissions$status$en._(_root);
}

// Path: settings
class _Translations$settings$en extends Translations$settings$es {
	_Translations$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get back => 'Back';
	@override String get displayName => 'Display name';
	@override String get noName => 'No name';
	@override String get edit => 'Edit';
	@override late final _Translations$settings$editName$en editName = _Translations$settings$editName$en._(_root);
	@override String get voice => 'Voice';
	@override String get defaultTalkMode => 'Default talk mode';
	@override String get defaultTalkModeHelp => 'Applies every time you join a frecu.';
	@override late final _Translations$settings$talkMode$en talkMode = _Translations$settings$talkMode$en._(_root);
	@override String get appearance => 'Appearance';
	@override String get theme => 'Theme';
	@override String get themeHelp => 'Auto follows your phone';
	@override late final _Translations$settings$themeMode$en themeMode = _Translations$settings$themeMode$en._(_root);
	@override String get saveError => 'Couldn\'t save';
	@override String get footer => '100% local · no internet';
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

// Path: lobby.network
class _Translations$lobby$network$en extends Translations$lobby$network$es {
	_Translations$lobby$network$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get checking => 'Checking network';
	@override String connected({required Object ip}) => 'Network · ${ip}';
	@override String get offline => 'No local network';
}

// Path: lobby.tuner
class _Translations$lobby$tuner$en extends Translations$lobby$tuner$es {
	_Translations$lobby$tuner$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get scanning => 'Scanning · _frecu._tcp';
	@override String get paused => 'Search paused';
	@override String signals({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} signal',
		other: '${n} signals',
	);
}

// Path: lobby.empty
class _Translations$lobby$empty$en extends Translations$lobby$empty$es {
	_Translations$lobby$empty$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'No signals yet';
	@override String get message => 'Join the host\'s Wi-Fi or ask them to show you their QR.';
	@override String get searching => 'Still searching';
}

// Path: lobby.offline
class _Translations$lobby$offline$en extends Translations$lobby$offline$es {
	_Translations$lobby$offline$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'You\'re not on any Wi-Fi network.';
	@override String get message => 'Join the host\'s hotspot to find rooms.';
}

// Path: permissions.welcome
class _Translations$permissions$welcome$en extends Translations$permissions$welcome$es {
	_Translations$permissions$welcome$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kicker => 'No internet · no coverage';
	@override String get title => 'Your whole group on the same frecu.';
	@override String get message => 'Talk in real time with up to 6 people near you. All they need is a shared Wi-Fi network.';
	@override String get start => 'Get started';
}

// Path: permissions.name
class _Translations$permissions$name$en extends Translations$permissions$name$es {
	_Translations$permissions$name$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'What should we call you?';
	@override String get message => 'This is how you\'ll be seen and heard in every frecu.';
	@override String get signature => 'Your signal signature · born from your name';
	@override String get label => 'Display name';
	@override String get hint => 'Your name';
	@override String get help => 'You can change it anytime in Settings.';
	@override String tooLong({required Object max}) => 'Use ${max} characters at most.';
	@override String get saveError => 'Couldn\'t save your name. Please try again.';
	@override String get next => 'Continue';
}

// Path: permissions.status
class _Translations$permissions$status$en extends Translations$permissions$status$es {
	_Translations$permissions$status$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pending => 'Pending';
	@override String get granted => 'Granted';
	@override String get denied => 'Denied';
}

// Path: settings.editName
class _Translations$settings$editName$en extends Translations$settings$editName$es {
	_Translations$settings$editName$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Your name';
	@override String get message => 'This is how people will see and hear you in every frecu.';
	@override String get hint => 'Type your name';
	@override String get save => 'Save';
	@override String tooLong({required Object max}) => 'Use ${max} characters at most.';
	@override String get saveError => 'Couldn\'t save your name. Try again.';
}

// Path: settings.talkMode
class _Translations$settings$talkMode$en extends Translations$settings$talkMode$es {
	_Translations$settings$talkMode$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get pushToTalk => 'PTT';
	@override String get openMic => 'Open';
}

// Path: settings.themeMode
class _Translations$settings$themeMode$en extends Translations$settings$themeMode$es {
	_Translations$settings$themeMode$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get auto => 'Auto';
	@override String get light => 'Light';
	@override String get dark => 'Dark';
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
			'lobby.title' => 'frecu',
			'lobby.settings' => 'Settings',
			'lobby.heading' => 'Pick your room',
			'lobby.createRoom' => 'Create room',
			'lobby.scanQr' => 'Scan',
			'lobby.joinRoom' => 'Connect by IP',
			'lobby.nearbyRooms' => 'Nearby rooms',
			'lobby.accessCode' => 'Access code',
			'lobby.roomName' => 'Room name',
			'lobby.network.checking' => 'Checking network',
			'lobby.network.connected' => ({required Object ip}) => 'Network · ${ip}',
			'lobby.network.offline' => 'No local network',
			'lobby.tuner.scanning' => 'Scanning · _frecu._tcp',
			'lobby.tuner.paused' => 'Search paused',
			'lobby.tuner.signals' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} signal', other: '${n} signals', ), 
			'lobby.empty.title' => 'No signals yet',
			'lobby.empty.message' => 'Join the host\'s Wi-Fi or ask them to show you their QR.',
			'lobby.empty.searching' => 'Still searching',
			'lobby.offline.title' => 'You\'re not on any Wi-Fi network.',
			'lobby.offline.message' => 'Join the host\'s hotspot to find rooms.',
			'lobby.noteNames.0' => 'C',
			'lobby.noteNames.1' => 'D♭',
			'lobby.noteNames.2' => 'D',
			'lobby.noteNames.3' => 'E♭',
			'lobby.noteNames.4' => 'E',
			'lobby.noteNames.5' => 'F',
			'lobby.noteNames.6' => 'F♯',
			'lobby.noteNames.7' => 'G',
			'lobby.noteNames.8' => 'A♭',
			'lobby.noteNames.9' => 'A',
			'lobby.noteNames.10' => 'B♭',
			'lobby.noteNames.11' => 'B',
			'lobby.noNote' => '—',
			'lobby.hz' => ({required Object value}) => '${value} Hz',
			'lobby.decimalSeparator' => '.',
			'room.title' => 'Active room',
			'room.leave' => 'Leave room',
			'room.participants' => 'Participants',
			'room.pushToTalk' => 'Hold to talk',
			'room.openMic' => 'Open microphone',
			'room.speaker' => 'Speaker',
			'room.earpiece' => 'Earpiece',
			'room.bluetooth' => 'Bluetooth',
			'room.speaking' => 'Speaking',
			'room.muted' => 'Muted',
			'room.host' => 'Host',
			'room.roomClosed' => 'Room has been closed by host',
			'room.reconnecting' => 'Reconnecting...',
			'room.accept' => 'Accept',
			'permissions.back' => 'Back',
			'permissions.stepOf' => ({required Object current, required Object total}) => '${current} / ${total}',
			'permissions.welcome.kicker' => 'No internet · no coverage',
			'permissions.welcome.title' => 'Your whole group on the same frecu.',
			'permissions.welcome.message' => 'Talk in real time with up to 6 people near you. All they need is a shared Wi-Fi network.',
			'permissions.welcome.start' => 'Get started',
			'permissions.name.title' => 'What should we call you?',
			'permissions.name.message' => 'This is how you\'ll be seen and heard in every frecu.',
			'permissions.name.signature' => 'Your signal signature · born from your name',
			'permissions.name.label' => 'Display name',
			'permissions.name.hint' => 'Your name',
			'permissions.name.help' => 'You can change it anytime in Settings.',
			'permissions.name.tooLong' => ({required Object max}) => 'Use ${max} characters at most.',
			'permissions.name.saveError' => 'Couldn\'t save your name. Please try again.',
			'permissions.name.next' => 'Continue',
			'permissions.title' => 'Three permissions and you\'re set.',
			'permissions.description' => 'Frecu only talks to your local network. Your voice never leaves your group.',
			'permissions.microphone' => 'Microphone',
			'permissions.microphoneDesc' => 'So your group can hear you.',
			'permissions.nearbyDevices' => 'Local network & nearby devices',
			'permissions.nearbyDevicesDesc' => 'To find frecus and use Bluetooth headphones.',
			'permissions.notifications' => 'Notifications',
			'permissions.notificationsDesc' => 'They keep the frecu alive with the screen off.',
			'permissions.camera' => 'The camera is only requested when scanning a QR code.',
			'permissions.grant' => 'Grant permissions',
			'permissions.openSettings' => 'Settings',
			'permissions.finish' => 'Continue',
			'permissions.status.pending' => 'Pending',
			'permissions.status.granted' => 'Granted',
			'permissions.status.denied' => 'Denied',
			'settings.title' => 'Settings',
			'settings.back' => 'Back',
			'settings.displayName' => 'Display name',
			'settings.noName' => 'No name',
			'settings.edit' => 'Edit',
			'settings.editName.title' => 'Your name',
			'settings.editName.message' => 'This is how people will see and hear you in every frecu.',
			'settings.editName.hint' => 'Type your name',
			'settings.editName.save' => 'Save',
			'settings.editName.tooLong' => ({required Object max}) => 'Use ${max} characters at most.',
			'settings.editName.saveError' => 'Couldn\'t save your name. Try again.',
			'settings.voice' => 'Voice',
			'settings.defaultTalkMode' => 'Default talk mode',
			'settings.defaultTalkModeHelp' => 'Applies every time you join a frecu.',
			'settings.talkMode.pushToTalk' => 'PTT',
			'settings.talkMode.openMic' => 'Open',
			'settings.appearance' => 'Appearance',
			'settings.theme' => 'Theme',
			'settings.themeHelp' => 'Auto follows your phone',
			'settings.themeMode.auto' => 'Auto',
			'settings.themeMode.light' => 'Light',
			'settings.themeMode.dark' => 'Dark',
			'settings.saveError' => 'Couldn\'t save',
			'settings.footer' => '100% local · no internet',
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
