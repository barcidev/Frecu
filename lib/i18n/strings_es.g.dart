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

	/// es: 'frecu'
	String get title => 'frecu';

	/// es: 'Ajustes'
	String get settings => 'Ajustes';

	/// es: 'Elige tu frecu'
	String get heading => 'Elige tu frecu';

	/// es: 'Crear frecu'
	String get createRoom => 'Crear frecu';

	/// es: 'Escanear'
	String get scanQr => 'Escanear';

	/// es: 'Conectar por IP'
	String get joinRoom => 'Conectar por IP';

	/// es: 'Frecus cercanas'
	String get nearbyRooms => 'Frecus cercanas';

	/// es: 'Código de acceso'
	String get accessCode => 'Código de acceso';

	/// es: 'Nombre de la frecu'
	String get roomName => 'Nombre de la frecu';

	late final Translations$lobby$network$es network = Translations$lobby$network$es.internal(_root);
	late final Translations$lobby$tuner$es tuner = Translations$lobby$tuner$es.internal(_root);
	late final Translations$lobby$empty$es empty = Translations$lobby$empty$es.internal(_root);
	late final Translations$lobby$offline$es offline = Translations$lobby$offline$es.internal(_root);
	List<String> get noteNames => [
		'Do',
		'Re♭',
		'Re',
		'Mi♭',
		'Mi',
		'Fa',
		'Fa♯',
		'Sol',
		'La♭',
		'La',
		'Si♭',
		'Si',
	];

	/// es: '—'
	String get noNote => '—';

	/// es: '$value Hz'
	String hz({required Object value}) => '${value} Hz';

	/// es: ','
	String get decimalSeparator => ',';
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

	/// es: 'Reconectando...'
	String get reconnecting => 'Reconectando...';

	/// es: 'Aceptar'
	String get accept => 'Aceptar';

	List<String> get noteNames => [
		'Do',
		'Re♭',
		'Re',
		'Mi♭',
		'Mi',
		'Fa',
		'Fa♯',
		'Sol',
		'La♭',
		'La',
		'Si♭',
		'Si',
	];
	late final Translations$room$mesh$es mesh = Translations$room$mesh$es.internal(_root);
	late final Translations$room$header$es header = Translations$room$header$es.internal(_root);
	late final Translations$room$talk$es talk = Translations$room$talk$es.internal(_root);
}

// Path: permissions
class Translations$permissions$es {
	Translations$permissions$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Atrás'
	String get back => 'Atrás';

	/// es: '$current / $total'
	String stepOf({required Object current, required Object total}) => '${current} / ${total}';

	late final Translations$permissions$welcome$es welcome = Translations$permissions$welcome$es.internal(_root);
	late final Translations$permissions$name$es name = Translations$permissions$name$es.internal(_root);

	/// es: 'Tres permisos y listo.'
	String get title => 'Tres permisos y listo.';

	/// es: 'Frecu solo habla con tu red local. Tu voz nunca sale de tu grupo.'
	String get description => 'Frecu solo habla con tu red local. Tu voz nunca sale de tu grupo.';

	/// es: 'Micrófono'
	String get microphone => 'Micrófono';

	/// es: 'Para que tu grupo te escuche.'
	String get microphoneDesc => 'Para que tu grupo te escuche.';

	/// es: 'Red local y dispositivos cercanos'
	String get nearbyDevices => 'Red local y dispositivos cercanos';

	/// es: 'Para encontrar frecus y usar audífonos Bluetooth.'
	String get nearbyDevicesDesc => 'Para encontrar frecus y usar audífonos Bluetooth.';

	/// es: 'Notificaciones'
	String get notifications => 'Notificaciones';

	/// es: 'Mantienen la frecu viva con la pantalla apagada.'
	String get notificationsDesc => 'Mantienen la frecu viva con la pantalla apagada.';

	/// es: 'La cámara se pedirá solo al escanear un QR.'
	String get camera => 'La cámara se pedirá solo al escanear un QR.';

	/// es: 'Conceder permisos'
	String get grant => 'Conceder permisos';

	/// es: 'Ajustes'
	String get openSettings => 'Ajustes';

