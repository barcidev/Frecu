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
	late final Translations$splash$es splash = Translations$splash$es.internal(_root);
	late final Translations$messages$es messages = Translations$messages$es.internal(_root);
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

	late final Translations$lobby$join$es join = Translations$lobby$join$es.internal(_root);

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

	/// es: 'Frecu sin nombre'
	String get unnamedRoom => 'Frecu sin nombre';

	late final Translations$lobby$network$es network = Translations$lobby$network$es.internal(_root);
	late final Translations$lobby$tuner$es tuner = Translations$lobby$tuner$es.internal(_root);
	late final Translations$lobby$empty$es empty = Translations$lobby$empty$es.internal(_root);
	late final Translations$lobby$offline$es offline = Translations$lobby$offline$es.internal(_root);
	late final Translations$lobby$newRoom$es newRoom = Translations$lobby$newRoom$es.internal(_root);
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

	/// es: 'Reconectando...'
	String get reconnecting => 'Reconectando...';

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
	late final Translations$room$sheets$es sheets = Translations$room$sheets$es.internal(_root);
	late final Translations$room$closure$es closure = Translations$room$closure$es.internal(_root);
	late final Translations$room$talk$es talk = Translations$room$talk$es.internal(_root);
	late final Translations$room$notification$es notification = Translations$room$notification$es.internal(_root);
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

	/// es: 'General'
	String get general => 'General';

	late final Translations$settings$language$es language = Translations$settings$language$es.internal(_root);
	late final Translations$settings$permissions$es permissions = Translations$settings$permissions$es.internal(_root);

	/// es: 'Guía del punto de acceso'
	String get hotspotGuide => 'Guía del punto de acceso';

	late final Translations$settings$vibration$es vibration = Translations$settings$vibration$es.internal(_root);

	/// es: 'Licencias'
	String get licenses => 'Licencias';

	/// es: 'Apariencia'
	String get appearance => 'Apariencia';

	/// es: 'Tema'
	String get theme => 'Tema';

	/// es: 'Auto sigue al teléfono'
	String get themeHelp => 'Auto sigue al teléfono';

	late final Translations$settings$themeMode$es themeMode = Translations$settings$themeMode$es.internal(_root);

	/// es: 'No se pudo guardar'
	String get saveError => 'No se pudo guardar';

	/// es: '$app · 100% local · sin internet'
	String footer({required Object app}) => '${app} · 100% local · sin internet';

	/// es: 'Frecu $version'
	String appVersion({required Object version}) => 'Frecu ${version}';
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

	/// es: 'Esta frecu usa otra versión de Frecu'
	String get versionMismatch => 'Esta frecu usa otra versión de Frecu';

	/// es: 'Error en el subsistema de audio'
	String get audio => 'Error en el subsistema de audio';

	/// es: 'Error inesperado'
	String get unexpected => 'Error inesperado';
}

// Path: splash
class Translations$splash$es {
	Translations$splash$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'frecu'
	String get title => 'frecu';

	/// es: 'Voz de grupo. Sin internet.'
	String get tagline => 'Voz de grupo. Sin internet.';

	/// es: 'v$version'
	String version({required Object version}) => 'v${version}';

	/// es: 'Red local'
	String get localNetwork => 'Red local';

	/// es: 'Malla P2P'
	String get mesh => 'Malla P2P';

	/// es: 'Toca para entrar'
	String get skip => 'Toca para entrar';
}

// Path: messages
class Translations$messages$es {
	Translations$messages$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Mensajes'
	String get button => 'Mensajes';

	/// es: 'Para toda la frecu'
	String get kicker => 'Para toda la frecu';

	/// es: 'Mensajes rápidos'
	String get title => 'Mensajes rápidos';

	/// es: 'Llegan al instante y vibran, aunque tengan la pantalla apagada.'
	String get message => 'Llegan al instante y vibran, aunque tengan la pantalla apagada.';

	late final Translations$messages$kinds$es kinds = Translations$messages$kinds$es.internal(_root);

	/// es: 'Mantén para enviar SOS'
	String get sosHold => 'Mantén para enviar SOS';

	/// es: 'Alarma para todos hasta que alguien la atienda'
	String get sosHoldHelp => 'Alarma para todos hasta que alguien la atienda';

	/// es: 'Enviado · $text'
	String sent({required Object text}) => 'Enviado · ${text}';

	/// es: 'SOS enviado a tu grupo'
	String get sosSent => 'SOS enviado a tu grupo';

	/// es: '$name · $text'
	String received({required Object name, required Object text}) => '${name} · ${text}';

	/// es: 'No se pudo enviar: sin conexión con el anfitrión'
	String get sendError => 'No se pudo enviar: sin conexión con el anfitrión';

	late final Translations$messages$sos$es sos = Translations$messages$sos$es.internal(_root);
}

// Path: lobby.join
class Translations$lobby$join$es {
	Translations$lobby$join$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Cerrar'
	String get close => 'Cerrar';

	/// es: 'Puerto $port'
	String port({required Object port}) => 'Puerto ${port}';

	/// es: 'Código incorrecto. Revisa e intenta otra vez.'
	String get wrongCode => 'Código incorrecto. Revisa e intenta otra vez.';

	/// es: 'Podrás entrar cuando alguien salga.'
	String get roomFullHint => 'Podrás entrar cuando alguien salga.';

	/// es: 'Revisa que estés en su misma red Wi-Fi.'
	String get unreachableHint => 'Revisa que estés en su misma red Wi-Fi.';

