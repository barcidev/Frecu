/* ==========================================================================
   FRECU · Portadora — Documento, galería y prototipo navegable
   ========================================================================== */
'use strict';

const $ = (s, r = document) => r.querySelector(s);
const $$ = (s, r = document) => [...r.querySelectorAll(s)];
const el = (s) => { const t = document.createElement('template'); t.innerHTML = s.trim(); return t.content.firstElementChild; };
const cssVar = (k) => getComputedStyle(document.documentElement).getPropertyValue(k).trim();
const ease = (k) => cssVar(`--spring-${k}`) || 'cubic-bezier(.22,1,.36,1)';
const OUT = 'cubic-bezier(.16,1,.3,1)';

/* ---------- Componentes en el documento ---------- */
function card(title, path, desc, demo, o = {}) {
  return `<div class="cbox ${o.wide ? 'wide' : ''}"><div class="ch"><b>${title}</b><code>${path}</code></div><p class="cd">${desc}</p><div class="demo ${o.demo || ''}" ${o.attrs || ''}>${demo}</div></div>`;
}
function buildComponents() {
  const people = [['Jorge', 'signal', 'speak', 'voice', 'Tú · hablando'], ['Andrés', 'p1', 'idle', '', 'En reposo'], ['Ana', 'p2', 'speak', 'voice', 'Hablando'], ['Leo', 'p3', 'muted', '', 'Silenciado'], ['Sofi', 'p4', 'link', '', 'Conectando'], ['Marta', 'p5', 'off', '', 'Sin señal']];
  const sigs = people.map(([n, c, m, l, s]) => `<div style="display:flex;flex-direction:column;align-items:center;gap:10px;width:118px">${UI.sig(n, { size: 96, color: c, mode: m, level: l })}<b style="font:600 14px/1 var(--f-ui)">${n}</b><span class="t-label-s c3">${s}</span></div>`).join('');
  const docMesh = meshFor('rx');
  const tunerSt = { rooms: [{ s: 2, label: 'Re4' }, { s: 16, label: 'Mi5' }, { s: 21, label: 'La5' }], sel: null };
  const pst = pttState('idle');
  const html = [
    card('FrButton', 'core/design/widgets/fr_button.dart', 'Primario (señal), secundario (grafito), fantasma y peligro. Altura 58, esquinas continuas. La luz sigue al dedo y al cargar la etiqueta se vuelve onda.',
      `${UI.btn('Crear frecu', { icon: 'plus' })}${UI.btn('Escanear', { v: 'secondary', icon: 'scan' })}${UI.btn('Conectar por IP', { v: 'ghost', icon: 'nodes' })}${UI.btn('Salir', { v: 'danger', icon: 'exit' })}${UI.btn('Abrir frecu', { cls: 'loading', attrs: 'style="min-width:160px"' })}`, { wide: true }),
    card('SignalSignature', 'core/design/widgets/signal_signature.dart', 'La identidad de cada persona: una curva de Lissajous que nace del hash de su nombre (forma idéntica en todos los teléfonos). Respira en reposo, se enciende al hablar, se aplana al silenciarse y se vuelve punteada al conectar. Distinguible por forma, no solo por color.', sigs, { wide: true }),
    card('PttCore', 'features/room/presentation/widgets/ptt_core.dart', 'El corazón de la app. Mantén presionado (o la barra espaciadora). El bisel de 72 marcas es un VU circular, el anillo líquido reacciona a tu voz y emite ondas.',
      `<div data-doc-ptt>${pttZone('idle', pst)}</div>`),
    card('FrPinField + FrKeypad', 'core/design/widgets/fr_pin_field.dart', 'Celdas en matriz de puntos y teclado propio de teclas grandes (aptas con guantes). Envío automático al cuarto dígito. Prueba 4827 y luego otro código.',
      `<div data-doc-pin style="display:flex;flex-direction:column;gap:16px;width:300px">${UI.pin('', {})}<p class="pin-msg">Se envía al completar</p>${UI.keypad()}</div>`, { demo: 'col' }),
    card('FrequencyTuner', 'features/lobby/presentation/widgets/frequency_tuner.dart', 'Teclado de dos octavas (Do4–Si5): cada frecu descubierta por mDNS es un pico sobre la tecla de su nota. La aguja recorre las teclas mientras busca y salta con resorte al elegir una. Toca la banda para sintonizar.',
      `<div class="tuner" style="width:100%;margin:0;cursor:pointer" data-doc-tuner><canvas data-c="tuner" data-st="${st(tunerSt)}"></canvas><div class="tl t-label-s"><span>Escaneando · _frecu._tcp</span><span class="cs">3 señales</span></div></div>`, { wide: false }),
    card('NearbyRoomTile', 'features/lobby/presentation/widgets/nearby_room_tile.dart', 'Nota en matriz de puntos con su frecuencia y mini espectro, nombre, IP y candado (siempre lleva código). Estado seleccionado con borde de señal.',
      `<div style="display:flex;flex-direction:column;gap:10px;width:100%">${UI.rtile(NEARBY[0], { sel: true })}${UI.rtile(NEARBY[1])}</div>`, { demo: 'col' }),
    card('FifthsClock', 'features/lobby/presentation/widgets/fifths_clock.dart', 'El reloj del círculo de quintas: la aguja de la hora señala la nota de la frecu. Aparece al crear la frecu; aquí corre acelerado para recorrer las 24 horas.',
      `<canvas data-c="fifths" data-st="${st({ demo: true })}" style="width:230px;height:230px"></canvas>`),
    card('RoomMesh', 'features/room/presentation/widgets/room_mesh.dart', 'La sala como red: 6 lugares en hexágono (el máximo de la malla), tú abajo junto al pulgar, el anfitrión con antena. Quien habla se enciende y sus paquetes de voz viajan por las aristas hacia los demás.',
      `<div class="mesh" style="width:390px;height:304px"><canvas data-c="mesh" data-st="${st(docMesh)}"></canvas><div class="labels">${meshLabels(docMesh)}</div></div>`, { wide: true }),
    card('StatusIsland', 'features/room/presentation/widgets/status_island.dart', 'Cápsula superior que cambia de forma con resorte: estado de la frecu, quién habla, eventos (se unió, salió) y reconexión.',
      `<div style="display:flex;flex-direction:column;gap:10px;align-items:center">${isleFor('idle', 5)}${isleFor('rx', 5)}${isleFor('tx', 5)}${isleFor('rec', 5)}${isleFor('connecting', 1)}</div>`, { demo: 'col' }),
    card('TalkModeSwitch · FrSwitch', 'core/design/widgets/fr_segmented.dart', 'Pulgar líquido que se estira al viajar y se asienta con rebote. Mismo lenguaje en el interruptor.',
      `<div style="display:flex;flex-direction:column;gap:18px;width:260px">${UI.seg([{ label: 'PTT', icon: 'walkie' }, { label: 'Abierto', icon: 'openMic' }], 0)}${UI.seg([{ label: 'Android' }, { label: 'iPhone' }], 1, { cls: 'signal' })}<div style="display:flex;gap:14px;align-items:center">${UI.tog(true)}${UI.tog(false)}<span class="t-label-s c3">FrSwitch</span></div></div>`, { demo: 'col' }),
    card('StatusPill · FrTag', 'core/design/widgets/status_pill.dart', 'Punto con halo que late según el estado. Etiquetas en mono mayúscula.',
      `<div style="display:flex;flex-wrap:wrap;gap:10px;justify-content:center">${UI.pill('Conectado', 'ok')}${UI.pill('Conectando', 'warn busy')}${UI.pill('Reconectando · 4 s', 'warn')}${UI.pill('Sin red local', 'alert')}${UI.pill('Cerrada', 'off')}${UI.tag('Anfitrión')}${UI.tag('3/3', 's')}${UI.tag('v1', 'w')}</div>`),
    card('AudioRoutePill · FrOption', 'features/room/presentation/widgets/audio_route_selector.dart', 'Salida actual con actividad en vivo; al tocar abre las opciones. Bluetooth muestra el nombre del dispositivo.',
      `<div style="display:flex;flex-direction:column;gap:10px;width:100%;max-width:340px">${UI.route('speaker')}${UI.opt('headset', 'Sena 50S', 'Bluetooth · conectado', { on: true })}${UI.opt('earpiece', 'Auricular', 'Teléfono en la oreja')}</div>`, { demo: 'col' }),
    card('FrTextField', 'core/design/widgets/fr_text_field.dart', 'Etiqueta mono arriba, contador, línea de señal que se dibuja al enfocar y sacudida amortiguada en error.',
      `<div style="display:flex;flex-direction:column;gap:18px;width:100%;max-width:340px">${UI.field('Nombre de la frecu', 'Ruta del domingo', { count: '16/24', cls: 'focus' })}${UI.field('IP del anfitrión', '192.168.43.1', { mono: true, icon: 'nodes', cls: 'error', help: 'El anfitrión no responde en 192.168.43.1:47800' })}</div>`, { demo: 'col' }),
    card('PermissionRow · StepDots', 'features/permissions/presentation/widgets/permission_row.dart', 'Cada permiso con su porqué. Concedido, pendiente y denegado (con acceso directo a Ajustes).',
      `<div style="display:flex;flex-direction:column;gap:10px;width:100%;max-width:360px">${UI.perm('mic', 'Micrófono', 'Para que tu grupo te escuche.', 'ok')}${UI.perm('wifi', 'Red local', 'Para encontrar frecus.')}${UI.perm('bell', 'Notificaciones', 'Frecu activa en segundo plano.', 'deny')}<div style="display:flex;gap:14px;align-items:center;justify-content:center;margin-top:6px">${UI.steps(3, 0)}${UI.steps(3, 1)}${UI.steps(3, 2)}</div></div>`, { demo: 'col' }),
    card('FrBanner · FrToast · WaveLoader', 'core/design/widgets/fr_banner.dart', 'Avisos contextuales sin modales. El loader de onda reemplaza a todos los spinners.',
      `<div style="display:flex;flex-direction:column;gap:10px;width:100%;max-width:360px">${UI.banner('warn', 'headset', '<b>Micrófono abierto con altavoz.</b> Usa audífonos para evitar eco.')}${UI.banner('alert', 'wifi', '<b>No estás en ninguna red Wi-Fi.</b> Únete al punto de acceso del anfitrión.', { close: false })}<div style="display:flex;gap:10px;align-items:center;justify-content:space-between">${UI.toast('<b>Ana</b> se unió', { sig: 'Ana', color: 'p2' })}<canvas class="wave-loader" data-c="wave"></canvas></div></div>`, { demo: 'col' }),
    card('InviteQr', 'features/room/presentation/widgets/invite_qr.dart', 'qr_flutter con módulos redondos, ojos de esquina suave y la firma de Frecu al centro (corrección H).',
      `<div class="qr-frame" style="width:200px;height:200px;padding:16px;border-radius:30px"><canvas data-c="qr" data-seed="77"></canvas></div>`),
  ].join('');
  $('#comp').innerHTML = html;
  $('#icons').innerHTML = Object.keys(ICONS).filter((k) => k !== 'dot').map((k) => `<div>${I(k, 's28')}<span>${k}</span></div>`).join('');

  // PTT de documentación
  const zone = $('[data-doc-ptt] .ptt');
  const press = (on) => {
    pst.tx = on; pst.levelFn = on ? (t) => voice(t, 5) : null;
    zone.classList.toggle('tx', on); zone.classList.toggle('down', on);
    $('.pl', zone).textContent = on ? 'Al aire' : 'Mantén';
    $('[data-doc-ptt] [data-hint]').textContent = on ? 'Suelta para escuchar' : PTT_COPY.idle[2];
  };
  zone.addEventListener('pointerdown', (e) => { e.preventDefault(); press(true); const t0 = performance.now(); zone.__t = setInterval(() => { $('.tm', zone).textContent = `00:${String(Math.floor((performance.now() - t0) / 1000)).padStart(2, '0')}`; }, 200); });
  const up = () => { if (pst.tx) { press(false); clearInterval(zone.__t); } };
  addEventListener('pointerup', up); addEventListener('pointercancel', up);

  // PIN de documentación
  const pinBox = $('[data-doc-pin]'); let digits = '';
  pinBox.addEventListener('click', (e) => {
    const k = e.target.closest('[data-key]'); if (!k) return;
    const key = k.dataset.key; const cur = $('.pin', pinBox);
    if (cur.classList.contains('busy')) return;
    if (cur.classList.contains('error') || cur.classList.contains('ok')) digits = '';
    if (key === 'del') digits = digits.slice(0, -1); else if (/\d/.test(key) && digits.length < 4) digits += key; else return;
    const n = el(UI.pin(digits, {})); if (digits.length && key !== 'del') n.children[digits.length - 1].classList.add('pop');
    cur.replaceWith(n); $('.pin-msg', pinBox).textContent = 'Se envía al completar'; $('.pin-msg', pinBox).className = 'pin-msg';
    if (digits.length === 4) {
      n.classList.add('busy'); $('.pin-msg', pinBox).textContent = 'Verificando…';
      setTimeout(() => {
        n.classList.remove('busy'); const ok = digits === ROOM.pin; n.classList.add(ok ? 'ok' : 'error');
        const m = $('.pin-msg', pinBox); m.textContent = ok ? 'Código correcto' : 'Código incorrecto. Intenta otra vez.'; m.className = 'pin-msg ' + (ok ? 'okm' : 'err');
      }, 800);
    }
  });
  // Sintonizador de documentación
  $('[data-doc-tuner]').addEventListener('click', () => { const s = tunerSt; const chs = s.rooms.map((r) => r.s); const i = chs.indexOf(s.sel); s.sel = i === chs.length - 1 ? null : chs[i + 1]; });
}

