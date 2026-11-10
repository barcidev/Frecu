/* ==========================================================================
   FRECU · Portadora — Motor: ruido, resortes, bucle y dibujantes de canvas
   Todo lo que aquí se dibuja tiene equivalente en Flutter con CustomPainter.
   ========================================================================== */
'use strict';

const TAU = Math.PI * 2;
const DPR = Math.min(window.devicePixelRatio || 1, 2);
const REDUCED = { on: matchMedia('(prefers-reduced-motion: reduce)').matches };

const clamp = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
const lerp = (a, b, t) => a + (b - a) * t;
const smooth = (a, b, v) => { const t = clamp((v - a) / (b - a)); return t * t * (3 - 2 * t); };
const easeOut = (t) => 1 - Math.pow(1 - clamp(t), 4);
const easeInOut = (t) => { t = clamp(t); return t < .5 ? 8 * t ** 4 : 1 - Math.pow(-2 * t + 2, 4) / 2; };

/* ---------- Hash y aleatorio determinista ---------- */
function hash(str) {
  let h = 2166136261 >>> 0;
  for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619); }
  return h >>> 0;
}
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/* ---------- Ruido Perlin 2D (movimiento orgánico) ---------- */
const PERM = new Uint8Array(512);
(() => {
  const r = rng(1337); const p = [...Array(256).keys()];
  for (let i = 255; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [p[i], p[j]] = [p[j], p[i]]; }
  for (let i = 0; i < 512; i++) PERM[i] = p[i & 255];
})();
function grad(h, x, y) {
  switch (h & 7) {
    case 0: return x + y; case 1: return -x + y; case 2: return x - y; case 3: return -x - y;
    case 4: return x; case 5: return -x; case 6: return y; default: return -y;
  }
}
function noise2(x, y) {
  const fx = Math.floor(x), fy = Math.floor(y);
  const X = fx & 255, Y = fy & 255; x -= fx; y -= fy;
  const u = x * x * x * (x * (x * 6 - 15) + 10), v = y * y * y * (y * (y * 6 - 15) + 10);
  const aa = PERM[PERM[X] + Y], ab = PERM[PERM[X] + Y + 1], ba = PERM[PERM[X + 1] + Y], bb = PERM[PERM[X + 1] + Y + 1];
  return lerp(lerp(grad(aa, x, y), grad(ba, x - 1, y), u), lerp(grad(ab, x, y - 1), grad(bb, x - 1, y - 1), u), v);
}
const noise1 = (x) => noise2(x, .37);

/* Envolvente de voz simulada: sílabas + frases + pausas */
function voice(t, seed = 0) {
  const s = seed * 17.3;
  const syl = Math.max(0, Math.sin(t * TAU * 4.1 + noise1(t * .8 + s) * 4));
  const phrase = smooth(-.12, .22, noise1(t * .45 + s + 9));
  const grain = .62 + .38 * noise1(t * 6 + s);
  return clamp(syl * phrase * grain * 1.35);
}

/* ---------- Resortes → easing CSS linear() (equivale a SpringDescription) ---------- */
const SPRINGS = {
  press: { stiffness: 600, ratio: .62 },
  flow: { stiffness: 220, ratio: .9 },
  organic: { stiffness: 160, ratio: .5 },
};
function springSamples({ stiffness, ratio }, n = 72) {
  const damping = 2 * ratio * Math.sqrt(stiffness);
  const dt = 1 / 240; let x = 0, v = 0; const out = [0];
  let steps = 0;
  while (steps < 240 * 4) {
    const a = -stiffness * (x - 1) - damping * v; v += a * dt; x += v * dt; steps++; out.push(x);
    if (steps > 30 && Math.abs(x - 1) < .0008 && Math.abs(v) < .005) break;
  }
  const res = [];
  for (let i = 0; i <= n; i++) res.push(out[Math.round(i / n * (out.length - 1))]);
  res[n] = 1;
  return { values: res, seconds: steps * dt };
}
function installSprings() {
  if (!CSS.supports('transition-timing-function', 'linear(0, 1)')) return;
  const root = document.documentElement.style;
  for (const [k, s] of Object.entries(SPRINGS)) {
    const { values } = springSamples(s);
    root.setProperty(`--spring-${k}`, `linear(${values.map((v) => v.toFixed(4)).join(', ')})`);
  }
}