	/// es: 'Participante'
	String get defaultName => 'Participante';

	/// es: 'Esta frecu está llena ($max/$max).'
	String full({required Object max}) => 'Esta frecu está llena (${max}/${max}).';

	/// es: 'El anfitrión no responde.'
	String get unreachable => 'El anfitrión no responde.';

	/// es: 'No se pudo entrar a la frecu.'
	String get failed => 'No se pudo entrar a la frecu.';

	/// es: 'Revisa que estés en su misma red Wi-Fi e intenta otra vez.'
	String get failedHint => 'Revisa que estés en su misma red Wi-Fi e intenta otra vez.';

	/// es: 'Esta frecu usa otra versión de Frecu.'
	String get versionMismatch => 'Esta frecu usa otra versión de Frecu.';

	/// es: 'Actualiza Frecu en los dos teléfonos.'
	String get versionMismatchHint => 'Actualiza Frecu en los dos teléfonos.';

	late final Translations$lobby$join$pin$es pin = Translations$lobby$join$pin$es.internal(_root);
	late final Translations$lobby$join$ip$es ip = Translations$lobby$join$ip$es.internal(_root);
	late final Translations$lobby$join$scan$es scan = Translations$lobby$join$scan$es.internal(_root);
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

	/// es: 'La búsqueda falló · reintentando'
	String get failed => 'La búsqueda falló · reintentando';
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

	/// es: 'Abrir ajustes de Wi-Fi'
	String get openSettings => 'Abrir ajustes de Wi-Fi';
}

// Path: lobby.newRoom
class Translations$lobby$newRoom$es {
	Translations$lobby$newRoom$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Atrás'
	String get back => 'Atrás';

	/// es: 'Paso $current de $total'
	String step({required Object current, required Object total}) => 'Paso ${current} de ${total}';

	late final Translations$lobby$newRoom$guide$es guide = Translations$lobby$newRoom$guide$es.internal(_root);

	/// es: 'Nueva frecu'
	String get title => 'Nueva frecu';

	/// es: 'Tu frecu suena en'
	String get soundsIn => 'Tu frecu suena en';

	/// es: 'Abierta a las $time'
	String openedAt({required Object time}) => 'Abierta a las ${time}';

	/// es: 'Nombre de la frecu'
	String get name => 'Nombre de la frecu';

	/// es: 'Ej. Ruta del domingo'
	String get nameHint => 'Ej. Ruta del domingo';

	/// es: 'Frecu de $name'
	String defaultName({required Object name}) => 'Frecu de ${name}';

	/// es: 'Mi frecu'
	String get untitled => 'Mi frecu';

	/// es: 'Código de acceso'
	String get code => 'Código de acceso';

	/// es: '4 dígitos'
	String get codeDigits => '4 dígitos';

	/// es: 'Generar otro'
	String get regenerate => 'Generar otro';

	/// es: 'Compártelo solo con tu grupo: evita que se unan desconocidos de la misma red.'
	String get codeHelp => 'Compártelo solo con tu grupo: evita que se unan desconocidos de la misma red.';

	/// es: 'Abrir frecu'
	String get open => 'Abrir frecu';

	/// es: 'Reloj de quintas: $time, $note'
	String clockLabel({required Object time, required Object note}) => 'Reloj de quintas: ${time}, ${note}';
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

	/// es: 'Señal débil'
	String get weak => 'Señal débil';

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

// Path: room.sheets
class Translations$room$sheets$es {
	Translations$room$sheets$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Cerrar'
	String get close => 'Cerrar';

	late final Translations$room$sheets$invite$es invite = Translations$room$sheets$invite$es.internal(_root);
	late final Translations$room$sheets$route$es route = Translations$room$sheets$route$es.internal(_root);
	late final Translations$room$sheets$leave$es leave = Translations$room$sheets$leave$es.internal(_root);
}

// Path: room.closure
class Translations$room$closure$es {
	Translations$room$closure$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Fuera del aire'
	String get offAir => 'Fuera del aire';

	/// es: '$note · fuera del aire'
	String noteOffAir({required Object note}) => '${note} · fuera del aire';

	/// es: 'Fin de la transmisión'
	String get title => 'Fin de la transmisión';

	/// es: 'Cerraste la frecu. Todos los participantes fueron desconectados.'
	String get host => 'Cerraste la frecu. Todos los participantes fueron desconectados.';

	/// es: 'El anfitrión cerró la frecu. Puedes unirte a otra cuando quieras.'
	String get peer => 'El anfitrión cerró la frecu. Puedes unirte a otra cuando quieras.';

	/// es: 'Se perdió la señal del anfitrión. Puedes unirte a otra cuando quieras.'
	String get lost => 'Se perdió la señal del anfitrión. Puedes unirte a otra cuando quieras.';

	/// es: 'Duración'
	String get duration => 'Duración';

	/// es: 'Personas'
	String get people => 'Personas';

	/// es: 'Nota'
	String get note => 'Nota';

	/// es: 'Volver al inicio'
	String get home => 'Volver al inicio';
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
	late final Translations$room$talk$mic$es mic = Translations$room$talk$mic$es.internal(_root);
}

// Path: room.notification
class Translations$room$notification$es {
	Translations$room$notification$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Frecu en segundo plano'
	String get channelName => 'Frecu en segundo plano';