/* ---------- Paleta doble (noche · día) ---------- */
const PALETTE = [
  ['Superficies', 'FrColors · surface0–4', [['Vacío', '#060708', '#EEF0EC', 'Fondo de la app.'], ['Grafito · Papel', '#0C0E10', '#FFFFFF', 'Tarjetas y controles.'], ['Pizarra', '#13161A', '#F6F7F4', 'Hojas y campos.'], ['Acero', '#1B1F24', '#E6E9E3', 'Presionado y pulgares.'], ['Titanio', '#262B31', '#D3D8D1', 'Bordes de control.']]],
  ['Texto', 'FrColors · text1–4 · contraste sobre el fondo', [['Principal', '#F2F4F3', '#0C0F0D', '18:1 · 17:1'], ['Secundario', '#A3ABA8', '#49524D', '8.2:1 · 7:1'], ['Etiquetas', '#7A8380', '#5F6964', '4.9:1 · 5:1'], ['Decorativo', '#3F4644', '#A9B0AB', 'Reglas y vacíos.'], ['Tinta de señal', '#0A0C05', '#0A0C05', 'Texto sobre el verde.']]],
  ['Señal y estados', 'FrColors · signal · signalFg · warn · alert', [['Señal · lima mate', '#C4E05C', '#C4E05C', 'El mismo verde en ambos: botón principal, PTT al aire, brillos y marcatexto.'], ['Señal · texto y trazo', '#C4E05C', '#0C0F0D', 'De día el texto va en tinta y el verde lo subraya: sobre blanco no se lee como letra.'], ['Ámbar', '#FFB547', '#A86400', 'Reconexión y eco.'], ['Bengala', '#FF5A4E', '#D2362B', 'Errores y salir.'], ['Velo', 'rgba(2,3,4,.55)', 'rgba(16,20,18,.28)', 'Detrás de las hojas.']]],
  ['Canales de participantes', 'FrColors · peer[0..5]', [['Tú', '#C4E05C', '#C4E05C', 'Siempre tu color; de día, trazo en tinta con halo verde.'], ['Hielo', '#7FD6FF', '#0B84B8', ''], ['Orquídea', '#C9A0FF', '#7A4BD1', ''], ['Coral', '#FF8E7A', '#CF4B33', ''], ['Menta', '#5FF0C0', '#0B9A70', ''], ['Oro', '#FFD166', '#A97800', '']]],
];
function buildPalette() {
  const hex = (v) => (v.startsWith('#') ? v : 'velo');
  $('#palette').innerHTML = PALETTE.map(([title, tok, items]) => `<div class="sub"><h3>${title}</h3><small>${tok}</small></div>
    <div class="swatches ${items.length === 6 ? 's6' : ''}">${items.map(([n, d, l, u]) => `<div class="swatch"><div class="chip duo"><i style="background:${d}"><span>Noche</span></i><i style="background:${l}"><span>Día</span></i></div><div class="info"><b>${n}</b><span>${hex(d)} · ${hex(l)}</span>${u ? `<p>${u}</p>` : ''}</div></div>`).join('')}</div>`).join('');
  const pairs = [['Inicio', () => V.lobby({ sel: ROOM.note.s })], ['Frecu activa · Ana habla', () => roomView('rx')], ['Nueva frecu', () => V.create()]];
  $('#pairs').innerHTML = pairs.map(([t, f]) => ['dark', 'light'].map((m) => `<div class="gitem"><div class="scaler">${phone(f(), { attrs: `data-theme="${m}"` })}</div><div class="cap"><em>${m === 'dark' ? 'Noche · oscuro' : 'Día · claro'}</em><b>${t}</b></div></div>`).join('')).join('');
}

