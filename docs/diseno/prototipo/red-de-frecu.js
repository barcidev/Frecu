/* ==========================================================================
   Frecu · La red la crea Frecu (LocalOnlyHotspot) — prototipo
   Página aparte: reutiliza engine.js, components.js y screens.js sin tocarlos.
   ========================================================================== */

const NET = { ssid: 'AndroidShare_4821', key: 'a3f91c7e5b2d', ip: '192.168.62.1' };
const closeBtn = UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' });
const ghost = (label) => `<button class="btn btn-ghost"><span class="lbl">${label}</span></button>`;
const under = (html, cls) => html.replace(`class="view ${cls}`, `class="view ${cls} under`);
const padded = (html) => `<div class="pad" style="margin-top:20px">${html}</div>`;

/* ---------- Anfitrión Android: paso 1 ---------- */
const netCard = () => `<div class="nfc-box rf-net"><span class="oic">${I('hotspot')}</span>
  <span class="ot"><span class="t-label-s cs">Red de la frecu</span><b class="t-data">${NET.ssid}</b><span class="t-body-s">La clave viaja en el QR</span></span>${UI.pill('Al aire', 'ok')}</div>`;

const HOST = {
  idle: {
    body: () => `<ol class="stepsl pad" style="margin-top:10px">
      <li><span><b>Toca «Crear la red».</b> La primera vez, Android te pide el permiso de dispositivos cercanos.</span></li>
      <li><span><b>Abre tu frecu y muestra el QR.</b> Ya lleva la red y su clave: tu grupo entra con un solo escaneo.</span></li>
      <li><span><b>Al cerrar la frecu, la red se apaga.</b> La próxima tendrá otro nombre y otra clave.</span></li></ol>`,
    dock: () => UI.btn('Crear la red', { icon: 'hotspot' }) + ghost('Prefiero mi zona Wi-Fi'),
  },
  creating: {
    body: () => padded(`<div class="wifi-step"><canvas class="wave-loader" data-c="wave" style="width:46px;height:20px"></canvas><span><b>Creando la red…</b><span class="t-body-s c3">Tarda unos segundos.</span></span></div>`),
    dock: () => UI.btn('Creando la red…', { cls: 'rf-wait' }) + ghost('Cancelar'),
  },
  ready: {
    head: ['Tu red está al aire', 'Ahora ponle nombre y código a tu frecu.'],
    body: () => padded(netCard()),
    dock: () => UI.btn('Seguir', { iconR: 'arrow' }),
  },
  busy: {
    body: () => padded(UI.banner('warn', 'hotspot', '<b>Tu zona Wi-Fi está encendida.</b> Android no deja crear otra red a la vez. Apágala y reintenta, o sigue con ella: tu grupo se une a tu zona Wi-Fi como hoy.<br><span class="act">Abrir ajustes de la zona Wi-Fi</span>', { close: false })),
    dock: () => UI.btn('Reintentar', { icon: 'regen' }) + ghost('Seguir con mi zona Wi-Fi'),
  },
  denied: {
    body: () => padded(UI.banner('alert', 'lock', '<b>Falta el permiso de dispositivos cercanos.</b> Android lo exige para crear la red.<br><span class="act">Abrir ajustes de Frecu</span>', { close: false })),
    dock: () => UI.btn('Reintentar', { icon: 'regen' }) + ghost('Prefiero mi zona Wi-Fi'),
  },
  failed: {
    body: () => padded(UI.banner('alert', 'alert', '<b>No se pudo crear la red.</b> Reintenta en unos segundos o usa tu zona Wi-Fi.', { close: false })),
    dock: () => UI.btn('Reintentar', { icon: 'regen' }) + ghost('Prefiero mi zona Wi-Fi'),
  },
};

function hostNet(state = 'idle') {
  const s = HOST[state];
  const [title, message] = s.head || ['Frecu crea la red', 'Tu teléfono será la antena del grupo. Sin internet y sin gastar tus datos.'];
  return `<section class="view v-hotspot" data-screen="hotspot">
    <div class="appbar">${back}<span class="ttl"><span class="t-label-s c3">Paso 1 de 2</span><b>Prepara la red</b></span>${spacer}</div>
    <div class="hs-ill"><canvas data-c="hotspot"></canvas></div>
    <div class="pad"><h1 class="h-screen" style="font-size:26px;line-height:30px">${title}</h1><p class="p-screen" style="margin-top:8px">${message}</p></div>
    ${s.body()}
    <div class="dock">${s.dock()}</div></section>`;
}