	/// es: 'Mantiene activa la conexión de Frecu con la pantalla apagada.'
	String get channelDescription => 'Mantiene activa la conexión de Frecu con la pantalla apagada.';

	/// es: 'Frecu activa'
	String get title => 'Frecu activa';

	/// es: '$room · Conectado'
	String connected({required Object room}) => '${room} · Conectado';

	/// es: '$room · Reconectando…'
	String reconnecting({required Object room}) => '${room} · Reconectando…';

	/// es: 'Salir de la frecu'
	String get leave => 'Salir de la frecu';
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

// Path: settings.language
class Translations$settings$language$es {
	Translations$settings$language$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Idioma'
	String get title => 'Idioma';

	/// es: 'Auto usa el idioma del teléfono.'
	String get message => 'Auto usa el idioma del teléfono.';

	/// es: 'Auto'
	String get auto => 'Auto';

	/// es: 'Sigue al teléfono'
	String get autoHelp => 'Sigue al teléfono';

	/// es: 'Auto · $language'
	String autoValue({required Object language}) => 'Auto · ${language}';

	/// es: 'Español'
	String get es => 'Español';

	/// es: 'English'
	String get en => 'English';
}

// Path: settings.permissions
class Translations$settings$permissions$es {
	Translations$settings$permissions$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Permisos'
	String get title => 'Permisos';

	/// es: 'Micrófono, red local, notificaciones'
	String get subtitle => 'Micrófono, red local, notificaciones';

	/// es: '$granted/$total'
	String count({required Object granted, required Object total}) => '${granted}/${total}';
}

// Path: settings.vibration
class Translations$settings$vibration$es {
	Translations$settings$vibration$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Vibración'
	String get title => 'Vibración';

	/// es: 'Al transmitir, cuando alguien empieza a hablar y si se pierde la conexión.'
	String get subtitle => 'Al transmitir, cuando alguien empieza a hablar y si se pierde la conexión.';
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

// Path: messages.kinds
class Translations$messages$kinds$es {
	Translations$messages$kinds$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Me quedé atrás'
	String get behind => 'Me quedé atrás';

	/// es: 'Parada en la próxima'
	String get stop => 'Parada en la próxima';

	/// es: 'Necesito combustible'
	String get fuel => 'Necesito combustible';

	/// es: 'Todo bien'
	String get ok => 'Todo bien';

	/// es: 'Voy en camino'
	String get onMyWay => 'Voy en camino';

	/// es: 'SOS'
	String get sos => 'SOS';
}

// Path: messages.sos
class Translations$messages$sos$es {
	Translations$messages$sos$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'SOS'
	String get kicker => 'SOS';

	/// es: '$name necesita ayuda'
	String title({required Object name}) => '${name} necesita ayuda';

	/// es: 'Avisa al grupo si vas hacia allá. La alarma sigue hasta que la atiendas.'
	String get body => 'Avisa al grupo si vas hacia allá. La alarma sigue hasta que la atiendas.';

	/// es: 'Voy en camino'
	String get onMyWay => 'Voy en camino';

	/// es: 'Entendido'
	String get dismiss => 'Entendido';
}

// Path: lobby.join.pin
class Translations$lobby$join$pin$es {
	Translations$lobby$join$pin$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Ingresa el código de acceso. Pídeselo al anfitrión.'
	String get message => 'Ingresa el código de acceso. Pídeselo al anfitrión.';

	/// es: 'Se envía al completar los 4 dígitos'
	String get autoSend => 'Se envía al completar los 4 dígitos';

	/// es: 'Verificando con el anfitrión…'
	String get checking => 'Verificando con el anfitrión…';

	/// es: 'Código correcto · entrando'
	String get correct => 'Código correcto · entrando';

	/// es: 'Borrar'
	String get delete => 'Borrar';

	/// es: 'Entrarás como'
	String get joiningAs => 'Entrarás como';
}

// Path: lobby.join.ip
class Translations$lobby$join$ip$es {
	Translations$lobby$join$ip$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Conexión manual'
	String get kicker => 'Conexión manual';

	/// es: 'Úsalo si la frecu no aparece en la lista.'
	String get message => 'Úsalo si la frecu no aparece en la lista.';

	/// es: 'IP del anfitrión'
	String get host => 'IP del anfitrión';

	/// es: 'Sin respuesta en el puerto $port'
	String noAnswer({required Object port}) => 'Sin respuesta en el puerto ${port}';

	/// es: 'Escribe una IP como $ip.'
	String invalid({required Object ip}) => 'Escribe una IP como ${ip}.';

	/// es: 'Conectar'
	String get connect => 'Conectar';
}

// Path: lobby.join.scan
class Translations$lobby$join$scan$es {
	Translations$lobby$join$scan$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Escanear invitación'
	String get title => 'Escanear invitación';

	/// es: 'QR de la frecu'
	String get subtitle => 'QR de la frecu';

	/// es: 'Atrás'
	String get back => 'Atrás';

	/// es: 'Linterna'
	String get torch => 'Linterna';

	/// es: 'Apunta al QR que muestra el anfitrión en su teléfono.'
	String get hint => 'Apunta al QR que muestra el anfitrión en su teléfono.';

	/// es: 'Este QR no es una invitación de Frecu.'
	String get invalid => 'Este QR no es una invitación de Frecu.';

	/// es: 'Frecu encontrada'
	String get found => 'Frecu encontrada';

	/// es: 'Frecu sin nota'
	String get noNote => 'Frecu sin nota';