/* ---------- La nota de cada frecu ---------- */
function buildNota() {
  $('#nota-clock').innerHTML = `<canvas data-c="fifths" data-st="${st({ demo: true, caption: true })}"></canvas>`;
  $('#notes-grid').innerHTML = FIFTHS.map((f, i) => {
    const n = noteAt(i);
    return `<div class="nchip"><span class="t-label-s c3">${String(i === 0 ? 12 : i).padStart(2, '0')} en el reloj</span>${UI.note(n)}<span class="t-label-s c3">${fmtHz(n.hz)} Hz</span></div>`;
  }).join('');
}

/* ---------- Galería ---------- */
function buildGallery() {
  const root = $('#gallery');
  root.innerHTML = GALLERY.map((f, fi) => `<div class="flow-label"><b>${f.flow}</b><span>${f.items.length} pantallas</span><i></i></div>
    <div class="gal">${f.items.map((it, ii) => `<div class="gitem" data-g="${fi}.${ii}" title="Abrir en el prototipo navegable"><div class="scaler">${phone(it.html())}</div><div class="cap"><em>${it.route}</em><b>${it.title}</b><span>${it.desc}</span></div></div>`).join('')}</div>`).join('');
  root.addEventListener('click', (e) => {
    const g = e.target.closest('.gitem'); if (!g) return;
    e.preventDefault();
    const [fi, ii] = g.dataset.g.split('.').map(Number); const it = GALLERY[fi].items[ii];
    $('#flujo').scrollIntoView({ behavior: 'smooth' });
    setTimeout(() => Proto.open(...it.go), 520);
  }, true);
}

/* ==========================================================================
   Prototipo navegable
   ========================================================================== */