/* ---------- Frecu abierta (anfitrión) ---------- */
const inviteNet = () => `<div class="sheet" data-sheet-el="invite"><span class="grab"></span>
  <div class="sh-h"><div><span class="t-label-s c3">Invitar a la frecu</span><h3 style="margin-top:8px">Escanea para unirte</h3><p>Desde Frecu › Escanear. El QR ya lleva la red, su clave y el código.</p></div>${closeBtn}</div>
  <div class="qr-frame"><canvas data-c="qr" data-seed="91"></canvas></div>
  <div class="inv-meta"><div><span class="t-label-s c3">Nota</span>${UI.note(ROOM.note)}</div><div><span class="t-label-s c3">Código</span><b class="t-dot">${ROOM.pin}</b></div><div><span class="t-label-s c3">Anfitrión</span><span class="t-data">${NET.ip}</span><span class="t-label-s c3">Puerto ${ROOM.port}</span></div></div>
  <div class="nfc-box"><span class="oic">${I('hotspot')}</span><span class="ot"><b class="t-data">${NET.ssid}</b><span class="t-body-s">Clave <span class="t-data c2">${NET.key}</span></span></span><span class="t-label-s c3">A mano</span></div></div>`;

const roomNetDown = () => roomView('alone')
  .replace(isleFor('alone', 1), UI.isle('warn', '<i class="dot"></i><span class="t-label" style="color:var(--warn)">Red apagada</span>'))
  .replace('<div class="ctrls">', `<div class="echo" style="top:186px;z-index:30">${UI.banner('alert', 'hotspot', '<b>La red de la frecu se apagó.</b> Tu grupo se desconectó. Créala de nuevo y vuelve a mostrar el QR.<br><span class="act">Crear la red de nuevo</span>', { close: false })}</div><div class="ctrls">`);

/* ---------- Invitado ---------- */
const scanNet = () => V.scan({ lock: true }).replace(
  `${noteTxt(ROOM.note)} · ${ROOM.ip}</span>`,
  `${noteTxt(ROOM.note)} · ${NET.ip}</span><span class="t-body-s c3 rf-netline">${I('hotspot', 's16')}Red <span class="t-data">${NET.ssid}</span></span>`,
);

const retry = () => UI.btn('Reintentar', { icon: 'regen' }) + ghost('Conectarme a mano');
const JOIN = {
  connecting: {
    p: 'Primero conectamos tu teléfono a la red de la frecu.',
    body: () => `<div class="wifi-step"><canvas class="wave-loader" data-c="wave" style="width:46px;height:20px"></canvas><span><b>Conectando a la Wi-Fi «${NET.ssid}»…</b><span class="t-body-s c3">Tu teléfono te pedirá confirmar la red.</span></span></div>
      <p class="t-label-s c3" style="text-align:center">Entrarás como <span class="c1">${ME}</span></p>`,
  },
  declined: {
    p: 'Para entrar a esta frecu, tu teléfono tiene que estar en su red.',
    body: () => UI.banner('warn', 'wifi', '<b>No te conectaste a la red.</b> Se canceló el aviso del sistema.', { close: false }) + retry(),
  },
  missing: {
    p: 'Para entrar a esta frecu, tu teléfono tiene que estar en su red.',
    body: () => UI.banner('alert', 'wifi', `<b>No encontramos la red «${NET.ssid}».</b> Acércate al anfitrión y revisa que la frecu siga abierta.`, { close: false }) + retry(),
  },
  manual: {
    p: 'Abre Ajustes › Wi-Fi, elige esta red y escribe la clave. Luego vuelve a Frecu.',
    body: () => `${UI.field('Red', NET.ssid, { mono: true, icon: 'wifi' })}${UI.field('Clave', NET.key, { mono: true, icon: 'lock', right: 'Copiar' })}
      <div class="rf-two">${UI.btn('Abrir Wi-Fi', { v: 'secondary', icon: 'wifi' })}${UI.btn('Ya me conecté', { iconR: 'arrow' })}</div>`,
  },
};

function joinSheet(kind = 'connecting') {
  const j = JOIN[kind];
  return `<div class="sheet" data-sheet-el="wifijoin"><span class="grab"></span>
    <div class="sh-h"><div><span class="t-label-s c3">${noteTxt(ROOM.note)} · ${fmtHz(ROOM.note.hz)} Hz · ${NET.ip}</span><h3 style="margin-top:8px">${ROOM.name}</h3><p>${j.p}</p></div>${closeBtn}</div>
    ${j.body()}</div>`;
}

const sysAlert = () => `<div class="rf-sys"><span class="t-label-s rf-tag">Aviso del sistema · iPhone</span>
  <div class="rf-alert"><b>«Frecu» quiere conectarse a la red Wi-Fi «${NET.ssid}»</b><div class="rf-alert-b"><button>Cancelar</button><button>Conectarse</button></div></div></div>`;

const scanUnder = () => under(scanNet(), 'v-scan') + scrim;

