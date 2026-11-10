/* ==========================================================================
   FRECU · Portadora — Pantallas (cada una = una @RoutePage u hoja modal)
   ========================================================================== */
'use strict';

const ME = 'Jorge';
// La nota de cada frecu sale de la hora en que se abrió (círculo de quintas).
const ROOM = { name: 'Ruta del domingo', note: noteAt(16, 24), opened: '16:24', ip: '192.168.43.1', port: 47800, pin: '4827' };
const NEARBY = [
  { name: 'Ruta del domingo', note: ROOM.note, ip: '192.168.43.1' },
  { name: 'Brigada Norte', note: noteAt(15, 5), ip: '192.168.43.87' },
];
const BLE_ROOM = { name: 'Caravana Sur', note: noteAt(9, 40), ble: true, ssid: 'Moto de Andrés' };
const noteTxt = (n) => `${n.name}${n.oct}`;

const SBAR = `<div class="sbar"><b>08:24</b><span class="sic">
  <svg width="17" height="11" viewBox="0 0 17 11"><rect x="0" y="7" width="3" height="4" rx="1" fill="currentColor"/><rect x="4.5" y="5" width="3" height="6" rx="1" fill="currentColor"/><rect x="9" y="2.5" width="3" height="8.5" rx="1" fill="currentColor"/><rect x="13.5" y="0" width="3" height="11" rx="1" fill="currentColor" opacity=".3"/></svg>
  <svg width="15" height="11" viewBox="0 0 15 11"><path d="M7.5 10.6L.7 3.7a9.7 9.7 0 0 1 13.6 0z" fill="currentColor"/></svg>
  <svg width="26" height="12" viewBox="0 0 26 12"><rect x=".5" y=".5" width="22" height="11" rx="3.5" fill="none" stroke="currentColor" opacity=".45"/><rect x="2" y="2" width="15" height="8" rx="2" fill="currentColor"/><rect x="23.5" y="4" width="1.8" height="4" rx=".9" fill="currentColor" opacity=".45"/></svg>
</span></div>`;

function phone(inner, o = {}) {
  return `<div class="phone" ${o.attrs || ''}><div class="screen">${SBAR}${o.stage ? `<div class="stage">${inner}</div>` : inner}<div class="home-ind"></div></div><div class="cam"></div></div>`;
}
const spacer = '<span style="width:48px;flex:none"></span>';
const back = UI.ibtn('back', { cls: 'ghost', attrs: 'data-back', label: 'Atrás' });

/* ---------- Participantes y malla ---------- */
function node(name, ck, o = {}) {
  return { name, ck, get color() { return Theme.c(this.ck); }, sig: sigParams(name), state: o.state || 'ok', me: !!o.me, host: !!o.host, muted: !!o.muted, levelFn: o.levelFn || null, dist: o.dist || null, dir: o.dir ?? 0, behind: !!o.behind };
}
/* Distancia y rumbo de cada persona cuando comparte su ubicación (V1). */
const GEO = { 'Andrés': ['45 m', -10], Ana: ['120 m', 20], Leo: ['210 m', 160], Sofi: ['90 m', 75], Marta: ['60 m', 110] };
function applyGeo(ms, o = {}) {
  ms.nodes.forEach((n) => { if (n && !n.me && GEO[n.name]) [n.dist, n.dir] = GEO[n.name]; });
  if (o.behind) { const s = ms.nodes.find((n) => n && n.name === 'Sofi'); if (s) { s.dist = '850 m'; s.dir = 190; s.behind = true; s.state = 'weak'; } }
  return ms;
}
const arrow = (deg) => `<svg class="dir" viewBox="0 0 24 24" style="transform:rotate(${deg}deg)" aria-hidden="true">${ICONS.dir}</svg>`;
const GEO_KINDS = ['geo', 'behind', 'msg', 'sos'];
function meshFor(kind) {
  const me = node(ME, 'signal', { me: true });
  const andres = node('Andrés', 'p1', { host: true });
  const ana = node('Ana', 'p2'), leo = node('Leo', 'p3'), sofi = node('Sofi', 'p4');
  let nodes = [me, ana, sofi, andres, null, leo]; let status = 'ok';
  if (kind === 'rx') ana.levelFn = (t) => voice(t, 2);
  if (kind === 'tx') me.levelFn = (t) => voice(t, 5);
  if (kind === 'open') me.levelFn = (t) => voice(t, 5) * .7;
  if (kind === 'rec') { status = 'rec'; leo.state = 'rec'; }
  if (kind === 'connecting') { me.state = 'link'; andres.state = 'link'; nodes = [me, null, null, andres, null, null]; }
  if (kind === 'alone') { me.host = true; nodes = [me, null, null, null, null, null]; }
  if (kind === 'weak') leo.state = 'weak';
  const ms = { nodes, status };
  if (GEO_KINDS.includes(kind)) applyGeo(ms, { behind: kind === 'behind' });
  return ms;
}
function meshLabels(ms) {
  const slots = meshSlots(390, 304);
  return slots.map((s, i) => {
    const n = ms.nodes[i];
    if (!n) return `<span class="nl free" style="left:${s.x}px;top:${s.y + 30}px"><b class="t-label-s">Libre</b></span><button class="slot-hit" data-sheet="invite" style="left:${s.x}px;top:${s.y}px" aria-label="Invitar"></button>`;
    let sub = n.me && n.host ? 'Tú · anfitrión' : n.me ? 'Tú' : n.host ? 'Anfitrión' : '';
    let cls = '';
    if (n.dist && !n.host) sub = `${n.dist} ${arrow(n.dir)}`;
    if (n.dist && n.host) sub = `Anfitrión · ${n.dist} ${arrow(n.dir)}`;
    if (n.levelFn) { cls = 'speak'; sub = n.me ? 'Al aire' : 'Hablando'; }
    if (n.state === 'weak') { cls = 'weak'; sub = n.dist ? `Señal débil · ${n.dist}` : 'Señal débil'; }
    if (n.behind) { cls = 'weak'; sub = `Atrás · ${n.dist} ${arrow(n.dir)}`; }
    if (n.state === 'rec' || ms.status === 'rec') { cls = 'rec'; sub = 'Reconectando'; }
    if (n.muted) sub = 'Silenciado';
    if (n.state === 'link') sub = 'Conectando';
    return `<span class="nl ${cls}" data-slot="${i}" style="left:${s.x}px;top:${s.y + 33}px;--nc:var(--${n.ck === 'signal' ? 'signal-fg' : n.ck})"><b>${n.name}</b><span class="t-label-s">${sub}</span></span>`;
  }).join('');
}

