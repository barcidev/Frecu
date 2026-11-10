/* ==========================================================================
   FRECU · Portadora — Íconos, constructores de componentes e hidratación
   ========================================================================== */
'use strict';

/* Set de íconos propio: rejilla 24, trazo 1.6, extremos redondos */
const ICONS = {
  mic: '<rect x="9" y="3" width="6" height="11.5" rx="3"/><path d="M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v3M8.5 21h7"/>',
  micOff: '<path d="M15 10V6a3 3 0 0 0-5.7-1.3M9 9.5v2a3 3 0 0 0 5 2.2M5.5 11.5a6.5 6.5 0 0 0 10.9 4.8M18.5 11.5c0 .7-.1 1.3-.3 1.9M12 18v3M8.5 21h7M4 4l16 16"/>',
  walkie: '<rect x="6" y="7" width="12" height="14" rx="3.2"/><path d="M9 7V2.5M9.5 11.5h5M9.5 14.5h5M9.5 17.5h3"/>',
  openMic: '<rect x="9.5" y="4" width="5" height="9.5" rx="2.5"/><path d="M7 10.5a5 5 0 0 0 10 0M12 15.5V19.5M4.6 7.2a9 9 0 0 0 0 7.6M19.4 7.2a9 9 0 0 1 0 7.6"/>',
  speaker: '<path d="M4 9.5h3.2L12 5.5v13l-4.8-4H4z"/><path d="M15.5 9a4 4 0 0 1 0 6M18 6.5a7.6 7.6 0 0 1 0 11"/>',
  earpiece: '<path d="M7.2 3.5h2.6l1.5 4-2 1.6a10.4 10.4 0 0 0 5.6 5.6l1.6-2 4 1.5v2.6a2.2 2.2 0 0 1-2.4 2.2A16 16 0 0 1 5 5.9a2.2 2.2 0 0 1 2.2-2.4z"/>',
  bluetooth: '<path d="M7 7.5l10 9-5 4.5V3l5 4.5-10 9"/>',
  headset: '<path d="M4 15.5V12a8 8 0 0 1 16 0v3.5"/><rect x="3.5" y="14" width="4" height="6.5" rx="1.6"/><rect x="16.5" y="14" width="4" height="6.5" rx="1.6"/>',
  qr: '<rect x="4" y="4" width="6" height="6" rx="1.6"/><rect x="14" y="4" width="6" height="6" rx="1.6"/><rect x="4" y="14" width="6" height="6" rx="1.6"/><path d="M14 14h2.5v2.5M20 14v.01M14 20h.01M17 17.5V20h3v-3"/>',
  scan: '<path d="M4 8.5V6a2 2 0 0 1 2-2h2.5M15.5 4H18a2 2 0 0 1 2 2v2.5M20 15.5V18a2 2 0 0 1-2 2h-2.5M8.5 20H6a2 2 0 0 1-2-2v-2.5M4 12h16"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  sliders: '<path d="M4 7h9M17 7h3M4 17h3M11 17h9"/><circle cx="15" cy="7" r="2"/><circle cx="9" cy="17" r="2"/>',
  back: '<path d="M14.5 5.5L8 12l6.5 6.5"/>',
  chevron: '<path d="M9.5 5.5L16 12l-6.5 6.5"/>',
  down: '<path d="M6.5 9.5l5.5 5.5 5.5-5.5"/>',
  arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
  close: '<path d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>',
  lock: '<rect x="5" y="10.5" width="14" height="10" rx="3"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5M12 14.5V17"/>',
  antenna: '<path d="M12 10.5V21M8.5 21h7"/><circle cx="12" cy="8.2" r="1.9"/><path d="M8.3 4.8a5.2 5.2 0 0 0 0 6.8M15.7 4.8a5.2 5.2 0 0 1 0 6.8M5.4 2.6a8.8 8.8 0 0 0 0 11.2M18.6 2.6a8.8 8.8 0 0 1 0 11.2"/>',
  users: '<circle cx="9" cy="8.5" r="3.5"/><path d="M3 20a6 6 0 0 1 12 0M16 5.3a3.3 3.3 0 0 1 0 6.4M18 14.6a5.6 5.6 0 0 1 3 5.1"/>',
  exit: '<path d="M14 4H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h7M10 12h10M16.5 8.5L20 12l-3.5 3.5"/>',
  regen: '<path d="M19.5 12a7.5 7.5 0 1 1-2.2-5.3M19.5 4v4.5H15"/>',
  check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  alert: '<path d="M10.3 4.6a2 2 0 0 1 3.4 0l7.4 12.8a2 2 0 0 1-1.7 3H4.6a2 2 0 0 1-1.7-3z"/><path d="M12 10v4M12 17v.01"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.5v.01"/>',
  wifi: '<path d="M12 19v.01M8.6 15.4a4.8 4.8 0 0 1 6.8 0M5.6 12.3a9.1 9.1 0 0 1 12.8 0M2.6 9.2a13.4 13.4 0 0 1 18.8 0"/>',
  hotspot: '<rect x="8" y="10" width="8" height="11" rx="2"/><path d="M8.6 6.6a4.8 4.8 0 0 1 6.8 0M6 4a8.5 8.5 0 0 1 12 0"/>',
  globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a13.5 13.5 0 0 1 0 18M12 3a13.5 13.5 0 0 0 0 18"/>',
  flash: '<path d="M13.5 3L5.5 13.5H11L10 21l8.5-11H13z"/>',
  signal: '<circle cx="12" cy="12" r="1.8"/><path d="M8.6 8.6a4.8 4.8 0 0 0 0 6.8M15.4 8.6a4.8 4.8 0 0 1 0 6.8M5.6 5.6a9 9 0 0 0 0 12.8M18.4 5.6a9 9 0 0 1 0 12.8"/>',
  backspace: '<path d="M9 5.5h10a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H9l-6-6.5z"/><path d="M12.5 9.5l4.5 5M17 9.5l-4.5 5"/>',
  edit: '<path d="M14.5 5.5l4 4L8.5 19.5h-4v-4z"/><path d="M12.5 7.5l4 4"/>',
  bell: '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 2h-15z"/><path d="M10 21h4"/>',
  camera: '<path d="M4 8.5a2 2 0 0 1 2-2h2l1.5-2h5l1.5 2h2a2 2 0 0 1 2 2V18a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z"/><circle cx="12" cy="13" r="3.5"/>',
  nodes: '<circle cx="12" cy="5" r="2"/><circle cx="5" cy="19" r="2"/><circle cx="19" cy="19" r="2"/><path d="M12 7v4.5M12 11.5L6.4 17.4M12 11.5l5.6 5.9"/>',
  volume: '<rect x="8" y="2.5" width="8" height="19" rx="3"/><path d="M19.5 7v4M12 6v.01"/>',
  dot: '<circle cx="12" cy="12" r="3" fill="currentColor"/>',
  /* V1 · sensores y hardware */
  pin: '<path d="M12 21s-6.5-6.2-6.5-11.2a6.5 6.5 0 0 1 13 0C18.5 14.8 12 21 12 21z"/><circle cx="12" cy="9.8" r="2.4"/>',
  msg: '<path d="M5 4.5h14a2 2 0 0 1 2 2v8.5a2 2 0 0 1-2 2h-7l-4.5 3.5V17H5a2 2 0 0 1-2-2V6.5a2 2 0 0 1 2-2z"/><path d="M8 9h8M8 12.5h5"/>',
  sos: '<path d="M6.5 18.5V13a5.5 5.5 0 0 1 11 0v5.5"/><path d="M4.5 21h15M12 2.5V5M4.2 6.2l1.8 1.8M19.8 6.2L18 8M12 11v4"/>',
  nfc: '<path d="M9 8.5a5 5 0 0 1 0 7M12.2 6a8.6 8.6 0 0 1 0 12M15.4 3.5a12.2 12.2 0 0 1 0 17"/><circle cx="5.5" cy="12" r="1.4"/>',
  wind: '<path d="M3 9h11a3 3 0 1 0-3-3M3 13h15a3 3 0 1 1-3 3M3 17h6"/>',
  vibrate: '<rect x="8" y="4" width="8" height="16" rx="2.5"/><path d="M4.8 9v6M19.2 9v6M2 10.5v3M22 10.5v3"/>',
  ear: '<path d="M7 9.5a5.5 5.5 0 0 1 11 0c0 3-2.5 4-3 6.5-.4 2.2-1.9 4-4.2 4A3.8 3.8 0 0 1 7 16.2"/><path d="M10 10a2.5 2.5 0 0 1 5 0c0 1.5-1.5 2-1.5 3.5"/>',
  fuel: '<rect x="4" y="4" width="10" height="16.5" rx="2"/><path d="M4 10.5h10M14 8.5l3.2 2.3a2 2 0 0 1 .8 1.6V17a1.5 1.5 0 0 0 3 0V9l-2.5-3"/>',
  flag: '<path d="M5.5 21V3.5M5.5 4.5h11l-2.2 4 2.2 4h-11"/>',
  dir: '<path d="M12 3.5l5.5 16-5.5-3.6-5.5 3.6z" fill="currentColor" stroke="none"/>',
};
const I = (n, cls = '') => `<svg class="ic ${cls}" viewBox="0 0 24 24" aria-hidden="true">${ICONS[n] || ''}</svg>`;