/* ---------- Galería ---------- */
const RF_GALLERY = [
  { flow: 'Anfitrión Android · la red la crea Frecu', items: [
    { title: 'Prepara la red', route: 'CreateRoomRoute · paso 1 · Android', desc: '«Crear la red» va primero. La guía de la zona Wi-Fi queda detrás de «Prefiero mi zona Wi-Fi».', html: () => hostNet('idle') },
    { title: 'Creando la red', route: 'startLocalOnlyHotspot', desc: 'Después del permiso, unos segundos de espera. Atrás o Cancelar la apagan.', html: () => hostNet('creating') },
    { title: 'Red al aire', route: 'LocalOnlyHotspotReservation', desc: 'Se ve el nombre. La clave no hace falta aquí: viaja en el QR de la frecu.', html: () => hostNet('ready') },
    { title: 'Zona Wi-Fi encendida', route: 'ERROR_INCOMPATIBLE_MODE', desc: 'Android no deja las dos redes a la vez. Se puede seguir con la zona Wi-Fi de siempre.', html: () => hostNet('busy') },
    { title: 'Sin permiso', route: 'NEARBY_WIFI_DEVICES negado', desc: 'En Android 12 o anterior el permiso es el de ubicación, y la ubicación tiene que estar encendida.', html: () => hostNet('denied') },
    { title: 'No se pudo crear', route: 'ERROR_GENERIC · ERROR_NO_CHANNEL', desc: 'Cualquier otro fallo: reintentar o volver a la guía.', html: () => hostNet('failed') },
    { title: 'Prefiero mi zona Wi-Fi', route: 'Guía de hotspot · sin cambios', desc: 'La guía de hoy, para compartir internet, en Android 7 o si la red de Frecu falla.', html: () => V.hotspot() },
    { title: 'Anfitrión iPhone', route: 'Guía de hotspot · iPhone', desc: 'iOS no deja que una app cree la red: sigue con el punto de acceso personal.', html: () => V.hotspot({ os: 'ios' }) },
  ] },
  { flow: 'Frecu abierta · anfitrión', items: [
    { title: 'Invitar', route: 'Hoja · InviteSheet', desc: 'El mismo QR, ahora con la red y su clave. Debajo, la red por si alguien se une a mano.', html: () => under(roomView('alone'), 'v-room') + scrim + inviteNet() },
    { title: 'La red se apagó', route: 'LocalOnlyHotspotCallback.onStopped', desc: 'Si Android la apaga (zona Wi-Fi, modo avión), el anfitrión la crea de nuevo y muestra el QR nuevo.', html: () => roomNetDown() },
  ] },
  { flow: 'Invitado · un solo QR', items: [
    { title: 'QR detectado', route: 'ScanQrRoute · bloqueo', desc: 'La tarjeta dice a qué red se va a conectar el teléfono.', html: () => scanNet() },
    { title: 'Conectando a la red', route: 'WifiNetworkSpecifier · NEHotspotConfiguration', desc: 'Antes de unirse, Frecu conecta el teléfono a la red de la frecu.', html: () => scanUnder() + joinSheet('connecting') },
    { title: 'Aviso del sistema', route: 'iOS · Android', desc: 'Lo dibuja el sistema. En Android es su propio diálogo para elegir la red.', html: () => scanUnder() + joinSheet('connecting') + sysAlert() },
    { title: 'Aviso cancelado', route: 'El invitado dijo que no', desc: 'Sin la red no hay frecu: reintentar o conectarse a mano.', html: () => scanUnder() + joinSheet('declined') },
    { title: 'Red fuera de alcance', route: 'Red no encontrada', desc: 'El anfitrión está lejos o ya cerró la frecu.', html: () => scanUnder() + joinSheet('missing') },
    { title: 'Conectarse a mano', route: 'Respaldo · Android 7 a 9', desc: 'Nombre y clave para escribirlos en Ajustes › Wi-Fi. También si el teléfono no puede conectarse solo.', html: () => scanUnder() + joinSheet('manual') },
  ] },
];

function buildRF() {
  const root = document.getElementById('gallery');
  root.innerHTML = RF_GALLERY.map((f) => `<div class="flow-label"><b>${f.flow}</b><span>${f.items.length} pantallas</span><i></i></div>
    <div class="gal">${f.items.map((it) => `<div class="gitem"><div class="scaler">${phone(it.html())}</div><div class="cap"><em>${it.route}</em><b>${it.title}</b><span>${it.desc}</span></div></div>`).join('')}</div>`).join('');
  document.querySelectorAll('[data-theme-set]').forEach((b) => b.addEventListener('click', () => {
    document.documentElement.dataset.theme = b.dataset.themeSet;
    document.querySelectorAll('[data-theme-set]').forEach((x) => x.classList.toggle('on', x === b));
  }));
}

function bootRF() {
  document.documentElement.dataset.theme = document.documentElement.dataset.theme || 'dark';
  installSprings(); Theme.refresh();
  buildRF();
  hydrate(document);
  if (document.fonts) document.fonts.ready.then(() => document.querySelectorAll('.seg').forEach((s) => placeSeg(s)));
}
document.readyState === 'loading' ? document.addEventListener('DOMContentLoaded', bootRF) : bootRF();