function isleFor(kind, count) {
  if (kind === 'rx') return UI.isle('', `${UI.sig('Ana', { size: 24, color: 'p2', mode: 'speak', level: 'voice' })}<span class="t-label" style="color:var(--p2)">Ana · hablando</span>`);
  if (kind === 'tx') return UI.isle('tx', `<i class="dot"></i><span class="t-label">Al aire · <span data-timer>00:04</span></span>`);
  if (kind === 'open') return UI.isle('', `<i class="dot"></i><span class="t-label">Micrófono abierto · ${count}/6</span>`);
  if (kind === 'rec') return UI.isle('warn', `<i class="dot"></i><span class="t-label" style="color:var(--warn)">Reconectando · 4 s</span>`);
  if (kind === 'connecting') return UI.isle('', `<canvas class="wave-loader" style="width:34px;height:16px" data-c="wave"></canvas><span class="t-label">Conectando…</span>`);
  if (kind === 'alone') return UI.isle('', `<i class="dot"></i><span class="t-label">Al aire · esperando a tu grupo</span>`);
  if (kind === 'weak') return UI.isle('warn', ISLE_V1.weak);
  if (kind === 'behind') return UI.isle('warn', ISLE_V1.behind);
  if (kind === 'msg') return UI.isle('', ISLE_V1.msg);
  if (kind === 'sos') return UI.isle('alert', ISLE_V1.sos);
  return UI.isle('', `<i class="dot"></i><span class="t-label">En línea · ${count}/6</span>`);
}

/* Contenido de la isla para los eventos nuevos de V1. */
const ISLE_V1 = {
  weak: `<i class="dot"></i><span class="t-label" style="color:var(--warn)">Leo · señal débil</span>`,
  behind: `<span style="color:var(--warn);display:flex">${I('pin', 's16')}</span><span class="t-label" style="color:var(--warn)">Sofi se quedó atrás</span>`,
  msg: `${UI.sig('Ana', { size: 24, color: 'p2' })}<span class="t-label"><span style="color:var(--p2)">Ana</span> · Parada en la próxima</span>`,
  sos: `<i class="dot"></i><span class="t-label">SOS de Ana · 120 m</span>`,
  sent: (txt) => `<span style="color:var(--signal-fg);display:flex">${I('check', 's16')}</span><span class="t-label">Enviado · ${txt}</span>`,
  sosSent: `<i class="dot"></i><span class="t-label">SOS enviado a tu grupo</span>`,
};
const QUICK = [['back', 'Me quedé atrás'], ['flag', 'Parada en la próxima'], ['fuel', 'Necesito combustible'], ['check', 'Todo bien']];
const sosOverlay = () => `<div class="sos-ov" data-theme="dark"><div class="sos-in">
    <span class="sos-ring">${I('sos', 's34')}</span>
    <span class="t-label sos-k">SOS · hace 5 s</span>
    <h2>Ana necesita ayuda</h2>
    <p>Está a <b>120 m ${arrow(20)}</b> hacia el noreste. Su ubicación se actualiza mientras dure el aviso.</p>
    <div class="sos-acts">${UI.btn('Voy en camino', { icon: 'check', attrs: 'data-ack="go"' })}${UI.btn('Entendido', { v: 'secondary', attrs: 'data-ack' })}</div>
  </div></div>`;

const PTT_COPY = {
  idle: ['mic', 'Mantén', 'Mantén para hablar · o usa el botón de volumen'],
  rx: ['mic', 'Mantén', 'Ana está hablando · puedes responder'],
  tx: ['mic', 'Al aire', 'Suelta para escuchar'],
  open: ['openMic', 'Abierto', 'Toca para silenciarte'],
  muted: ['micOff', 'Silencio', 'Toca para activar tu micrófono'],
  rec: ['mic', 'En espera', 'Recuperando la conexión…'],
  connecting: ['mic', 'En espera', 'Conectando con el anfitrión…'],
  alone: ['mic', 'Mantén', 'Muestra el QR para que tu grupo se una'],
};
function pttZone(kind, pst) {
  const [icon, label, hint] = PTT_COPY[kind] || PTT_COPY.idle;
  const cls = [pst.tx ? 'tx' : '', pst.mode === 'open' ? 'open' : '', pst.muted ? 'muted' : '', pst.dis ? 'dis' : ''].join(' ');
  return `<div class="ptt-zone"><div class="ptt ${cls}" data-ptt><canvas data-c="ptt" data-st="${st(pst)}"></canvas>
    <button class="ptt-core" aria-label="Hablar">${I(icon, 's34')}<span class="tm t-dot" data-timer>00:04</span><span class="pl t-label">${label}</span></button></div>
    <span class="ptt-hint t-label-s" data-hint>${hint}</span></div>`;
}
function pttState(kind) {
  const p = { mode: kind === 'open' || kind === 'muted' ? 'open' : 'ptt', dis: kind === 'rec' || kind === 'connecting', tx: false, muted: kind === 'muted', level: 0, rx: null };
  if (kind === 'tx') { p.tx = true; Object.defineProperty(p, 'level', { get: () => voice(Loop.t, 5) }); }
  if (kind === 'open') { p.tx = true; Object.defineProperty(p, 'level', { get: () => voice(Loop.t, 5) * .7 }); }
  if (kind === 'rx') p.rx = { get color() { return Theme.c('p2'); }, get level() { return voice(Loop.t, 2); } };
  return p;
}