const Proto = {
  token: 0, stack: [], R: null, busy: false, route: 'speaker', bt: true, ipTries: 0,

  init() {
    this.holder = $('#proto-holder');
    this.holder.innerHTML = phone('', { stage: true, attrs: 'data-proto' });
    this.phoneEl = $('.phone', this.holder); this.screen = $('.screen', this.holder); this.stage = $('.stage', this.holder);
    this.fit(); addEventListener('resize', () => this.fit());
    new IntersectionObserver((es) => { this.visible = es[0].isIntersecting; }, { threshold: .3 }).observe(this.holder);
    this.bind();
    setInterval(() => this.tickTimer(), 200);
    this.open('splash');
  },
  fit() {
    const s = Math.min(1, (innerHeight - 56) / 864); this.scale = s;
    this.phoneEl.style.transform = `scale(${s})`; this.phoneEl.style.transformOrigin = '0 0';
    this.holder.style.width = 390 * s + 'px'; this.holder.style.height = 844 * s + 'px';
  },
  later(fn, ms) { const tk = this.token; setTimeout(() => { if (tk === this.token) fn(); }, ms); },
  pointFrom(e) { const r = this.screen.getBoundingClientRect(); const k = r.width / 390; return { x: (e.clientX - r.left) / k, y: (e.clientY - r.top) / k }; },
  pointOf(node) { const a = this.screen.getBoundingClientRect(), b = node.getBoundingClientRect(); const k = a.width / 390; return { x: (b.left + b.width / 2 - a.left) / k, y: (b.top + b.height / 2 - a.top) / k }; },
  inRoom() { return this.cur && this.cur.dataset.screen === 'room' && this.R; },

  render(key, state = {}) {
    if (key === 'room') return this.enterRoom(state);
    this.R = null;
    return el(V[key](state));
  },
  after(key, state = {}) {
    if (key === 'splash') this.later(() => this.go('welcome', {}, 'fade'), 3900);
    if (key === 'scan' && !state.lock) this.later(() => this.lockScan(), 2600);
    if (key === 'room') this.afterRoom(state);
    if (key === 'lobby' && state.born) state.born = false;
  },
  async transition(nv, tr = 'wave', origin) {
    const old = this.cur; this.cur = nv;
    if (tr === 'back' && old) this.stage.insertBefore(nv, old); else this.stage.appendChild(nv);
    hydrate(nv);
    if (!old) return;
    if (REDUCED.on && tr !== 'none') tr = 'fade';
    this.busy = true;
    const F = ease('flow');
    if (tr === 'none') { old.remove(); this.busy = false; return; }
    let main;
    if (tr === 'wave') {
      const { x, y } = origin || { x: 195, y: 640 };
      const r = Math.hypot(Math.max(x, 390 - x), Math.max(y, 844 - y)) + 20;
      main = nv.animate([{ clipPath: `circle(0px at ${x}px ${y}px)` }, { clipPath: `circle(${r}px at ${x}px ${y}px)` }], { duration: 760, easing: OUT });
      nv.animate([{ transform: 'scale(1.08)', filter: 'brightness(1.5)' }, { transform: 'scale(1)', filter: 'brightness(1)' }], { duration: 760, easing: OUT });
      old.animate([{ transform: 'scale(1)', filter: 'brightness(1)' }, { transform: 'scale(.9)', filter: 'brightness(.35)' }], { duration: 760, easing: OUT, fill: 'forwards' });
      const ring = el('<i class="wave-ring"></i>'); this.screen.appendChild(ring);
      ring.animate([{ left: x + 'px', top: y + 'px', width: '0px', height: '0px', opacity: 1 }, { left: x - r + 'px', top: y - r + 'px', width: 2 * r + 'px', height: 2 * r + 'px', opacity: 0 }], { duration: 760, easing: OUT }).finished.then(() => ring.remove());
    } else if (tr === 'slide') {
      main = nv.animate([{ transform: 'translateX(100%)' }, { transform: 'translateX(0)' }], { duration: 560, easing: F });
      old.animate([{ transform: 'translateX(0)', filter: 'brightness(1)' }, { transform: 'translateX(-28%)', filter: 'brightness(.45)' }], { duration: 560, easing: F, fill: 'forwards' });
    } else if (tr === 'back') {
      main = old.animate([{ transform: 'translateX(0)' }, { transform: 'translateX(100%)' }], { duration: 520, easing: F, fill: 'forwards' });
      nv.animate([{ transform: 'translateX(-28%)', filter: 'brightness(.45)' }, { transform: 'translateX(0)', filter: 'brightness(1)' }], { duration: 520, easing: F });
    } else {
      main = nv.animate([{ opacity: 0, transform: 'scale(1.03)', filter: 'blur(6px)' }, { opacity: 1, transform: 'scale(1)', filter: 'blur(0)' }], { duration: 620, easing: OUT });
      old.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 420, easing: 'ease-out', fill: 'forwards' });
    }
    await main.finished.catch(() => {});
    old.remove(); this.busy = false;
  },
  go(key, state = {}, tr = 'wave', origin) {
    if (this.busy) return;
    this.token++; this.closeSheetNow();
    if (key === 'lobby' && this.cur && this.cur.dataset.screen === 'perms') { this.stack = []; state = { born: true }; }
    this.stack.push({ key, state });
    const nv = this.render(key, state);
    this.after(key, state);
    this.transition(nv, tr, origin);
  },
  back() {
    if ($('.sheet', this.screen)) return this.closeSheet();
    if (this.busy || this.stack.length < 2) return;
    this.token++; this.stack.pop();
    const { key, state } = this.stack[this.stack.length - 1];
    const nv = this.render(key, state); this.after(key, state); this.transition(nv, 'back');
  },
  home() {
    this.token++; this.closeSheetNow(); this.stack = [{ key: 'lobby', state: {} }];
    this.transition(this.render('lobby', {}), 'fade');
  },
  open(key, state = {}, sheet, sheetState) {
    this.token++; this.busy = false; this.closeSheetNow();
    this.stack = ['splash', 'welcome', 'name', 'perms', 'lobby'].includes(key) ? [] : [{ key: 'lobby', state: {} }];
    this.stack.push({ key, state });
    const nv = this.render(key, state); this.after(key, state);
    this.transition(nv, this.cur ? 'fade' : 'none');
    if (sheet) this.later(() => (sheet === 'pin' ? this.pickRoom(ROOM.note.s) : this.openSheet(sheet, sheetState)), 650);
  },

  /* ----- Hojas ----- */
  openSheet(name, state = {}) {
    if ($('.sheet', this.screen) || this.busy) return;
    const R = this.R;
    const s = name === 'route' ? { route: R?.route, bt: R?.bt } : name === 'leave' ? { host: R?.host, others: R ? R.ms.nodes.filter(Boolean).length - 1 : 4 } : name === 'quick' ? { geo: R?.geo } : name === 'invite' ? { net: R?.net } : state;
    const sc = el(scrim), sh = el(SH[name](s));
    this.screen.append(sc, sh); hydrate(sh);
    this.cur.classList.remove('restore'); this.cur.classList.add('under');
    sc.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 320, easing: 'ease-out' });
    sh.animate([{ transform: 'translateY(105%)' }, { transform: 'translateY(0)' }], { duration: 640, easing: ease('flow') });
    if (name === 'pin') { this.pin = { digits: '', state: '' }; this.renderPin(); }
    if (name === 'blepin') this.later(() => this.expandToRoom({ kind: 'connecting' }), 2600);
    if (name === 'nfc') this.later(() => { const n = $('.sheet', this.screen); if (!n) return; const f = el(SH.nfc({ found: true })); n.innerHTML = f.innerHTML; hydrate(n); if (navigator.vibrate) navigator.vibrate(20); }, 1800);
  },
  closeSheet() {
    const sh = $('.sheet', this.screen), sc = $('.scrim', this.screen); if (!sh) return;
    this.cur.classList.add('restore'); this.cur.classList.remove('under');
    sc.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 280, fill: 'forwards' }).finished.then(() => sc.remove());
    sh.animate([{ transform: 'translateY(0)' }, { transform: 'translateY(105%)' }], { duration: 400, easing: 'cubic-bezier(.4,0,1,1)', fill: 'forwards' }).finished.then(() => sh.remove());
    this.pickRoom(null, true);
  },
  closeSheetNow() { $$('.sheet, .scrim', this.screen).forEach((n) => n.remove()); if (this.cur) this.cur.classList.remove('under'); },
  async expandToRoom(state = {}) {
    const sh = $('.sheet', this.screen), sc = $('.scrim', this.screen); if (!sh) return;
    this.token++; this.busy = true;
    const top = sh.offsetTop;
    [...sh.children].forEach((c) => c.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 220, fill: 'forwards' }));
    await sh.animate([{ top: top + 'px', left: '8px', right: '8px', bottom: '8px', borderRadius: '40px' }, { top: '0px', left: '0px', right: '0px', bottom: '0px', borderRadius: '58px' }], { duration: 620, easing: ease('flow'), fill: 'forwards' }).finished;
    this.stack.push({ key: 'room', state });
    const nv = this.render('room', state); this.cur.remove(); this.cur = nv; this.stage.appendChild(nv); hydrate(nv);
    this.afterRoom(state);
    nv.animate([{ opacity: 0, transform: 'scale(.97)' }, { opacity: 1, transform: 'scale(1)' }], { duration: 520, easing: OUT });
    sh.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 420, fill: 'forwards' }).finished.then(() => { sh.remove(); sc && sc.remove(); });
    this.busy = false;
  },

  /* ----- Inicio ----- */
  pickRoom(ch, silent) {
    const tv = this.cur && $('canvas[data-c="tuner"]', this.cur);
    if (tv && tv.__st) tv.__st.sel = ch;
    $$('.rtile', this.cur || document.createElement('div')).forEach((t) => { const on = +t.dataset.room === ch; t.classList.toggle('sel', on); const sp = $('canvas[data-c="spark"]', t); if (sp) sp.dataset.on = on ? '1' : '0'; });
    if (!silent && ch != null) this.later(() => this.openSheet('pin'), 380);
  },
  renderPin(pop) {
    const sh = $('.sheet', this.screen); if (!sh) return; const P = this.pin;
    const n = el(UI.pin(P.digits, { state: P.state, attrs: 'data-pin' }));
    if (pop && P.digits.length) n.children[P.digits.length - 1].classList.add('pop');
    $('[data-pin]', sh).replaceWith(n);
    const msg = { error: '<p class="pin-msg err">Código incorrecto. Revisa e intenta otra vez.</p>', busy: '<p class="pin-msg">Verificando con el anfitrión…</p>', ok: '<p class="pin-msg okm">Código correcto · entrando</p>' }[P.state] || `<p class="pin-msg">Código de esta demo: <b class="c1">${ROOM.pin}</b></p>`;
    $('[data-pin-msg]', sh).innerHTML = msg;
  },
  pinKey(k) {
    const P = this.pin; if (!P || P.state === 'busy' || P.state === 'ok') return;
    if (P.state === 'error') { P.digits = ''; P.state = ''; }
    if (k === 'del') P.digits = P.digits.slice(0, -1); else if (/^\d$/.test(k) && P.digits.length < 4) P.digits += k; else return;
    this.renderPin(k !== 'del');
    if (P.digits.length === 4) {
      P.state = 'busy'; this.renderPin();
      this.later(() => { if (P.digits === ROOM.pin) { P.state = 'ok'; this.renderPin(); this.later(() => this.expandToRoom({ kind: 'connecting' }), 700); } else { P.state = 'error'; this.renderPin(); } }, 900);
    }
  },
  async grant(btn) {
    btn.classList.add('loading'); const tk = this.token;
    const rows = $$('[data-perms] .perm', this.cur);
    for (const r of rows) { await new Promise((ok) => setTimeout(ok, 450)); if (tk !== this.token) return; r.classList.add('ok'); $('.ps', r).innerHTML = I('check', 's16'); }
    await new Promise((ok) => setTimeout(ok, 350)); if (tk !== this.token) return;
    const dock = $('.dock', this.cur); dock.innerHTML = UI.btn('Continuar', { iconR: 'arrow', attrs: 'data-go="lobby" data-tr="wave"' }); hydrate(dock);
    dock.firstElementChild.animate([{ transform: 'scale(.9)', opacity: 0 }, { transform: 'scale(1)', opacity: 1 }], { duration: 520, easing: ease('organic') });
  },
  lockScan() {
    const v = this.cur; if (!v || v.dataset.screen !== 'scan') return;
    $('.reticle', v).classList.add('lock');
    const net = !!this.stack.at(-1)?.state?.net;
    const b = $('.scan-bottom', v); b.innerHTML = el(V.scan({ lock: true, net })).querySelector('.scan-bottom').innerHTML; hydrate(b);
    if (navigator.vibrate) navigator.vibrate(18);
  },

  /* ----- Frecu activa ----- */
  enterRoom(s) {
    const kind = s.kind || 'idle';
    const base = kind === 'connecting' || kind === 'alone' ? kind : 'idle';
    const v1 = ['weak', ...GEO_KINDS, 'net', 'mixed'].includes(kind);
    const ms = meshFor(v1 ? kind : base);
    const R = this.R = { host: base === 'alone' || !!s.host, mode: 'ptt', route: this.route, bt: this.bt, muted: false, status: 'ok', speaker: null, event: null, txStart: 0, connecting: base === 'connecting', ms, pst: pttState(base === 'connecting' ? 'connecting' : 'idle'), geo: GEO_KINDS.includes(kind), net: !!s.net || kind === 'net' || kind === 'mixed' };
    if (R.host && base !== 'alone') { ms.nodes[0].host = true; ms.nodes[3] = node('Marta', 'p5'); }
    return el(roomView(v1 ? kind : base, { ms, pst: R.pst, host: R.host, route: R.route, net: R.net }));
  },
  afterRoom(s) {
    const kind = s.kind || 'idle'; const R = this.R;
    if (kind === 'connecting') {
      this.later(() => { R.connecting = false; R.pst.dis = false; R.ms.nodes.forEach((n) => n && (n.state = 'ok')); this.syncRoom(); }, 1500);
      this.later(() => this.addPeer('Ana', 'p2', 1, true), 1900);
      this.later(() => this.addPeer('Sofi', 'p4', 2, true), 2300);
      this.later(() => this.addPeer('Leo', 'p3', 5, true), 2700);
    }
    if (kind === 'alone') { this.later(() => this.addPeer('Ana', 'p2', 3), 2600); this.later(() => this.addPeer('Leo', 'p3', 1), 5200); }
    if (kind === 'rx') this.later(() => this.simSpeak(), 500);
    if (kind === 'open') this.later(() => this.setMode('open'), 450);
    if (kind === 'rec') this.later(() => this.simRec(), 450);
    if (kind === 'weak') this.event(ISLE_V1.weak, 'warn', 4200);
    if (kind === 'behind') this.event(ISLE_V1.behind, 'warn', 4200);
    if (kind === 'msg') this.event(ISLE_V1.msg, '', 4200);
    if (kind === 'sos') this.event(ISLE_V1.sos, 'alert', 60000);
    this.syncRoom();
  },
  syncRoom() {
    const R = this.R, v = this.cur; if (!R || !v || v.dataset.screen !== 'room') return;
    $('.labels', v).innerHTML = meshLabels(R.ms);
    const p = $('.ptt', v), pst = R.pst; const count = R.ms.nodes.filter(Boolean).length;
    p.classList.toggle('tx', !!pst.tx && !pst.dis); p.classList.toggle('open', R.mode === 'open'); p.classList.toggle('muted', R.mode === 'open' && R.muted); p.classList.toggle('dis', !!pst.dis);
    const kind = pst.dis ? (R.status === 'rec' ? 'rec' : 'connecting') : R.mode === 'open' ? (R.muted ? 'muted' : 'open') : pst.tx ? 'tx' : R.speaker ? 'rx' : R.host && count === 1 ? 'alone' : 'idle';
    const [icon, label, hint] = PTT_COPY[kind];
    $('.ptt-core svg', p).outerHTML = I(icon, 's34');
    $('.ptt-core .pl', p).textContent = label;
    $('[data-hint]', v).textContent = kind === 'rx' ? `${R.speaker.name} está hablando · puedes responder` : hint;
    this.isleSync();
  },
  setIsle(kind, inner) {
    const isle = this.cur && $('.isle', this.cur); if (!isle) return;
    const key = kind + '|' + inner; if (isle.__key === key) return; isle.__key = key;
    const w0 = isle.offsetWidth;
    isle.className = 'isle ' + kind; isle.innerHTML = `<span class="in">${inner}</span>`; hydrate(isle);
    const w1 = isle.offsetWidth;
    if (!REDUCED.on) isle.animate([{ width: w0 + 'px' }, { width: w1 + 'px' }], { duration: 640, easing: ease('organic') });
  },
  isleSync() {
    const R = this.R; if (!R) return; const count = R.ms.nodes.filter(Boolean).length;
    if (R.status === 'rec') return this.setIsle('warn', `<i class="dot"></i><span class="t-label" style="color:var(--warn)">Reconectando · <span data-count>${R.recLeft}</span> s</span>`);
    if (R.event && performance.now() < R.event.until) return this.setIsle(R.event.kind || '', R.event.html);
    if (R.connecting) return this.setIsle('', '<canvas class="wave-loader" style="width:34px;height:16px" data-c="wave"></canvas><span class="t-label">Conectando…</span>');
    if (R.pst.tx && R.mode === 'ptt') return this.setIsle('tx', '<i class="dot"></i><span class="t-label">Al aire · <span data-timer>00:00</span></span>');
    if (R.speaker) return this.setIsle('', `${UI.sig(R.speaker.name, { size: 24, color: R.speaker.ck, mode: 'speak', level: 'voice' })}<span class="t-label" style="color:var(--${R.speaker.ck})">${R.speaker.name} · hablando</span>`);
    if (R.mode === 'open') return this.setIsle('', `<i class="dot"></i><span class="t-label">${R.muted ? 'Silenciado' : 'Micrófono abierto'} · ${count}/6</span>`);
    if (R.host && count === 1) return this.setIsle('', '<i class="dot"></i><span class="t-label">Al aire · esperando a tu grupo</span>');
    return this.setIsle('', `<i class="dot"></i><span class="t-label">En línea · ${count}/6</span>`);
  },
  event(html, kind = '', ms = 2600) { const R = this.R; if (!R) return; R.event = { html, kind, until: performance.now() + ms }; this.isleSync(); this.later(() => this.isleSync(), ms + 30); },
  addPeer(name, ck, slot, quiet) {
    const R = this.R; if (!R) return null;
    const order = slot != null ? [slot, 3, 1, 5, 2, 4] : [3, 1, 5, 2, 4];
    const free = order.find((i) => !R.ms.nodes[i]); if (free == null) return null;
    const n = node(name, ck); n.born = Loop.t; R.ms.nodes[free] = n;
    if (!quiet) this.event(`${UI.sig(name, { size: 24, color: ck })}<span class="t-label"><span style="color:var(--${ck})">${name}</span> se unió</span>`);
    this.syncRoom(); return n;
  },
  startTx() {
    const R = this.R; if (!this.inRoom() || R.mode !== 'ptt' || R.pst.dis || R.pst.tx) return;
    const fn = (t) => voice(t, 5);
    R.pst.tx = true; R.pst.levelFn = fn; R.ms.nodes[0].levelFn = fn; R.txStart = performance.now();
    $('.ptt', this.cur).classList.add('down'); this.syncRoom(); if (navigator.vibrate) navigator.vibrate(12);
  },
  endTx() {
    const R = this.R; if (!R || !R.pst.tx || R.mode !== 'ptt') return;
    R.pst.tx = false; R.pst.levelFn = null; R.ms.nodes[0].levelFn = null;
    const p = this.cur && $('.ptt', this.cur); if (p) p.classList.remove('down');
    this.syncRoom();
  },
  tickTimer() {
    const R = this.R; if (!R || !R.pst.tx || R.mode !== 'ptt') return;
    const s = Math.floor((performance.now() - R.txStart) / 1000);
    $$('[data-timer]', this.screen).forEach((n) => { n.textContent = `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`; });
  },
  setMode(mode) {
    const R = this.R; if (!this.inRoom() || R.pst.dis) return;
    R.mode = mode; setSeg($('[data-mode-seg]', this.cur), mode === 'open' ? 1 : 0);
    const me = R.ms.nodes[0]; const fn = (t) => voice(t, 5) * .7;
    R.muted = false; me.muted = false;
    if (mode === 'open') { R.pst.mode = 'open'; R.pst.tx = true; R.pst.levelFn = fn; me.levelFn = fn; if (R.route === 'speaker') this.showEcho(); }
    else { R.pst.mode = 'ptt'; R.pst.tx = false; R.pst.levelFn = null; me.levelFn = null; this.hideEcho(); }
    this.syncRoom();
  },
  toggleMute() {
    const R = this.R; const me = R.ms.nodes[0]; const fn = (t) => voice(t, 5) * .7;
    R.muted = !R.muted; me.muted = R.muted; R.pst.tx = !R.muted; R.pst.levelFn = R.muted ? null : fn; me.levelFn = R.pst.levelFn;
    this.syncRoom();
  },
  showEcho() {
    if ($('.echo', this.cur)) return;
    const e = el(`<div class="echo">${UI.banner('warn', 'headset', '<b>Micrófono abierto con altavoz.</b> Usa audífonos para evitar eco.')}</div>`);
    $('.mesh', this.cur).after(e);
  },
  hideEcho() { const e = this.cur && $('.echo', this.cur); if (e) e.animate([{ opacity: 1 }, { opacity: 0, transform: 'translateY(-8px)' }], { duration: 240, fill: 'forwards' }).finished.then(() => e.remove()); },
  setRoute(r) {
    const R = this.R; if (!R) return; if (r === 'bluetooth' && !R.bt) return;
    R.route = this.route = r; $('.route', this.cur).outerHTML = UI.route(r);
    if (r !== 'speaker') this.hideEcho(); else if (R.mode === 'open') this.showEcho();
    this.closeSheet();
    this.event(`<span style="color:var(--signal);display:flex">${I(ROUTES[r].icon, 's16')}</span><span class="t-label">Audio por ${ROUTES[r].label}</span>`);
  },

  /* ----- Simulaciones ----- */
  ensureRoom(fn) {
    if (this.inRoom()) return fn();
    this.open('room', {}); setTimeout(fn, 900);
  },
  simSpeak() {
    this.ensureRoom(() => {
      const R = this.R; let ana = R.ms.nodes.find((n) => n && n.name === 'Ana') || this.addPeer('Ana', 'p2', null, true);
      if (!ana || R.status === 'rec') return;
      const fn = (t) => voice(t, 2);
      ana.levelFn = fn; R.speaker = ana; R.pst.rx = { get color() { return Theme.c('p2'); }, get level() { return fn(Loop.t); } };
      this.syncRoom();
      this.later(() => { ana.levelFn = null; R.speaker = null; R.pst.rx = null; this.syncRoom(); }, 5200);
    });
  },
  simRec() {
    this.ensureRoom(() => {
      const R = this.R; if (R.status === 'rec') return;
      if (R.pst.tx && R.mode === 'ptt') this.endTx();
      R.status = 'rec'; R.ms.status = 'rec'; R.pst.dis = true; R.recLeft = 4; R.speaker = null; R.pst.rx = null;
      this.syncRoom();
      const tick = () => {
        R.recLeft--;
        if (R.recLeft > 0) { const c = $('[data-count]', this.cur); if (c) c.textContent = R.recLeft; this.later(tick, 1000); return; }
        R.status = 'ok'; R.ms.status = 'ok'; R.pst.dis = false;
        this.event(`<span style="color:var(--signal);display:flex">${I('check', 's16')}</span><span class="t-label">Conexión recuperada</span>`);
        this.syncRoom();
      };
      this.later(tick, 1000);
    });
  },
  simJoin() {
    this.ensureRoom(() => {
      const R = this.R; const pool = [['Marta', 'p5'], ['Sofi', 'p4'], ['Leo', 'p3'], ['Ana', 'p2']];
      const next = pool.find(([n]) => !R.ms.nodes.some((x) => x && x.name === n));
      if (next && this.addPeer(next[0], next[1])) return;
      const i = R.ms.nodes.findIndex((x, k) => x && k !== 0 && !x.host && x !== R.speaker); if (i < 0) return;
      const gone = R.ms.nodes[i]; R.ms.nodes[i] = null;
      this.event(`<span style="color:var(--tx-3);display:flex">${I('exit', 's16')}</span><span class="t-label">${gone.name} salió</span>`); this.syncRoom();
    });
  },
  simBt() {
    this.ensureRoom(() => { this.bt = this.R.bt = true; this.setRoute('bluetooth'); });
  },
  simClose() { this.ensureRoom(() => this.later(() => this.go('closed', { host: false }, 'fade'), 300)); },

  /* ----- V1 · sensores y hardware ----- */
  buzz(p) { if (navigator.vibrate) navigator.vibrate(p); },
  findNode(name) { return this.R && this.R.ms.nodes.find((n) => n && n.name === name); },
  setGeo(on) {
    const R = this.R; if (!R) return; R.geo = on;
    if (on) applyGeo(R.ms); else R.ms.nodes.forEach((n) => { if (n) { n.dist = null; n.behind = false; } });
    const m = $('.mesh', this.cur); const tag = $('.geo-tag', m);
    if (on && !tag) m.append(el(`<div class="geo-tag">${I('pin', 's16')}<span class="t-label-s">Compartes tu ubicación</span></div>`));
    if (!on && tag) tag.remove();
    this.syncRoom();
  },
  simWeak() {
    this.ensureRoom(() => {
      const n = this.findNode('Leo') || this.R.ms.nodes.find((x) => x && !x.me); if (!n) return;
      n.state = 'weak'; this.syncRoom(); this.event(ISLE_V1.weak.replace('Leo', n.name), 'warn', 3600); this.buzz([30, 60, 30]);
      this.later(() => { n.state = 'ok'; this.syncRoom(); }, 6000);
    });
  },
  simMsg() { this.ensureRoom(() => { this.event(ISLE_V1.msg, '', 4200); this.buzz([20, 40, 20]); }); },
  simBehind() {
    this.ensureRoom(() => {
      if (!this.R.geo) this.setGeo(true);
      applyGeo(this.R.ms, { behind: true }); this.syncRoom();
      this.event(ISLE_V1.behind, 'warn', 4200); this.buzz([30, 60, 30]);
      if (!$('.echo', this.cur)) { const b = el(`<div class="echo">${UI.banner('warn', 'pin', '<b>Sofi se quedó atrás.</b> Va a 850 m del grupo, hacia el sur.')}</div>`); this.cur.append(b); }
    });
  },
  simSos() {
    this.ensureRoom(() => {
      if (!this.R.geo) this.setGeo(true);
      if ($('.sos-ov', this.cur)) return;
      const o = el(sosOverlay()); this.cur.append(o); hydrate(o); this.event(ISLE_V1.sos, 'alert', 60000); this.buzz([200, 100, 200, 100, 200]);
    });
  },
  /* ----- Modo internet ----- */
  netClick(t, e) {
    const nt = t.closest('[data-net-tog]');
    if (nt) {
      const net = !nt.classList.contains('on'); const top = this.stack.at(-1); if (top) top.state = { ...top.state, net };
      const pin = $('[data-create-pin]', this.cur).textContent;
      const nv = el(V.create({ net, pin }));
      ['[data-net-row]', '.field-h', '.chv', '.dock'].forEach((q) => { const n = $(q, nv); $(q, this.cur).replaceWith(n); hydrate(n); });
      this.buzz(8); return true;
    }
    const j = t.closest('[data-join="net"]');
    if (j) { if (j.closest('.sheet')) this.expandToRoom({ kind: 'connecting', net: true }); else this.go('room', { kind: 'connecting', net: true }, 'wave', this.pointFrom(e)); return true; }
    const sh = t.closest('[data-share]');
    if (sh) {
      if (sh.classList.contains('loading')) return true;
      sh.classList.add('loading');
      this.later(() => { sh.classList.remove('loading'); $('.lbl', sh).textContent = 'Enlace compartido'; $('svg', sh).outerHTML = I('check'); sh.classList.add('done'); this.buzz(20); }, 1100);
      return true;
    }
    const rt = t.closest('[data-link-retry]');
    if (rt) {
      rt.classList.add('loading');
      this.later(() => { const n = $('.sheet', this.screen); if (!n) return; const f = el(SH.link()); n.innerHTML = f.innerHTML; hydrate(n); this.buzz(20); }, 1400);
      return true;
    }
    return false;
  },
  v1Click(t) {
    const q = t.closest('[data-quick]');
    if (q) { const txt = q.dataset.quick; this.closeSheet(); this.later(() => this.event(ISLE_V1.sent(txt), '', 2600), 380); this.buzz(12); return true; }
    const ack = t.closest('[data-ack]');
    if (ack) {
      const o = ack.closest('.sos-ov'); o.animate([{ opacity: 1 }, { opacity: 0 }], { duration: 320, fill: 'forwards' }).finished.then(() => o.remove());
      if (this.R) { this.R.event = null; this.isleSync(); if (ack.dataset.ack === 'go') this.later(() => this.event(ISLE_V1.sent('Voy en camino'), '', 2600), 340); }
      return true;
    }
    const nw = t.closest('[data-nfc-write]');
    if (nw) {
      const l = $('.lbl', nw); l.textContent = 'Acerca la etiqueta…'; nw.classList.add('loading');
      this.later(() => { nw.classList.remove('loading'); l.textContent = 'Etiqueta grabada'; nw.classList.add('done'); this.buzz(20); }, 1800);
      return true;
    }
    const gt = t.closest('[data-geo-tog]');
    if (gt) {
      const on = !gt.classList.contains('on'); // el clic global aún no lo alterna
      const sub = gt.closest('.row').querySelector('.rt span');
      if (sub) sub.textContent = on ? 'Tu grupo ve a qué distancia y hacia dónde estás.' : 'Apagado. Tu grupo no ve dónde estás.';
      this.setGeo(on); return false;
    }
    return false;
  },
  sosHold(b) {
    b.classList.add('holding');
    const tm = setTimeout(() => {
      b.classList.remove('holding'); this.closeSheet(); this.buzz([200, 100, 200]);
      this.later(() => this.event(ISLE_V1.sosSent, 'alert', 3600), 380);
    }, 1200);
    const stop = () => { clearTimeout(tm); b.classList.remove('holding'); removeEventListener('pointerup', stop); };
    addEventListener('pointerup', stop);
  },

  /* ----- Eventos ----- */
  bind() {
    const sc = this.screen;
    sc.addEventListener('click', (e) => {
      const t = e.target;
      const key = t.closest('[data-key]'); if (key && t.closest('.sheet')) return this.pinKey(key.dataset.key);
      const seg = t.closest('.seg button');
      if (seg) {
        const box = seg.parentElement; const i = +seg.dataset.i;
        if (box.matches('[data-mode-seg]')) return this.setMode(i ? 'open' : 'ptt');
        setSeg(box, i);
        if (box.matches('[data-theme-seg]')) { if (i) this.phoneEl.dataset.theme = i === 1 ? 'light' : 'dark'; else delete this.phoneEl.dataset.theme; return; }
        if (box.matches('[data-os-seg]')) { const ol = $('.stepsl', this.cur); ol.innerHTML = el(V.hotspot({ os: i ? 'ios' : 'android' })).querySelector('.stepsl').innerHTML; ol.animate([{ opacity: 0, transform: 'translateY(8px)' }, { opacity: 1, transform: 'none' }], { duration: 420, easing: OUT }); }
        return;
      }
      if (t.closest('[data-dismiss]')) { const b = t.closest('.echo') || t.closest('.banner'); b.animate([{ opacity: 1 }, { opacity: 0, transform: 'translateY(-8px)' }], { duration: 240, fill: 'forwards' }).finished.then(() => b.remove()); return; }
      if (this.v1Click(t) || this.netClick(t, e)) return;
      const a = t.closest('[data-go],[data-back],[data-sheet],[data-close],[data-grant],[data-regen],[data-create],[data-join],[data-route],[data-leave],[data-home],[data-flash],.ptt-core');
      if (!a) return;
      const d = a.dataset;
      if (a.classList.contains('ptt-core')) { if (this.R && this.R.mode === 'open' && !this.R.pst.dis) this.toggleMute(); return; }
      if (d.go) return this.go(d.go, {}, d.tr || 'wave', this.pointFrom(e));
      if ('back' in d) return this.back();
      if (d.room && d.sheet === 'pin') return this.pickRoom(+d.room);
      if (d.sheet) return this.openSheet(d.sheet);
      if ('close' in d) return this.closeSheet();
      if ('grant' in d) return this.grant(a);
      if ('regen' in d) {
        const pin = String(Math.floor(1000 + Math.random() * 9000)); const n = el(UI.pin(pin, { cls: 'read', attrs: 'data-create-pin' }));
        [...n.children].forEach((c, i) => { c.style.animationDelay = i * 60 + 'ms'; c.classList.add('pop'); });
        $('[data-create-pin]', this.cur).replaceWith(n); a.animate([{ transform: 'rotate(0)' }, { transform: 'rotate(360deg)' }], { duration: 700, easing: ease('organic') }); return;
      }
      if ('create' in d) { a.classList.add('loading'); const o = this.pointOf(a); this.later(() => this.go('room', { kind: 'alone', host: true, net: d.create === 'net' }, 'wave', o), 1100); return; }
      if (d.join === 'qr' && a.closest('.sheet')) return this.expandToRoom({ kind: 'connecting' });
      if (d.join === 'qr') return this.go('room', { kind: 'connecting' }, 'wave', this.pointFrom(e));
      if (d.join === 'ip') {
        a.classList.add('loading');
        this.later(() => {
          a.classList.remove('loading');
          if (this.ipTries++ % 2 === 0) { const sh = $('.sheet', sc); const f = $$('.field', sh)[0]; f.classList.remove('focus'); f.classList.add('error'); if (!$('.banner', sh)) a.before(el(UI.banner('alert', 'alert', '<b>El anfitrión no responde.</b> Revisa que estés en su misma red Wi-Fi. Toca otra vez para reintentar.', { close: false }))); }
          else this.expandToRoom({ kind: 'connecting' });
        }, 1200);
        return;
      }
      if (d.route) return this.setRoute(d.route);
      if (d.leave === 'host') { this.closeSheetNow(); return this.go('closed', { host: true }, 'fade'); }
      if (d.leave === 'peer') return this.home();
      if ('home' in d) return this.home();
      if ('flash' in d) { a.classList.toggle('on'); return; }
    });
    sc.addEventListener('pointerdown', (e) => { if (e.target.closest('.ptt-core') && this.R && this.R.mode === 'ptt') { e.preventDefault(); this.startTx(); } });
    sc.addEventListener('pointerdown', (e) => { const b = e.target.closest('[data-sos]'); if (b) { e.preventDefault(); this.sosHold(b); } });
    addEventListener('pointerup', () => this.endTx()); addEventListener('pointercancel', () => this.endTx());
    sc.addEventListener('input', (e) => {
      if (!e.target.matches('[data-name-input]')) return;
      const v = e.target.value; const cv = $('.sig-stage canvas', this.cur); if (cv) cv.dataset.name = v || '·';
      const c = $('.field-count', this.cur); if (c) c.textContent = `${v.length}/20`;
    });
    addEventListener('keydown', (e) => {
      if (e.code !== 'Space' || e.repeat || !this.visible || e.target.matches('input')) return;
      if (this.inRoom() && this.R.mode === 'ptt') { e.preventDefault(); this.startTx(); }
    });
    addEventListener('keyup', (e) => { if (e.code === 'Space') this.endTx(); });
    $$('[data-sim]').forEach((b) => b.addEventListener('click', () => {
      const k = b.dataset.sim;
      ({ speak: () => this.simSpeak(), rec: () => this.simRec(), join: () => this.simJoin(), bt: () => this.simBt(), close: () => this.simClose(), weak: () => this.simWeak(), msg: () => this.simMsg(), behind: () => this.simBehind(), sos: () => this.simSos() })[k]?.();
    }));
    $$('[data-tour]').forEach((b) => b.addEventListener('click', () => {
      const [k, s, sh] = b.dataset.tour.split(':'); this.open(k, s ? { kind: s, host: s === 'alone' } : {}, sh);
    }));
  },
};