	/// es: 'Continuar'
	String get finish => 'Continuar';

	late final Translations$permissions$status$es status = Translations$permissions$status$es.internal(_root);
}

// Path: settings
class Translations$settings$es {
	Translations$settings$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Ajustes'
	String get title => 'Ajustes';

	/// es: 'Atrás'
	String get back => 'Atrás';

	/// es: 'Nombre visible'
	String get displayName => 'Nombre visible';

	/// es: 'Sin nombre'
	String get noName => 'Sin nombre';

	/// es: 'Editar'
	String get edit => 'Editar';

	late final Translations$settings$editName$es editName = Translations$settings$editName$es.internal(_root);

	/// es: 'Voz'
	String get voice => 'Voz';

	/// es: 'Modo de habla por defecto'
	String get defaultTalkMode => 'Modo de habla por defecto';

	/// es: 'Se aplica al entrar a cada frecu.'
	String get defaultTalkModeHelp => 'Se aplica al entrar a cada frecu.';

	late final Translations$settings$talkMode$es talkMode = Translations$settings$talkMode$es.internal(_root);

	/// es: 'Apariencia'
	String get appearance => 'Apariencia';

	/// es: 'Tema'
	String get theme => 'Tema';

	/// es: 'Auto sigue al teléfono'
	String get themeHelp => 'Auto sigue al teléfono';

	late final Translations$settings$themeMode$es themeMode = Translations$settings$themeMode$es.internal(_root);

	/// es: 'No se pudo guardar'
	String get saveError => 'No se pudo guardar';

	/// es: '100 % local · sin internet'
	String get footer => '100 % local · sin internet';
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

// Path: lobby.network
class Translations$lobby$network$es {
	Translations$lobby$network$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Buscando red'
	String get checking => 'Buscando red';

	/// es: 'Red · $ip'
	String connected({required Object ip}) => 'Red · ${ip}';

	/// es: 'Sin red local'
	String get offline => 'Sin red local';
}

// Path: lobby.tuner
class Translations$lobby$tuner$es {
	Translations$lobby$tuner$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Escaneando · _frecu._tcp'
	String get scanning => 'Escaneando · _frecu._tcp';

	/// es: 'Búsqueda en pausa'
	String get paused => 'Búsqueda en pausa';

	/// es: '(one) {$n señal} (other) {$n señales}'
	String signals({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '${n} señal',
		other: '${n} señales',
	);
}

// Path: lobby.empty
class Translations$lobby$empty$es {
	Translations$lobby$empty$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Sin señales por ahora'
	String get title => 'Sin señales por ahora';

	/// es: 'Conéctate a la Wi-Fi del anfitrión o pídele que te muestre su QR.'
	String get message => 'Conéctate a la Wi-Fi del anfitrión o pídele que te muestre su QR.';

	/// es: 'La búsqueda sigue activa'
	String get searching => 'La búsqueda sigue activa';
}

// Path: lobby.offline
class Translations$lobby$offline$es {
	Translations$lobby$offline$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'No estás en ninguna red Wi-Fi.'
	String get title => 'No estás en ninguna red Wi-Fi.';

	/// es: 'Únete al punto de acceso del anfitrión para encontrar frecus.'
	String get message => 'Únete al punto de acceso del anfitrión para encontrar frecus.';
}

// Path: room.mesh
class Translations$room$mesh$es {
	Translations$room$mesh$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Tú'
	String get you => 'Tú';

	/// es: 'Tú · anfitrión'
	String get youHost => 'Tú · anfitrión';

	/// es: 'Al aire'
	String get onAir => 'Al aire';

	/// es: 'Conectando'
	String get connecting => 'Conectando';

	/// es: 'Reconectando'
	String get reconnecting => 'Reconectando';

	/// es: 'Libre'
	String get free => 'Libre';

	/// es: 'Invitar'
	String get invite => 'Invitar';
}

// Path: room.header
class Translations$room$header$es {
	Translations$room$header$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Eres el anfitrión'
	String get youAreHost => 'Eres el anfitrión';

	/// es: 'Anfitrión · $name'
	String hostedBy({required Object name}) => 'Anfitrión · ${name}';