function roomView(kind = 'idle', o = {}) {
  const ms = o.ms || meshFor(kind);
  const host = kind === 'alone' || o.host;
  const count = ms.nodes.filter(Boolean).length;
  const pst = o.pst || pttState(kind);
  const route = o.route || 'speaker';
  const echo = (kind === 'open' && route === 'speaker' && o.echo !== false)
    ? `<div class="echo">${UI.banner('warn', 'headset', '<b>Micrófono abierto con altavoz.</b> Usa audífonos para evitar eco.')}</div>` : '';
  const behind = kind === 'behind'
    ? `<div class="echo">${UI.banner('warn', 'pin', '<b>Sofi se quedó atrás.</b> Va a 850 m del grupo, hacia el sur.')}</div>` : '';
  const geo = GEO_KINDS.includes(kind) || o.geo ? `<div class="geo-tag">${I('pin', 's16')}<span class="t-label-s">Compartes tu ubicación</span></div>` : '';
  return `<section class="view v-room ${o.cls || ''}" data-screen="room">
    ${isleFor(kind, count)}
    <div class="room-h">
      <div class="rl"><span class="chip"><small class="t-label-s c3">${Math.round(ROOM.note.hz)} Hz</small>${UI.note(ROOM.note)}</span><span class="rn"><b>${ROOM.name}</b><span class="t-label-s">${host ? 'Eres el anfitrión' : 'Anfitrión · Andrés'}</span></span></div>
      <div class="rr">${UI.ibtn('msg', { attrs: 'data-sheet="quick"', label: 'Mensajes' })}${UI.ibtn('qr', { attrs: 'data-sheet="invite"', label: 'Invitar' })}${UI.ibtn('exit', { cls: 'danger', attrs: 'data-sheet="leave"', label: 'Salir' })}</div>
    </div>
    <div class="mesh"><canvas data-c="mesh" data-st="${st(ms)}"></canvas><div class="labels">${meshLabels(ms)}</div>${geo}</div>
    ${echo}${behind}${kind === 'sos' ? sosOverlay() : ''}
    <div class="ctrls">${UI.route(route)}${UI.seg([{ label: 'PTT', icon: 'walkie' }, { label: 'Abierto', icon: 'openMic' }], pst.mode === 'open' ? 1 : 0, { attrs: 'data-mode-seg' })}</div>
    ${pttZone(kind, pst)}
  </section>`;
}

