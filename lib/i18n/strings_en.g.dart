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
	@override late final _Translations$nfcIos$en nfcIos = _Translations$nfcIos$en._(_root);
	@override late final _Translations$errors$en errors = _Translations$errors$en._(_root);
	@override late final _Translations$splash$en splash = _Translations$splash$en._(_root);
	@override late final _Translations$messages$en messages = _Translations$messages$en._(_root);
	@override late final _Translations$location$en location = _Translations$location$en._(_root);
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
	@override late final _Translations$lobby$nfc$en nfc = _Translations$lobby$nfc$en._(_root);
	@override String get title => 'frecu';
	@override late final _Translations$lobby$join$en join = _Translations$lobby$join$en._(_root);
	@override String get settings => 'Settings';
	@override String get heading => 'Pick your room';
	@override String get createRoom => 'Create room';
	@override String get scanQr => 'Scan';
	@override String get joinRoom => 'Connect by IP';
	@override String get nearbyRooms => 'Nearby rooms';
	@override String get accessCode => 'Access code';
	@override String get unnamedRoom => 'Unnamed room';
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
	@override late final _Translations$room$network$en network = _Translations$room$network$en._(_root);
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
	@override late final _Translations$room$handover$en handover = _Translations$room$handover$en._(_root);
	@override late final _Translations$room$closure$en closure = _Translations$room$closure$en._(_root);
	@override late final _Translations$room$internet$en internet = _Translations$room$internet$en._(_root);
	@override late final _Translations$room$talk$en talk = _Translations$room$talk$en._(_root);
	@override late final _Translations$room$notification$en notification = _Translations$room$notification$en._(_root);
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
	@override String get general => 'General';
	@override late final _Translations$settings$language$en language = _Translations$settings$language$en._(_root);
	@override late final _Translations$settings$permissions$en permissions = _Translations$settings$permissions$en._(_root);
	@override String get hotspotGuide => 'Hotspot guide';
	@override late final _Translations$settings$windFilter$en windFilter = _Translations$settings$windFilter$en._(_root);
	@override late final _Translations$settings$earpieceOnRaise$en earpieceOnRaise = _Translations$settings$earpieceOnRaise$en._(_root);
	@override late final _Translations$settings$volumePtt$en volumePtt = _Translations$settings$volumePtt$en._(_root);
	@override late final _Translations$settings$vibration$en vibration = _Translations$settings$vibration$en._(_root);
	@override String get licenses => 'Licenses';
	@override String get appearance => 'Appearance';
	@override String get theme => 'Theme';
	@override String get themeHelp => 'Auto follows your phone';
	@override late final _Translations$settings$themeMode$en themeMode = _Translations$settings$themeMode$en._(_root);
	@override String get saveError => 'Couldn\'t save';
	@override String footer({required Object app}) => '${app} · 100% local · no internet';
	@override String appVersion({required Object version}) => 'Frecu ${version}';
}

// Path: nfcIos
class _Translations$nfcIos$en extends Translations$nfcIos$es {
	_Translations$nfcIos$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get read => 'Hold the host\'s phone or the frecu tag near.';
	@override String get write => 'Hold the NFC tag near.';
	@override String get done => 'Done';
	@override String get notInvite => 'That\'s not a Frecu invitation.';
	@override String get failed => 'Didn\'t work. Try again.';
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
	@override String get versionMismatch => 'This frecu uses another version of Frecu';
	@override String get audio => 'Audio subsystem error';
	@override String get hotspot => 'The room\'s network couldn\'t be created';
	@override String get wifiJoin => 'Couldn\'t connect to the room\'s network';
	@override String get nfc => 'Could not use NFC';
	@override String get unexpected => 'Unexpected error';
}

// Path: splash
class _Translations$splash$en extends Translations$splash$es {
	_Translations$splash$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'frecu';
	@override String get tagline => 'Group voice. No internet.';
	@override String version({required Object version}) => 'v${version}';
	@override String get localNetwork => 'Local network';
	@override String get mesh => 'P2P mesh';
	@override String get skip => 'Tap to enter';
}

// Path: messages
class _Translations$messages$en extends Translations$messages$es {
	_Translations$messages$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get button => 'Messages';
	@override String get kicker => 'For the whole frecu';
	@override String get title => 'Quick messages';
	@override String get message => 'They arrive instantly and vibrate, even with the screen off.';
	@override late final _Translations$messages$kinds$en kinds = _Translations$messages$kinds$en._(_root);
	@override String get sosHold => 'Hold to send SOS';
	@override String get sosHoldHelp => 'Alarm for everyone until someone answers';
	@override String sent({required Object text}) => 'Sent · ${text}';
	@override String get sosSent => 'SOS sent to your group';
	@override String received({required Object name, required Object text}) => '${name} · ${text}';
	@override String get sendError => 'Couldn\'t send: no connection to the host';
	@override late final _Translations$messages$sos$en sos = _Translations$messages$sos$en._(_root);
}

// Path: location
class _Translations$location$en extends Translations$location$es {
	_Translations$location$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$location$share$en share = _Translations$location$share$en._(_root);
	@override String get sharingTag => 'Sharing your location';
	@override String get denied => 'No location permission';
	@override String get deniedForever => 'No location permission: turn it on in your phone\'s settings';
	@override String get failed => 'Couldn\'t use your location';
	@override String behind({required Object name}) => '${name} fell behind';
	@override String behindCaption({required Object distance}) => 'Behind · ${distance}';
	@override String towards({required Object distance, required Object direction}) => '${distance} ${direction}';
	@override String sosDetail({required Object distance, required Object direction}) => 'They\'re ${distance} to the ${direction}. Tell the group if you\'re heading there.';
	@override String meters({required Object value}) => '${value} m';
	@override String kilometers({required Object value}) => '${value} km';
	@override late final _Translations$location$compass$en compass = _Translations$location$compass$en._(_root);
	@override late final _Translations$location$compassLong$en compassLong = _Translations$location$compassLong$en._(_root);
}

// Path: lobby.nfc
class _Translations$lobby$nfc$en extends Translations$lobby$nfc$es {
	_Translations$lobby$nfc$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get byIp => 'By IP';
	@override String get button => 'By NFC';
	@override String get kicker => 'Join by NFC';
	@override String get title => 'Bring your phone close';
	@override String get message => 'Touch the back of your phone to the host\'s, or to a frecu tag.';
	@override String get iphoneHint => 'On iPhone, hold the top of your phone against the other one.';
	@override String get foundTitle => 'Frecu found';
	@override String get foundMessage => 'We read the invitation. It already has the code.';
	@override String get notInvite => 'That doesn\'t carry a Frecu invitation.';
	@override String get failed => 'Couldn\'t read it. Bring it close again.';
	@override String get retry => 'Retry';
}

// Path: lobby.join
class _Translations$lobby$join$en extends Translations$lobby$join$es {
	_Translations$lobby$join$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$lobby$join$bluetooth$en bluetooth = _Translations$lobby$join$bluetooth$en._(_root);
	@override String get close => 'Close';
	@override String get internet => 'Over the internet';
	@override String get internetUnreachableHint => 'Check that you have internet and that the frecu is still open.';
	@override String get noInternet => 'You\'re offline';
	@override String get noInternetHint => 'Turn on mobile data or connect to a Wi-Fi with internet.';
	@override String port({required Object port}) => 'Port ${port}';
	@override String get wrongCode => 'Wrong code. Check it and try again.';
	@override String get roomFullHint => 'You can join when someone leaves.';
	@override String get unreachableHint => 'Make sure you\'re on the same Wi-Fi network.';
	@override String get defaultName => 'Participant';
	@override String full({required Object max}) => 'This room is full (${max}/${max}).';
	@override String get unreachable => 'The host isn\'t responding.';
	@override String get failed => 'Couldn\'t join the room.';
	@override String get failedHint => 'Make sure you\'re on the same Wi-Fi network and try again.';
	@override String get versionMismatch => 'This frecu uses another version of Frecu.';
	@override String get versionMismatchHint => 'Update Frecu on both phones.';
	@override late final _Translations$lobby$join$wifi$en wifi = _Translations$lobby$join$wifi$en._(_root);
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
	@override String get offline => 'No Wi-Fi';
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
	@override String get failed => 'Search failed · retrying';
}