/* ---------- Colores del tema (se releen al cambiar acento) ---------- */
const THEME_KEYS = ['signal', 'signal-fg', 'ink-rgb', 'warn', 'alert', 'p1', 'p2', 'p3', 'p4', 'p5', 'tx-1', 'tx-2', 'tx-3', 'tx-4', 'bg-0', 'bg-1', 'bg-2', 'bg-3'];
const Theme = {
  caches: {}, mode: 'dark',
  refresh() {
    for (const m of ['dark', 'light']) {
      let p = document.getElementById('theme-probe-' + m);
      if (!p) { p = document.createElement('i'); p.id = 'theme-probe-' + m; p.dataset.theme = m; p.hidden = true; document.body.appendChild(p); }
      const cs = getComputedStyle(p); const c = {};
      for (const k of THEME_KEYS) c[k] = cs.getPropertyValue('--' + k).trim();
      c['signal-fill'] = c.signal; c.signal = c['signal-fg'];
      this.caches[m] = c;
    }
  },
  use(el) { const host = el.closest('[data-theme]'); this.mode = host ? host.dataset.theme : 'dark'; },
  c(k) { const c = this.caches[this.mode] || {}; return c[k] || k; },
};
const ink = (a) => `rgba(${Theme.c('ink-rgb')},${a})`;
// El brillo de la señal siempre es verde: de noche coincide con el trazo; de día el trazo es tinta y el halo, marcatexto
const glow = (col) => (col === Theme.c('signal') ? Theme.c('signal-fill') : col);
const dayK = () => (Theme.mode === 'light' ? 2.2 : 1);
const _rgb = {};
function rgba(hex, a) {
  if (!hex) return `rgba(255,255,255,${a})`;
  if (hex.startsWith('rgb')) return hex;
  let v = _rgb[hex];
  if (!v) {
    const h = hex.replace('#', '');
    const n = parseInt(h.length === 3 ? h.split('').map((x) => x + x).join('') : h, 16);
    v = _rgb[hex] = [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  return `rgba(${v[0]},${v[1]},${v[2]},${a})`;
}
const PCOLORS = ['signal', 'p1', 'p2', 'p3', 'p4', 'p5'];

/* ---------- Bucle de animación con visibilidad ---------- */
const Loop = {
  items: new Set(), t0: performance.now(), started: false, t: 0,
  add(it) { this.items.add(it); if (!this.started) { this.started = true; requestAnimationFrame(Loop.tick); } return it; },
  tick(now) {
    const t = Math.max(0, (now - Loop.t0) / 1000); Loop.t = t; // el primer cuadro puede llegar antes de t0
    for (const it of Loop.items) {
      if (!it.el.isConnected) { Loop.items.delete(it); io.unobserve(it.el); continue; }
      if (!it.visible) continue;
      Theme.use(it.el);
      it.draw(REDUCED.on ? (it.frozen ?? (it.frozen = t)) : t, it);
    }
    requestAnimationFrame(Loop.tick);
  },
};
const io = new IntersectionObserver((es) => es.forEach((e) => { if (e.target.__loop) e.target.__loop.visible = e.isIntersecting; }), { rootMargin: '160px' });
function animate(el, draw, extra = {}) {
  const it = Object.assign({ el, draw, visible: true }, extra);
  el.__loop = it; io.observe(el); Loop.add(it); return it;
}
function surface(cv) {
  const w = cv.clientWidth, h = cv.clientHeight;
  if (!w || !h) return null;
  const W = Math.round(w * DPR), H = Math.round(h * DPR);
  if (cv.width !== W || cv.height !== H) { cv.width = W; cv.height = H; }
  const c = cv.getContext('2d');
  c.setTransform(DPR, 0, 0, DPR, 0, 0); c.clearRect(0, 0, w, h);
  return { c, w, h };
}

/* ---------- Nota de la frecu: la hora sobre el círculo de quintas ---------- */
const FIFTHS = [['Do', 'C', 0], ['Sol', 'G', 7], ['Re', 'D', 2], ['La', 'A', 9], ['Mi', 'E', 4], ['Si', 'B', 11], ['Fa♯', 'F♯', 6], ['Re♭', 'D♭', 1], ['La♭', 'A♭', 8], ['Mi♭', 'E♭', 3], ['Si♭', 'B♭', 10], ['Fa', 'F', 5]].map(([es, en, pc]) => ({ es, en, pc }));
const PC_NAME = []; FIFTHS.forEach((f) => { PC_NAME[f.pc] = f.es; });
function noteAt(hour, minute = 0, taken = []) {
  let i = hour % 12; const oct = hour < 12 ? 4 : 5;
  for (let k = 0; k < 12 && taken.includes(`${FIFTHS[i].pc}/${oct}`); k++) i = (i + 1) % 12;
  const f = FIFTHS[i]; const midi = 12 * (oct + 1) + f.pc;
  return { name: f.es, en: f.en, oct, pc: f.pc, s: (oct - 4) * 12 + f.pc, hz: 440 * 2 ** ((midi - 69) / 12), pos: i, hour, minute };
}
const fmtHz = (hz) => hz.toFixed(1).replace('.', ',');

/* ==========================================================================
   Dibujantes
   ========================================================================== */

/* Firma de señal (Lissajous) — identidad de cada participante */
const RATIOS = [[1, 2], [2, 3], [3, 4], [3, 2], [1, 3], [2, 5], [4, 5], [3, 5], [5, 4], [4, 3]];
function sigParams(name) {
  const h = hash((name || '·').trim().toLowerCase());
  const r = rng(h);
  const [a, b] = RATIOS[h % RATIOS.length];
  return { a, b, phase: r() * TAU, rot: (r() - .5) * .7, drift: .07 + r() * .09 };
}
const _pts = new Float32Array(2 * 400);
function drawSig(c, cx, cy, R, p, t, o = {}) {
  const lvl = o.level || 0; const col = o.color || Theme.c('signal');
  const mode = o.mode || 'idle'; const alpha = o.alpha ?? 1;
  const N = o.n || 220;
  const flat = mode === 'muted' ? .05 : mode === 'off' ? 0.02 : 1;
  const amp = R * (.74 + .2 * lvl);
  const d = p.phase + t * (p.drift + lvl * 1.4);
  for (let i = 0; i <= N; i++) {
    const u = i / N * TAU;
    const wob = 1 + lvl * (.09 * Math.sin(u * 9 + t * 13) + .06 * noise2(Math.cos(u) * 1.4 + t * 2.2, Math.sin(u) * 1.4));
    _pts[i * 2] = Math.sin(p.a * u + d) * amp * wob;
    _pts[i * 2 + 1] = Math.sin(p.b * u) * amp * wob * flat;
  }
  c.save(); c.translate(cx, cy); c.rotate(p.rot); c.lineJoin = 'round'; c.lineCap = 'round';
  if (lvl > .02 && mode === 'speak') { c.shadowColor = glow(col); c.shadowBlur = 4 + 16 * lvl; }
  const base = mode === 'off' ? .16 : mode === 'link' ? .32 : mode === 'muted' ? .45 : .4 + .55 * lvl;
  c.strokeStyle = rgba(col, base * alpha);
  c.lineWidth = Math.max(.9, R * .032) * (1 + lvl * .9);
  if (mode === 'link') c.setLineDash([R * .06, R * .1]);
  c.beginPath(); c.moveTo(_pts[0], _pts[1]);
  for (let i = 1; i <= N; i++) c.lineTo(_pts[i * 2], _pts[i * 2 + 1]);
  c.stroke(); c.setLineDash([]); c.shadowBlur = 0;
  if (mode !== 'off') { // cometa de fósforo que recorre la curva
    const K = 30, len = .2, head = (t * (.16 + lvl * .7) + p.phase) % 1;
    c.lineWidth = Math.max(1.2, R * .05) * (1 + lvl * .6);
    for (let k = 0; k < K; k++) {
      const f = ((head - len * k / K) % 1 + 1) % 1; const i = Math.floor(f * N);
      c.strokeStyle = rgba(col, (1 - k / K) * (mode === 'link' ? .5 : .95) * alpha);
      c.beginPath(); c.moveTo(_pts[i * 2], _pts[i * 2 + 1]); c.lineTo(_pts[i * 2 + 2], _pts[i * 2 + 3]); c.stroke();
    }
  }
  c.restore();
}

/* Loader de onda (reemplaza los spinners) */
function drawWave(c, w, h, t, col, amp = .36) {
  c.lineCap = 'round';
  for (let k = 0; k < 2; k++) {
    c.beginPath();
    for (let x = 0; x <= w; x += 1) {
      const e = Math.sin(Math.PI * x / w);
      const y = h / 2 + Math.sin(x / w * TAU * 1.6 - t * 7 - k * 1.2) * h * amp * e * (k ? .55 : 1);
      x ? c.lineTo(x, y) : c.moveTo(x, y);
    }
    c.strokeStyle = rgba(col, k ? .35 : .95); c.lineWidth = k ? 1.2 : 2; c.stroke();
  }
}

/* Sintonizador: teclado de dos octavas (Do4–Si5); cada frecu es un pico sobre su nota */
const WHITE = [0, 2, 4, 5, 7, 9, 11];
function keyX(n, x0, W) {
  const o = Math.floor(n / 12), r = n % 12; const wi = WHITE.indexOf(r);
  return wi >= 0 ? x0 + (o * 7 + wi + .5) * W : x0 + (o * 7 + WHITE.indexOf(r - 1) + 1) * W;
}
function drawTuner(c, w, h, st, t) {
  const sig = Theme.c('signal');
  const x0 = 16, x1 = w - 16, W = (x1 - x0) / 14, kh = 18;
  const ky = h - kh - 22, base = ky - 6;
  const lit = new Map(st.rooms.map((r) => [r.s, st.sel === r.s ? 1 : .5]));
  for (let i = 0; i < 14; i++) { // teclas blancas
    const x = x0 + i * W; const L = lit.get(WHITE[i % 7] + 12 * Math.floor(i / 7));
    c.fillStyle = L ? rgba(sig, .1 + .25 * L) : ink(.03); c.fillRect(x + 1, ky, W - 2, kh);
    c.strokeStyle = L ? rgba(sig, .4 + .5 * L) : ink(.13); c.lineWidth = 1; c.strokeRect(x + 1.5, ky + .5, W - 3, kh - 1);
  }
  for (let o = 0; o < 2; o++) for (const r of [1, 3, 6, 8, 10]) { // teclas negras
    const L = lit.get(o * 12 + r); const x = keyX(o * 12 + r, x0, W);
    c.fillStyle = L ? rgba(sig, .55 + .4 * L) : ink(.3); c.fillRect(x - W * .28, ky, W * .56, kh * .58);
  }
  c.font = '500 8.5px "Martian Mono", monospace'; c.fillStyle = ink(.38); c.textBaseline = 'alphabetic';
  c.textAlign = 'left'; c.fillText('DO4', x0, h - 7); c.fillText('DO5', x0 + 7 * W, h - 7); c.textAlign = 'right'; c.fillText('SI5', x1, h - 7);
  // piso de ruido
  c.beginPath();
  for (let x = x0; x <= x1; x += 2) {
    const n = Math.abs(noise2(x * .045, t * .9)) * 9 + Math.abs(noise2(x * .3, t * 2.4)) * 3;
    const y = base - 2 - n * (st.rooms.length ? .7 : 1);
    x === x0 ? c.moveTo(x, y) : c.lineTo(x, y);
  }
  c.strokeStyle = ink(.22); c.lineWidth = 1; c.stroke();
  // picos sobre la nota de cada frecu
  for (const r of st.rooms) {
    const age = t - (r.born ?? -10); const g = r.born == null ? 1 : clamp(1 - Math.exp(-age * 4) * Math.cos(age * 9));
    const sel = st.sel === r.s;
    const A = (h - 96) * g * (sel ? 1.06 : .8) * (.93 + .07 * Math.sin(t * 3 + r.s));
    const cx = keyX(r.s, x0, W), sd = 7;
    const grd = c.createLinearGradient(0, base - A, 0, base);
    const fill = Theme.c('signal-fill');
    grd.addColorStop(0, rgba(fill, (sel ? .38 : .2) * dayK())); grd.addColorStop(1, rgba(fill, 0));
    c.beginPath(); c.moveTo(cx - sd * 4, base);
    for (let x = cx - sd * 4; x <= cx + sd * 4; x += 1) c.lineTo(x, base - A * Math.exp(-((x - cx) ** 2) / (2 * sd * sd)) - Math.abs(noise2(x * .2, t * 3)) * 2);
    c.lineTo(cx + sd * 4, base); c.closePath(); c.fillStyle = grd; c.fill();
    c.shadowColor = glow(sig); c.shadowBlur = sel ? 14 : 8; c.strokeStyle = rgba(sig, sel ? 1 : .75); c.lineWidth = 1.4; c.stroke(); c.shadowBlur = 0;
    c.font = '600 9px "Martian Mono", monospace'; c.fillStyle = rgba(sig, sel ? 1 : .8); c.textAlign = 'center'; c.fillText(r.label, cx, base - A - 8);
  }
  // aguja
  const n = st.needle || (st.needle = { x: .5, v: 0 });
  const target = st.sel != null ? (keyX(st.sel, x0, W) - x0) / (x1 - x0) : .5 + .44 * Math.sin(t * .42) + .02 * noise1(t * 3);
  const k = 90, dmp = 16, dt = 1 / 60; const acc = -k * (n.x - target) - dmp * n.v; n.v += acc * dt; n.x += n.v * dt;
  const nx = x0 + n.x * (x1 - x0); const top = 34;
  if (st.sel == null) {
    const dir = Math.sign(n.v || 1); const trail = c.createLinearGradient(nx - 60 * dir, 0, nx, 0);
    trail.addColorStop(0, rgba(Theme.c('signal-fill'), 0)); trail.addColorStop(1, rgba(Theme.c('signal-fill'), .08 * dayK()));
    c.fillStyle = trail; c.fillRect(Math.min(nx, nx - 60 * dir), top, 60, ky - top);
  }
  c.shadowColor = glow(sig); c.shadowBlur = 10; c.fillStyle = sig; c.fillRect(nx - .75, top, 1.5, ky - top + kh); c.shadowBlur = 0;
  c.beginPath(); c.moveTo(nx - 5, top - 6); c.lineTo(nx + 5, top - 6); c.lineTo(nx, top); c.closePath(); c.fill();
  if (st.sel == null) { // lectura: la nota bajo la aguja
    let best = 0, bd = 1e9; for (let q = 0; q < 24; q++) { const d = Math.abs(keyX(q, x0, W) - nx); if (d < bd) { bd = d; best = q; } }
    c.font = '600 9px "Martian Mono", monospace'; c.textAlign = nx > w - 60 ? 'right' : 'left'; c.fillStyle = sig;
    c.fillText(PC_NAME[best % 12] + (4 + Math.floor(best / 12)), nx + (nx > w - 60 ? -9 : 9), top + 4);
  }
}

/* Reloj del círculo de quintas: la hora apunta a la nota de la frecu */
function drawFifths(c, w, h, st, t) {
  const sig = Theme.c('signal'); const cap = st.caption ? 92 : 0;
  const cx = w / 2, cy = (h - cap) / 2, R = Math.min(w, h - cap) * .36;
  let hour = st.hour, minute = st.minute;
  if (st.demo) { const k = (t * .55) % 24; hour = Math.floor(k); minute = (k % 1) * 60; }
  const pos = hour % 12;
  const a0 = -Math.PI / 2 + pos * TAU / 12; // sector activo
  const g = c.createRadialGradient(cx, cy, R * .2, cx, cy, R);
  g.addColorStop(0, rgba(sig, 0)); g.addColorStop(1, rgba(sig, .14));
  c.fillStyle = g; c.beginPath(); c.moveTo(cx, cy); c.arc(cx, cy, R, a0 - TAU / 24, a0 + TAU / 24); c.closePath(); c.fill();
  c.strokeStyle = ink(.07); c.lineWidth = 1; c.beginPath(); // estrella {12/5}: la escala cromática trazada sobre las quintas
  for (let i = 0; i <= 12; i++) { const q = (i * 5) % 12; const a = -Math.PI / 2 + q * TAU / 12; const x = cx + Math.cos(a) * R * .8, y = cy + Math.sin(a) * R * .8; i ? c.lineTo(x, y) : c.moveTo(x, y); }
  c.stroke();
  for (let i = 0; i < 60; i++) { // marcas de minutos
    const a = -Math.PI / 2 + i * TAU / 60; const major = i % 5 === 0; const r0 = R * (major ? .88 : .94);
    c.strokeStyle = major ? ink(.32) : ink(.12); c.lineWidth = major ? 1.4 : 1;
    c.beginPath(); c.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0); c.lineTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R); c.stroke();
  }
  const fs = Math.max(9, Math.round(R * .17));
  c.textAlign = 'center'; c.textBaseline = 'middle';
  for (let i = 0; i < 12; i++) { // notas
    const a = -Math.PI / 2 + i * TAU / 12; const on = i === pos;
    c.font = `${on ? 700 : 500} ${fs}px "Martian Mono", monospace`; c.fillStyle = on ? sig : ink(.42);
    if (on) { c.shadowColor = glow(sig); c.shadowBlur = 12; }
    c.fillText(FIFTHS[i].es, cx + Math.cos(a) * R * 1.22, cy + Math.sin(a) * R * 1.22); c.shadowBlur = 0;
  }
  const ha = -Math.PI / 2 + ((hour % 12) + minute / 60) * TAU / 12, ma = -Math.PI / 2 + minute / 60 * TAU;
  c.lineCap = 'round';
  c.strokeStyle = ink(.5); c.lineWidth = 1.3; c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + Math.cos(ma) * R * .82, cy + Math.sin(ma) * R * .82); c.stroke();
  c.strokeStyle = sig; c.lineWidth = 2.6; c.shadowColor = glow(sig); c.shadowBlur = 12;
  c.beginPath(); c.moveTo(cx, cy); c.lineTo(cx + Math.cos(ha) * R * .6, cy + Math.sin(ha) * R * .6); c.stroke(); c.shadowBlur = 0;
  c.fillStyle = sig; c.beginPath(); c.arc(cx, cy, 3.5, 0, TAU); c.fill();
  if (st.caption) {
    const nt = noteAt(hour, minute);
    c.textBaseline = 'alphabetic'; c.fillStyle = Theme.c('tx-1'); c.font = '800 46px "Doto", monospace';
    c.fillText(`${nt.name}${nt.oct}`, cx, h - 40);
    c.font = '500 10.5px "Martian Mono", monospace'; c.fillStyle = ink(.5);
    c.fillText(`${String(hour).padStart(2, '0')}:${String(Math.floor(minute)).padStart(2, '0')}  ·  ${fmtHz(nt.hz)} HZ`, cx, h - 14);
  }
}