	/// es: '$value Hz'
	String hz({required Object value}) => '${value} Hz';

	/// es: 'Nota $note, $hz Hz'
	String note({required Object note, required Object hz}) => 'Nota ${note}, ${hz} Hz';

	/// es: 'Invitar'
	String get invite => 'Invitar';
}

// Path: room.talk
class Translations$room$talk$es {
	Translations$room$talk$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'PTT'
	String get modePtt => 'PTT';

	/// es: 'Abierto'
	String get modeOpen => 'Abierto';

	late final Translations$room$talk$core$es core = Translations$room$talk$core$es.internal(_root);
	late final Translations$room$talk$hint$es hint = Translations$room$talk$hint$es.internal(_root);
	late final Translations$room$talk$island$es island = Translations$room$talk$island$es.internal(_root);
	late final Translations$room$talk$echo$es echo = Translations$room$talk$echo$es.internal(_root);
}

// Path: permissions.welcome
class Translations$permissions$welcome$es {
	Translations$permissions$welcome$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Sin internet · sin cobertura'
	String get kicker => 'Sin internet · sin cobertura';

	/// es: 'Todo tu grupo en la misma frecu.'
	String get title => 'Todo tu grupo en la misma frecu.';

	/// es: 'Habla en tiempo real con hasta 6 personas cerca de ti. Solo necesitan compartir una red Wi-Fi.'
	String get message => 'Habla en tiempo real con hasta 6 personas cerca de ti. Solo necesitan compartir una red Wi-Fi.';

	/// es: 'Empezar'
	String get start => 'Empezar';
}

// Path: permissions.name
class Translations$permissions$name$es {
	Translations$permissions$name$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: '¿Cómo te llamamos?'
	String get title => '¿Cómo te llamamos?';

	/// es: 'Así te verán y escucharán en cada frecu.'
	String get message => 'Así te verán y escucharán en cada frecu.';

	/// es: 'Tu firma de señal · nace de tu nombre'
	String get signature => 'Tu firma de señal · nace de tu nombre';

	/// es: 'Nombre visible'
	String get label => 'Nombre visible';

	/// es: 'Tu nombre'
	String get hint => 'Tu nombre';

	/// es: 'Puedes cambiarlo cuando quieras en Ajustes.'
	String get help => 'Puedes cambiarlo cuando quieras en Ajustes.';

	/// es: 'Usa como máximo $max caracteres.'
	String tooLong({required Object max}) => 'Usa como máximo ${max} caracteres.';

	/// es: 'No se pudo guardar tu nombre. Inténtalo de nuevo.'
	String get saveError => 'No se pudo guardar tu nombre. Inténtalo de nuevo.';

	/// es: 'Continuar'
	String get next => 'Continuar';
}

// Path: permissions.status
class Translations$permissions$status$es {
	Translations$permissions$status$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Pendiente'
	String get pending => 'Pendiente';

	/// es: 'Concedido'
	String get granted => 'Concedido';

	/// es: 'Denegado'
	String get denied => 'Denegado';
}

// Path: settings.editName
class Translations$settings$editName$es {
	Translations$settings$editName$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Tu nombre'
	String get title => 'Tu nombre';

	/// es: 'Así te verán y escucharán en cada frecu.'
	String get message => 'Así te verán y escucharán en cada frecu.';

	/// es: 'Escribe tu nombre'
	String get hint => 'Escribe tu nombre';

	/// es: 'Guardar'
	String get save => 'Guardar';

	/// es: 'Usa como máximo $max caracteres.'
	String tooLong({required Object max}) => 'Usa como máximo ${max} caracteres.';

	/// es: 'No se pudo guardar el nombre. Intenta otra vez.'
	String get saveError => 'No se pudo guardar el nombre. Intenta otra vez.';
}

// Path: settings.talkMode
class Translations$settings$talkMode$es {
	Translations$settings$talkMode$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'PTT'
	String get pushToTalk => 'PTT';

	/// es: 'Abierto'
	String get openMic => 'Abierto';
}

// Path: settings.themeMode
class Translations$settings$themeMode$es {
	Translations$settings$themeMode$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Auto'
	String get auto => 'Auto';