	/// es: 'Unirme'
	String get join => 'Unirme';

	/// es: 'Escanear otro QR'
	String get another => 'Escanear otro QR';

	late final Translations$lobby$join$scan$camera$es camera = Translations$lobby$join$scan$camera$es.internal(_root);
}

// Path: lobby.newRoom.guide
class Translations$lobby$newRoom$guide$es {
	Translations$lobby$newRoom$guide$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Prepara la red'
	String get title => 'Prepara la red';

	/// es: 'Activa tu punto de acceso'
	String get heading => 'Activa tu punto de acceso';

	/// es: 'Tu teléfono será la antena del grupo.'
	String get message => 'Tu teléfono será la antena del grupo.';

	/// es: 'Android'
	String get android => 'Android';

	/// es: 'iPhone'
	String get iphone => 'iPhone';

	List<HotspotStep> get androidSteps => [
		Translations$lobby$newRoom$guide$androidSteps$0$es.internal(_root),
		Translations$lobby$newRoom$guide$androidSteps$1$es.internal(_root),
		Translations$lobby$newRoom$guide$androidSteps$2$es.internal(_root),
	];
	List<HotspotStep> get iphoneSteps => [
		Translations$lobby$newRoom$guide$iphoneSteps$0$es.internal(_root),
		Translations$lobby$newRoom$guide$iphoneSteps$1$es.internal(_root),
		Translations$lobby$newRoom$guide$iphoneSteps$2$es.internal(_root),
	];

	/// es: 'Ya está activo'
	String get ready => 'Ya está activo';

	/// es: 'Ya estamos en la misma Wi-Fi'
	String get sameWifi => 'Ya estamos en la misma Wi-Fi';

	/// es: 'Abrir ajustes de zona Wi-Fi'
	String get openSettings => 'Abrir ajustes de zona Wi-Fi';

	/// es: 'Abrir Ajustes'
	String get openSettingsIphone => 'Abrir Ajustes';
}

// Path: room.sheets.invite
class Translations$room$sheets$invite$es {
	Translations$room$sheets$invite$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Invitar a la frecu'
	String get kicker => 'Invitar a la frecu';

	/// es: 'Escanea para unirte'
	String get title => 'Escanea para unirte';

	/// es: 'Desde Frecu › Escanear. El QR ya incluye el código.'
	String get message => 'Desde Frecu › Escanear. El QR ya incluye el código.';

	/// es: 'Nota'
	String get note => 'Nota';

	/// es: 'Código'
	String get code => 'Código';

	/// es: 'Anfitrión'
	String get host => 'Anfitrión';

	/// es: 'Puerto $port'
	String port({required Object port}) => 'Puerto ${port}';

	/// es: 'También aparece en “$list” para quien esté en tu red.'
	String footer({required Object list}) => 'También aparece en “${list}” para quien esté en tu red.';

	/// es: 'Código QR de invitación'
	String get qr => 'Código QR de invitación';
}

// Path: room.sheets.route
class Translations$room$sheets$route$es {
	Translations$room$sheets$route$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Salida de audio'
	String get kicker => 'Salida de audio';

	/// es: '¿Dónde escuchas?'
	String get title => '¿Dónde escuchas?';

	/// es: 'Al conectar audífonos, el audio cambia solo.'
	String get message => 'Al conectar audífonos, el audio cambia solo.';

	/// es: 'Manos libres'
	String get speakerSub => 'Manos libres';

	/// es: 'Teléfono en la oreja'
	String get earpieceSub => 'Teléfono en la oreja';

	/// es: 'Conectado'
	String get bluetoothOn => 'Conectado';

	/// es: 'Sin dispositivo'
	String get bluetoothOff => 'Sin dispositivo';

	/// es: 'Bluetooth · conectado'
	String get bluetoothDevice => 'Bluetooth · conectado';

	/// es: 'Salida de audio: $route'
	String label({required Object route}) => 'Salida de audio: ${route}';
}

// Path: room.sheets.leave
class Translations$room$sheets$leave$es {
	Translations$room$sheets$leave$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: '¿Salir de la frecu?'
	String get peerTitle => '¿Salir de la frecu?';

	/// es: 'Podrás volver a unirte con el código de acceso.'
	String get peerMessage => 'Podrás volver a unirte con el código de acceso.';

	/// es: 'Salir de la frecu'
	String get peerConfirm => 'Salir de la frecu';

	/// es: 'Cerrar la frecu para todos'
	String get hostTitle => 'Cerrar la frecu para todos';

	/// es: 'Eres el anfitrión. Si sales, la frecu se cierra.'
	String get hostAlone => 'Eres el anfitrión. Si sales, la frecu se cierra.';

	/// es: 'Eres el anfitrión. Si sales, la frecu se cierra para la otra persona.'
	String get hostOne => 'Eres el anfitrión. Si sales, la frecu se cierra para la otra persona.';

	/// es: 'Eres el anfitrión. Si sales, la frecu se cierra para las otras $count personas.'
	String hostMany({required Object count}) => 'Eres el anfitrión. Si sales, la frecu se cierra para las otras ${count} personas.';

	/// es: 'Cerrar frecu'
	String get hostConfirm => 'Cerrar frecu';

	/// es: 'Cancelar'
	String get cancel => 'Cancelar';
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

	/// es: 'Reconectando · $seconds s'
	String reconnectingIn({required Object seconds}) => 'Reconectando · ${seconds} s';

	/// es: '$name se unió'
	String joined({required Object name}) => '${name} se unió';