/* Núcleo PTT: bisel con VU circular, anillo líquido y ondas */
function drawPtt(c, w, h, st, t) {
  const cx = w / 2, cy = h / 2; const sig = Theme.c('signal'); const TX = st.tx && !st.dis;
  const lvIn = st.levelFn ? st.levelFn(t) : (st.level || 0);
  const target = TX ? Math.max(.12, lvIn) : 0;
  st.lv = lerp(st.lv || 0, target, target > (st.lv || 0) ? .35 : .12);
  const rxl = st.rx ? st.rx.level : 0;
  st.rv = lerp(st.rv || 0, rxl, .25);
  const col = TX ? sig : st.rx ? st.rx.color : Theme.c('tx-3');
  const active = TX || (st.rx && st.rv > .02);
  // ondas
  st.ripples = st.ripples || []; st.lastR = st.lastR || 0;
  if (active && t - st.lastR > (TX ? .42 : .7)) { st.ripples.push({ t0: t, col: glow(col), a: col === sig ? .45 * dayK() : .45 }); st.lastR = t; }
  st.ripples = st.ripples.filter((r) => t - r.t0 < 1.4);
  for (const r of st.ripples) {
    const k = (t - r.t0) / 1.4; const R = 82 + k * 42;
    c.beginPath();
    for (let i = 0; i <= 96; i++) {
      const a = i / 96 * TAU; const rr = R + noise2(Math.cos(a) * 1.2 + r.t0, Math.sin(a) * 1.2 + t) * 4 * (1 - k);
      i ? c.lineTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr) : c.moveTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr);
    }
    c.closePath(); c.strokeStyle = rgba(r.col, Math.min(1, (1 - k) * r.a)); c.lineWidth = 1.2 + (1 - k) * 1.5; c.stroke();
  }
  // bisel con 72 marcas (VU circular)
  const lit = TX ? Math.round(72 * (.08 + .92 * st.lv)) : st.rx ? Math.round(72 * st.rv * .9) : 0;
  const sweep = (t * .25) % 1;
  for (let i = 0; i < 72; i++) {
    const a = -Math.PI / 2 + i / 72 * TAU; const major = i % 6 === 0;
    const r0 = 113, r1 = r0 + (major ? 9 : 5);
    const on = i < lit;
    let alpha = major ? .28 : .14;
    if (!active && !st.dis) { const d = Math.abs(i / 72 - sweep); alpha += Math.max(0, .5 - Math.min(d, 1 - d) * 9) * .6; }
    c.strokeStyle = on ? rgba(col, .95) : ink(st.dis ? .08 : alpha);
    c.lineWidth = major ? 1.6 : 1.2;
    if (on) { c.shadowColor = glow(col); c.shadowBlur = 8; }
    c.beginPath(); c.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0); c.lineTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1); c.stroke();
    c.shadowBlur = 0;
  }
  // anillo líquido
  const amp = TX ? 3 + 9 * st.lv : st.rx ? 2 + 7 * st.rv : 1.3;
  const spd = TX ? 1.6 : .5;
  c.beginPath();
  for (let i = 0; i <= 140; i++) {
    const a = i / 140 * TAU;
    const rr = 94 + noise2(Math.cos(a) * 1.6 + t * spd, Math.sin(a) * 1.6 - t * spd * .7) * amp;
    i ? c.lineTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr) : c.moveTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr);
  }
  c.closePath();
  if (active) { c.shadowColor = glow(col); c.shadowBlur = 16; }
  c.strokeStyle = active ? rgba(col, .85) : ink(.16); c.lineWidth = active ? 1.8 : 1.2; c.stroke(); c.shadowBlur = 0;
}

