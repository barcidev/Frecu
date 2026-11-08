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
	@override late final _Translations$lobby$join$en join = _Translations$lobby$join$en._(_root);
	@override String get settings => 'Settings';
	@override String get heading => 'Pick your room';
	@override String get createRoom => 'Create room';
	@override String get scanQr => 'Scan';
	@override String get joinRoom => 'Connect by IP';
	@override String get nearbyRooms => 'Nearby rooms';
	@override String get accessCode => 'Access code';
	@override late final _Translations$lobby$network$en network = _Translations$lobby$network$en._(_root);
	@override late final _Translations$lobby$tuner$en tuner = _Translations$lobby$tuner$en._(_root);
	@override late final _Translations$lobby$empty$en empty = _Translations$lobby$empty$en._(_root);
	@override late final _Translations$lobby$offline$en offline = _Translations$lobby$offline$en._(_root);
	@override late final _Translations$lobby$newRoom$en newRoom = _Translations$lobby$newRoom$en._(_root);
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
	@override String get reconnecting => 'Reconnecting...';
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
	@override late final _Translations$room$mesh$en mesh = _Translations$room$mesh$en._(_root);
	@override late final _Translations$room$header$en header = _Translations$room$header$en._(_root);
	@override late final _Translations$room$sheets$en sheets = _Translations$room$sheets$en._(_root);
	@override late final _Translations$room$closure$en closure = _Translations$room$closure$en._(_root);
	@override late final _Translations$room$talk$en talk = _Translations$room$talk$en._(_root);
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