/* ---------- Pantallas ---------- */
const V = {
  splash: () => `<section class="view v-splash" data-screen="splash"><canvas class="splash" data-c="splash"></canvas>
    <div class="mark"><b>frecu</b><span>Voz de grupo. Sin internet.</span></div>
    <div class="foot t-label-s"><span>v0.1</span><span>·</span><span>Red local</span><span>·</span><span>Malla P2P</span></div></section>`,

  welcome: () => `<section class="view v-welcome" data-screen="welcome">
    <div class="topline">${UI.steps(3, 0)}<span class="t-label-s c3">01 / 03</span></div>
    <div class="hero-c" style="height:380px"><canvas data-c="orbit" data-st="${st({ names: ['Jorge', 'Ana', 'Leo', 'Sofi', 'Andrés', 'Marta'] })}"></canvas></div>
    <div class="copy"><span class="kicker t-label"><i></i>Sin internet · sin cobertura</span>
      <h1 class="h-screen">Todo tu grupo en la misma frecu.</h1>
      <p class="p-screen">Habla en tiempo real con hasta 6 personas cerca de ti. Solo necesitan compartir una red Wi-Fi.</p></div>
    <div class="dock">${UI.btn('Empezar', { iconR: 'arrow', attrs: 'data-go="name"' })}</div></section>`,

  name: () => `<section class="view v-name" data-screen="name">
    <div class="topline" style="padding-left:10px">${UI.ibtn('back', { cls: 'ghost s40', attrs: 'data-back' })}${UI.steps(3, 1)}<span class="t-label-s c3">02 / 03</span></div>
    <div class="pad" style="margin-top:10px"><h1 class="h-screen">¿Cómo te llamamos?</h1><p class="p-screen" style="margin-top:10px">Así te verán y escucharán en cada frecu.</p></div>
    <div class="sig-stage">${UI.sig(ME, { size: 210, mode: 'speak', level: 'soft', r: .4 })}<span class="lbl t-label-s">Tu firma de señal · nace de tu nombre</span></div>
    <div class="pad">${UI.field('Nombre visible', ME, { count: '5/20', help: 'Puedes cambiarlo cuando quieras en Ajustes.', cls: 'focus', attrs: 'data-name-input maxlength="20"' })}</div>
    <div class="dock">${UI.btn('Continuar', { iconR: 'arrow', attrs: 'data-go="perms"' })}</div></section>`,

  perms: (s = {}) => {
    const g = s.granted || [];
    return `<section class="view v-perms" data-screen="perms">
    <div class="topline" style="padding-left:10px">${UI.ibtn('back', { cls: 'ghost s40', attrs: 'data-back' })}${UI.steps(3, 2)}<span class="t-label-s c3">03 / 03</span></div>
    <div class="pad" style="margin-top:10px"><h1 class="h-screen">Tres permisos y listo.</h1><p class="p-screen" style="margin-top:10px">Frecu solo habla con tu red local. Tu voz nunca sale de tu grupo.</p></div>
    <div class="pad" style="display:flex;flex-direction:column;gap:10px;margin-top:24px" data-perms>
      ${UI.perm('mic', 'Micrófono', 'Para que tu grupo te escuche.', g[0])}
      ${UI.perm('wifi', 'Red local y dispositivos cercanos', 'Para encontrar frecus y usar audífonos Bluetooth.', g[1])}
      ${UI.perm('bell', 'Notificaciones', 'Mantienen la frecu viva con la pantalla apagada.', g[2])}
    </div>
    <p class="pad t-body-s c3" style="margin-top:16px;display:flex;gap:8px;align-items:center">${I('camera', 's16')}La cámara se pedirá solo al escanear un QR.</p>
    <div class="dock">${g.length === 3 ? UI.btn('Continuar', { iconR: 'arrow', attrs: 'data-go="lobby" data-tr="wave"' }) : UI.btn('Conceder permisos', { icon: 'check', attrs: 'data-grant' })}</div></section>`;
  },

  lobby: (s = {}) => {
    const kind = s.kind || 'rooms';
    const rooms = kind === 'rooms' ? NEARBY : kind === 'ble' ? [BLE_ROOM] : [];
    const tst = { rooms: rooms.map((r, i) => ({ s: r.note.s, label: noteTxt(r.note), born: s.born ? Loop.t + .5 + i * .7 : null })), sel: s.sel ?? null };
    const pill = kind === 'nonet' || kind === 'ble' ? UI.pill('Sin red local', 'alert') : UI.pill('Red · 192.168.43.27', 'ok');
    const list = kind === 'rooms'
      ? `<div class="list">${NEARBY.map((r) => UI.rtile(r, { sel: s.sel === r.note.s, attrs: 'data-sheet="pin"' })).join('')}</div>`
      : kind === 'ble'
        ? `<div class="list">${UI.rtile(BLE_ROOM, { attrs: 'data-sheet="blepin"' })}<p class="t-body-s c3" style="margin-top:4px;display:flex;gap:8px;align-items:center">${I('info', 's16')}Aún no estás en su Wi-Fi: al poner el código te conectamos.</p></div>`
      : kind === 'empty'
        ? `<div class="empty"><canvas class="wave-loader" data-c="wave" style="width:80px;height:26px;margin-bottom:8px"></canvas><b>Sin señales por ahora</b><span>Conéctate a la Wi-Fi del anfitrión o pídele que te muestre su QR.</span><span class="t-label-s c3" style="margin-top:6px">La búsqueda sigue activa</span></div>`
        : `<div class="pad" style="margin-top:16px">${UI.banner('alert', 'wifi', '<b>No estás en ninguna red Wi-Fi.</b> Únete al punto de acceso del anfitrión para encontrar frecus.<br><span class="act">Abrir ajustes de Wi-Fi</span>', { close: false })}</div>`;
    return `<section class="view v-lobby" data-screen="lobby">
      <div class="appbar" style="padding-left:20px"><span class="wordmark"><canvas data-c="brand"></canvas>frecu</span>${pill}${UI.ibtn('sliders', { attrs: 'data-go="settings" data-tr="slide"', label: 'Ajustes' })}</div>
      <div class="lobby-head"><div><span class="kicker t-label"><i></i>Frecus cercanas</span><h1 class="h-screen" style="margin-top:10px;font-size:28px">Elige tu frecu</h1></div><b class="count t-dot">${String(rooms.length).padStart(2, '0')}</b></div>
      <div class="tuner" ${kind === 'nonet' ? 'style="opacity:.35"' : ''}><canvas data-c="tuner" data-st="${st(tst)}"></canvas><div class="tl t-label-s"><span>${kind === 'nonet' ? 'Búsqueda en pausa' : kind === 'ble' ? 'Escaneando · Bluetooth' : 'Escaneando · Wi-Fi y Bluetooth'}</span><span class="${rooms.length ? 'cs' : ''}">${rooms.length} señales</span></div></div>
      ${list}
      <div class="dock"><div class="two">${UI.btn('Crear frecu', { icon: 'plus', attrs: 'data-go="hotspot" data-tr="wave"' })}${UI.btn('Escanear', { v: 'secondary', icon: 'scan', attrs: 'data-go="scan" data-tr="wave"' })}</div>
        <div class="two ghosts"><button class="btn btn-ghost" data-sheet="ip">${I('nodes', 's18')}<span class="lbl">Por IP</span></button><button class="btn btn-ghost" data-sheet="nfc">${I('nfc', 's18')}<span class="lbl">Por NFC</span></button></div></div></section>`;
  },

  hotspot: (s = {}) => {
    const ios = s.os === 'ios';
    const steps = ios
      ? ['<b>Abre Ajustes › Punto de acceso personal</b> y activa “Permitir a otros conectarse”.', '<b>Comparte la contraseña</b> con tu grupo y que se unan a tu red.', '<b>Mantén Frecu abierta</b> mientras se unen. En iPhone recomendamos que el anfitrión use Android.']
      : ['<b>Abre Ajustes › Zona Wi-Fi</b> (el nombre cambia según la marca).', `<b>Actívala</b> y comparte el nombre y la contraseña con tu grupo. <button class="step-act" data-sheet="hscred">${I('bluetooth', 's16')}Guardarlos para invitar por Bluetooth</button>`, '<b>Vuelve a Frecu</b> y abre tu frecu. No usa tus datos móviles.'];
    return `<section class="view v-hotspot" data-screen="hotspot">
      <div class="appbar">${back}<span class="ttl"><span class="t-label-s c3">Paso 1 de 2</span><b>Prepara la red</b></span>${spacer}</div>
      <div class="hs-ill"><canvas data-c="hotspot"></canvas></div>
      <div class="pad"><h1 class="h-screen" style="font-size:26px;line-height:30px">Activa tu punto de acceso</h1><p class="p-screen" style="margin-top:8px">Tu teléfono será la antena del grupo.</p></div>
      <div class="pad" style="margin-top:16px">${UI.seg([{ label: 'Android' }, { label: 'iPhone' }], ios ? 1 : 0, { attrs: 'data-os-seg' })}</div>
      <ol class="stepsl pad" style="margin-top:6px">${steps.map((x) => `<li><span>${x}</span></li>`).join('')}</ol>
      <div class="dock">${UI.btn('Ya está activo', { iconR: 'arrow', attrs: 'data-go="create" data-tr="slide"' })}<button class="btn btn-ghost" data-go="create" data-tr="slide"><span class="lbl">Ya estamos en la misma Wi-Fi</span></button></div></section>`;
  },

  create: (s = {}) => `<section class="view v-create" data-screen="create">
    <div class="appbar">${back}<span class="ttl"><span class="t-label-s c3">Paso 2 de 2</span><b>Nueva frecu</b></span>${spacer}</div>
    <div class="ch-hero fifths"><canvas data-c="fifths" data-st="${st({ hour: 16, minute: 24 })}"></canvas>
      <div class="chv"><span class="t-label-s c3">Tu frecu suena en</span>${UI.note(ROOM.note, 'big')}<span class="t-label-s c2">${fmtHz(ROOM.note.hz)} Hz</span><span class="t-label-s c3">Abierta a las ${ROOM.opened}</span></div></div>
    <div class="pad" style="display:flex;flex-direction:column;gap:22px;margin-top:22px">
      ${UI.field('Nombre de la frecu', ROOM.name, { count: '16/24', ph: 'Ej. Ruta del domingo' })}
      <div class="field"><span class="field-l">${UI.label('Código de acceso')}<span class="t-label-s c3">4 dígitos</span></span>
        <div class="pinrow">${UI.pin(s.pin || ROOM.pin, { cls: 'read', attrs: 'data-create-pin' })}${UI.ibtn('regen', { label: 'Generar otro', attrs: 'data-regen' })}</div>
        <span class="field-h">Compártelo solo con tu grupo: evita que se unan desconocidos de la misma red.</span></div>
    </div>
    <div class="dock">${UI.btn('Abrir frecu', { icon: 'antenna', attrs: 'data-create' })}</div></section>`,

  scan: (s = {}) => `<section class="view v-scan" data-screen="scan" data-theme="dark"><canvas class="cam" data-c="cam"></canvas>
    <div class="scan-top"><div class="appbar">${UI.ibtn('back', { attrs: 'data-back', label: 'Atrás' })}<span class="ttl"><b>Escanear invitación</b><span class="t-label-s c3">QR de la frecu</span></span>${UI.ibtn('flash', { label: 'Linterna', attrs: 'data-flash' })}</div></div>
    <div class="reticle ${s.lock ? 'lock' : ''}"><i class="cn a"></i><i class="cn b"></i><i class="cn c"></i><i class="cn d"></i><span class="beam"></span><span class="found"><i>${I('check', 's28')}</i></span></div>
    <div class="scan-bottom">${s.lock
      ? `<div class="scan-card"><span><span class="t-label-s cs">Frecu encontrada</span><b style="display:block;font:660 18px/1.2 var(--f-ui);font-stretch:108%;margin:7px 0 6px">${ROOM.name}</b><span class="t-label-s c3">${noteTxt(ROOM.note)} · ${ROOM.ip}</span></span>${UI.btn('Unirme', { cls: 'btn-s', attrs: 'data-join="qr"' })}</div>`
      : `<p>Apunta al QR que muestra el anfitrión en su teléfono.</p>${UI.btn('Conectar por IP', { v: 'secondary', icon: 'nodes', cls: 'btn-s', attrs: 'data-sheet="ip"' })}`}</div></section>`,

  room: (s = {}) => roomView(s.kind || 'idle', s),

  settings: () => `<section class="view v-settings" data-screen="settings">
    <div class="appbar">${back}<span class="ttl"><b>Ajustes</b></span>${spacer}</div>
    <div class="profile"><span class="pp">${UI.sig(ME, { size: 96, mode: 'speak', level: 'soft', r: .38 })}</span>
      <span style="display:flex;flex-direction:column;gap:8px;align-items:flex-start"><span class="t-label-s c3">Nombre visible</span><b style="font:700 26px/1 var(--f-ui);font-stretch:120%;letter-spacing:-.02em">${ME}</b>
      <button class="btn btn-secondary btn-s" style="--h:34px;padding:0 12px;border-radius:11px;font-size:13px">${I('edit', 's16')}<span class="lbl">Editar</span></button></span></div>
    <div class="set-label t-label-s">Voz</div>
    <div class="pad"><div class="group"><div class="row" style="grid-template-columns:1fr"><span class="rt"><b>Modo de habla por defecto</b><span>Se aplica al entrar a cada frecu.</span></span></div>
      <div style="padding:0 14px 14px">${UI.seg([{ label: 'PTT', icon: 'walkie' }, { label: 'Abierto', icon: 'openMic' }], 0)}</div>
      ${UI.row('Filtro de viento', 'Quita el ruido del viento en moto o bici. Usa algo más de batería.', UI.tog(true))}
      ${UI.row('Auricular al acercar', 'Si te llevas el teléfono a la oreja, el audio pasa al auricular.', UI.tog(true))}
      ${UI.row('Hablar con el botón de volumen', 'Solo Android. Mantén pulsado para hablar; con la pantalla apagada, pulsa para empezar y otra vez para terminar.', UI.tog(false))}</div></div>
    <div class="set-label t-label-s">General</div>
    <div class="pad"><div class="group">
      ${UI.row('Idioma', 'Español', `<span class="t-label-s">ES</span>${I('chevron', 's18 c3')}`)}
      ${UI.row('Vibración', 'Al transmitir, cuando alguien empieza a hablar y si se pierde la conexión.', UI.tog(true))}
      ${UI.row('Permisos', 'Micrófono, red local, notificaciones', `${UI.tag('3/3', 's')}${I('chevron', 's18 c3')}`)}
      ${UI.row('Guía del punto de acceso', '')}
      ${UI.row('Licencias', '')}</div></div>
    <div class="set-label t-label-s">Apariencia</div>
    <div class="pad"><div class="group"><div class="row"><span class="rt"><b>Tema</b><span>Auto sigue al teléfono</span></span>${UI.seg([{ label: 'Auto' }, { label: 'Claro' }, { label: 'Oscuro' }], 0, { attrs: 'data-theme-seg' })}</div></div></div>
    <p class="t-label-s c3" style="text-align:center;margin:24px 0 28px">Frecu 1.0.0 · 100% local · sin internet</p></section>`,

  closed: (s = {}) => `<section class="view v-closed" data-screen="closed">
    <div class="flat"><canvas data-c="flat"></canvas></div>
    <div class="pad" style="text-align:center;display:flex;flex-direction:column;gap:12px;align-items:center">
      <span class="t-label c3">${noteTxt(ROOM.note)} · fuera del aire</span><h1 class="h-screen">Fin de la transmisión</h1>
      <p class="p-screen" style="max-width:300px">${s.host ? 'Cerraste la frecu. Todos los participantes fueron desconectados.' : 'El anfitrión cerró la frecu. Puedes unirte a otra cuando quieras.'}</p></div>
    <div class="pad" style="margin-top:30px"><div class="stats">
      <div><span class="t-label-s c3">Duración</span><b class="t-dot">42:17</b></div>
      <div><span class="t-label-s c3">Personas</span><b class="t-dot">05</b></div>
      <div><span class="t-label-s c3">Nota</span>${UI.note(ROOM.note)}</div></div></div>
    <div class="dock">${UI.btn('Volver al inicio', { attrs: 'data-home' })}</div></section>`,
};