/* ---------- Documento: navegación y ajustes ---------- */
function bindDoc() {
  const links = $$('.side nav a');
  const io2 = new IntersectionObserver((es) => es.forEach((e) => { if (e.isIntersecting) links.forEach((a) => a.classList.toggle('on', a.getAttribute('href') === '#' + e.target.id)); }), { rootMargin: '-35% 0px -60% 0px' });
  $$('main [id]').forEach((s) => s.matches('.sec, .hero') && io2.observe(s));
  $$('[data-theme-set]').forEach((b) => b.addEventListener('click', () => {
    document.documentElement.dataset.theme = b.dataset.themeSet;
    $$('[data-theme-set]').forEach((x) => x.classList.toggle('on', x === b));
  }));
  $$('[data-motion]').forEach((b) => b.addEventListener('click', () => {
    REDUCED.on = b.dataset.motion === 'reduced'; document.documentElement.classList.toggle('reduce-motion', REDUCED.on);
    $$('[data-motion]').forEach((x) => x.classList.toggle('on', x === b));
  }));
}

/* ---------- Arranque ---------- */
function boot() {
  document.documentElement.dataset.theme = document.documentElement.dataset.theme || 'dark';
  installSprings(); Theme.refresh();
  buildComponents(); buildPalette(); buildNota(); buildGallery(); bindDoc();
  hydrate(document);
  Proto.init();
  document.fonts && document.fonts.ready.then(() => $$('.seg').forEach((s) => placeSeg(s)));
}
document.readyState === 'loading' ? document.addEventListener('DOMContentLoaded', boot) : boot();