/* ---------- Constructores (cada uno = un widget Flutter) ---------- */
const UI = {
  btn(label, o = {}) {
    const v = o.v || 'primary';
    return `<button class="btn btn-${v} ${o.cls || ''}" ${o.attrs || ''}>${o.icon ? I(o.icon) : ''}<span class="lbl">${label}</span>${o.iconR ? I(o.iconR) : ''}<canvas class="wave" data-c="wave" data-col="${v === 'primary' ? 'ink' : 'signal'}"></canvas></button>`;
  },
  ibtn(icon, o = {}) { return `<button class="ibtn ${o.cls || ''}" aria-label="${o.label || icon}" ${o.attrs || ''}>${I(icon)}</button>`; },
  label(t, cls = '') { return `<span class="t-label ${cls}">${t}</span>`; },
  sig(name, o = {}) {
    const s = o.size || 64;
    return `<canvas class="sig ${o.cls || ''}" style="width:${s}px;height:${s}px" data-c="sig" data-name="${name}" data-color="${o.color || 'signal'}" data-mode="${o.mode || 'idle'}" data-level="${o.level ?? ''}" data-r="${o.r || .42}"></canvas>`;
  },
  field(lbl, value, o = {}) {
    return `<label class="field ${o.cls || ''}"><span class="field-l">${UI.label(lbl)}${o.right ? `<span class="t-label-s">${o.right}</span>` : ''}</span>
      <span class="field-box">${o.icon ? I(o.icon, 's18 c3') : ''}<input ${o.mono ? 'class="mono"' : ''} value="${value}" placeholder="${o.ph || ''}" ${o.attrs || ''}>${o.count ? `<span class="field-count">${o.count}</span>` : ''}</span>
      ${o.help ? `<span class="field-h">${o.help}</span>` : ''}</label>`;
  },
  pin(digits, o = {}) {
    const cells = [0, 1, 2, 3].map((i) => `<i class="${i === digits.length && !o.state ? 'cur' : ''}">${digits[i] ?? ''}</i>`).join('');
    return `<div class="pin ${o.state || ''} ${o.cls || ''}" ${o.attrs || ''}>${cells}</div>`;
  },
  keypad(o = {}) {
    const k = ['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((d) => `<button data-key="${d}">${d}</button>`).join('');
    return `<div class="keys" ${o.attrs || ''}>${k}<button class="fn" data-key="regen" aria-label="Generar">${o.left || ''}</button><button data-key="0">0</button><button class="fn" data-key="del" aria-label="Borrar">${I('backspace')}</button></div>`;
  },
  seg(items, on = 0, o = {}) {
    return `<div class="seg ${o.cls || ''}" ${o.attrs || ''}><span class="seg-thumb"></span>${items.map((it, i) => `<button class="${i === on ? 'on' : ''}" data-i="${i}" ${it.attrs || ''}>${it.icon ? I(it.icon, 's18') : ''}<span class="t-label">${it.label}</span></button>`).join('')}</div>`;
  },
  tog(on, attrs = '') { return `<button class="tog ${on ? 'on' : ''}" role="switch" aria-checked="${on}" ${attrs}></button>`; },
  pill(text, kind = 'ok') { return `<span class="pill ${kind} t-label-s"><i class="dot"></i>${text}</span>`; },
  tag(text, kind = '') { return `<span class="tag ${kind} t-label-s">${text}</span>`; },
  route(route) {
    const r = ROUTES[route];
    return `<button class="route" data-sheet="route">${I(r.icon, 's18')}<span class="rl"><b>${r.label}</b></span><span class="bars"><i></i><i></i><i></i></span>${I('down', 's16 c3')}</button>`;
  },
  note(n, cls = '') { return `<span class="note ${cls}"><b class="t-dot">${n.name.replace(/([♯♭])/, '<i class="acc">$1</i>')}</b><sub class="t-label-s">${n.oct}</sub></span>`; },
  rtile(room, o = {}) {
    const n = room.note;
    return `<button class="rtile ${o.sel ? 'sel' : ''}" data-room="${n.s}" ${o.attrs || ''}>
      <span class="chbox"><canvas data-c="spark" data-ch="${n.s}" data-on="${o.sel ? 1 : 0}"></canvas><small class="t-label-s c3">${fmtHz(n.hz)} Hz</small>${UI.note(n)}</span>
      <span class="ri"><b>${room.name}</b><span class="t-label-s">${room.ble ? `${I('bluetooth', 's16')}Cerca · por Bluetooth` : `${I('lock', 's16')}${room.ip}`}</span></span>
      <span class="go">${I('arrow', 's18')}</span></button>`;
  },
  perm(icon, title, desc, state = '') {
    const st = state === 'ok' ? I('check', 's16') : state === 'deny' ? '<span class="t-label-s">Ajustes</span>' : '';
    return `<div class="perm ${state}"><span class="pic">${I(icon)}</span><span class="pt"><b>${title}</b><span>${desc}</span></span><span class="ps">${st}</span></div>`;
  },
  steps(n, on) { return `<span class="steps">${Array.from({ length: n }, (_, i) => `<i class="${i === on ? 'on' : i < on ? 'done' : ''}"></i>`).join('')}</span>`; },
  banner(kind, icon, html, o = {}) { return `<div class="banner ${kind} ${o.cls || ''}">${I(icon, 's18')}<div>${html}</div>${o.close === false ? '<span></span>' : `<button class="x" data-dismiss>${I('close', 's16')}</button>`}</div>`; },
  toast(html, o = {}) { return `<div class="toast ${o.cls || ''}">${o.sig ? UI.sig(o.sig, { size: 30, color: o.color || 'p2', mode: 'speak', level: 'voice' }) : `<span class="tic" style="background:rgba(var(--signal-rgb),.14);color:var(--signal-fg)">${I(o.icon || 'check', 's16')}</span>`}<span>${html}</span></div>`; },
  opt(icon, title, sub, o = {}) { return `<button class="opt ${o.on ? 'on' : ''} ${o.dis ? 'dis' : ''}" ${o.attrs || ''}><span class="oic">${I(icon)}</span><span class="ot"><b>${title}</b><span class="t-label-s">${sub}</span></span><span class="ock">${o.on ? I('check', 's16') : ''}</span></button>`; },
  row(title, sub, right) { return `<div class="row"><span class="rt"><b>${title}</b>${sub ? `<span>${sub}</span>` : ''}</span><span class="rv">${right || I('chevron', 's18 c3')}</span></div>`; },
  isle(kind, html) { return `<div class="isle-wrap"><div class="isle ${kind}" data-theme="dark"><span class="in">${html}</span></div></div>`; },
};

const ROUTES = {
  speaker: { icon: 'speaker', label: 'Altavoz', sub: 'Salida' },
  earpiece: { icon: 'earpiece', label: 'Auricular', sub: 'Salida' },
  bluetooth: { icon: 'headset', label: 'Sena 50S', sub: 'Bluetooth' },
};

/* ---------- Hidratación de canvas declarativos ---------- */
const STATES = new Map(); let _stN = 0;
const st = (obj) => { const id = 's' + (++_stN); STATES.set(id, obj); return id; };
function levelFrom(spec, t, seed) {
  if (spec === 'voice') return voice(t, seed);
  if (spec === 'soft') return voice(t, seed) * .55;
  const n = parseFloat(spec); return Number.isFinite(n) ? n : 0;
}
function colorOf(key) { return key && key.startsWith('#') ? key : Theme.c(key || 'signal'); }

const DRAW = {
  sig(cv, t) {
    const S = surface(cv); if (!S) return;
    const name = cv.dataset.name;
    if (cv.__name !== name) { cv.__name = name; cv.__p = sigParams(name); }
    const lvl = levelFrom(cv.dataset.level, t, (cv.__p.phase * 10) | 0);
    let mode = cv.dataset.mode || 'idle';
    if ((mode === 'idle' || mode === 'speak') && lvl > .04) mode = 'speak';
    drawSig(S.c, S.w / 2, S.h / 2, Math.min(S.w, S.h) * parseFloat(cv.dataset.r || .42), cv.__p, t, { color: colorOf(cv.dataset.color), level: lvl, mode });
  },
  wave(cv, t) { const S = surface(cv); if (S) drawWave(S.c, S.w, S.h, t, cv.dataset.col === 'ink' ? '#0A0C05' : Theme.c('signal')); },
  fifths(cv, t) { const S = surface(cv); if (S) drawFifths(S.c, S.w, S.h, cv.__st, t); },
  tuner(cv, t) { const S = surface(cv); if (S) drawTuner(S.c, S.w, S.h, cv.__st, t); },
  ptt(cv, t) { const S = surface(cv); if (S) drawPtt(S.c, S.w, S.h, cv.__st, t); },
  mesh(cv, t) { const S = surface(cv); if (S) drawMesh(S.c, S.w, S.h, cv.__st, t); },
  orbit(cv, t) { const S = surface(cv); if (S) drawOrbit(S.c, S.w, S.h, cv.__st, t); },
  splash(cv, t) { const S = surface(cv); if (S) drawSplash(S.c, S.w, S.h, t - (cv.__t0 || 0), { a: 2, b: 3, phase: .6 }); },
  hotspot(cv, t) { const S = surface(cv); if (S) drawHotspot(S.c, S.w, S.h, t); },
  flat(cv, t) { const S = surface(cv); if (S) drawFlat(S.c, S.w, S.h, t); },
  cam(cv, t) { const S = surface(cv); if (S) drawCamera(S.c, S.w, S.h, t); },
  spark(cv, t) { const S = surface(cv); if (S) drawSpark(S.c, S.w, S.h, t, +cv.dataset.ch, cv.dataset.on === '1'); },
  pillar(cv, t) { const S = surface(cv); if (S) drawPillar(S.c, S.w, S.h, +cv.dataset.k, t); },
  curve(cv, t) { const S = surface(cv); if (!S) return; cv.__fn = cv.__fn || curveFn(cv.dataset.k); drawCurve(S.c, S.w, S.h, cv.__fn, t, +cv.dataset.dur); },
  brand(cv, t) { const S = surface(cv); if (S) drawSig(S.c, S.w / 2, S.h / 2, S.w * .42, { a: 2, b: 3, phase: .6, rot: 0, drift: .12 }, t, { color: Theme.c('signal'), n: 180 }); },
  hero(cv, t) {
    const S = surface(cv); if (!S) return; const { c, w, h } = S; const cx = w / 2, cy = h / 2;
    for (let i = 0; i < 120; i++) {
      const a = i / 120 * TAU; const r0 = w * .45, r1 = r0 + (i % 10 ? 4 : 12);
      c.strokeStyle = ink(i % 10 ? .1 : .25); c.lineWidth = 1;
      c.beginPath(); c.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0); c.lineTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1); c.stroke();
    }
    const lv = voice(t, 2);
    drawSig(c, cx, cy, w * .34, { a: 3, b: 2, phase: 1.2, rot: .2, drift: .05 }, t, { color: Theme.c('p1'), level: 0, n: 300, alpha: .55 });
    drawSig(c, cx, cy, w * .3, { a: 4, b: 5, phase: 2, rot: -.3, drift: .04 }, t, { color: Theme.c('p2'), level: 0, n: 300, alpha: .4 });
    drawSig(c, cx, cy, w * .36, { a: 2, b: 3, phase: .6, rot: 0, drift: .08 }, t, { color: Theme.c('signal'), level: lv, mode: 'speak', n: 320 });
  },
  qr(cv) {
    const w = cv.clientWidth; if (!w || cv.__done === w) return; cv.__done = w;
    cv.width = cv.height = Math.round(w * DPR); const c = cv.getContext('2d'); c.setTransform(DPR, 0, 0, DPR, 0, 0); drawQR(c, w, +cv.dataset.seed || 7);
  },
};