/* ---------- Hojas modales ---------- */
const SH = {
  pin: (s = {}) => {
    const state = s.state || '';
    const msg = state === 'error' ? '<p class="pin-msg err">Código incorrecto. Revisa e intenta otra vez.</p>'
      : state === 'full' ? UI.banner('warn', 'users', '<b>Esta frecu está llena (6/6).</b> Podrás entrar cuando alguien salga.', { close: false })
        : state === 'busy' ? '<p class="pin-msg">Verificando con el anfitrión…</p>'
          : '<p class="pin-msg">Se envía al completar los 4 dígitos</p>';
    return `<div class="sheet" data-sheet-el="pin"><span class="grab"></span>
      <div class="sh-h"><div><span class="t-label-s c3">${noteTxt(ROOM.note)} · ${fmtHz(ROOM.note.hz)} Hz · ${ROOM.ip}</span><h3 style="margin-top:8px">${ROOM.name}</h3><p>Ingresa el código de acceso. Pídeselo al anfitrión.</p></div>${UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' })}</div>
      ${UI.pin(s.digits ?? '48', { state: state === 'full' ? '' : state, attrs: 'data-pin' })}
      <div data-pin-msg>${msg}</div>
      ${UI.keypad({ attrs: 'data-keys' })}
      <p class="t-label-s c3" style="text-align:center">Entrarás como <span class="c1">${ME}</span></p></div>`;
  },
  ip: (s = {}) => `<div class="sheet" data-sheet-el="ip"><span class="grab"></span>
    <div class="sh-h"><div><span class="t-label-s c3">Conexión manual</span><h3 style="margin-top:8px">Conectar por IP</h3><p>Úsalo si la frecu no aparece en la lista.</p></div>${UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' })}</div>
    ${UI.field('IP del anfitrión', ROOM.ip, { mono: true, icon: 'nodes', right: 'Puerto 47800', cls: s.error ? 'error' : 'focus' })}
    ${UI.field('Código de acceso', ROOM.pin, { mono: true, icon: 'lock' })}
    ${s.error ? UI.banner('alert', 'alert', '<b>El anfitrión no responde.</b> Revisa que estés en su misma red Wi-Fi.', { close: false }) : ''}
    ${UI.btn('Conectar', { icon: 'arrow', attrs: 'data-join="ip"' })}</div>`,
  invite: () => `<div class="sheet" data-sheet-el="invite"><span class="grab"></span>
    <div class="sh-h"><div><span class="t-label-s c3">Invitar a la frecu</span><h3 style="margin-top:8px">Escanea para unirte</h3><p>Desde Frecu › Escanear. El QR ya incluye el código.</p></div>${UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' })}</div>
    <div class="qr-frame"><canvas data-c="qr" data-seed="77"></canvas></div>
    <div class="inv-meta"><div><span class="t-label-s c3">Nota</span>${UI.note(ROOM.note)}</div><div><span class="t-label-s c3">Código</span><b class="t-dot">${ROOM.pin}</b></div><div><span class="t-label-s c3">Anfitrión</span><span class="t-data">${ROOM.ip}</span><span class="t-label-s c3">Puerto ${ROOM.port}</span></div></div>
    <div class="nfc-box"><span class="oic">${I('nfc')}</span><span class="ot"><b>También por NFC</b><span class="t-body-s">Acerca otro teléfono al tuyo</span></span>
      <button class="btn btn-secondary btn-s nfc-w" data-nfc-write>${I('nfc', 's16')}<span class="lbl">Grabar etiqueta</span></button></div></div>`,
  hscred: () => `<div class="sheet" data-sheet-el="hscred"><span class="grab"></span>
    <div class="sh-h"><div><span class="t-label-s c3">Invitar por Bluetooth · opcional</span><h3 style="margin-top:8px">Tu zona Wi-Fi</h3><p>Quien esté cerca y tenga el código de la frecu se conecta a tu red sin buscarla. Se guarda solo en tu teléfono.</p></div>${UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' })}</div>
    ${UI.field('Nombre de la zona Wi-Fi', 'Moto de Andrés', { ph: 'Tal como aparece en Ajustes', cls: 'focus' })}
    ${UI.field('Contraseña', '••••••••••', { icon: 'lock', help: 'Android no deja que las apps la lean: escríbela tal como está en Ajustes › Zona Wi-Fi.' })}
    ${UI.btn('Guardar', { icon: 'check', attrs: 'data-close' })}</div>`,
  quick: (s = {}) => `<div class="sheet" data-sheet-el="quick"><span class="grab"></span>
    <div class="sh-h"><div><span class="t-label-s c3">Para toda la frecu</span><h3 style="margin-top:8px">Mensajes rápidos</h3><p>Llegan al instante y vibran, aunque tengan la pantalla apagada.</p></div>${UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' })}</div>
    <div class="qgrid">${QUICK.map(([ic, l]) => `<button class="qbtn" data-quick="${l}">${I(ic, 's20')}<span>${l}</span></button>`).join('')}</div>
    <button class="sos-btn" data-sos><span class="sos-fill"></span>${I('sos', 's20')}<span><b>Mantén para enviar SOS</b><small>Alarma para todos, con tu ubicación si la compartes</small></span></button>
    <div class="group">${UI.row('Compartir mi ubicación', s.geo ? 'Tu grupo ve a qué distancia y hacia dónde estás.' : 'Apagado. Tu grupo no ve dónde estás.', UI.tog(!!s.geo, 'data-geo-tog'))}</div></div>`,
  blepin: (s = {}) => `<div class="sheet" data-sheet-el="blepin"><span class="grab"></span>
    <div class="sh-h"><div><span class="t-label-s c3">${noteTxt(BLE_ROOM.note)} · ${fmtHz(BLE_ROOM.note.hz)} Hz · por Bluetooth</span><h3 style="margin-top:8px">${BLE_ROOM.name}</h3><p>Código correcto. Te conectamos a la red del anfitrión.</p></div>${UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' })}</div>
    ${UI.pin('4827', { cls: 'read ok' })}
    <div class="wifi-step"><canvas class="wave-loader" data-c="wave" style="width:46px;height:20px"></canvas><span><b>Conectando a la Wi-Fi «${BLE_ROOM.ssid}»…</b><span class="t-body-s c3">Tu teléfono te pedirá confirmar la red.</span></span></div></div>`,
  nfc: (s = {}) => `<div class="sheet" data-sheet-el="nfc"><span class="grab"></span>
    <div class="sh-h"><div><span class="t-label-s c3">Unirse por NFC</span><h3 style="margin-top:8px">${s.found ? 'Frecu encontrada' : 'Acerca tu teléfono'}</h3><p>${s.found ? 'Leímos la invitación del anfitrión. Ya trae el código.' : 'Junta el dorso de tu teléfono con el del anfitrión, o con una etiqueta de la frecu.'}</p></div>${UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' })}</div>
    <div class="nfc-stage ${s.found ? 'found' : ''}"><span class="nfc-ring"></span><span class="nfc-ring b"></span><span class="nfc-ic">${I(s.found ? 'check' : 'nfc', 's34')}</span></div>
    ${s.found
      ? `<div class="scan-card"><span><span class="t-label-s cs">Por NFC</span><b style="display:block;font:660 18px/1.2 var(--f-ui);font-stretch:108%;margin:7px 0 6px">${ROOM.name}</b><span class="t-label-s c3">${noteTxt(ROOM.note)} · ${ROOM.ip}</span></span>${UI.btn('Unirme', { cls: 'btn-s', attrs: 'data-join="qr"' })}</div>`
      : '<p class="t-label-s c3" style="text-align:center">En iPhone, mantén la parte de arriba del teléfono junto al otro.</p>'}</div>`,
  route: (s = {}) => {
    const r = s.route || 'speaker'; const bt = s.bt !== false;
    return `<div class="sheet" data-sheet-el="route"><span class="grab"></span>
    <div class="sh-h"><div><span class="t-label-s c3">Salida de audio</span><h3 style="margin-top:8px">¿Dónde escuchas?</h3><p>Al conectar audífonos, el audio cambia solo.</p></div>${UI.ibtn('close', { cls: 's40', attrs: 'data-close', label: 'Cerrar' })}</div>
    <div style="display:flex;flex-direction:column;gap:8px">
      ${UI.opt('speaker', 'Altavoz', 'Manos libres', { on: r === 'speaker', attrs: 'data-route="speaker"' })}
      ${UI.opt('earpiece', 'Auricular', 'Teléfono en la oreja', { on: r === 'earpiece', attrs: 'data-route="earpiece"' })}
      ${UI.opt('headset', bt ? 'Sena 50S' : 'Bluetooth', bt ? 'Bluetooth · conectado' : 'Sin dispositivo', { on: r === 'bluetooth', dis: !bt, attrs: 'data-route="bluetooth"' })}
    </div></div>`;
  },
  leave: (s = {}) => `<div class="sheet" data-sheet-el="leave"><span class="grab"></span>
    <div style="display:flex;flex-direction:column;align-items:center;text-align:center;gap:12px;padding:10px 6px 4px">
      <span class="perm" style="padding:0;background:none;box-shadow:none"><span class="pic" style="width:56px;height:56px;border-radius:18px;color:var(--alert)">${I(s.host ? 'antenna' : 'exit', 's28')}</span></span>
      <h3 style="font:680 22px/1.2 var(--f-ui);font-stretch:116%">${s.host ? 'Cerrar la frecu para todos' : '¿Salir de la frecu?'}</h3>
      <p class="p-screen" style="font-size:14.5px">${s.host ? leaveCopy(s.others ?? 4) : 'Podrás volver a unirte con el código de acceso.'}</p></div>
    ${UI.btn(s.host ? 'Cerrar frecu' : 'Salir de la frecu', { v: 'danger-solid', icon: 'exit', attrs: `data-leave="${s.host ? 'host' : 'peer'}"` })}
    ${UI.btn('Cancelar', { v: 'secondary', attrs: 'data-close' })}</div>`,
};
const scrim = '<div class="scrim" data-close></div>';
const leaveCopy = (n) => (n <= 0 ? 'Eres el anfitrión. Si sales, la frecu se cierra.' : `Eres el anfitrión. Si sales, la frecu se cierra para ${n === 1 ? 'la otra persona' : `las otras ${n} personas`}.`);