	/// es: '$name salió'
	String left({required Object name}) => '${name} salió';

	/// es: 'Audio por $route'
	String route({required Object route}) => 'Audio por ${route}';

	/// es: 'Conexión recuperada'
	String get recovered => 'Conexión recuperada';

	/// es: '$name · señal débil'
	String weak({required Object name}) => '${name} · señal débil';
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

// Path: room.talk.mic
class Translations$room$talk$mic$es {
	Translations$room$talk$mic$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Tu micrófono no está disponible.'
	String get title => 'Tu micrófono no está disponible.';

	/// es: 'Escuchas a tu grupo, pero nadie te oye. Revisa el permiso en Ajustes.'
	String get message => 'Escuchas a tu grupo, pero nadie te oye. Revisa el permiso en Ajustes.';

	/// es: 'Abrir ajustes'
	String get settings => 'Abrir ajustes';

	/// es: 'Cerrar aviso'
	String get dismiss => 'Cerrar aviso';
}

// Path: lobby.join.scan.camera
class Translations$lobby$join$scan$camera$es {
	Translations$lobby$join$scan$camera$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Frecu no tiene acceso a la cámara.'
	String get deniedTitle => 'Frecu no tiene acceso a la cámara.';

	/// es: 'Permítela en Ajustes para escanear la invitación, o conéctate por IP.'
	String get deniedMessage => 'Permítela en Ajustes para escanear la invitación, o conéctate por IP.';

	/// es: 'La cámara no está disponible.'
	String get unavailableTitle => 'La cámara no está disponible.';

	/// es: 'Puedes unirte con la IP del anfitrión.'
	String get unavailableMessage => 'Puedes unirte con la IP del anfitrión.';

	/// es: 'Abrir ajustes'
	String get openSettings => 'Abrir ajustes';
}

// Path: lobby.newRoom.guide.androidSteps.0
class Translations$lobby$newRoom$guide$androidSteps$0$es with HotspotStep {
	Translations$lobby$newRoom$guide$androidSteps$0$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Abre Ajustes › Zona Wi-Fi'
	@override String get lead => 'Abre Ajustes › Zona Wi-Fi';

	/// es: ' (el nombre cambia según la marca).'
	@override String get rest => ' (el nombre cambia según la marca).';
}

// Path: lobby.newRoom.guide.androidSteps.1
class Translations$lobby$newRoom$guide$androidSteps$1$es with HotspotStep {
	Translations$lobby$newRoom$guide$androidSteps$1$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Actívala'
	@override String get lead => 'Actívala';

	/// es: ' y comparte el nombre y la contraseña con tu grupo.'
	@override String get rest => ' y comparte el nombre y la contraseña con tu grupo.';
}

// Path: lobby.newRoom.guide.androidSteps.2
class Translations$lobby$newRoom$guide$androidSteps$2$es with HotspotStep {
	Translations$lobby$newRoom$guide$androidSteps$2$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Vuelve a Frecu'
	@override String get lead => 'Vuelve a Frecu';

	/// es: ' y abre tu frecu. No usa tus datos móviles.'
	@override String get rest => ' y abre tu frecu. No usa tus datos móviles.';
}

// Path: lobby.newRoom.guide.iphoneSteps.0
class Translations$lobby$newRoom$guide$iphoneSteps$0$es with HotspotStep {
	Translations$lobby$newRoom$guide$iphoneSteps$0$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Abre Ajustes › Punto de acceso personal'
	@override String get lead => 'Abre Ajustes › Punto de acceso personal';

	/// es: ' y activa «Permitir a otros conectarse».'
	@override String get rest => ' y activa «Permitir a otros conectarse».';
}

// Path: lobby.newRoom.guide.iphoneSteps.1
class Translations$lobby$newRoom$guide$iphoneSteps$1$es with HotspotStep {
	Translations$lobby$newRoom$guide$iphoneSteps$1$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Comparte la contraseña'
	@override String get lead => 'Comparte la contraseña';

	/// es: ' con tu grupo y que se unan a tu red.'
	@override String get rest => ' con tu grupo y que se unan a tu red.';
}

// Path: lobby.newRoom.guide.iphoneSteps.2
class Translations$lobby$newRoom$guide$iphoneSteps$2$es with HotspotStep {
	Translations$lobby$newRoom$guide$iphoneSteps$2$es.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// es: 'Mantén Frecu abierta'
	@override String get lead => 'Mantén Frecu abierta';