/* Malla de la frecu: hexágono de 6 lugares, aristas y paquetes de voz */
function meshSlots(w, h) {
  const cx = w / 2, cy = h / 2 - 14, R = 104;
  const ang = [90, 150, 210, 270, 330, 30];
  return ang.map((d) => ({ x: cx + Math.cos(d * Math.PI / 180) * R, y: cy + Math.sin(d * Math.PI / 180) * R }));
}
function drawMesh(c, w, h, st, t) {
  const slots = meshSlots(w, h);
  const nodes = st.nodes; const rec = st.status === 'rec';
  const lv = nodes.map((n) => (n && !rec && n.levelFn ? n.levelFn(t) : 0));
  st.sm = st.sm || [0, 0, 0, 0, 0, 0];
  for (let i = 0; i < 6; i++) st.sm[i] = lerp(st.sm[i], lv[i], lv[i] > st.sm[i] ? .4 : .1);
  const ageA = (n) => (n.born != null ? clamp((t - n.born) * 1.4) : 1);
  // aristas
  for (let i = 0; i < 6; i++) for (let j = i + 1; j < 6; j++) {
    const A = nodes[i], B = nodes[j]; if (!A || !B) continue;
    c.globalAlpha = Math.min(ageA(A), ageA(B));
    const a = slots[i], b = slots[j];
    const sp = Math.max(st.sm[i], st.sm[j]); const sCol = st.sm[i] >= st.sm[j] ? A.color : B.color;
    const weak = rec || A.state !== 'ok' || B.state !== 'ok';
    c.setLineDash(weak ? [3, 5] : []);
    if (sp > .04) {
      const g = c.createLinearGradient(a.x, a.y, b.x, b.y);
      const fromI = st.sm[i] >= st.sm[j];
      g.addColorStop(fromI ? 0 : 1, rgba(sCol, .2 + .5 * sp)); g.addColorStop(fromI ? 1 : 0, rgba(sCol, .05));
      c.strokeStyle = g; c.lineWidth = 1 + sp;
    } else { c.strokeStyle = weak ? rgba(Theme.c('warn'), .22) : ink(.08); c.lineWidth = 1; }
    c.beginPath(); c.moveTo(a.x, a.y); c.lineTo(b.x, b.y); c.stroke();
  }
  c.globalAlpha = 1; c.setLineDash([]);
  // paquetes de voz
  st.pk = st.pk || []; st.last = st.last || [0, 0, 0, 0, 0, 0];
  for (let i = 0; i < 6; i++) {
    if (!nodes[i] || st.sm[i] < .18 || rec) continue;
    if (t - st.last[i] > .16 - st.sm[i] * .08) {
      st.last[i] = t;
      for (let j = 0; j < 6; j++) if (j !== i && nodes[j] && nodes[j].state === 'ok') st.pk.push({ i, j, t0: t, col: nodes[i].color });
    }
  }
  st.pk = st.pk.filter((p) => t - p.t0 < .75);
  for (const p of st.pk) {
    const k = easeInOut((t - p.t0) / .75); const a = slots[p.i], b = slots[p.j];
    const x = lerp(a.x, b.x, k), y = lerp(a.y, b.y, k);
    c.fillStyle = rgba(p.col, .9 * Math.sin(Math.PI * k)); c.shadowColor = glow(p.col); c.shadowBlur = 8;
    c.beginPath(); c.arc(x, y, 1.8, 0, TAU); c.fill(); c.shadowBlur = 0;
  }
  // nodos
  for (let i = 0; i < 6; i++) {
    const s = slots[i]; const n = nodes[i];
    if (!n) {
      c.setLineDash([2, 4]); c.strokeStyle = ink(.16); c.lineWidth = 1;
      c.beginPath(); c.arc(s.x, s.y, 22, 0, TAU); c.stroke(); c.setLineDash([]);
      c.strokeStyle = ink(.28); c.lineWidth = 1.4;
      c.beginPath(); c.moveTo(s.x - 5, s.y); c.lineTo(s.x + 5, s.y); c.moveTo(s.x, s.y - 5); c.lineTo(s.x, s.y + 5); c.stroke();
      continue;
    }
    const l = st.sm[i]; const age = n.born != null ? t - n.born : 9;
    const gs = age < 1.6 ? clamp(1 - Math.exp(-age * 6) * Math.cos(age * 11), 0, 1.25) : 1; if (gs < .04) continue;
    const R = (27 + l * 3) * gs;
    if (l > .04) { // halo
      const g = c.createRadialGradient(s.x, s.y, R * .6, s.x, s.y, R * 2.2);
      g.addColorStop(0, rgba(n.color, .22 * l + .05)); g.addColorStop(1, rgba(n.color, 0));
      c.fillStyle = g; c.beginPath(); c.arc(s.x, s.y, R * 2.2, 0, TAU); c.fill();
    }
    c.fillStyle = Theme.c('bg-1'); c.beginPath(); c.arc(s.x, s.y, R, 0, TAU); c.fill();
    const recN = rec || n.state === 'rec';
    if (recN) { c.setLineDash([4, 4]); c.lineDashOffset = -t * 12; }
    c.strokeStyle = recN ? rgba(Theme.c('warn'), .7) : l > .04 ? rgba(n.color, .5 + .5 * l) : n.me ? rgba(n.color, .45) : ink(.13);
    c.lineWidth = l > .04 ? 1.5 : 1; c.beginPath(); c.arc(s.x, s.y, R, 0, TAU); c.stroke(); c.setLineDash([]); c.lineDashOffset = 0;
    drawSig(c, s.x, s.y, 17 * gs, n.sig, t + i * 3, { color: n.color, level: l, mode: recN ? 'link' : n.muted ? 'muted' : n.state === 'link' ? 'link' : l > .04 ? 'speak' : 'idle', alpha: recN ? .6 : 1, n: 150 });
    if (n.host) { // marca de antena
      c.strokeStyle = rgba(Theme.c('tx-2'), .9); c.lineWidth = 1.2; const ax = s.x + R * .72, ay = s.y - R * .72;
      c.fillStyle = Theme.c('bg-0'); c.beginPath(); c.arc(ax, ay, 8, 0, TAU); c.fill(); c.stroke();
      c.beginPath(); c.moveTo(ax, ay + 3.5); c.lineTo(ax, ay - 1.5); c.stroke();
      c.beginPath(); c.arc(ax, ay - 1.5, 3, Math.PI * 1.15, Math.PI * 1.85); c.stroke();
    }
  }
}

