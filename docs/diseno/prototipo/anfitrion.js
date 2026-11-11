/* ==========================================================================
   Frecu · Tipo de frecu y traspaso de anfitrión — prototipo
   Página aparte: reutiliza engine.js, components.js y screens.js sin tocarlos.
   ========================================================================== */

const under = (html, cls) => html.replace(`class="view ${cls}`, `class="view ${cls} under`);
const ghost = (label) => `<button class="btn btn-ghost"><span class="lbl">${label}</span></button>`;

/* ---------- Crear: primero el tipo ---------- */
function kindStep(kind = 'local', o = {}) {
  const local = kind === 'local';
  return `<section class="view v-create" data-screen="kind">
    <div class="appbar">${back}<span class="ttl"><span class="t-label-s c3">Paso 1 de ${local ? 3 : 2}</span><b>Nueva frecu</b></span>${spacer}</div>
    <div class="pad" style="margin-top:18px"><h1 class="h-screen" style="font-size:26px;line-height:30px">¿Cómo se une tu grupo?</h1>
      <p class="p-screen" style="margin-top:8px">Se elige una vez. La frecu no mezcla las dos formas.</p></div>
    <div class="pad ah-opts" style="margin-top:22px">
      ${UI.opt('hotspot', 'Local', 'Todos conectados a la misma Wi-Fi: la que crea tu teléfono o una que ya tengan, como la de la casa o la oficina. Sin internet y sin gastar datos.', { on: local })}
      ${UI.opt('globe', 'Por internet', o.offline ? 'Necesitas internet para crearla. Conéctate a una Wi-Fi con internet o activa tus datos.' : 'Desde cualquier lugar, con el QR o el enlace. Usa datos móviles.', { on: !local, dis: o.offline })}
    </div>
    <div class="dock">${UI.btn('Seguir', { iconR: 'arrow' })}</div></section>`;
}

/* «Nueva frecu» sin el interruptor; el paso y la etiqueta dicen el tipo. */
function createOf(kind) {
  const net = kind === 'net';
  let html = V.create({ net }).replace(/<div class="group" data-net-row>[\s\S]*?<\/div><\/div>/, '');
  html = html.replace('Paso 2 de 2', net ? 'Paso 2 de 2' : 'Paso 3 de 3');
  if (!net) html = html.replace(`Abierta a las ${ROOM.opened}</span>`, `Abierta a las ${ROOM.opened}</span><span class="tag s t-label-s">${I('hotspot', 's12')}Local</span>`);
  return html;
}

/* ---------- Mallas ---------- */
function meshWith(o = {}) {
  const me = node(ME, 'signal', { me: true, host: !!o.meHost });
  const andres = node('Andrés', 'p1', { host: !o.anaHost && !o.meHost });
  const ana = node('Ana', 'p2', { host: !!o.anaHost }), leo = node('Leo', 'p3'), sofi = node('Sofi', 'p4');
  if (o.andresGone) andres.state = 'rec';
  const nodes = [me, ana, sofi, o.noAndres ? null : andres, null, leo];
  return { nodes, status: o.status || 'ok' };
}
const hostLine = (html, name) => html.replace('Anfitrión · Andrés', `Anfitrión · ${name}`);

