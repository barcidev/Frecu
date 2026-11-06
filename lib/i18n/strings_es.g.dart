///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEs = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$es app = Translations$app$es.internal(_root);
	late final Translations$lobby$es lobby = Translations$lobby$es.internal(_root);
	late final Translations$room$es room = Translations$room$es.internal(_root);
	late final Translations$permissions$es permissions = Translations$permissions$es.internal(_root);
	late final Translations$settings$es settings = Translations$settings$es.internal(_root);
	late final Translations$errors$es errors = Translations$errors$es.internal(_root);
}

// Path: app
class Translations$app$es {
	Translations$app$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Frecu'
	String get title => 'Frecu';
}

// Path: lobby
class Translations$lobby$es {
	Translations$lobby$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Frecu'
	String get title => 'Frecu';

	/// es: 'Crear frecu'
	String get createRoom => 'Crear frecu';

	/// es: 'Escanear QR'
	String get scanQr => 'Escanear QR';

	/// es: 'Unirse a frecu'
	String get joinRoom => 'Unirse a frecu';

	/// es: 'Frecus cercanas'
	String get nearbyRooms => 'Frecus cercanas';

	/// es: 'No se encontraron frecus en la red'
	String get noRoomsNearby => 'No se encontraron frecus en la red';

	/// es: 'Código de acceso'
	String get accessCode => 'Código de acceso';

	/// es: 'Nombre de la frecu'
	String get roomName => 'Nombre de la frecu';

	/// es: 'Tu nombre visible'
	String get yourName => 'Tu nombre visible';
}

// Path: room
class Translations$room$es {
	Translations$room$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Frecu activa'
	String get title => 'Frecu activa';

	/// es: 'Salir de la frecu'
	String get leave => 'Salir de la frecu';

	/// es: 'Participantes'
	String get participants => 'Participantes';

	/// es: 'Mantén presionado para hablar'
	String get pushToTalk => 'Mantén presionado para hablar';

	/// es: 'Micrófono abierto'
	String get openMic => 'Micrófono abierto';

	/// es: 'Altavoz'
	String get speaker => 'Altavoz';

	/// es: 'Auricular'
	String get earpiece => 'Auricular';

	/// es: 'Bluetooth'
	String get bluetooth => 'Bluetooth';

	/// es: 'Hablando'
	String get speaking => 'Hablando';

	/// es: 'Silenciado'
	String get muted => 'Silenciado';

	/// es: 'Anfitrión'
	String get host => 'Anfitrión';

	/// es: 'La frecu fue cerrada por el anfitrión'
	String get roomClosed => 'La frecu fue cerrada por el anfitrión';
}

// Path: permissions
class Translations$permissions$es {
	Translations$permissions$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Permisos requeridos'
	String get title => 'Permisos requeridos';

	/// es: 'Frecu necesita permisos para comunicarse sin internet.'
	String get description => 'Frecu necesita permisos para comunicarse sin internet.';

	/// es: 'Micrófono'
	String get microphone => 'Micrófono';

	/// es: 'Transmite tu voz a los participantes de la frecu.'
	String get microphoneDesc => 'Transmite tu voz a los participantes de la frecu.';

	/// es: 'Red local y dispositivos cercanos'
	String get nearbyDevices => 'Red local y dispositivos cercanos';

	/// es: 'Descubre y conecta con otros teléfonos en la misma red.'
	String get nearbyDevicesDesc => 'Descubre y conecta con otros teléfonos en la misma red.';

	/// es: 'Notificaciones'
	String get notifications => 'Notificaciones';

	/// es: 'Mantiene la frecu activa en segundo plano con pantalla apagada.'
	String get notificationsDesc => 'Mantiene la frecu activa en segundo plano con pantalla apagada.';

	/// es: 'Conceder permisos'
	String get grant => 'Conceder permisos';

	/// es: 'Permisos concedidos'
	String get granted => 'Permisos concedidos';
}

// Path: settings
class Translations$settings$es {
	Translations$settings$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Ajustes'
	String get title => 'Ajustes';

	/// es: 'Nombre visible'
	String get displayName => 'Nombre visible';

	/// es: 'Modo de habla por defecto'
	String get defaultTalkMode => 'Modo de habla por defecto';

	/// es: 'Idioma'
	String get language => 'Idioma';
}

// Path: errors
class Translations$errors$es {
	Translations$errors$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Error de red local'
	String get network => 'Error de red local';

	/// es: 'Permiso denegado'
	String get permissionDenied => 'Permiso denegado';

	/// es: 'La frecu está llena (máximo 6 participantes)'
	String get roomFull => 'La frecu está llena (máximo 6 participantes)';

	/// es: 'Código de acceso inválido'
	String get invalidAccessCode => 'Código de acceso inválido';

	/// es: 'El anfitrión no responde'
	String get hostUnreachable => 'El anfitrión no responde';

	/// es: 'Error en el subsistema de audio'
	String get audio => 'Error en el subsistema de audio';

	/// es: 'Error inesperado'
	String get unexpected => 'Error inesperado';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Frecu',
			'lobby.title' => 'Frecu',
			'lobby.createRoom' => 'Crear frecu',
			'lobby.scanQr' => 'Escanear QR',
			'lobby.joinRoom' => 'Unirse a frecu',
			'lobby.nearbyRooms' => 'Frecus cercanas',
			'lobby.noRoomsNearby' => 'No se encontraron frecus en la red',
			'lobby.accessCode' => 'Código de acceso',
			'lobby.roomName' => 'Nombre de la frecu',
			'lobby.yourName' => 'Tu nombre visible',
			'room.title' => 'Frecu activa',
			'room.leave' => 'Salir de la frecu',
			'room.participants' => 'Participantes',
			'room.pushToTalk' => 'Mantén presionado para hablar',
			'room.openMic' => 'Micrófono abierto',
			'room.speaker' => 'Altavoz',
			'room.earpiece' => 'Auricular',
			'room.bluetooth' => 'Bluetooth',
			'room.speaking' => 'Hablando',
			'room.muted' => 'Silenciado',
			'room.host' => 'Anfitrión',
			'room.roomClosed' => 'La frecu fue cerrada por el anfitrión',
			'permissions.title' => 'Permisos requeridos',
			'permissions.description' => 'Frecu necesita permisos para comunicarse sin internet.',
			'permissions.microphone' => 'Micrófono',
			'permissions.microphoneDesc' => 'Transmite tu voz a los participantes de la frecu.',
			'permissions.nearbyDevices' => 'Red local y dispositivos cercanos',
			'permissions.nearbyDevicesDesc' => 'Descubre y conecta con otros teléfonos en la misma red.',
			'permissions.notifications' => 'Notificaciones',
			'permissions.notificationsDesc' => 'Mantiene la frecu activa en segundo plano con pantalla apagada.',
			'permissions.grant' => 'Conceder permisos',
			'permissions.granted' => 'Permisos concedidos',
			'settings.title' => 'Ajustes',
			'settings.displayName' => 'Nombre visible',
			'settings.defaultTalkMode' => 'Modo de habla por defecto',
			'settings.language' => 'Idioma',
			'errors.network' => 'Error de red local',
			'errors.permissionDenied' => 'Permiso denegado',
			'errors.roomFull' => 'La frecu está llena (máximo 6 participantes)',
			'errors.invalidAccessCode' => 'Código de acceso inválido',
			'errors.hostUnreachable' => 'El anfitrión no responde',
			'errors.audio' => 'Error en el subsistema de audio',
			'errors.unexpected' => 'Error inesperado',
			_ => null,
		};
	}
}