// Path: lobby.offline
class _Translations$lobby$offline$en extends Translations$lobby$offline$es {
	_Translations$lobby$offline$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'No Wi-Fi for now';
	@override String get message => 'Nearby rooms show up when you join a Wi-Fi network. Over the internet, scan the host\'s QR.';
	@override String get openSettings => 'Open Wi-Fi settings';
}

// Path: lobby.newRoom
class _Translations$lobby$newRoom$en extends Translations$lobby$newRoom$es {
	_Translations$lobby$newRoom$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get back => 'Back';
	@override String step({required Object current, required Object total}) => 'Step ${current} of ${total}';
	@override late final _Translations$lobby$newRoom$reach$en reach = _Translations$lobby$newRoom$reach$en._(_root);
	@override late final _Translations$lobby$newRoom$guide$en guide = _Translations$lobby$newRoom$guide$en._(_root);
	@override late final _Translations$lobby$newRoom$network$en network = _Translations$lobby$newRoom$network$en._(_root);
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
	@override String get codeHelpInternet => 'The link and the QR already include it: share them only with your group.';
	@override String get open => 'Open room';
	@override String clockLabel({required Object time, required Object note}) => 'Circle of fifths clock: ${time}, ${note}';
}

// Path: room.network
class _Translations$room$network$en extends Translations$room$network$es {
	_Translations$room$network$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lostTitle => 'The room\'s network turned off.';
	@override String get lostMessage => 'Your group got disconnected. Create it again and show the QR again.';
	@override String get recreate => 'Create the network again';
	@override String get recreating => 'Creating the network…';
	@override String get failedTitle => 'The network couldn\'t be created.';
	@override String get failedMessage => 'Turn your hotspot off if it\'s on and try again.';
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
	@override String get weak => 'Weak signal';
	@override String get internet => 'Over the internet';
	@override String get noAudio => 'No audio';
	@override String get free => 'Free';
	@override String get invite => 'Invite';
}