/* ---------- Salir (anfitrión) ---------- */
function leaveHost(mode = 'choose') {
  const icon = `<span class="perm" style="padding:0;background:none;box-shadow:none"><span class="pic" style="width:56px;height:56px;border-radius:18px;color:var(--signal-fg)">${I('antenna', 's28')}</span></span>`;
  if (mode === 'hotspot') return SH.leave({ host: true }).replace(leaveCopy(4), 'Tu teléfono es la red de la frecu. Si sales, la frecu se cierra para las otras 4 personas.');
  if (mode === 'pick') {
    const peers = [['Ana', 'p2', 'Lleva más tiempo · sugerida', true], ['Sofi', 'p4', 'Desde las 16:31'], ['Leo', 'p3', 'Desde las 16:40']];
    return `<div class="sheet" data-sheet-el="handover"><span class="grab"></span>
      <div class="sh-h"><div><span class="t-label-s c3">Que siga sin mí</span><h3 style="margin-top:8px">¿Quién lleva la frecu?</h3><p>Esa persona muestra el QR y decide cuándo cerrarla.</p></div>${UI.ibtn('close', { cls: 's40', label: 'Cerrar' })}</div>
      <div class="ah-peer">${peers.map(([n, c, sub, on]) => `<button class="opt ${on ? 'on' : ''}"><span class="oic" style="background:none;box-shadow:none">${UI.sig(n, { size: 34, color: c })}</span><span class="ot"><b>${n}</b><span class="t-label-s ${on ? 'ah-sug' : ''}">${sub}</span></span><span class="ock">${on ? I('check', 's16') : ''}</span></button>`).join('')}</div>
      ${UI.btn('Pasar a Ana y salir', { icon: 'exit' })}</div>`;
  }
  return `<div class="sheet" data-sheet-el="leave"><span class="grab"></span>
    <div style="display:flex;flex-direction:column;align-items:center;text-align:center;gap:12px;padding:10px 6px 4px">${icon}
      <h3 style="font:680 22px/1.2 var(--f-ui);font-stretch:116%">¿Qué pasa con la frecu?</h3>
      <p class="p-screen" style="font-size:14.5px">Eres el anfitrión y hay 4 personas más.</p></div>
    <div class="ah-opts">
      ${UI.opt('users', 'Que siga sin mí', 'Pasas la frecu a otra persona y sales. Los demás siguen hablando.', { on: true })}
      ${UI.opt('exit', 'Cerrarla para todos', 'La frecu se cierra y todos salen.')}
    </div>
    ${UI.btn('Seguir', { iconR: 'arrow' })}
    ${UI.btn('Cancelar', { v: 'secondary' })}</div>`;
}

/* ---------- Traspaso visto por los invitados y por quien la recibe ---------- */
const toastAt = (html, o) => `<div class="ah-toast">${UI.toast(html, o)}</div>`;
const withOverlay = (html, overlay) => html.replace('<div class="ctrls">', `${overlay}<div class="ctrls">`);

const guestAfter = (msg) => withOverlay(hostLine(roomView('idle', { ms: meshWith({ anaHost: true, noAndres: true }) }), 'Ana'), toastAt(msg, { sig: 'Ana', color: 'p2' }));

const heirView = (msg) => withOverlay(
  roomView('idle', { host: true, ms: meshWith({ meHost: true, noAndres: true }) }).replace('Eres el anfitrión', 'Llevas la frecu'),
  `<div class="echo ah-banner">${UI.banner('info', 'antenna', msg + '<br><span class="act">Mostrar el QR</span>')}</div>`,
);

const guestSearching = () => {
  const ms = meshWith({ andresGone: true });
  return roomView('idle', { ms }).replace(
    isleFor('idle', ms.nodes.filter(Boolean).length),
    UI.isle('warn', '<i class="dot"></i><span class="t-label" style="color:var(--warn)">Andrés no responde · 3 s</span>'),
  ).replace('Mantén para hablar · o usa el botón de volumen', 'Siguen hablando · si no vuelve, Ana toma la frecu');
};

const backAsGuest = () => withOverlay(
  hostLine(roomView('idle', { ms: { nodes: [node(ME, 'signal', { me: true }), node('Ana', 'p2', { host: true }), node('Sofi', 'p4'), null, null, node('Leo', 'p3')], status: 'ok' } }), 'Ana'),
  toastAt('Volviste como invitado · Ana lleva la frecu', { icon: 'check' }),
);

/* ---------- Red del anfitrión: no hay traspaso ---------- */
const hotspotRetry = () => roomView('rec', { ms: meshWith({ andresGone: true, status: 'rec' }) })
  .replace('Recuperando la conexión…', 'La red era el teléfono de Andrés');
const hotspotClosed = () => V.closed().replace('El anfitrión cerró la frecu. Puedes unirte a otra cuando quieras.', 'Se perdió la red del anfitrión y no volvió. Puedes unirte a otra cuando quieras.');