	/// es: 'Claro'
	String get light => 'Claro';

	/// es: 'Oscuro'
	String get dark => 'Oscuro';
}

// Path: room.talk.core
class Translations$room$talk$core$es {
	Translations$room$talk$core$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Mantén'
	String get hold => 'Mantén';

	/// es: 'Al aire'
	String get onAir => 'Al aire';

	/// es: 'Abierto'
	String get open => 'Abierto';

	/// es: 'Silencio'
	String get silence => 'Silencio';

	/// es: 'En espera'
	String get standby => 'En espera';

	/// es: 'Hablar'
	String get talk => 'Hablar';
}

// Path: room.talk.hint
class Translations$room$talk$hint$es {
	Translations$room$talk$hint$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Mantén para hablar'
	String get idle => 'Mantén para hablar';

	/// es: 'Muestra el QR para que tu grupo se una'
	String get alone => 'Muestra el QR para que tu grupo se una';

	/// es: '$name está hablando · puedes responder'
	String receiving({required Object name}) => '${name} está hablando · puedes responder';

	/// es: 'Suelta para escuchar'
	String get onAir => 'Suelta para escuchar';

	/// es: 'Toca para silenciarte'
	String get open => 'Toca para silenciarte';

	/// es: 'Toca para activar tu micrófono'
	String get muted => 'Toca para activar tu micrófono';

	/// es: 'Conectando con el anfitrión…'
	String get connecting => 'Conectando con el anfitrión…';

	/// es: 'Recuperando la conexión…'
	String get reconnecting => 'Recuperando la conexión…';
}

// Path: room.talk.island
class Translations$room$talk$island$es {
	Translations$room$talk$island$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'En línea · $count/$max'
	String online({required Object count, required Object max}) => 'En línea · ${count}/${max}';

	/// es: 'Micrófono abierto · $count/$max'
	String openMic({required Object count, required Object max}) => 'Micrófono abierto · ${count}/${max}';

	/// es: 'Silenciado · $count/$max'
	String muted({required Object count, required Object max}) => 'Silenciado · ${count}/${max}';

	/// es: 'Al aire · $time'
	String onAir({required Object time}) => 'Al aire · ${time}';

	/// es: '$name · hablando'
	String receiving({required Object name}) => '${name} · hablando';

	/// es: 'Al aire · esperando a tu grupo'
	String get waiting => 'Al aire · esperando a tu grupo';

	/// es: 'Conectando…'
	String get connecting => 'Conectando…';

	/// es: 'Reconectando…'
	String get reconnecting => 'Reconectando…';
}

// Path: room.talk.echo
class Translations$room$talk$echo$es {
	Translations$room$talk$echo$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Micrófono abierto con altavoz.'
	String get title => 'Micrófono abierto con altavoz.';

	/// es: 'Usa audífonos para evitar eco.'
	String get message => 'Usa audífonos para evitar eco.';