// Path: room.header
class _Translations$room$header$en extends Translations$room$header$es {
	_Translations$room$header$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get youAreHost => 'You\'re the host';
	@override String get carrying => 'You carry the frecu';
	@override String get internetTag => 'Over the internet';
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

// Path: room.handover
class _Translations$room$handover$en extends Translations$room$handover$es {
	_Translations$room$handover$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get leaveTitle => 'What happens to the frecu?';
	@override String get leaveOne => 'You carry the frecu and there\'s one more person.';
	@override String leaveMany({required Object count}) => 'You carry the frecu and there are ${count} more people.';
	@override String get keep => 'Keep it going without me';
	@override String get keepDetail => 'You pass the frecu to someone else and leave. Everyone else keeps talking.';
	@override String get close => 'Close it for everyone';
	@override String get closeDetail => 'The frecu closes and everyone leaves.';
	@override String get next => 'Continue';
	@override String get cancel => 'Cancel';
	@override String get pickTitle => 'Who carries the frecu?';
	@override String get pickMessage => 'That person shows the QR and decides when to close it.';
	@override String get suggested => 'Here the longest · suggested';
	@override String since({required Object time}) => 'Since ${time}';
	@override String pass({required Object name}) => 'Pass to ${name} and leave';
	@override String left({required Object previous, required Object name}) => '${previous} left · ${name} carries the frecu now';
	@override String lost({required Object previous, required Object name}) => '${previous} disconnected · ${name} carries the frecu now';
	@override String taken({required Object name}) => '${name} carries the frecu now';
	@override String get heirTitle => 'You carry the frecu now.';
	@override String heirLeft({required Object name}) => '${name} passed it to you on leaving.';
	@override String heirLost({required Object name}) => '${name} disconnected.';
	@override String get showQr => 'Show the QR';
	@override String get dismiss => 'Dismiss notice';
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
	@override String get lostNetwork => 'The host\'s network was lost and didn\'t come back. You can join another one whenever you like.';
	@override String get duration => 'Duration';
	@override String get people => 'People';
	@override String get note => 'Note';
	@override String get home => 'Back to home';
}

// Path: room.internet
class _Translations$room$internet$en extends Translations$room$internet$es {
	_Translations$room$internet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get cutTitle => 'The Frecu network has no internet.';
	@override String cutMessage({required Object names}) => 'You won\'t hear ${names}, who joined over the internet, and they won\'t hear you.';
	@override String get nor => ' or ';
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
	@override late final _Translations$room$talk$mic$en mic = _Translations$room$talk$mic$en._(_root);
}

// Path: room.notification
class _Translations$room$notification$en extends Translations$room$notification$es {
	_Translations$room$notification$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get channelName => 'Frecu in the background';
	@override String get channelDescription => 'Keeps the Frecu connection alive with the screen off.';
	@override String get title => 'Frecu active';
	@override String get connected => 'Connected';
	@override String get reconnecting => 'Reconnecting…';
	@override String get leave => 'Leave the room';
	@override String get close => 'Close the room';
	@override String get talk => 'Talk';
	@override String get cut => 'Stop talking';
	@override String get mute => 'Mute me';
	@override String get unmute => 'Unmute';
	@override String route({required Object route}) => 'Audio output: ${route}';
	@override String sos({required Object where}) => 'SOS · ${where}';
	@override String towards({required Object distance, required Object direction}) => '${distance} to the ${direction}';
	@override String get sosGo => 'On my way';
	@override String get sosAck => 'Got it';
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

// Path: settings.language
class _Translations$settings$language$en extends Translations$settings$language$es {
	_Translations$settings$language$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Language';
	@override String get message => 'Auto uses your phone\'s language.';
	@override String get auto => 'Auto';
	@override String get autoHelp => 'Follows your phone';
	@override String autoValue({required Object language}) => 'Auto · ${language}';
	@override String get es => 'Español';
	@override String get en => 'English';
}

// Path: settings.permissions
class _Translations$settings$permissions$en extends Translations$settings$permissions$es {
	_Translations$settings$permissions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Permissions';
	@override String get subtitle => 'Microphone, local network, notifications';
	@override String count({required Object granted, required Object total}) => '${granted}/${total}';
}

// Path: settings.windFilter
class _Translations$settings$windFilter$en extends Translations$settings$windFilter$es {
	_Translations$settings$windFilter$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wind filter';
	@override String get subtitle => 'Removes the rumble of wind and engine on a motorcycle or bike.';
}

// Path: settings.earpieceOnRaise
class _Translations$settings$earpieceOnRaise$en extends Translations$settings$earpieceOnRaise$es {
	_Translations$settings$earpieceOnRaise$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Earpiece when raised';
	@override String get subtitle => 'Hold the phone to your ear and the audio moves to the earpiece.';
}

// Path: settings.volumePtt
class _Translations$settings$volumePtt$en extends Translations$settings$volumePtt$es {
	_Translations$settings$volumePtt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Talk with the volume button';
	@override String get subtitle => 'Hold to talk. With the screen off, press to start and again to stop.';
}

// Path: settings.vibration
class _Translations$settings$vibration$en extends Translations$settings$vibration$es {
	_Translations$settings$vibration$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vibration';
	@override String get subtitle => 'When you transmit, when someone starts talking and if the connection drops.';
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

// Path: messages.kinds
class _Translations$messages$kinds$en extends Translations$messages$kinds$es {
	_Translations$messages$kinds$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get behind => 'I fell behind';
	@override String get stop => 'Stop at the next one';
	@override String get fuel => 'I need fuel';
	@override String get ok => 'All good';
	@override String get onMyWay => 'On my way';
	@override String get sos => 'SOS';
}

// Path: messages.sos
class _Translations$messages$sos$en extends Translations$messages$sos$es {
	_Translations$messages$sos$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kicker => 'SOS';
	@override String title({required Object name}) => '${name} needs help';
	@override String get body => 'Tell the group if you\'re heading there. The alarm continues until you answer.';
	@override String get onMyWay => 'On my way';
	@override String get dismiss => 'Got it';
}

// Path: location.share
class _Translations$location$share$en extends Translations$location$share$es {
	_Translations$location$share$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Share my location';
	@override String get on => 'Your group sees how far away you are and in which direction.';
	@override String get off => 'Off. Your group can\'t see where you are.';
}

// Path: location.compass
class _Translations$location$compass$en extends Translations$location$compass$es {
	_Translations$location$compass$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get n => 'N';
	@override String get ne => 'NE';
	@override String get e => 'E';
	@override String get se => 'SE';
	@override String get s => 'S';
	@override String get sw => 'SW';
	@override String get w => 'W';
	@override String get nw => 'NW';
}

// Path: location.compassLong
class _Translations$location$compassLong$en extends Translations$location$compassLong$es {
	_Translations$location$compassLong$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get n => 'north';
	@override String get ne => 'northeast';
	@override String get e => 'east';
	@override String get se => 'southeast';
	@override String get s => 'south';
	@override String get sw => 'southwest';
	@override String get w => 'west';
	@override String get nw => 'northwest';
}

// Path: lobby.join.bluetooth
class _Translations$lobby$join$bluetooth$en extends Translations$lobby$join$bluetooth$es {
	_Translations$lobby$join$bluetooth$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get via => 'Via Bluetooth';
	@override String get hint => 'You\'re not on their Wi-Fi yet: enter the code and we\'ll connect you.';
	@override String get unreachable => 'The host isn\'t answering over Bluetooth.';
	@override String get unreachableHint => 'Move closer to their phone and try again.';
}

// Path: lobby.join.wifi
class _Translations$lobby$join$wifi$en extends Translations$lobby$join$wifi$es {
	_Translations$lobby$join$wifi$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String network({required Object ssid}) => 'Network ${ssid}';
	@override String get message => 'First we connect your phone to the room\'s network.';
	@override String get needed => 'To join this room, your phone has to be on its network.';
	@override String connecting({required Object ssid}) => 'Connecting to the Wi-Fi “${ssid}”…';
	@override String get confirmHint => 'Your phone will ask you to confirm the network.';
	@override String get declinedTitle => 'You didn\'t join the network.';
	@override String get declinedMessage => 'The system prompt was canceled.';
	@override String notFoundTitle({required Object ssid}) => 'We couldn\'t find the network “${ssid}”.';
	@override String get notFoundMessage => 'Get closer to the host and check that the room is still open.';
	@override String get failedTitle => 'We couldn\'t connect you to the network.';
	@override String get failedMessage => 'Try again or connect by hand.';
	@override String get manualMessage => 'Open Settings › Wi-Fi, pick this network and type the password. Then come back to Frecu.';
	@override String get manualOld => 'This phone can\'t join the network on its own. Do it from Settings › Wi-Fi with these details and come back to Frecu.';
	@override String get networkLabel => 'Network';
	@override String get keyLabel => 'Password';
	@override String get noKey => 'Open network, no password';
	@override String get copy => 'Copy';
	@override String get copied => 'Password copied';
	@override String get retry => 'Try again';
	@override String get manual => 'Connect by hand';
	@override String get openWifi => 'Open Wi-Fi';
	@override String get done => 'I\'m connected';
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
	@override String invalid({required Object ip}) => 'Enter an IP like ${ip}.';
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
	@override String get foundInternet => 'Room found · over the internet';
	@override String get noNote => 'Room without a note';
	@override String get join => 'Join';
	@override String get another => 'Scan another QR';
	@override late final _Translations$lobby$join$scan$camera$en camera = _Translations$lobby$join$scan$camera$en._(_root);
}

// Path: lobby.newRoom.reach
class _Translations$lobby$newRoom$reach$en extends Translations$lobby$newRoom$reach$es {
	_Translations$lobby$newRoom$reach$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'How does your group join?';
	@override String get message => 'You choose once. The room doesn\'t mix both ways.';
	@override String get local => 'Local';
	@override String get localDetail => 'Everyone on the same Wi-Fi: the one your phone creates or one you already have, like at home or the office. No internet and no data used.';
	@override String get internet => 'Over the internet';
	@override String get internetDetail => 'From anywhere, with the QR or the link. Uses mobile data.';
	@override String get internetOffline => 'You need internet to create it. Connect to a Wi-Fi with internet or turn on your data.';
	@override String get internetUnavailable => 'This version of Frecu doesn\'t create rooms over the internet.';
	@override String get kContinue => 'Continue';
}

// Path: lobby.newRoom.guide
class _Translations$lobby$newRoom$guide$en extends Translations$lobby$newRoom$guide$es {
	_Translations$lobby$newRoom$guide$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get saveForBluetooth => 'Save it to invite via Bluetooth';
	@override String get savedForBluetooth => 'Hotspot saved · edit';
	@override late final _Translations$lobby$newRoom$guide$hotspotSheet$en hotspotSheet = _Translations$lobby$newRoom$guide$hotspotSheet$en._(_root);
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
	@override String get openSettings => 'Open hotspot settings';
	@override String get openSettingsIphone => 'Open Settings';
}

// Path: lobby.newRoom.network
class _Translations$lobby$newRoom$network$en extends Translations$lobby$newRoom$network$es {
	_Translations$lobby$newRoom$network$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get heading => 'Frecu creates the network';
	@override String get message => 'Your phone will be the group\'s antenna. No internet, and none of your data.';
	@override String get readyHeading => 'Your network is on air';
	@override String get readyMessage => 'Now give your room a name and a code.';
	@override List<HotspotStep> get steps => [
		_Translations$lobby$newRoom$network$steps$0$en._(_root),
		_Translations$lobby$newRoom$network$steps$1$en._(_root),
		_Translations$lobby$newRoom$network$steps$2$en._(_root),
	];
	@override String get create => 'Create the network';
	@override String get creating => 'Creating the network…';
	@override String get creatingHint => 'It takes a few seconds.';
	@override String get cancel => 'Cancel';
	@override String get useHotspot => 'I\'d rather use my hotspot';
	@override String get keepHotspot => 'Keep using my hotspot';
	@override String get kContinue => 'Continue';
	@override String get retry => 'Try again';
	@override String get label => 'Room network';
	@override String get keyInQr => 'The password travels in the QR';
	@override String get onAir => 'On air';
	@override String get hotspotOnTitle => 'Your hotspot is on.';
	@override String get hotspotOnMessage => 'Android doesn\'t allow another network at the same time. Turn it off and try again, or keep it: your group joins your hotspot as usual.';
	@override String get hotspotOnAction => 'Open hotspot settings';
	@override String get nearbyDeniedTitle => 'The nearby devices permission is missing.';
	@override String get nearbyDeniedMessage => 'Android requires it to create the network.';
	@override String get locationDeniedTitle => 'The precise location permission is missing.';
	@override String get locationDeniedMessage => 'On Android 12 or earlier, Android requires it to create the network.';
	@override String get permissionAction => 'Open Frecu settings';
	@override String get locationOffTitle => 'Location is off.';
	@override String get locationOffMessage => 'On Android 12 or earlier, Android requires it to create the network.';
	@override String get locationOffAction => 'Open location settings';
	@override String get failedTitle => 'The network couldn\'t be created.';
	@override String get failedMessage => 'Try again in a few seconds or use your hotspot.';
	@override String get unsupportedTitle => 'This phone can\'t create the network.';
	@override String get unsupportedMessage => 'It needs Android 8 or later. Use your hotspot.';
}

// Path: room.sheets.invite
class _Translations$room$sheets$invite$en extends Translations$room$sheets$invite$es {
	_Translations$room$sheets$invite$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$room$sheets$invite$internet$en internet = _Translations$room$sheets$invite$internet$en._(_root);
	@override String get nfcTitle => 'Also by NFC';
	@override String get nfcMessage => 'Bring another phone close to yours';
	@override String get nfcMessageTag => 'Write it to an NFC tag';
	@override String get nfcWrite => 'Write tag';
	@override late final _Translations$room$sheets$invite$nfcSheet$en nfcSheet = _Translations$room$sheets$invite$nfcSheet$en._(_root);
	@override String get kicker => 'Invite to the frecu';
	@override String get title => 'Scan to join';
	@override String get message => 'From Frecu › Scan. The QR already includes the code.';
	@override String get note => 'Note';
	@override String get code => 'Code';
	@override String get host => 'Host';
	@override String port({required Object port}) => 'Port ${port}';
	@override String footer({required Object list}) => 'It also shows up in “${list}” for anyone on your network.';
	@override String get qr => 'Invite QR code';
	@override String get messageWifi => 'From Frecu › Scan. The QR already carries the network, its password and the code.';
	@override String wifiKey({required Object key}) => 'Password ${key}';
	@override String get wifiOpen => 'Open network, no password';
	@override String get byHand => 'By hand';
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
	@override String get bluetoothDevice => 'Bluetooth · connected';
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
	@override String get networkAlone => 'Your phone is the frecu\'s network. If you leave, the frecu closes.';
	@override String get networkOne => 'Your phone is the frecu\'s network. If you leave, the frecu closes for the other person.';
	@override String networkMany({required Object count}) => 'Your phone is the frecu\'s network. If you leave, the frecu closes for the other ${count} people.';
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
	@override String hostSilent({required Object name}) => 'Everyone can still talk · if they don\'t come back, ${name} takes the frecu';
	@override String get hostSilentYou => 'Everyone can still talk · if they don\'t come back, you take the frecu';
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
	@override String reconnectingIn({required Object seconds}) => 'Reconnecting · ${seconds} s';
	@override String hostSilent({required Object name}) => '${name} isn\'t responding';
	@override String hostSilentFor({required Object name, required Object seconds}) => '${name} isn\'t responding · ${seconds} s';
	@override String joined({required Object name}) => '${name} joined';
	@override String left({required Object name}) => '${name} left';
	@override String route({required Object route}) => 'Audio via ${route}';
	@override String get recovered => 'Connection restored';
	@override String weak({required Object name}) => '${name} · weak signal';
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

// Path: room.talk.mic
class _Translations$room$talk$mic$en extends Translations$room$talk$mic$es {
	_Translations$room$talk$mic$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Your microphone isn\'t available.';
	@override String get message => 'You can hear your group, but nobody can hear you. Check the permission in Settings.';
	@override String get settings => 'Open settings';
	@override String get dismiss => 'Dismiss notice';
}

// Path: lobby.join.scan.camera
class _Translations$lobby$join$scan$camera$en extends Translations$lobby$join$scan$camera$es {
	_Translations$lobby$join$scan$camera$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get deniedTitle => 'Frecu can\'t use the camera.';
	@override String get deniedMessage => 'Allow it in Settings to scan the invite, or connect by IP.';
	@override String get unavailableTitle => 'The camera isn\'t available.';
	@override String get unavailableMessage => 'You can join with the host\'s IP.';
	@override String get openSettings => 'Open settings';
}

// Path: lobby.newRoom.guide.hotspotSheet
class _Translations$lobby$newRoom$guide$hotspotSheet$en extends Translations$lobby$newRoom$guide$hotspotSheet$es {
	_Translations$lobby$newRoom$guide$hotspotSheet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kicker => 'Invite via Bluetooth · optional';
	@override String get title => 'Your hotspot';
	@override String get message => 'Anyone nearby with the frecu\'s code joins your network without looking for it. It\'s stored only on your phone.';
	@override String get ssid => 'Hotspot name';
	@override String get ssidHint => 'As it appears in Settings';
	@override String get key => 'Password';
	@override String get keyHelp => 'Android doesn\'t let apps read it: type it exactly as it is in Settings › Hotspot.';
	@override String get save => 'Save';
	@override String get forget => 'Forget it';
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

// Path: lobby.newRoom.network.steps.0
class _Translations$lobby$newRoom$network$steps$0$en extends Translations$lobby$newRoom$network$steps$0$es with HotspotStep {
	_Translations$lobby$newRoom$network$steps$0$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Tap “Create the network”.';
	@override String get rest => ' The first time, Android asks for the nearby devices permission.';
}

// Path: lobby.newRoom.network.steps.1
class _Translations$lobby$newRoom$network$steps$1$en extends Translations$lobby$newRoom$network$steps$1$es with HotspotStep {
	_Translations$lobby$newRoom$network$steps$1$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Open your room and show the QR.';
	@override String get rest => ' It already carries the network and its password: your group joins with a single scan.';
}

// Path: lobby.newRoom.network.steps.2
class _Translations$lobby$newRoom$network$steps$2$en extends Translations$lobby$newRoom$network$steps$2$es with HotspotStep {
	_Translations$lobby$newRoom$network$steps$2$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get lead => 'Closing the room turns the network off.';
	@override String get rest => ' The next one gets a new name and a new password.';
}

// Path: room.sheets.invite.internet
class _Translations$room$sheets$invite$internet$en extends Translations$room$sheets$invite$internet$es {
	_Translations$room$sheets$invite$internet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kicker => 'Invite · over the internet';
	@override String get title => 'Scan or share';
	@override String get message => 'They work from anywhere and already include the code.';
	@override String get connection => 'Connection';
	@override String get internet => 'Internet';
	@override String andWifi({required Object name}) => 'and Wi-Fi “${name}”';
	@override String get share => 'Share link';
	@override String shareText({required Object name, required Object link}) => 'Join my frecu “${name}” on Frecu: ${link}';
}

// Path: room.sheets.invite.nfcSheet
class _Translations$room$sheets$invite$nfcSheet$en extends Translations$room$sheets$invite$nfcSheet$es {
	_Translations$room$sheets$invite$nfcSheet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get kicker => 'Write invitation';
	@override String get title => 'Bring a tag close';
	@override String get message => 'Touch an NFC tag to the back of your phone. It works while this frecu stays open.';
	@override String get done => 'Invitation written';
	@override String get readOnly => 'That tag can\'t be written.';
	@override String get tooSmall => 'The invitation doesn\'t fit on that tag.';
	@override String get failed => 'Couldn\'t write it. Bring it close again.';
	@override String get retry => 'Retry';
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
			'lobby.nfc.byIp' => 'By IP',
			'lobby.nfc.button' => 'By NFC',
			'lobby.nfc.kicker' => 'Join by NFC',
			'lobby.nfc.title' => 'Bring your phone close',
			'lobby.nfc.message' => 'Touch the back of your phone to the host\'s, or to a frecu tag.',
			'lobby.nfc.iphoneHint' => 'On iPhone, hold the top of your phone against the other one.',
			'lobby.nfc.foundTitle' => 'Frecu found',
			'lobby.nfc.foundMessage' => 'We read the invitation. It already has the code.',
			'lobby.nfc.notInvite' => 'That doesn\'t carry a Frecu invitation.',
			'lobby.nfc.failed' => 'Couldn\'t read it. Bring it close again.',
			'lobby.nfc.retry' => 'Retry',
			'lobby.title' => 'frecu',
			'lobby.join.bluetooth.via' => 'Via Bluetooth',
			'lobby.join.bluetooth.hint' => 'You\'re not on their Wi-Fi yet: enter the code and we\'ll connect you.',
			'lobby.join.bluetooth.unreachable' => 'The host isn\'t answering over Bluetooth.',
			'lobby.join.bluetooth.unreachableHint' => 'Move closer to their phone and try again.',
			'lobby.join.close' => 'Close',
			'lobby.join.internet' => 'Over the internet',
			'lobby.join.internetUnreachableHint' => 'Check that you have internet and that the frecu is still open.',
			'lobby.join.noInternet' => 'You\'re offline',
			'lobby.join.noInternetHint' => 'Turn on mobile data or connect to a Wi-Fi with internet.',
			'lobby.join.port' => ({required Object port}) => 'Port ${port}',
			'lobby.join.wrongCode' => 'Wrong code. Check it and try again.',
			'lobby.join.roomFullHint' => 'You can join when someone leaves.',
			'lobby.join.unreachableHint' => 'Make sure you\'re on the same Wi-Fi network.',
			'lobby.join.defaultName' => 'Participant',
			'lobby.join.full' => ({required Object max}) => 'This room is full (${max}/${max}).',
			'lobby.join.unreachable' => 'The host isn\'t responding.',
			'lobby.join.failed' => 'Couldn\'t join the room.',
			'lobby.join.failedHint' => 'Make sure you\'re on the same Wi-Fi network and try again.',
			'lobby.join.versionMismatch' => 'This frecu uses another version of Frecu.',
			'lobby.join.versionMismatchHint' => 'Update Frecu on both phones.',
			'lobby.join.wifi.network' => ({required Object ssid}) => 'Network ${ssid}',
			'lobby.join.wifi.message' => 'First we connect your phone to the room\'s network.',
			'lobby.join.wifi.needed' => 'To join this room, your phone has to be on its network.',
			'lobby.join.wifi.connecting' => ({required Object ssid}) => 'Connecting to the Wi-Fi “${ssid}”…',
			'lobby.join.wifi.confirmHint' => 'Your phone will ask you to confirm the network.',
			'lobby.join.wifi.declinedTitle' => 'You didn\'t join the network.',
			'lobby.join.wifi.declinedMessage' => 'The system prompt was canceled.',
			'lobby.join.wifi.notFoundTitle' => ({required Object ssid}) => 'We couldn\'t find the network “${ssid}”.',
			'lobby.join.wifi.notFoundMessage' => 'Get closer to the host and check that the room is still open.',
			'lobby.join.wifi.failedTitle' => 'We couldn\'t connect you to the network.',
			'lobby.join.wifi.failedMessage' => 'Try again or connect by hand.',
			'lobby.join.wifi.manualMessage' => 'Open Settings › Wi-Fi, pick this network and type the password. Then come back to Frecu.',
			'lobby.join.wifi.manualOld' => 'This phone can\'t join the network on its own. Do it from Settings › Wi-Fi with these details and come back to Frecu.',
			'lobby.join.wifi.networkLabel' => 'Network',
			'lobby.join.wifi.keyLabel' => 'Password',
			'lobby.join.wifi.noKey' => 'Open network, no password',
			'lobby.join.wifi.copy' => 'Copy',
			'lobby.join.wifi.copied' => 'Password copied',
			'lobby.join.wifi.retry' => 'Try again',
			'lobby.join.wifi.manual' => 'Connect by hand',
			'lobby.join.wifi.openWifi' => 'Open Wi-Fi',
			'lobby.join.wifi.done' => 'I\'m connected',
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
			'lobby.join.ip.invalid' => ({required Object ip}) => 'Enter an IP like ${ip}.',
			'lobby.join.ip.connect' => 'Connect',
			'lobby.join.scan.title' => 'Scan invite',
			'lobby.join.scan.subtitle' => 'Room QR',
			'lobby.join.scan.back' => 'Back',
			'lobby.join.scan.torch' => 'Flashlight',
			'lobby.join.scan.hint' => 'Point at the QR the host shows on their phone.',
			'lobby.join.scan.invalid' => 'This QR isn\'t a Frecu invite.',
			'lobby.join.scan.found' => 'Room found',
			'lobby.join.scan.foundInternet' => 'Room found · over the internet',
			'lobby.join.scan.noNote' => 'Room without a note',
			'lobby.join.scan.join' => 'Join',
			'lobby.join.scan.another' => 'Scan another QR',
			'lobby.join.scan.camera.deniedTitle' => 'Frecu can\'t use the camera.',
			'lobby.join.scan.camera.deniedMessage' => 'Allow it in Settings to scan the invite, or connect by IP.',
			'lobby.join.scan.camera.unavailableTitle' => 'The camera isn\'t available.',
			'lobby.join.scan.camera.unavailableMessage' => 'You can join with the host\'s IP.',
			'lobby.join.scan.camera.openSettings' => 'Open settings',
			'lobby.settings' => 'Settings',
			'lobby.heading' => 'Pick your room',
			'lobby.createRoom' => 'Create room',
			'lobby.scanQr' => 'Scan',
			'lobby.joinRoom' => 'Connect by IP',
			'lobby.nearbyRooms' => 'Nearby rooms',
			'lobby.accessCode' => 'Access code',
			'lobby.unnamedRoom' => 'Unnamed room',
			'lobby.network.checking' => 'Checking network',
			'lobby.network.connected' => ({required Object ip}) => 'Network · ${ip}',
			'lobby.network.offline' => 'No Wi-Fi',
			'lobby.tuner.scanning' => 'Scanning · _frecu._tcp',
			'lobby.tuner.paused' => 'Search paused',
			'lobby.tuner.signals' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} signal', other: '${n} signals', ), 
			'lobby.empty.title' => 'No signals yet',
			'lobby.empty.message' => 'Join the host\'s Wi-Fi or ask them to show you their QR.',
			'lobby.empty.searching' => 'Still searching',
			'lobby.empty.failed' => 'Search failed · retrying',
			'lobby.offline.title' => 'No Wi-Fi for now',
			'lobby.offline.message' => 'Nearby rooms show up when you join a Wi-Fi network. Over the internet, scan the host\'s QR.',
			'lobby.offline.openSettings' => 'Open Wi-Fi settings',
			'lobby.newRoom.back' => 'Back',
			'lobby.newRoom.step' => ({required Object current, required Object total}) => 'Step ${current} of ${total}',
			'lobby.newRoom.reach.title' => 'How does your group join?',
			'lobby.newRoom.reach.message' => 'You choose once. The room doesn\'t mix both ways.',
			'lobby.newRoom.reach.local' => 'Local',
			'lobby.newRoom.reach.localDetail' => 'Everyone on the same Wi-Fi: the one your phone creates or one you already have, like at home or the office. No internet and no data used.',
			'lobby.newRoom.reach.internet' => 'Over the internet',
			'lobby.newRoom.reach.internetDetail' => 'From anywhere, with the QR or the link. Uses mobile data.',
			'lobby.newRoom.reach.internetOffline' => 'You need internet to create it. Connect to a Wi-Fi with internet or turn on your data.',
			'lobby.newRoom.reach.internetUnavailable' => 'This version of Frecu doesn\'t create rooms over the internet.',
			'lobby.newRoom.reach.kContinue' => 'Continue',
			'lobby.newRoom.guide.saveForBluetooth' => 'Save it to invite via Bluetooth',
			'lobby.newRoom.guide.savedForBluetooth' => 'Hotspot saved · edit',
			'lobby.newRoom.guide.hotspotSheet.kicker' => 'Invite via Bluetooth · optional',
			'lobby.newRoom.guide.hotspotSheet.title' => 'Your hotspot',
			'lobby.newRoom.guide.hotspotSheet.message' => 'Anyone nearby with the frecu\'s code joins your network without looking for it. It\'s stored only on your phone.',
			'lobby.newRoom.guide.hotspotSheet.ssid' => 'Hotspot name',
			'lobby.newRoom.guide.hotspotSheet.ssidHint' => 'As it appears in Settings',
			'lobby.newRoom.guide.hotspotSheet.key' => 'Password',
			'lobby.newRoom.guide.hotspotSheet.keyHelp' => 'Android doesn\'t let apps read it: type it exactly as it is in Settings › Hotspot.',
			'lobby.newRoom.guide.hotspotSheet.save' => 'Save',
			'lobby.newRoom.guide.hotspotSheet.forget' => 'Forget it',
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
			'lobby.newRoom.guide.openSettings' => 'Open hotspot settings',
			'lobby.newRoom.guide.openSettingsIphone' => 'Open Settings',
			'lobby.newRoom.network.heading' => 'Frecu creates the network',
			'lobby.newRoom.network.message' => 'Your phone will be the group\'s antenna. No internet, and none of your data.',
			'lobby.newRoom.network.readyHeading' => 'Your network is on air',
			'lobby.newRoom.network.readyMessage' => 'Now give your room a name and a code.',
			'lobby.newRoom.network.steps.0.lead' => 'Tap “Create the network”.',
			'lobby.newRoom.network.steps.0.rest' => ' The first time, Android asks for the nearby devices permission.',
			'lobby.newRoom.network.steps.1.lead' => 'Open your room and show the QR.',
			'lobby.newRoom.network.steps.1.rest' => ' It already carries the network and its password: your group joins with a single scan.',
			'lobby.newRoom.network.steps.2.lead' => 'Closing the room turns the network off.',
			'lobby.newRoom.network.steps.2.rest' => ' The next one gets a new name and a new password.',
			'lobby.newRoom.network.create' => 'Create the network',
			'lobby.newRoom.network.creating' => 'Creating the network…',
			'lobby.newRoom.network.creatingHint' => 'It takes a few seconds.',
			'lobby.newRoom.network.cancel' => 'Cancel',
			'lobby.newRoom.network.useHotspot' => 'I\'d rather use my hotspot',
			'lobby.newRoom.network.keepHotspot' => 'Keep using my hotspot',
			'lobby.newRoom.network.kContinue' => 'Continue',
			'lobby.newRoom.network.retry' => 'Try again',
			'lobby.newRoom.network.label' => 'Room network',
			'lobby.newRoom.network.keyInQr' => 'The password travels in the QR',
			'lobby.newRoom.network.onAir' => 'On air',
			'lobby.newRoom.network.hotspotOnTitle' => 'Your hotspot is on.',
			'lobby.newRoom.network.hotspotOnMessage' => 'Android doesn\'t allow another network at the same time. Turn it off and try again, or keep it: your group joins your hotspot as usual.',
			'lobby.newRoom.network.hotspotOnAction' => 'Open hotspot settings',
			'lobby.newRoom.network.nearbyDeniedTitle' => 'The nearby devices permission is missing.',
			'lobby.newRoom.network.nearbyDeniedMessage' => 'Android requires it to create the network.',
			'lobby.newRoom.network.locationDeniedTitle' => 'The precise location permission is missing.',
			'lobby.newRoom.network.locationDeniedMessage' => 'On Android 12 or earlier, Android requires it to create the network.',
			'lobby.newRoom.network.permissionAction' => 'Open Frecu settings',
			'lobby.newRoom.network.locationOffTitle' => 'Location is off.',
			'lobby.newRoom.network.locationOffMessage' => 'On Android 12 or earlier, Android requires it to create the network.',
			'lobby.newRoom.network.locationOffAction' => 'Open location settings',
			'lobby.newRoom.network.failedTitle' => 'The network couldn\'t be created.',
			'lobby.newRoom.network.failedMessage' => 'Try again in a few seconds or use your hotspot.',
			'lobby.newRoom.network.unsupportedTitle' => 'This phone can\'t create the network.',
			'lobby.newRoom.network.unsupportedMessage' => 'It needs Android 8 or later. Use your hotspot.',
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
			'lobby.newRoom.codeHelpInternet' => 'The link and the QR already include it: share them only with your group.',
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
			'room.network.lostTitle' => 'The room\'s network turned off.',
			'room.network.lostMessage' => 'Your group got disconnected. Create it again and show the QR again.',
			'room.network.recreate' => 'Create the network again',
			'room.network.recreating' => 'Creating the network…',
			'room.network.failedTitle' => 'The network couldn\'t be created.',
			'room.network.failedMessage' => 'Turn your hotspot off if it\'s on and try again.',
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
			'room.mesh.weak' => 'Weak signal',
			'room.mesh.internet' => 'Over the internet',
			'room.mesh.noAudio' => 'No audio',
			'room.mesh.free' => 'Free',
			'room.mesh.invite' => 'Invite',
			'room.header.youAreHost' => 'You\'re the host',
			'room.header.carrying' => 'You carry the frecu',
			'room.header.internetTag' => 'Over the internet',
			'room.header.hostedBy' => ({required Object name}) => 'Host · ${name}',
			'room.header.hz' => ({required Object value}) => '${value} Hz',
			'room.header.note' => ({required Object note, required Object hz}) => 'Note ${note}, ${hz} Hz',
			'room.header.invite' => 'Invite',
			'room.sheets.close' => 'Close',
			'room.sheets.invite.internet.kicker' => 'Invite · over the internet',
			'room.sheets.invite.internet.title' => 'Scan or share',
			'room.sheets.invite.internet.message' => 'They work from anywhere and already include the code.',
			'room.sheets.invite.internet.connection' => 'Connection',
			'room.sheets.invite.internet.internet' => 'Internet',
			'room.sheets.invite.internet.andWifi' => ({required Object name}) => 'and Wi-Fi “${name}”',
			'room.sheets.invite.internet.share' => 'Share link',
			'room.sheets.invite.internet.shareText' => ({required Object name, required Object link}) => 'Join my frecu “${name}” on Frecu: ${link}',
			'room.sheets.invite.nfcTitle' => 'Also by NFC',
			'room.sheets.invite.nfcMessage' => 'Bring another phone close to yours',
			'room.sheets.invite.nfcMessageTag' => 'Write it to an NFC tag',
			'room.sheets.invite.nfcWrite' => 'Write tag',
			'room.sheets.invite.nfcSheet.kicker' => 'Write invitation',
			'room.sheets.invite.nfcSheet.title' => 'Bring a tag close',
			'room.sheets.invite.nfcSheet.message' => 'Touch an NFC tag to the back of your phone. It works while this frecu stays open.',
			'room.sheets.invite.nfcSheet.done' => 'Invitation written',
			'room.sheets.invite.nfcSheet.readOnly' => 'That tag can\'t be written.',
			'room.sheets.invite.nfcSheet.tooSmall' => 'The invitation doesn\'t fit on that tag.',
			'room.sheets.invite.nfcSheet.failed' => 'Couldn\'t write it. Bring it close again.',
			'room.sheets.invite.nfcSheet.retry' => 'Retry',
			'room.sheets.invite.kicker' => 'Invite to the frecu',
			'room.sheets.invite.title' => 'Scan to join',
			'room.sheets.invite.message' => 'From Frecu › Scan. The QR already includes the code.',
			'room.sheets.invite.note' => 'Note',
			'room.sheets.invite.code' => 'Code',
			'room.sheets.invite.host' => 'Host',
			'room.sheets.invite.port' => ({required Object port}) => 'Port ${port}',
			'room.sheets.invite.footer' => ({required Object list}) => 'It also shows up in “${list}” for anyone on your network.',
			'room.sheets.invite.qr' => 'Invite QR code',
			'room.sheets.invite.messageWifi' => 'From Frecu › Scan. The QR already carries the network, its password and the code.',
			'room.sheets.invite.wifiKey' => ({required Object key}) => 'Password ${key}',
			'room.sheets.invite.wifiOpen' => 'Open network, no password',
			'room.sheets.invite.byHand' => 'By hand',
			'room.sheets.route.kicker' => 'Audio output',
			'room.sheets.route.title' => 'Where do you listen?',
			'room.sheets.route.message' => 'When you plug in headphones, the audio switches by itself.',
			'room.sheets.route.speakerSub' => 'Hands-free',
			'room.sheets.route.earpieceSub' => 'Phone to your ear',
			'room.sheets.route.bluetoothOn' => 'Connected',
			'room.sheets.route.bluetoothOff' => 'No device',
			'room.sheets.route.bluetoothDevice' => 'Bluetooth · connected',
			'room.sheets.route.label' => ({required Object route}) => 'Audio output: ${route}',
			'room.sheets.leave.peerTitle' => 'Leave the frecu?',
			'room.sheets.leave.peerMessage' => 'You can join again with the access code.',
			'room.sheets.leave.peerConfirm' => 'Leave the frecu',
			'room.sheets.leave.hostTitle' => 'Close the frecu for everyone',
			'room.sheets.leave.hostAlone' => 'You\'re the host. If you leave, the frecu closes.',
			'room.sheets.leave.hostOne' => 'You\'re the host. If you leave, the frecu closes for the other person.',
			'room.sheets.leave.hostMany' => ({required Object count}) => 'You\'re the host. If you leave, the frecu closes for the other ${count} people.',
			'room.sheets.leave.networkAlone' => 'Your phone is the frecu\'s network. If you leave, the frecu closes.',
			'room.sheets.leave.networkOne' => 'Your phone is the frecu\'s network. If you leave, the frecu closes for the other person.',
			'room.sheets.leave.networkMany' => ({required Object count}) => 'Your phone is the frecu\'s network. If you leave, the frecu closes for the other ${count} people.',
			'room.sheets.leave.hostConfirm' => 'Close frecu',
			'room.sheets.leave.cancel' => 'Cancel',
			'room.handover.leaveTitle' => 'What happens to the frecu?',
			'room.handover.leaveOne' => 'You carry the frecu and there\'s one more person.',
			'room.handover.leaveMany' => ({required Object count}) => 'You carry the frecu and there are ${count} more people.',
			'room.handover.keep' => 'Keep it going without me',
			'room.handover.keepDetail' => 'You pass the frecu to someone else and leave. Everyone else keeps talking.',
			'room.handover.close' => 'Close it for everyone',
			'room.handover.closeDetail' => 'The frecu closes and everyone leaves.',
			'room.handover.next' => 'Continue',
			'room.handover.cancel' => 'Cancel',
			'room.handover.pickTitle' => 'Who carries the frecu?',
			'room.handover.pickMessage' => 'That person shows the QR and decides when to close it.',
			'room.handover.suggested' => 'Here the longest · suggested',
			'room.handover.since' => ({required Object time}) => 'Since ${time}',
			'room.handover.pass' => ({required Object name}) => 'Pass to ${name} and leave',
			'room.handover.left' => ({required Object previous, required Object name}) => '${previous} left · ${name} carries the frecu now',
			'room.handover.lost' => ({required Object previous, required Object name}) => '${previous} disconnected · ${name} carries the frecu now',
			'room.handover.taken' => ({required Object name}) => '${name} carries the frecu now',
			'room.handover.heirTitle' => 'You carry the frecu now.',
			'room.handover.heirLeft' => ({required Object name}) => '${name} passed it to you on leaving.',
			'room.handover.heirLost' => ({required Object name}) => '${name} disconnected.',
			'room.handover.showQr' => 'Show the QR',
			'room.handover.dismiss' => 'Dismiss notice',
			'room.closure.offAir' => 'Off the air',
			'room.closure.noteOffAir' => ({required Object note}) => '${note} · off the air',
			'room.closure.title' => 'End of transmission',
			'room.closure.host' => 'You closed the frecu. Everyone was disconnected.',
			'room.closure.peer' => 'The host closed the frecu. You can join another one whenever you like.',
			'room.closure.lost' => 'The host\'s signal was lost. You can join another one whenever you like.',
			'room.closure.lostNetwork' => 'The host\'s network was lost and didn\'t come back. You can join another one whenever you like.',
			'room.closure.duration' => 'Duration',
			'room.closure.people' => 'People',
			'room.closure.note' => 'Note',
			'room.closure.home' => 'Back to home',
			'room.internet.cutTitle' => 'The Frecu network has no internet.',
			'room.internet.cutMessage' => ({required Object names}) => 'You won\'t hear ${names}, who joined over the internet, and they won\'t hear you.',
			'room.internet.nor' => ' or ',
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
			'room.talk.hint.hostSilent' => ({required Object name}) => 'Everyone can still talk · if they don\'t come back, ${name} takes the frecu',
			'room.talk.hint.hostSilentYou' => 'Everyone can still talk · if they don\'t come back, you take the frecu',
			'room.talk.island.online' => ({required Object count, required Object max}) => 'Online · ${count}/${max}',
			'room.talk.island.openMic' => ({required Object count, required Object max}) => 'Open mic · ${count}/${max}',
			'room.talk.island.muted' => ({required Object count, required Object max}) => 'Muted · ${count}/${max}',
			'room.talk.island.onAir' => ({required Object time}) => 'On air · ${time}',
			'room.talk.island.receiving' => ({required Object name}) => '${name} · talking',
			'room.talk.island.waiting' => 'On air · waiting for your group',
			'room.talk.island.connecting' => 'Connecting…',
			'room.talk.island.reconnecting' => 'Reconnecting…',
			'room.talk.island.reconnectingIn' => ({required Object seconds}) => 'Reconnecting · ${seconds} s',
			'room.talk.island.hostSilent' => ({required Object name}) => '${name} isn\'t responding',
			'room.talk.island.hostSilentFor' => ({required Object name, required Object seconds}) => '${name} isn\'t responding · ${seconds} s',
			'room.talk.island.joined' => ({required Object name}) => '${name} joined',
			'room.talk.island.left' => ({required Object name}) => '${name} left',
			'room.talk.island.route' => ({required Object route}) => 'Audio via ${route}',
			'room.talk.island.recovered' => 'Connection restored',
			'room.talk.island.weak' => ({required Object name}) => '${name} · weak signal',
			'room.talk.echo.title' => 'Open mic on speaker.',
			'room.talk.echo.message' => 'Use headphones to avoid echo.',
			'room.talk.echo.dismiss' => 'Dismiss notice',
			'room.talk.mic.title' => 'Your microphone isn\'t available.',
			'room.talk.mic.message' => 'You can hear your group, but nobody can hear you. Check the permission in Settings.',
			'room.talk.mic.settings' => 'Open settings',
			'room.talk.mic.dismiss' => 'Dismiss notice',
			'room.notification.channelName' => 'Frecu in the background',
			'room.notification.channelDescription' => 'Keeps the Frecu connection alive with the screen off.',
			'room.notification.title' => 'Frecu active',
			'room.notification.connected' => 'Connected',
			'room.notification.reconnecting' => 'Reconnecting…',
			'room.notification.leave' => 'Leave the room',
			'room.notification.close' => 'Close the room',
			'room.notification.talk' => 'Talk',
			'room.notification.cut' => 'Stop talking',
			'room.notification.mute' => 'Mute me',
			'room.notification.unmute' => 'Unmute',
			'room.notification.route' => ({required Object route}) => 'Audio output: ${route}',
			'room.notification.sos' => ({required Object where}) => 'SOS · ${where}',
			'room.notification.towards' => ({required Object distance, required Object direction}) => '${distance} to the ${direction}',
			'room.notification.sosGo' => 'On my way',
			'room.notification.sosAck' => 'Got it',
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
			'settings.general' => 'General',
			'settings.language.title' => 'Language',
			'settings.language.message' => 'Auto uses your phone\'s language.',
			'settings.language.auto' => 'Auto',
			'settings.language.autoHelp' => 'Follows your phone',
			'settings.language.autoValue' => ({required Object language}) => 'Auto · ${language}',
			'settings.language.es' => 'Español',
			'settings.language.en' => 'English',
			'settings.permissions.title' => 'Permissions',
			'settings.permissions.subtitle' => 'Microphone, local network, notifications',
			'settings.permissions.count' => ({required Object granted, required Object total}) => '${granted}/${total}',
			'settings.hotspotGuide' => 'Hotspot guide',
			'settings.windFilter.title' => 'Wind filter',
			'settings.windFilter.subtitle' => 'Removes the rumble of wind and engine on a motorcycle or bike.',
			'settings.earpieceOnRaise.title' => 'Earpiece when raised',
			'settings.earpieceOnRaise.subtitle' => 'Hold the phone to your ear and the audio moves to the earpiece.',
			'settings.volumePtt.title' => 'Talk with the volume button',
			'settings.volumePtt.subtitle' => 'Hold to talk. With the screen off, press to start and again to stop.',
			'settings.vibration.title' => 'Vibration',
			'settings.vibration.subtitle' => 'When you transmit, when someone starts talking and if the connection drops.',
			'settings.licenses' => 'Licenses',
			'settings.appearance' => 'Appearance',
			'settings.theme' => 'Theme',
			'settings.themeHelp' => 'Auto follows your phone',
			'settings.themeMode.auto' => 'Auto',
			'settings.themeMode.light' => 'Light',
			'settings.themeMode.dark' => 'Dark',
			'settings.saveError' => 'Couldn\'t save',
			'settings.footer' => ({required Object app}) => '${app} · 100% local · no internet',
			'settings.appVersion' => ({required Object version}) => 'Frecu ${version}',
			'nfcIos.read' => 'Hold the host\'s phone or the frecu tag near.',
			'nfcIos.write' => 'Hold the NFC tag near.',
			'nfcIos.done' => 'Done',
			'nfcIos.notInvite' => 'That\'s not a Frecu invitation.',
			'nfcIos.failed' => 'Didn\'t work. Try again.',
			'errors.network' => 'Local network error',
			'errors.permissionDenied' => 'Required permission denied',
			'errors.roomFull' => 'Room is full (max 6 participants)',
			'errors.invalidAccessCode' => 'Invalid access code',
			'errors.hostUnreachable' => 'Host is unreachable',
			'errors.versionMismatch' => 'This frecu uses another version of Frecu',
			'errors.audio' => 'Audio subsystem error',
			'errors.hotspot' => 'The room\'s network couldn\'t be created',
			'errors.wifiJoin' => 'Couldn\'t connect to the room\'s network',
			'errors.nfc' => 'Could not use NFC',
			'errors.unexpected' => 'Unexpected error',
			'splash.title' => 'frecu',
			'splash.tagline' => 'Group voice. No internet.',
			'splash.version' => ({required Object version}) => 'v${version}',
			'splash.localNetwork' => 'Local network',
			'splash.mesh' => 'P2P mesh',
			'splash.skip' => 'Tap to enter',
			'messages.button' => 'Messages',
			'messages.kicker' => 'For the whole frecu',
			'messages.title' => 'Quick messages',
			'messages.message' => 'They arrive instantly and vibrate, even with the screen off.',
			'messages.kinds.behind' => 'I fell behind',
			'messages.kinds.stop' => 'Stop at the next one',
			'messages.kinds.fuel' => 'I need fuel',
			_ => null,
		} ?? switch (path) {
			'messages.kinds.ok' => 'All good',
			'messages.kinds.onMyWay' => 'On my way',
			'messages.kinds.sos' => 'SOS',
			'messages.sosHold' => 'Hold to send SOS',
			'messages.sosHoldHelp' => 'Alarm for everyone until someone answers',
			'messages.sent' => ({required Object text}) => 'Sent · ${text}',
			'messages.sosSent' => 'SOS sent to your group',
			'messages.received' => ({required Object name, required Object text}) => '${name} · ${text}',
			'messages.sendError' => 'Couldn\'t send: no connection to the host',
			'messages.sos.kicker' => 'SOS',
			'messages.sos.title' => ({required Object name}) => '${name} needs help',
			'messages.sos.body' => 'Tell the group if you\'re heading there. The alarm continues until you answer.',
			'messages.sos.onMyWay' => 'On my way',
			'messages.sos.dismiss' => 'Got it',
			'location.share.title' => 'Share my location',
			'location.share.on' => 'Your group sees how far away you are and in which direction.',
			'location.share.off' => 'Off. Your group can\'t see where you are.',
			'location.sharingTag' => 'Sharing your location',
			'location.denied' => 'No location permission',
			'location.deniedForever' => 'No location permission: turn it on in your phone\'s settings',
			'location.failed' => 'Couldn\'t use your location',
			'location.behind' => ({required Object name}) => '${name} fell behind',
			'location.behindCaption' => ({required Object distance}) => 'Behind · ${distance}',
			'location.towards' => ({required Object distance, required Object direction}) => '${distance} ${direction}',
			'location.sosDetail' => ({required Object distance, required Object direction}) => 'They\'re ${distance} to the ${direction}. Tell the group if you\'re heading there.',
			'location.meters' => ({required Object value}) => '${value} m',
			'location.kilometers' => ({required Object value}) => '${value} km',
			'location.compass.n' => 'N',
			'location.compass.ne' => 'NE',
			'location.compass.e' => 'E',
			'location.compass.se' => 'SE',
			'location.compass.s' => 'S',
			'location.compass.sw' => 'SW',
			'location.compass.w' => 'W',
			'location.compass.nw' => 'NW',
			'location.compassLong.n' => 'north',
			'location.compassLong.ne' => 'northeast',
			'location.compassLong.e' => 'east',
			'location.compassLong.se' => 'southeast',
			'location.compassLong.s' => 'south',
			'location.compassLong.sw' => 'southwest',
			'location.compassLong.w' => 'west',
			'location.compassLong.nw' => 'northwest',
			_ => null,
		};
	}
}