/* Constelación de bienvenida (órbita lenta) */
function drawOrbit(c, w, h, st, t) {
  const cx = w / 2, cy = h / 2 + 6; const names = st.names;
  const pos = names.map((_, i) => {
    const a = -Math.PI / 2 + i / names.length * TAU + t * .06;
    const R = 118 + 10 * Math.sin(t * .5 + i);
    return { x: cx + Math.cos(a) * R, y: cy + Math.sin(a) * R * .86 };
  });
  for (let r = 0; r < 4; r++) { // anillos de medición
    c.strokeStyle = ink(.05 - r * .008); c.lineWidth = 1;
    c.beginPath(); c.ellipse(cx, cy, 60 + r * 46, (60 + r * 46) * .86, 0, 0, TAU); c.stroke();
  }
  st.mesh = st.mesh || { nodes: [], status: 'ok' };
  const speaking = Math.floor(t / 2.6) % names.length;
  for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) {
    const sp = i === speaking || j === speaking;
    c.strokeStyle = sp ? rgba(Theme.c(PCOLORS[speaking]), .28) : ink(.07);
    c.beginPath(); c.moveTo(pos[i].x, pos[i].y); c.lineTo(pos[j].x, pos[j].y); c.stroke();
  }
  for (let j = 0; j < names.length; j++) { // paquetes desde quien habla
    if (j === speaking) continue;
    const k = ((t * 1.3 + j * .21) % 1); const a = pos[speaking], b = pos[j];
    const col = Theme.c(PCOLORS[speaking]);
    c.fillStyle = rgba(col, Math.sin(Math.PI * k)); c.shadowColor = glow(col); c.shadowBlur = 10;
    c.beginPath(); c.arc(lerp(a.x, b.x, k), lerp(a.y, b.y, k), 2, 0, TAU); c.fill(); c.shadowBlur = 0;
  }
  names.forEach((n, i) => {
    const lvl = i === speaking ? voice(t, i) : 0; const col = Theme.c(PCOLORS[i]);
    c.fillStyle = Theme.c('bg-0'); c.beginPath(); c.arc(pos[i].x, pos[i].y, 30, 0, TAU); c.fill();
    c.strokeStyle = i === speaking ? rgba(col, .6) : ink(.12); c.lineWidth = 1; c.stroke();
    drawSig(c, pos[i].x, pos[i].y, 20, sigParams(n), t + i, { color: col, level: lvl, mode: lvl > .04 ? 'speak' : 'idle', n: 150 });
  });
}