	/// es: 'Cerrar aviso'
	String get dismiss => 'Cerrar aviso';
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
			'lobby.title' => 'frecu',
			'lobby.settings' => 'Ajustes',
			'lobby.heading' => 'Elige tu frecu',
			'lobby.createRoom' => 'Crear frecu',
			'lobby.scanQr' => 'Escanear',
			'lobby.joinRoom' => 'Conectar por IP',
			'lobby.nearbyRooms' => 'Frecus cercanas',
			'lobby.accessCode' => 'Código de acceso',
			'lobby.roomName' => 'Nombre de la frecu',
			'lobby.network.checking' => 'Buscando red',
			'lobby.network.connected' => ({required Object ip}) => 'Red · ${ip}',
			'lobby.network.offline' => 'Sin red local',
			'lobby.tuner.scanning' => 'Escaneando · _frecu._tcp',
			'lobby.tuner.paused' => 'Búsqueda en pausa',
			'lobby.tuner.signals' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} señal', other: '${n} señales', ), 
			'lobby.empty.title' => 'Sin señales por ahora',
			'lobby.empty.message' => 'Conéctate a la Wi-Fi del anfitrión o pídele que te muestre su QR.',
			'lobby.empty.searching' => 'La búsqueda sigue activa',
			'lobby.offline.title' => 'No estás en ninguna red Wi-Fi.',
			'lobby.offline.message' => 'Únete al punto de acceso del anfitrión para encontrar frecus.',
			'lobby.noteNames.0' => 'Do',
			'lobby.noteNames.1' => 'Re♭',
			'lobby.noteNames.2' => 'Re',
			'lobby.noteNames.3' => 'Mi♭',
			'lobby.noteNames.4' => 'Mi',
			'lobby.noteNames.5' => 'Fa',
			'lobby.noteNames.6' => 'Fa♯',
			'lobby.noteNames.7' => 'Sol',
			'lobby.noteNames.8' => 'La♭',
			'lobby.noteNames.9' => 'La',
			'lobby.noteNames.10' => 'Si♭',
			'lobby.noteNames.11' => 'Si',
			'lobby.noNote' => '—',
			'lobby.hz' => ({required Object value}) => '${value} Hz',
			'lobby.decimalSeparator' => ',',
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
			'room.reconnecting' => 'Reconectando...',
			'room.accept' => 'Aceptar',
			'room.noteNames.0' => 'Do',
			'room.noteNames.1' => 'Re♭',
			'room.noteNames.2' => 'Re',
			'room.noteNames.3' => 'Mi♭',
			'room.noteNames.4' => 'Mi',
			'room.noteNames.5' => 'Fa',
			'room.noteNames.6' => 'Fa♯',
			'room.noteNames.7' => 'Sol',
			'room.noteNames.8' => 'La♭',
			'room.noteNames.9' => 'La',
			'room.noteNames.10' => 'Si♭',
			'room.noteNames.11' => 'Si',
			'room.mesh.you' => 'Tú',
			'room.mesh.youHost' => 'Tú · anfitrión',
			'room.mesh.onAir' => 'Al aire',
			'room.mesh.connecting' => 'Conectando',
			'room.mesh.reconnecting' => 'Reconectando',
			'room.mesh.free' => 'Libre',
			'room.mesh.invite' => 'Invitar',
			'room.header.youAreHost' => 'Eres el anfitrión',
			'room.header.hostedBy' => ({required Object name}) => 'Anfitrión · ${name}',
			'room.header.hz' => ({required Object value}) => '${value} Hz',
			'room.header.note' => ({required Object note, required Object hz}) => 'Nota ${note}, ${hz} Hz',
			'room.header.invite' => 'Invitar',
			'room.talk.modePtt' => 'PTT',
			'room.talk.modeOpen' => 'Abierto',
			'room.talk.core.hold' => 'Mantén',
			'room.talk.core.onAir' => 'Al aire',
			'room.talk.core.open' => 'Abierto',
			'room.talk.core.silence' => 'Silencio',
			'room.talk.core.standby' => 'En espera',
			'room.talk.core.talk' => 'Hablar',
			'room.talk.hint.idle' => 'Mantén para hablar',
			'room.talk.hint.alone' => 'Muestra el QR para que tu grupo se una',
			'room.talk.hint.receiving' => ({required Object name}) => '${name} está hablando · puedes responder',
			'room.talk.hint.onAir' => 'Suelta para escuchar',
			'room.talk.hint.open' => 'Toca para silenciarte',
			'room.talk.hint.muted' => 'Toca para activar tu micrófono',
			'room.talk.hint.connecting' => 'Conectando con el anfitrión…',
			'room.talk.hint.reconnecting' => 'Recuperando la conexión…',
			'room.talk.island.online' => ({required Object count, required Object max}) => 'En línea · ${count}/${max}',
			'room.talk.island.openMic' => ({required Object count, required Object max}) => 'Micrófono abierto · ${count}/${max}',
			'room.talk.island.muted' => ({required Object count, required Object max}) => 'Silenciado · ${count}/${max}',
			'room.talk.island.onAir' => ({required Object time}) => 'Al aire · ${time}',
			'room.talk.island.receiving' => ({required Object name}) => '${name} · hablando',
			'room.talk.island.waiting' => 'Al aire · esperando a tu grupo',
			'room.talk.island.connecting' => 'Conectando…',
			'room.talk.island.reconnecting' => 'Reconectando…',
			'room.talk.echo.title' => 'Micrófono abierto con altavoz.',
			'room.talk.echo.message' => 'Usa audífonos para evitar eco.',
			'room.talk.echo.dismiss' => 'Cerrar aviso',
			'permissions.back' => 'Atrás',
			'permissions.stepOf' => ({required Object current, required Object total}) => '${current} / ${total}',
			'permissions.welcome.kicker' => 'Sin internet · sin cobertura',
			'permissions.welcome.title' => 'Todo tu grupo en la misma frecu.',
			'permissions.welcome.message' => 'Habla en tiempo real con hasta 6 personas cerca de ti. Solo necesitan compartir una red Wi-Fi.',
			'permissions.welcome.start' => 'Empezar',
			'permissions.name.title' => '¿Cómo te llamamos?',
			'permissions.name.message' => 'Así te verán y escucharán en cada frecu.',
			'permissions.name.signature' => 'Tu firma de señal · nace de tu nombre',
			'permissions.name.label' => 'Nombre visible',
			'permissions.name.hint' => 'Tu nombre',
			'permissions.name.help' => 'Puedes cambiarlo cuando quieras en Ajustes.',
			'permissions.name.tooLong' => ({required Object max}) => 'Usa como máximo ${max} caracteres.',
			'permissions.name.saveError' => 'No se pudo guardar tu nombre. Inténtalo de nuevo.',
			'permissions.name.next' => 'Continuar',
			'permissions.title' => 'Tres permisos y listo.',
			'permissions.description' => 'Frecu solo habla con tu red local. Tu voz nunca sale de tu grupo.',
			'permissions.microphone' => 'Micrófono',
			'permissions.microphoneDesc' => 'Para que tu grupo te escuche.',
			'permissions.nearbyDevices' => 'Red local y dispositivos cercanos',
			'permissions.nearbyDevicesDesc' => 'Para encontrar frecus y usar audífonos Bluetooth.',
			'permissions.notifications' => 'Notificaciones',
			'permissions.notificationsDesc' => 'Mantienen la frecu viva con la pantalla apagada.',
			'permissions.camera' => 'La cámara se pedirá solo al escanear un QR.',
			'permissions.grant' => 'Conceder permisos',
			'permissions.openSettings' => 'Ajustes',
			'permissions.finish' => 'Continuar',
			'permissions.status.pending' => 'Pendiente',
			'permissions.status.granted' => 'Concedido',
			'permissions.status.denied' => 'Denegado',
			'settings.title' => 'Ajustes',
			'settings.back' => 'Atrás',
			'settings.displayName' => 'Nombre visible',
			'settings.noName' => 'Sin nombre',
			'settings.edit' => 'Editar',
			'settings.editName.title' => 'Tu nombre',
			'settings.editName.message' => 'Así te verán y escucharán en cada frecu.',
			'settings.editName.hint' => 'Escribe tu nombre',
			'settings.editName.save' => 'Guardar',
			'settings.editName.tooLong' => ({required Object max}) => 'Usa como máximo ${max} caracteres.',
			'settings.editName.saveError' => 'No se pudo guardar el nombre. Intenta otra vez.',
			'settings.voice' => 'Voz',
			'settings.defaultTalkMode' => 'Modo de habla por defecto',
			'settings.defaultTalkModeHelp' => 'Se aplica al entrar a cada frecu.',
			'settings.talkMode.pushToTalk' => 'PTT',
			'settings.talkMode.openMic' => 'Abierto',
			'settings.appearance' => 'Apariencia',
			'settings.theme' => 'Tema',
			'settings.themeHelp' => 'Auto sigue al teléfono',
			'settings.themeMode.auto' => 'Auto',
			'settings.themeMode.light' => 'Claro',
			'settings.themeMode.dark' => 'Oscuro',
			'settings.saveError' => 'No se pudo guardar',
			'settings.footer' => '100 % local · sin internet',
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