/* ---------- Galería ---------- */
const AH_GALLERY = [
  { flow: 'Crear · el tipo va primero', items: [
    { title: 'Local', route: 'CreateRoomRoute · paso 1 · nuevo', desc: 'Local va marcada por defecto. Después siguen «Prepara la red» y «Nueva frecu».', html: () => kindStep('local') },
    { title: 'Por internet', route: 'CreateRoomRoute · paso 1', desc: 'Se salta «Prepara la red»: va directo a «Nueva frecu».', html: () => kindStep('net') },
    { title: 'Sin internet ahora', route: 'Sin conexión a la nube', desc: '«Por internet» se ve atenuada y dice qué falta.', html: () => kindStep('local', { offline: true }) },
    { title: 'Nueva frecu · local', route: 'NewRoomStep · paso 3 de 3', desc: 'Sin interruptor: la etiqueta dice el tipo elegido.', html: () => createOf('local') },
    { title: 'Nueva frecu · por internet', route: 'NewRoomStep · paso 2 de 2', desc: 'Igual que hoy con internet, sin interruptor.', html: () => createOf('net') },
  ] },
  { flow: 'Router o internet · el anfitrión sale', items: [
    { title: '¿Qué pasa con la frecu?', route: 'Hoja · salir · con traspaso', desc: 'Dos caminos. «Que siga sin mí» va marcado. Si está solo, la hoja de hoy: cerrar.', html: () => under(roomView('idle', { host: true }), 'v-room') + scrim + leaveHost('choose') },
    { title: '¿Quién lleva la frecu?', route: 'Hoja · elegir sucesor', desc: 'Sugerida la persona que lleva más tiempo. Con una sola persona más, el botón va directo: «Pasar a Ana y salir».', html: () => under(roomView('idle', { host: true }), 'v-room') + scrim + leaveHost('pick') },
    { title: 'Los demás', route: 'host_changed · voluntario', desc: 'Aviso corto y la cabecera cambia. La voz sigue.', html: () => guestAfter('Andrés salió · Ana lleva ahora la frecu') },
    { title: 'Quien la recibe', route: 'Ahora es anfitrión', desc: 'En router, su QR es nuevo (otra IP). Por internet, el enlace es el mismo.', html: () => heirView('<b>Ahora llevas la frecu.</b> Andrés te la pasó al salir.') },
  ] },
  { flow: 'Router o internet · el anfitrión se cae', items: [
    { title: 'Anfitrión sin respuesta', route: 'RoomStatus.reconnecting', desc: 'Unos 4 s de espera por si vuelve. La voz entre los demás no se corta.', html: () => guestSearching() },
    { title: 'Toma automática', route: 'host_changed · caída', desc: 'Pasa a la primera persona de la lista de sucesión que siga conectada.', html: () => guestAfter('Andrés se desconectó · Ana lleva ahora la frecu') },
    { title: 'Quien la recibe', route: 'Ahora es anfitrión · caída', desc: 'Nadie tuvo que elegir. Si Ana tampoco responde, sigue la próxima de la lista.', html: () => heirView('<b>Ahora llevas la frecu.</b> Andrés se desconectó.') },
    { title: 'El anterior vuelve', route: 'Turno mayor · entra como invitado', desc: 'Vuelve a entrar como invitado. Ana sigue llevando la frecu.', html: () => backAsGuest() },
  ] },
  { flow: 'Red creada por el anfitrión · sin traspaso', items: [
    { title: 'Salir', route: 'Hoja · salir · zona Wi-Fi', desc: 'Solo «Cerrar frecu», y dice por qué: su teléfono es la red.', html: () => under(roomView('idle', { host: true }), 'v-room') + scrim + leaveHost('hotspot') },
    { title: 'Se cayó el anfitrión', route: 'RoomStatus.reconnecting', desc: 'Los invitados reintentan como hoy, por si el teléfono vuelve.', html: () => hotspotRetry() },
    { title: 'No volvió', route: 'RoomStatus.closed', desc: 'Tras los reintentos, la frecu se cierra.', html: () => hotspotClosed() },
  ] },
];

function buildAH() {
  const root = document.getElementById('gallery');
  root.innerHTML = AH_GALLERY.map((f) => `<div class="flow-label"><b>${f.flow}</b><span>${f.items.length} pantallas</span><i></i></div>
    <div class="gal">${f.items.map((it) => `<div class="gitem"><div class="scaler">${phone(it.html())}</div><div class="cap"><em>${it.route}</em><b>${it.title}</b><span>${it.desc}</span></div></div>`).join('')}</div>`).join('');
  document.querySelectorAll('[data-theme-set]').forEach((b) => b.addEventListener('click', () => {
    document.documentElement.dataset.theme = b.dataset.themeSet;
    document.querySelectorAll('[data-theme-set]').forEach((x) => x.classList.toggle('on', x === b));
  }));
}

function bootAH() {
  document.documentElement.dataset.theme = document.documentElement.dataset.theme || 'dark';
  installSprings(); Theme.refresh();
  buildAH();
  hydrate(document);
  if (document.fonts) document.fonts.ready.then(() => document.querySelectorAll('.seg').forEach((s) => placeSeg(s)));
}
document.readyState === 'loading' ? document.addEventListener('DOMContentLoaded', bootAH) : bootAH();