/* Splash: portadora plana → onda → firma */
const SPLASH_P = 5.2;
function drawSplash(c, w, h, t, sig) {
  const p = t % SPLASH_P; const cx = w / 2, cy = h * .4;
  const col = Theme.c('signal'); const L = w * .36;
  const grow = easeOut(p / .55); const amp = easeInOut((p - .5) / .9) * 54;
  const m = easeInOut((p - 1.35) / 1); const settle = easeInOut((p - 2.2) / .8);
  const fade = 1 - smooth(4.7, 5.15, p);
  const N = 260; const R = lerp(90, 62, settle);
  c.save(); c.globalAlpha = fade; c.lineCap = 'round'; c.lineJoin = 'round';
  c.shadowColor = glow(col); c.shadowBlur = 18;
  c.beginPath();
  for (let i = 0; i <= N; i++) {
    const u = i / N; const U = u * TAU;
    const wx = cx + (u - .5) * 2 * L * grow;
    const env = Math.sin(Math.PI * u);
    const wy = cy + Math.sin(U * 3 - t * 3.2) * amp * env;
    const lx = cx + Math.sin(sig.a * U + sig.phase + t * .25) * R;
    const ly = cy + Math.sin(sig.b * U) * R;
    const x = lerp(wx, lx, m), y = lerp(wy, ly, m);
    i ? c.lineTo(x, y) : c.moveTo(x, y);
  }
  c.strokeStyle = rgba(col, .9); c.lineWidth = 2; c.stroke();
  c.restore();
  // marcas del dial
  c.globalAlpha = fade * smooth(.1, .8, p);
  for (let i = 0; i < 90; i++) {
    const a = i / 90 * TAU; const r0 = 132, r1 = r0 + (i % 5 ? 4 : 9);
    c.strokeStyle = ink(i % 5 ? .1 : .22); c.lineWidth = 1;
    c.beginPath(); c.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0); c.lineTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1); c.stroke();
  }
  c.globalAlpha = 1;
}