function hydrate(root) {
  root.querySelectorAll('canvas[data-c]').forEach((cv) => {
    if (cv.__hyd) return; cv.__hyd = true;
    const fn = DRAW[cv.dataset.c]; if (!fn) return;
    if (cv.dataset.st) cv.__st = STATES.get(cv.dataset.st);
    if (cv.dataset.c === 'splash') cv.__t0 = Loop.t;
    animate(cv, (t) => fn(cv, t));
  });
  root.querySelectorAll('.seg').forEach(placeSeg);
}

function placeSeg(seg, animateIt) {
  const btns = [...seg.querySelectorAll('button')]; const on = Math.max(0, btns.findIndex((b) => b.classList.contains('on')));
  const th = seg.querySelector('.seg-thumb'); const w = (seg.clientWidth - 8) / btns.length;
  if (!seg.clientWidth) { requestAnimationFrame(() => placeSeg(seg)); return; }
  th.style.width = w + 'px'; th.style.transform = `translateX(${on * w}px)`;
  if (animateIt) { th.classList.remove('stretch'); void th.offsetWidth; th.classList.add('stretch'); }
}
function setSeg(seg, i) {
  seg.querySelectorAll('button').forEach((b, k) => b.classList.toggle('on', k === i));
  placeSeg(seg, true);
}