/* ---------- Catálogo para la galería ---------- */
const GALLERY = [
  { flow: 'Arranque y primera vez', items: [
    { title: 'Arranque', route: 'Splash nativo + intro', desc: 'La portadora plana se modula y se pliega en la firma de Frecu.', html: () => V.splash(), go: ['splash'] },
    { title: 'Bienvenida', route: 'PermissionsRoute · 1/3', desc: 'La malla de 6 lugares explica el producto sin texto técnico.', html: () => V.welcome(), go: ['welcome'] },
    { title: 'Tu nombre y tu firma', route: 'Nuevo · 2/3', desc: 'La firma de señal se genera en vivo con cada letra del nombre.', html: () => V.name(), go: ['name'] },
    { title: 'Permisos', route: 'PermissionsRoute · 3/3', desc: 'Tres permisos con su porqué. La cámara se pide en contexto.', html: () => V.perms({ granted: ['ok', 'ok'] }), go: ['perms'] },
  ] },
  { flow: 'Inicio y unión', items: [
    { title: 'Inicio · frecus cercanas', route: 'LobbyRoute', desc: 'Sintonizador de dos octavas: cada frecu detectada por mDNS es un pico sobre la tecla de su nota.', html: () => V.lobby({ sel: ROOM.note.s }), go: ['lobby'] },
    { title: 'Inicio · escaneando', route: 'LobbyRoute · vacío', desc: 'Solo ruido de fondo y la aguja barriendo. Guía clara de qué hacer.', html: () => V.lobby({ kind: 'empty' }), go: ['lobby', { kind: 'empty' }] },
    { title: 'Inicio · sin red', route: 'LobbyRoute · error', desc: 'Sin IP local la búsqueda se pausa y se explica cómo resolverlo.', html: () => V.lobby({ kind: 'nonet' }), go: ['lobby', { kind: 'nonet' }] },
    { title: 'Código de acceso', route: 'Hoja · PinSheet', desc: 'Teclado propio, celdas de matriz de puntos, envío automático.', html: () => V.lobby({ sel: ROOM.note.s }).replace('class="view v-lobby"', 'class="view v-lobby under"') + scrim + SH.pin(), go: ['lobby', {}, 'pin'] },
    { title: 'Código incorrecto', route: 'Failure.invalidAccessCode', desc: 'Sacudida amortiguada y mensaje en rojo bengala.', html: () => V.lobby({ sel: ROOM.note.s }).replace('class="view v-lobby"', 'class="view v-lobby under"') + scrim + SH.pin({ digits: '4821', state: 'error' }), go: ['lobby', {}, 'pin'] },
    { title: 'Conectar por IP', route: 'Hoja · Failure.hostUnreachable', desc: 'Respaldo manual con el error de anfitrión inalcanzable.', html: () => V.lobby({ sel: ROOM.note.s }).replace('class="view v-lobby"', 'class="view v-lobby under"') + scrim + SH.ip({ error: true }), go: ['lobby', {}, 'ip'] },
    { title: 'Escanear QR', route: 'ScanQrRoute', desc: 'Retícula que respira y haz de barrido sobre la cámara.', html: () => V.scan(), go: ['scan'] },
    { title: 'QR detectado', route: 'ScanQrRoute · bloqueo', desc: 'Las esquinas se cierran con resorte sobre el código y confirman.', html: () => V.scan({ lock: true }), go: ['scan', { lock: true }] },
  ] },
  { flow: 'Crear frecu (anfitrión)', items: [
    { title: 'Prepara la red', route: 'Nuevo · guía de hotspot', desc: 'Guía por plataforma; Android se prioriza como anfitrión.', html: () => V.hotspot(), go: ['hotspot'] },
    { title: 'Nueva frecu', route: 'CreateRoomRoute', desc: 'La nota sale de la hora en el círculo de quintas; nombre y código regenerable.', html: () => V.create(), go: ['create'] },
    { title: 'Frecu abierta', route: 'RoomRoute · anfitrión solo', desc: 'Lugares libres invitan a compartir el QR.', html: () => roomView('alone'), go: ['room', { kind: 'alone', host: true }] },
    { title: 'Invitar', route: 'Hoja · InviteSheet', desc: 'QR de módulos redondos con la firma al centro, código e IP.', html: () => roomView('alone').replace('class="view v-room ', 'class="view v-room under ') + scrim + SH.invite(), go: ['room', { kind: 'alone', host: true }, 'invite'] },
  ] },
  { flow: 'Frecu activa', items: [
    { title: 'Conectando', route: 'RoomStatus.connecting', desc: 'La malla se dibuja punteada mientras se negocia cada enlace.', html: () => roomView('connecting'), go: ['room', { kind: 'connecting' }] },
    { title: 'En línea', route: 'RoomStatus.connected', desc: 'Hexágono de 6 lugares: tú abajo, cerca del pulgar.', html: () => roomView('idle'), go: ['room'] },
    { title: 'Ana habla', route: 'talk_state · recepción', desc: 'Su firma se enciende y los paquetes viajan por la malla hacia todos.', html: () => roomView('rx'), go: ['room', { kind: 'rx' }] },
    { title: 'Tú transmites', route: 'PTT presionado', desc: 'El núcleo se ilumina, el bisel funciona como VU circular.', html: () => roomView('tx'), go: ['room'] },
    { title: 'Micrófono abierto', route: 'TalkMode.openMic + altavoz', desc: 'Aviso de eco cuando el audio sale por altavoz.', html: () => roomView('open'), go: ['room', { kind: 'open' }] },
    { title: 'Reconectando', route: 'RoomStatus.reconnecting', desc: 'La malla se vuelve ámbar y punteada; el PTT queda en espera.', html: () => roomView('rec'), go: ['room', { kind: 'rec' }] },
    { title: 'Salida de audio', route: 'Hoja · AudioRouteSheet', desc: 'Altavoz, auricular o Bluetooth con el dispositivo conectado.', html: () => roomView('idle').replace('class="view v-room ', 'class="view v-room under ') + scrim + SH.route({ route: 'bluetooth' }), go: ['room', {}, 'route'] },
    { title: 'Cerrar la frecu', route: 'Hoja · anfitrión', desc: 'Confirmación con consecuencia explícita para el grupo.', html: () => roomView('idle', { host: true }).replace('class="view v-room ', 'class="view v-room under ') + scrim + SH.leave({ host: true }), go: ['room', { host: true }, 'leave'] },
  ] },
  { flow: 'Novedades V1 · sensores y hardware', items: [
    { title: 'Señal débil', route: 'getStats · calidad del enlace', desc: 'El enlace se vuelve ámbar y punteado; la isla avisa una vez y el teléfono vibra.', html: () => roomView('weak'), go: ['room', { kind: 'weak' }] },
    { title: 'Distancias del grupo', route: 'Mensaje position · GPS', desc: 'Con la ubicación compartida, cada nombre lleva su distancia y una flecha hacia donde está.', html: () => roomView('geo'), go: ['room', { kind: 'geo' }] },
    { title: 'Se quedó atrás', route: 'Regla de distancia', desc: 'Si alguien se aleja del grupo más de lo normal, aviso ámbar con su distancia y rumbo.', html: () => roomView('behind'), go: ['room', { kind: 'behind' }] },
    { title: 'Mensajes rápidos', route: 'Hoja · QuickMessageSheet', desc: 'Cuatro mensajes de un toque, SOS manteniendo pulsado y el interruptor de ubicación.', html: () => roomView('geo').replace('class="view v-room ', 'class="view v-room under ') + scrim + SH.quick({ geo: true }), go: ['room', { kind: 'geo' }, 'quick'] },
    { title: 'Mensaje recibido', route: 'Mensaje quick_message', desc: 'Llega a la isla con la firma de quien lo manda, y vibra.', html: () => roomView('msg'), go: ['room', { kind: 'msg' }] },
    { title: 'SOS recibido', route: 'Mensaje quick_message · sos', desc: 'Alarma a pantalla completa con distancia y rumbo hasta que alguien la atiende.', html: () => roomView('sos'), go: ['room', { kind: 'sos' }] },
    { title: 'Ajustes nuevos', route: 'SettingsRoute', desc: 'Filtro de viento, auricular al acercar, botón de volumen (Android) y vibración.', html: () => V.settings(), go: ['settings'] },
    { title: 'Zona Wi-Fi para Bluetooth', route: 'Guía de hotspot · Android', desc: 'Nombre y contraseña opcionales para que otros se unan por Bluetooth sin buscar la red.', html: () => V.hotspot().replace('class="view v-hotspot"', 'class="view v-hotspot under"') + scrim + SH.hscred(), go: ['hotspot', {}, 'hscred'] },
    { title: 'Frecu cercana por Bluetooth', route: 'LobbyRoute · BLE', desc: 'Aparece aunque aún no estés en su Wi-Fi.', html: () => V.lobby({ kind: 'ble' }), go: ['lobby', { kind: 'ble' }] },
    { title: 'Conectando a su Wi-Fi', route: 'Hoja · unión por BLE', desc: 'Con el código correcto, el anfitrión entrega su red y el teléfono se conecta.', html: () => V.lobby({ kind: 'ble' }).replace('class="view v-lobby"', 'class="view v-lobby under"') + scrim + SH.blepin(), go: ['lobby', { kind: 'ble' }, 'blepin'] },
    { title: 'Invitar por NFC', route: 'Hoja · InviteSheet', desc: 'El QR de siempre, y además acercar otro teléfono o grabar una etiqueta NFC.', html: () => roomView('alone').replace('class="view v-room ', 'class="view v-room under ') + scrim + SH.invite(), go: ['room', { kind: 'alone', host: true }, 'invite'] },
    { title: 'Unirse por NFC', route: 'Hoja · NfcJoinSheet', desc: 'Leer la invitación del teléfono del anfitrión o de una etiqueta.', html: () => V.lobby({ sel: ROOM.note.s }).replace('class="view v-lobby"', 'class="view v-lobby under"') + scrim + SH.nfc({ found: true }), go: ['lobby', {}, 'nfc'] },
  ] },
  { flow: 'Cierre y ajustes', items: [
    { title: 'Fin de la transmisión', route: 'RoomStatus.closed', desc: 'La firma se aplana en una línea: la frecu salió del aire.', html: () => V.closed(), go: ['closed'] },
    { title: 'Ajustes', route: 'SettingsRoute', desc: 'Tu firma, modo de habla por defecto, idioma y ayuda.', html: () => V.settings(), go: ['settings'] },
  ] },
];