	/// es: ' mientras se unen. En iPhone recomendamos que el anfitrión use Android.'
	@override String get rest => ' mientras se unen. En iPhone recomendamos que el anfitrión use Android.';
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
			'lobby.join.close' => 'Cerrar',
			'lobby.join.port' => ({required Object port}) => 'Puerto ${port}',
			'lobby.join.wrongCode' => 'Código incorrecto. Revisa e intenta otra vez.',
			'lobby.join.roomFullHint' => 'Podrás entrar cuando alguien salga.',
			'lobby.join.unreachableHint' => 'Revisa que estés en su misma red Wi-Fi.',
			'lobby.join.defaultName' => 'Participante',
			'lobby.join.full' => ({required Object max}) => 'Esta frecu está llena (${max}/${max}).',
			'lobby.join.unreachable' => 'El anfitrión no responde.',
			'lobby.join.failed' => 'No se pudo entrar a la frecu.',
			'lobby.join.failedHint' => 'Revisa que estés en su misma red Wi-Fi e intenta otra vez.',
			'lobby.join.versionMismatch' => 'Esta frecu usa otra versión de Frecu.',
			'lobby.join.versionMismatchHint' => 'Actualiza Frecu en los dos teléfonos.',
			'lobby.join.pin.message' => 'Ingresa el código de acceso. Pídeselo al anfitrión.',
			'lobby.join.pin.autoSend' => 'Se envía al completar los 4 dígitos',
			'lobby.join.pin.checking' => 'Verificando con el anfitrión…',
			'lobby.join.pin.correct' => 'Código correcto · entrando',
			'lobby.join.pin.delete' => 'Borrar',
			'lobby.join.pin.joiningAs' => 'Entrarás como',
			'lobby.join.ip.kicker' => 'Conexión manual',
			'lobby.join.ip.message' => 'Úsalo si la frecu no aparece en la lista.',
			'lobby.join.ip.host' => 'IP del anfitrión',
			'lobby.join.ip.noAnswer' => ({required Object port}) => 'Sin respuesta en el puerto ${port}',
			'lobby.join.ip.invalid' => ({required Object ip}) => 'Escribe una IP como ${ip}.',
			'lobby.join.ip.connect' => 'Conectar',
			'lobby.join.scan.title' => 'Escanear invitación',
			'lobby.join.scan.subtitle' => 'QR de la frecu',
			'lobby.join.scan.back' => 'Atrás',
			'lobby.join.scan.torch' => 'Linterna',
			'lobby.join.scan.hint' => 'Apunta al QR que muestra el anfitrión en su teléfono.',
			'lobby.join.scan.invalid' => 'Este QR no es una invitación de Frecu.',
			'lobby.join.scan.found' => 'Frecu encontrada',
			'lobby.join.scan.noNote' => 'Frecu sin nota',
			'lobby.join.scan.join' => 'Unirme',
			'lobby.join.scan.another' => 'Escanear otro QR',
			'lobby.join.scan.camera.deniedTitle' => 'Frecu no tiene acceso a la cámara.',
			'lobby.join.scan.camera.deniedMessage' => 'Permítela en Ajustes para escanear la invitación, o conéctate por IP.',
			'lobby.join.scan.camera.unavailableTitle' => 'La cámara no está disponible.',
			'lobby.join.scan.camera.unavailableMessage' => 'Puedes unirte con la IP del anfitrión.',
			'lobby.join.scan.camera.openSettings' => 'Abrir ajustes',
			'lobby.settings' => 'Ajustes',
			'lobby.heading' => 'Elige tu frecu',
			'lobby.createRoom' => 'Crear frecu',
			'lobby.scanQr' => 'Escanear',
			'lobby.joinRoom' => 'Conectar por IP',
			'lobby.nearbyRooms' => 'Frecus cercanas',
			'lobby.accessCode' => 'Código de acceso',
			'lobby.unnamedRoom' => 'Frecu sin nombre',
			'lobby.network.checking' => 'Buscando red',
			'lobby.network.connected' => ({required Object ip}) => 'Red · ${ip}',
			'lobby.network.offline' => 'Sin red local',
			'lobby.tuner.scanning' => 'Escaneando · _frecu._tcp',
			'lobby.tuner.paused' => 'Búsqueda en pausa',
			'lobby.tuner.signals' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '${n} señal', other: '${n} señales', ), 
			'lobby.empty.title' => 'Sin señales por ahora',
			'lobby.empty.message' => 'Conéctate a la Wi-Fi del anfitrión o pídele que te muestre su QR.',
			'lobby.empty.searching' => 'La búsqueda sigue activa',
			'lobby.empty.failed' => 'La búsqueda falló · reintentando',
			'lobby.offline.title' => 'No estás en ninguna red Wi-Fi.',
			'lobby.offline.message' => 'Únete al punto de acceso del anfitrión para encontrar frecus.',
			'lobby.offline.openSettings' => 'Abrir ajustes de Wi-Fi',
			'lobby.newRoom.back' => 'Atrás',
			'lobby.newRoom.step' => ({required Object current, required Object total}) => 'Paso ${current} de ${total}',
			'lobby.newRoom.guide.title' => 'Prepara la red',
			'lobby.newRoom.guide.heading' => 'Activa tu punto de acceso',
			'lobby.newRoom.guide.message' => 'Tu teléfono será la antena del grupo.',
			'lobby.newRoom.guide.android' => 'Android',
			'lobby.newRoom.guide.iphone' => 'iPhone',
			'lobby.newRoom.guide.androidSteps.0.lead' => 'Abre Ajustes › Zona Wi-Fi',
			'lobby.newRoom.guide.androidSteps.0.rest' => ' (el nombre cambia según la marca).',
			'lobby.newRoom.guide.androidSteps.1.lead' => 'Actívala',
			'lobby.newRoom.guide.androidSteps.1.rest' => ' y comparte el nombre y la contraseña con tu grupo.',
			'lobby.newRoom.guide.androidSteps.2.lead' => 'Vuelve a Frecu',
			'lobby.newRoom.guide.androidSteps.2.rest' => ' y abre tu frecu. No usa tus datos móviles.',
			'lobby.newRoom.guide.iphoneSteps.0.lead' => 'Abre Ajustes › Punto de acceso personal',
			'lobby.newRoom.guide.iphoneSteps.0.rest' => ' y activa «Permitir a otros conectarse».',
			'lobby.newRoom.guide.iphoneSteps.1.lead' => 'Comparte la contraseña',
			'lobby.newRoom.guide.iphoneSteps.1.rest' => ' con tu grupo y que se unan a tu red.',
			'lobby.newRoom.guide.iphoneSteps.2.lead' => 'Mantén Frecu abierta',
			'lobby.newRoom.guide.iphoneSteps.2.rest' => ' mientras se unen. En iPhone recomendamos que el anfitrión use Android.',
			'lobby.newRoom.guide.ready' => 'Ya está activo',
			'lobby.newRoom.guide.sameWifi' => 'Ya estamos en la misma Wi-Fi',
			'lobby.newRoom.guide.openSettings' => 'Abrir ajustes de zona Wi-Fi',
			'lobby.newRoom.guide.openSettingsIphone' => 'Abrir Ajustes',
			'lobby.newRoom.title' => 'Nueva frecu',
			'lobby.newRoom.soundsIn' => 'Tu frecu suena en',
			'lobby.newRoom.openedAt' => ({required Object time}) => 'Abierta a las ${time}',
			'lobby.newRoom.name' => 'Nombre de la frecu',
			'lobby.newRoom.nameHint' => 'Ej. Ruta del domingo',
			'lobby.newRoom.defaultName' => ({required Object name}) => 'Frecu de ${name}',
			'lobby.newRoom.untitled' => 'Mi frecu',
			'lobby.newRoom.code' => 'Código de acceso',
			'lobby.newRoom.codeDigits' => '4 dígitos',
			'lobby.newRoom.regenerate' => 'Generar otro',
			'lobby.newRoom.codeHelp' => 'Compártelo solo con tu grupo: evita que se unan desconocidos de la misma red.',
			'lobby.newRoom.open' => 'Abrir frecu',
			'lobby.newRoom.clockLabel' => ({required Object time, required Object note}) => 'Reloj de quintas: ${time}, ${note}',
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
			'room.reconnecting' => 'Reconectando...',
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
			'room.mesh.weak' => 'Señal débil',
			'room.mesh.free' => 'Libre',
			'room.mesh.invite' => 'Invitar',
			'room.header.youAreHost' => 'Eres el anfitrión',
			'room.header.hostedBy' => ({required Object name}) => 'Anfitrión · ${name}',
			'room.header.hz' => ({required Object value}) => '${value} Hz',
			'room.header.note' => ({required Object note, required Object hz}) => 'Nota ${note}, ${hz} Hz',
			'room.header.invite' => 'Invitar',
			'room.sheets.close' => 'Cerrar',
			'room.sheets.invite.kicker' => 'Invitar a la frecu',
			'room.sheets.invite.title' => 'Escanea para unirte',
			'room.sheets.invite.message' => 'Desde Frecu › Escanear. El QR ya incluye el código.',
			'room.sheets.invite.note' => 'Nota',
			'room.sheets.invite.code' => 'Código',
			'room.sheets.invite.host' => 'Anfitrión',
			'room.sheets.invite.port' => ({required Object port}) => 'Puerto ${port}',
			'room.sheets.invite.footer' => ({required Object list}) => 'También aparece en “${list}” para quien esté en tu red.',
			'room.sheets.invite.qr' => 'Código QR de invitación',
			'room.sheets.route.kicker' => 'Salida de audio',
			'room.sheets.route.title' => '¿Dónde escuchas?',
			'room.sheets.route.message' => 'Al conectar audífonos, el audio cambia solo.',
			'room.sheets.route.speakerSub' => 'Manos libres',
			'room.sheets.route.earpieceSub' => 'Teléfono en la oreja',
			'room.sheets.route.bluetoothOn' => 'Conectado',
			'room.sheets.route.bluetoothOff' => 'Sin dispositivo',
			'room.sheets.route.bluetoothDevice' => 'Bluetooth · conectado',
			'room.sheets.route.label' => ({required Object route}) => 'Salida de audio: ${route}',
			'room.sheets.leave.peerTitle' => '¿Salir de la frecu?',
			'room.sheets.leave.peerMessage' => 'Podrás volver a unirte con el código de acceso.',
			'room.sheets.leave.peerConfirm' => 'Salir de la frecu',
			'room.sheets.leave.hostTitle' => 'Cerrar la frecu para todos',
			'room.sheets.leave.hostAlone' => 'Eres el anfitrión. Si sales, la frecu se cierra.',
			'room.sheets.leave.hostOne' => 'Eres el anfitrión. Si sales, la frecu se cierra para la otra persona.',
			'room.sheets.leave.hostMany' => ({required Object count}) => 'Eres el anfitrión. Si sales, la frecu se cierra para las otras ${count} personas.',
			'room.sheets.leave.hostConfirm' => 'Cerrar frecu',
			'room.sheets.leave.cancel' => 'Cancelar',
			'room.closure.offAir' => 'Fuera del aire',
			'room.closure.noteOffAir' => ({required Object note}) => '${note} · fuera del aire',
			'room.closure.title' => 'Fin de la transmisión',
			'room.closure.host' => 'Cerraste la frecu. Todos los participantes fueron desconectados.',
			'room.closure.peer' => 'El anfitrión cerró la frecu. Puedes unirte a otra cuando quieras.',
			'room.closure.lost' => 'Se perdió la señal del anfitrión. Puedes unirte a otra cuando quieras.',
			'room.closure.duration' => 'Duración',
			'room.closure.people' => 'Personas',
			'room.closure.note' => 'Nota',
			'room.closure.home' => 'Volver al inicio',
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
			'room.talk.island.reconnectingIn' => ({required Object seconds}) => 'Reconectando · ${seconds} s',
			'room.talk.island.joined' => ({required Object name}) => '${name} se unió',
			'room.talk.island.left' => ({required Object name}) => '${name} salió',
			'room.talk.island.route' => ({required Object route}) => 'Audio por ${route}',
			'room.talk.island.recovered' => 'Conexión recuperada',
			'room.talk.island.weak' => ({required Object name}) => '${name} · señal débil',
			'room.talk.echo.title' => 'Micrófono abierto con altavoz.',
			'room.talk.echo.message' => 'Usa audífonos para evitar eco.',
			'room.talk.echo.dismiss' => 'Cerrar aviso',
			'room.talk.mic.title' => 'Tu micrófono no está disponible.',
			'room.talk.mic.message' => 'Escuchas a tu grupo, pero nadie te oye. Revisa el permiso en Ajustes.',
			'room.talk.mic.settings' => 'Abrir ajustes',
			'room.talk.mic.dismiss' => 'Cerrar aviso',
			'room.notification.channelName' => 'Frecu en segundo plano',
			'room.notification.channelDescription' => 'Mantiene activa la conexión de Frecu con la pantalla apagada.',
			'room.notification.title' => 'Frecu activa',
			'room.notification.connected' => ({required Object room}) => '${room} · Conectado',
			'room.notification.reconnecting' => ({required Object room}) => '${room} · Reconectando…',
			'room.notification.leave' => 'Salir de la frecu',
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
			'settings.general' => 'General',
			'settings.language.title' => 'Idioma',
			'settings.language.message' => 'Auto usa el idioma del teléfono.',
			'settings.language.auto' => 'Auto',
			'settings.language.autoHelp' => 'Sigue al teléfono',
			'settings.language.autoValue' => ({required Object language}) => 'Auto · ${language}',
			'settings.language.es' => 'Español',
			'settings.language.en' => 'English',
			'settings.permissions.title' => 'Permisos',
			'settings.permissions.subtitle' => 'Micrófono, red local, notificaciones',
			'settings.permissions.count' => ({required Object granted, required Object total}) => '${granted}/${total}',
			'settings.hotspotGuide' => 'Guía del punto de acceso',
			'settings.vibration.title' => 'Vibración',
			'settings.vibration.subtitle' => 'Al transmitir, cuando alguien empieza a hablar y si se pierde la conexión.',
			'settings.licenses' => 'Licencias',
			'settings.appearance' => 'Apariencia',
			'settings.theme' => 'Tema',
			'settings.themeHelp' => 'Auto sigue al teléfono',
			'settings.themeMode.auto' => 'Auto',
			'settings.themeMode.light' => 'Claro',
			'settings.themeMode.dark' => 'Oscuro',
			'settings.saveError' => 'No se pudo guardar',
			'settings.footer' => ({required Object app}) => '${app} · 100% local · sin internet',
			'settings.appVersion' => ({required Object version}) => 'Frecu ${version}',
			'errors.network' => 'Error de red local',
			'errors.permissionDenied' => 'Permiso denegado',
			'errors.roomFull' => 'La frecu está llena (máximo 6 participantes)',
			'errors.invalidAccessCode' => 'Código de acceso inválido',
			'errors.hostUnreachable' => 'El anfitrión no responde',
			'errors.versionMismatch' => 'Esta frecu usa otra versión de Frecu',
			'errors.audio' => 'Error en el subsistema de audio',
			'errors.unexpected' => 'Error inesperado',
			'splash.title' => 'frecu',
			'splash.tagline' => 'Voz de grupo. Sin internet.',
			'splash.version' => ({required Object version}) => 'v${version}',
			'splash.localNetwork' => 'Red local',
			'splash.mesh' => 'Malla P2P',
			'splash.skip' => 'Toca para entrar',
			'messages.button' => 'Mensajes',
			'messages.kicker' => 'Para toda la frecu',
			'messages.title' => 'Mensajes rápidos',
			'messages.message' => 'Llegan al instante y vibran, aunque tengan la pantalla apagada.',
			'messages.kinds.behind' => 'Me quedé atrás',
			'messages.kinds.stop' => 'Parada en la próxima',
			'messages.kinds.fuel' => 'Necesito combustible',
			'messages.kinds.ok' => 'Todo bien',
			'messages.kinds.onMyWay' => 'Voy en camino',
			'messages.kinds.sos' => 'SOS',
			'messages.sosHold' => 'Mantén para enviar SOS',
			'messages.sosHoldHelp' => 'Alarma para todos hasta que alguien la atienda',
			'messages.sent' => ({required Object text}) => 'Enviado · ${text}',
			'messages.sosSent' => 'SOS enviado a tu grupo',
			'messages.received' => ({required Object name, required Object text}) => '${name} · ${text}',
			'messages.sendError' => 'No se pudo enviar: sin conexión con el anfitrión',
			'messages.sos.kicker' => 'SOS',
			'messages.sos.title' => ({required Object name}) => '${name} necesita ayuda',
			'messages.sos.body' => 'Avisa al grupo si vas hacia allá. La alarma sigue hasta que la atiendas.',
			'messages.sos.onMyWay' => 'Voy en camino',
			'messages.sos.dismiss' => 'Entendido',
			_ => null,
		};
	}
}