// Path: lobby.join
class _Translations$lobby$join$en extends Translations$lobby$join$es {
	_Translations$lobby$join$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get close => 'Close';
	@override String port({required Object port}) => 'Port ${port}';
	@override String get wrongCode => 'Wrong code. Check it and try again.';
	@override String get roomFullHint => 'You can join when someone leaves.';
	@override String get unreachableHint => 'Make sure you\'re on the same Wi-Fi network.';
	@override late final _Translations$lobby$join$pin$en pin = _Translations$lobby$join$pin$en._(_root);
	@override late final _Translations$lobby$join$ip$en ip = _Translations$lobby$join$ip$en._(_root);
	@override late final _Translations$lobby$join$scan$en scan = _Translations$lobby$join$scan$en._(_root);
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

// Path: lobby.newRoom
class _Translations$lobby$newRoom$en extends Translations$lobby$newRoom$es {
	_Translations$lobby$newRoom$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get back => 'Back';
	@override String step({required Object current, required Object total}) => 'Step ${current} of ${total}';
	@override late final _Translations$lobby$newRoom$guide$en guide = _Translations$lobby$newRoom$guide$en._(_root);
	@override String get title => 'New room';
	@override String get soundsIn => 'Your room sounds in';
	@override String openedAt({required Object time}) => 'Opened at ${time}';
	@override String get name => 'Room name';
	@override String get nameHint => 'E.g. Sunday ride';
	@override String defaultName({required Object name}) => '${name}\'s room';
	@override String get untitled => 'My room';
	@override String get code => 'Access code';
	@override String get codeDigits => '4 digits';
	@override String get regenerate => 'Generate another';
	@override String get codeHelp => 'Share it only with your group: it keeps strangers on the same network out.';
	@override String get open => 'Open room';
	@override String clockLabel({required Object time, required Object note}) => 'Circle of fifths clock: ${time}, ${note}';
}

// Path: room.mesh
class _Translations$room$mesh$en extends Translations$room$mesh$es {
	_Translations$room$mesh$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get you => 'You';
	@override String get youHost => 'You · host';
	@override String get onAir => 'On air';
	@override String get connecting => 'Connecting';
	@override String get reconnecting => 'Reconnecting';
	@override String get free => 'Free';
	@override String get invite => 'Invite';
}

// Path: room.header
class _Translations$room$header$en extends Translations$room$header$es {
	_Translations$room$header$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get youAreHost => 'You\'re the host';
	@override String hostedBy({required Object name}) => 'Host · ${name}';
	@override String hz({required Object value}) => '${value} Hz';
	@override String note({required Object note, required Object hz}) => 'Note ${note}, ${hz} Hz';
	@override String get invite => 'Invite';
}

// Path: room.sheets
class _Translations$room$sheets$en extends Translations$room$sheets$es {
	_Translations$room$sheets$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get close => 'Close';
	@override late final _Translations$room$sheets$invite$en invite = _Translations$room$sheets$invite$en._(_root);
	@override late final _Translations$room$sheets$route$en route = _Translations$room$sheets$route$en._(_root);
	@override late final _Translations$room$sheets$leave$en leave = _Translations$room$sheets$leave$en._(_root);
}

// Path: room.closure
class _Translations$room$closure$en extends Translations$room$closure$es {
	_Translations$room$closure$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get offAir => 'Off the air';
	@override String noteOffAir({required Object note}) => '${note} · off the air';
	@override String get title => 'End of transmission';
	@override String get host => 'You closed the frecu. Everyone was disconnected.';
	@override String get peer => 'The host closed the frecu. You can join another one whenever you like.';
	@override String get lost => 'The host\'s signal was lost. You can join another one whenever you like.';
	@override String get duration => 'Duration';
	@override String get people => 'People';
	@override String get note => 'Note';
	@override String get home => 'Back to home';
}

// Path: room.talk
class _Translations$room$talk$en extends Translations$room$talk$es {
	_Translations$room$talk$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get modePtt => 'PTT';
	@override String get modeOpen => 'Open';
	@override late final _Translations$room$talk$core$en core = _Translations$room$talk$core$en._(_root);
	@override late final _Translations$room$talk$hint$en hint = _Translations$room$talk$hint$en._(_root);
	@override late final _Translations$room$talk$island$en island = _Translations$room$talk$island$en._(_root);
	@override late final _Translations$room$talk$echo$en echo = _Translations$room$talk$echo$en._(_root);
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

// Path: lobby.join.pin
class _Translations$lobby$join$pin$en extends Translations$lobby$join$pin$es {
	_Translations$lobby$join$pin$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get message => 'Enter the access code. Ask the host for it.';
	@override String get autoSend => 'Sent once all 4 digits are in';
	@override String get checking => 'Checking with the host…';
	@override String get correct => 'Code accepted · joining';
	@override String get delete => 'Delete';
	@override String get joiningAs => 'You\'ll join as';
}

// Path: lobby.join.ip
class _Translations$lobby$join$ip$en extends Translations$lobby$join$ip$es {
	_Translations$lobby$join$ip$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kicker => 'Manual connection';
	@override String get message => 'Use it if the room isn\'t on the list.';
	@override String get host => 'Host IP';
	@override String noAnswer({required Object port}) => 'No answer on port ${port}';
	@override String get connect => 'Connect';
}

// Path: lobby.join.scan
class _Translations$lobby$join$scan$en extends Translations$lobby$join$scan$es {
	_Translations$lobby$join$scan$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Scan invite';
	@override String get subtitle => 'Room QR';
	@override String get back => 'Back';
	@override String get torch => 'Flashlight';
	@override String get hint => 'Point at the QR the host shows on their phone.';
	@override String get invalid => 'This QR isn\'t a Frecu invite.';
	@override String get found => 'Room found';
	@override String get noNote => 'Room without a note';
	@override String get join => 'Join';
}

// Path: lobby.newRoom.guide
class _Translations$lobby$newRoom$guide$en extends Translations$lobby$newRoom$guide$es {
	_Translations$lobby$newRoom$guide$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Set up the network';
	@override String get heading => 'Turn on your hotspot';
	@override String get message => 'Your phone will be the group\'s antenna.';
	@override String get android => 'Android';
	@override String get iphone => 'iPhone';
	@override List<HotspotStep> get androidSteps => [
		_Translations$lobby$newRoom$guide$androidSteps$0$en._(_root),
		_Translations$lobby$newRoom$guide$androidSteps$1$en._(_root),
		_Translations$lobby$newRoom$guide$androidSteps$2$en._(_root),
	];
	@override List<HotspotStep> get iphoneSteps => [
		_Translations$lobby$newRoom$guide$iphoneSteps$0$en._(_root),
		_Translations$lobby$newRoom$guide$iphoneSteps$1$en._(_root),
		_Translations$lobby$newRoom$guide$iphoneSteps$2$en._(_root),
	];
	@override String get ready => 'It\'s on';
	@override String get sameWifi => 'We\'re already on the same Wi-Fi';
}

// Path: room.sheets.invite
class _Translations$room$sheets$invite$en extends Translations$room$sheets$invite$es {
	_Translations$room$sheets$invite$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kicker => 'Invite to the frecu';
	@override String get title => 'Scan to join';
	@override String get message => 'From Frecu › Scan. The QR already includes the code.';
	@override String get note => 'Note';
	@override String get code => 'Code';
	@override String get host => 'Host';
	@override String port({required Object port}) => 'Port ${port}';
	@override String footer({required Object list}) => 'It also shows up in “${list}” for anyone on your network.';
	@override String get qr => 'Invite QR code';
}

// Path: room.sheets.route
class _Translations$room$sheets$route$en extends Translations$room$sheets$route$es {
	_Translations$room$sheets$route$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kicker => 'Audio output';
	@override String get title => 'Where do you listen?';
	@override String get message => 'When you plug in headphones, the audio switches by itself.';
	@override String get speakerSub => 'Hands-free';
	@override String get earpieceSub => 'Phone to your ear';
	@override String get bluetoothOn => 'Connected';
	@override String get bluetoothOff => 'No device';
	@override String label({required Object route}) => 'Audio output: ${route}';
}

// Path: room.sheets.leave
class _Translations$room$sheets$leave$en extends Translations$room$sheets$leave$es {
	_Translations$room$sheets$leave$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get peerTitle => 'Leave the frecu?';
	@override String get peerMessage => 'You can join again with the access code.';
	@override String get peerConfirm => 'Leave the frecu';
	@override String get hostTitle => 'Close the frecu for everyone';
	@override String get hostAlone => 'You\'re the host. If you leave, the frecu closes.';
	@override String get hostOne => 'You\'re the host. If you leave, the frecu closes for the other person.';
	@override String hostMany({required Object count}) => 'You\'re the host. If you leave, the frecu closes for the other ${count} people.';
	@override String get hostConfirm => 'Close frecu';
	@override String get cancel => 'Cancel';
}

// Path: room.talk.core
class _Translations$room$talk$core$en extends Translations$room$talk$core$es {
	_Translations$room$talk$core$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get hold => 'Hold';
	@override String get onAir => 'On air';
	@override String get open => 'Open';
	@override String get silence => 'Muted';
	@override String get standby => 'Standby';
	@override String get talk => 'Talk';
}

// Path: room.talk.hint
class _Translations$room$talk$hint$en extends Translations$room$talk$hint$es {
	_Translations$room$talk$hint$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get idle => 'Hold to talk';
	@override String get alone => 'Show the QR so your group can join';
	@override String receiving({required Object name}) => '${name} is talking · you can reply';
	@override String get onAir => 'Release to listen';
	@override String get open => 'Tap to mute yourself';
	@override String get muted => 'Tap to turn on your microphone';
	@override String get connecting => 'Connecting to the host…';
	@override String get reconnecting => 'Restoring the connection…';
}

// Path: room.talk.island
class _Translations$room$talk$island$en extends Translations$room$talk$island$es {
	_Translations$room$talk$island$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String online({required Object count, required Object max}) => 'Online · ${count}/${max}';
	@override String openMic({required Object count, required Object max}) => 'Open mic · ${count}/${max}';
	@override String muted({required Object count, required Object max}) => 'Muted · ${count}/${max}';
	@override String onAir({required Object time}) => 'On air · ${time}';
	@override String receiving({required Object name}) => '${name} · talking';
	@override String get waiting => 'On air · waiting for your group';
	@override String get connecting => 'Connecting…';
	@override String get reconnecting => 'Reconnecting…';
}

// Path: room.talk.echo
class _Translations$room$talk$echo$en extends Translations$room$talk$echo$es {
	_Translations$room$talk$echo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Open mic on speaker.';
	@override String get message => 'Use headphones to avoid echo.';
	@override String get dismiss => 'Dismiss notice';
}

// Path: lobby.newRoom.guide.androidSteps.0
class _Translations$lobby$newRoom$guide$androidSteps$0$en extends Translations$lobby$newRoom$guide$androidSteps$0$es with HotspotStep {
	_Translations$lobby$newRoom$guide$androidSteps$0$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Open Settings › Hotspot';
	@override String get rest => ' (the name varies by brand).';
}

// Path: lobby.newRoom.guide.androidSteps.1
class _Translations$lobby$newRoom$guide$androidSteps$1$en extends Translations$lobby$newRoom$guide$androidSteps$1$es with HotspotStep {
	_Translations$lobby$newRoom$guide$androidSteps$1$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Turn it on';
	@override String get rest => ' and share its name and password with your group.';
}

// Path: lobby.newRoom.guide.androidSteps.2
class _Translations$lobby$newRoom$guide$androidSteps$2$en extends Translations$lobby$newRoom$guide$androidSteps$2$es with HotspotStep {
	_Translations$lobby$newRoom$guide$androidSteps$2$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Come back to Frecu';
	@override String get rest => ' and open your room. It doesn\'t use your mobile data.';
}

// Path: lobby.newRoom.guide.iphoneSteps.0
class _Translations$lobby$newRoom$guide$iphoneSteps$0$en extends Translations$lobby$newRoom$guide$iphoneSteps$0$es with HotspotStep {
	_Translations$lobby$newRoom$guide$iphoneSteps$0$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Open Settings › Personal Hotspot';
	@override String get rest => ' and turn on “Allow Others to Join”.';
}

// Path: lobby.newRoom.guide.iphoneSteps.1
class _Translations$lobby$newRoom$guide$iphoneSteps$1$en extends Translations$lobby$newRoom$guide$iphoneSteps$1$es with HotspotStep {
	_Translations$lobby$newRoom$guide$iphoneSteps$1$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Share the password';
	@override String get rest => ' with your group so they join your network.';
}

// Path: lobby.newRoom.guide.iphoneSteps.2
class _Translations$lobby$newRoom$guide$iphoneSteps$2$en extends Translations$lobby$newRoom$guide$iphoneSteps$2$es with HotspotStep {
	_Translations$lobby$newRoom$guide$iphoneSteps$2$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Keep Frecu open';
	@override String get rest => ' while they join. On iPhone we recommend that the host uses Android.';
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
			'lobby.join.close' => 'Close',
			'lobby.join.port' => ({required Object port}) => 'Port ${port}',
			'lobby.join.wrongCode' => 'Wrong code. Check it and try again.',
			'lobby.join.roomFullHint' => 'You can join when someone leaves.',
			'lobby.join.unreachableHint' => 'Make sure you\'re on the same Wi-Fi network.',
			'lobby.join.pin.message' => 'Enter the access code. Ask the host for it.',
			'lobby.join.pin.autoSend' => 'Sent once all 4 digits are in',
			'lobby.join.pin.checking' => 'Checking with the host…',
			'lobby.join.pin.correct' => 'Code accepted · joining',
			'lobby.join.pin.delete' => 'Delete',
			'lobby.join.pin.joiningAs' => 'You\'ll join as',
			'lobby.join.ip.kicker' => 'Manual connection',
			'lobby.join.ip.message' => 'Use it if the room isn\'t on the list.',
			'lobby.join.ip.host' => 'Host IP',
			'lobby.join.ip.noAnswer' => ({required Object port}) => 'No answer on port ${port}',
			'lobby.join.ip.connect' => 'Connect',
			'lobby.join.scan.title' => 'Scan invite',
			'lobby.join.scan.subtitle' => 'Room QR',
			'lobby.join.scan.back' => 'Back',
			'lobby.join.scan.torch' => 'Flashlight',
			'lobby.join.scan.hint' => 'Point at the QR the host shows on their phone.',
			'lobby.join.scan.invalid' => 'This QR isn\'t a Frecu invite.',
			'lobby.join.scan.found' => 'Room found',
			'lobby.join.scan.noNote' => 'Room without a note',
			'lobby.join.scan.join' => 'Join',
			'lobby.settings' => 'Settings',
			'lobby.heading' => 'Pick your room',
			'lobby.createRoom' => 'Create room',
			'lobby.scanQr' => 'Scan',
			'lobby.joinRoom' => 'Connect by IP',
			'lobby.nearbyRooms' => 'Nearby rooms',
			'lobby.accessCode' => 'Access code',
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
			'lobby.newRoom.back' => 'Back',
			'lobby.newRoom.step' => ({required Object current, required Object total}) => 'Step ${current} of ${total}',
			'lobby.newRoom.guide.title' => 'Set up the network',
			'lobby.newRoom.guide.heading' => 'Turn on your hotspot',
			'lobby.newRoom.guide.message' => 'Your phone will be the group\'s antenna.',
			'lobby.newRoom.guide.android' => 'Android',
			'lobby.newRoom.guide.iphone' => 'iPhone',
			'lobby.newRoom.guide.androidSteps.0.lead' => 'Open Settings › Hotspot',
			'lobby.newRoom.guide.androidSteps.0.rest' => ' (the name varies by brand).',
			'lobby.newRoom.guide.androidSteps.1.lead' => 'Turn it on',
			'lobby.newRoom.guide.androidSteps.1.rest' => ' and share its name and password with your group.',
			'lobby.newRoom.guide.androidSteps.2.lead' => 'Come back to Frecu',
			'lobby.newRoom.guide.androidSteps.2.rest' => ' and open your room. It doesn\'t use your mobile data.',
			'lobby.newRoom.guide.iphoneSteps.0.lead' => 'Open Settings › Personal Hotspot',
			'lobby.newRoom.guide.iphoneSteps.0.rest' => ' and turn on “Allow Others to Join”.',
			'lobby.newRoom.guide.iphoneSteps.1.lead' => 'Share the password',
			'lobby.newRoom.guide.iphoneSteps.1.rest' => ' with your group so they join your network.',
			'lobby.newRoom.guide.iphoneSteps.2.lead' => 'Keep Frecu open',
			'lobby.newRoom.guide.iphoneSteps.2.rest' => ' while they join. On iPhone we recommend that the host uses Android.',
			'lobby.newRoom.guide.ready' => 'It\'s on',
			'lobby.newRoom.guide.sameWifi' => 'We\'re already on the same Wi-Fi',
			'lobby.newRoom.title' => 'New room',
			'lobby.newRoom.soundsIn' => 'Your room sounds in',
			'lobby.newRoom.openedAt' => ({required Object time}) => 'Opened at ${time}',
			'lobby.newRoom.name' => 'Room name',
			'lobby.newRoom.nameHint' => 'E.g. Sunday ride',
			'lobby.newRoom.defaultName' => ({required Object name}) => '${name}\'s room',
			'lobby.newRoom.untitled' => 'My room',
			'lobby.newRoom.code' => 'Access code',
			'lobby.newRoom.codeDigits' => '4 digits',
			'lobby.newRoom.regenerate' => 'Generate another',
			'lobby.newRoom.codeHelp' => 'Share it only with your group: it keeps strangers on the same network out.',
			'lobby.newRoom.open' => 'Open room',
			'lobby.newRoom.clockLabel' => ({required Object time, required Object note}) => 'Circle of fifths clock: ${time}, ${note}',
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
			'room.reconnecting' => 'Reconnecting...',
			'room.noteNames.0' => 'C',
			'room.noteNames.1' => 'D♭',
			'room.noteNames.2' => 'D',
			'room.noteNames.3' => 'E♭',
			'room.noteNames.4' => 'E',
			'room.noteNames.5' => 'F',
			'room.noteNames.6' => 'F♯',
			'room.noteNames.7' => 'G',
			'room.noteNames.8' => 'A♭',
			'room.noteNames.9' => 'A',
			'room.noteNames.10' => 'B♭',
			'room.noteNames.11' => 'B',
			'room.mesh.you' => 'You',
			'room.mesh.youHost' => 'You · host',
			'room.mesh.onAir' => 'On air',
			'room.mesh.connecting' => 'Connecting',
			'room.mesh.reconnecting' => 'Reconnecting',
			'room.mesh.free' => 'Free',
			'room.mesh.invite' => 'Invite',
			'room.header.youAreHost' => 'You\'re the host',
			'room.header.hostedBy' => ({required Object name}) => 'Host · ${name}',
			'room.header.hz' => ({required Object value}) => '${value} Hz',
			'room.header.note' => ({required Object note, required Object hz}) => 'Note ${note}, ${hz} Hz',
			'room.header.invite' => 'Invite',
			'room.sheets.close' => 'Close',
			'room.sheets.invite.kicker' => 'Invite to the frecu',
			'room.sheets.invite.title' => 'Scan to join',
			'room.sheets.invite.message' => 'From Frecu › Scan. The QR already includes the code.',
			'room.sheets.invite.note' => 'Note',
			'room.sheets.invite.code' => 'Code',
			'room.sheets.invite.host' => 'Host',
			'room.sheets.invite.port' => ({required Object port}) => 'Port ${port}',
			'room.sheets.invite.footer' => ({required Object list}) => 'It also shows up in “${list}” for anyone on your network.',
			'room.sheets.invite.qr' => 'Invite QR code',
			'room.sheets.route.kicker' => 'Audio output',
			'room.sheets.route.title' => 'Where do you listen?',
			'room.sheets.route.message' => 'When you plug in headphones, the audio switches by itself.',
			'room.sheets.route.speakerSub' => 'Hands-free',
			'room.sheets.route.earpieceSub' => 'Phone to your ear',
			'room.sheets.route.bluetoothOn' => 'Connected',
			'room.sheets.route.bluetoothOff' => 'No device',
			'room.sheets.route.label' => ({required Object route}) => 'Audio output: ${route}',
			'room.sheets.leave.peerTitle' => 'Leave the frecu?',
			'room.sheets.leave.peerMessage' => 'You can join again with the access code.',
			'room.sheets.leave.peerConfirm' => 'Leave the frecu',
			'room.sheets.leave.hostTitle' => 'Close the frecu for everyone',
			'room.sheets.leave.hostAlone' => 'You\'re the host. If you leave, the frecu closes.',
			'room.sheets.leave.hostOne' => 'You\'re the host. If you leave, the frecu closes for the other person.',
			'room.sheets.leave.hostMany' => ({required Object count}) => 'You\'re the host. If you leave, the frecu closes for the other ${count} people.',
			'room.sheets.leave.hostConfirm' => 'Close frecu',
			'room.sheets.leave.cancel' => 'Cancel',
			'room.closure.offAir' => 'Off the air',
			'room.closure.noteOffAir' => ({required Object note}) => '${note} · off the air',
			'room.closure.title' => 'End of transmission',
			'room.closure.host' => 'You closed the frecu. Everyone was disconnected.',
			'room.closure.peer' => 'The host closed the frecu. You can join another one whenever you like.',
			'room.closure.lost' => 'The host\'s signal was lost. You can join another one whenever you like.',
			'room.closure.duration' => 'Duration',
			'room.closure.people' => 'People',
			'room.closure.note' => 'Note',
			'room.closure.home' => 'Back to home',
			'room.talk.modePtt' => 'PTT',
			'room.talk.modeOpen' => 'Open',
			'room.talk.core.hold' => 'Hold',
			'room.talk.core.onAir' => 'On air',
			'room.talk.core.open' => 'Open',
			'room.talk.core.silence' => 'Muted',
			'room.talk.core.standby' => 'Standby',
			'room.talk.core.talk' => 'Talk',
			'room.talk.hint.idle' => 'Hold to talk',
			'room.talk.hint.alone' => 'Show the QR so your group can join',
			'room.talk.hint.receiving' => ({required Object name}) => '${name} is talking · you can reply',
			'room.talk.hint.onAir' => 'Release to listen',
			'room.talk.hint.open' => 'Tap to mute yourself',
			'room.talk.hint.muted' => 'Tap to turn on your microphone',
			'room.talk.hint.connecting' => 'Connecting to the host…',
			'room.talk.hint.reconnecting' => 'Restoring the connection…',
			'room.talk.island.online' => ({required Object count, required Object max}) => 'Online · ${count}/${max}',
			'room.talk.island.openMic' => ({required Object count, required Object max}) => 'Open mic · ${count}/${max}',
			'room.talk.island.muted' => ({required Object count, required Object max}) => 'Muted · ${count}/${max}',
			'room.talk.island.onAir' => ({required Object time}) => 'On air · ${time}',
			'room.talk.island.receiving' => ({required Object name}) => '${name} · talking',
			'room.talk.island.waiting' => 'On air · waiting for your group',
			'room.talk.island.connecting' => 'Connecting…',
			'room.talk.island.reconnecting' => 'Reconnecting…',
			'room.talk.echo.title' => 'Open mic on speaker.',
			'room.talk.echo.message' => 'Use headphones to avoid echo.',
			'room.talk.echo.dismiss' => 'Dismiss notice',
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