/* ---------- Microinteracciones globales ---------- */
document.addEventListener('pointerdown', (e) => {
  const b = e.target.closest('.btn'); if (!b) return;
  const r = b.getBoundingClientRect(); const sx = b.offsetWidth / r.width || 1;
  b.style.setProperty('--x', (e.clientX - r.left) * sx + 'px'); b.style.setProperty('--y', (e.clientY - r.top) * sx + 'px');
  b.classList.add('lit');
});
['pointerup', 'pointercancel', 'pointerleave'].forEach((ev) => document.addEventListener(ev, () => document.querySelectorAll('.btn.lit').forEach((b) => b.classList.remove('lit')), true));
document.addEventListener('click', (e) => {
  const sb = e.target.closest('.seg button');
  if (sb && !sb.closest('[data-proto]')) setSeg(sb.parentElement, +sb.dataset.i);
  const tg = e.target.closest('.tog');
  if (tg) { tg.classList.toggle('on'); tg.setAttribute('aria-checked', tg.classList.contains('on')); }
  const dm = e.target.closest('[data-dismiss]');
  if (dm && !dm.closest('[data-proto]')) { const bn = dm.closest('.banner'); bn.animate([{ opacity: 1 }, { opacity: 0, transform: 'translateY(-6px)' }], { duration: 240, easing: 'ease-out' }).onfinish = () => bn.remove(); }
});