/* Ilustración de punto de acceso: teléfono emisor con anillos orgánicos */
function drawHotspot(c, w, h, t) {
  const cx = w / 2, cy = h / 2; const col = Theme.c('signal');
  for (let k = 0; k < 4; k++) {
    const ph = ((t * .35 + k / 4) % 1); const R = 34 + ph * 110;
    c.beginPath();
    for (let i = 0; i <= 120; i++) {
      const a = i / 120 * TAU; const rr = R + noise2(Math.cos(a) + k * 3, Math.sin(a) + t * .6) * 6 * ph;
      i ? c.lineTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr * .62) : c.moveTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr * .62);
    }
    c.closePath(); c.strokeStyle = rgba(col, (1 - ph) * .5); c.lineWidth = 1.3; c.stroke();
  }
  // teléfono
  c.fillStyle = Theme.c('bg-2'); c.strokeStyle = ink(.3); c.lineWidth = 1.2;
  c.beginPath(); c.roundRect(cx - 19, cy - 34, 38, 68, 9); c.fill(); c.stroke();
  c.fillStyle = col; c.shadowColor = glow(col); c.shadowBlur = 12; c.beginPath(); c.arc(cx, cy - 6, 3.5, 0, TAU); c.fill(); c.shadowBlur = 0;
  c.strokeStyle = rgba(col, .9); c.lineWidth = 1.5;
  for (let r = 1; r <= 2; r++) { c.beginPath(); c.arc(cx, cy - 6, 6 * r + 2, Math.PI * 1.2, Math.PI * 1.8); c.stroke(); }
  // satélites
  ['Ana', 'Leo', 'Sofi'].forEach((n, i) => {
    const a = -2.4 + i * 1.6 + Math.sin(t * .4 + i) * .1; const x = cx + Math.cos(a) * 128, y = cy + Math.sin(a) * 66;
    c.fillStyle = Theme.c('bg-0'); c.beginPath(); c.arc(x, y, 15, 0, TAU); c.fill();
    c.strokeStyle = ink(.14); c.lineWidth = 1; c.stroke();
    drawSig(c, x, y, 10, sigParams(n), t, { color: Theme.c(PCOLORS[i + 1]), n: 120 });
  });
}

/* Línea plana: fin de la transmisión */
function drawFlat(c, w, h, t) {
  const p = t % 6; const cx = w / 2, cy = h / 2; const k = 1 - easeInOut(p / 2.4);
  const sig = sigParams('frecu');
  c.lineCap = 'round';
  c.beginPath();
  for (let i = 0; i <= 220; i++) {
    const u = i / 220 * TAU; const lx = Math.sin(sig.a * u + sig.phase) * 80, ly = Math.sin(sig.b * u) * 80;
    const fx = (i / 220 - .5) * (w - 60), fy = 0;
    const blip = p > 3 ? Math.exp(-(((i / 220) - ((p - 3) / 3)) ** 2) / .0008) * 10 * Math.sin(i * .9) : 0;
    const x = cx + lerp(fx, lx, k), y = cy + lerp(fy + blip, ly, k);
    i ? c.lineTo(x, y) : c.moveTo(x, y);
  }
  c.strokeStyle = rgba(Theme.c('tx-2'), .7); c.lineWidth = 1.6; c.stroke();
  c.fillStyle = ink(.12);
  for (let x = 30; x < w - 20; x += 22) c.fillRect(x, cy + 70, 1, 6);
}

/* QR decorativo (en la app se genera con qr_flutter, módulos redondos) */
function drawQR(c, size, seed, ink = '#0B0D0F') {
  const n = 29, cell = size / n; const r = rng(seed);
  const inFinder = (x, y) => (x < 8 && y < 8) || (x > n - 9 && y < 8) || (x < 8 && y > n - 9);
  const inLogo = (x, y) => x > 10 && x < 18 && y > 10 && y < 18;
  c.fillStyle = ink;
  for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
    if (inFinder(x, y) || inLogo(x, y)) continue;
    const timing = (y === 6 || x === 6) && ((x + y) % 2 === 0);
    if (timing || r() > .52) { c.beginPath(); c.arc((x + .5) * cell, (y + .5) * cell, cell * .4, 0, TAU); c.fill(); }
  }
  for (const [fx, fy] of [[0, 0], [n - 7, 0], [0, n - 7]]) {
    c.lineWidth = cell; c.strokeStyle = ink;
    c.beginPath(); c.roundRect((fx + .5) * cell, (fy + .5) * cell, cell * 6, cell * 6, cell * 2); c.stroke();
    c.beginPath(); c.roundRect((fx + 2) * cell, (fy + 2) * cell, cell * 3, cell * 3, cell * 1.1); c.fill();
  }
  c.save(); c.translate(size / 2, size / 2);
  c.fillStyle = ink; c.beginPath(); c.roundRect(-cell * 3.6, -cell * 3.6, cell * 7.2, cell * 7.2, cell * 2); c.fill();
  drawSig(c, 0, 0, cell * 2.4, { a: 2, b: 3, phase: .6, rot: 0, drift: 0 }, 0, { color: Theme.c('signal-fill'), n: 160 });
  c.restore();
}

/* Cámara simulada para el escáner */
let _qrOff = null;
function drawCamera(c, w, h, t, st) {
  const sx = noise1(t * .7) * 5, sy = noise1(t * .6 + 4) * 5;
  const g = c.createLinearGradient(0, 0, 0, h);
  g.addColorStop(0, '#1a1d22'); g.addColorStop(.5, '#0d0f12'); g.addColorStop(1, '#151310');
  c.fillStyle = g; c.fillRect(0, 0, w, h);
  for (let i = 0; i < 7; i++) { // bokeh
    const x = (i * 97 + 40) % w + noise1(t * .1 + i) * 30, y = (i * 173 + 90) % h, r = 40 + (i % 3) * 30;
    const b = c.createRadialGradient(x, y, 0, x, y, r);
    b.addColorStop(0, `rgba(${i % 2 ? '255,200,140' : '140,170,210'},.1)`); b.addColorStop(1, 'rgba(0,0,0,0)');
    c.fillStyle = b; c.beginPath(); c.arc(x, y, r, 0, TAU); c.fill();
  }
  if (!_qrOff) { _qrOff = document.createElement('canvas'); _qrOff.width = _qrOff.height = 300; const q = _qrOff.getContext('2d'); q.fillStyle = '#F2F4EF'; q.fillRect(0, 0, 300, 300); q.translate(30, 30); drawQR(q, 240, 77); }
  c.save(); c.translate(w / 2 + sx, 330 + sy); c.rotate(-.08 + noise1(t * .3) * .02);
  c.fillStyle = '#050607'; c.beginPath(); c.roundRect(-118, -170, 236, 400, 30); c.fill();
  c.strokeStyle = 'rgba(255,255,255,.12)'; c.lineWidth = 2; c.stroke();
  c.globalAlpha = .92; c.drawImage(_qrOff, -95, -95, 190, 190); c.globalAlpha = 1;
  c.restore();
  const v = c.createRadialGradient(w / 2, h / 2, h * .2, w / 2, h / 2, h * .75);
  v.addColorStop(0, 'rgba(0,0,0,0)'); v.addColorStop(1, 'rgba(0,0,0,.7)'); c.fillStyle = v; c.fillRect(0, 0, w, h);
}

/* Mini espectro de la tarjeta de frecu cercana */
function drawSpark(c, w, h, t, ch, on) {
  const col = Theme.c('signal'); const cx = w * (.2 + .7 * ch / 23); const base = h * .5;
  c.beginPath();
  for (let x = 0; x <= w; x += 1.5) {
    const y = base - Math.exp(-((x - cx) ** 2) / 30) * (h * .34) * (.9 + .1 * Math.sin(t * 3)) - Math.abs(noise2(x * .2, t * 1.5)) * 2;
    x ? c.lineTo(x, y) : c.moveTo(x, y);
  }
  c.strokeStyle = rgba(col, on ? .9 : .3); c.lineWidth = 1.1; c.stroke();
}

/* Visuales de principios y curvas de movimiento */
function drawPillar(c, w, h, kind, t) {
  const col = Theme.c('signal'); const cy = h / 2;
  if (kind === 0) { // luz solo con señal
    const lv = voice(t, 3);
    c.beginPath();
    for (let x = 0; x <= w; x += 2) { const y = cy + Math.sin(x * .06 - t * 6) * 22 * lv * Math.sin(Math.PI * x / w); x ? c.lineTo(x, y) : c.moveTo(x, y); }
    c.shadowColor = glow(col); c.shadowBlur = 14 * lv; c.strokeStyle = lv > .05 ? rgba(col, .4 + .6 * lv) : ink(.25); c.lineWidth = 1.6; c.stroke(); c.shadowBlur = 0;
  } else if (kind === 1) { // precisión
    for (let x = 0; x <= w; x += 6) { const m = Math.round(x / 6) % 5 === 0; c.fillStyle = m ? ink(.4) : ink(.15); c.fillRect(x, h - 20, 1, m ? 14 : 7); }
    const nx = w * (.5 + .38 * Math.sin(t * .8)); c.fillStyle = col; c.shadowColor = glow(col); c.shadowBlur = 10; c.fillRect(nx, 8, 1.5, h - 14); c.shadowBlur = 0;
    c.font = '500 10px "Martian Mono", monospace'; c.fillText((nx / w * 100).toFixed(1), nx + 6, 18);
  } else if (kind === 2) { // orgánico
    const cx = w / 2;
    for (let k = 0; k < 3; k++) {
      c.beginPath();
      for (let i = 0; i <= 120; i++) { const a = i / 120 * TAU; const r = 26 + k * 10 + noise2(Math.cos(a) * 1.3 + t * .7, Math.sin(a) * 1.3 + k) * 7; i ? c.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r) : c.moveTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r); }
      c.closePath(); c.strokeStyle = rgba(col, .8 - k * .25); c.lineWidth = 1.3; c.stroke();
    }
  } else { // táctil
    const p = (t % 2.2) / 2.2; const cx = w / 2;
    for (let k = 0; k < 3; k++) { c.strokeStyle = ink(.14); c.beginPath(); c.arc(cx, cy, 14 + k * 12, 0, TAU); c.stroke(); }
    c.strokeStyle = rgba(col, 1 - p); c.lineWidth = 2; c.beginPath(); c.arc(cx, cy, 14 + easeOut(p) * 36, 0, TAU); c.stroke();
    const s = p < .1 ? 1 - p * 1.2 : 1; c.fillStyle = col; c.beginPath(); c.arc(cx, cy, 9 * s, 0, TAU); c.fill();
  }
}
function curveFn(kind) {
  if (kind === 'out') return (x) => 1 - Math.pow(1 - x, 4);
  if (kind === 'in') return (x) => x * x * x * x;
  if (kind === 'breath') return (x) => .5 - .5 * Math.cos(x * TAU);
  const v = springSamples(SPRINGS[kind], 120).values;
  return (x) => { const f = x * 120; const i = Math.floor(f); return lerp(v[Math.min(i, 120)], v[Math.min(i + 1, 120)], f - i); };
}
function drawCurve(c, w, h, fn, t, dur) {
  const pad = 14, x0 = pad, x1 = w * .62, y0 = h - pad, y1 = pad + 14;
  c.strokeStyle = ink(.08); c.lineWidth = 1;
  c.beginPath(); c.moveTo(x0, y0); c.lineTo(x1, y0); c.moveTo(x0, y1); c.lineTo(x1, y1); c.stroke();
  c.beginPath();
  for (let i = 0; i <= 100; i++) { const x = i / 100; const y = fn(x); const px = lerp(x0, x1, x), py = lerp(y0, y1, y); i ? c.lineTo(px, py) : c.moveTo(px, py); }
  c.strokeStyle = ink(.45); c.lineWidth = 1.4; c.stroke();
  const p = clamp(((t % (dur + .9)) / dur)); const v = fn(p); const col = Theme.c('signal');
  c.fillStyle = col; c.shadowColor = glow(col); c.shadowBlur = 10;
  c.beginPath(); c.arc(lerp(x0, x1, p), lerp(y0, y1, v), 3.5, 0, TAU); c.fill();
  const bx = w * .68, bw = w * .22; // carril
  c.shadowBlur = 0; c.fillStyle = ink(.06); c.fillRect(bx, h / 2 - 1, bw, 2);
  c.fillStyle = col; c.shadowBlur = 14; c.beginPath(); c.arc(bx + bw * clamp(v, -.2, 1.25), h / 2, 9, 0, TAU); c.fill(); c.shadowBlur = 0;
}
